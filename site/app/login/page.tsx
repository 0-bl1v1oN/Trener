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
      <h1 className="hero-title">
        Начни <span>свой путь к форме!</span>
      </h1>

      <form className="card auth-card auth-card-strong" onSubmit={onSubmit}>
        <h2>Вход</h2>
        <div className="field-block">
          <label>Логин</label>
          <input
            value={login}
            onChange={(e) => setLogin(e.target.value)}
            placeholder="client_login"
            required
          />
        </div>

        <div className="field-block">
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

        {error && <p className="auth-error">{error}</p>}
        <button className="auth-submit" disabled={busy}>
          {busy ? 'Входим...' : 'Войти в аккаунт'}
        </button>
      </form>
      <p className="auth-note">
        Используйте логин и пароль, который выдал вам ваш любимый тренер ❤️
      </p>
    </main>
  );
}