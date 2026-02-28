import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="container">
      <h1>Сайт прогресса</h1>
      <p>Вход только по логину и паролю.</p>
      <div className="row">
        <Link href="/login" className="card">
          Перейти к входу
        </Link>
      </div>
    </main>
  );
}