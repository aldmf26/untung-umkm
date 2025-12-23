<script setup lang="ts">
import type { Ref } from "vue";

definePageMeta({ layout: "dashboard" });

const toast = useToast();
const supabase = useSupabaseClient();
const router = useRouter();

const { data: reportsData, refresh: refreshReports } = await useAsyncData(
  "weekly-reports-list",
  async () => {
    const { data, error } = await supabase
      .from("weekly_reports")
      .select(
        "id, umkm_id, periode_mulai, periode_selesai, uang_masuk, uang_keluar, untung_rugi, created_at, umkm_profiles(id, nama_usaha, nama_pemilik, no_wa)"
      )
      .order("periode_mulai", { ascending: false });

    if (error) throw error;
    return data || [];
  }
);

const reports = computed(() => reportsData.value || []);

function fmtDate(d?: string) {
  if (!d) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(d));
}

function fmtMoney(n: number | string | null | undefined) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(Number(n || 0));
}

async function deleteReport(id: string) {
  const ok = confirm("Hapus laporan ini? Tindakan tidak dapat dibatalkan.");
  if (!ok) return;
  const { error } = await supabase.from("weekly_reports").delete().eq("id", id);
  if (error) {
    toast.add({
      title: "Gagal menghapus",
      description: error.message,
      color: "error",
    });
    return;
  }
  toast.add({
    title: "Terhapus",
    description: "Laporan telah dihapus",
    color: "success",
  });
  await refreshReports();
}

function goToUmkm(id: string) {
  router.push(`/dashboard/umkm/${id}`);
}

function goToInput(umkmId?: string) {
  const to = {
    path: "/dashboard/laporan/input",
    query: umkmId ? { umkm_id: umkmId } : {},
  };
  router.push(to);
}
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Laporan Mingguan">
        <template #right>
          <UButton
            label="Tambah Laporan"
            color="success"
            icon="i-heroicons-plus"
            @click="() => goToInput()"
          />
          <UButton label="Refresh" variant="ghost" @click="refreshReports" />
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="text-sm text-muted">Daftar laporan mingguan per UMKM</div>
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <div class="overflow-auto bg-elevated rounded-lg border p-4">
        <table class="min-w-full text-sm w-full">
          <thead class="text-left text-muted text-xs">
            <tr>
              <th class="pb-2">UMKM</th>
              <th class="pb-2">Periode</th>
              <th class="pb-2">Masuk</th>
              <th class="pb-2">Keluar</th>
              <th class="pb-2">Untung/Rugi</th>
              <th class="pb-2">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in reports" :key="r.id" class="border-t align-top">
              <td class="py-2">
                <div class="font-semibold">
                  {{ r.umkm_profiles?.nama_usaha || "-" }}
                </div>
                <div class="text-muted text-xs">
                  {{ r.umkm_profiles?.nama_pemilik || "-" }}
                </div>
              </td>
              <td class="py-2">
                {{ fmtDate(r.periode_mulai) }} —
                {{ fmtDate(r.periode_selesai) }}
              </td>
              <td class="py-2">{{ fmtMoney(r.uang_masuk) }}</td>
              <td class="py-2">{{ fmtMoney(r.uang_keluar) }}</td>
              <td class="py-2">{{ fmtMoney(r.untung_rugi) }}</td>
              <td class="py-2">
                <div class="flex gap-2">
                  <UButton
                    size="xs"
                    variant="ghost"
                    @click="() => goToUmkm(r.umkm_id)"
                    >Lihat UMKM</UButton
                  >
                  <UButton
                    size="xs"
                    color="error"
                    variant="ghost"
                    @click="() => deleteReport(r.id)"
                    >Hapus</UButton
                  >
                </div>
              </td>
            </tr>
            <tr v-if="(reports || []).length === 0">
              <td class="py-4 text-muted" colspan="6">Belum ada laporan.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </UDashboardPanel>
</template>
