import { NextResponse } from 'next/server';
import { z } from 'zod';

import { db } from '@/lib/db';
import { setAuthCookie, signToken, verifyPassword } from '@/lib/auth';

const loginSchema = z.object({
  login: z.string().min(1),
  password: z.string().min(1),
  rememberDevice: z.boolean().optional(),
});

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = loginSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Неверные данные для входа' }, { status: 400 });
  }

  const user = await db.user.findUnique({ where: { login: parsed.data.login } });
  if (!user) {
    return NextResponse.json({ error: 'Неверный логин или пароль' }, { status: 401 });
  }

  const ok = await verifyPassword(parsed.data.password, user.passwordHash);
  if (!ok) {
    return NextResponse.json({ error: 'Неверный логин или пароль' }, { status: 401 });
  }

  const token = signToken({ userId: user.id, role: user.role });
  await setAuthCookie(token, parsed.data.rememberDevice ?? true);

  return NextResponse.json({ role: user.role });
}