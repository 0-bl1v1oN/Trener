import { NextResponse } from 'next/server';
import { z } from 'zod';

import { hashPassword, setAuthCookie, signToken } from '@/lib/auth';
import { db } from '@/lib/db';

const registerSchema = z.object({
  fullName: z.string().min(2, 'Введите имя'),
  login: z
    .string()
    .min(3, 'Логин слишком короткий')
    .regex(/^[a-zA-Z0-9._-]+$/, 'Логин: латиница, цифры, . _ -'),
  password: z.string().min(6, 'Минимум 6 символов'),
});

function generateClientKey(login: string) {
  const suffix = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `${login.toUpperCase()}-${suffix}`;
}

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = registerSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues[0]?.message ?? 'Проверьте поля формы' },
      { status: 400 },
    );
  }

  const { fullName, login, password } = parsed.data;

  const existing = await db.user.findUnique({ where: { login } });
  if (existing) {
    return NextResponse.json({ error: 'Логин уже занят' }, { status: 409 });
  }

  const passwordHash = await hashPassword(password);

  const user = await db.user.create({
    data: {
      login,
      passwordHash,
      role: 'CLIENT',
      clientProfile: {
        create: {
          fullName,
          clientKey: generateClientKey(login),
        },
      },
    },
  });

  const token = signToken({ userId: user.id, role: user.role });
  await setAuthCookie(token);

  return NextResponse.json({ role: user.role });
}