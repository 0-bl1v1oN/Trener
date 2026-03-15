import { NextResponse } from 'next/server';
import { z } from 'zod';

import { hashPassword } from '@/lib/auth';
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

function sanitizeLoginBase(clientId: string) {
  const clean = clientId.toLowerCase().replace(/[^a-z0-9]/g, '');
  return clean.length > 0 ? clean.slice(0, 18) : 'client';
}

function randomPassword(length = 10) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  let out = '';
  for (let i = 0; i < length; i += 1) {
    out += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return out;
}

async function nextAvailableLogin(base: string) {
  let idx = 0;
  while (true) {
    const login = idx === 0 ? `client_${base}` : `client_${base}_${idx}`;
    const exists = await db.user.findUnique({ where: { login } });
    if (!exists) return login;
    idx += 1;
  }
}

export async function POST(req: Request) {
  const auth = await requireAdmin();
  if (auth instanceof NextResponse) return auth;

  const body = await req.json();
  const parsed = importSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Неверный формат JSON' }, { status: 400 });
  }

  let imported = 0;
  const createdClients: Array<{ clientKey: string; fullName: string; login: string; password: string }> = [];

  for (const c of parsed.data.clients) {
    let profile = await db.clientProfile.findUnique({ where: { clientKey: c.clientId } });

    if (!profile) {
      const base = sanitizeLoginBase(c.clientId);
      const login = await nextAvailableLogin(base);
      const password = randomPassword();
      const passHash = await hashPassword(password);

      const created = await db.user.create({
        data: {
          login,
          passwordHash: passHash,
          role: 'CLIENT',
          clientProfile: {
            create: {
              clientKey: c.clientId,
              fullName: c.clientName,
            },
          },
        },
        include: { clientProfile: true },
      });

      profile = created.clientProfile!;
      createdClients.push({
        clientKey: c.clientId,
        fullName: c.clientName,
        login,
        password,
      });
    } else if (profile.fullName !== c.clientName) {
      profile = await db.clientProfile.update({
        where: { id: profile.id },
        data: { fullName: c.clientName },
      });
    }

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

  return NextResponse.json({ imported, createdClients });
}