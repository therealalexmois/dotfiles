# ExcalidrawZ MCP: режимы, восстановление, ограничения

Читай, когда не ясно, в каком режиме MCP, нужно восстановить затертый файл или доступен
режим Optimized. Факты собраны по исходникам ExcalidrawZ v2.5.1 (октябрь 2026) на
github.com/chocoford/ExcalidrawZ; на конкретной сборке пользователя их нужно перепроверять.

## Подключение

ExcalidrawZ – десктопное приложение macOS. Его MCP-сервер слушает `127.0.0.1:8490` и
подключается в Claude Code через `npx mcp-remote http://127.0.0.1:8490/mcp`. Инструменты
появляются как `mcp__excalidrawz__*`.

## Режимы

| Режим | Инструменты | Куда пишет |
| --- | --- | --- |
| Basic (по умолчанию) | `read_me`, `create_view` | В активный файл, заменяя содержимое |
| Optimized | `get_app_context`, `get_current_file`, `list_groups`, `list_files`, `create_file`, `open_file`, `read_view`, `replace_view`, `set_canvas_preferences`, `get_current_file_checkpoints` и другие | В выбранный или созданный файл |

Режим переключается в настройках MCP приложения. Optimized откатывается в Basic, если
приложение считает его недоступным; условие доступности не выяснено.

Режим определяй по списку инструментов: если есть только `read_me` и `create_view`, это Basic.

## Восстановление затертого файла

Перед записью через MCP приложение сохраняет checkpoint «Before MCP update», после записи
второй. Чтобы вернуть содержимое: открыть файл, вкладка History в инспекторе, выбрать
checkpoint «Before MCP update», «Restore from history». Срок хранения истории не выяснен.

`restoreCheckpoint` в `create_view` возвращает только к `checkpointId` из ответов
`create_view` этой сессии. Состояние до первого вызова он не вернет.

## Ошибки записи

| Ответ `create_view` | Причина | Что делать |
| --- | --- | --- |
| `The file “<имя>.excalidraw” couldn’t be opened because there is no such file.` | Активный файл переименовали или перенесли после открытия, приложение держит старый путь | Не повторять вызов, попросить переоткрыть файл и подтвердить (наблюдалось 2 ноября 2026 года) |

## Ограничения Basic

- Шрифт: конвертер ставит всем `text` и меткам `fontFamily: 5` (Excalifont, рукописный),
  значение из JSON игнорируется. Обход – выделить все и сменить шрифт в панели свойств.
- Санитайзер по умолчанию ставит `fillStyle: "hachure"` и `strokeWidth: 1`, поэтому эти поля
  задаются явно.
- Работы с библиотеками нет. Готовых библиотек Excalidraw для sequence-диаграмм тоже нет.
- Mermaid-конвертер Excalidraw делает редактируемым только flowchart, sequence вставляет
  картинкой. Инструмента для Mermaid в MCP нет.

## Номера шрифтов Excalidraw

| `fontFamily` | Шрифт | Вид |
| --- | --- | --- |
| 1, 5 | Virgil, Excalifont | Рукописный |
| 2, 6, 9 | Helvetica, Nunito, Liberation Sans | Обычный |
| 3, 8 | Cascadia, Comic Shanns | Моноширинный |
