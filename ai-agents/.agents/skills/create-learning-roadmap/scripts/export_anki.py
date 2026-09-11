#!/usr/bin/env python3
"""Export source-linked roadmap cards to Anki-compatible TSV."""
from __future__ import annotations
import argparse
import csv
import json
from pathlib import Path
from typing import Any
FIELDS = ("front","back","type","tags","source")
def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as file: value = json.load(file)
    if not isinstance(value,dict): raise ValueError("Roadmap root must be an object")
    return value
def clean(value: object) -> str: return " ".join(str(value).split())
def export_cards(data: dict[str, Any],output: Path) -> int:
    rows:list[dict[str,str]]=[]
    for node in data.get("nodes",[]):
        for card in node.get("anki_cards",[]):
            rows.append({"front":clean(card.get("front","")),"back":clean(card.get("back","")),"type":clean(card.get("type","basic")),"tags":" ".join(clean(tag) for tag in card.get("tags",[])),"source":clean(card.get("source",""))})
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open("w",encoding="utf-8",newline="") as file:
        writer=csv.DictWriter(file,fieldnames=FIELDS,delimiter="\t",lineterminator="\n"); writer.writeheader(); writer.writerows(rows)
    return len(rows)
def main() -> int:
    parser=argparse.ArgumentParser(); parser.add_argument("roadmap",type=Path); parser.add_argument("--output",type=Path,default=Path("anki-cards.tsv")); args=parser.parse_args()
    count=export_cards(load_json(args.roadmap),args.output); print(f"Exported {count} cards to {args.output}"); return 0
if __name__ == "__main__": raise SystemExit(main())
