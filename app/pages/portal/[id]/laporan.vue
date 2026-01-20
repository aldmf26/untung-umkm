<script setup lang="ts">
definePageMeta({ layout: false });

const route = useRoute();
const supabase = useSupabaseClient();
const toast = useToast();

const umkmId = computed(() => route.params.id as string);

// Date filter state
const selectedMonth = ref(
  `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, "0")}`
);

const fromDate = computed(() => {
  const [year, month] = selectedMonth.value.split("-");
  return `${year}-${month}-01`;
});

const toDate = computed(() => {
  const [year, month] = selectedMonth.value.split("-");
  const lastDay = new Date(parseInt(year), parseInt(month), 0).getDate();
  return `${year}-${month}-${lastDay}`;
});

// Load UMKM profile
const { data: umkm } = await useAsyncData(`portal-umkm-${umkmId.value}`, async () => {
  const { data } = await supabase
    .from("umkm_profiles")
    .select("*")
    .eq("id", umkmId.value)
    .single();
  return data;
});

// Load reports
const { data: reports, refresh } = await useAsyncData(
  () => `portal-reports-${umkmId.value}-${fromDate.value}-${toDate.value}`,
  async () => {
    let query = supabase
      .from("weekly_reports")
      .select("*")
      .eq("umkm_id", umkmId.value)
      .order("periode_mulai", { ascending: false });

    if (fromDate.value) query = query.gte("periode_mulai", fromDate.value);
    if (toDate.value) query = query.lte("periode_selesai", toDate.value);

    const { data } = await query;
    return data || [];
  }
);

function fmtMoney(n: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(n || 0);
}

function fmtDate(d?: string) {
  if (!d) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(d));
}

// Export to Excel
async function exportExcel() {
  try {
    const dataRows = (reports.value || []).map((r: any) => ({
      periode_mulai: r.periode_mulai,
      periode_selesai: r.periode_selesai,
      uang_masuk: Number(r.uang_masuk || 0),
      uang_keluar: Number(r.uang_keluar || 0),
      untung_rugi: Number(r.uang_masuk || 0) - Number(r.uang_keluar || 0),
      rangkuman: r.rangkuman || "",
      saran: r.saran || "",
    }));

    const mod: any = await import("exceljs");
    const Workbook = mod.Workbook || mod.default?.Workbook || mod.default || mod;
    const wb: any = new Workbook();
    const ws = wb.addWorksheet("Laporan");

    const headers = ["Periode Mulai", "Periode Selesai", "Uang Masuk", "Uang Keluar", "Untung/Rugi", "Rangkuman", "Saran"];
    ws.addRow(headers);

    const headerRow = ws.getRow(1);
    headerRow.font = { bold: true };
    headerRow.eachCell((cell: any) => {
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" },
      };
    });

    dataRows.forEach((r: any) => {
      ws.addRow([
        r.periode_mulai,
        r.periode_selesai,
        r.uang_masuk,
        r.uang_keluar,
        r.untung_rugi,
        r.rangkuman,
        r.saran,
      ]);
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
      col.width = Math.min(max, 40);
    });

    const buf = await wb.xlsx.writeBuffer();
    const blob = new Blob([buf], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `laporan_${umkm.value?.nama_usaha || "umkm"}_${selectedMonth.value}.xlsx`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);

    toast.add({ title: "Berhasil export!", color: "success" });
  } catch (err: any) {
    console.error(err);
    toast.add({ title: "Gagal export", description: err.message, color: "error" });
  }
}

useHead({
  title: `Laporan - ${umkm.value?.nama_usaha || "Portal"}`,
});
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-emerald-50 to-teal-100 dark:from-gray-900 dark:to-gray-800">
    <div class="max-w-4xl mx-auto px-4 py-8">
      <!-- Header -->
      <div class="flex items-center gap-4 mb-6">
        <NuxtLink
          :to="`/portal/${umkmId}`"
          class="w-12 h-12 bg-white dark:bg-gray-800 rounded-xl flex items-center justify-center shadow-lg hover:scale-105 transition-all"
        >
          <span class="text-2xl">←</span>
        </NuxtLink>
        <div>
          <h1 class="text-2xl font-bold text-gray-800 dark:text-white">📊 Laporan</h1>
          <p class="text-gray-600 dark:text-gray-400">{{ umkm?.nama_usaha }}</p>
        </div>
      </div>

      <!-- Filter & Export -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-4 shadow-lg border border-gray-100 dark:border-gray-700 mb-6">
        <div class="flex flex-col sm:flex-row items-center gap-4">
          <div class="flex items-center gap-2 flex-1">
            <span class="text-gray-600 dark:text-gray-400">Bulan:</span>
            <input
              type="month"
              v-model="selectedMonth"
              @change="refresh"
              class="px-4 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-800 dark:text-white"
            />
          </div>
          <button
            @click="exportExcel"
            class="w-full sm:w-auto px-6 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-medium rounded-xl flex items-center justify-center gap-2 transition-all"
          >
            <span>📥</span> Download Excel
          </button>
        </div>
      </div>

      <!-- Reports List -->
      <div class="space-y-4">
        <div v-if="!reports || reports.length === 0" class="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-lg text-center">
          <div class="text-5xl mb-4">📭</div>
          <p class="text-gray-600 dark:text-gray-400">Belum ada laporan untuk bulan ini</p>
        </div>

        <div
          v-for="report in reports"
          :key="report.id"
          class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700"
        >
          <!-- Period Header -->
          <div class="flex items-center justify-between mb-4">
            <div class="text-gray-600 dark:text-gray-400">
              📅 {{ fmtDate(report.periode_mulai) }} - {{ fmtDate(report.periode_selesai) }}
            </div>
            <span
              v-if="report.is_partial"
              class="px-3 py-1 bg-amber-100 text-amber-700 rounded-full text-sm"
            >
              Partial
            </span>
          </div>

          <!-- Financial Summary -->
          <div class="grid grid-cols-3 gap-4 mb-4">
            <div class="text-center p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl">
              <div class="text-sm text-gray-600 dark:text-gray-400">Masuk</div>
              <div class="font-bold text-emerald-600">{{ fmtMoney(report.uang_masuk) }}</div>
            </div>
            <div class="text-center p-3 bg-red-50 dark:bg-red-900/20 rounded-xl">
              <div class="text-sm text-gray-600 dark:text-gray-400">Keluar</div>
              <div class="font-bold text-red-600">{{ fmtMoney(report.uang_keluar) }}</div>
            </div>
            <div
              :class="[
                'text-center p-3 rounded-xl',
                (report.uang_masuk - report.uang_keluar) >= 0
                  ? 'bg-blue-50 dark:bg-blue-900/20'
                  : 'bg-orange-50 dark:bg-orange-900/20'
              ]"
            >
              <div class="text-sm text-gray-600 dark:text-gray-400">
                {{ (report.uang_masuk - report.uang_keluar) >= 0 ? 'Untung' : 'Rugi' }}
              </div>
              <div
                :class="[
                  'font-bold',
                  (report.uang_masuk - report.uang_keluar) >= 0 ? 'text-blue-600' : 'text-orange-600'
                ]"
              >
                {{ fmtMoney(Math.abs(report.uang_masuk - report.uang_keluar)) }}
              </div>
            </div>
          </div>

          <!-- Rangkuman -->
          <div v-if="report.rangkuman" class="mb-3">
            <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">📝 Rangkuman</div>
            <p class="text-gray-600 dark:text-gray-400 text-sm whitespace-pre-wrap">{{ report.rangkuman }}</p>
          </div>

          <!-- Saran -->
          <div v-if="report.saran">
            <div class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">💡 Saran</div>
            <p class="text-gray-600 dark:text-gray-400 text-sm whitespace-pre-wrap">{{ report.saran }}</p>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="text-center mt-12 text-gray-500 dark:text-gray-400 text-sm">
        <p>Powered by <strong>Laporku</strong></p>
      </div>
    </div>
  </div>
</template>
