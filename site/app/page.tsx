import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="container">
      <h1>Сайт прогресса</h1>
      <p>Войдите в существующий аккаунт или создайте новый клиентский профиль.</p>
      <div className="row">
        <Link href="/login" className="card">
          Вход / Регистрация
        </Link>
      </div>
    </main>
  );
}