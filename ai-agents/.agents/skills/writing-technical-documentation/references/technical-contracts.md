# Технические контракты и команды

## API reference

Для endpoint указывать в стабильном порядке:

1. назначение и применимость;
2. method и path;
3. authentication и permissions;
4. path, query и header parameters;
5. request body schema;
6. минимальный request;
7. responses и согласованный пример;
8. ошибки, условия возникновения и действие клиента;
9. ограничения, compatibility и deprecation.

Не выводить default из примера. Не считать поле optional только потому, что оно
отсутствует в одном response.

## CLI и команды

- Указать shell, рабочую директорию и пользователя, если они влияют на результат.
- Указать prerequisites, required environment variables и permissions.
- Не смешивать prompt shell с копируемой командой.
- Показать ожидаемый output отдельно.
- Не использовать `sudo`, destructive flags и широкие globs без необходимости и
  предупреждения.
- Дать idempotency, rollback или повторный запуск, если это важно.

## Конфигурация

Для каждого параметра указывать:

- точное имя;
- type и format;
- обязательность;
- default только из источника истины;
- allowed values и constraints;
- scope и precedence;
- secret handling;
- version compatibility;
- reload или restart requirement.

## Runbook и production

- Сначала подтвердить symptom и scope воздействия.
- Начать с read-only диагностики.
- Разделить diagnosis, mitigation и permanent fix.
- Поставить warning непосредственно перед опасным действием.
- Указать monitoring signal после изменения.
- Определить stop condition, rollback и escalation.

## Проверка примеров

Считать пример непроверенным, пока не подтверждены:

- синтаксис;
- доступность command или endpoint;
- согласованность входа и результата;
- применимость версии;
- отсутствие secrets;
- наблюдаемый критерий успеха.
