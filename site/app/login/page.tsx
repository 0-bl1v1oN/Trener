'use client';

import { useState, type FormEvent } from 'react';
import { useRouter } from 'next/navigation';

type AuthMode = 'login' | 'register';

export default function LoginPage() {
  const router = useRouter();
  const [mode, setMode] = useState<AuthMode>('login');
  const [fullName, setFullName] = useState('');
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);

    const endpoint = mode === 'login' ? '/api/auth/login' : '/api/auth/register';
    const payload = mode === 'login' ? { login, password } : { fullName, login, password };

    const res = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
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
      <h1>{mode === 'login' ? 'Вход' : 'Регистрация'}</h1>

      <div className="row" style={{ marginBottom: 12 }}>
        <button type="button" onClick={() => setMode('login')} disabled={busy || mode === 'login'}>
          Вход
        </button>
        <button
          type="button"
          onClick={() => setMode('register')}
          disabled={busy || mode === 'register'}
        >
          Регистрация
        </button>
      </div>
      <form className="card" onSubmit={onSubmit}>
      {mode === 'register' && (
          <div style={{ marginBottom: 10 }}>
            <label>Ваше имя</label>
            <input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Иван Иванов"
              required
            />
          </div>
        )}
        <div style={{ marginBottom: 10 }}>
          <label>Логин</label>
          <input
            value={login}
            onChange={(e) => setLogin(e.target.value)}
            placeholder="trainer_client_1"
            required
          />
        </div>

        <div style={{ marginBottom: 10 }}>
          <label>Пароль</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="минимум 6 символов"
            required
          />
        </div>

        {error && <p style={{ color: '#ff9aa4' }}>{error}</p>}
        <button disabled={busy}>
          {busy ? 'Подождите...' : mode === 'login' ? 'Войти' : 'Создать аккаунт'}
        </button>
      </form>
    </main>
  );
}