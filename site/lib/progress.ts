export type ExerciseJsonItem = {
  name?: string;
  weightKg?: number | null;
};

export type DayJsonItem = {
  dayNumber?: number;
  title?: string;
  exercises?: ExerciseJsonItem[];
};

export type SnapshotLike = {
  period: string;
  sessionsDone: number;
  daysJson: unknown;
};

export type ExerciseTrend = 'progression' | 'regression' | 'stagnation';

export type ExerciseAnalytics = {
  exercise: string;
  latest: number;
  previous: number;
  delta: number;
  trend: ExerciseTrend;
};

export function parseDaysJson(daysJson: unknown): DayJsonItem[] {
  if (!Array.isArray(daysJson)) return [];
  return daysJson as DayJsonItem[];
}

function normalizeExerciseName(name: string) {
  return name.trim().toLowerCase().replaceAll('ё', 'е');
}

function extractExerciseAverages(days: DayJsonItem[]) {
  const bucket = new Map<string, { label: string; sum: number; count: number }>();

  for (const day of days) {
    const ex = Array.isArray(day.exercises) ? day.exercises : [];
    for (const row of ex) {
      if (!row?.name) continue;
      if (typeof row.weightKg !== 'number') continue;
      const key = normalizeExerciseName(row.name);
      const prev = bucket.get(key);
      if (!prev) {
        bucket.set(key, { label: row.name.trim(), sum: row.weightKg, count: 1 });
      } else {
        prev.sum += row.weightKg;
        prev.count += 1;
      }
    }
  }

  const averages = new Map<string, { label: string; avg: number }>();
  for (const [k, v] of bucket.entries()) {
    averages.set(k, { label: v.label, avg: v.sum / v.count });
  }
  return averages;
}

function toTrend(delta: number): ExerciseTrend {
  if (delta > 0.5) return 'progression';
  if (delta < -0.5) return 'regression';
  return 'stagnation';
}

export function buildExerciseAnalytics(latest: SnapshotLike, previous?: SnapshotLike | null) {
  if (!previous) return [] as ExerciseAnalytics[];

  const latestAvg = extractExerciseAverages(parseDaysJson(latest.daysJson));
  const prevAvg = extractExerciseAverages(parseDaysJson(previous.daysJson));

  const out: ExerciseAnalytics[] = [];
  for (const [key, now] of latestAvg.entries()) {
    const before = prevAvg.get(key);
    if (!before) continue;
    const delta = now.avg - before.avg;
    out.push({
      exercise: now.label,
      latest: now.avg,
      previous: before.avg,
      delta,
      trend: toTrend(delta),
    });
  }

  return out.sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta));
}

export function summarizeTrends(items: ExerciseAnalytics[]) {
  return items.reduce(
    (acc, it) => {
      acc[it.trend] += 1;
      return acc;
    },
    { progression: 0, regression: 0, stagnation: 0 },
  );
}