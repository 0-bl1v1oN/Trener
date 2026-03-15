import { NextResponse } from 'next/server';
import { z } from 'zod';

import { db } from '@/lib/db';
import { requireAdmin } from '@/lib/guards';
import { buildExerciseAnalytics, summarizeTrends, type SnapshotLike } from '@/lib/progress';

const querySchema = z.object({
  clientKey: z.string().min(1),
});

export async function POST(req: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await req.json();
  const parsed = querySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Укажите clientKey' }, { status: 400 });
  }

  const profile = await db.clientProfile.findUnique({
    where: { clientKey: parsed.data.clientKey },
    include: { snapshots: { orderBy: { createdAt: 'desc' } } },
  });

  if (!profile) {
    return NextResponse.json({ error: 'Клиент не найден' }, { status: 404 });
  }

  const snapshots = profile.snapshots as SnapshotLike[];
  const latest = snapshots[0] ?? null;
  const previous = snapshots[1] ?? null;

  const exerciseAnalytics = latest ? buildExerciseAnalytics(latest, previous) : [];
  const trendSummary = summarizeTrends(exerciseAnalytics);

  return NextResponse.json({
    client: {
      clientKey: profile.clientKey,
      fullName: profile.fullName,
    },
    snapshots,
    analytics: {
      hasComparison: Boolean(latest && previous),
      latestPeriod: latest?.period ?? null,
      previousPeriod: previous?.period ?? null,
      sessionsDelta: latest && previous ? latest.sessionsDone - previous.sessionsDone : null,
      trendSummary,
      exerciseAnalytics,
    },
  });
}