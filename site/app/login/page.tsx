'use client';

import { useState, type FormEvent } from 'react';
import { useRouter } from 'next/navigation';


export default function LoginPage() {
  const router = useRouter();
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberDevice, setRememberDevice] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);

    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login, password, rememberDevice }),
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
    <main className="container auth-page">
      <h1 className="auth-title">Ваш прогресс</h1>

      <form className="card auth-card" onSubmit={onSubmit}>
        <h2>Вход</h2>
        <div style={{ marginBottom: 10 }}>
          <label>Логин</label>
          <input
            value={login}
            onChange={(e) => setLogin(e.target.value)}
            placeholder="client_login"
            required
          />
        </div>

        <div style={{ marginBottom: 10 }}>
          <label>Пароль</label>
          <div className="password-field">
            <input
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Введите пароль"
              required
            />
            <button
              type="button"
              className="icon-button"
              onClick={() => setShowPassword((prev) => !prev)}
              aria-label={showPassword ? 'Скрыть пароль' : 'Показать пароль'}
              title={showPassword ? 'Скрыть пароль' : 'Показать пароль'}
            >
              👁
            </button>
          </div>
        </div>

        <label className="remember-check">
          <input
            type="checkbox"
            checked={rememberDevice}
            onChange={(e) => setRememberDevice(e.target.checked)}
          />
          Запомнить на этом устройстве
        </label>

        {error && <p style={{ color: '#ff9aa4' }}>{error}</p>}
        <button disabled={busy}>{busy ? 'Входим...' : 'Войти'}</button>
      </form>
      <p className="auth-note">
        Используйте логин и пароль, который выдал вам ваш любимый тренер ❤️
      </p>
    </main>
  );
}