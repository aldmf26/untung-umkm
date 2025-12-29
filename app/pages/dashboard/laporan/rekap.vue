<script setup lang="ts">
import type { Period, Range } from "~/types";
import { sub } from "date-fns";
import { getPaginationRowModel } from "@tanstack/table-core";
import type { TableColumn } from "@nuxt/ui";

definePageMeta({
  layout: "dashboard",
});
const UButton = resolveComponent("UButton");

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
    .select("id, nama_usaha, nama_pemilik, status")
    .order("tanggal_join", { ascending: false });

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

// Detail table: search + pagination
const tableDetail = ref<any>(null);
const detailSearch = ref("");
const detailPagination = ref({ pageIndex: 0, pageSize: 10 });

const detailColumns: TableColumn<any>[] = [
  {
    accessorKey: "No",
    header: "No",
    cell: ({ row }: any) => h("div", {}, row.index + 1),
  },
  {
    id: "nama_usaha",
    header: "UMKM",
    accessorFn: (row: any) => row.nama_usaha || "",
    cell: ({ row }) =>
      h("div", {}, [
        h("div", { class: "font-bold" }, row.original.nama_usaha || "-"),
        h(
          "div",
          { class: "text-sm text-muted" },
          row.original.nama_pemilik || "-"
        ),
      ]),
  },
  {
    accessorKey: "total_pembayaran",
    header: "Pembayaran",
    cell: ({ row }: any) =>
      h(
        "div",
        { class: "text-right text-success font-medium" },
        new Intl.NumberFormat("id-ID", {
          style: "currency",
          currency: "IDR",
          minimumFractionDigits: 0,
        }).format(row.original.total_pembayaran || 0)
      ),
  },
  {
    accessorKey: "total_masuk",
    header: "Uang Masuk",
    cell: ({ row }: any) =>
      h(
        "div",
        { class: "text-right text-info" },
        new Intl.NumberFormat("id-ID", {
          style: "currency",
          currency: "IDR",
          minimumFractionDigits: 0,
        }).format(row.original.total_masuk || 0)
      ),
  },
  {
    accessorKey: "total_keluar",
    header: "Uang Keluar",
    cell: ({ row }: any) =>
      h(
        "div",
        { class: "text-right text-orange-600" },
        new Intl.NumberFormat("id-ID", {
          style: "currency",
          currency: "IDR",
          minimumFractionDigits: 0,
        }).format(row.original.total_keluar || 0)
      ),
  },
  {
    accessorKey: "total_profit",
    header: "Profit",
    cell: ({ row }: any) => {
      const v = row.original.total_profit || 0;
      return h(
        "div",
        {
          class:
            "text-right font-semibold " +
            (v >= 0 ? "text-success" : "text-error"),
        },
        new Intl.NumberFormat("id-ID", {
          style: "currency",
          currency: "IDR",
          minimumFractionDigits: 0,
        }).format(v)
      );
    },
  },
  {
    accessorKey: "jumlah_laporan",
    header: "Laporan",
    cell: ({ row }: any) =>
      h("div", { class: "text-center" }, row.original.jumlah_laporan),
  },
  {
    id: "actions",
    header: "Aksi",
    cell: ({ row }: any) =>
      h(
        UButton,
        {
          size: "xs",
          variant: "ghost",
          onClick: () => router.push(`/dashboard/umkm/${row.original.id}`),
        },
        { default: () => "Lihat" }
      ),
  },
];

const filteredSummaries = computed(() => {
  const q = detailSearch.value.trim().toLowerCase();
  if (!q) return summaries.value;
  return summaries.value.filter(
    (s: any) =>
      (s.nama_usaha || "").toLowerCase().includes(q) ||
      (s.nama_pemilik || "").toLowerCase().includes(q)
  );
});

function fmtMoney(n: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(n);
}

useHead({
  title: "Rekap Laporan Mingguan",
});
</script>

<template>
  <UDashboardPage>
    <UDashboardPanel grow>
      <UDashboardToolbar>
        <template #left>
          <HomeDateRangePicker v-model="range" />
          <HomePeriodSelect v-model="period" :range="range" />
        </template>
      </UDashboardToolbar>

      <UDashboardPanelContent>
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <UCard class="bg-elevated rounded-lg border shadow-sm">
            <div class="flex items-start justify-between">
              <div class="">
                <p class="text-sm">Total Pembayaran</p>
                <p class="text-2xl font-bold text-success mt-2">
                  {{ fmtMoney(totalPembayaranAll) }}
                </p>
                <p class="text-xs text-muted mt-1">Dari klien ke admin</p>
              </div>
            </div>
          </UCard>

          <UCard class="bg-elevated rounded-lg border shadow-sm">
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm">Total Uang Masuk</p>
                <p class="text-2xl font-bold text-info mt-2">
                  {{ fmtMoney(totalMasukAll) }}
                </p>
                <p class="text-xs text-muted mt-1">Pendapatan UMKM</p>
              </div>
            </div>
          </UCard>

          <UCard class="bg-elevated rounded-lg border shadow-sm">
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm">Total Uang Keluar</p>
                <p class="text-2xl font-bold text-orange-600 mt-2">
                  {{ fmtMoney(totalKeluarAll) }}
                </p>
                <p class="text-xs text-muted mt-1">Pengeluaran UMKM</p>
              </div>
            </div>
          </UCard>

          <UCard class="bg-elevated rounded-lg border shadow-sm">
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm">Total Profit</p>
                <p
                  class="text-2xl font-bold mt-2"
                  :class="
                    totalProfitAll >= 0 ? 'text-success' : 'text-error'
                  "
                >
                  {{ fmtMoney(totalProfitAll) }}
                </p>
                <p class="text-xs text-muted mt-1">Untung/Rugi Gabungan</p>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Top Performers -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
          <!-- Top by Profit -->
          <UCard class="bg-elevated rounded-lg border shadow-sm">
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
                    class="w-8 h-8 rounded-full bg-success text-white flex items-center justify-center font-bold text-sm"
                  >
                    {{ idx + 1 }}
                  </div>
                  <div>
                    <p class="font-medium text-sm">{{ item.nama_usaha }}</p>
                    <p class="text-xs text-muted">
                      {{ item.jumlah_laporan }} laporan
                    </p>
                  </div>
                </div>
                <div class="text-right">
                  <p
                    class="font-semibold text-sm"
                    :class="
                      item.total_profit >= 0 ? 'text-success' : 'text-error'
                    "
                  >
                    {{ fmtMoney(item.total_profit) }}
                  </p>
                </div>
              </NuxtLink>
            </div>
          </UCard>

          <!-- Top by Pembayaran -->
          <UCard class="bg-elevated rounded-lg border shadow-sm">
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
                    class="w-8 h-8 rounded-full bg-success flex items-center justify-center text-white font-bold text-sm"
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
                  <p class="font-semibold text-sm text-success">
                    {{ fmtMoney(item.total_pembayaran) }}
                  </p>
                </div>
              </div>
            </div>
          </UCard>

          <!-- Top by Pendapatan -->
          <UCard class="bg-elevated rounded-lg border shadow-sm">
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
                    class="w-8 h-8 rounded-full bg-success text-white flex items-center justify-center font-bold text-sm"
                  >
                    {{ idx + 1 }}
                  </div>
                  <div>
                    <p class="font-medium text-sm">{{ item.nama_usaha }}</p>
                    <p class="text-xs text-muted">
                      Avg: {{ fmtMoney(item.avg_profit) }}
                    </p>
                  </div>
                </div>
                <div class="text-right">
                  <p class="font-semibold text-sm text-info">
                    {{ fmtMoney(item.total_masuk) }}
                  </p>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <UCard class="bg-elevated rounded-lg border shadow-sm">
          <template #header>
            <div class="flex items-center justify-between w-full">
              <h3 class="font-semibold">Detail Per UMKM</h3>

              <div class="flex items-center gap-2">
                <UInput
                  v-model="detailSearch"
                  class="max-w-sm"
                  size="sm"
                  icon="i-lucide-search"
                  placeholder="Cari UMKM..."
                />
              </div>
            </div>
          </template>

          <div class="overflow-auto rounded-lg p-2">
            <UTable
              ref="tableDetail"
              :data="filteredSummaries"
              :columns="detailColumns"
              v-model:pagination="detailPagination"
              :getPaginationRowModel="getPaginationRowModel"
            >
              <template #empty-state>
                <div class="text-center py-12 text-gray-500">
                  <UIcon
                    name="i-heroicons-document-text"
                    class="text-4xl mb-4"
                  />
                  <p class="font-medium">Tidak ada data untuk range ini.</p>
                </div>
              </template>
            </UTable>
          </div>

          <div
            class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-auto"
          >
            <div class="text-sm text-muted">
              {{
                tableDetail?.tableApi?.getFilteredSelectedRowModel().rows
                  .length || 0
              }}
              of
              {{
                tableDetail?.tableApi?.getFilteredRowModel().rows.length || 0
              }}
              row(s) selected.
            </div>

            <div class="flex items-center gap-1.5">
              <UPagination
                :default-page="
                  (tableDetail?.tableApi?.getState().pagination.pageIndex ||
                    0) + 1
                "
                :items-per-page="
                  tableDetail?.tableApi?.getState().pagination.pageSize
                "
                :total="
                  tableDetail?.tableApi?.getFilteredRowModel().rows.length
                "
                @update:page="(p: number) => tableDetail?.tableApi?.setPageIndex(p - 1)"
              />
            </div>
          </div>
        </UCard>
      </UDashboardPanelContent>
    </UDashboardPanel>
  </UDashboardPage>
</template>
