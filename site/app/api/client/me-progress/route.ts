import { NextResponse } from 'next/server';

import { db } from '@/lib/db';
import { requireClient } from '@/lib/guards';

export async function GET() {
  const auth = await requireClient();
  if (auth instanceof NextResponse) return auth;

  const profile = await db.clientProfile.findUnique({
    where: { userId: auth.userId },
    include: { snapshots: { orderBy: { period: 'desc' } } },
  });

  if (!profile) {
    return NextResponse.json({ error: 'Профиль не найден' }, { status: 404 });
  }

  return NextResponse.json({
    fullName: profile.fullName,
    snapshots: profile.snapshots,
  });
}