"""Тесты линтера Tier 1 (`lint_banned_terms.py`).

Запуск: uv run --with pytest --with markdown-it-py --with mdit-py-plugins \
    pytest test_lint_banned_terms.py -v
"""

from __future__ import annotations

import pytest

import lint_banned_terms as lint

EM = chr(0x2014)  # длинное тире, строим без литерала
EN = chr(0x2013)  # короткое тире


def rules() -> list[lint.Rule]:
    return lint.build_rules(lint.load_terms(lint.DEFAULT_TERMS), lint.load_yo_keep(lint.DEFAULT_TERMS))


def mkline(raw: str, *, is_table_row: bool = False) -> lint.Line:
    """Строит `Line` для одной строки: regex-маски + backtick-спаны segment-а."""
    spans = lint.prose_spans(raw)
    spans.extend(lint.code_span_lines([raw], [(0, 1)]).get(0, []))
    return lint.Line(raw=raw, masked=lint.blank_spans(raw, spans), spans=spans, is_table_row=is_table_row)


def test_prose_spans_marks_url_not_backticks():
    line = "код `x  y` и http://a.b/c текст"
    spans = lint.prose_spans(line)

    # backtick-спаны теперь считаются отдельно (code_span_lines), не в prose_spans.
    assert any(line[s:e].startswith("http") for s, e in spans)
    assert not any(line[s:e] == "`x  y`" for s, e in spans)


def test_code_span_masked_via_segment():
    line = "a `code` b"
    masked = mkline(line).masked

    assert len(masked) == len(line)
    assert "code" not in masked


def test_term_rule_reports_stem_without_fix():
    hits = list(lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS)).scan_line(mkline("сделали провижинг")))

    assert hits
    assert hits[0].replacement is None
    assert "провижинг" in hits[0].matched


@pytest.mark.parametrize(
    "text",
    [
        "уточнить маппинг полей",
        "мэппинг компетенций",
        "собрали фидбек команды",
        "запрос скоупится по владельцу",
        "надо заскоупить задачу",
        "заасайнить тикет на себя",
        "пропушили изменение в прод",
        "диспетч результата в очередь",
        "метрика ключуется по user_id",
        "результат презентован команде",
    ],
)
def test_new_terms_flagged(text):
    rule = lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS))

    assert list(rule.scan_line(mkline(text))), text


@pytest.mark.parametrize(
    "text",
    [
        "диспетчер направил заявку",
        "диспетчеризация запросов",
        "он презентовал решение команде",
        "будет презентовать на демо",
        "ключ на столе, ключом по проводу",
    ],
)
def test_legit_words_not_flagged(text):
    rule = lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS))

    assert not list(rule.scan_line(mkline(text))), text


def test_em_dash_flagged_in_prose():
    hits = list(lint.EmDashRule().scan_line(mkline(f"текст {EM} текст")))

    assert hits
    assert hits[0].replacement == EN


def test_em_dash_in_code_ignored():
    assert not list(lint.EmDashRule().scan_line(mkline(f"`a {EM} b`")))


def test_internal_double_space_flagged():
    hits = list(lint.WhitespaceRule().scan_line(mkline("текст  текст")))

    assert hits
    assert hits[0].replacement == " "


def test_trailing_double_space_not_flagged():
    assert not list(lint.WhitespaceRule().scan_line(mkline("строка  ")))


def test_space_before_punct_flagged():
    hits = list(lint.WhitespaceRule().scan_line(mkline("текст ,")))

    assert hits
    assert hits[0].replacement == ""


def test_double_space_in_code_span_ignored():
    assert not list(lint.WhitespaceRule().scan_line(mkline("a `x  y` b")))


def test_whitespace_skips_table_row():
    line = mkline("| a    b | c |", is_table_row=True)

    assert not list(lint.WhitespaceRule().scan_line(line))


def test_em_dash_in_table_cell_still_flagged():
    line = mkline(f"| {EM} | x |", is_table_row=True)

    assert list(lint.EmDashRule().scan_line(line))


def test_scan_excludes_frontmatter_and_code(tmp_path):
    md = tmp_path / "t.md"
    md.write_text(
        "---\ntag: провижинг\n---\n\nМы сделали провижинг.\n\n```\nпровижинг\n```\n",
        encoding="utf-8",
    )

    findings = lint.scan(md, rules())

    assert {f.line for f in findings} == {5}


def test_scan_skips_table_whitespace_but_keeps_term(tmp_path):
    md = tmp_path / "tbl.md"
    md.write_text(
        "проза\n\n| A | B |\n| --- | --- |\n| x    y | провижинг |\n",
        encoding="utf-8",
    )

    findings = lint.scan(md, rules())

    assert not [f for f in findings if f.rule_id == "whitespace"]
    assert [f for f in findings if f.rule_id == "banned-term"]


def test_fix_applies_fixable_leaves_report_only(tmp_path):
    md = tmp_path / "t.md"
    md.write_text(f"текст {EM} текст  и провижинг ,\n", encoding="utf-8")

    remaining = lint.fix_file(md, rules())
    out = md.read_text(encoding="utf-8")

    assert EM not in out
    assert "  " not in out
    assert " ," not in out
    assert any(r.rule_id == "banned-term" for r in remaining)


def test_fix_preserves_table_alignment(tmp_path):
    md = tmp_path / "tbl.md"
    original = "| A | B |\n| --- | --- |\n| x    y | z |\n"
    md.write_text(original, encoding="utf-8")

    lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original


def test_fix_is_idempotent(tmp_path):
    md = tmp_path / "t.md"
    md.write_text(f"a {EM} b  c ,\n", encoding="utf-8")

    lint.fix_file(md, rules())
    once = md.read_text(encoding="utf-8")
    lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == once


def test_load_terms_empty_raises(tmp_path):
    toml = tmp_path / "empty.toml"
    toml.write_text("[[wrong]]\nid = 'x'\n", encoding="utf-8")

    with pytest.raises(ValueError):
        lint.load_terms(toml)


def test_load_terms_bad_regex_raises_value_error(tmp_path):
    toml = tmp_path / "bad.toml"
    toml.write_text(
        '[[term]]\nid = "x"\npatterns = ["("]\nreplacement = "y"\n',
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="битый regex"):
        lint.load_terms(toml)


def test_load_terms_missing_key_raises_value_error(tmp_path):
    toml = tmp_path / "nokey.toml"
    toml.write_text('[[term]]\nid = "x"\n', encoding="utf-8")

    with pytest.raises(ValueError, match="обязательного ключа"):
        lint.load_terms(toml)


def test_main_clean_returns_zero(tmp_path):
    md = tmp_path / "c.md"
    md.write_text("Чистая проза.\n", encoding="utf-8")

    assert lint.main([str(md)]) == 0


def test_main_findings_returns_one(tmp_path):
    md = tmp_path / "d.md"
    md.write_text("Мы сделали провижинг.\n", encoding="utf-8")

    assert lint.main([str(md)]) == 1


def test_main_read_error_priority_over_findings(tmp_path):
    md = tmp_path / "d.md"
    md.write_text("Мы сделали провижинг.\n", encoding="utf-8")
    missing = tmp_path / "missing.md"

    assert lint.main([str(md), str(missing)]) == 2


def test_main_non_markdown_is_error(tmp_path):
    txt = tmp_path / "n.txt"
    txt.write_text("провижинг\n", encoding="utf-8")

    assert lint.main([str(txt)]) == 2


# --- Репро из red-team отчета ---


def test_multiline_code_span_not_flagged_or_fixed(tmp_path):
    md = tmp_path / "a1.md"
    original = "начало `cmd --flag " + EM + " value  x\ny` конец\n"
    md.write_text(original, encoding="utf-8")

    findings = lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original
    assert not findings


def test_multiline_code_span_hides_term(tmp_path):
    md = tmp_path / "a1b.md"
    md.write_text("текст `провижинг\nвнутри` конец\n", encoding="utf-8")

    assert not lint.scan(md, rules())


def test_double_backtick_nested_span_not_fixed(tmp_path):
    md = tmp_path / "a8.md"
    original = "вот ``x `a  " + EM + " b` y`` конец\n"
    md.write_text(original, encoding="utf-8")

    lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original


def test_double_backtick_nested_term_not_flagged():
    line = mkline("вот ``a `провижинг` b`` конец")

    assert not list(lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS)).scan_line(line))


def test_comparison_angle_brackets_term_flagged(tmp_path):
    md = tmp_path / "a2.md"
    md.write_text("если x < y, а провижинг важен > z, то все.\n", encoding="utf-8")

    findings = lint.scan(md, rules())

    assert any(f.rule_id == "banned-term" for f in findings)


def test_crlf_preserved_by_fix(tmp_path):
    md = tmp_path / "a9.md"
    md.write_bytes("первая строка\r\nслово  слово\r\nтретья строка\r\n".encode())

    lint.fix_file(md, rules())
    out = md.read_bytes().decode()

    assert out.count("\r\n") == 3
    assert "слово слово" in out


def test_u2028_not_treated_as_newline(tmp_path):
    md = tmp_path / "a10.md"
    md.write_text("тире " + EM + " тут\nдве части\n", encoding="utf-8")

    lint.fix_file(md, rules())
    out = md.read_text(encoding="utf-8")

    assert "две части" in out


def test_bom_preserved_by_fix(tmp_path):
    md = tmp_path / "a11.md"
    md.write_bytes(b"\xef\xbb\xbf" + "слово  слово\n".encode())

    lint.fix_file(md, rules())

    assert md.read_bytes().startswith(b"\xef\xbb\xbf")


def test_frontmatter_with_blank_line_excluded(tmp_path):
    # round-2 #7: легальный YAML с пустой строкой внутри - это frontmatter,
    # а не проза; значения полей не сканируются.
    md = tmp_path / "f9.md"
    md.write_text(
        "---\ntitle: тест\n\ndescription: провижинг знач\n---\n\nтекст\n",
        encoding="utf-8",
    )

    assert not lint.scan(md, rules())


def test_leading_fenced_block_is_frontmatter(tmp_path):
    # Ведущий ---...--- markdown-it (с front_matter-плагином) трактует как
    # frontmatter - согласуется с Obsidian, средой пользователя.
    md = tmp_path / "a14.md"
    md.write_text("---\n\nМы сделали провижинг.\n\n---\n\nхвост\n", encoding="utf-8")

    assert not lint.scan(md, rules())


def test_fix_converges_in_one_run(tmp_path):
    md = tmp_path / "a7.md"
    md.write_text("слово  ,\n", encoding="utf-8")

    remaining = lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == "слово,\n"
    assert not remaining


def test_list_marker_alignment_not_flagged(tmp_path):
    md = tmp_path / "a15.md"
    original = "-   пункт\n\n        код\n"
    md.write_text(original, encoding="utf-8")

    findings = lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original
    assert not findings


def test_link_destination_with_parens_not_fixed(tmp_path):
    md = tmp_path / "a12.md"
    original = "[док](docs/a(b)v" + EM + "g.md) конец\n"
    md.write_text(original, encoding="utf-8")

    lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original


def test_reference_definition_not_fixed(tmp_path):
    md = tmp_path / "a13.md"
    original = "[id]: docs/file" + EM + "name.md\n\nссылка [текст][id] тут\n"
    md.write_text(original, encoding="utf-8")

    lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original


def test_table_instead_of_array_gives_value_error(tmp_path):
    toml = tmp_path / "table.toml"
    toml.write_text('[term]\nid = "x"\npatterns = ["a"]\nreplacement = "y"\n', encoding="utf-8")

    with pytest.raises(ValueError, match="массивом таблиц"):
        lint.load_terms(toml)


def test_empty_patterns_rejected(tmp_path):
    toml = tmp_path / "empty_patterns.toml"
    toml.write_text('[[term]]\nid = "x"\npatterns = []\nreplacement = "y"\n', encoding="utf-8")

    with pytest.raises(ValueError, match="непустым списком"):
        lint.load_terms(toml)


def test_escaped_backtick_does_not_open_span():
    line = mkline("символ \\` литерал, а провижинг дальше и `код` тут")
    hits = list(lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS)).scan_line(line))

    assert hits
    assert "провижинг" in hits[0].matched


def test_bare_url_extends_to_whitespace():
    # URL тянется до пробела: кириллический IRI маскируется целиком (round-2 #1/#5),
    # тире, приклеенное к URL, считается частью адреса (accepted round-1 #12).
    glued = mkline("смотри https://a.b" + EM + "тире тут")
    assert not list(lint.EmDashRule().scan_line(glued))

    cyrillic = mkline("смотри https://пример.рф/провижинг тут")
    assert not list(lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS)).scan_line(cyrillic))


def test_findings_sorted_by_column(tmp_path):
    md = tmp_path / "sorted.md"
    md.write_text("тут " + EM + " и провижинг и еще " + EM + " хвост\n", encoding="utf-8")

    findings = lint.scan(md, rules())
    cols = [f.col for f in findings]

    assert cols == sorted(cols)


# --- Репро из red-team отчета, раунд 2 ---


def test_backtick_does_not_pair_across_heading(tmp_path):
    md = tmp_path / "r2f1.md"
    md.write_text("текст ` конец\n# провижинг ` заголовок\n", encoding="utf-8")

    assert any(f.rule_id == "banned-term" for f in lint.scan(md, rules()))


def test_backtick_does_not_pair_across_list_items(tmp_path):
    md = tmp_path / "r2f2.md"
    md.write_text("- пункт ` один\n- провижинг ` два\n", encoding="utf-8")

    assert any(f.rule_id == "banned-term" for f in lint.scan(md, rules()))


def test_backtick_does_not_pair_across_table_cells(tmp_path):
    md = tmp_path / "r2f2b.md"
    md.write_text("| a ` b | c |\n| --- | --- |\n| провижинг ` d | e |\n", encoding="utf-8")

    assert any(f.rule_id == "banned-term" for f in lint.scan(md, rules()))


def test_single_source_of_truth_for_backtick_spans(tmp_path):
    # round-2 #4: построчная и joined-модели больше не расходятся.
    md = tmp_path / "r2f3.md"
    md.write_text("a ` b\nc ` провижинг ` e ` f\n", encoding="utf-8")

    assert any(f.rule_id == "banned-term" for f in lint.scan(md, rules()))


def test_glossary_style_refdef_is_prose(tmp_path):
    # round-2 #6: «[термин]: описание» без валидного title - проза, не refdef.
    md = tmp_path / "r2f5.md"
    md.write_text("[провижинг]: это калька, не термин.\n", encoding="utf-8")

    assert any(f.rule_id == "banned-term" for f in lint.scan(md, rules()))


def test_real_refdef_line_fully_masked(tmp_path):
    # round-2 #10: настоящий refdef (включая title) не сканируется.
    md = tmp_path / "r2f5b.md"
    md.write_text('[id]: https://a.b/c "провижинг в тайтле"\n\nссылка [x][id]\n', encoding="utf-8")

    assert not [f for f in lint.scan(md, rules()) if f.rule_id == "banned-term"]


def test_vertical_tab_line_does_not_break_code_span(tmp_path):
    # round-2 #2: \v продолжает абзац по CommonMark, спан через него сохранен.
    vt = chr(0x0B)
    md = tmp_path / "r2f16.md"
    original = "a `один " + EM + " два  x\n" + vt + "\nтри` b\n"
    md.write_text(original, encoding="utf-8")

    lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == original


def test_prefixed_verb_dispatch_flagged():
    # round-2 #12: приставочная форма «задиспетчить».
    rule = lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS))

    assert list(rule.scan_line(mkline("Мы задиспетчили событие.")))
    assert not list(rule.scan_line(mkline("диспетчер направил заявку")))


# --- R3: правило ё ---


def test_yo_flagged_and_fixable():
    hits = list(lint.YoRule(frozenset()).scan_line(mkline("ещё раз")))

    assert len(hits) == 1
    assert hits[0].matched == "ё"
    assert hits[0].replacement == "е"


def test_yo_uppercase_preserves_case():
    hits = list(lint.YoRule(frozenset()).scan_line(mkline("Ёлка стоит")))

    assert hits[0].replacement == "Е"


def test_yo_in_code_span_ignored():
    assert not list(lint.YoRule(frozenset()).scan_line(mkline("`ещё` код")))


def test_yo_fix_replaces_in_file(tmp_path):
    md = tmp_path / "yo.md"
    md.write_text("ещё раз\n", encoding="utf-8")

    remaining = lint.fix_file(md, rules())

    assert md.read_text(encoding="utf-8") == "еще раз\n"
    assert not remaining


def test_yo_keep_word_reported_not_fixed(tmp_path):
    md = tmp_path / "keep.md"
    md.write_text("всё и ещё\n", encoding="utf-8")
    kept = lint.build_rules(lint.load_terms(lint.DEFAULT_TERMS), frozenset({"всё"}))

    remaining = lint.fix_file(md, kept)

    # «ещё» починено, «всё» из yo_keep сохранено, но остается находкой (report-only).
    assert md.read_text(encoding="utf-8") == "всё и еще\n"
    assert any(f.rule_id == "yo" and not f.fixable for f in remaining)


def test_yo_keep_is_case_insensitive():
    hits = list(lint.YoRule(frozenset({"всё"})).scan_line(mkline("Всё готово")))

    assert hits[0].replacement is None


def test_load_yo_keep_default_empty():
    assert lint.load_yo_keep(lint.DEFAULT_TERMS) == frozenset()


def test_load_yo_keep_reads_words(tmp_path):
    toml = tmp_path / "k.toml"
    toml.write_text(
        'yo_keep = ["Всё", "узнаём"]\n\n[[term]]\nid = "x"\npatterns = ["a"]\nreplacement = "y"\n',
        encoding="utf-8",
    )

    assert lint.load_yo_keep(toml) == frozenset({"всё", "узнаём"})


def test_load_yo_keep_bad_type_raises(tmp_path):
    toml = tmp_path / "badyo.toml"
    toml.write_text('yo_keep = "нет"\n', encoding="utf-8")

    with pytest.raises(ValueError, match="yo_keep"):
        lint.load_yo_keep(toml)


def test_main_yo_returns_one(tmp_path):
    md = tmp_path / "y.md"
    md.write_text("ещё раз\n", encoding="utf-8")

    assert lint.main([str(md)]) == 1
