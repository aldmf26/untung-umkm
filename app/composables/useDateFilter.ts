import { ref, computed } from 'vue';

export type DateFilterType = 'month' | 'year' | 'custom';

export function useDateFilter(opts?: { defaultType?: DateFilterType; defaultMonth?: string }) {
  const now = new Date();
  const defaultType = opts?.defaultType || 'month';
  const defaultMonth = opts?.defaultMonth || `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

  const dateFilterType = ref<DateFilterType>(defaultType);
  const selectedMonth = ref<string>(defaultMonth); // 'YYYY-MM'
  const selectedYear = ref<number>(now.getFullYear());
  const fromDate = ref<string>(''); // 'YYYY-MM-DD'
  const toDate = ref<string>('');

  function setMonthRangeFromSelectedMonth() {
    const [yStr, mStr] = (selectedMonth.value || defaultMonth).split('-');
    const y = Number(yStr || now.getFullYear());
    const m = Number(mStr || now.getMonth() + 1);
    fromDate.value = `${String(y).padStart(4, '0')}-${String(m).padStart(2, '0')}-01`;
    const last = new Date(y, m, 0).getDate();
    toDate.value = `${String(y).padStart(4, '0')}-${String(m).padStart(2, '0')}-${String(last).padStart(2, '0')}`;
  }

  function setYearRange(y?: number) {
    const year = Number(y || selectedYear.value || now.getFullYear());
    fromDate.value = `${year}-01-01`;
    toDate.value = `${year}-12-31`;
  }

  // initialize to default month
  setMonthRangeFromSelectedMonth();

  async function apply(cb?: () => Promise<void> | void) {
    if (dateFilterType.value === 'month') {
      setMonthRangeFromSelectedMonth();
    } else if (dateFilterType.value === 'year') {
      setYearRange(selectedYear.value);
    }
    if (cb) await cb();
  }

  async function reset(cb?: () => Promise<void> | void) {
    dateFilterType.value = defaultType;
    selectedMonth.value = defaultMonth;
    selectedYear.value = now.getFullYear();
    setMonthRangeFromSelectedMonth();
    if (cb) await cb();
  }

  const label = computed(() => `${fromDate.value} — ${toDate.value}`);

  return {
    dateFilterType,
    selectedMonth,
    selectedYear,
    fromDate,
    toDate,
    setMonthRangeFromSelectedMonth,
    setYearRange,
    apply,
    reset,
    label,
  } as const;
}
