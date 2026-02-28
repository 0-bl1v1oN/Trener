import { NextResponse } from 'next/server';

import { readAuthPayload } from './auth';

export async function requireAdmin() {
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