# Выбор паттерна обработки отказа

Использовать этот reference для выбора и проверки preconditions и trade-offs. Не считать перечисление паттернов требованием применить каждый из них.

## Базовая модель

`Fail-fast`, `fail-open` и `fail-closed` отвечают на разные вопросы:

- `fail-fast` - когда обнаружить и остановить некорректную операцию;
- `fail-open` и `fail-closed` - какое решение принять, если контроль или проверка недоступны;
- `fail-safe` - какое конечное состояние безопасно для конкретного domain.

Обычно решение сочетает несколько уровней: раннее обнаружение, безопасную политику, ограничение времени, изоляцию отказа, запасной режим и recovery.

## Decision sequence

1. Если нарушен обязательный invariant, input contract или configuration, использовать `fail-fast` на ближайшей границе владения.
2. Если отказал security, policy или release gate, сравнить false allow и false deny. При неприемлемом false allow использовать `fail-closed`.
3. Если можно вернуть корректный ограниченный результат, выбрать fallback, failover или graceful degradation.
4. Если зависимость может зависнуть, установить timeout или общий deadline.
5. Если ошибка transient и повтор безопасен, добавить bounded retry с backoff и jitter.
6. Если повторяющийся отказ может занимать ресурсы, рассмотреть circuit breaker.
7. Если общий ресурс создает blast radius, использовать bulkhead.
8. При контролируемом producer использовать backpressure; при неконтролируемой перегрузке - load shedding.
9. После частичных side effects использовать compensation или Saga, если atomic transaction невозможна.
10. Для stateless-компонента допускать restart или self-healing, не скрывая постоянную причину.

Если ни один resilience pattern не улучшает корректность или recovery, вернуть явную ошибку.

## Каталог паттернов

| Паттерн | Когда применять | Обязательные условия | Типичная ошибка |
| --- | --- | --- | --- |
| `fail-fast` | Невалидные input, invariant или обязательная configuration | Проверять на ближайшей границе владения | Завершать весь сервис из-за одной невалидной пользовательской сущности |
| `fail-closed` | Невозможно выполнить gate, а false allow опасен | Явный отказ или отключение capability | Считать недоступность проверки успешным результатом |
| `fail-open` | False deny опаснее, а разрешение ограничено и обратимо | Bounded scope, observability, явное risk acceptance | Использовать для authorization, destructive actions или integrity-critical flows |
| `fail-safe` | Нужно определить безопасное domain-состояние | Анализ safety, security, integrity и availability | Автоматически приравнивать safe state к closed state во всех domains |
| fallback | Есть семантически допустимый запасной результат | Ограничения freshness и correctness известны caller | Использовать stale cache или default, скрывая обязательную ошибку |
| failover | Есть здоровый резерв | Проверены readiness, consistency и routing | Переключаться на отстающую или непригодную replica |
| graceful degradation | Необязательную функцию можно отключить | Основной результат остается корректным; degraded path тестируется | Возвращать неполный результат как полный |
| timeout | Remote call или операция может зависнуть | Timeout согласован с latency budget | Ставить произвольное значение без учета общего deadline |
| deadline | Несколько вызовов делят общий временной бюджет | Передавать оставшийся budget вниз по call chain | Давать каждой зависимости полный timeout независимо |
| retry | Ошибка transient | Bounded attempts, deadline, idempotency, backoff и jitter | Повторять validation error, permanent failure или non-idempotent side effect |
| circuit breaker | Повторные вызовы к падающей зависимости расходуют ресурсы | Определены failure threshold, open period, probe и fallback или fast failure | Добавлять breaker без timeout, metrics и recovery contract |
| bulkhead | Компоненты конкурируют за thread, connection, queue или quota | Раздельные лимиты и наблюдаемость saturation | Оставлять общий pool, через который один tenant блокирует остальных |
| backpressure | Consumer может сообщить producer о снижении скорости | Протокол поддерживает flow control | Бесконечно накапливать очередь |
| load shedding | Нагрузка превышает capacity и producer нельзя замедлить | Приоритеты, admission control и metrics отказов | Отбрасывать критичные и фоновые запросы одинаково |
| compensation | Операция частично изменила внешнее состояние | Domain-specific undo, durable progress, idempotent steps | Считать компенсацию обычным rollback или предполагать, что она не падает |
| Saga | Business transaction охватывает несколько services или stores | Явные steps, state, compensation и recovery | Использовать для операции, которую закрывает одна atomic transaction |
| restart / self-healing | Упал stateless или восстанавливаемый компонент | State вынесен или восстанавливается; есть crash-loop detection | Перезапускать permanent configuration failure без ограничения |

## Граница fail-fast

Останавливать минимальную единицу работы, которая владеет ошибкой:

- встроенную configuration, известную до deploy, проверять lint или test в CI и повторно при startup;
- пользовательскую configuration проверять при create или update и отклонять эту сущность;
- request validation выполнять до business logic;
- внутренний invariant делать видимым рядом с источником, не подменяя случайным default.

`Fail-fast` не требует завершать весь процесс при любой ошибке.

## Retry checklist

Рекомендовать retry только при положительных ответах:

- Ошибка действительно transient?
- Caller может отличить ее от permanent и business errors?
- Операция идемпотентна или защищена idempotency key?
- Частично выполненный предыдущий вызов не создаст duplicate side effect?
- Есть общий deadline и ограничение attempts?
- Используются backoff и jitter?
- Retry не дублируется на нескольких уровнях call chain?
- Dependency получает возможность восстановиться?

## Fail-open checklist

Рекомендовать `fail-open` только при положительных ответах:

- Отказал именно контроль или gate, а не основная business operation?
- False deny опаснее false allow в этом domain?
- Продолжение не нарушает authorization, integrity или irreversible constraints?
- Разрешенная операция ограничена по времени, scope или quota?
- Решение наблюдаемо и может быть быстро отменено?
- Risk acceptance принадлежит уполномоченному владельцу?

При неизвестном ответе не рекомендовать `fail-open`.

## Anti-patterns

- Возвращать default при отсутствии обязательной configuration.
- Перехватывать широкое исключение, логировать и продолжать с неизвестным state.
- Считать недоступность authorization или policy check успешной проверкой.
- Выполнять unbounded retry или retry без timeout.
- Повторять non-idempotent operation без защиты от duplicate side effects.
- Независимо повторять один вызов на каждом уровне call chain.
- Использовать fallback без явного контракта freshness и correctness.
- Добавлять circuit breaker без failure classification, metrics и recovery behavior.
- Проектировать сложный degraded mode, который не тестируется.
- Перезапускать весь runtime из-за невалидной пользовательской configuration.
- Предлагать несколько resilience layers без конкретного failure scenario.

## Типовые сочетания

| Сценарий | Минимальное сочетание |
| --- | --- |
| Нет обязательной встроенной configuration | CI validation + startup `fail-fast` |
| Невалидное объявление пользовательского subagent | Validation на registration boundary; отклонить только объявление |
| Недоступен authorization service | `timeout` + `fail-closed`; при повторяющемся отказе рассмотреть circuit breaker |
| Недоступен optional recommendation service | `timeout` + graceful degradation |
| Внешний API отвечает `429` или `503` | Deadline + bounded retry с backoff и jitter; учитывать idempotency |
| Primary storage недоступен | Failover только на готовую и согласованную replica; иначе явная ошибка |
| Distributed workflow выполнен частично | Durable state + compensation или Saga + observability |
