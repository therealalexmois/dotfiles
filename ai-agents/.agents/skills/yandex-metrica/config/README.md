# Получение токена Yandex Metrica API

## Шаг 1: Зарегистрируйте приложение

1. Перейдите на https://oauth.yandex.ru/client/new
2. Укажите название приложения
3. В разделе «Платформы» выберите «Веб-сервисы»
4. В «Права» добавьте: **Яндекс.Метрика** → все нужные разрешения:
   - `metrika:read` — чтение данных счётчиков
   - `metrika:write` — управление счётчиками и настройками
5. Сохраните `client_id`

## Шаг 2: Получите OAuth токен

Откройте в браузере:

```
https://oauth.yandex.ru/authorize?response_type=token&client_id=ВАШ_CLIENT_ID
```

После авторизации токен будет в URL:
```
https://oauth.yandex.ru/#access_token=ВАШТОКЕН&token_type=bearer&expires_in=31536000
```

Скопируйте значение `access_token`.

## Шаг 3: Настройте токен

```bash
cp config/.env.example config/.env
```

Вставьте токен:
```
YANDEX_METRICA_TOKEN=ваш_токен_здесь
```

## Проверка

```bash
bash scripts/check_connection.sh
```

## Частые проблемы

### "Unauthorized" (401)
- Токен устарел → получите новый
- Нет прав `metrika:read` → пересоздайте приложение с правами

### "Access denied" (403)
- Нет доступа к данному счётчику → проверьте права в Метрике

## Срок жизни токена

Токен действует **1 год**. После истечения получите новый.

## Документация

- Metrica API: https://yandex.ru/dev/metrika/
- Management API: https://yandex.ru/dev/metrika/doc/api2/management/management.html
- Reporting API: https://yandex.ru/dev/metrika/doc/api2/api_v1/intro.html
