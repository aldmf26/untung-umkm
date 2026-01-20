<script setup lang="ts">
import {
  eachWeekOfInterval,
  startOfWeek,
  addDays,
  format,
  subMonths,
} from "date-fns";
import {
  VisXYContainer,
  VisLine,
  VisAxis,
  VisArea,
  VisCrosshair,
  VisTooltip,
} from "@unovis/vue";

const props = defineProps<{
  umkmId: string;
}>();

const cardRef = useTemplateRef<HTMLElement | null>("cardRef");

// Date range - default last 3 months
const selectedMonths = ref(3);
const monthOptions = [
  { label: '1 Bulan', value: 1 },
  { label: '3 Bulan', value: 3 },
  { label: '6 Bulan', value: 6 },
  { label: '12 Bulan', value: 12 },
];

const range = computed(() => ({
  start: subMonths(new Date(), selectedMonths.value),
  end: new Date(),
}));

type DataRecord = {
  date: Date;
  amount: number;
};

const { width } = useElementSize(cardRef);
const data = ref<DataRecord[]>([]);
const supabase = useSupabaseClient();

async function fetchReports() {
  const start = range.value.start.toISOString().split("T")[0];
  const end = range.value.end.toISOString().split("T")[0];

  const { data: reports } = await supabase
    .from("weekly_reports")
    .select("periode_mulai, uang_masuk, uang_keluar")
    .eq("umkm_id", props.umkmId)
    .gte("periode_mulai", start)
    .lte("periode_selesai", end)
    .order("periode_mulai", { ascending: true });

  const rows = (reports || []) as Array<{
    periode_mulai: string;
    uang_masuk: number;
    uang_keluar: number;
  }>;

  // Group by week
  const weeks = eachWeekOfInterval(range.value, { weekStartsOn: 1 });
  data.value = weeks.map((ws) => {
    const startOfW = startOfWeek(ws, { weekStartsOn: 1 });
    const endOfW = addDays(startOfW, 6);
    const amt = rows.reduce((acc, r) => {
      const d = new Date(r.periode_mulai);
      if (d >= startOfW && d <= endOfW) {
        return acc + ((r.uang_masuk || 0) - (r.uang_keluar || 0));
      }
      return acc;
    }, 0);
    return { date: startOfW, amount: amt };
  });
}

watch(
  [() => props.umkmId, selectedMonths],
  () => {
    if (!props.umkmId) return;
    fetchReports();
  },
  { immediate: true }
);

const x = (_: DataRecord, i: number) => i;
const y = (d: DataRecord) => d.amount;

const total = computed(() =>
  data.value.reduce((acc: number, { amount }) => acc + amount, 0)
);

const formatNumber = new Intl.NumberFormat("id-ID", {
  style: "currency",
  currency: "IDR",
  maximumFractionDigits: 0,
}).format;

const formatDate = (date: Date): string => format(date, "d MMM");

const xTicks = (i: number) => {
  if (i === 0 || i === data.value.length - 1 || !data.value[i]) return "";
  return formatDate(data.value[i].date);
};

const template = (d: DataRecord) =>
  `${formatDate(d.date)}: ${formatNumber(d.amount)}`;
</script>

<template>
  <div
    ref="cardRef"
    class="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg border border-gray-100 dark:border-gray-700"
  >
    <!-- Header -->
    <div class="flex items-center justify-between mb-4">
      <div>
        <h2 class="text-lg font-bold text-gray-800 dark:text-white flex items-center gap-2">
          <span>📈</span> Tren Untung/Rugi
        </h2>
        <p
          class="text-2xl font-bold mt-1"
          :class="total >= 0 ? 'text-emerald-600' : 'text-red-600'"
        >
          {{ formatNumber(total) }}
        </p>
      </div>
      <!-- Date Filter -->
      <select
        v-model="selectedMonths"
        class="px-4 py-2 rounded-xl border border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-800 dark:text-white text-sm"
      >
        <option v-for="opt in monthOptions" :key="opt.value" :value="opt.value">
          {{ opt.label }}
        </option>
      </select>
    </div>

    <!-- Chart -->
    <div v-if="data.length > 1" class="h-48">
      <VisXYContainer
        :data="data"
        :padding="{ top: 20 }"
        class="h-full"
        :width="width"
      >
        <VisLine :x="x" :y="y" color="#10b981" />
        <VisArea :x="x" :y="y" color="#10b981" :opacity="0.1" />
        <VisAxis type="x" :x="x" :tick-format="xTicks" />
        <VisCrosshair color="#10b981" :template="template" />
        <VisTooltip />
      </VisXYContainer>
    </div>

    <!-- Empty state -->
    <div v-else class="h-48 flex items-center justify-center text-gray-400">
      <div class="text-center">
        <div class="text-3xl mb-2">📊</div>
        <p>Belum cukup data untuk grafik</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.unovis-xy-container {
  --vis-crosshair-line-stroke-color: #10b981;
  --vis-crosshair-circle-stroke-color: #fff;
  --vis-axis-grid-color: #e5e7eb;
  --vis-axis-tick-color: #e5e7eb;
  --vis-axis-tick-label-color: #6b7280;
  --vis-tooltip-background-color: #fff;
  --vis-tooltip-border-color: #e5e7eb;
  --vis-tooltip-text-color: #111827;
}
</style>
