<script setup lang="ts">
import * as z from "zod";
import type { FormSubmitEvent } from "@nuxt/ui";

definePageMeta({
  layout: "dashboard",
  middleware: "auth",
});

const supabase = useSupabaseClient();
const route = useRoute();
const router = useRouter();
const toast = useToast();

// Resolve modal component (used for AI prompt preview)
const UModal = resolveComponent("UModal");

// If `report_id` is present in the query, we're editing an existing report
const reportId = ref<string | null>(
  (route.query.report_id as string) || (route.query.id as string) || null
);
const isEditing = computed(() => !!reportId.value);

// Schema validasi
const schema = z.object({
  umkm_id: z.string().min(1, "Pilih UMKM"),
  periode_mulai: z.string().min(1, "Periode mulai wajib diisi"),
  periode_selesai: z.string().min(1, "Periode selesai wajib diisi"),
  uang_masuk: z.number().min(0, "Uang masuk minimal 0"),
  uang_keluar: z.number().min(0, "Uang keluar minimal 0"),
  masalah: z.string().optional(),
  saran: z.string().min(10, "Saran minimal 10 karakter"),
  is_partial: z.boolean(),
});

type Schema = z.output<typeof schema>;

// Load list UMKM
const { data: umkmList } = await useAsyncData<any[]>("umkm-list", async () => {
  const { data } = await (supabase as any)
    .from("umkm_profiles")
    .select("id, nama_usaha, nama_pemilik, status, no_wa")
    .order("nama_usaha");
  return data || [];
});

// State form
const state = reactive<Partial<Schema>>({
  umkm_id:
    (route.query.umkm_id as string) ||
    (route.query.umkm as string) ||
    undefined,
  periode_mulai: undefined,
  periode_selesai: undefined,
  uang_masuk: undefined,
  uang_keluar: undefined,
  masalah: undefined,
  saran: undefined,
  is_partial: false,
});

const selectedUmkm = computed(() => {
  return umkmList.value?.find((u) => u.id === state.umkm_id);
});

// SelectItem mapping for USelectMenu: allows mapping between {label,value,description} and state.umkm_id (string)
interface SelectItem {
  label: string;
  value: string;
  description: string | null;
}

const selectedUmkmItem = computed<SelectItem | undefined>({
  get() {
    const id = state.umkm_id;
    const u = umkmList.value?.find((x: any) => x.id === id);
    if (!u) return undefined;
    return {
      label: `${u.nama_usaha} — ${u.nama_pemilik}`,
      value: u.id,
      description: u.status
        ? u.status.charAt(0).toUpperCase() + u.status.slice(1)
        : "",
    };
  },
  set(v) {
    state.umkm_id = (v as any)?.value;
  },
});

const untungRugi = computed(() => {
  const masuk = state.uang_masuk || 0;
  const keluar = state.uang_keluar || 0;
  return masuk - keluar;
});

const whatsappPreview = computed(() => {
  if (!selectedUmkm.value) return "";

  const formatRupiah = (num: number) =>
    new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      minimumFractionDigits: 0,
    }).format(num);

  const formatDate = (dateStr: string) => {
    if (!dateStr) return "-";
    return new Intl.DateTimeFormat("id-ID", {
      day: "numeric",
      month: "short",
      year: "numeric",
    }).format(new Date(dateStr));
  };

  return `📊 *Laporan Keuangan Mingguan*\n${
    selectedUmkm.value.nama_usaha
  }\nPeriode: ${formatDate(state.periode_mulai!)} - ${formatDate(
    state.periode_selesai!
  )}\n\n💰 Uang Masuk: ${formatRupiah(
    state.uang_masuk || 0
  )}\n💸 Uang Keluar: ${formatRupiah(state.uang_keluar || 0)}\n${
    untungRugi.value >= 0 ? "📈" : "📉"
  } ${untungRugi.value >= 0 ? "Untung" : "Rugi"}: ${formatRupiah(
    Math.abs(untungRugi.value)
  )}${
    state.masalah ? `\n\n⚠️ *Masalah:*\n${state.masalah}` : ""
  }\n\n💡 *Saran:*\n${state.saran || "-"}`;
});

// Set periode minggu ini otomatis OR load report if editing
onMounted(async () => {
  // If editing, load the report; otherwise set default week
  if (reportId.value) {
    try {
      const { data: r, error } = await (supabase as any)
        .from("weekly_reports")
        .select("*")
        .eq("id", reportId.value)
        .single();
      if (error) throw error;
      // Populate form state with existing values
      state.umkm_id = r.umkm_id;
      state.periode_mulai = r.periode_mulai;
      state.periode_selesai = r.periode_selesai;
      state.uang_masuk = Number(r.uang_masuk || 0);
      state.uang_keluar = Number(r.uang_keluar || 0);
      state.masalah = r.masalah || undefined;
      state.saran = r.saran || undefined;
      state.is_partial = !!r.is_partial;
    } catch (err: any) {
      toast.add({
        title: "Gagal memuat laporan",
        description: err.message,
        color: "error",
      });
    }
  } else {
    const today = new Date();
    const monday = new Date(today);
    monday.setDate(today.getDate() - today.getDay() + 1);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);

    state.periode_mulai = monday.toISOString().split("T")[0];
    state.periode_selesai = sunday.toISOString().split("T")[0];
  }

  // Respect incoming umkm_id query if present and not already set by a fetched report
  if (!state.umkm_id && route.query.umkm_id)
    state.umkm_id = route.query.umkm_id as string;
});

// Previous reports for AI prompt (last 8 weeks)
const { data: prevReportsData, refresh: refreshPrevReports } =
  await useAsyncData<any[]>(
    () =>
      `prev-reports:${state.umkm_id || "none"}:${state.periode_mulai || ""}`,
    async () => {
      if (!state.umkm_id) return [];
      const { data } = await (supabase as any)
        .from("weekly_reports")
        .select(
          "periode_mulai, periode_selesai, uang_masuk, uang_keluar, masalah, saran"
        )
        .eq("umkm_id", state.umkm_id)
        .order("periode_mulai", { ascending: false })
        .limit(8);
      return data || [];
    }
  );

const prevReports = computed(() => prevReportsData.value || []);

// AI prompt generation & preview/copy
const aiPreviewOpen = ref(false);

const aiPrompt = computed(() => {
  if (!selectedUmkm.value) return "";
  const fmt = (n: number) =>
    new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      minimumFractionDigits: 0,
    }).format(n || 0);

  const lines: string[] = [];
  lines.push(
    `UMKM: ${selectedUmkm.value.nama_usaha} (Pemilik: ${selectedUmkm.value.nama_pemilik})`
  );
  lines.push(
    `Periode laporan: ${state.periode_mulai || "-"} — ${
      state.periode_selesai || "-"
    }`
  );
  lines.push(`Uang Masuk: ${fmt(state.uang_masuk || 0)}`);
  lines.push(`Uang Keluar: ${fmt(state.uang_keluar || 0)}`);
  lines.push(
    `Untung/Rugi: ${
      state.uang_masuk && state.uang_keluar
        ? fmt((state.uang_masuk || 0) - (state.uang_keluar || 0))
        : "-"
    }\n`
  );

  if ((prevReports.value || []).length) {
    lines.push("Data 8 minggu terakhir (terbaru dulu):");
    prevReports.value.forEach((r: any, idx: number) => {
      const masuk = Number(r.uang_masuk || 0);
      const keluar = Number(r.uang_keluar || 0);
      const ur = masuk - keluar;
      lines.push(
        `${idx + 1}. ${r.periode_mulai} — ${r.periode_selesai}: Masuk ${fmt(
          masuk
        )}, Keluar ${fmt(keluar)}, Untung/Rugi ${fmt(ur)}`
      );
    });
  } else {
    lines.push("Tidak ada data historis tersedia.");
  }

  lines.push(
    "\nInstruksi untuk AI:\n" +
      "Kamu adalah pembantu keuangan sederhana untuk pemilik toko kecil.\n" +
      "Jawaban HARUS singkat, jelas, dan cocok dikirim lewat WhatsApp.\n\n" +
      "Gunakan struktur WAJIB dan URUT berikut (jangan tambah bagian lain):\n\n" +
      "1. Rangkuman Mingguan (Analisa Singkat)\n" +
      "- Maksimal 2 kalimat\n" +
      "- Sebutkan: untung/rugi, jumlahnya, dan perbandingan dengan minggu sebelumnya (jika ada)\n\n" +
      "2. Grafik Teks (bukan gambar)\n" +
      "- Gunakan simbol █\n" +
      "- Ukuran kecil dan mudah di-screenshot\n" +
      "- Tampilkan tren UNTUNG dari data mingguan\n\n" +
      "3. Masalah yang Mungkin\n" +
      "- Bullet point pendek (2–3 poin)\n" +
      "- Fokus ke masalah utama\n\n" +
      "4. Saran Praktis\n" +
      "- Bullet point\n" +
      "- Setiap saran WAJIB ada 'Cara melakukannya'\n" +
      "- Harus mudah dilakukan, tanpa teori\n\n" +
      "Gaya bahasa:\n" +
      "- Bahasa Indonesia sangat sederhana\n" +
      "- Seperti ngobrol dengan teman\n" +
      "- Jangan panjang dan jangan formal\n" +
      "- Harus enak di-copy paste ke WhatsApp"
  );

  return lines.join("\n");
});

async function copyPromptToAi() {
  if (!aiPrompt.value) return;
  await navigator.clipboard.writeText(aiPrompt.value);
  toast.add({
    title: "Prompt Disalin",
    description: "Prompt AI telah disalin ke clipboard",
    color: "success",
  });
}

// Submit
const loading = ref(false);
async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true;
  try {
    if (reportId.value) {
      // Update existing report
      const payload: any = {
        periode_mulai: event.data.periode_mulai,
        periode_selesai: event.data.periode_selesai,
        uang_masuk: event.data.uang_masuk,
        uang_keluar: event.data.uang_keluar,
        masalah: event.data.masalah || null,
        saran: event.data.saran,
        is_partial: event.data.is_partial,
      };

      const { error } = await (supabase as any)
        .from("weekly_reports")
        .update(payload)
        .eq("id", reportId.value);

      if (error) throw error;

      toast.add({
        title: "Laporan Berhasil Diperbarui!",
        description: `Laporan untuk ${selectedUmkm.value?.nama_usaha} telah diperbarui`,
        color: "success",
        icon: "i-heroicons-check-circle",
      });

      router.push("/dashboard/laporan");
    } else {
      // Create new report (existing behavior)
      const { error } = await (supabase as any).from("weekly_reports").insert({
        umkm_id: event.data.umkm_id,
        periode_mulai: event.data.periode_mulai,
        periode_selesai: event.data.periode_selesai,
        uang_masuk: event.data.uang_masuk,
        uang_keluar: event.data.uang_keluar,
        masalah: event.data.masalah || null,
        saran: event.data.saran,
        is_partial: event.data.is_partial,
      });

      if (error) throw error;

      toast.add({
        title: "Laporan Berhasil Disimpan!",
        description: `Laporan untuk ${selectedUmkm.value?.nama_usaha} telah tersimpan`,
        color: "success",
        icon: "i-heroicons-check-circle",
      });

      router.push("/dashboard/laporan");
    }
  } catch (error: any) {
    toast.add({
      title: reportId.value ? "Gagal Memperbarui" : "Gagal Menyimpan",
      description: error.message,
      color: "error",
    });
  } finally {
    loading.value = false;
  }
}

// WhatsApp actions
function sendWhatsApp() {
  if (!selectedUmkm.value) return;
  const no = (selectedUmkm.value.no_wa || "").replace(/^0/, "62");
  const message = encodeURIComponent(whatsappPreview.value);
  window.open(`https://wa.me/${no}?text=${message}`, "_blank");
}

function copyToWhatsApp() {
  navigator.clipboard.writeText(whatsappPreview.value);
  toast.add({
    title: "Teks Disalin!",
    description: "Pesan WhatsApp siap dikirim",
    color: "success",
  });
}
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar
        :title="isEditing ? 'Edit Laporan Mingguan' : 'Input Laporan Mingguan'"
      >
        <template #right>
          <UButton
            to="/dashboard/laporan"
            variant="ghost"
            icon="i-heroicons-arrow-left"
            label="Kembali"
          />
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="text-sm text-muted">
            Isi laporan keuangan mingguan untuk satu UMKM
          </div>
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <!-- Full width di desktop, padding nyaman di mobile -->
      <div class="py-6 px-4 sm:px-6 lg:px-8">
        <div class="max-w-3xl mx-auto">
          <UForm
            :schema="schema"
            :state="state"
            @submit="onSubmit"
            class="space-y-8"
          >
            <!-- 1. Pilih UMKM -->
            <UCard class="shadow-sm">
              <template #header>
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-xl flex items-center justify-center shrink-0"
                  >
                    <span
                      class="text-blue-600 dark:text-blue-400 font-bold text-lg"
                      >1</span
                    >
                  </div>
                  <h3 class="font-semibold text-lg">Pilih UMKM</h3>
                </div>
              </template>

              <UFormField label="UMKM" name="umkm_id" required>
                <USelectMenu
                  v-model="selectedUmkmItem"
                  :items="
                    umkmList?.map((u) => ({
                      label: `${u.nama_usaha} — ${u.nama_pemilik}`,
                      value: u.id,
                      description:
                        u.status.charAt(0).toUpperCase() + u.status.slice(1),
                    })) || []
                  "
                  placeholder="Cari dan pilih UMKM..."
                  searchable
                  class="w-full"
                />
              </UFormField>
            </UCard>

            <!-- 2. Data Keuangan -->
            <UCard v-if="state.umkm_id" class="shadow-sm">
              <template #header>
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-xl flex items-center justify-center shrink-0"
                  >
                    <span
                      class="text-green-600 dark:text-green-400 font-bold text-lg"
                      >2</span
                    >
                  </div>
                  <h3 class="font-semibold text-lg">Data Keuangan Mingguan</h3>
                </div>
              </template>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <UFormField
                  label="Periode Mulai (Senin)"
                  name="periode_mulai"
                  required
                >
                  <UInput
                    v-model="state.periode_mulai"
                    type="date"
                    class="w-full"
                  />
                </UFormField>
                <UFormField
                  label="Periode Selesai (Minggu)"
                  name="periode_selesai"
                  required
                >
                  <UInput
                    v-model="state.periode_selesai"
                    type="date"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="Uang Masuk" name="uang_masuk" required>
                  <UInput
                    v-model.number="state.uang_masuk"
                    type="number"
                    placeholder="0"
                    class="w-full"
                  >
                    <template #leading>
                      <span class="text-gray-500 dark:text-gray-400">Rp</span>
                    </template>
                  </UInput>
                </UFormField>

                <UFormField label="Uang Keluar" name="uang_keluar" required>
                  <UInput
                    v-model.number="state.uang_keluar"
                    type="number"
                    placeholder="0"
                    class="w-full"
                  >
                    <template #leading>
                      <span class="text-gray-500 dark:text-gray-400">Rp</span>
                    </template>
                  </UInput>
                </UFormField>
              </div>

              <UAlert
                class="mt-6"
                :color="untungRugi >= 0 ? 'success' : 'error'"
                variant="soft"
                :icon="
                  untungRugi >= 0
                    ? 'i-heroicons-arrow-trending-up'
                    : 'i-heroicons-arrow-trending-down'
                "
                :title="`${
                  untungRugi >= 0 ? 'Untung' : 'Rugi'
                } ${new Intl.NumberFormat('id-ID', {
                  style: 'currency',
                  currency: 'IDR',
                  minimumFractionDigits: 0,
                }).format(Math.abs(untungRugi))}`"
              />

              <UFormField class="mt-5">
                <UCheckbox
                  v-model="state.is_partial"
                  label="Laporan partial (minggu pertama atau trial)"
                />
              </UFormField>
            </UCard>

            <!-- 3. Analisis & Saran -->
            <UCard v-if="state.umkm_id" class="shadow-sm">
              <template #header>
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 bg-purple-100 dark:bg-purple-900/30 rounded-xl flex items-center justify-center shrink-0"
                  >
                    <span
                      class="text-purple-600 dark:text-purple-400 font-bold text-lg"
                      >3</span
                    >
                  </div>
                  <h3 class="font-semibold text-lg">
                    Analisis & Saran Praktis
                  </h3>
                </div>
              </template>
              <!-- AI Prompt actions -->
              <div class="flex items-center gap-2 mb-5">
                <UButton
                  size="sm"
                  color="neutral"
                  icon="i-heroicons-clipboard-document"
                  :disabled="
                    !state.umkm_id ||
                    !state.periode_mulai ||
                    !state.periode_selesai
                  "
                  @click.prevent="copyPromptToAi"
                >
                  Copy Prompt ke AI
                </UButton>

                <div class="text-sm text-muted">
                  Gunakan prompt ini untuk meminta analisis & saran otomatis ke
                  layanan AI.
                </div>
              </div>

              <div class="space-y-6">
                <UFormField
                  label="Masalah yang Ditemukan (Opsional)"
                  name="masalah"
                >
                  <UTextarea
                    v-model="state.masalah"
                    placeholder="Contoh: Stok sering habis di akhir minggu, pengeluaran listrik tinggi, dll."
                    :rows="4"
                    class="w-full"
                    autoresize
                  />
                </UFormField>

                <UFormField label="Saran Praktis" name="saran" required>
                  <UTextarea
                    v-model="state.saran"
                    placeholder="Contoh:\n• Tambah stok di awal minggu\n• Matikan lampu yang tidak perlu\n• Catat pengeluaran harian lebih teliti"
                    :rows="6"
                    class="w-full font-medium"
                    autoresize
                  />
                </UFormField>
              </div>
            </UCard>

            <!-- 4. Preview WhatsApp -->
            <UCard v-if="state.umkm_id && state.saran" class="shadow-sm">
              <template #header>
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 bg-amber-100 dark:bg-amber-900/30 rounded-xl flex items-center justify-center shrink-0"
                    >
                      <span
                        class="text-amber-600 dark:text-amber-400 font-bold text-lg"
                        >4</span
                      >
                    </div>
                    <h3 class="font-semibold text-lg">
                      Preview Pesan WhatsApp
                    </h3>
                  </div>
                  <div class="flex gap-2">
                    <UButton
                      @click="copyToWhatsApp"
                      icon="i-heroicons-clipboard-document"
                      label="Copy"
                      variant="soft"
                      size="sm"
                    />
                    <UButton
                      @click="sendWhatsApp"
                      icon="i-simple-icons-whatsapp"
                      label="Kirim WA"
                      color="success"
                      size="sm"
                    />
                  </div>
                </div>
              </template>

              <div
                class="bg-gray-50 dark:bg-gray-800/50 p-5 rounded-xl border border-gray-200 dark:border-gray-700"
              >
                <pre
                  class="whitespace-pre-wrap text-sm leading-relaxed font-sans"
                  >{{ whatsappPreview }}</pre
                >
              </div>
            </UCard>
            <!-- Submit Buttons -->
            <div class="flex flex-col sm:flex-row justify-end gap-4 pt-2">
              <UButton
                to="/dashboard/laporan"
                label="Batal"
                color="neutral"
                variant="subtle"
                class="w-full sm:w-auto"
              />
              <UButton
                type="submit"
                label="Simpan Laporan"
                color="success"
                size="lg"
                icon="i-heroicons-check"
                :loading="loading"
                :disabled="!state.umkm_id || !state.saran"
                class="w-full sm:w-auto"
              />
            </div>
          </UForm>
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
