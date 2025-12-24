<script setup lang="ts">
import type { Ref } from "vue";

definePageMeta({ layout: "dashboard" });

const toast = useToast();
const supabase = useSupabaseClient();
const router = useRouter();

// Resolve components used in renderers and toolbar
const UButton = resolveComponent("UButton");
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

import type { TableColumn } from "@nuxt/ui";
import { getPaginationRowModel } from "@tanstack/table-core";
import type { Row } from "@tanstack/table-core";

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
            onClick: () => openEditReport(row.original),
          },
          { default: () => "Edit" }
        ),
        h(UButton, {
          size: "xs",
          variant: "ghost",
          onClick: () => router.push(`/dashboard/umkm/${row.original.umkm_id}`),
        },{default: 'Lihat'}),
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

        <template #right>
          <div class="flex items-center gap-2">
            <UInput
              v-model="searchQuery"
              placeholder="Cari UMKM..."
              size="sm"
              class="w-64"
            />
            <USelect
              v-model:number="pagination.pageSize"
              :items="[
                { label: '10', value: 10 },
                { label: '25', value: 25 },
                { label: '50', value: 50 },
              ]"
              size="sm"
            />
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
    </template>
  </UDashboardPanel>
</template>
