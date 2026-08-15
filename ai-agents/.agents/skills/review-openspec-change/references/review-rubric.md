# OpenSpec review rubric

Использовать эту рубрику только внутри scope, который пользователь задал для текущего review. Не превращать ее в обязательный checklist всего change. Сначала применять относящийся к scope официальный baseline, затем project-specific contract и только потом усиленные эвристики по риску.

## Официальный baseline OpenSpec

Источники:

- [Reviewing a Change](https://github.com/Fission-AI/OpenSpec/blob/main/docs/reviewing-changes.md)
- [OpenSpec on a Team](https://github.com/Fission-AI/OpenSpec/blob/main/docs/team-workflow.md#reviewing-specs-in-a-pull-request)
- [Writing Good Specs](https://github.com/Fission-AI/OpenSpec/blob/main/docs/writing-specs.md)
- [Core Concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md)
- [Using OpenSpec in an Existing Project](https://github.com/Fission-AI/OpenSpec/blob/main/docs/existing-projects.md)
- [Customization](https://github.com/Fission-AI/OpenSpec/blob/main/docs/customization.md)
- [Explore First](https://github.com/Fission-AI/OpenSpec/blob/main/docs/explore.md)
- [Editing & Iterating on a Change](https://github.com/Fission-AI/OpenSpec/blob/main/docs/editing-changes.md)

Основные правила:

- Ревьюировать план после propose/ff до apply; после реализации проверять код через verify или эквивалентное сопоставление.
- Читать proposal → delta specs → design при необходимости → tasks. Если intent неверен, сначала исправить proposal.
- При review реализации читать proposal → delta specs → code diff и проверять, что код доставляет ровно согласованные requirements.
- Считать PR или MR контейнером для change и кода, а не условием запуска review.
- Держать в change один intent и подбирать глубину review по риску.
- Описывать в spec наблюдаемое поведение, а не код.
- Формулировать один requirement как одно поведение с одним `SHALL`/`MUST`.
- Давать каждому requirement хотя бы один scenario, который действительно его проверяет.
- Покрывать наиболее важные edge/error cases.
- Выбирать `ADDED`, `MODIFIED`, `REMOVED` сравнением с base spec; для `MODIFIED` приводить полную новую версию requirement.
- Добавлять `Purpose` для новой capability; не использовать delta Purpose для изменения Purpose существующей capability.
- Именовать spec path по долгоживущей capability, а не по change; группировать capabilities по понятной команде domain-области.
- В brownfield описывать только затрагиваемый срез и не требовать полного baseline до первого реального change.
- Делать tasks упорядоченными и трассируемыми к requirements; не создавать один гигантский task и не выходить за scope.
- Помнить, что project context, per-artifact rules и custom schema являются частью фактического контракта генерации. Operation guidance остается advisory и не должно автоматически копироваться в артефакты.
- Использовать Explore для исследования и выбора пути, не для создания артефактов или изменения кода.

## Scope filter

- Один файл или diff не равен полному review change.
- Набор артефактов не разрешает автоматически проверять остальные артефакты.
- Дополнительный файл можно читать как evidence, не включая его в verdict.
- Отсутствие out-of-scope файла не блокирует scoped verdict.
- Полный gate, capability inventory, strict validation и delivery statuses применять только когда они входят в scope или необходимы для конкретного finding.

## Project-aware проверка

Если verdict зависит от project contract, проверить относящиеся к нему вопросы:

- Какая schema реально разрешена для change: CLI override, `.openspec.yaml`, project config или default?
- Какие artifacts, templates, `requires` и rules фактически действуют?
- Не оценивается ли custom artifact по шаблону default `spec-driven`?
- Соответствуют ли sections шаблону и artifact instructions?
- Не попали ли process rules в `spec.md`, хотя должны быть per-artifact rules или operation guidance?
- Не используется ли устаревший audit/source как текущий contract?
- Проверены ли соседние capabilities по `Purpose` и смыслу, а не только точному имени?
- Не спутано ли имя change с target capability и archive path?

Custom schema может добавлять артефакты и gates, но их наличие не является универсальной best practice. Требовать дополнительный `review.md`, Jira section или статусный блок только когда это зафиксировано действующей schema/rules либо явно нужно пользователю.

## Усиленный gate по риску

Применять для security, data loss, cross-repo contracts, migrations, production enablement, agent tool permissions, irreversible actions и дорогой неоднозначности.

Проверять:

- Trust boundary: кому и каким данным доверяет решение?
- Evidence: что именно доказано кодом, тестом, protocol output или контрактом?
- Enforcement: какой механизм реально блокирует нарушение?
- Classification: не выдается ли metadata/annotation за enforcement?
- Residual risk: что остается возможным после всех проверок?
- Delivery boundary: что отдельно разрешено или заблокировано для разработки, live test, merge, enablement/deploy и archive?
- Exit condition: какое наблюдаемое evidence снимает каждый blocker и кто его поставляет?

Пример корректного разделения: source review может подтвердить текущее отсутствие явных мутаций; `tools/list` подтверждает публикацию metadata; runtime gate подтверждает enforcement. Ни одно из этих доказательств не заменяет остальные автоматически.

## Severity

### BLOCKER

Использовать, когда defect делает план небезопасным или не позволяет однозначно определить, что строить:

- неверный intent или scope;
- противоречивые обязательные требования;
- ложная гарантия безопасности/контракта;
- критический human decision с несколькими существенно разными реализациями;
- разрешение необратимого или live-действия без необходимой границы;
- отсутствующий факт, без которого нельзя безопасно утвердить сам план.

### MAJOR

Использовать, когда высок риск неправильной реализации или непроверяемого результата:

- составной, расплывчатый или ненаблюдаемый requirement;
- requirement без проверяющего scenario;
- неправильный delta type;
- capability boundary, создающая конкурирующий source of truth или неверный archive target;
- важный missing edge/error case;
- смысловое противоречие между artifacts;
- task без requirement или requirement без исполнимого покрытия;
- unsupported factual claim, влияющий на design или delivery;
- prerequisite без проверяемого exit condition.

### MINOR

Использовать для локальной ясности или maintainability, когда реализация останется однозначной и безопасной. MINOR не блокирует PASS, если пользователь не установил более строгий gate.

### SUGGESTION

Использовать только для необязательного улучшения. Не превращать preference в defect и не открывать новый review round ради suggestion.

## Coverage matrix

Построить мысленно или явно для полного или сложного change, выбранного набора артефактов либо проверки реализации:

| Intent/constraint | Requirement + scenario | Design decision | Task/test | Evidence |
|---|---|---|---|---|
| Что и зачем | Какое observable behavior считается done | Как это будет достигнуто | Что конкретно выполнить и проверить | Чем подтверждено |

Флагать пустые обязательные ячейки. Не требовать design decision, если реализация очевидна и schema допускает lightweight change.

## Типовые анти-паттерны

- `spec.md` содержит Jira key, follow-up статус, имя класса, путь файла или пошаговую реализацию.
- Один requirement содержит несколько `SHALL`, перечисление через «и также» или разные failure modes.
- Scenario просто перефразирует requirement и не задает конкретную ситуацию.
- `ADDED` дублирует уже существующий requirement вместо `MODIFIED`.
- Capability механически названа по change, версии endpoint или полю без проверки более устойчивой domain-области.
- Отдельный полный baseline объявлен prerequisite для brownfield-change без самостоятельной ценности.
- Proposal превращается в mini-design или хранит быстро устаревающий Jira status.
- Design называет metadata «policy» или «guarantee», хотя runtime ее не проверяет.
- Feature flag объявлен safety boundary без доказанного enforcement.
- Audit-note, комментарий или имя функции используется как authoritative contract.
- Tasks с placeholders выглядят конкретными, но не исполнимы.
- Strict validation называется доказательством semantic correctness.
- Внешний blocker ошибочно превращает качественный OpenSpec в FAIL либо, наоборот, скрывается за общим PASS.
- Каждый повторный review добавляет новые вкусовые критерии и двигает completion gate.

## Verdict semantics

| Verdict | Значение |
|---|---|
| `PASS` | В проверенном scope нет внутренних BLOCKER/MAJOR. Для ограниченного review назвать scope. |
| `PASS с внешним delivery-blocker` | Полный OpenSpec готов, но конкретная внешняя зависимость блокирует названные delivery stages. |
| `CHANGES REQUIRED` | В проверенном scope есть исправимые внутренние BLOCKER/MAJOR. |
| `BLOCKED` | Для запрошенного verdict нужен недоступный факт или human decision; задать один точный вопрос. |

При PASS завершить цикл. Не требовать новый round из-за MINOR/SUGGESTION, если они не нарушают явный acceptance gate.

## Формат finding

```text
[M2] tasks.md — prerequisite не имеет exit condition
Evidence: точная цитата или ссылка на участок.
Impact: невозможно объективно определить готовность merge.
Required fix: разделить upstream contract, local normalization и reviewer evidence.
Closed when: для каждого владельца указан наблюдаемый результат.
```

Формулировать required fix на уровне результата. Не навязывать конкретную реализацию, если несколько вариантов одинаково корректны и решение не принято.

## Bounded self-review success gate

Включать только критерии, относящиеся к исходному scope:

- все открытые BLOCKER/MAJOR закрыты по их success conditions;
- новых регрессий и cross-artifact contradictions нет;
- все файлы и diff внутри scope проверены полностью;
- strict OpenSpec validation и `git diff --check` успешны, если scope требовал эти проверки, либо честно указан environment blocker;
- evidence приведено прямо в transcript, а не скрыто во временном файле;
- semantic review и delivery statuses указаны раздельно;
- loop ограничен по turns и останавливается на новом human decision.
