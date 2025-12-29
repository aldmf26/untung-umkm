<script setup lang="ts">
import { sub } from "date-fns";
import type { DropdownMenuItem } from "@nuxt/ui";
import type { Period, Range } from "~/types";

definePageMeta({
  middleware: "auth",
  layout: "dashboard",
});

const { isNotificationsSlideoverOpen } = useDashboard();

const items = [
  [
    {
      label: "New Input",
      icon: "i-lucide-file-plus",
      to: "/dashboard/laporan/input",
    },
    {
      label: "New customer",
      icon: "i-lucide-user-plus",
      to: "/dashboard/customers",
    },
  ],
] satisfies DropdownMenuItem[][];

const range = shallowRef<Range>({
  start: sub(new Date(), { days: 14 }),
  end: new Date(),
});
const period = ref<Period>("daily");

// Load UMKM profiles for dashboard summary
const { data: umkmProfiles, refresh: refreshUmkm } = await useAsyncData(
  "dashboard-umkm",
  async () => {
    const supabase = useSupabaseClient();
    const { data } = await supabase
      .from("umkm_profiles")
      .select("*")
      .order("tanggal_join", { ascending: false });

    return data || [];
  },
  { immediate: true }
);

const totalCount = computed(() => (umkmProfiles.value || []).length);
const countActive = computed(
  () =>
    (umkmProfiles.value || []).filter((p: any) => p.status === "active").length
);
const countTrial = computed(
  () =>
    (umkmProfiles.value || []).filter((p: any) => p.status === "trial").length
);
const countInactive = computed(
  () =>
    (umkmProfiles.value || []).filter((p: any) => p.status === "inactive")
      .length
);

const recentJoins = computed(() => (umkmProfiles.value || []).slice(0, 5));

// === PENDAPATAN DARI TABEL PAYMENTS ===
const supabase = useSupabaseClient();

// Pendapatan bulan ini
const currentMonthStart = new Date(
  new Date().getFullYear(),
  new Date().getMonth(),
  1
);
const currentMonthEnd = new Date(
  new Date().getFullYear(),
  new Date().getMonth() + 1,
  0
);

const { data: paymentsThisMonth } = await useAsyncData(
  "payments-this-month",
  async () => {
    const { data } = await supabase
      .from("payments")
      .select("jumlah")
      .gte("tanggal_bayar", currentMonthStart.toISOString().split("T")[0])
      .lte("tanggal_bayar", currentMonthEnd.toISOString().split("T")[0]);

    return data || [];
  }
);

const pendapatanBulanIni = computed(() => {
  return (paymentsThisMonth.value || []).reduce(
    (sum, p: any) => sum + (p.jumlah || 0),
    0
  );
});

// Total pendapatan all time
const { data: allPayments } = await useAsyncData("payments-all", async () => {
  const { data } = await supabase.from("payments").select("jumlah");
  return data || [];
});

const totalPendapatan = computed(() => {
  return (allPayments.value || []).reduce(
    (sum, p: any) => sum + (p.jumlah || 0),
    0
  );
});

// Payments in selected range (for dashboard summary)
const paymentsInRange = ref<any[]>([]);
async function fetchPaymentsInRange() {
  const start = range.value.start.toISOString().split("T")[0];
  const end = range.value.end.toISOString().split("T")[0];
  const { data } = await supabase
    .from("payments")
    .select("umkm_id, jumlah")
    .gte("tanggal_bayar", start)
    .lte("tanggal_bayar", end);
  paymentsInRange.value = data || [];
}

watch(
  range,
  () => {
    fetchPaymentsInRange();
  },
  { immediate: true }
);

const payingCustomersCount = computed(
  () => new Set((paymentsInRange.value || []).map((p) => p.umkm_id)).size
);
const totalPaidInRange = computed(() =>
  (paymentsInRange.value || []).reduce(
    (s: number, p: any) => s + (p.jumlah || 0),
    0
  )
);

function fmtMoney(n: number) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
  }).format(n);
}

function fmtDate(d?: string) {
  if (!d) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(d));
}

useHead({
  title: "Dashboard",
});
</script>

<template>
  <UDashboardPanel id="home">
    <template #header>
      <UDashboardNavbar title="Home" :ui="{ right: 'gap-3' }">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UDropdownMenu :items="items">
            <UButton icon="i-lucide-plus" size="md" class="rounded-full" />
          </UDropdownMenu>
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <HomeDateRangePicker v-model="range" class="-ms-1" />
          <HomePeriodSelect v-model="period" :range="range" />
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <div class="space-y-6">
        <!-- Top summary cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div
            class="p-4 bg-elevated rounded-lg border shadow-sm flex flex-col"
          >
            <div class="text-sm text-muted">Total Klien</div>
            <div class="mt-2 text-3xl font-bold">{{ totalCount }}</div>
            <div class="mt-2 text-sm text-muted">
              Jumlah total klien terdaftar
            </div>
          </div>

          <div
            class="p-4 bg-elevated rounded-lg border shadow-sm flex flex-col"
          >
            <div class="text-sm text-muted">Active</div>
            <div class="mt-2 text-2xl font-semibold text-emerald-600">
              {{ countActive }}
            </div>
            <div class="mt-2 text-sm text-muted">Klien berbayar aktif</div>
          </div>

          <div
            class="p-4 bg-elevated rounded-lg border shadow-sm flex flex-col"
          >
            <div class="text-sm text-muted">Trial</div>
            <div class="mt-2 text-2xl font-semibold text-amber-600">
              {{ countTrial }}
            </div>
            <div class="mt-2 text-sm text-muted">Klien di masa trial</div>
          </div>

          <div
            class="p-4 bg-elevated rounded-lg border shadow-sm flex flex-col"
          >
            <div class="text-sm text-muted">Inactive</div>
            <div class="mt-2 text-2xl font-semibold text-red-600">
              {{ countInactive }}
            </div>
            <div class="mt-2 text-sm text-muted">Klien tidak aktif</div>
          </div>
        </div>

        <!-- Pendapatan Cards (Baru Ditambahkan) -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div
            class="p-4 bg-elevated rounded-lg border shadow-sm flex flex-col"
          >
            <div class="text-sm text-muted">Pendapatan Bulan Ini</div>
            <div class="mt-2 text-3xl font-bold text-green-600">
              {{ fmtMoney(pendapatanBulanIni) }}
            </div>
            <div class="mt-2 text-sm text-muted">
              Total pembayaran yang masuk bulan ini
            </div>
          </div>

          <div
            class="p-4 bg-elevated rounded-lg border shadow-sm flex flex-col"
          >
            <div class="text-sm text-muted">Total Pendapatan</div>
            <div class="mt-2 text-3xl font-bold text-green-600">
              {{ fmtMoney(totalPendapatan) }}
            </div>
            <div class="mt-2 text-sm text-muted">
              Semua pembayaran sejak awal
            </div>
          </div>
        </div>

        <!-- Chart + Recent Joins -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div
            class="lg:col-span-2 p-4 bg-elevated rounded-lg border shadow-sm"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-muted">Ringkasan Mingguan</div>
              <NuxtLink to="/dashboard/payments">
                <UButton size="sm" variant="ghost">Lihat Laporan</UButton>
              </NuxtLink>
            </div>

            <HomeChart :period="period" :range="range" />

            <div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div class="p-3 bg-elevated rounded-lg border">
                <div class="text-sm text-muted">Klien bayar (range)</div>
                <div class="mt-2 text-2xl font-bold">
                  {{ payingCustomersCount }}
                </div>
                <div class="mt-1 text-sm text-muted">
                  Jumlah UMKM yang menerima pembayaran dalam rentang terpilih
                </div>
              </div>

              <div class="p-3 bg-elevated rounded-lg border">
                <div class="text-sm text-muted">Total Pembayaran (range)</div>
                <div class="mt-2 text-2xl font-bold text-green-600">
                  {{ fmtMoney(totalPaidInRange) }}
                </div>
                <div class="mt-1 text-sm text-muted">
                  Total nilai pembayaran pada rentang terpilih
                </div>
              </div>
            </div>
          </div>

          <div class="p-4 bg-elevated rounded-lg border shadow-sm">
            <div class="flex items-center justify-between">
              <div class="text-lg font-medium">Pendaftar Baru</div>
              <RouterLink to="/dashboard/customers">
                <UButton size="sm" variant="ghost">Lihat Semua</UButton>
              </RouterLink>
            </div>

            <div class="mt-4">
              <div class="overflow-auto">
                <table class="min-w-full text-sm">
                  <thead class="text-left text-muted text-xs">
                    <tr>
                      <th class="pb-2">Nama</th>
                      <th class="pb-2">Tanggal Join</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="p in recentJoins" :key="p.id" class="border-t">
                      <td class="py-2">
                        {{ p.nama_usaha }}
                        <div class="text-muted text-xs">
                          {{ p.nama_pemilik }}
                        </div>
                      </td>
                      <td class="py-2">{{ fmtDate(p.tanggal_join) }}</td>
                    </tr>
                    <tr v-if="(recentJoins || []).length === 0">
                      <td class="py-4 text-muted" colspan="2">
                        Belum ada UMKM.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
