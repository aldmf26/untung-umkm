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

// If `debt_id` is present in the query, we're editing an existing debt
const debtId = ref<string | null>(
  (route.query.debt_id as string) || (route.query.id as string) || null
);
const isEditing = computed(() => !!debtId.value);

// Schema validasi
const schema = z.object({
  umkm_id: z.string().min(1, "Pilih UMKM"),
  nama_debitur: z.string().min(1, "Nama debitur wajib diisi"),
  no_wa: z.string().optional(),
  jumlah: z.number().min(1, "Jumlah hutang minimal Rp 1"),
  tanggal_hutang: z.string().min(1, "Tanggal hutang wajib diisi"),
  jatuh_tempo: z.string().optional(),
  keterangan: z.string().optional(),
  status: z.enum(["belum_lunas", "lunas"]),
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
  nama_debitur: undefined,
  no_wa: undefined,
  jumlah: undefined,
  tanggal_hutang: undefined,
  jatuh_tempo: undefined,
  keterangan: undefined,
  status: "belum_lunas",
});

const selectedUmkm = computed(() => {
  return umkmList.value?.find((u) => u.id === state.umkm_id);
});

// SelectItem mapping for USelectMenu
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

// Set tanggal hari ini otomatis OR load debt if editing
onMounted(async () => {
  if (debtId.value) {
    try {
      const { data: d, error } = await (supabase as any)
        .from("debts")
        .select("*")
        .eq("id", debtId.value)
        .single();
      if (error) throw error;
      // Populate form state with existing values
      state.umkm_id = d.umkm_id;
      state.nama_debitur = d.nama_debitur;
      state.no_wa = d.no_wa || undefined;
      state.jumlah = Number(d.jumlah || 0);
      state.tanggal_hutang = d.tanggal_hutang;
      state.jatuh_tempo = d.jatuh_tempo || undefined;
      state.keterangan = d.keterangan || undefined;
      state.status = d.status || "belum_lunas";
    } catch (err: any) {
      toast.add({
        title: "Gagal memuat data hutang",
        description: err.message,
        color: "error",
      });
    }
  } else {
    // Set default date to today
    const today = new Date();
    state.tanggal_hutang = today.toISOString().split("T")[0];
  }

  // Respect incoming umkm_id query if present and not already set
  if (!state.umkm_id && route.query.umkm_id)
    state.umkm_id = route.query.umkm_id as string;
});

// Submit
const loading = ref(false);
async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true;
  try {
    if (debtId.value) {
      // Update existing debt
      const payload: any = {
        nama_debitur: event.data.nama_debitur,
        no_wa: event.data.no_wa || null,
        jumlah: event.data.jumlah,
        tanggal_hutang: event.data.tanggal_hutang,
        jatuh_tempo: event.data.jatuh_tempo || null,
        keterangan: event.data.keterangan || null,
        status: event.data.status,
      };

      // If marked as lunas, set tanggal_lunas
      if (event.data.status === "lunas") {
        payload.tanggal_lunas = new Date().toISOString().split("T")[0];
      }

      const { error } = await (supabase as any)
        .from("debts")
        .update(payload)
        .eq("id", debtId.value);

      if (error) throw error;

      toast.add({
        title: "Data Hutang Berhasil Diperbarui!",
        description: `Hutang ${event.data.nama_debitur} telah diperbarui`,
        color: "success",
        icon: "i-heroicons-check-circle",
      });

      router.push("/dashboard/hutang");
    } else {
      // Create new debt
      const { error } = await (supabase as any).from("debts").insert({
        umkm_id: event.data.umkm_id,
        nama_debitur: event.data.nama_debitur,
        no_wa: event.data.no_wa || null,
        jumlah: event.data.jumlah,
        tanggal_hutang: event.data.tanggal_hutang,
        jatuh_tempo: event.data.jatuh_tempo || null,
        keterangan: event.data.keterangan || null,
        status: event.data.status,
      });

      if (error) throw error;

      toast.add({
        title: "Hutang Berhasil Dicatat!",
        description: `Hutang ${event.data.nama_debitur} telah tersimpan`,
        color: "success",
        icon: "i-heroicons-check-circle",
      });

      router.push("/dashboard/hutang");
    }
  } catch (error: any) {
    toast.add({
      title: debtId.value ? "Gagal Memperbarui" : "Gagal Menyimpan",
      description: error.message,
      color: "error",
    });
  } finally {
    loading.value = false;
  }
}

// WhatsApp reminder
function sendWhatsAppReminder() {
  if (!state.no_wa || !selectedUmkm.value) return;

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
      month: "long",
      year: "numeric",
    }).format(new Date(dateStr));
  };

  const message = `Halo ${state.nama_debitur},

Ini adalah pengingat untuk hutang Anda di ${selectedUmkm.value.nama_usaha}:

💰 Jumlah: ${formatRupiah(state.jumlah || 0)}
📅 Tanggal Hutang: ${formatDate(state.tanggal_hutang!)}
${state.jatuh_tempo ? `⏰ Jatuh Tempo: ${formatDate(state.jatuh_tempo)}` : ""}

Mohon segera melakukan pembayaran. Terima kasih! 🙏`;

  const no = (state.no_wa || "").replace(/^0/, "62");
  const encodedMessage = encodeURIComponent(message);
  window.open(`https://wa.me/${no}?text=${encodedMessage}`, "_blank");
}

function copyWhatsAppMessage() {
  if (!selectedUmkm.value) return;

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
      month: "long",
      year: "numeric",
    }).format(new Date(dateStr));
  };

  const message = `Halo ${state.nama_debitur},

Ini adalah pengingat untuk hutang Anda di ${selectedUmkm.value.nama_usaha}:

💰 Jumlah: ${formatRupiah(state.jumlah || 0)}
📅 Tanggal Hutang: ${formatDate(state.tanggal_hutang!)}
${state.jatuh_tempo ? `⏰ Jatuh Tempo: ${formatDate(state.jatuh_tempo)}` : ""}

Mohon segera melakukan pembayaran. Terima kasih! 🙏`;

  navigator.clipboard.writeText(message);
  toast.add({
    title: "Teks Disalin!",
    description: "Pesan pengingat siap dikirim via WhatsApp",
    color: "success",
  });
}

useHead({
  title: isEditing.value ? "Edit Hutang" : "Catat Hutang Baru",
});
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar :title="isEditing ? 'Edit Data Hutang' : 'Catat Hutang Baru'">
        <template #right>
          <UButton
            to="/dashboard/hutang"
            variant="ghost"
            icon="i-heroicons-arrow-left"
            label="Kembali"
          />
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="text-sm text-muted">
            Catat hutang pelanggan untuk satu UMKM
          </div>
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
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
                    <span class="text-blue-600 dark:text-blue-400 font-bold text-lg">1</span>
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

            <!-- 2. Data Debitur -->
            <UCard v-if="state.umkm_id" class="shadow-sm">
              <template #header>
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 bg-red-100 dark:bg-red-900/30 rounded-xl flex items-center justify-center shrink-0"
                  >
                    <span class="text-red-600 dark:text-red-400 font-bold text-lg">2</span>
                  </div>
                  <h3 class="font-semibold text-lg">Data Orang Berhutang</h3>
                </div>
              </template>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <UFormField label="Nama Debitur" name="nama_debitur" required>
                  <UInput
                    v-model="state.nama_debitur"
                    placeholder="Nama orang yang berhutang"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="No. WhatsApp (Opsional)" name="no_wa">
                  <UInput
                    v-model="state.no_wa"
                    placeholder="08123456789"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="Jumlah Hutang" name="jumlah" required>
                  <UInput
                    v-model.number="state.jumlah"
                    type="number"
                    placeholder="0"
                    class="w-full"
                  >
                    <template #leading>
                      <span class="text-gray-500 dark:text-gray-400">Rp</span>
                    </template>
                  </UInput>
                </UFormField>

                <UFormField label="Tanggal Hutang" name="tanggal_hutang" required>
                  <UInput
                    v-model="state.tanggal_hutang"
                    type="date"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="Jatuh Tempo (Opsional)" name="jatuh_tempo">
                  <UInput
                    v-model="state.jatuh_tempo"
                    type="date"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="Status" name="status">
                  <USelect
                    v-model="state.status"
                    :items="[
                      { label: 'Belum Lunas', value: 'belum_lunas' },
                      { label: 'Lunas', value: 'lunas' },
                    ]"
                    class="w-full"
                  />
                </UFormField>
              </div>

              <UFormField label="Keterangan (Opsional)" name="keterangan" class="mt-5">
                <UTextarea
                  v-model="state.keterangan"
                  placeholder="Catatan tambahan tentang hutang ini..."
                  :rows="3"
                  class="w-full"
                  autoresize
                />
              </UFormField>

              <!-- Jumlah preview -->
              <UAlert
                v-if="state.jumlah"
                class="mt-6"
                color="warning"
                variant="soft"
                icon="i-heroicons-banknotes"
                :title="`Hutang: ${new Intl.NumberFormat('id-ID', {
                  style: 'currency',
                  currency: 'IDR',
                  minimumFractionDigits: 0,
                }).format(state.jumlah || 0)}`"
              />
            </UCard>

            <!-- 3. Pengingat WhatsApp -->
            <UCard v-if="state.umkm_id && state.nama_debitur && state.no_wa" class="shadow-sm">
              <template #header>
                <div class="flex items-center justify-between w-full">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-xl flex items-center justify-center shrink-0"
                    >
                      <span class="text-green-600 dark:text-green-400 font-bold text-lg">3</span>
                    </div>
                    <h3 class="font-semibold text-lg">Pengingat WhatsApp</h3>
                  </div>
                  <div class="flex gap-2">
                    <UButton
                      @click="copyWhatsAppMessage"
                      icon="i-heroicons-clipboard-document"
                      label="Copy"
                      variant="soft"
                      size="sm"
                    />
                    <UButton
                      @click="sendWhatsAppReminder"
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
                <pre class="whitespace-pre-wrap text-sm leading-relaxed font-sans">Halo {{ state.nama_debitur }},

Ini adalah pengingat untuk hutang Anda di {{ selectedUmkm?.nama_usaha }}:

💰 Jumlah: {{ new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(state.jumlah || 0) }}
📅 Tanggal Hutang: {{ state.tanggal_hutang ? new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(state.tanggal_hutang)) : '-' }}
{{ state.jatuh_tempo ? `⏰ Jatuh Tempo: ${new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(state.jatuh_tempo))}` : '' }}

Mohon segera melakukan pembayaran. Terima kasih! 🙏</pre>
              </div>
            </UCard>

            <!-- Submit Buttons -->
            <div class="flex flex-col sm:flex-row justify-end gap-4 pt-2">
              <UButton
                to="/dashboard/hutang"
                label="Batal"
                color="neutral"
                variant="subtle"
                class="w-full sm:w-auto"
              />
              <UButton
                type="submit"
                :label="isEditing ? 'Simpan Perubahan' : 'Simpan Hutang'"
                color="success"
                size="lg"
                icon="i-heroicons-check"
                :loading="loading"
                :disabled="!state.umkm_id || !state.nama_debitur || !state.jumlah"
                class="w-full sm:w-auto"
              />
            </div>
          </UForm>
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
