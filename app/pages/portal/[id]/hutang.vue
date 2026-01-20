<script setup lang="ts">
definePageMeta({ layout: false });

const route = useRoute();
const supabase = useSupabaseClient();
const toast = useToast();

const umkmId = computed(() => route.params.id as string);

// Filter state
const filterStatus = ref("all"); // all, belum_lunas, lunas

// Load UMKM profile
const { data: umkm } = await useAsyncData(`portal-umkm-${umkmId.value}`, async () => {
  const { data } = await supabase
    .from("umkm_profiles")
    .select("*")
    .eq("id", umkmId.value)
    .single();
  return data;
});

// Load debts
const { data: allDebts, refresh } = await useAsyncData(
  `portal-debts-${umkmId.value}`,
  async () => {
    const { data } = await supabase
      .from("debts")
      .select("*")
      .eq("umkm_id", umkmId.value)
      .order("tanggal_hutang", { ascending: false });
    return data || [];
  }
);

const debts = computed(() => {
  if (filterStatus.value === "all") return allDebts.value || [];
  return (allDebts.value || []).filter((d: any) => d.status === filterStatus.value);
});

const totalBelumLunas = computed(() =>
  (allDebts.value || [])
    .filter((d: any) => d.status === "belum_lunas")
    .reduce((sum: number, d: any) => sum + (d.jumlah || 0), 0)
);

const countBelumLunas = computed(() =>
  (allDebts.value || []).filter((d: any) => d.status === "belum_lunas").length
);

const countLunas = computed(() =>
  (allDebts.value || []).filter((d: any) => d.status === "lunas").length
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

function isOverdue(jatuhTempo: string, status: string) {
  if (!jatuhTempo || status === "lunas") return false;
  return new Date(jatuhTempo) < new Date();
}

// Export to Excel
async function exportExcel() {
  try {
    const dataRows = (debts.value || []).map((d: any) => ({
      nama_debitur: d.nama_debitur,
      no_wa: d.no_wa || "",
      jumlah: Number(d.jumlah || 0),
      tanggal_hutang: d.tanggal_hutang,
      jatuh_tempo: d.jatuh_tempo || "",
      status: d.status === "lunas" ? "Lunas" : "Belum Lunas",
      keterangan: d.keterangan || "",
    }));

    const mod: any = await import("exceljs");
    const Workbook = mod.Workbook || mod.default?.Workbook || mod.default || mod;
    const wb: any = new Workbook();
    const ws = wb.addWorksheet("Hutang");

    const headers = ["Nama Debitur", "No WA", "Jumlah", "Tanggal Hutang", "Jatuh Tempo", "Status", "Keterangan"];
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
        r.nama_debitur,
        r.no_wa,
        r.jumlah,
        r.tanggal_hutang,
        r.jatuh_tempo,
        r.status,
        r.keterangan,
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
    a.download = `hutang_${umkm.value?.nama_usaha || "umkm"}.xlsx`;
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
  title: `Hutang - ${umkm.value?.nama_usaha || "Portal"}`,
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
          <h1 class="text-2xl font-bold text-gray-800 dark:text-white">📝 Hutang Pelanggan</h1>
          <p class="text-gray-600 dark:text-gray-400">{{ umkm?.nama_usaha }}</p>
        </div>
      </div>

      <!-- Total Summary -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700 mb-6">
        <div class="flex items-center justify-between mb-4">
          <div class="text-gray-600 dark:text-gray-400">Total Piutang Belum Lunas</div>
          <div class="text-2xl font-bold text-red-600">{{ fmtMoney(totalBelumLunas) }}</div>
        </div>
        <div class="flex gap-2 text-sm">
          <span class="px-3 py-1 bg-amber-100 text-amber-700 rounded-full">
            {{ countBelumLunas }} belum lunas
          </span>
          <span class="px-3 py-1 bg-emerald-100 text-emerald-700 rounded-full">
            {{ countLunas }} lunas
          </span>
        </div>
      </div>

      <!-- Filter & Export -->
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-4 shadow-lg border border-gray-100 dark:border-gray-700 mb-6">
        <div class="flex flex-col sm:flex-row items-center gap-4">
          <div class="flex items-center gap-2 flex-1">
            <span class="text-gray-600 dark:text-gray-400">Status:</span>
            <select
              v-model="filterStatus"
              class="px-4 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-800 dark:text-white"
            >
              <option value="all">Semua</option>
              <option value="belum_lunas">Belum Lunas</option>
              <option value="lunas">Lunas</option>
            </select>
          </div>
          <button
            @click="exportExcel"
            class="w-full sm:w-auto px-6 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-medium rounded-xl flex items-center justify-center gap-2 transition-all"
          >
            <span>📥</span> Download Excel
          </button>
        </div>
      </div>

      <!-- Debts List -->
      <div class="space-y-3">
        <div v-if="!debts || debts.length === 0" class="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-lg text-center">
          <div class="text-5xl mb-4">✨</div>
          <p class="text-gray-600 dark:text-gray-400">Tidak ada data hutang</p>
        </div>

        <div
          v-for="debt in debts"
          :key="debt.id"
          :class="[
            'bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-lg border-2',
            isOverdue(debt.jatuh_tempo, debt.status)
              ? 'border-red-300 dark:border-red-800'
              : 'border-gray-100 dark:border-gray-700'
          ]"
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <!-- Name & Status -->
              <div class="flex items-center gap-2 mb-2">
                <span class="font-bold text-lg text-gray-800 dark:text-white">
                  {{ debt.nama_debitur }}
                </span>
                <span
                  :class="[
                    'px-2 py-0.5 rounded-full text-xs font-medium',
                    debt.status === 'lunas'
                      ? 'bg-emerald-100 text-emerald-700'
                      : 'bg-amber-100 text-amber-700'
                  ]"
                >
                  {{ debt.status === 'lunas' ? '✅ Lunas' : '⏳ Belum Lunas' }}
                </span>
                <span
                  v-if="isOverdue(debt.jatuh_tempo, debt.status)"
                  class="px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700"
                >
                  ⚠️ Jatuh Tempo
                </span>
              </div>

              <!-- Amount -->
              <div class="font-bold text-xl text-red-600 mb-2">
                {{ fmtMoney(debt.jumlah) }}
              </div>

              <!-- Details -->
              <div class="text-gray-500 dark:text-gray-400 text-sm space-y-1">
                <div>📅 Tanggal: {{ fmtDate(debt.tanggal_hutang) }}</div>
                <div v-if="debt.jatuh_tempo">⏰ Jatuh Tempo: {{ fmtDate(debt.jatuh_tempo) }}</div>
                <div v-if="debt.no_wa">📱 {{ debt.no_wa }}</div>
                <div v-if="debt.keterangan" class="mt-2 text-gray-600 dark:text-gray-400">
                  📝 {{ debt.keterangan }}
                </div>
              </div>
            </div>

            <!-- Icon -->
            <div class="text-4xl ml-4">
              {{ debt.status === 'lunas' ? '✅' : '💸' }}
            </div>
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
