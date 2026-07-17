# Профили RFC и ADR

## Оглавление

- [Модель выбора](#модель-выбора)
- [Problem RFC](#problem-rfc)
- [Product RFC](#product-rfc)
- [Technical RFC](#technical-rfc)
- [Combined RFC](#combined-rfc)
- [ADR](#adr)
- [Компактный и полный формат](#компактный-и-полный-формат)
- [Основание структуры](#основание-структуры)

## Модель выбора

Выбирай документ по трем независимым осям.

1. **Назначение**:
   - выровнять понимание проблемы;
   - запросить feedback или решение по proposal;
   - зафиксировать принятое решение.
2. **Покрытие**:
   - product;
   - technical;
   - combined.
3. **Глубина**:
   - compact;
   - full.

Не создавай отдельный тип только из-за длины. Короткий product RFC и полный
product RFC имеют одну логику, но разный набор применимых секций.

Если локальный процесс называет problem-only документ RFC, сохрани это название.
Не переименовывай его в PRD только из-за внешней терминологии.

## Problem RFC

Используй, когда предмет review — сама проблема, ее границы, последствия,
ограничения, гипотезы или следующий исследовательский шаг.

Обязательное ядро:

- Summary с вопросом или feedback request;
- контекст и problem statement;
- свидетельства и влияние либо явный пробел данных;
- цель обсуждения;
- in scope и out of scope;
- известные ограничения и предположения;
- открытые вопросы;
- следующий decision point.

Решение, подробные альтернативы и rollout не обязательны. Если гипотезы уже есть,
опиши их как гипотезы, не как зрелые варианты.

Problem RFC готов к review, когда ревьюеры могут подтвердить или оспорить проблему,
границы и план следующего шага. Он не обязан быть готов к implementation review.

## Product RFC

Используй, когда основное решение касается пользовательского поведения,
продуктового scope, сценариев, правил, ожидаемого эффекта или критериев успеха.

Обязательное ядро:

- Summary;
- контекст и проблема;
- цель и non-goals;
- in scope и out of scope;
- затронутые пользователи или системы;
- ключевые сценарии;
- предлагаемое поведение или decision question;
- проверяемые требования;
- критерии успеха либо `TBD`;
- альтернативы, риски и rollout пропорционально значимости.

Не требуй User Story, если обычный сценарий короче и точнее. Не превращай
техническое ограничение в искусственную пользовательскую потребность.

## Technical RFC

Используй, когда основное решение касается архитектуры или реализации.

Обязательное ядро:

- Summary;
- контекст, проблема, цели и non-goals;
- функциональные требования, NFR, ограничения и ASR;
- границы системы и затронутые компоненты;
- реальные варианты и одинаковые критерии сравнения;
- proposed design либо decision question;
- последствия и trade-offs.

Добавляй по применимости:

- interfaces и contracts;
- data model, ownership, consistency и migration;
- runtime flow и failure modes;
- security, privacy и trust boundaries;
- observability и operational ownership;
- compatibility, rollout и rollback;
- test plan, evals и acceptance criteria.

Не включай подробности кода, которые не влияют на решение или контракт.

## Combined RFC

Используй, если одни и те же ревьюеры должны согласовать продуктовую семантику и
техническую реализацию, а разделение создало бы два взаимозависимых документа.

Собирай структуру так:

1. Summary.
2. Контекст и проблема.
3. Цели, non-goals и scope.
4. Пользователи, сценарии и product behavior.
5. Требования и критерии успеха.
6. Technical design.
7. Альтернативы и сквозные trade-offs.
8. Риски, rollout, rollback и validation.
9. Открытые вопросы и decision request.

Не повторяй продуктовую проблему в техническом анализе. Покажи трассировку:

```text
проблема → цель → требование → design decision → проверка
```

Раздели combined RFC на два документа, если продуктовая и техническая части имеют
разных владельцев, разные сроки принятия или технический design может независимо
заменяться без изменения product contract.

## ADR

Используй ADR для сохранения одного архитектурно значимого решения после выбора.

Обязательное ядро:

- название решения;
- status;
- context и forces;
- decision;
- considered alternatives или причина их отсутствия;
- positive, negative и neutral consequences;
- supersession links, если решение заменяет другое.

ADR должен оставаться коротким и описывать одно решение. Если документ запрашивает
широкое согласование будущего design, это RFC, а не ADR.

## Компактный и полный формат

### Compact

Оставь только секции, необходимые для решения. Обычно достаточно Summary,
Problem/Context, Goals/Non-goals, Proposal или Decision, Alternatives/Consequences
и Open questions.

### Full

Добавь профильные секции, если изменение межкомандное, трудно обратимое, меняет
контракты или данные, имеет значимые quality-attribute trade-offs либо требует
миграции и управляемого rollout.

Ни число страниц, ни количество заголовков сами по себе не определяют глубину.

## Основание структуры

- Rust RFC ставит после Summary раздел Motivation, который должен подробно
  объяснять пользовательскую проблему, а затем отделяет proposal, drawbacks и
  alternatives: https://github.com/rust-lang/rfcs/blob/master/0000-template.md
- Kubernetes KEP использует порядок Summary, Motivation, Goals, Non-Goals,
  Proposal, Risks, Design Details, Test Plan и rollout/operations sections:
  https://github.com/kubernetes/enhancements/blob/master/keps/NNNN-kep-template/README.md
- HashiCorp сначала определяет проблему, затем использует RFC для proposal и
  feedback по решению: https://www.hashicorp.com/en/how-hashicorp-works/articles/writing-practices-and-culture
- Классический ADR фиксирует Context, Decision, Status и Consequences и остается
  небольшим документом: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions

Эти источники показывают устойчивые паттерны, но не задают универсальный стандарт.
Локальный RFC-процесс и обязательный шаблон имеют приоритет.
