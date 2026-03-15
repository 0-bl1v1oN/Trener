'use client';

import { useEffect, useMemo, useState, type FormEvent } from 'react';

type ClientOption = { id: string; fullName: string; clientKey: string };
type CreatedClientCred = { clientKey: string; fullName: string; login: string; password: string };
type ExerciseAnalytics = {
  exercise: string;
  latest: number;
  previous: number;
  delta: number;
  trend: 'progression' | 'regression' | 'stagnation';
};

type ReportResponse = {
  client: { clientKey: string; fullName: string };
  snapshots: Array<{ period: string; sessionsDone: number }>;
  analytics: {
    hasComparison: boolean;
    latestPeriod: string | null;
    previousPeriod: string | null;
    sessionsDelta: number | null;
    trendSummary: { progression: number; regression: number; stagnation: number };
    exerciseAnalytics: ExerciseAnalytics[];
  };
};

export default function AdminPage() {
  const [fullName, setFullName] = useState('');
  const [clientKey, setClientKey] = useState('');
  const [login, setLogin] = useState('');
  const [password, setPassword] = useState('');
  const [jsonText, setJsonText] = useState('');
  const [msg, setMsg] = useState<string | null>(null);

  const [clients, setClients] = useState<ClientOption[]>([]);
  const [selectedClientKey, setSelectedClientKey] = useState('');
  const [report, setReport] = useState<ReportResponse | null>(null);
  const [createdCreds, setCreatedCreds] = useState<CreatedClientCred[]>([]);

  async function loadClients() {
    const res = await fetch('/api/admin/users');
    const data = await res.json();
    if (!res.ok) return;
    setClients(data.clients ?? []);
  }

  useEffect(() => {
    void loadClients();
  }, []);

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
    if (res.ok) {
      await loadClients();
      setFullName('');
      setClientKey('');
      setLogin('');
      setPassword('');
    }
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
    if (!res.ok) {
      setMsg(data.error ?? 'Ошибка импорта');
      return;
    }

    setCreatedCreds(data.createdClients ?? []);
    setMsg(`Импортировано: ${data.imported}`);
    await loadClients();
  }

  async function buildReport() {
    if (!selectedClientKey) {
      setMsg('Выберите клиента для отчёта');
      return;
    }
    setMsg(null);
    const res = await fetch('/api/admin/report', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ clientKey: selectedClientKey }),
    });
    const data = await res.json();
    if (!res.ok) {
      setMsg(data.error ?? 'Не удалось построить отчёт');
      return;
    }
    setReport(data as ReportResponse);
  }

  const reportText = useMemo(() => {
    if (!report) return '';
    return JSON.stringify(report, null, 2);
  }, [report]);

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

      <section className="card" style={{ marginBottom: 14 }}>
        <h2>Импорт отчёта</h2>
        <p>Вставьте JSON из кнопки «Собрать данные». Клиенты создадутся автоматически, если их не было.</p>
        <textarea
          rows={12}
          value={jsonText}
          onChange={(e) => setJsonText(e.target.value)}
          placeholder="{ ... }"
        />
        <div style={{ marginTop: 10 }}>
          <button onClick={importProgress}>Импортировать отчёт</button>
        </div>

        {createdCreds.length > 0 && (
          <div style={{ marginTop: 12 }}>
            <h3>Новые клиенты (логины/пароли)</h3>
            {createdCreds.map((c) => (
              <div key={c.clientKey}>
                • {c.fullName} ({c.clientKey}) — <b>{c.login}</b> / <b>{c.password}</b>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="card" style={{ marginBottom: 14 }}>
        <h2>Аналитика и отчёт на сайте</h2>
        <div className="row" style={{ alignItems: 'flex-end' }}>
          <div style={{ flex: 1, minWidth: 260 }}>
            <label>Клиент</label>
            <select value={selectedClientKey} onChange={(e) => setSelectedClientKey(e.target.value)}>
              <option value="">Выберите клиента</option>
              {clients.map((c) => (
                <option key={c.id} value={c.clientKey}>
                  {c.fullName} ({c.clientKey})
                </option>
              ))}
            </select>
          </div>
          <div>
            <button onClick={buildReport}>Собрать отчёт</button>
          </div>
        </div>

        {report && (
          <div style={{ marginTop: 14 }}>
            <h3>{report.client.fullName}</h3>
            <p>
              Периоды: {report.snapshots.length}. Сравнение: {report.analytics.latestPeriod ?? '—'} ↔{' '}
              {report.analytics.previousPeriod ?? '—'}.
            </p>

            <div className="row" style={{ gap: 8 }}>
              <div className="card" style={{ flex: 1 }}>
                <strong>Прогрессия</strong>
                <div>{report.analytics.trendSummary.progression}</div>
              </div>
              <div className="card" style={{ flex: 1 }}>
                <strong>Стагнация</strong>
                <div>{report.analytics.trendSummary.stagnation}</div>
              </div>
              <div className="card" style={{ flex: 1 }}>
                <strong>Регрессия</strong>
                <div>{report.analytics.trendSummary.regression}</div>
              </div>
            </div>

            <div style={{ marginTop: 10 }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr>
                    <th style={{ textAlign: 'left' }}>Упражнение</th>
                    <th>Было (кг)</th>
                    <th>Стало (кг)</th>
                    <th>Δ</th>
                    <th>Статус</th>
                  </tr>
                </thead>
                <tbody>
                  {report.analytics.exerciseAnalytics.slice(0, 20).map((it) => (
                    <tr key={it.exercise}>
                      <td>{it.exercise}</td>
                      <td style={{ textAlign: 'center' }}>{it.previous.toFixed(1)}</td>
                      <td style={{ textAlign: 'center' }}>{it.latest.toFixed(1)}</td>
                      <td style={{ textAlign: 'center' }}>{it.delta > 0 ? '+' : ''}{it.delta.toFixed(1)}</td>
                      <td style={{ textAlign: 'center' }}>
                        {it.trend === 'progression' ? 'Прогрессия' : it.trend === 'regression' ? 'Регрессия' : 'Стагнация'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <label style={{ marginTop: 12, display: 'block' }}>JSON отчёта для отправки</label>
            <textarea rows={10} value={reportText} readOnly />
          </div>
        )}
      </section>

      {msg && <p style={{ marginTop: 14 }}>{msg}</p>}
    </main>
  );
}