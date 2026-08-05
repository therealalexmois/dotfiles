# Capability boundary review

Использовать этот reference для выбора и ревью target capability. Это дистилляция официальной документации OpenSpec и review-эвристик; эвристики не выдавать за требования CLI.

## Официальный контракт

Источники, проверенные 2026-08-05:

- [Concepts — Specs](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md#specs): specs организуются по domain; типовые срезы — feature area, component и bounded context.
- [Glossary](https://github.com/Fission-AI/OpenSpec/blob/main/docs/glossary.md): domain — выбранная проектом логическая группировка specs; permanent specs в целом являются текущим source of truth.
- [Using OpenSpec in an Existing Project](https://github.com/Fission-AI/OpenSpec/blob/main/docs/existing-projects.md): не документировать весь brownfield заранее; создавать domain при первом реальном change и позволять specs накапливаться постепенно.
- [Writing Good Specs](https://github.com/Fission-AI/OpenSpec/blob/main/docs/writing-specs.md): выбирать delta против существующего requirement; новая capability получает `Purpose`; один change сохраняет один intent.
- [OpenSpec changelog 1.0.2](https://github.com/Fission-AI/OpenSpec/blob/main/CHANGELOG.md): spec path именуется по capability, а не по change.
- [Reviewing a Change](https://github.com/Fission-AI/OpenSpec/blob/main/docs/reviewing-changes.md): сначала проверяется правильность intent и scope, затем то, корректно ли delta определяет done.

Из этого следует:

- capability — логическая область поведения и archive target, а не обязательное отображение одного endpoint, класса или user story;
- OpenSpec допускает разные стратегии domain slicing и не устанавливает универсальную единственно верную гранулярность;
- endpoint-level или field-level capability не запрещена, но требует смыслового основания;
- отсутствие полного baseline в brownfield не является blocker для нового change;
- новая capability может начаться с `Purpose` и одного `ADDED` requirement, описывающего только текущий срез.

### Domain и capability

- **Domain** — логическая группировка и namespace для specs, выбранные проектом.
- **Capability** — устойчивая область поведения, permanent spec и target для применения delta при archive.
- **Capability path** — полный путь к capability относительно `openspec/specs/`. В плоской структуре он может состоять из одного сегмента, который одновременно играет роль domain. В иерархической структуре domain служит namespace, например `identity/user-auth` в `openspec/specs/identity/user-auth/spec.md`.

Не использовать это различие как новый gate. Оно нужно только для точного определения полного target path и archive semantics.

## Процедура выбора

### 1. Инвентаризировать source of truth

Проверить:

- `openspec/specs/**/spec.md`: пути, `Purpose`, названия и смысл requirements;
- active changes: соседние или конкурирующие delta paths;
- archive только как историческое evidence, а не как текущий source of truth;
- project rules, если они задают собственную taxonomy.

Искать не только точное имя. Сопоставлять акторов, observable behavior, потребителей, ownership, trust boundary и жизненный цикл.

### 2. Разделить change и capability

- **Change** отвечает: какое bounded изменение делается сейчас?
- **Capability** отвечает: в какой устойчивой области живет это и будущие связные поведения после archive?
- **Requirement** отвечает: какое одно наблюдаемое поведение должно быть истинно?

Change может называться `add-tool-description-field`, а capability — `agent-tool-catalog`. Совпадение имен не требуется.

### 3. Оценить кандидатов

Для каждого разумного target path проверить:

1. **Cohesion:** requirements используют близких акторов, потребителей и инварианты.
2. **Stability:** технический rename URL, DTO или поля не заставляет переименовать capability, если смысл не изменился.
3. **Discoverability:** newcomer ожидаемо найдет поведение в этом месте.
4. **Growth:** 2–3 вероятных соседних requirements поместятся естественно, не превращая spec в свалку.
5. **Ownership/lifecycle:** поведение меняется и утверждается примерно одними владельцами и на одном жизненном цикле.
6. **Archive semantics:** после archive не появятся конкурирующие или дублирующие sources of truth.

Это эвристики. Не требовать прохождения каждого пункта как формального OpenSpec gate.

### 4. Проверить крайние гранулярности

Слишком узкая граница вероятна, если capability:

- повторяет change slug;
- названа по одному JSON-полю, флагу или версии endpoint;
- не имеет Purpose шире текущей строки schema;
- провоцирует отдельную spec для каждого соседнего поля;
- потребует rename при внутреннем рефакторинге без изменения поведения.

Слишком широкая граница вероятна, если capability:

- называется `api`, `backend`, `system` без конкретной ответственности;
- объединяет разных акторов, владельцев или trust boundaries;
- допускает почти любое будущее requirement;
- скрывает несколько независимо поставляемых capabilities.

Field-level capability может быть обоснована, если поле выражает самостоятельную политику или контракт: имеет отдельные инварианты, совместимость, владельца, потребителей или lifecycle. Сам факт наличия одного поля недостаточен.

Endpoint-level capability может быть обоснована, если endpoint сам является устойчивым публичным продуктовым контрактом. Если URL — только transport для более долгоживущей функции, предпочитать имя функции или компонента.

### 5. Выбрать brownfield-стратегию

Если подходящая capability существует:

- направить delta в нее;
- использовать `MODIFIED` только при изменении существующего requirement целиком;
- использовать `ADDED` для нового поведения даже внутри давно существующего endpoint.

Если capability не существует:

- создать ее текущим change через `Purpose` + `ADDED Requirements`;
- описать только затрагиваемое поведение;
- не требовать отдельный MR с полным reverse-engineered baseline.

Если существует узкая соседняя capability:

- не повторять слабую taxonomy автоматически;
- не переносить ее автоматически в текущий change;
- выбрать один из вариантов и назвать trade-off:
  1. сохранить текущую taxonomy ради минимального scope;
  2. создать более устойчивую capability текущим change, оставив временную фрагментацию;
  3. выполнить отдельный spec-maintenance change для миграции уже описанных requirements;
  4. объединить migration с feature-change только если без нее невозможно получить однозначный source of truth и это явно входит в intent.

Полный baseline отдельным MR оправдан только при самостоятельной ценности: cross-team contract audit, compliance, migration, ownership transfer или устранение уже опасного расхождения. Желание «сначала описать все правильно» само по себе недостаточно.

## Severity и verdict

Использовать `MAJOR`, если boundary defect приводит к одному из последствий:

- `MODIFIED` не имеет target requirement или `ADDED` создает конкурирующий контракт;
- archive положит требования не в ту capability;
- одна и та же семантика будет нормативно описана в нескольких местах;
- scope объединяет независимо поставляемые изменения;
- implementer не может однозначно определить владельца или контракт.

Использовать `MINOR` или `SUGGESTION`, если текущая реализация и archive однозначны, а проблема касается будущей discoverability или taxonomy cleanliness. Не блокировать change только ради красивой иерархии.

При спорном выборе вернуть 2–4 варианта с рисками и рекомендовать один. Запрашивать human decision только если варианты материально меняют scope, migration или ownership; иначе применить KISS и объяснить вывод.
