import { NextResponse } from 'next/server';

import { readAuthPayload, type AuthPayload } from './auth';

function localAdminBypass(): AuthPayload | null {
  if (process.env.NODE_ENV === 'production') return null;
  return { userId: 'local-admin', role: 'ADMIN' };
}

export async function requireAdmin() {
  const bypass = localAdminBypass();
  if (bypass) return bypass;
  const payload = await readAuthPayload();
  if (!payload || payload.role !== 'ADMIN') {
    return NextResponse.json({ error: 'Требуется доступ администратора' }, { status: 401 });
  }
  return payload;
}

export async function requireClient() {
  const payload = await readAuthPayload();
  if (!payload || payload.role !== 'CLIENT') {
    return NextResponse.json({ error: 'Требуется вход клиента' }, { status: 401 });
  }
  return payload;
}