<script setup lang="ts">
import { useRoute, useRouter } from "vue-router";
const route = useRoute();
const router = useRouter();
const id = route.params.id as string;

const { data: umkmData, refresh: refreshUmkm } = await useAsyncData(
  ["umkm-profile", id],
  async () => {
    const supabase = useSupabaseClient();
    const { data, error } = await supabase
      .from("umkm_profiles")
      .select("*")
      .eq("id", id)
      .limit(1)
      .single();
    if (error) throw error;
    return data;
  }
);

const { data: reportsData, refresh: refreshReports } = await useAsyncData(
  ["weekly-reports", id],
  async () => {
    const supabase = useSupabaseClient();
    const { data, error } = await supabase
      .from("weekly_reports")
      .select("*")
      .eq("umkm_id", id)
      .order("periode_mulai", { ascending: false });
    if (error) throw error;
    return data || [];
  }
);

function fmtDate(d: string | null) {
  if (!d) return "-";
  return new Date(d).toLocaleDateString("id-ID");
}

function openWaForProfile() {
  const no = (umkmData.value?.no_wa || "").replace(/^0/, "62");
  if (!no) {
    useToast().add({ title: "Nomor WA tidak tersedia", color: "warning" });
    return;
  }
  const msg = encodeURIComponent(
    `Halo ${umkmData.value.nama_pemilik}, ini ringkasan laporan Anda.`
  );
  window.open(`https://wa.me/${no}?text=${msg}`, "_blank");
}

function goToAddLaporan() {
  router.push({ path: "/dashboard/laporan/input", query: { umkm_id: id } });
}
</script>

<template>
  <UDashboardPanel
    :title="umkmData?.nama_usaha || 'UMKM'"
    description="Detail UMKM & Riwayat Laporan"
  >
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 p-4">
      <div class="lg:col-span-1 bg-elevated border rounded p-4">
        <div class="text-sm text-muted">Pemilik</div>
        <div class="font-semibold text-lg">{{ umkmData?.nama_pemilik }}</div>

        <div class="mt-3 text-sm text-muted">WA</div>
        <div class="font-mono">{{ umkmData?.no_wa || "-" }}</div>

        <div class="mt-3 text-sm text-muted">Status</div>
        <UBadge
          :color="
            umkmData?.status === 'active'
              ? 'success'
              : umkmData?.status === 'trial'
              ? 'warning'
              : 'error'
          "
          class="capitalize"
          >{{ umkmData?.status }}</UBadge
        >

        <div class="mt-4 flex gap-2">
          <UButton
            label="Tambah Laporan"
            color="success"
            @click="goToAddLaporan"
          />
          <UButton label="Kirim WA" variant="ghost" @click="openWaForProfile" />
        </div>
      </div>

      <div class="lg:col-span-2 bg-elevated border rounded p-4">
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm text-muted">Riwayat Laporan</div>
            <div class="text-lg font-medium">Laporan Mingguan</div>
          </div>
        </div>

        <div class="mt-4 overflow-auto">
          <table class="min-w-full text-sm">
            <thead class="text-left text-muted text-xs">
              <tr>
                <th class="pb-2">Periode</th>
                <th class="pb-2">Masuk</th>
                <th class="pb-2">Keluar</th>
                <th class="pb-2">Untung/Rugi</th>
                <th class="pb-2">Aksi</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in reportsData" :key="r.id" class="border-t">
                <td class="py-2">
                  {{ fmtDate(r.periode_mulai) }} —
                  {{ fmtDate(r.periode_selesai) }}
                </td>
                <td class="py-2">
                  Rp {{ Number(r.uang_masuk).toLocaleString("id-ID") }}
                </td>
                <td class="py-2">
                  Rp {{ Number(r.uang_keluar).toLocaleString("id-ID") }}
                </td>
                <td class="py-2">
                  Rp {{ Number(r.untung_rugi).toLocaleString("id-ID") }}
                </td>
                <td class="py-2">
                  <div class="flex gap-2">
                    <UButton size="xs" variant="ghost">Lihat</UButton>
                    <!-- Expand: add edit/delete actions in next iteration -->
                  </div>
                </td>
              </tr>
              <tr v-if="(reportsData || []).length === 0">
                <td class="py-4 text-muted" colspan="5">
                  Belum ada laporan untuk UMKM ini.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </UDashboardPanel>
</template>
