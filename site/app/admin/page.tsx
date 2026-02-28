'use client';

import { useState, type FormEvent } from 'react';

export default function AdminPage() {
  const [fullName, setFullName] = useState('');
  const [clientKey, setClientKey] = useState('');
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [jsonText, setJsonText] = useState('');
  const [msg, setMsg] = useState<string | null>(null);

  async function createClient(e: FormEvent) {
    e.preventDefault();
    setMsg(null);
    const res = await fetch('/api/admin/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fullName, clientKey, login, password }),
    });
    const data = await res.json();
    setMsg(res.ok ? 'Клиент создан' : data.error ?? 'Ошибка');
  }

  async function importProgress() {
    setMsg(null);
    let payload: unknown;
    try {
      payload = JSON.parse(jsonText);
    } catch {
      setMsg('Невалидный JSON');
      return;
    }

    const res = await fetch('/api/admin/import-progress', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    setMsg(res.ok ? `Импортировано: ${data.imported}` : data.error ?? 'Ошибка импорта');
  }

  return (
    <main className="container">
      <h1>Админ-панель</h1>

      <section className="card" style={{ marginBottom: 14 }}>
        <h2>Добавить клиента</h2>
        <form onSubmit={createClient}>
          <div className="row">
            <div style={{ flex: 1, minWidth: 220 }}>
              <label>Имя клиента</label>
              <input value={fullName} onChange={(e) => setFullName(e.target.value)} required />
            </div>
            <div style={{ flex: 1, minWidth: 220 }}>
              <label>Ключ клиента (из app clientId)</label>
              <input value={clientKey} onChange={(e) => setClientKey(e.target.value)} required />
            </div>
          </div>
          <div className="row" style={{ marginTop: 10 }}>
            <div style={{ flex: 1, minWidth: 220 }}>
              <label>Логин</label>
              <input value={login} onChange={(e) => setLogin(e.target.value)} required />
            </div>
            <div style={{ flex: 1, minWidth: 220 }}>
              <label>Пароль</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <button type="submit">Создать клиента</button>
          </div>
        </form>
      </section>

      <section className="card">
        <h2>Импорт прогресса</h2>
        <p>Вставьте JSON-файл из приложения (кнопка «Собрать данные»).</p>
        <textarea
          rows={12}
          value={jsonText}
          onChange={(e) => setJsonText(e.target.value)}
          placeholder="{ ... }"
        />
        <div style={{ marginTop: 10 }}>
          <button onClick={importProgress}>Импортировать</button>
        </div>
      </section>

      {msg && <p style={{ marginTop: 14 }}>{msg}</p>}
    </main>
  );
}