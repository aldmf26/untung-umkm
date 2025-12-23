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

function fmtDate(d?: string) {
  if (!d) return "-";
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(d));
}
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
          <!-- NOTE: The `-ms-1` class is used to align with the `DashboardSidebarCollapse` button here. -->
          <HomeDateRangePicker v-model="range" class="-ms-1" />

          <HomePeriodSelect v-model="period" :range="range" />
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <div class="space-y-6">
        <!-- Top summary cards (Nuxt UI style) -->
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

        <!-- Chart + Recent Joins -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div
            class="lg:col-span-2 p-4 bg-elevated rounded-lg border shadow-sm"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm text-muted">Ringkasan Mingguan</div>
              <div>
                <RouterLink to="/dashboard/laporan">
                  <UButton size="sm" variant="ghost">Lihat Laporan</UButton>
                </RouterLink>
              </div>
            </div>

            <HomeChart :period="period" :range="range" />
          </div>

          <div class="p-4 bg-elevated rounded-lg border shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-lg font-medium">Pendaftar Baru</div>
              </div>
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
                      <td class="py-4 text-muted" colspan="4">
                        Belum ada UMKM.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <!-- Stats & Sales -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div class="p-4 bg-elevated rounded-lg border shadow-sm">
            <HomeStats :period="period" :range="range" />
          </div>

          <div class="p-4 bg-elevated rounded-lg border shadow-sm">
            <HomeSales :period="period" :range="range" />
          </div>
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
