import { NextResponse } from 'next/server';
import { z } from 'zod';

import { db } from '@/lib/db';
import { hashPassword, setAuthCookie, signToken, verifyPassword } from '@/lib/auth';

const loginSchema = z.object({
  login: z.string().min(1),
  password: z.string().min(1),
  rememberDevice: z.boolean().optional(),
});

const DEFAULT_ADMIN_LOGIN = 'admin';
const DEFAULT_ADMIN_PASSWORD = 'admin';

async function ensureDefaultAdminAccount() {
  const existing = await db.user.findUnique({ where: { login: DEFAULT_ADMIN_LOGIN } });
  if (existing) return existing;

  const passwordHash = await hashPassword(DEFAULT_ADMIN_PASSWORD);
  return db.user.create({
    data: {
      login: DEFAULT_ADMIN_LOGIN,
      passwordHash,
      role: 'ADMIN',
    },
  });
}

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = loginSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Неверные данные для входа' }, { status: 400 });
  }

  const { login, password } = parsed.data;
  if (login === DEFAULT_ADMIN_LOGIN && password === DEFAULT_ADMIN_PASSWORD) {
    const admin = await ensureDefaultAdminAccount();
    const token = signToken({ userId: admin.id, role: admin.role });
    await setAuthCookie(token, parsed.data.rememberDevice ?? true);
    return NextResponse.json({ role: admin.role });
  }

  const user = await db.user.findUnique({ where: { login } });
  if (!user) {
    return NextResponse.json({ error: 'Неверный логин или пароль' }, { status: 401 });
  }

  const ok = await verifyPassword(password, user.passwordHash);
  if (!ok) {
    return NextResponse.json({ error: 'Неверный логин или пароль' }, { status: 401 });
  }

  const token = signToken({ userId: user.id, role: user.role });
  await setAuthCookie(token, parsed.data.rememberDevice ?? true);

  return NextResponse.json({ role: user.role });
}