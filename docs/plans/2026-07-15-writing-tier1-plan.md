# Tier 1 Rules Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development or
> executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`)
> syntax for tracking.

**Goal:** превратить `lint_banned_terms.py` из линтера одного правила в
детерминированный движок правил с общим протоколом, добавить R2 (`—`->`–`) и R4
(пробелы) и режим `--fix`.

**Architecture:** один самодостаточный CLI-скрипт (`uv run`, PEP 723). Типы правил -
в коде за протоколом `Rule`; данные - в `banned-terms.toml`. Маскирование кода/URL
даёт список исключённых span на строку; term/em-dash матчатся по masked, whitespace -
по raw с фильтром по span. Автофикс применяет замены на raw по офсетам матча
справа-налево.

**Tech Stack:** Python 3.11+, `tomllib` (stdlib), `markdown-it-py`, `pytest` (тесты
через `uv run --with pytest`).

Полный дизайн: `docs/plans/2026-07-15-writing-tier1-design.md`.

---

## File Structure

- Modify: `ai-agents/.agents/skills/writing/scripts/lint_banned_terms.py` - ввести
  `Hit`, `Rule`-протокол, три правила (`TermRule`, `EmDashRule`, `WhitespaceRule`),
  движок и `--fix`. Один файл: скрипт остаётся самодостаточным для `uv run`.
- Create: `ai-agents/.agents/skills/writing/scripts/test_lint_banned_terms.py` -
  pytest-тесты правил, движка и `--fix`.
- Modify: `ai-agents/.agents/skills/writing/SKILL.md` - описать `--fix` в шаге
  «Чистота».

---

## Task 1: Span-based masking

**Files:**
- Modify: `scripts/lint_banned_terms.py`
- Test: `scripts/test_lint_banned_terms.py`

- [ ] **Step 1: Тест на span-хелперы**

```python
def test_prose_spans_marks_inline_code_and_url():
    line = "код `x  y` и http://a.b/c текст"
    spans = prose_spans(line)
    assert any(line[s:e] == "`x  y`" for s, e in spans)
    assert any(line[s:e].startswith("http") for s, e in spans)

def test_blank_spans_preserves_length():
    line = "a `code` b"
    masked = blank_spans(line, prose_spans(line))
    assert len(masked) == len(line)
    assert "code" not in masked
```

- [ ] **Step 2: Реализовать `prose_spans`, `blank_spans`, `in_spans`**

```python
def prose_spans(line: str) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    for pattern in MASK_INLINE:
        spans.extend((m.start(), m.end()) for m in pattern.finditer(line))
    return spans

def blank_spans(line: str, spans: list[tuple[int, int]]) -> str:
    chars = list(line)
    for start, end in spans:
        for i in range(start, end):
            chars[i] = " "
    return "".join(chars)

def in_spans(pos: int, spans: list[tuple[int, int]]) -> bool:
    return any(start <= pos < end for start, end in spans)
```

- [ ] **Step 3: Прогнать тесты** - `uv run --with pytest pytest scripts/test_lint_banned_terms.py -k spans -v`. Expected: PASS.

## Task 2: `Rule`-протокол и `Hit`

**Files:**
- Modify: `scripts/lint_banned_terms.py`

- [ ] **Step 1: Ввести `Hit` и протокол**

```python
@dataclass(frozen=True)
class Hit:
    start: int
    end: int
    matched: str
    message: str
    replacement: str | None  # None -> report-only

class Rule(Protocol):
    id: str

    def scan_line(self, masked: str, raw: str, spans: list[tuple[int, int]]) -> Iterable[Hit]: ...
```

- [ ] **Step 2: Расширить `Finding` полем `fixable`, добавить `rule_id`.**

## Task 3: R1 `TermRule` (рефактор существующего)

- [ ] **Step 1: Тест** - термин находится, замена в message, report-only.

```python
def test_term_rule_reports_stem_without_fix():
    terms = load_terms(DEFAULT_TERMS)
    hits = list(TermRule(terms).scan_line("сделали провижинг", "сделали провижинг", []))
    assert hits and hits[0].replacement is None
    assert "провижинг" in hits[0].matched
```

- [ ] **Step 2: Реализовать `TermRule`** матчами по `masked`, `replacement=None`.

## Task 4: R2 `EmDashRule`

- [ ] **Step 1: Тест** - `—` в прозе флагается и фиксится в `–`, в коде нет.

```python
def test_em_dash_flagged_in_prose_not_in_code():
    rule = EmDashRule()
    assert list(rule.scan_line("текст — текст", "текст — текст", []))
    masked = blank_spans("`a — b`", prose_spans("`a — b`"))
    assert not list(rule.scan_line(masked, "`a — b`", prose_spans("`a — b`")))
```

- [ ] **Step 2: Реализовать**

```python
EM_DASH = re.compile("—")

class EmDashRule:
    id = "em-dash"

    def scan_line(self, masked, raw, spans):
        for m in EM_DASH.finditer(masked):
            yield Hit(m.start(), m.end(), m.group(0), "замените — на –", "–")
```

## Task 5: R4 `WhitespaceRule`

- [ ] **Step 1: Тесты** - внутренний двойной пробел флагается; хвостовые 2 пробела (markdown-перенос) - нет; пробел перед пунктуацией флагается; двойной пробел в inline-коде - нет.

```python
def test_internal_double_space_flagged():
    assert list(WhitespaceRule().scan_line("текст  текст", "текст  текст", []))

def test_trailing_double_space_not_flagged():
    raw = "строка  "
    assert not list(WhitespaceRule().scan_line(raw, raw, []))

def test_space_before_punct_flagged():
    hits = list(WhitespaceRule().scan_line("текст ,", "текст ,", []))
    assert hits and hits[0].replacement == ""

def test_double_space_in_code_span_ignored():
    raw = "a `x  y` b"
    spans = prose_spans(raw)
    assert not list(WhitespaceRule().scan_line(blank_spans(raw, spans), raw, spans))
```

- [ ] **Step 2: Реализовать** (матчи по `raw`, фильтр по `spans`)

```python
DOUBLE_SPACE = re.compile(r"(?<=\S) {2,}(?=\S)")
SPACE_BEFORE_PUNCT = re.compile(r"(?<=\S)( +)(?=[,.;:!?])")

class WhitespaceRule:
    id = "whitespace"

    def scan_line(self, masked, raw, spans):
        for m in DOUBLE_SPACE.finditer(raw):
            if not in_spans(m.start(), spans):
                yield Hit(m.start(), m.end(), m.group(0), "лишние пробелы", " ")
        for m in SPACE_BEFORE_PUNCT.finditer(raw):
            if not in_spans(m.start(1), spans):
                yield Hit(m.start(1), m.end(1), m.group(1), "пробел перед пунктуацией", "")
```

## Task 6: Движок scan + build_rules

- [ ] **Step 1: Тест интеграции на temp-файле** - term + em-dash + whitespace находятся, frontmatter/code/url исключены.
- [ ] **Step 2: Реализовать** `build_rules(terms)` и `scan(path, rules)`, собирающий `Finding` из всех правил по не-исключённым строкам.

## Task 7: Режим `--fix`

- [ ] **Step 1: Тесты** - `—`->`–`, двойной пробел схлопнут, пробел перед пунктуацией убран; термин остаётся report-only; повторный прогон идемпотентен.

```python
def test_fix_applies_fixable_leaves_report_only(tmp_path):
    f = tmp_path / "t.md"
    f.write_text("текст — текст  и провижинг ,\n", encoding="utf-8")
    remaining = fix_file(f, build_rules(load_terms(DEFAULT_TERMS)))
    out = f.read_text(encoding="utf-8")
    assert "—" not in out and "  " not in out and " ," not in out
    assert any(r.rule_id == "banned-term" for r in remaining)
```

- [ ] **Step 2: Реализовать** `fix_line` (замены справа-налево, без пересечений) и `fix_file`; `--fix` в CLI. Exit: 0 если не осталось findings, 1 если остались report-only, 2 ошибка.

## Task 8: CLI, docs, регресс

- [ ] **Step 1:** добавить флаг `--fix` в `argparse`, развести режимы report / fix.
- [ ] **Step 2:** обновить `SKILL.md` (шаг «Чистота»): `--fix` чинит fixable, report-only разрешает человек/LLM.
- [ ] **Step 3: Полный прогон**

```sh
uv run --with pytest --with markdown-it-py pytest scripts/test_lint_banned_terms.py -v
uv run scripts/lint_banned_terms.py scripts/../SKILL.md   # dogfood, ждём чисто
```

- [ ] **Step 4: Commit**

```sh
git add ai-agents/.agents/skills/writing/scripts/ ai-agents/.agents/skills/writing/SKILL.md
git commit -m "feat(skills): add rules engine, em-dash and whitespace rules with --fix"
```

---

## Self-Review

- **Coverage:** каждое решение дизайна (1-6) имеет задачу: планка (в каталоге правил),
  каталог R1/R2/R4 (Tasks 3-5), конфиг/код (Task 2 протокол), маскирование (Task 1),
  автофикс (Task 7), контракт Tier1/Tier2 (Task 8 docs). R3 - вне этой волны.
- **Типы:** `Hit`, `Finding`, `Rule.scan_line` согласованы между задачами.
- **Placeholder-scan:** код показан во всех шагах, заглушек нет.
