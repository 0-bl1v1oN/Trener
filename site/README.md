# Trener Site (MVP)

Сайт для публикации прогресса клиентов с двумя ролями:

- **Админ**: создаёт аккаунты клиентов, загружает JSON из мобильного приложения.
- **Клиент**: входит по своему логину/паролю и видит только свои данные.

## Стек

- Next.js (App Router)
- Prisma + PostgreSQL
- JWT + cookie
- bcrypt для паролей

## Быстрый запуск

```bash
cd site
cp .env.example .env
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run dev
```

## Первая настройка админа

Создайте админа в БД вручную (одноразово), например через Prisma Studio/SQL:

- `role = ADMIN`
- `login = ваш_логин`
- `passwordHash = bcrypt hash`

> Для MVP это ручной шаг, позже можно добавить bootstrap-скрипт.

## Формат импорта

API `/api/admin/import-progress` принимает JSON из мобильного приложения:

- `period`: строка периода (например `01-2026`)
- `clients[]`: массив клиентов с `clientId`, `sessionsDone`, `days`

`clientId` из файла должен соответствовать `clientKey` в таблице `ClientProfile`.