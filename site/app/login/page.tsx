'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);

    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login, password }),
    });

    const data = await res.json();
    setBusy(false);

    if (!res.ok) {
      setError(data.error ?? 'Ошибка входа');
      return;
    }

    router.push(data.role === 'ADMIN' ? '/admin' : '/client');
    router.refresh();
  }

  return (
    <main className="container">
      <h1>Вход</h1>
      <form className="card" onSubmit={onSubmit}>
        <div style={{ marginBottom: 10 }}>
          <label>Логин</label>
          <input value={login} onChange={(e) => setLogin(e.target.value)} required />
        </div>

        <div style={{ marginBottom: 10 }}>
          <label>Пароль</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>

        {error && <p style={{ color: '#ff9aa4' }}>{error}</p>}
        <button disabled={busy}>{busy ? 'Входим...' : 'Войти'}</button>
      </form>
    </main>
  );
}