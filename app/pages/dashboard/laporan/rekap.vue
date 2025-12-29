<script setup lang="ts">
import type { Period, Range } from "~/types";
import { sub } from "date-fns";

definePageMeta({
  layout: "dashboard",
});

const supabase = useSupabaseClient();
const router = useRouter();

const range = ref<Range>({
  start: sub(new Date(), { days: 30 }),
  end: new Date(),
});
const period = ref<Period>("daily");

// Load UMKM data
const { data: umkmData } = await useAsyncData("rekap-umkm", async () => {
  const { data } = await supabase
    .from("umkm_profiles")
    .select("id, nama_usaha, nama_pemilik, status");
  return data || [];
});

// Load payments in range
const { data: paymentsData, refresh: refreshPayments } = await useAsyncData(
  "rekap-payments",
  async () => {
    const start = range.value.start.toISOString().split("T")[0];
    const end = range.value.end.toISOString().split("T")[0];
    const { data } = await supabase
      .from("payments")
      .select("umkm_id, jumlah, tanggal_bayar")
      .gte("tanggal_bayar", start)
      .lte("tanggal_bayar", end);
    return data || [];
  }
);

// Load reports in range
const { data: reportsData, refresh: refreshReports } = await useAsyncData(
  "rekap-reports",
  async () => {
    const start = range.value.start.toISOString().split("T")[0];
    const end = range.value.end.toISOString().split("T")[0];
    const { data } = await supabase
      .from("weekly_reports")
      .select("umkm_id, uang_masuk, uang_keluar, untung_rugi, periode_mulai")
      .gte("periode_mulai", start)
      .lte("periode_mulai", end);
    return data || [];
  }
);

watch(range, () => {
  refreshPayments();
  refreshReports();
});

// Compute summaries per UMKM
const summaries = computed(() => {
  const umkms = umkmData.value || [];
  const payments = paymentsData.value || [];
  const reports = reportsData.value || [];

  return umkms.map((u: any) => {
    const umkmPayments = payments.filter((p: any) => p.umkm_id === u.id);
    const umkmReports = reports.filter((r: any) => r.umkm_id === u.id);

    const totalPembayaran = umkmPayments.reduce(
      (sum, p: any) => sum + (p.jumlah || 0),
      0
    );
    const totalMasuk = umkmReports.reduce(
      (sum, r: any) => sum + (r.uang_masuk || 0),
      0
    );
    const totalKeluar = umkmReports.reduce(
      (sum, r: any) => sum + (r.uang_keluar || 0),
      0
    );
    const totalProfit = umkmReports.reduce(
      (sum, r: any) => sum + (r.untung_rugi || 0),
      0
    );
    const jumlahLaporan = umkmReports.length;

    return {
      id: u.id,
      nama_usaha: u.nama_usaha,
      nama_pemilik: u.nama_pemilik,
      status: u.status,
      total_pembayaran: totalPembayaran,
      total_masuk: totalMasuk,
      total_keluar: totalKeluar,
      total_profit: totalProfit,
      jumlah_laporan: jumlahLaporan,
      avg_profit: jumlahLaporan > 0 ? totalProfit / jumlahLaporan : 0,
    };
  });
});

// Global stats
const totalPembayaranAll = computed(() =>
  summaries.value.reduce((sum, s) => sum + s.total_pembayaran, 0)
);
const totalMasukAll = computed(() =>
  summaries.value.reduce((sum, s) => sum + s.total_masuk, 0)
);
const totalKeluarAll = computed(() =>
  summaries.value.reduce((sum, s) => sum + s.total_keluar, 0)
);
const totalProfitAll = computed(() =>
  summaries.value.reduce((sum, s) => sum + s.total_profit, 0)
);

// Top performers
const topByProfit = computed(() =>
  [...summaries.value]
    .sort((a, b) => b.total_profit - a.total_profit)
    .slice(0, 5)
);
const topByPembayaran = computed(() =>
  [...summaries.value]
    .sort((a, b) => b.total_pembayaran - a.total_pembayaran)
    .slice(0, 5)
);
const topByMasuk = computed(() =>
  [...summaries.value].sort((a, b) => b.total_masuk - a.total_masuk).slice(0, 5)
);

function fmtMoney(n: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(n);
}
</script>

<template>
  <UDashboardPage>
    <UDashboardPanel grow>
      <UDashboardNavbar title="Rekap & Analisis UMKM" />

      <UDashboardToolbar>
        <template #left>
          <HomeDateRangePicker v-model="range" />
          <HomePeriodSelect v-model="period" :range="range" />
        </template>
      </UDashboardToolbar>

      <UDashboardPanelContent>
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <UCard>
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm text-gray-600">Total Pembayaran</p>
                <p class="text-2xl font-bold text-green-600 mt-2">
                  {{ fmtMoney(totalPembayaranAll) }}
                </p>
                <p class="text-xs text-gray-500 mt-1">Dari klien ke admin</p>
              </div>
            </div>
          </UCard>

          <UCard>
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm text-gray-600">Total Uang Masuk</p>
                <p class="text-2xl font-bold text-blue-600 mt-2">
                  {{ fmtMoney(totalMasukAll) }}
                </p>
                <p class="text-xs text-gray-500 mt-1">Pendapatan UMKM</p>
              </div>
            </div>
          </UCard>

          <UCard>
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm text-gray-600">Total Uang Keluar</p>
                <p class="text-2xl font-bold text-orange-600 mt-2">
                  {{ fmtMoney(totalKeluarAll) }}
                </p>
                <p class="text-xs text-gray-500 mt-1">Pengeluaran UMKM</p>
              </div>
            </div>
          </UCard>

          <UCard>
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm text-gray-600">Total Profit</p>
                <p
                  class="text-2xl font-bold mt-2"
                  :class="
                    totalProfitAll >= 0 ? 'text-green-600' : 'text-red-600'
                  "
                >
                  {{ fmtMoney(totalProfitAll) }}
                </p>
                <p class="text-xs text-gray-500 mt-1">Untung/Rugi Gabungan</p>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Top Performers -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
          <!-- Top by Profit -->
          <UCard>
            <template #header>
              <div class="flex items-center justify-between">
                <h3 class="font-semibold">🏆 Top 5 Profit Terbesar</h3>
              </div>
            </template>

            <div class="space-y-3">
              <NuxtLink
                v-for="(item, idx) in topByProfit"
                :key="item.id"
                class="flex items-center justify-between p-3 transition-colors cursor-pointer"
                :to="`/dashboard/umkm/${item.id}`"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-8 h-8 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center text-white font-bold text-sm"
                  >
                    {{ idx + 1 }}
                  </div>
                  <div>
                    <p class="font-medium text-sm">{{ item.nama_usaha }}</p>
                    <p class="text-xs text-gray-500">
                      {{ item.jumlah_laporan }} laporan
                    </p>
                  </div>
                </div>
                <div class="text-right">
                  <p
                    class="font-semibold text-sm"
                    :class="
                      item.total_profit >= 0 ? 'text-green-600' : 'text-red-600'
                    "
                  >
                    {{ fmtMoney(item.total_profit) }}
                  </p>
                </div>
              </NuxtLink>
            </div>
          </UCard>

          <!-- Top by Pembayaran -->
          <UCard>
            <template #header>
              <h3 class="font-semibold">💰 Top 5 Pembayaran Tertinggi</h3>
            </template>

            <div class="space-y-3">
              <div
                v-for="(item, idx) in topByPembayaran"
                :key="item.id"
                class="flex items-center justify-between p-3 transition-colors cursor-pointer"
                @click="router.push(`/dashboard/umkm/${item.id}`)"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-8 h-8 rounded-full bg-gradient-to-br from-green-400 to-emerald-500 flex items-center justify-center text-white font-bold text-sm"
                  >
                    {{ idx + 1 }}
                  </div>
                  <div>
                    <p class="font-medium text-sm">{{ item.nama_usaha }}</p>
                    <UBadge
                      :color="
                        item.status === 'active'
                          ? 'success'
                          : item.status === 'trial'
                          ? 'warning'
                          : 'error'
                      "
                      variant="soft"
                      size="sm"
                    >
                      {{ item.status }}
                    </UBadge>
                  </div>
                </div>
                <div class="text-right">
                  <p class="font-semibold text-sm text-green-600">
                    {{ fmtMoney(item.total_pembayaran) }}
                  </p>
                </div>
              </div>
            </div>
          </UCard>

          <!-- Top by Pendapatan -->
          <UCard>
            <template #header>
              <h3 class="font-semibold">📈 Top 5 Pendapatan Terbesar</h3>
            </template>

            <div class="space-y-3">
              <div
                v-for="(item, idx) in topByMasuk"
                :key="item.id"
                class="flex items-center justify-between p-3 transition-colors cursor-pointer"
                @click="router.push(`/dashboard/umkm/${item.id}`)"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-cyan-500 flex items-center justify-center text-white font-bold text-sm"
                  >
                    {{ idx + 1 }}
                  </div>
                  <div>
                    <p class="font-medium text-sm">{{ item.nama_usaha }}</p>
                    <p class="text-xs text-gray-500">
                      Avg: {{ fmtMoney(item.avg_profit) }}
                    </p>
                  </div>
                </div>
                <div class="text-right">
                  <p class="font-semibold text-sm text-blue-600">
                    {{ fmtMoney(item.total_masuk) }}
                  </p>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Detail Table -->
        <UCard>
          <template #header>
            <h3 class="font-semibold">Detail Per UMKM</h3>
          </template>

          <div class="overflow-x-auto">
            <table class="min-w-full divide-y">
              <thead class="">
                <tr>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                  >
                    UMKM
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                  >
                    Status
                  </th>
                  <th
                    class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase"
                  >
                    Pembayaran
                  </th>
                  <th
                    class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase"
                  >
                    Uang Masuk
                  </th>
                  <th
                    class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase"
                  >
                    Uang Keluar
                  </th>
                  <th
                    class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase"
                  >
                    Profit
                  </th>
                  <th
                    class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase"
                  >
                    Laporan
                  </th>
                  <th
                    class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase"
                  >
                    Aksi
                  </th>
                </tr>
              </thead>
              <tbody class="">
                <tr v-for="item in summaries" :key="item.id">
                  <td class="px-4 py-3">
                    <div>
                      <p class="font-medium text-sm">{{ item.nama_usaha }}</p>
                      <p class="text-xs text-gray-500">
                        {{ item.nama_pemilik }}
                      </p>
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <UBadge
                      :color="
                        item.status === 'active'
                          ? 'success'
                          : item.status === 'trial'
                          ? 'warning'
                          : 'error'
                      "
                      variant="soft"
                      size="md"
                    >
                      {{ item.status }}
                    </UBadge>
                  </td>
                  <td
                    class="px-4 py-3 text-right text-sm font-medium text-green-600"
                  >
                    {{ fmtMoney(item.total_pembayaran) }}
                  </td>
                  <td class="px-4 py-3 text-right text-sm text-blue-600">
                    {{ fmtMoney(item.total_masuk) }}
                  </td>
                  <td class="px-4 py-3 text-right text-sm text-orange-600">
                    {{ fmtMoney(item.total_keluar) }}
                  </td>
                  <td
                    class="px-4 py-3 text-right text-sm font-semibold"
                    :class="
                      item.total_profit >= 0 ? 'text-green-600' : 'text-red-600'
                    "
                  >
                    {{ fmtMoney(item.total_profit) }}
                  </td>
                  <td class="px-4 py-3 text-center text-sm">
                    {{ item.jumlah_laporan }}
                  </td>
                  <td class="px-4 py-3 text-center">
                    <UButton
                      size="xs"
                      variant="ghost"
                      @click="router.push(`/dashboard/umkm/${item.id}`)"
                    >
                      Lihat
                    </UButton>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </UCard>
      </UDashboardPanelContent>
    </UDashboardPanel>
  </UDashboardPage>
</template>
