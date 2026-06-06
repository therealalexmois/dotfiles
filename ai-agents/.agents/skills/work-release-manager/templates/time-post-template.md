# Time post (инженеры, канал dws-ai-agent)

Главный анонс релиза в инженерном канале. Короткий, без таблиц, ссылается на
wiki manifest. Общие правила (status, язык, ссылки) -
[announcement-rules.md](../references/announcement-rules.md). Длинные Sage-ссылки и
post-release observation - в thread ([thread-template.md](thread-template.md)).

Отвечает быстро: что выпущено, healthy ли prod, есть ли user impact, что
изменилось, кто owner, где детали, какой rollback target.

## Структура

```
## Production release: data-agent <release-tag>

**Status**: <release-status>
**Previous release**: [<previous-release>](<previous-tag-url>)
**Rollback target**: [<previous-release>](<previous-tag-url>)
**User impact**: <короткая сводка user impact, либо «none»>

**Links**: [Pipeline](url) · [Compare](url) · [Deploy](url) · [Logs](url) · [Manifest](url)

---

### Summary
- **Rollout**: <короткое состояние rollout>.
- **DB migrations**: <yes / no / unknown>.
- **Secrets/runtime config**: <changes / no changes / unknown>.
- **Feature flags**: <changes / known issue / no changes>.

---

### Changelog
**Features**
- **<scope>**: <короткое описание изменения>. @owner

**Fixes**
- **<scope>**: <короткое описание изменения>. @owner

**Docs / Chore**
- **<scope>**: <сгруппированная сводка docs/chore, максимум 2 буллета>. @owner

---

### Known issues
- **<ISSUE_CODE>**: <сводка issue>. **Impact**: <impact>. **Owner**: @owner. **Action**: <action>.
```

## Правила

Вводную метку перед двоеточием делать жирной по всему посту - в metadata-блоке
(`**Status**:`, `**User impact**:`), `**Links**:`, буллетах Summary
(`**Rollout**:`), scope в changelog (`**metrics**:`) и метках Known issues
(`**Impact**:`, `**Owner**:`, `**Action**:`). Если у буллета changelog нет
scope-метки - жирной выделять нечего.

Должен: оставаться коротким; `User impact` - отдельной строкой; `Rollback
target` - всегда; ссылка на manifest - всегда; owner - прямо в буллете changelog
как `@login`; Docs / Chore - максимум 2 буллета; feature flags - только если
изменились или проблемные; known issue - один раз, не размазывать; длинные Sage-
ссылки держать вне основного поста (в thread).

Не должен содержать: полную ownership-таблицу; полную MR/Jira-таблицу; длинные
Sage URL; детальный deploy manifest; детальные image/pod/cluster данные (кроме
инцидента); повтор одного known issue.

## Owner format

Owner - в конце буллета changelog как `@login`. Не добавлять «Проверка:» или
«Production check:».

Хорошо:

- Helicopter: подстановка элемента формы и проверка Thermostat token. @da.sharipov

Плохо:

- ... Thermostat token. Проверка: @da.sharipov

Логины: искать в участниках канала `dws-ai-team`, для внешних контрибьюторов -
`dwsai-agent-skills-contributors` (`get_channel_members` + `get_users_info`,
match по display name автора коммита/MR). Нет в каналах и `search_users`
неоднозначен - оставить имя без `@`, логин не выдумывать.

## Лимит и доставка

Лимит Time - 4000 символов. Если не влезает - сокращать, длинные Sage deep-
ссылки выносить в thread (`create_post` с `root_id`). Перед постом в канал -
DM-self-test (`dm` на свой username), проверить Mattermost-markdown. Публикация
в канал - только после `AskUserQuestion`.

Mattermost-рендеринг (плотная верстка):

- Крупные секции (`### Summary`, `### Changelog`, `### Known issues`) разделяй
  горизонтальной линией `---` (пустая строка, `---`, пустая строка перед
  заголовком). Это дает четкие чанки.
- `###`-заголовок и групповой `**Features**/**Fixes**/**Docs / Chore**` ставь
  вплотную к своим буллетам, без пустой строки между ними, иначе заголовок
  «висит» с разрывом сверху и снизу.
- Пустую строку держи только перед жирным групповым заголовком (после буллетов
  предыдущей группы), иначе он прилипнет к предыдущему буллету как continuation.
- Буллеты внутри группы - без пустых строк между ними (tight list).
- `Previous release` и `Rollback target` оформляй ссылками на tag-страницы.
