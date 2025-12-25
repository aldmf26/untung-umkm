<script setup lang="ts">
import * as z from "zod";
import type { FormSubmitEvent } from "@nuxt/ui";

definePageMeta({ layout: "dashboard" });

const supabase = useSupabaseClient();
const route = useRoute();
const router = useRouter();
const toast = useToast();

// Schema validasi
const schema = z.object({
  umkm_id: z.string().min(1, "Pilih UMKM"),
  jumlah: z.number().min(1, "Jumlah minimal 1"),
  tanggal_bayar: z.string().min(1, "Tanggal bayar wajib"),
  periode: z.string().optional(),
  keterangan: z.string().optional(),
});

type Schema = z.output<typeof schema>;

// Load list UMKM
const { data: umkmList } = await useAsyncData(
  "umkm-list-payments",
  async () => {
    const { data } = await supabase
      .from("umkm_profiles")
      .select("id, nama_usaha, nama_pemilik, no_wa")
      .order("nama_usaha");
    return data || [];
  }
);

// State form
const state = reactive<Partial<Schema>>({
  umkm_id: (route.query.umkm_id as string) || undefined,
  jumlah: undefined,
  tanggal_bayar: undefined,
  periode: undefined,
  keterangan: undefined,
});

// Pilihan periode untuk field 'Periode (opsional)'
const periodOptions = [
  { label: "Mingguan", value: "Mingguan" },
  { label: "Bulanan", value: "Bulanan" },
];

// Quick payment options (dinamis) — klik salah satu akan mengisi `jumlah` dan `periode`
const quickOptions = [
  { id: "q1", amount: 40000, periode: "Mingguan" },
  { id: "q2", amount: 120000, periode: "Bulanan" },
];

const selectedQuick = computed(() => {
  return quickOptions.find(
    (q) => Number(state.jumlah) === q.amount && state.periode === q.periode
  );
});

function selectQuickOption(q: { id: string; amount: number; periode: string }) {
  state.jumlah = q.amount;
  state.periode = q.periode;
}

function fmtMoney(n: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(n);
}

onMounted(() => {
  if (!state.tanggal_bayar) {
    state.tanggal_bayar = new Date().toISOString().split("T")[0];
  }
});

const selectedUmkm = computed(() => {
  return umkmList.value?.find((u: any) => u.id === state.umkm_id);
});

// SelectItem mapping for USelectMenu: USelectMenu expects the selected item object
interface SelectItem {
  label: string;
  value: string;
  description?: string | null;
}

const selectedUmkmItem = computed<SelectItem | undefined>({
  get() {
    const id = state.umkm_id;
    const u = umkmList.value?.find((x: any) => x.id === id);
    if (!u) return undefined;
    return {
      label: `${u.nama_usaha} — ${u.nama_pemilik}`,
      value: u.id,
      description: u.no_wa || undefined,
    };
  },
  set(v) {
    state.umkm_id = (v as any)?.value;
  },
});

// Submit
const loading = ref(false);
async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true;
  try {
    const payload: any = {
      umkm_id: event.data.umkm_id,
      jumlah: event.data.jumlah,
      tanggal_bayar: event.data.tanggal_bayar,
      periode: event.data.periode || null,
      keterangan: event.data.keterangan || null,
    };

    const { error } = await supabase.from("payments").insert(payload as any);

    if (error) throw error;

    toast.add({
      title: "Pembayaran Tersimpan!",
      description: `Pembayaran untuk ${
        (selectedUmkm.value as any)?.nama_usaha
      } telah tercatat`,
      color: "success",
      icon: "i-heroicons-check-circle",
    });

    router.push("/dashboard/payments");
  } catch (error: any) {
    toast.add({
      title: "Gagal Menyimpan",
      description: error.message,
      color: "error",
    });
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Catat Pembayaran">
        <template #right>
          <UButton
            to="/dashboard/payments"
            variant="ghost"
            icon="i-heroicons-arrow-left"
            label="Kembali"
          />
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="text-sm text-muted">
            Form catat pembayaran, rapi dan senada dengan laporan
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
                      label: `${(u as any).nama_usaha} — ${(u as any).nama_pemilik}`,
                      value: (u as any).id,
                      description: (u as any).no_wa || undefined,
                    })) || []
                  "
                  placeholder="Cari dan pilih UMKM..."
                  searchable
                  class="w-full"
                />
              </UFormField>
            </UCard>

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
                  <h3 class="font-semibold text-lg">Detail Pembayaran</h3>
                </div>
              </template>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <UFormField label="Jumlah (Rp)" name="jumlah" required>
                  <UInput
                    v-model.number="state.jumlah"
                    type="number"
                    placeholder="40000"
                    class="w-full"
                  >
                    <template #leading>
                      <span class="text-gray-500 dark:text-gray-400">Rp</span>
                    </template>
                  </UInput>

                  <!-- Quick options (klik untuk isi jumlah & periode) -->
                  <div class="mt-2 flex items-center gap-2">
                    <UText variant="muted" class="text-sm">Cepat:</UText>
                    <div class="flex gap-2">
                      <UButton
                        v-for="q in quickOptions"
                        :key="q.id"
                        size="sm"
                        :color="
                          selectedQuick?.id === q.id ? 'success' : 'neutral'
                        "
                        variant="outline"
                        @click.prevent="selectQuickOption(q)"
                      >
                        <span class="font-medium">{{
                          fmtMoney(q.amount)
                        }}</span>
                        <span class="text-xs text-muted ml-2">{{
                          q.periode
                        }}</span>
                      </UButton>
                    </div>
                  </div>
                </UFormField>

                <UFormField label="Tanggal Bayar" name="tanggal_bayar" required>
                  <UInput
                    v-model="state.tanggal_bayar"
                    type="date"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="Periode (opsional)" name="periode">
                  <USelect
                    v-model="state.periode"
                    :items="periodOptions"
                    placeholder="Pilih periode"
                    class="w-full"
                  />
                </UFormField>

                <UFormField label="Keterangan (opsional)" name="keterangan">
                  <UTextarea
                    v-model="state.keterangan"
                    :rows="3"
                    placeholder="Contoh: Pembayaran bulan Desember"
                    autoresize
                    class="w-full"
                  />
                </UFormField>
              </div>
            </UCard>

            <div class="flex flex-col sm:flex-row justify-end gap-4 pt-2">
              <UButton
                to="/dashboard/payments"
                label="Batal"
                color="neutral"
                variant="subtle"
                class="w-full sm:w-auto"
              />
              <UButton
                type="submit"
                label="Simpan Pembayaran"
                color="success"
                size="lg"
                icon="i-heroicons-check"
                :loading="loading"
                :disabled="!state.umkm_id || !state.jumlah"
                class="w-full sm:w-auto"
              />
            </div>
          </UForm>
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
