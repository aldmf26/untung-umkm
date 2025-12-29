<script setup lang="ts">
import type { Ref } from "vue";

definePageMeta({
  layout: "dashboard",
  middleware: "auth",
});

const toast = useToast();
const supabase = useSupabaseClient();
const router = useRouter();

// Resolve components used in renderers and toolbar
const UButton = resolveComponent("UButton");
const UDropdownMenu = resolveComponent("UDropdownMenu");
const UInput = resolveComponent("UInput");
const USelect = resolveComponent("USelect");
const UCheckbox = resolveComponent("UCheckbox");
const UModal = resolveComponent("UModal");
const UCard = resolveComponent("UCard");
const UFormField = resolveComponent("UFormField");
const UTextarea = resolveComponent("UTextarea");
const UIcon = resolveComponent("UIcon");
const table = useTemplateRef("table");

// Table controls
const columnFilters = ref([]);
const columnVisibility = ref({});
const rowSelection = ref({});

// Edit modal state for reports
const editReportOpen = ref(false);
const editReport = reactive<any>({
  id: "",
  periode_mulai: "",
  periode_selesai: "",
  uang_masuk: 0,
  uang_keluar: 0,
  masalah: "",
  saran: "",
  is_partial: false,
});

function openEditReport(r: any) {
  Object.assign(editReport, {
    id: r.id,
    periode_mulai: r.periode_mulai,
    periode_selesai: r.periode_selesai,
    uang_masuk: Number(r.uang_masuk || 0),
    uang_keluar: Number(r.uang_keluar || 0),
    masalah: r.masalah || "",
    saran: r.saran || "",
    is_partial: !!r.is_partial,
  });
  editReportOpen.value = true;
}

async function saveEditReport() {
  try {
    const payload: any = {
      periode_mulai: editReport.periode_mulai,
      periode_selesai: editReport.periode_selesai,
      uang_masuk: editReport.uang_masuk,
      uang_keluar: editReport.uang_keluar,
      masalah: editReport.masalah || null,
      saran: editReport.saran,
      is_partial: editReport.is_partial,
    };

    const { error } = await (supabase as any)
      .from("weekly_reports")
      .update(payload)
      .eq("id", editReport.id);
    if (error) throw error;
    toast.add({ title: "Laporan diperbarui", color: "success" });
    editReportOpen.value = false;
    await refreshReports();
  } catch (error: any) {
    toast.add({ title: "Gagal", description: error.message, color: "error" });
  }
}

async function deleteSelectedReports() {
  const selected =
    table?.value?.tableApi?.getFilteredSelectedRowModel().rows || [];
  const ids = selected.map((r: any) => r.original.id);
  if (!ids.length) return;
  if (!confirm(`Hapus ${ids.length} laporan?`)) return;
  const { error } = await supabase
    .from("weekly_reports")
    .delete()
    .in("id", ids);
  if (error)
    return toast.add({
      title: "Gagal",
      description: error.message,
      color: "error",
    });
  toast.add({ title: `${ids.length} laporan dihapus`, color: "success" });
  await refreshReports();
}

function _buildCsv(rows: any[], headers: string[]) {
  const csv = [headers.join(",")]
    .concat(
      rows.map((r: any) =>
        headers
          .map((h) => {
            const v = r[h] ?? r[h] === 0 ? r[h] : "";
            return `"${(v ?? "").toString().replace(/"/g, '""')}"`;
          })
          .join(",")
      )
    )
    .join("\n");
  return csv;
}

function _downloadCsv(csv: string, filename: string) {
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

async function exportReportsXlsx() {
  try {
    const rows =
      table?.value?.tableApi
        ?.getFilteredRowModel()
        .rows?.map((r: any) => r.original) ||
      reports.value ||
      [];
    const dataRows = rows.map((r: any) => ({
      periode_mulai: r.periode_mulai,
      periode_selesai: r.periode_selesai,
      nama_usaha: r.umkm_profiles?.nama_usaha || "",
      nama_pemilik: r.umkm_profiles?.nama_pemilik || "",
      uang_masuk: Number(r.uang_masuk || 0),
      uang_keluar: Number(r.uang_keluar || 0),
      untung_rugi: Number(r.untung_rugi || 0),
      created_at: r.created_at || "",
    }));

    // @ts-ignore - exceljs may be an optional dependency; install if missing
    const mod: any = await import("exceljs");
    const Workbook =
      mod.Workbook || mod.default?.Workbook || mod.default || mod;
    const wb: any = new Workbook();
    const ws = wb.addWorksheet("Laporan");

    const headers = [
      "Periode Mulai",
      "Periode Selesai",
      "Nama Usaha",
      "Nama Pemilik",
      "Uang Masuk",
      "Uang Keluar",
      "Untung/Rugi",
      "Created At",
    ];
    ws.addRow(headers);

    const headerRow = ws.getRow(1);
    headerRow.font = { bold: true } as any;
    headerRow.alignment = { horizontal: "center", vertical: "middle" } as any;
    headerRow.eachCell((cell: any) => {
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" },
      };
    });

    dataRows.forEach((r: any) => {
      const row = ws.addRow([
        r.periode_mulai,
        r.periode_selesai,
        r.nama_usaha,
        r.nama_pemilik,
        r.uang_masuk,
        r.uang_keluar,
        r.untung_rugi,
        r.created_at,
      ]);
      // numeric columns
      (row.getCell(7) as any).numFmt = "#,##0";
      (row.getCell(8) as any).numFmt = "#,##0";
      (row.getCell(9) as any).numFmt = "#,##0";
    });

    ws.eachRow((row: any) => {
      row.eachCell((cell: any) => {
        cell.border = {
          top: { style: "thin" },
          left: { style: "thin" },
          bottom: { style: "thin" },
          right: { style: "thin" },
        };
      });
    });

    ws.columns.forEach((col: any) => {
      let max = 10;
      col.eachCell((cell: any) => {
        const v = (cell.value || "").toString();
        max = Math.max(max, v.length + 2);
      });
      col.width = Math.min(max, 50);
    });

    const buf = await wb.xlsx.writeBuffer();
    const blob = new Blob([buf], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    const label =
      typeof dateRangeLabel?.value === "string"
        ? dateRangeLabel.value.replace(/\s+/g, "_")
        : "range";
    a.href = url;
    a.download = `laporan_${label}.xlsx`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  } catch (err: any) {
    console.error(err);
    toast.add({
      title: "Gagal mengekspor",
      description: "Install paket exceljs (pnpm add exceljs) atau coba lagi",
      color: "error",
    });
  }
}

import type { TableColumn } from "@nuxt/ui";
import { getPaginationRowModel } from "@tanstack/table-core";
import type { Row } from "@tanstack/table-core";

import { useDateFilter } from "~/composables/useDateFilter";
const df = useDateFilter();
const {
  dateFilterType,
  selectedMonth,
  selectedYear,
  fromDate,
  toDate,
  apply: applyDateFilterCb,
  reset: resetDateFilterCb,
  setMonthRangeFromSelectedMonth,
  label: dateRangeLabel,
} = df;

const { data: reportsData, refresh: refreshReports } = await useAsyncData(
  () => `weekly-reports-list:${fromDate.value}:${toDate.value}`,
  async () => {
    let query: any = supabase
      .from("weekly_reports")
      .select(
        "id, umkm_id, periode_mulai, periode_selesai, uang_masuk, uang_keluar, untung_rugi, created_at, umkm_profiles(id, nama_usaha, nama_pemilik, no_wa)"
      )
      .order("periode_mulai", { ascending: false });

    if (fromDate.value) query = query.gte("periode_mulai", fromDate.value);
    if (toDate.value) query = query.lte("periode_mulai", toDate.value);

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  }
);

async function applyDateFilter() {
  await applyDateFilterCb(refreshReports);
}

async function resetDateFilter() {
  await resetDateFilterCb(refreshReports);
}

const reports = computed(() => reportsData.value || []);

interface Report {
  id: string;
  umkm_id: string;
  periode_mulai: string;
  periode_selesai: string;
  uang_masuk: number;
  uang_keluar: number;
  untung_rugi: number;
  umkm_profiles?: { id: string; nama_usaha: string; nama_pemilik: string };
}

const columns: TableColumn<Report>[] = [
  {
    id: "select",
    header: ({ table }) =>
      h(UCheckbox, {
        modelValue: table.getIsSomePageRowsSelected()
          ? "indeterminate"
          : table.getIsAllPageRowsSelected(),
        "onUpdate:modelValue": (v: boolean | "indeterminate") =>
          table.toggleAllPageRowsSelected(!!v),
        ariaLabel: "Select all",
      }),
    cell: ({ row }) =>
      h(UCheckbox, {
        modelValue: row.getIsSelected(),
        "onUpdate:modelValue": (v: boolean | "indeterminate") =>
          row.toggleSelected(!!v),
        ariaLabel: "Select row",
      }),
  },
  {
    accessorKey: "umkm",
    header: "UMKM",
    accessorFn: (r: Report) => r.umkm_profiles?.nama_usaha || "",
    cell: ({ row }) =>
      h("div", { class: "" }, [
        h(
          "div",
          { class: "font-semibold" },
          row.original.umkm_profiles?.nama_usaha || "-"
        ),
        h(
          "div",
          { class: "text-muted text-xs" },
          row.original.umkm_profiles?.nama_pemilik || "-"
        ),
      ]),
  },

  {
    id: "periode",
    header: "Periode",
    accessorFn: (r: Report) => `${r.periode_mulai} — ${r.periode_selesai}`,
    cell: ({ row }) =>
      `${row.original.periode_mulai} — ${row.original.periode_selesai}`,
  },
  {
    accessorKey: "uang_masuk",
    header: "Masuk",
    cell: ({ row }) =>
      new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
        minimumFractionDigits: 0,
      }).format(row.original.uang_masuk || 0),
  },
  {
    accessorKey: "uang_keluar",
    header: "Keluar",
    cell: ({ row }) =>
      new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
        minimumFractionDigits: 0,
      }).format(row.original.uang_keluar || 0),
  },
  {
    accessorKey: "untung_rugi",
    header: "Untung/Rugi",
    cell: ({ row }) =>
      row.original.untung_rugi >= 0
        ? h(
            "span",
            { class: "text-green-500" },
            `+${new Intl.NumberFormat("id-ID", {
              style: "currency",
              currency: "IDR",
              minimumFractionDigits: 0,
            }).format(row.original.untung_rugi || 0)}`
          )
        : h(
            "span",
            { class: "text-red-500" },
            `-${new Intl.NumberFormat("id-ID", {
              style: "currency",
              currency: "IDR",
              minimumFractionDigits: 0,
            }).format(Math.abs(row.original.untung_rugi) || 0)}`
          ),
  },
  {
    id: "actions",
    header: "Aksi",
    cell: ({ row }) =>
      h("div", { class: "flex gap-2" }, [
        h(
          UButton,
          {
            size: "xs",
            variant: "ghost",
            // Navigate to input page and pass report id + umkm id so the input page can load for editing
            onClick: () => goToInput(row.original.umkm_id, row.original.id),
          },
          { default: () => "Edit" }
        ),
        h(
          UButton,
          {
            size: "xs",
            variant: "ghost",
            onClick: () =>
              router.push(`/dashboard/umkm/${row.original.umkm_id}`),
          },
          { default: "Lihat" }
        ),
        h(UButton, {
          icon: "i-heroicons-trash",
          color: "error",
          variant: "ghost",
          size: "xs",
          onClick: async () => {
            if (!confirm("Hapus laporan ini?")) return;
            const { error } = await supabase
              .from("weekly_reports")
              .delete()
              .eq("id", row.original.id);
            if (error)
              return toast.add({
                title: "Gagal",
                description: error.message,
                color: "error",
              });
            toast.add({ title: "Terhapus", color: "success" });
            refreshReports();
          },
        }),
      ]),
  },
];

const searchQuery = computed({
  get: (): string =>
    (table.value?.tableApi?.getColumn("umkm")?.getFilterValue() as string) ||
    "",
  set: (value: string) =>
    table.value?.tableApi
      ?.getColumn("umkm")
      ?.setFilterValue(value || undefined),
});

const pagination = ref({ pageIndex: 0, pageSize: 10 });

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

function goToInput(umkmId?: string, reportId?: string) {
  const query: any = {};
  if (umkmId) query.umkm_id = umkmId;
  if (reportId) query.report_id = reportId;
  const to = {
    path: "/dashboard/laporan/input",
    query,
  };
  router.push(to);
}

useHead({
  title: "Laporan Mingguan",
});
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Laporan Mingguan">
        <template #right>
          <div class="flex items-center gap-2">
            <UButton
              label="Tambah Laporan"
              color="success"
              icon="i-heroicons-plus"
              @click="() => goToInput()"
            />
            <UButton
              color="neutral"
              icon="i-heroicons-arrow-down-tray"
              label="Export Excel"
              variant="subtle"
              size="sm"
              @click="exportReportsXlsx"
            />
          </div>
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="text-sm text-muted ml-2">Range: {{ dateRangeLabel }}</div>
        </template>

        <template #right>
          <div class="flex items-center gap-2">
            <UInput
              v-model="searchQuery"
              placeholder="Cari Laporan..."
              size="sm"
              icon="i-lucide-search"
              class="w-64"
            />
            <UButton
              v-if="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
              label="Hapus"
              color="error"
              variant="subtle"
              icon="i-lucide-trash"
              @click="deleteSelectedReports"
            >
              <template #trailing>
                <UKbd>{{
                  table?.tableApi?.getFilteredSelectedRowModel().rows.length
                }}</UKbd>
              </template>
            </UButton>

            <div class="flex items-center gap-2">
              <USelect
                v-model="dateFilterType"
                :items="[
                  { label: 'Bulan', value: 'month' },
                  { label: 'Tahun', value: 'year' },
                  { label: 'Custom', value: 'custom' },
                ]"
                size="sm"
                class="w-36"
              />

              <div v-if="dateFilterType === 'month'">
                <UInput
                  type="month"
                  v-model="selectedMonth"
                  size="sm"
                  class="w-40"
                />
              </div>

              <div v-else-if="dateFilterType === 'year'">
                <UInput
                  type="number"
                  v-model.number="selectedYear"
                  size="sm"
                  class="w-28"
                  placeholder="2025"
                />
              </div>

              <div v-else class="flex items-center gap-2">
                <UInput type="date" v-model="fromDate" size="sm" class="w-36" />
                <UInput type="date" v-model="toDate" size="sm" class="w-36" />
              </div>

              <UButton size="sm" label="Terapkan" @click="applyDateFilter" />
              <UButton
                size="sm"
                variant="ghost"
                label="Reset"
                @click="resetDateFilter"
              />
            </div>
          </div>
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <div class="overflow-auto rounded-lg p-4">
        <UTable
          ref="table"
          :data="reports"
          :columns="columns"
          v-model:column-filters="columnFilters"
          v-model:column-visibility="columnVisibility"
          v-model:row-selection="rowSelection"
          v-model:pagination="pagination"
          :getPaginationRowModel="getPaginationRowModel"
        >
          <template #empty-state>
            <div class="text-center py-12 text-gray-500">
              <UIcon name="i-heroicons-document-text" class="text-6xl mb-4" />
              <p class="font-medium">Belum ada laporan.</p>
            </div>
          </template>
        </UTable>
      </div>

      <div
        class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-auto"
      >
        <div class="text-sm text-muted">
          {{ table?.tableApi?.getFilteredSelectedRowModel().rows.length || 0 }}
          of
          {{ table?.tableApi?.getFilteredRowModel().rows.length || 0 }} row(s)
          selected.
        </div>

        <div class="flex items-center gap-1.5">
          <UPagination
            :default-page="
              (table?.tableApi?.getState().pagination.pageIndex || 0) + 1
            "
            :items-per-page="table?.tableApi?.getState().pagination.pageSize"
            :total="table?.tableApi?.getFilteredRowModel().rows.length"
            @update:page="(p: number) => table?.tableApi?.setPageIndex(p - 1)"
          />
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
