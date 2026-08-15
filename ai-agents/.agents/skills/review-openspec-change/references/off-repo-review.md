# Review вне репозитория

Использовать этот режим, только если scope требует полного review, capability decision или base contract, а review-агент не может сам читать project worktree. Не применять его к отдельному proposal, design, tasks или diff, если запрошенный verdict не зависит от project inventory. Это evidence-policy skill, а не требование OpenSpec.

## Выбрать источник evidence

1. Если project worktree доступен, вернуться к обычному workflow и собрать evidence самостоятельно.
2. Если приложенные материалы уже содержат нужные факты, использовать их и запросить только точно известный недостающий файл или фрагмент.
3. Если нужно искать подходящую capability, дублирующее requirement или конфликтующий active delta, а inventory недоступен, сформировать bounded read-only prompt локальному агенту по шаблону ниже.

Не просить пользователя вручную выбирать потенциально релевантные specs, если локальный агент может проверить полный репозиторий. Локальный агент собирает кандидатов и evidence, но не принимает semantic decision вместо `review-openspec-change`.

В третьем случае вернуть адаптированный prompt целиком как готовое следующее действие. Не заменять его общим советом собрать evidence или перечнем нужных файлов.

## Сохранить verdict gate

До полного verdict проверить обычный review-комплект из `SKILL.md`. Для capability decision обязательно получить:

- inventory permanent capabilities с полными paths и `Purpose`;
- полные релевантные base requirements и scenarios;
- релевантные active changes и их delta paths;
- фактические project schema, config, rules и change-local metadata.

Пока необходимое evidence отсутствует, вернуть `BLOCKED` с одним следующим действием. Если нужен repo-wide поиск, этим действием должен быть запуск готового evidence prompt. Разрешено дать provisional findings по доступным артефактам, но нельзя выдавать `PASS`, утверждать отсутствие подходящей capability или фиксировать статус `existing` / `new` / `migration`.

Использовать archived changes только как историческое evidence. Они не заменяют permanent specs и active deltas как источники текущего контракта.

## Сформировать локальный evidence prompt

Адаптировать prompt к конкретному change: заполнить известные path, intent, actors, behavior и спорные утверждения. Не возвращать пользователю незаполненный шаблон.

```text
Работай в локальном репозитории <repo> только на чтение.

Цель: собрать evidence bundle для OpenSpec review change `<change>`.
Контекст поиска: <intent, actors, observable behavior, consumers и известные спорные утверждения>.

Ограничения:
- Не изменяй OpenSpec, код, Jira, Git, внешние системы или конфигурацию.
- Не создавай и не форматируй файлы, не запускай команды с побочными эффектами.
- До поиска выполни `git status --short`; повтори ту же команду после поиска. Не очищай существующие изменения. Верни оба полных вывода, включая пустой.
- Не выбирай окончательную target capability и не выноси verdict за `review-openspec-change`.
- Считай archive только историческим evidence, а не текущим source of truth.

Собери evidence:
1. Найди change и прочитай релевантные `AGENTS.md`, `openspec/config.yaml`, change-local `.openspec.yaml`, resolved schema, templates и artifact rules. Укажи установленную версию OpenSpec и использованные read-only команды, если resolution зависит от CLI.
2. Рекурсивно инвентаризируй все `openspec/specs/**/spec.md`. Для каждой permanent capability верни полный path и `Purpose`.
3. Выведи поисковые признаки из change: actors, observable behavior, consumers, ownership, lifecycle и trust boundary. Ищи кандидатов по смыслу, а не только по имени или delta path.
4. Для каждого кандидата верни точные `file:line`, полный `Purpose`, полные релевантные requirement/scenario blocks, краткое основание и неизвестное.
5. Проверь все active changes, исключая `openspec/changes/archive/**`. Верни релевантные delta paths, точные `file:line`, полные пересекающиеся delta blocks и характер возможного overlap или conflict.
6. Ищи похожие archived changes только для истории решений, rename или migration. Явно пометь их как historical evidence.
7. Если capability decision или factual claim зависит от кода, теста либо внешнего контракта в доступном checkout, верни подтверждающие `file:line` и полный релевантный блок.

Формат результата:
- Scope поиска и использованные read-only команды.
- Project OpenSpec contract.
- Inventory permanent capabilities.
- Candidate base specs.
- Relevant active deltas.
- Historical archive evidence.
- Relevant code или contract evidence.
- Unknowns и coverage limits.
- Полные `git status --short` до и после.

Для утверждения об отсутствии кандидатов, дубликатов или конфликтов перечисли проверенные roots, поисковые признаки и запросы. Не заменяй evidence пересказом без точных ссылок.
```

После получения bundle продолжить тот же review: проверить evidence самостоятельно, принять capability decision и пересчитать verdict. Не считать вывод локального агента доказательством без приведенных paths и фрагментов.
