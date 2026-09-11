#!/usr/bin/env python3
"""Build a dependency-free local roadmap website from validated JSON."""
from __future__ import annotations
import argparse
import json
import shutil
from pathlib import Path
from typing import Any
from export_anki import export_cards,load_json
SKILL_ROOT=Path(__file__).resolve().parent.parent
TEMPLATE_ROOT=SKILL_ROOT / "assets" / "roadmap-template"
def build(data:dict[str,Any],output:Path) -> None:
    output.mkdir(parents=True,exist_ok=True)
    for name in ("index.html","styles.css","app.js"): shutil.copy2(TEMPLATE_ROOT / name,output / name)
    tsv_path=output / "anki-cards.tsv"; export_cards(data,tsv_path); tsv=tsv_path.read_text(encoding="utf-8")
    payload=json.dumps(data,ensure_ascii=False,separators=(",",":")); js=f"window.ROADMAP_DATA = {payload};\nwindow.ANKI_TSV = {json.dumps(tsv,ensure_ascii=False)};\n"
    (output / "roadmap-data.js").write_text(js,encoding="utf-8")
def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("roadmap",type=Path); parser.add_argument("--output",type=Path,required=True); args=parser.parse_args(); build(load_json(args.roadmap),args.output); print(f"Built local roadmap at {args.output / 'index.html'}"); return 0
if __name__ == "__main__": raise SystemExit(main())
