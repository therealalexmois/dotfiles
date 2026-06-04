<!-- Источник: references/commands.md и блоки Quick Reference (CLI) / No Backend Available из skill jira (hwaas/nmsgo, .agents/skills/jira/SKILL.md, MR !584 и !607). Это альтернативный backend на случай, если dp_jira_* MCP недоступен. Основной backend проекта DWSAI - dp_jira_* MCP, см. SKILL.md. -->

# Jira CLI (backend `jira`)

Справочник по CLI `jira` (ankitpokhrel/jira-cli). Это альтернативный backend для операций с задачами, когда `dp_jira_*` MCP недоступен. Основной backend проекта DWSAI - `dp_jira_*` MCP (Spirit CLI); см. `SKILL.md`.

Safety-правило из `SKILL.md` действует и здесь: write-операции (`create`, `move`, `assign`, `comment add`, `link`) выполняй только после подтверждения, показывай команду перед запуском.

## Выбор backend

1. Проверь CLI: `which jira`. Если найден - можно использовать CLI backend.
2. Если CLI нет, используй `dp_jira_*` MCP (основной для DWSAI).
3. Если недоступно ничего - см. раздел `Если backend недоступен`.

## Quick Reference (CLI)

| Намерение | Команда |
|-----------|---------|
| Посмотреть задачу | `jira issue view ISSUE-KEY` |
| Мои задачи | `jira issue list -a$(jira me)` |
| Мои в работе | `jira issue list -a$(jira me) -s"In Progress"` |
| Создать задачу | `jira issue create -tType -s"Summary" -b"Description"` |
| Перевести по workflow | `jira issue move ISSUE-KEY "State"` |
| Назначить на себя | `jira issue assign ISSUE-KEY $(jira me)` |
| Снять назначение | `jira issue assign ISSUE-KEY x` |
| Добавить комментарий | `jira issue comment add ISSUE-KEY -b"Comment text"` |
| Открыть в браузере | `jira open ISSUE-KEY` |
| Текущий спринт | `jira sprint list --state active` |
| Кто я | `jira me` |

## Просмотр задач

```bash
# Одна задача
jira issue view ISSUE-KEY

# С комментариями
jira issue view ISSUE-KEY --comments 5

# Сырой JSON
jira issue view ISSUE-KEY --raw
```

## Поиск и списки

```bash
# Все задачи проекта
jira issue list

# Мои задачи
jira issue list -a$(jira me)

# По статусу (многословные статусы в кавычках)
jira issue list -s"In Progress"
jira issue list -s"To Do"
jira issue list -sDone

# По типу
jira issue list -tBug
jira issue list -tStory
jira issue list -tTask
jira issue list -tEpic

# По приоритету
jira issue list -yHigh
jira issue list -yCritical

# По метке
jira issue list -lurgent -lbug

# Комбинация фильтров
jira issue list -a$(jira me) -s"In Progress" -yHigh

# Текстовый поиск
jira issue list "login error"

# Недавно открытые
jira issue list --history

# За которыми слежу
jira issue list -w

# По дате создания / обновления
jira issue list --created today
jira issue list --created week
jira issue list --updated -2d

# Plain-вывод для скриптов
jira issue list --plain --no-headers
jira issue list --plain --columns key,summary,status,assignee

# Сырой JQL
jira issue list -q"status = 'In Progress' AND assignee = currentUser()"

# Пагинация
jira issue list --paginate 20
jira issue list --paginate 10:50 # start:limit
```

## Создание задач

```bash
# Интерактивно
jira issue create

# Неинтерактивно со всеми полями
jira issue create \
    -tBug \
    -s"Login button not working" \
    -b"Users cannot click the login button on Safari" \
    -yHigh \
    -lbug -lurgent

# Создать и назначить на себя
jira issue create -tTask -s"Summary" -a$(jira me)

# Sub-task (нужен parent)
jira issue create -tSub-task -P"PROJ-123" -s"Subtask summary"

# С custom field
jira issue create -tStory -s"Summary" --custom story-points=3

# Без промптов для опциональных полей
jira issue create -tTask -s"Quick task" --no-input

# Открыть в браузере после создания
jira issue create -tBug -s"Bug title" --web

# Описание из файла
jira issue create -tStory -s"Summary" --template /path/to/template.md

# Описание из stdin
echo "Description here" | jira issue create -tTask -s"Summary"
```

**Многострочное содержимое.** CLT плохо принимает многострочные строки в аргументе. Сначала запиши тело во временный файл:

```bash
cat > /tmp/jira_body.md <<'EOF'
## Description
User needs ability to export data...

## Acceptance Criteria
- Export works for CSV
- Export works for JSON
EOF

jira issue create --no-input \
  -tStory \
  -pPROJ \
  -s"Add export functionality" \
  -b"$(cat /tmp/jira_body.md)"
```

> Не используй `--no-input` без всех обязательных полей: команда падает с невнятной ошибкой. Сначала проверь обязательные поля проекта.

## Переходы по workflow

```bash
# Перевести в статус
jira issue move ISSUE-KEY "In Progress"
jira issue move ISSUE-KEY "Done"
jira issue move ISSUE-KEY "To Do"

# С комментарием
jira issue move ISSUE-KEY "Done" --comment "Completed the implementation"

# С резолюцией
jira issue move ISSUE-KEY "Done" -R"Fixed"

# С переназначением
jira issue move ISSUE-KEY "In Review" -a"reviewer@example.com"

# Открыть в браузере после перехода
jira issue move ISSUE-KEY "Done" --web
```

> Имена статусов и переходов зависят от проекта. Перед переходом сверяй доступные имена, не хардкодь.

## Назначение

```bash
jira issue assign ISSUE-KEY "user@example.com"
jira issue assign ISSUE-KEY "John Doe"
jira issue assign ISSUE-KEY $(jira me)
jira issue assign ISSUE-KEY default
jira issue assign ISSUE-KEY x   # снять назначение
```

## Комментарии

```bash
jira issue comment add ISSUE-KEY -b"This is my comment"
jira issue comment add ISSUE-KEY --template /path/to/comment.md
```

## Спринты

```bash
jira sprint list
jira sprint list --state active
jira sprint add SPRINT-ID ISSUE-KEY
jira sprint close SPRINT-ID
```

## Связи между задачами

| Связь | Значение |
|-------|----------|
| `Blocks` | Первая задача блокирует вторую |
| `Relates` | Общая связь |
| `Duplicate` | Та же работа |
| `Epic-Story` | Story принадлежит Epic |

```bash
jira issue link PROJ-123 PROJ-456 "Relates"
jira issue link PROJ-100 PROJ-200 "Blocks"   # PROJ-100 блокирует PROJ-200
jira issue link PROJ-EPIC PROJ-STORY "Epic-Story"
```

## Прочее

```bash
jira open ISSUE-KEY        # открыть в браузере
jira me                    # текущий пользователь
jira serverinfo            # информация о сервере
jira project list          # список проектов
jira board list            # список досок
```

## Если backend недоступен

Если недоступен ни `dp_jira_*` MCP, ни CLI `jira`, не выдумывай операции. Подскажи пользователю варианты:

1. CLI `jira` (ankitpokhrel/jira-cli): `brew install ankitpokhrel/jira-cli/jira-cli`, затем `jira init`.
2. `dp_jira_*` MCP (Spirit CLI) - основной backend проекта DWSAI.

Всегда явно показывай проблемы аутентификации, чтобы пользователь мог их устранить.
