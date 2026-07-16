"""Тесты линтера Tier 1 (`lint_banned_terms.py`).

Запуск: uv run --with pytest --with markdown-it-py pytest test_lint_banned_terms.py -v
"""

from __future__ import annotations

import pytest

import lint_banned_terms as lint

EM = chr(0x2014)  # длинное тире, строим без литерала
EN = chr(0x2013)  # короткое тире


def rules() -> list[lint.Rule]:
    return lint.build_rules(lint.load_terms(lint.DEFAULT_TERMS))


def mkline(raw: str, *, is_table_row: bool = False) -> lint.Line:
    spans = lint.prose_spans(raw)
    return lint.Line(raw=raw, masked=lint.blank_spans(raw, spans), spans=spans, is_table_row=is_table_row)


def test_prose_spans_marks_inline_code_and_url():
    line = "код `x  y` и http://a.b/c текст"
    spans = lint.prose_spans(line)

    assert any(line[s:e] == "`x  y`" for s, e in spans)
    assert any(line[s:e].startswith("http") for s, e in spans)


def test_blank_spans_preserves_length():
    line = "a `code` b"
    masked = lint.blank_spans(line, lint.prose_spans(line))

    assert len(masked) == len(line)
    assert "code" not in masked


def test_term_rule_reports_stem_without_fix():
    hits = list(lint.TermRule(lint.load_terms(lint.DEFAULT_TERMS)).scan_line(mkline("сделали провижинг")))

    assert hits
    assert hits[0].replacement is None
    assert "провижинг" in hits[0].matched


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


def test_main_clean_returns_zero(tmp_path):
    md = tmp_path / "c.md"
    md.write_text("Чистая проза.\n", encoding="utf-8")

    assert lint.main([str(md)]) == 0


def test_main_findings_returns_one(tmp_path):
    md = tmp_path / "d.md"
    md.write_text("Мы сделали провижинг.\n", encoding="utf-8")

    assert lint.main([str(md)]) == 1
