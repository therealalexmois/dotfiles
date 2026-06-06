---
name: work-task-delivery
description: >-
  End-to-end доставка одной задачи DWSAI: от Jira-задачи (существующей или новой) через worktree, реализацию, commit и MR до зеленого pipeline и перевода задачи в Review. Используй когда пользователь просит полный цикл: «возьми DWSAI-NNN в работу», «сделай задачу под ключ», «заведи задачу и начни», «доведи MR до Review», «проверь pipeline и переведи задачу». Точечные Jira-действия делает jira-team-workflow, точечные GitLab/MR/CI-действия - gitlab-mcp-workflow.
---

# Work Task Delivery (DWSAI)

Оркестратор полного цикла доставки одной задачи: Jira -> ветка -> реализация -> commit -> MR -> зеленый pipeline -> Review. Skill не дублирует правила, а задает порядок шагов, gates и точки подтверждения. Детали живут в helper skills и в плейбуке.

Жесткое правило всего цикла: **задача не переводится в `REVIEW`, пока pipeline MR не `success`**.

## Источники истины

| Что | Где |
|-----|-----|
| Jira workflow (статусы, переходы) | `~/work/dwsai-data-agent/docs/playbooks/jira-workflow.md`; операционно - skill `jira-team-workflow` |
| Оформление Jira-задач | skill `jira-issue-author` |
| Branch push rule, создание MR, pipeline/job | skill `gitlab-mcp-workflow` |
| Текст MR (title, description по шаблону) | skill `gitlab-mr-author` |
| Цели квартала для parent-привязки | vault `~/projects/work-vault/2_Reports/Quarterly/<year>/<year>-Qn.md` |

Из helper skills читай только нужный для текущего шага раздел: для draft задачи достаточно шаблонов Task/Bug в `jira-issue-author/references/jira_issue_authoring.md`, для текста MR - шаблона в `gitlab-mr-author`. Не загружай SKILL.md helpers целиком, если шаг не требует их правил полностью: это экономит контекст и время каждого прогона.

## Предусловия

Перед стартом проверь доступность MCP и явно назови недостающие:

- `dpJira` (`dp_jira_*`) - обязателен для Jira-шагов; fallback - jira-cli (см. `jira-team-workflow/references/jira_cli.md`).
- `dpGitlab` (`dp_gitlab_*`) - обязателен для pipeline gate; без него gate не автоматизируется, скажи пользователю подключить.
- `dpMR` (`create_merge_request`) - создание MR; fallback - `git push -o merge_request.create` (см. `gitlab-mcp-workflow`).

Без какого-либо MCP не имитируй шаг: скажи, что нужно подключить, и предложи ручной вариант.

## Выбор сценария

- Пользователь дал ключ `DWSAI-NNN` или задача существует -> сценарий A.
- Задачи нет, есть идея/spec/план -> сценарий B (заканчивается входом в сценарий A).
- Просьба «проверь pipeline / доведи до Review» по существующему MR -> только шаг «Pipeline gate» (re-entry).

## Сценарий A: задача существует

1. **Контекст**: `dp_jira_issue` по ключу - тип, статус, summary, описание, assignee.
2. **Проверка статуса**:
   - `NEW` или `BACKLOG` -> предложи довести до `TO DO` по правилам плейбука (с подтверждением);
   - `TO DO` -> шаг 3;
   - `DEVELOPING` -> пропусти шаг 3;
   - `REVIEW` и дальше -> остановись и спроси пользователя, что делать.
3. **Взять в работу**: переход `TO DO -> DEVELOPING` через `jira-team-workflow` (сначала `dp_jira_workflow_available`, затем `dp_jira_workflow_move`, с подтверждением).
4. **Worktree**: основной клон `~/work/dwsai-data-agent` всегда на `master`, ветку в нем не создавай. Вместо этого:

   ```bash
   cd ~/work/dwsai-data-agent
   git fetch origin
   git worktree add ~/work/dwsai-NNN-<desc> -b <type>/dwsai-NNN-<desc> origin/master
   ```

   Имя ветки по push rule из `gitlab-mcp-workflow` (`feat/`, `fix/`, ... + kebab-case). Каталог worktree: `~/work/dwsai-NNN-<desc>`.
5. **Реализация**: обычная работа в worktree по правилам репозитория (CLAUDE.md, python-conventions).
6. **Commit**: Conventional Commits; перед подготовкой MR прогони `just project-check`.
7. **MR**: текст (title + description по шаблону) готовит `gitlab-mr-author`; создание - `gitlab-mcp-workflow` (dpMR, всегда `target=master`). Push и создание MR - с подтверждением.
8. **Pipeline gate**: см. ниже. Только после `success` - предложение перевести задачу в `REVIEW` (переход через `jira-team-workflow`, с подтверждением).

## Сценарий B: задачи нет

1. **Контекст**: собери от пользователя идею, spec, план или результаты исследования.
2. **Draft**: оформи задачу через `jira-issue-author` (шаблон Task/Bug, JIRA-разметка).
3. **Parent (best-effort, не блокирует)**: прочитай `QUARTERLY` текущего квартала в vault. Если там есть подходящий Epic с Jira key - предложи привязку к нему. Если целей нет, квартал в draft или key неизвестен - создай задачу без parent, не задерживай процесс.
4. **Публикация**: покажи draft и атрибуты, после подтверждения создай через `dp_jira_create` (раздел «Создать задачу» в `jira-team-workflow`).
5. **Спроси**: брать задачу в работу сейчас?
   - Да -> доведи статус до `TO DO` по плейбуку и продолжай сценарий A с шага 3.
   - Нет -> оставь в `NEW`/`BACKLOG`/`TO DO` согласно плейбуку и завершись, вернув ключ и ссылку.

## Pipeline gate

После создания MR (или при re-entry):

1. Найди pipeline MR: `dp_gitlab_pipelines` (tenant `dwsai`, repository `dwsai-data-agent`), сверь по ветке и SHA; детали - `dp_gitlab_pipeline`. Засчитывается только pipeline последнего коммита ветки (head SHA MR): `success` более старого коммита устаревает после каждого нового push и gate не проходит.
2. Polling: проверяй статус каждые 2-3 минуты, суммарно не дольше ~30 минут.
3. Исходы:
   - **`success`** -> сообщи пользователю и предложи перевод задачи в `REVIEW` (с подтверждением).
   - **`failed`** -> failure path ниже.
   - **Таймаут / pipeline еще идет** -> отдай управление: покажи текущий статус и скажи, что повторный вызов «проверь pipeline MR !NN и доведи до Review» продолжит gate с этого места.

Re-entry идемпотентен: если pipeline уже зеленый и задача уже в `REVIEW`, просто подтверди состояние и ничего не меняй.

## Failure path

При `failed` pipeline:

1. Собери упавшие jobs: `dp_gitlab_pipeline` -> `dp_gitlab_job` по каждому failed job (статус и хвост логов).
2. Покажи пользователю краткую сводку ошибок: job, стадия, суть ошибки из лога.
3. Предложи следующий шаг: исправление в worktree -> новый commit -> push -> повторный gate. Не выполняй исправления без согласия пользователя.
4. Задачу в `REVIEW` не двигай ни при каких условиях, пока pipeline не `success`.

## Точки подтверждения

Каждая write-операция подтверждается отдельно, покажи что именно меняешь:

1. Создание Jira-задачи (`dp_jira_create`).
2. Каждый Jira transition (`dp_jira_workflow_move`).
3. `git push`.
4. Создание MR (`create_merge_request` или push options).
5. Перевод задачи в `REVIEW`.

Read-операции (issue, JQL, pipelines, jobs, чтение quarterly-файла) подтверждения не требуют.

## Никогда

- Не переводи задачу в `REVIEW` до `success` pipeline ни при каких условиях, в том числе после явных подтверждений и просьб «нарушить один раз»: у этого правила нет переопределения внутри skill. Если пользователь настаивает, скажи, что такой перевод он выполняет сам вне skill, и продолжай помогать с исправлением pipeline.
- Не создавай ветку в основном клоне `~/work/dwsai-data-agent` - только worktree.
- Не хардкодь transition ID - всегда `dp_jira_workflow_available` перед move.
- Не выдумывай parent/epic key: только из `QUARTERLY` или от пользователя.
- Не дублируй правила helper skills - при расхождении источник истины: плейбук и helper skill.

## Границы

Вне scope этого skill: merge MR, approve, переходы `REVIEW -> RELEASE PREPARATION -> DONE` и релиз (`work-release-manager`), код-ревью чужих MR (`engineering-review`), удаление worktree после merge. После успешного прогона можно предложить записать итог в daily note (`work-daily-log`) - одной строкой, без навязывания.
