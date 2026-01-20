<script setup lang="ts">
// Portal client - no auth required, using UUID from URL
definePageMeta({ layout: false });

const route = useRoute();
const supabase = useSupabaseClient();

const umkmId = computed(() => route.params.id as string);

// Load UMKM profile
const { data: umkm, error: umkmError } = await useAsyncData(
  `portal-umkm-${umkmId.value}`,
  async () => {
    const { data, error } = await supabase
      .from("umkm_profiles")
      .select("*")
      .eq("id", umkmId.value)
      .single();
    if (error) throw error;
    return data;
  }
);

// Load summary data
const { data: reports } = await useAsyncData(
  `portal-reports-${umkmId.value}`,
  async () => {
    const { data } = await supabase
      .from("weekly_reports")
      .select("*")
      .eq("umkm_id", umkmId.value)
      .order("periode_mulai", { ascending: false });
    return data || [];
  }
);

const { data: payments } = await useAsyncData(
  `portal-payments-${umkmId.value}`,
  async () => {
    const { data } = await supabase
      .from("payments")
      .select("*")
      .eq("umkm_id", umkmId.value)
      .order("tanggal_bayar", { ascending: false });
    return data || [];
  }
);

const { data: debts } = await useAsyncData(
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

// Computed stats
const totalLaporan = computed(() => (reports.value || []).length);
const totalPembayaran = computed(() =>
  (payments.value || []).reduce((sum: number, p: any) => sum + (p.jumlah || 0), 0)
);
const totalHutangBelumLunas = computed(() =>
  (debts.value || [])
    .filter((d: any) => d.status === "belum_lunas")
    .reduce((sum: number, d: any) => sum + (d.jumlah || 0), 0)
);

// Latest report
const latestReport = computed(() => (reports.value || [])[0]);

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
    month: "long",
    year: "numeric",
  }).format(new Date(d));
}

useHead({
  title: umkm.value ? `Portal ${umkm.value.nama_usaha}` : "Portal Client",
});
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-emerald-50 to-teal-100 dark:from-gray-900 dark:to-gray-800">
    <!-- Error State -->
    <div v-if="umkmError || !umkm" class="flex items-center justify-center min-h-screen p-6">
      <div class="text-center">
        <div class="text-6xl mb-4">😕</div>
        <h1 class="text-2xl font-bold text-gray-800 dark:text-white mb-2">Data Tidak Ditemukan</h1>
        <p class="text-gray-600 dark:text-gray-400">Link yang Anda akses tidak valid atau sudah tidak tersedia.</p>
      </div>
    </div>

    <!-- Main Content -->
    <div v-else class="max-w-4xl mx-auto px-4 py-8">
      <!-- Header -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center w-20 h-20 bg-emerald-500 rounded-full mb-4">
          <span class="text-3xl">🏪</span>
        </div>
        <h1 class="text-3xl font-bold text-gray-800 dark:text-white">{{ umkm.nama_usaha }}</h1>
        <p class="text-gray-600 dark:text-gray-400 mt-1">{{ umkm.nama_pemilik }}</p>
        <div class="flex items-center justify-center gap-2 mt-2">
          <span
            :class="[
              'px-3 py-1 rounded-full text-sm font-medium',
              umkm.status === 'active' ? 'bg-emerald-100 text-emerald-700' :
              umkm.status === 'trial' ? 'bg-amber-100 text-amber-700' :
              'bg-gray-100 text-gray-700'
            ]"
          >
            {{ umkm.status === 'active' ? '✅ Aktif' : umkm.status === 'trial' ? '🎁 Trial' : '⏸️ Tidak Aktif' }}
          </span>
        </div>
      </div>

      <!-- Summary Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        <!-- Total Laporan -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700">
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 bg-blue-100 dark:bg-blue-900/30 rounded-xl flex items-center justify-center">
              <span class="text-3xl">📊</span>
            </div>
            <div>
              <div class="text-3xl font-bold text-gray-800 dark:text-white">{{ totalLaporan }}</div>
              <div class="text-gray-500 dark:text-gray-400">Laporan</div>
            </div>
          </div>
        </div>

        <!-- Total Pembayaran -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700">
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 bg-emerald-100 dark:bg-emerald-900/30 rounded-xl flex items-center justify-center">
              <span class="text-3xl">💰</span>
            </div>
            <div>
              <div class="text-xl font-bold text-emerald-600">{{ fmtMoney(totalPembayaran) }}</div>
              <div class="text-gray-500 dark:text-gray-400">Total Bayar</div>
            </div>
          </div>
        </div>

        <!-- Hutang Pelanggan -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700">
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 bg-red-100 dark:bg-red-900/30 rounded-xl flex items-center justify-center">
              <span class="text-3xl">📝</span>
            </div>
            <div>
              <div class="text-xl font-bold text-red-600">{{ fmtMoney(totalHutangBelumLunas) }}</div>
              <div class="text-gray-500 dark:text-gray-400">Piutang</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Profit/Loss Chart -->
      <div class="mb-8">
        <PortalChart :umkm-id="umkmId" />
      </div>

      <!-- Latest Report Preview -->
      <div v-if="latestReport" class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700 mb-8">
        <h2 class="text-lg font-bold text-gray-800 dark:text-white mb-4 flex items-center gap-2">
          <span>📈</span> Laporan Terakhir
        </h2>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <div class="text-sm text-gray-500 dark:text-gray-400">Periode</div>
            <div class="font-medium">{{ fmtDate(latestReport.periode_mulai) }} - {{ fmtDate(latestReport.periode_selesai) }}</div>
          </div>
          <div>
            <div class="text-sm text-gray-500 dark:text-gray-400">Untung/Rugi</div>
            <div
              :class="[
                'font-bold text-lg',
                (latestReport.uang_masuk - latestReport.uang_keluar) >= 0 ? 'text-emerald-600' : 'text-red-600'
              ]"
            >
              {{ fmtMoney(latestReport.uang_masuk - latestReport.uang_keluar) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Navigation Menu -->
      <div class="grid grid-cols-2 gap-4">
        <NuxtLink
          :to="`/portal/${umkmId}/laporan`"
          class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700 hover:shadow-xl hover:scale-105 transition-all duration-200 text-center"
        >
          <div class="text-4xl mb-3">📊</div>
          <div class="font-bold text-gray-800 dark:text-white text-lg">Laporan</div>
          <div class="text-gray-500 dark:text-gray-400 text-sm mt-1">Lihat semua laporan</div>
        </NuxtLink>

        <NuxtLink
          :to="`/portal/${umkmId}/pembayaran`"
          class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700 hover:shadow-xl hover:scale-105 transition-all duration-200 text-center"
        >
          <div class="text-4xl mb-3">💳</div>
          <div class="font-bold text-gray-800 dark:text-white text-lg">Pembayaran</div>
          <div class="text-gray-500 dark:text-gray-400 text-sm mt-1">Riwayat pembayaran</div>
        </NuxtLink>

        <NuxtLink
          :to="`/portal/${umkmId}/hutang`"
          class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700 hover:shadow-xl hover:scale-105 transition-all duration-200 text-center"
        >
          <div class="text-4xl mb-3">📝</div>
          <div class="font-bold text-gray-800 dark:text-white text-lg">Hutang</div>
          <div class="text-gray-500 dark:text-gray-400 text-sm mt-1">Data piutang pelanggan</div>
        </NuxtLink>

        <a
          :href="`https://wa.me/${(umkm.no_wa || '').replace(/^0/, '62')}`"
          target="_blank"
          class="bg-emerald-500 hover:bg-emerald-600 rounded-2xl p-6 shadow-lg hover:shadow-xl hover:scale-105 transition-all duration-200 text-center text-white"
        >
          <div class="text-4xl mb-3">💬</div>
          <div class="font-bold text-lg">Hubungi Kami</div>
          <div class="text-emerald-100 text-sm mt-1">Chat via WhatsApp</div>
        </a>
      </div>

      <!-- Footer -->
      <div class="text-center mt-12 text-gray-500 dark:text-gray-400 text-sm">
        <p>Powered by <strong>Laporku</strong></p>
        <p class="mt-1">Pendampingan Keuangan UMKM</p>
      </div>
    </div>
  </div>
</template>
