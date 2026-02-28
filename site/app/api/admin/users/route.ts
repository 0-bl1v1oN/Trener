import { NextResponse } from 'next/server';
import { z } from 'zod';

import { hashPassword } from '@/lib/auth';
import { db } from '@/lib/db';
import { requireAdmin } from '@/lib/guards';

const schema = z.object({
  fullName: z.string().min(2),
  clientKey: z.string().min(2),
  login: z.string().min(2),
  password: z.string().min(4),
});

export async function POST(req: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await req.json();
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Проверьте поля формы' }, { status: 400 });
  }

  const exists = await db.user.findUnique({ where: { login: parsed.data.login } });
  if (exists) {
    return NextResponse.json({ error: 'Логин уже занят' }, { status: 409 });
  }

  const passHash = await hashPassword(parsed.data.password);

  const user = await db.user.create({
    data: {
      login: parsed.data.login,
      passwordHash: passHash,
      role: 'CLIENT',
      clientProfile: {
        create: {
          clientKey: parsed.data.clientKey,
          fullName: parsed.data.fullName,
        },
      },
    },
  });

  return NextResponse.json({ id: user.id });
}