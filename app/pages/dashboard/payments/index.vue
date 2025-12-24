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
const UDropdownMenu = resolveComponent("UDropdownMenu");
const UCheckbox = resolveComponent("UCheckbox");

// Load payments + join nama UMKM
const { data: paymentsData, refresh } = await useAsyncData(
  "payments-list",
  async () => {
    const { data } = await supabase
      .from("payments")
      .select(
        `
        id, 
        umkm_id, 
        jumlah, 
        periode, 
        tanggal_bayar, 
        keterangan,
        umkm_profiles!inner(id, nama_usaha, nama_pemilik)
      `
      )
      .order("tanggal_bayar", { ascending: false });
    return data || [];
  }
);

const payments = computed(() => paymentsData.value || []);

// Columns for List Pembayaran
const paymentColumns: TableColumn<any>[] = [
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
    accessorKey: "tanggal_bayar",
    header: "Tanggal",
    cell: ({ row }) =>
      new Intl.DateTimeFormat("id-ID", {
        day: "numeric",
        month: "short",
        year: "numeric",
      }).format(new Date(row.original.tanggal_bayar)),
  },
  {
    id: "nama_usaha",
    header: "UMKM",
    accessorFn: (row: any) => row.umkm_profiles?.nama_usaha || "",
    cell: ({ row }) =>
      h("div", {}, [
        h(
          "div",
          { class: "font-medium" },
          row.original.umkm_profiles?.nama_usaha || "-"
        ),
        h(
          "div",
          { class: "text-sm text-gray-500" },
          row.original.umkm_profiles?.nama_pemilik || "-"
        ),
      ]),
  },
  {
    accessorKey: "jumlah",
    header: "Jumlah",
    cell: ({ row }) =>
      h(
        "span",
        { class: "font-semibold text-green-600" },
        new Intl.NumberFormat("id-ID", {
          style: "currency",
          currency: "IDR",
          minimumFractionDigits: 0,
        }).format(row.original.jumlah || 0)
      ),
  },
  {
    accessorKey: "periode",
    header: "Periode",
    cell: ({ row }) => row.original.periode || "-",
  },
  {
    accessorKey: "keterangan",
    header: "Keterangan",
    cell: ({ row }) => row.original.keterangan || "-",
  },
  {
    id: "actions",
    header: "Aksi",
    cell: ({ row }) =>
      h("div", { class: "flex items-center gap-2" }, [
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

const handleDelete = async (row: Row<any>) => {
  if (!confirm("Hapus pembayaran ini?")) return;
  const { error } = await supabase
    .from("payments")
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

async function deleteSelectedPayments() {
  const selected =
    table?.value?.tableApi?.getFilteredSelectedRowModel().rows || [];
  const ids = selected.map((r: any) => r.original.id);
  if (!ids.length) return;
  if (!confirm(`Hapus ${ids.length} pembayaran?`)) return;
  const { error } = await supabase.from("payments").delete().in("id", ids);
  if (error)
    return toast.add({
      title: "Gagal",
      description: error.message,
      color: "error",
    });
  toast.add({ title: `${ids.length} pembayaran dihapus`, color: "success" });
  refresh();
}

const columnFilters = ref([]);
const columnVisibility = ref({});
const rowSelection = ref({});
const pagination = ref({ pageIndex: 0, pageSize: 10 });

const currentPage = computed({
  get: () => pagination.value.pageIndex + 1,
  set: (val: number) => (pagination.value.pageIndex = val - 1),
});

const searchQuery = computed({
  get: (): string =>
    (table.value?.tableApi
      ?.getColumn("nama_usaha")
      ?.getFilterValue() as string) || "",
  set: (value: string) =>
    table.value?.tableApi
      ?.getColumn("nama_usaha")
      ?.setFilterValue(value || undefined),
});
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Pembayaran Klien">
        <template #right>
          <div class="flex items-center gap-2">
            <UButton
              to="/dashboard/payments/input"
              color="success"
              icon="i-heroicons-plus"
              label="Catat Pembayaran"
            />

          </div>
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="text-sm text-muted">
            Riwayat semua transaksi pembayaran klien
          </div>
        </template>

        <template #right>
          <div class="flex items-center gap-2">
            <UInput
              v-model="searchQuery"
              placeholder="Cari UMKM..."
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
              @click="deleteSelectedPayments"
            >
              <template #trailing>
                <UKbd>{{
                  table?.tableApi?.getFilteredSelectedRowModel().rows.length
                }}</UKbd>
              </template>
            </UButton>

            <UDropdownMenu
              :items="table?.tableApi?.getAllColumns().filter((c: any) => c.getCanHide()).map((c: any) => ({
                label: c.id === 'nama_usaha' ? 'UMKM' : c.id,
                type: 'checkbox' as const,
                checked: c.getIsVisible(),
                onUpdateChecked: (v: boolean) => table?.tableApi?.getColumn(c.id)?.toggleVisibility(!!v),
                onSelect: (e?: Event) => e?.preventDefault(),
              }))"
              :content="{ align: 'end' }"
            >
              <UButton
                label="Kolom"
                color="neutral"
                variant="outline"
                trailing-icon="i-heroicons-adjustments-horizontal"
              />
            </UDropdownMenu>
          </div>
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <UTable
        ref="table"
        :data="payments"
        :columns="paymentColumns"
        v-model:column-filters="columnFilters"
        v-model:column-visibility="columnVisibility"
        v-model:row-selection="rowSelection"
        v-model:pagination="pagination"
        :pagination-options="{ getPaginationRowModel: getPaginationRowModel() }"
      >
        <template #empty-state>
          <div class="text-center py-12 text-gray-500">
            <UIcon name="i-heroicons-banknotes" class="text-6xl mb-4" />
            <p class="font-medium">Belum ada catatan pembayaran</p>
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
