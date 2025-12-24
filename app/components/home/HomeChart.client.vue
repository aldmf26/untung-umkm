<script setup lang="ts">
import {
  eachDayOfInterval,
  eachWeekOfInterval,
  eachMonthOfInterval,
  format,
  addDays,
  startOfWeek,
} from "date-fns";
import {
  VisXYContainer,
  VisLine,
  VisAxis,
  VisArea,
  VisCrosshair,
  VisTooltip,
} from "@unovis/vue";
import type { Period, Range } from "~/types";

const cardRef = useTemplateRef<HTMLElement | null>("cardRef");

const props = defineProps<{
  period: Period;
  range: Range;
}>();

type DataRecord = {
  date: Date;
  amount: number;
};

const { width } = useElementSize(cardRef);

const data = ref<DataRecord[]>([]);

const supabase = useSupabaseClient();

async function fetchPaymentsAndAggregate() {
  // Query payments in the selected range
  const start = props.range.start.toISOString().split("T")[0];
  const end = props.range.end.toISOString().split("T")[0];

  const { data: payments } = await supabase
    .from("payments")
    .select("tanggal_bayar, jumlah")
    .gte("tanggal_bayar", start)
    .lte("tanggal_bayar", end);

  const rows = (payments || []) as Array<{
    tanggal_bayar: string;
    jumlah: number;
  }>;

  // Helper to sum payments for an interval
  const sumBetween = (from: Date, to: Date) => {
    return rows.reduce((acc, p) => {
      const d = new Date(p.tanggal_bayar);
      if (d >= from && d <= to) return acc + (p.jumlah || 0);
      return acc;
    }, 0);
  };

  if (props.period === "daily") {
    const dates = eachDayOfInterval(props.range);
    data.value = dates.map((d) => ({
      date: d,
      amount: sumBetween(
        new Date(d.setHours(0, 0, 0, 0)),
        new Date(d.setHours(23, 59, 59, 999))
      ),
    }));
  } else if (props.period === "weekly") {
    const weeks = eachWeekOfInterval(props.range, { weekStartsOn: 1 });
    data.value = weeks.map((ws) => {
      const startOfW = startOfWeek(ws, { weekStartsOn: 1 });
      const endOfW = addDays(startOfW, 6);
      return {
        date: startOfW,
        amount: sumBetween(
          new Date(startOfW.setHours(0, 0, 0, 0)),
          new Date(endOfW.setHours(23, 59, 59, 999))
        ),
      };
    });
  } else {
    const months = eachMonthOfInterval(props.range);
    data.value = months.map((m) => ({
      date: m,
      amount: rows.reduce((acc, p) => {
        const d = new Date(p.tanggal_bayar);
        if (
          d.getMonth() === m.getMonth() &&
          d.getFullYear() === m.getFullYear()
        )
          return acc + (p.jumlah || 0);
        return acc;
      }, 0),
    }));
  }
}

watch(
  [() => props.period, () => props.range],
  () => {
    fetchPaymentsAndAggregate();
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

const formatDate = (date: Date): string => {
  return {
    daily: format(date, "d MMM"),
    weekly: format(date, "d MMM"),
    monthly: format(date, "MMM yyyy"),
  }[props.period];
};

const xTicks = (i: number) => {
  if (i === 0 || i === data.value.length - 1 || !data.value[i]) {
    return "";
  }

  return formatDate(data.value[i].date);
};

const template = (d: DataRecord) =>
  `${formatDate(d.date)}: ${formatNumber(d.amount)}`;
</script>

<template>
  <UCard
    ref="cardRef"
    :ui="{ root: 'overflow-visible', body: '!px-0 !pt-0 !pb-3' }"
  >
    <template #header>
      <div>
        <p class="text-xs text-muted uppercase mb-1.5">Revenue</p>
        <p class="text-3xl text-highlighted font-semibold">
          {{ formatNumber(total) }}
        </p>
      </div>
    </template>

    <VisXYContainer
      :data="data"
      :padding="{ top: 40 }"
      class="h-96"
      :width="width"
    >
      <VisLine :x="x" :y="y" color="var(--ui-primary)" />
      <VisArea :x="x" :y="y" color="var(--ui-primary)" :opacity="0.1" />

      <VisAxis type="x" :x="x" :tick-format="xTicks" />

      <VisCrosshair color="var(--ui-primary)" :template="template" />

      <VisTooltip />
    </VisXYContainer>
  </UCard>
</template>

<style scoped>
.unovis-xy-container {
  --vis-crosshair-line-stroke-color: var(--ui-primary);
  --vis-crosshair-circle-stroke-color: var(--ui-bg);

  --vis-axis-grid-color: var(--ui-border);
  --vis-axis-tick-color: var(--ui-border);
  --vis-axis-tick-label-color: var(--ui-text-dimmed);

  --vis-tooltip-background-color: var(--ui-bg);
  --vis-tooltip-border-color: var(--ui-border);
  --vis-tooltip-text-color: var(--ui-text-highlighted);
}
</style>
