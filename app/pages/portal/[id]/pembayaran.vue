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

// Load payments
const { data: payments, refresh } = await useAsyncData(
  () => `portal-payments-${umkmId.value}-${fromDate.value}-${toDate.value}`,
  async () => {
    let query = supabase
      .from("payments")
      .select("*")
      .eq("umkm_id", umkmId.value)
      .order("tanggal_bayar", { ascending: false });

    if (fromDate.value) query = query.gte("tanggal_bayar", fromDate.value);
    if (toDate.value) query = query.lte("tanggal_bayar", toDate.value);

    const { data } = await query;
    return data || [];
  }
);

const totalPembayaran = computed(() =>
  (payments.value || []).reduce((sum: number, p: any) => sum + (p.jumlah || 0), 0)
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
    const dataRows = (payments.value || []).map((p: any) => ({
      tanggal_bayar: p.tanggal_bayar,
      jumlah: Number(p.jumlah || 0),
      periode: p.periode || "",
      keterangan: p.keterangan || "",
    }));

    const mod: any = await import("exceljs");
    const Workbook = mod.Workbook || mod.default?.Workbook || mod.default || mod;
    const wb: any = new Workbook();
    const ws = wb.addWorksheet("Pembayaran");

    const headers = ["Tanggal", "Jumlah", "Periode", "Keterangan"];
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
      ws.addRow([r.tanggal_bayar, r.jumlah, r.periode, r.keterangan]);
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
    a.download = `pembayaran_${umkm.value?.nama_usaha || "umkm"}_${selectedMonth.value}.xlsx`;
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
  title: `Pembayaran - ${umkm.value?.nama_usaha || "Portal"}`,
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
          <h1 class="text-2xl font-bold text-gray-800 dark:text-white">💳 Pembayaran</h1>
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

      <!-- Total Summary -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700 mb-6">
        <div class="flex items-center justify-between">
          <div class="text-gray-600 dark:text-gray-400">Total Pembayaran Bulan Ini</div>
          <div class="text-2xl font-bold text-emerald-600">{{ fmtMoney(totalPembayaran) }}</div>
        </div>
      </div>

      <!-- Payments List -->
      <div class="space-y-3">
        <div v-if="!payments || payments.length === 0" class="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-lg text-center">
          <div class="text-5xl mb-4">📭</div>
          <p class="text-gray-600 dark:text-gray-400">Belum ada pembayaran untuk bulan ini</p>
        </div>

        <div
          v-for="payment in payments"
          :key="payment.id"
          class="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-lg border border-gray-100 dark:border-gray-700"
        >
          <div class="flex items-center justify-between">
            <div>
              <div class="font-bold text-emerald-600 text-lg">{{ fmtMoney(payment.jumlah) }}</div>
              <div class="text-gray-500 dark:text-gray-400 text-sm mt-1">
                📅 {{ fmtDate(payment.tanggal_bayar) }}
                <span v-if="payment.periode" class="ml-2">• {{ payment.periode }}</span>
              </div>
              <div v-if="payment.keterangan" class="text-gray-600 dark:text-gray-400 text-sm mt-2">
                {{ payment.keterangan }}
              </div>
            </div>
            <div class="text-4xl">💰</div>
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
