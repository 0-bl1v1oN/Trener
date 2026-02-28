import { redirect } from 'next/navigation';

import { readAuthPayload } from '@/lib/auth';
import { db } from '@/lib/db';

type DayJsonItem = {
  dayNumber?: number;
  title?: string;
  exercises?: ExerciseJsonItem[];
};

type ExerciseJsonItem = {
  name?: string;
  weightKg?: number | null;
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
        orderBy: { period: 'desc' },
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

  return (
    <main className="container">
      <h1>Мой прогресс</h1>
      <p>{client.fullName}</p>

      {client.snapshots.length === 0 ? (
        <p>Нет данных за периоды.</p>
      ) : (
        client.snapshots.map((s) => {
          const days = Array.isArray(s.daysJson) ? s.daysJson : [];
          return (
            <section className="card" key={s.id} style={{ marginBottom: 12 }}>
              <h3>Период: {s.period}</h3>
              <p>Отходил занятий: {s.sessionsDone}</p>
              {days.map((d, idx) => {
                const item = d as Record<string, unknown>;
                const title = (item.title as string) ?? 'Тренировка';
                const ex = Array.isArray(item.exercises) ? item.exercises : [];
                return (
                  <div key={idx} style={{ marginTop: 8 }}>
                    <strong>День {(item.dayNumber as number) ?? idx + 1} ({title})</strong>
                    {ex.map((e, exIdx) => {
                      const row = e as Record<string, unknown>;
                      return (
                        <div key={exIdx}>
                          • {(row.name as string) ?? 'Упражнение'} —{' '}
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