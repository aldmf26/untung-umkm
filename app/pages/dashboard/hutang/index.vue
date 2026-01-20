<script setup lang="ts">
definePageMeta({ layout: "dashboard", middleware: "auth" });

import type { TableColumn } from "@nuxt/ui";
import { getPaginationRowModel } from "@tanstack/table-core";
import type { Row } from "@tanstack/table-core";

const supabase = useSupabaseClient();
const toast = useToast();
const table = useTemplateRef("table");

// Resolve UI components
const UButton = resolveComponent("UButton");
const UCheckbox = resolveComponent("UCheckbox");
const UBadge = resolveComponent("UBadge");

const router = useRouter();

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
  label: dateRangeLabel,
} = df;

const { data: debtsData, refresh } = await useAsyncData(
  () => `debts-list:${fromDate.value}:${toDate.value}`,
  async () => {
    let query: any = supabase
      .from("debts")
      .select(
        `
        id, 
        umkm_id, 
        nama_debitur,
        no_wa,
        jumlah, 
        tanggal_hutang, 
        jatuh_tempo,
        keterangan,
        status,
        tanggal_lunas,
        umkm_profiles!inner(id, nama_usaha, nama_pemilik)
      `
      )
      .order("tanggal_hutang", { ascending: false });

    if (fromDate.value) query = query.gte("tanggal_hutang", fromDate.value);
    if (toDate.value) query = query.lte("tanggal_hutang", toDate.value);

    const { data } = await query;
    return data || [];
  }
);

async function applyDateFilter() {
  await applyDateFilterCb(refresh);
}

async function resetDateFilter() {
  await resetDateFilterCb(refresh);
}

const debts = computed(() => debtsData.value || []);

// Summary stats
const totalHutang = computed(() =>
  debts.value
    .filter((d: any) => d.status === "belum_lunas")
    .reduce((sum: number, d: any) => sum + (d.jumlah || 0), 0)
);

const countBelumLunas = computed(
  () => debts.value.filter((d: any) => d.status === "belum_lunas").length
);

const countLunas = computed(
  () => debts.value.filter((d: any) => d.status === "lunas").length
);

// Columns for List Hutang
const debtColumns: TableColumn<any>[] = [
  {
    id: "select",
    header: ({ table }) =>
      h(UCheckbox, {
        modelValue: table.getIsSomePageRowsSelected()
          ? "indeterminate"
          : table.getIsAllPageRowsSelected(),
        "onUpdate:modelValue": (value: boolean | "indeterminate") =>
          table.toggleAllPageRowsSelected(!!value),
        ariaLabel: "Select all",
      }),
    cell: ({ row }) =>
      h(UCheckbox, {
        modelValue: row.getIsSelected(),
        "onUpdate:modelValue": (value: boolean | "indeterminate") =>
          row.toggleSelected(!!value),
        ariaLabel: "Select row",
      }),
  },
  {
    accessorKey: "tanggal_hutang",
    header: "Tanggal",
    cell: ({ row }) =>
      new Intl.DateTimeFormat("id-ID", {
        day: "numeric",
        month: "short",
        year: "numeric",
      }).format(new Date(row.original.tanggal_hutang)),
  },
  {
    id: "nama_usaha",
    header: "UMKM",
    accessorFn: (row: any) => row.umkm_profiles?.nama_usaha || "",
    cell: ({ row }) =>
      h("div", {}, [
        h(
          "div",
          { class: "font-bold" },
          row.original.umkm_profiles?.nama_usaha || "-"
        ),
        h(
          "div",
          { class: "text-sm text-muted" },
          row.original.umkm_profiles?.nama_pemilik || "-"
        ),
      ]),
  },
  {
    accessorKey: "nama_debitur",
    header: "Nama Debitur",
    cell: ({ row }) =>
      h("div", {}, [
        h("div", { class: "font-medium" }, row.original.nama_debitur || "-"),
        row.original.no_wa
          ? h("div", { class: "text-sm text-muted" }, row.original.no_wa)
          : null,
      ]),
  },
  {
    accessorKey: "jumlah",
    header: "Jumlah",
    cell: ({ row }) =>
      h(
        "span",
        { class: "font-semibold text-red-600" },
        new Intl.NumberFormat("id-ID", {
          style: "currency",
          currency: "IDR",
          minimumFractionDigits: 0,
        }).format(row.original.jumlah || 0)
      ),
  },
  {
    accessorKey: "jatuh_tempo",
    header: "Jatuh Tempo",
    cell: ({ row }) => {
      if (!row.original.jatuh_tempo) return "-";
      const jatuhTempo = new Date(row.original.jatuh_tempo);
      const today = new Date();
      const isOverdue = jatuhTempo < today && row.original.status === "belum_lunas";
      
      return h(
        "span",
        { class: isOverdue ? "text-red-600 font-medium" : "" },
        new Intl.DateTimeFormat("id-ID", {
          day: "numeric",
          month: "short",
          year: "numeric",
        }).format(jatuhTempo)
      );
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) =>
      h(
        UBadge,
        {
          color: row.original.status === "lunas" ? "success" : "warning",
          variant: "soft",
        },
        { default: () => (row.original.status === "lunas" ? "Lunas" : "Belum Lunas") }
      ),
  },
  {
    id: "actions",
    header: "Aksi",
    cell: ({ row }) =>
      h("div", { class: "flex items-center gap-2" }, [
        row.original.status === "belum_lunas"
          ? h(
              UButton,
              {
                size: "xs",
                variant: "soft",
                color: "success",
                onClick: () => markAsLunas(row),
              },
              { default: () => "Lunas" }
            )
          : null,
        h(
          UButton,
          {
            size: "xs",
            variant: "ghost",
            onClick: () => goToInput(row.original.umkm_id, row.original.id),
          },
          { default: () => "Edit" }
        ),
        h(UButton, {
          icon: "i-heroicons-trash",
          color: "error",
          variant: "ghost",
          size: "xs",
          onClick: () => handleDelete(row),
        }),
      ]),
  },
];

async function markAsLunas(row: Row<any>) {
  if (!confirm("Tandai hutang ini sebagai lunas?")) return;
  
  const today = new Date().toISOString().split("T")[0];
  const { error } = await supabase
    .from("debts")
    .update({ status: "lunas", tanggal_lunas: today })
    .eq("id", row.original.id);
    
  if (error)
    return toast.add({
      title: "Gagal",
      description: error.message,
      color: "error",
    });
  toast.add({ title: "Hutang ditandai lunas", color: "success" });
  refresh();
}

const handleDelete = async (row: Row<any>) => {
  if (!confirm("Hapus data hutang ini?")) return;
  const { error } = await supabase
    .from("debts")
    .delete()
    .eq("id", row.original.id);
  if (error)
    return toast.add({
      title: "Gagal",
      description: error.message,
      color: "error",
    });
  toast.add({ title: "Terhapus", color: "success" });
  refresh();
};

async function deleteSelectedDebts() {
  const selected =
    table?.value?.tableApi?.getFilteredSelectedRowModel().rows || [];
  const ids = selected.map((r: any) => r.original.id);
  if (!ids.length) return;
  if (!confirm(`Hapus ${ids.length} data hutang?`)) return;
  const { error } = await supabase.from("debts").delete().in("id", ids);
  if (error)
    return toast.add({
      title: "Gagal",
      description: error.message,
      color: "error",
    });
  toast.add({ title: `${ids.length} data hutang dihapus`, color: "success" });
  refresh();
}

async function exportDebtsXlsx() {
  try {
    const rows =
      table?.value?.tableApi
        ?.getFilteredRowModel()
        .rows?.map((r: any) => r.original) ||
      debts.value ||
      [];
    const dataRows = rows.map((r: any) => ({
      tanggal_hutang: r.tanggal_hutang,
      nama_usaha: r.umkm_profiles?.nama_usaha || "",
      nama_debitur: r.nama_debitur || "",
      no_wa: r.no_wa || "",
      jumlah: Number(r.jumlah || 0),
      jatuh_tempo: r.jatuh_tempo || "",
      status: r.status === "lunas" ? "Lunas" : "Belum Lunas",
      keterangan: r.keterangan || "",
    }));

    const mod: any = await import("exceljs");
    const Workbook =
      mod.Workbook || mod.default?.Workbook || mod.default || mod;
    const wb: any = new Workbook();
    const ws = wb.addWorksheet("Hutang");

    const headers = [
      "Tanggal",
      "Nama Usaha",
      "Nama Debitur",
      "No WA",
      "Jumlah",
      "Jatuh Tempo",
      "Status",
      "Keterangan",
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
        r.tanggal_hutang,
        r.nama_usaha,
        r.nama_debitur,
        r.no_wa,
        r.jumlah,
        r.jatuh_tempo,
        r.status,
        r.keterangan,
      ]);
      const amountCell = row.getCell(5);
      amountCell.value = Number(r.jumlah || 0);
      (amountCell as any).numFmt = "#,##0";
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
    a.download = `hutang_${label}.xlsx`;
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

function goToInput(umkmId?: string, debtId?: string) {
  const query: any = {};
  if (umkmId) query.umkm_id = umkmId;
  if (debtId) query.debt_id = debtId;
  router.push({ path: "/dashboard/hutang/input", query });
}

const columnFilters = ref([]);
const columnVisibility = ref({});
const rowSelection = ref({});
const pagination = ref({ pageIndex: 0, pageSize: 10 });

const searchQuery = computed({
  get: (): string =>
    (table.value?.tableApi
      ?.getColumn("nama_debitur")
      ?.getFilterValue() as string) || "",
  set: (value: string) =>
    table.value?.tableApi
      ?.getColumn("nama_debitur")
      ?.setFilterValue(value || undefined),
});

useHead({
  title: "Data Hutang",
});
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Data Hutang">
        <template #right>
          <div class="flex items-center gap-2">
            <UButton
              to="/dashboard/hutang/input"
              color="success"
              icon="i-heroicons-plus"
              label="Catat Hutang"
            />
            <UButton
              color="neutral"
              icon="i-heroicons-arrow-down-tray"
              label="Export Excel"
              variant="subtle"
              size="sm"
              @click="exportDebtsXlsx"
            />
          </div>
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="flex items-center gap-4 ml-2">
            <div class="text-sm">
              <span class="text-muted">Total Hutang: </span>
              <span class="font-bold text-red-600">
                {{
                  new Intl.NumberFormat("id-ID", {
                    style: "currency",
                    currency: "IDR",
                    minimumFractionDigits: 0,
                  }).format(totalHutang)
                }}
              </span>
            </div>
            <div class="text-sm text-muted">
              {{ countBelumLunas }} belum lunas • {{ countLunas }} lunas
            </div>
          </div>
        </template>

        <template #right>
          <div class="flex items-center gap-2">
            <UInput
              v-model="searchQuery"
              placeholder="Cari Debitur..."
              size="sm"
              class="max-w-sm"
              icon="i-heroicons-magnifying-glass"
            />
            <UButton
              v-if="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
              label="Hapus"
              color="error"
              variant="subtle"
              icon="i-lucide-trash"
              @click="deleteSelectedDebts"
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
      <UTable
        ref="table"
        :data="debts"
        :columns="debtColumns"
        v-model:column-filters="columnFilters"
        v-model:column-visibility="columnVisibility"
        v-model:row-selection="rowSelection"
        v-model:pagination="pagination"
        :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
      >
        <template #empty-state>
          <div class="text-center py-12 text-gray-500">
            <UIcon name="i-heroicons-document-text" class="text-6xl mb-4" />
            <p class="font-medium">Belum ada catatan hutang</p>
          </div>
        </template>
      </UTable>

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
