import { redirect } from 'next/navigation';

import { readAuthPayload } from '@/lib/auth';
import { db } from '@/lib/db';
import {
  buildExerciseAnalytics,
  parseDaysJson,
  summarizeTrends,
  type DayJsonItem,
  type SnapshotLike,
} from '@/lib/progress';

type SnapshotItem = {
  id: string;
  period: string;
  sessionsDone: number;
  daysJson: unknown;
};


export default async function ClientPage() {
  const auth = await readAuthPayload();
  if (!auth || auth.role !== 'CLIENT') {
    redirect('/login');
  }

  const client = await db.clientProfile.findUnique({
    where: { userId: auth.userId },
    include: {
      snapshots: {
        orderBy: { createdAt: 'desc' },
      },
    },
  });

  if (!client) {
    return (
      <main className="container">
        <h1>Мой прогресс</h1>
        <p>Профиль клиента не найден.</p>
      </main>
    );
  }

  const snapshots = client.snapshots as SnapshotItem[];
  const latest = snapshots[0] as SnapshotLike | undefined;
  const prev = snapshots[1] as SnapshotLike | undefined;
  const analytics = latest ? buildExerciseAnalytics(latest, prev) : [];
  const summary = summarizeTrends(analytics);

  return (
    <main className="container">
      <h1>Мой прогресс</h1>
      <p>{client.fullName}</p>

      {latest && prev && (
        <section className="card" style={{ marginBottom: 12 }}>
          <h3>Аналитика: {latest.period} vs {prev.period}</h3>
          <div className="row">
            <div className="card" style={{ flex: 1 }}>
              <strong>Прогрессия</strong>
              <div>{summary.progression}</div>
            </div>
            <div className="card" style={{ flex: 1 }}>
              <strong>Стагнация</strong>
              <div>{summary.stagnation}</div>
            </div>
            <div className="card" style={{ flex: 1 }}>
              <strong>Регрессия</strong>
              <div>{summary.regression}</div>
            </div>
          </div>
          {analytics.slice(0, 8).map((a) => (
            <div key={a.exercise} style={{ marginTop: 6 }}>
              • {a.exercise}: {a.previous.toFixed(1)} → {a.latest.toFixed(1)} кг ({a.delta > 0 ? '+' : ''}
              {a.delta.toFixed(1)})
            </div>
          ))}
        </section>
      )}

      {snapshots.length === 0 ? (
        <p>Нет данных за периоды.</p>
      ) : (
        snapshots.map((s: SnapshotItem) => {
          const days: DayJsonItem[] = parseDaysJson(s.daysJson);
          return (
            <section className="card" key={s.id} style={{ marginBottom: 12 }}>
              <h3>Период: {s.period}</h3>
              <p>Отходил занятий: {s.sessionsDone}</p>
              {days.map((d: DayJsonItem, idx: number) => {
                const item = d as Record<string, unknown>;
                const title = (item.title as string) ?? 'Тренировка';
                const ex = Array.isArray(item.exercises) ? item.exercises : [];
                return (
                  <div key={idx} style={{ marginTop: 8 }}>
                    <strong>День {(item.dayNumber as number) ?? idx + 1} ({title})</strong>
                    {ex.map((row, exIdx: number) => {
                      const e = row as Record<string, unknown>;
                      return (
                        <div key={exIdx}>
                          • {(e.name as string) ?? 'Упражнение'} — {e.weightKg == null ? '—' : `${e.weightKg} кг`}
                          {row.weightKg == null ? '—' : `${row.weightKg} кг`}
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </section>
          );
        })
      )}
    </main>
  );
}