<script setup lang="ts">
import type { TableColumn } from "@nuxt/ui";
import { upperFirst } from "scule";
import { getPaginationRowModel } from "@tanstack/table-core";
import type { Row } from "@tanstack/table-core";
definePageMeta({
  layout: "dashboard",
});

interface UMKM {
  id: string;
  nama_usaha: string;
  nama_pemilik: string;
  no_wa: string;
  tanggal_join: string;
  status: "active" | "trial" | "inactive";
}

const UButton = resolveComponent("UButton");
const UBadge = resolveComponent("UBadge");
const UDropdownMenu = resolveComponent("UDropdownMenu");
const UCheckbox = resolveComponent("UCheckbox");
const CustomersEditModal = resolveComponent("CustomersEditModal");
const CustomersDeleteModal = resolveComponent("CustomersDeleteModal");

const toast = useToast();
const table = useTemplateRef("table");

const columnFilters = ref([
  {
    id: "nama_usaha",
    value: "",
  },
]);
const columnVisibility = ref();
const rowSelection = ref({});

// Load UMKM from Supabase
const { data: umkmData, refresh: refreshUmkm } = await useAsyncData(
  "umkm-profiles",
  async () => {
    const supabase = useSupabaseClient();
    const { data } = await supabase
      .from("umkm_profiles")
      .select("*")
      .order("nama_usaha", { ascending: true });

    return data || [];
  },
  { immediate: true }
);

function handleAdded(newItem: UMKM) {
  toast.add({
    title: "UMKM ditambahkan",
    description: newItem.nama_usaha,
    color: "success",
  });
  refreshUmkm();
}

async function handleDeleteSelected() {
  const selected =
    table?.value?.tableApi?.getFilteredSelectedRowModel().rows || [];
  const ids = selected.map((r: any) => r.original.id);
  if (!ids.length) return;

  const supabase = useSupabaseClient();
  const { error } = await supabase.from("umkm_profiles").delete().in("id", ids);
  if (error) {
    toast.add({
      title: "Gagal menghapus",
      description: error.message,
      color: "error",
    });
    return;
  }
  toast.add({
    title: "UMKM dihapus",
    description: `${ids.length} item dihapus`,
    color: "success",
  });
  refreshUmkm();
}

// handle delete emitted from single-row DeleteModal
function handleDeleted(ids?: string[]) {
  toast.add({
    title: "UMKM dihapus",
    description: `${ids?.length || 1} item dihapus`,
    color: "success",
  });
  refreshUmkm();
}

// handle updated emitted from EditModal
function handleUpdated() {
  toast.add({ title: "UMKM diperbarui", color: "success" });
  refreshUmkm();
}

const status = ref("success");

function getRowItems(row: Row<UMKM>) {
  return [
    {
      type: "label",
      label: "Aksi Cepat",
    },
    {
      label: "Input Laporan Minggu Ini",
      icon: "i-heroicons-document-plus",
      color: "success",
      onSelect() {
        navigateTo(`/dashboard/laporan/input?umkm=${row.original.id}`);
      },
    },
    {
      type: "separator",
    },
    {
      label: "Lihat Riwayat Laporan",
      icon: "i-heroicons-document-text",
      onSelect() {
        navigateTo(`/dashboard/umkm/${row.original.id}`);
      },
    },

    {
      label: "Kirim Reminder WA",
      icon: "i-simple-icons-whatsapp",
      onSelect() {
        const waUrl = `https://wa.me/${row.original.no_wa.replace(
          /^0/,
          "62"
        )}?text=${encodeURIComponent(
          "Halo " +
            row.original.nama_pemilik +
            ", jangan lupa kirim laporan keuangan minggu ini ya! 😊"
        )}`;
        window.open(waUrl, "_blank");
        toast.add({
          title: "WhatsApp dibuka",
          description: "Silakan kirim pesan reminder",
          color: "success",
        });
      },
    },
    {
      label: "Copy Nomor WhatsApp",
      icon: "i-heroicons-clipboard-document",
      onSelect() {
        toast.add({
          title: "Nomor disalin",
          description: `Nomor WhatsApp berhasil disalin`,
          color: "success",
        });
        navigator.clipboard.writeText(row.original.no_wa);
      },
    },
    {
      label: "Salin Template Pesan WA",
      icon: "i-heroicons-clipboard-document",
      onSelect() {
        const template = `Halo ${row.original.nama_pemilik},\n\nBerikut ringkasan mingguan usaha *${row.original.nama_usaha}*:\n- Uang masuk: ...\n- Uang keluar: ...\n- Untung/Rugi: ...\n\nSalam,\nTim Pendampingan UMKM`;
        navigator.clipboard.writeText(template);
        toast.add({
          title: "Template disalin",
          description: "Template pesan WA berhasil disalin ke clipboard",
          color: "success",
        });
      },
    },
  ];
}

const columns: TableColumn<UMKM>[] = [
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
    accessorKey: "nama_usaha",
    header: "Nama Usaha",
    cell: ({ row }) => row.original.nama_usaha,
  },
  {
    accessorKey: "nama_pemilik",
    header: "Pemilik",
    cell: ({ row }) => row.original.nama_pemilik,
  },
  {
    accessorKey: "no_wa",
    header: "No. WhatsApp",
    cell: ({ row }) => {
      return h("div", { class: "flex items-center gap-2" }, [
        h("span", { class: "font-mono text-sm" }, row.original.no_wa),
        h(UButton, {
          icon: "i-simple-icons-whatsapp",
          color: "success",
          variant: "ghost",
          size: "xs",
          onClick: () => {
            const waUrl = `https://wa.me/${row.original.no_wa.replace(
              /^0/,
              "62"
            )}`;
            window.open(waUrl, "_blank");
          },
        }),
      ]);
    },
  },
  {
    accessorKey: "tanggal_join",
    header: ({ column }) => {
      const isSorted = column.getIsSorted();
      return h(UButton, {
        color: "neutral",
        variant: "ghost",
        label: "Tanggal Join",
        icon: isSorted
          ? isSorted === "asc"
            ? "i-heroicons-arrow-up"
            : "i-heroicons-arrow-down"
          : "i-heroicons-arrows-up-down",
        class: "-mx-2.5",
        onClick: () => column.toggleSorting(column.getIsSorted() === "asc"),
      });
    },
    cell: ({ row }) => {
      const date = new Date(row.original.tanggal_join);
      return new Intl.DateTimeFormat("id-ID", {
        day: "numeric",
        month: "short",
        year: "numeric",
      }).format(date);
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    filterFn: "equals",
    cell: ({ row }) => {
      const statusConfig = {
        active: {
          color: "success" as const,
          label: "Active",
          icon: "i-heroicons-check-circle",
        },
        trial: {
          color: "warning" as const,
          label: "Trial",
          icon: "i-heroicons-clock",
        },
        inactive: {
          color: "error" as const,
          label: "Inactive",
          icon: "i-heroicons-x-circle",
        },
      };

      const config = statusConfig[row.original.status];

      return h(
        UBadge,
        {
          class: "capitalize",
          variant: "subtle",
          color: config.color,
          icon: config.icon,
        },
        () => config.label
      );
    },
  },
  {
    id: "actions",
    header: "Aksi",
    cell: ({ row }) => {
      return h("div", { class: "flex items-center gap-2" }, [
        // Edit modal trigger button
        h(
          CustomersEditModal,
          { item: row.original, onUpdated: () => refreshUmkm() },
          () =>
            h(UButton, {
              icon: "i-heroicons-pencil-square",
              color: "neutral",
              variant: "ghost",
              size: "xs",
            })
        ),
        // Delete modal for single row
        h(
          CustomersDeleteModal,
          {
            ids: [row.original.id],
            onDeleted: (ids: string[]) => handleDeleted(ids),
          },
          () =>
            h(UButton, {
              icon: "i-heroicons-trash",
              color: "error",
              variant: "ghost",
              size: "xs",
            })
        ),
        h(
          UDropdownMenu,
          {
            content: {
              align: "end",
            },
            items: getRowItems(row),
          },
          () =>
            h(UButton, {
              icon: "i-heroicons-ellipsis-vertical",
              color: "neutral",
              variant: "ghost",
              size: "xs",
            })
        ),
      ]);
    },
  },
];

const statusFilter = ref("all");

watch(
  () => statusFilter.value,
  (newVal) => {
    if (!table?.value?.tableApi) return;

    const statusColumn = table.value.tableApi.getColumn("status");
    if (!statusColumn) return;

    if (newVal === "all") {
      statusColumn.setFilterValue(undefined);
    } else {
      statusColumn.setFilterValue(newVal);
    }
  }
);

const searchQuery = computed({
  get: (): string => {
    return (
      (table.value?.tableApi
        ?.getColumn("nama_usaha")
        ?.getFilterValue() as string) || ""
    );
  },
  set: (value: string) => {
    table.value?.tableApi
      ?.getColumn("nama_usaha")
      ?.setFilterValue(value || undefined);
  },
});

const pagination = ref({
  pageIndex: 0,
  pageSize: 10,
});

useHead({
  title: "Data UMKM - Dashboard",
});
</script>

<template>
  <UDashboardPanel id="customers">
    <template #header>
      <UDashboardNavbar title="Customers">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <CustomersAddModal @saved="handleAdded" />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-end gap-1.5">
        <UInput
          v-model="searchQuery"
          class="max-w-sm"
          size="sm"
          icon="i-lucide-search"
          placeholder="Cari UMKM..."
        />

        <div class="flex flex-wrap items-center gap-1.5">
          <CustomersDeleteModal
            :count="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
            @confirmed="handleDeleteSelected"
          >
            <UButton
              v-if="table?.tableApi?.getFilteredSelectedRowModel().rows.length"
              label="Delete"
              color="error"
              variant="subtle"
              icon="i-lucide-trash"
            >
              <template #trailing>
                <UKbd>
                  {{
                    table?.tableApi?.getFilteredSelectedRowModel().rows.length
                  }}
                </UKbd>
              </template>
            </UButton>
          </CustomersDeleteModal>

          <USelect
            v-model="statusFilter"
            :items="[
              { label: 'Semua Status', value: 'all' },
              { label: 'Active', value: 'active' },
              { label: 'Trial', value: 'trial' },
              { label: 'Inactive', value: 'inactive' },
            ]"
            placeholder="Filter status"
            class="min-w-32"
            size="sm"
          />
        </div>
      </div>

      <UTable
        ref="table"
        v-model:column-filters="columnFilters"
        v-model:column-visibility="columnVisibility"
        v-model:row-selection="rowSelection"
        v-model:pagination="pagination"
        :pagination-options="{
          getPaginationRowModel: getPaginationRowModel(),
        }"
        class="shrink-0"
        :data="umkmData"
        :columns="columns"
        :loading="status === 'pending'"
        :ui="{
          base: 'table-fixed border-separate border-spacing-0',
          thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
          tbody: '[&>tr]:last:[&>td]:border-b-0',
          th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
          td: 'border-b border-default',
          separator: 'h-0',
        }"
      />

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
