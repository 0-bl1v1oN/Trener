import { NextResponse } from 'next/server';
import { z } from 'zod';

import { db } from '@/lib/db';
import { requireAdmin } from '@/lib/guards';

const importSchema = z.object({
  period: z.string().min(2),
  clients: z.array(
    z.object({
      clientId: z.string().min(1),
      clientName: z.string().min(1),
      sessionsDone: z.number().int().nonnegative(),
      days: z.array(z.record(z.any())),
    }),
  ),
});

export async function POST(req: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await req.json();
  const parsed = importSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Неверный формат JSON' }, { status: 400 });
  }

  let imported = 0;

  for (const c of parsed.data.clients) {
    const profile = await db.clientProfile.findUnique({ where: { clientKey: c.clientId } });
    if (!profile) continue;

    await db.progressSnapshot.upsert({
      where: {
        clientId_period: {
          clientId: profile.id,
          period: parsed.data.period,
        },
      },
      update: {
        sessionsDone: c.sessionsDone,
        daysJson: c.days,
      },
      create: {
        clientId: profile.id,
        period: parsed.data.period,
        sessionsDone: c.sessionsDone,
        daysJson: c.days,
      },
    });

    imported += 1;
  }

  return NextResponse.json({ imported });
}