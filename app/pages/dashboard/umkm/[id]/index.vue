<script setup lang="ts">
import type { TableColumn } from "@nuxt/ui";
import { getPaginationRowModel } from "@tanstack/table-core";
import type { Row } from "@tanstack/table-core";
import { sub } from "date-fns";

definePageMeta({ layout: "dashboard" });

const route = useRoute();
const id = route.params.id as string;
const supabase = useSupabaseClient();
const toast = useToast();
const router = useRouter();

// Components
const UButton = resolveComponent("UButton");
const UInput = resolveComponent("UInput");
const USelect = resolveComponent("USelect");
const UCard = resolveComponent("UCard");
const UFormField = resolveComponent("UFormField");
const UTextarea = resolveComponent("UTextarea");
const UModal = resolveComponent("UModal");
const UIcon = resolveComponent("UIcon");
const HomeDateRangePicker = resolveComponent("HomeDateRangePicker");
const HomePeriodSelect = resolveComponent("HomePeriodSelect");
const table = useTemplateRef("table");

// Data: UMKM profile
const { data: umkmData} = await useAsyncData(
  `umkm-profile-${id}`,
  async () => {
    const { data, error } = await supabase
      .from("umkm_profiles")
      .select("id, nama_usaha, nama_pemilik, no_wa, status, tanggal_join")
      .eq("id", id)
      .single();
    if (error) throw error;
    return data || null;
  }
);

// Payments for this UMKM (cumulative)
const { data: paymentsData } = await useAsyncData(
  `umkm-payments-${id}`,
  async () => {
    const { data } = await supabase
      .from("payments")
      .select("jumlah")
      .eq("umkm_id", id);

    return data || [];
  }
);

const totalPayment = computed(() =>
  (paymentsData.value || []).reduce(
    (sum: number, p: any) => sum + Number(p.jumlah || 0),
    0
  )
);

// Reports for this UMKM
const { data: reportsData, refresh: refreshReports } = await useAsyncData(
  `umkm-reports-${id}`,
  async () => {
    const { data } = await supabase
      .from("weekly_reports")
      .select(
        "id, periode_mulai, periode_selesai, uang_masuk, uang_keluar, untung_rugi, masalah, saran, created_at"
      )
      .eq("umkm_id", id)
      .order("periode_mulai", { ascending: false });
    return data || [];
  }
);

const reports = computed(() => reportsData.value || []);

// Range and period for chart
const range = shallowRef({
  start: sub(new Date(), { days: 14 }),
  end: new Date(),
});
const period = ref("weekly");

// Cumulative profit
const cumulativeProfit = computed(() =>
  (reports.value || []).reduce(
    (s: number, r: any) => s + Number(r.untung_rugi || 0),
    0
  )
);

// Table columns
interface ReportRow {
  id: string;
  periode_mulai: string;
  periode_selesai: string;
  uang_masuk: number;
  uang_keluar: number;
  untung_rugi: number;
  created_at: string;
}

const columns: TableColumn<ReportRow>[] = [
  {
    accessorKey: "periode_mulai",
    header: "Periode",
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
      new Intl.NumberFormat("id-ID", {
        style: "currency",
        currency: "IDR",
        minimumFractionDigits: 0,
      }).format(row.original.untung_rugi || 0),
  },
  {
    id: "actions",
    header: "Aksi",
    cell: ({ row }) =>
      h("div", { class: "flex gap-2" }, [
        h(UButton, {
          icon: "i-lucide-trash",
          size: "xs",
          color: "error",
          variant: "ghost",
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

// Edit modal for reports (reuse pattern)
const editReportOpen = ref(false);
const editReport = reactive<any>({
  id: "",
  periode_mulai: "",
  periode_selesai: "",
  uang_masuk: 0,
  uang_keluar: 0,
  masalah: "",
  saran: "",
});

function openEdit(r: any) {
  Object.assign(editReport, { ...r });
  editReportOpen.value = true;
}

async function saveEdit() {
  try {
    const payload: any = {
      periode_mulai: editReport.periode_mulai,
      periode_selesai: editReport.periode_selesai,
      uang_masuk: editReport.uang_masuk,
      uang_keluar: editReport.uang_keluar,
      masalah: editReport.masalah || null,
      saran: editReport.saran,
    };
    const { error } = await (supabase as any)
      .from("weekly_reports")
      .update(payload)
      .eq("id", editReport.id);
    if (error) throw error;
    toast.add({ title: "Laporan diperbarui", color: "success" });
    editReportOpen.value = false;
    await refreshReports();
  } catch (e: any) {
    toast.add({ title: "Gagal", description: e.message, color: "error" });
  }
}

// Quick actions
function goToInputReport() {
  router.push({ path: "/dashboard/laporan/input", query: { umkm_id: id } });
}
function goToPaymentInput() {
  router.push({ path: "/dashboard/payments/input", query: { umkm_id: id } });
}
function sendWhatsapp() {
  const no = (umkmData.value?.no_wa || "").replace(/^0/, "62");
  const msg = encodeURIComponent(
    `Halo ${umkmData.value?.nama_pemilik}, ini dari Tim. Mohon kirim laporan mingguan ya.`
  );
  window.open(`https://wa.me/${no}?text=${msg}`, "_blank");
}

const columnFilters = ref([] as any[]);

const searchQuery = computed({
  get: () =>
    (table.value?.tableApi
      ?.getColumn("periode_mulai")
      ?.getFilterValue() as string) || "",
  set: (v: string) =>
    table.value?.tableApi
      ?.getColumn("periode_mulai")
      ?.setFilterValue(v || undefined),
});
const tablePagination = ref({ pageIndex: 0, pageSize: 10 });

useHead({
  title: "Detail UMKM",
});
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar :title="umkmData?.nama_usaha || 'UMKM'">
        <template #right>
          <div class="flex items-center gap-2">
            <UButton
              icon="i-heroicons-document-plus"
              label="Input Laporan"
              @click="goToInputReport"
            />
            <UButton
              icon="i-heroicons-plus"
              label="Catat Pembayaran"
              color="success"
              @click="goToPaymentInput"
            />
            <UButton
              icon="i-simple-icons-whatsapp"
              label="Kirim WA"
              variant="ghost"
              @click="sendWhatsapp"
            />
          </div>
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <div class="flex items-center gap-4">
            <div class="text-sm text-muted">Profil & Riwayat Laporan</div>
          </div>
        </template>
        <template #right>
          <div class="flex gap-2 items-center">
            <HomeDateRangePicker v-model="range" />
            <HomePeriodSelect v-model="period" :range="range" />
          </div>
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div class="lg:col-span-1 p-4 bg-elevated rounded-lg border shadow-sm">
          <div class="text-sm text-muted">Profil UMKM</div>
          <div class="mt-4">
            <div class="text-lg font-semibold">{{ umkmData?.nama_usaha }}</div>
            <div class="text-sm text-muted">{{ umkmData?.nama_pemilik }}</div>
            <div class="mt-3 text-sm">
              Status: <strong class="capitalize">{{ umkmData?.status }}</strong>
            </div>
            <div class="text-sm">
              No WA: <span class="font-mono">{{ umkmData?.no_wa }}</span>
            </div>
            <div class="text-sm">
              Join:
              {{
                umkmData?.tanggal_join
                  ? new Intl.DateTimeFormat("id-ID", {
                      day: "numeric",
                      month: "short",
                      year: "numeric",
                    }).format(new Date(umkmData.tanggal_join))
                  : "-"
              }}
            </div>

            <div class="mt-4 p-3 bg-elevated rounded-lg border">
              <div class="text-sm text-muted">Total Untung Kumulatif</div>
              <div class="mt-2 text-2xl font-bold">
                {{
                  new Intl.NumberFormat("id-ID", {
                    style: "currency",
                    currency: "IDR",
                    minimumFractionDigits: 0,
                  }).format(cumulativeProfit)
                }}
              </div>
            </div>
            <div class="mt-4 p-3 bg-elevated rounded-lg border">
              <div class="text-sm text-muted">Total Payment</div>
              <div class="mt-2 text-2xl font-bold">
                {{
                  new Intl.NumberFormat("id-ID", {
                    style: "currency",
                    currency: "IDR",
                    minimumFractionDigits: 0,
                  }).format(totalPayment)
                }}
              </div>
            </div>
          </div>
        </div>

        <div class="lg:col-span-2">
          <div class="grid grid-cols-1 gap-4">
            <UmkmChart :umkmId="id" :period="period" :range="range" />

            <div class="p-4 bg-elevated rounded-lg border shadow-sm">
              <UTable
                ref="table"
                :data="reports"
                :columns="columns"
                v-model:column-filters="columnFilters"
                v-model:pagination="tablePagination"
                :getPaginationRowModel="getPaginationRowModel"
              >
                <template #empty-state>
                  <div class="text-center py-12 text-gray-500">
                    <UIcon
                      name="i-heroicons-document-text"
                      class="text-6xl mb-4"
                    />
                    <p class="font-medium">Belum ada laporan.</p>
                  </div>
                </template>
              </UTable>
            </div>
          </div>
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
