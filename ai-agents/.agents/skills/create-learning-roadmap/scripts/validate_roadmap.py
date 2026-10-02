#!/usr/bin/env python3
"""Validate roadmap structure and graph invariants."""
from __future__ import annotations
import argparse,json,sys
from pathlib import Path
from typing import Any
from urllib.parse import urlparse
KINDS={"core","optional","deep-dive","remediation","reference"}; CARD_TYPES={"basic","cloze","comparison","mechanism","scenario","misconception","prediction"}; SOURCE_GROUPS=("foundation","deepening","reference")
def load(path:Path)->dict[str,Any]:
    with path.open(encoding="utf-8") as file: data=json.load(file)
    if not isinstance(data,dict): raise ValueError("root must be an object")
    return data
def collect_ids(items:list[Any],label:str,errors:list[str])->set[str]:
    ids:set[str]=set()
    for index,item in enumerate(items):
        if not isinstance(item,dict) or not item.get("id"): errors.append(f"{label}[{index}].id is required"); continue
        value=str(item["id"])
        if value in ids: errors.append(f"duplicate {label} id: {value}")
        ids.add(value)
    return ids
def validate_sources(value:Any,prefix:str,errors:list[str])->None:
    if not isinstance(value,dict): errors.append(f"{prefix}.sources must be an object"); return
    if not any(value.get(group) for group in SOURCE_GROUPS): errors.append(f"{prefix}.sources must contain at least one source")
    for group in SOURCE_GROUPS:
        sources=value.get(group,[])
        if not isinstance(sources,list): errors.append(f"{prefix}.sources.{group} must be an array"); continue
        for index,source in enumerate(sources):
            item=f"{prefix}.sources.{group}[{index}]"
            if not isinstance(source,dict): errors.append(f"{item} must be an object"); continue
            for field in ("title","url","type","why","level","language","verified_at"):
                if not source.get(field): errors.append(f"{item}.{field} is required")
            if urlparse(str(source.get("url",""))).scheme not in {"http","https"}: errors.append(f"{item}.url must be HTTP(S)")
def validate_practice(items:Any,prefix:str,errors:list[str])->None:
    if not isinstance(items,list): return
    for index,item in enumerate(items):
        label=f"{prefix}.practice[{index}]"
        if not isinstance(item,dict): errors.append(f"{label} must be an object"); continue
        for field in ("title","type","task","constraints","deliverable","allowed_assistance","checks"):
            if not item.get(field): errors.append(f"{label}.{field} is required")
        for field in ("constraints","checks"):
            if not isinstance(item.get(field),list): errors.append(f"{label}.{field} must be an array")
def validate_cards(items:Any,prefix:str,errors:list[str])->None:
    if not isinstance(items,list): return
    for index,item in enumerate(items):
        label=f"{prefix}.anki_cards[{index}]"
        if not isinstance(item,dict): errors.append(f"{label} must be an object"); continue
        for field in ("front","back","type","tags","source"):
            if not item.get(field): errors.append(f"{label}.{field} is required")
        if item.get("type") not in CARD_TYPES: errors.append(f"{label}.type must be one of {sorted(CARD_TYPES)}")
        if not isinstance(item.get("tags"),list): errors.append(f"{label}.tags must be an array")
def detect_cycles(graph:dict[str,list[str]],errors:list[str])->None:
    visiting:set[str]=set(); visited:set[str]=set()
    def visit(node:str,path:list[str])->None:
        if node in visiting:
            start=path.index(node) if node in path else 0; errors.append("dependency cycle: " + " -> ".join(path[start:]+[node])); return
        if node in visited:return
        visiting.add(node)
        for dependency in graph.get(node,[]):
            if dependency in graph: visit(dependency,path+[node])
        visiting.remove(node); visited.add(node)
    for node in graph: visit(node,[])
def validate(data:dict[str,Any])->list[str]:
    errors:list[str]=[]; meta=data.get("meta")
    if not isinstance(meta,dict): errors.append("meta must be an object")
    else:
        for field in ("id","title","goal","audience","generated_at","language"):
            if not meta.get(field): errors.append(f"meta.{field} is required")
    stages=data.get("stages"); nodes=data.get("nodes")
    if not isinstance(stages,list) or not stages: errors.append("stages must be a non-empty array"); stages=[]
    if not isinstance(nodes,list) or not nodes: errors.append("nodes must be a non-empty array"); nodes=[]
    stage_ids=collect_ids(stages,"stage",errors); node_ids=collect_ids(nodes,"node",errors); graph:dict[str,list[str]]={}
    node_kinds={str(node.get("id")):node.get("kind") for node in nodes if isinstance(node,dict) and node.get("id")}
    for index,stage in enumerate(stages):
        if not isinstance(stage,dict): continue
        for field in ("title","description","order"):
            if stage.get(field) is None or stage.get(field) == "": errors.append(f"stage[{index}].{field} is required")
    for node in nodes:
        if not isinstance(node,dict) or not node.get("id"): continue
        node_id=str(node["id"]); prefix=f"node[{node_id}]"
        if node.get("stage") not in stage_ids: errors.append(f"{prefix}.stage references a missing stage")
        if node.get("kind") not in KINDS: errors.append(f"{prefix}.kind must be one of {sorted(KINDS)}")
        for field in ("title","summary"):
            if not node.get(field): errors.append(f"{prefix}.{field} is required")
        for field in ("learning_outcomes","practice","completion_criteria","anki_cards"):
            if not isinstance(node.get(field),list): errors.append(f"{prefix}.{field} must be an array")
        if node.get("kind") != "reference":
            for field in ("learning_outcomes","practice","completion_criteria"):
                if not node.get(field): errors.append(f"{prefix}.{field} must not be empty")
        prerequisites=node.get("prerequisites",[])
        if not isinstance(prerequisites,list): errors.append(f"{prefix}.prerequisites must be an array"); prerequisites=[]
        if not all(isinstance(item,str) for item in prerequisites): errors.append(f"{prefix}.prerequisites entries must be strings")
        if len(prerequisites) != len(set(str(item) for item in prerequisites)): errors.append(f"{prefix}.prerequisites must not contain duplicates")
        graph[node_id]=[str(item) for item in prerequisites]
        for item in prerequisites:
            item_id=str(item)
            if item_id not in node_ids: errors.append(f"{prefix}.prerequisites references missing node {item_id}")
            if item == node_id: errors.append(f"{prefix} cannot depend on itself")
            if node.get("kind") == "core" and node_kinds.get(item_id) not in {"core","remediation"}: errors.append(f"{prefix} cannot depend on a hidden branch node {item_id}")
        validate_sources(node.get("sources"),prefix,errors); validate_practice(node.get("practice",[]),prefix,errors); validate_cards(node.get("anki_cards",[]),prefix,errors)
        selected_urls={str(source.get("url")) for group in node.get("sources",{}).values() if isinstance(group,list) for source in group if isinstance(source,dict) and source.get("url")}
        for index,card in enumerate(node.get("anki_cards",[])):
            if isinstance(card,dict) and card.get("source") not in selected_urls: errors.append(f"{prefix}.anki_cards[{index}].source must reference a selected node source")
    capstone=data.get("capstone")
    if capstone is not None:
        if not isinstance(capstone,dict): errors.append("capstone must be null or an object")
        else:
            for field in (
                "title","problem","system_to_build","functional_requirements",
                "constraints","starter_scope","deliverables","milestones",
                "acceptance_criteria",
            ):
                if not capstone.get(field): errors.append(f"capstone.{field} is required")
            for field in (
                "functional_requirements","constraints","starter_scope",
                "deliverables","milestones","acceptance_criteria",
            ):
                if not isinstance(capstone.get(field),list): errors.append(f"capstone.{field} must be an array")
            milestone_ids:set[str]=set()
            for index,milestone in enumerate(capstone.get("milestones",[])):
                label=f"capstone.milestones[{index}]"
                if not isinstance(milestone,dict): errors.append(f"{label} must be an object"); continue
                for field in ("id","title","after_stage","task","related_nodes","deliverable","checks"):
                    if not milestone.get(field): errors.append(f"{label}.{field} is required")
                milestone_id=str(milestone.get("id",""))
                if milestone_id in milestone_ids: errors.append(f"duplicate capstone milestone id: {milestone_id}")
                milestone_ids.add(milestone_id)
                if milestone.get("after_stage") not in stage_ids: errors.append(f"{label}.after_stage references a missing stage")
                related_nodes=milestone.get("related_nodes",[])
                if not isinstance(related_nodes,list): errors.append(f"{label}.related_nodes must be an array")
                else:
                    if not all(isinstance(node_id,str) for node_id in related_nodes): errors.append(f"{label}.related_nodes entries must be strings")
                    for node_id in related_nodes:
                        node_id_value=str(node_id)
                        if node_id_value not in node_ids: errors.append(f"{label}.related_nodes references missing node {node_id_value}")
                        if node_kinds.get(node_id_value) not in {"core","remediation"}: errors.append(f"{label}.related_nodes cannot make hidden branch node {node_id_value} required")
                    if milestone.get("after_stage") in stage_ids and not any(
                        isinstance(node,dict)
                        and node.get("id") in related_nodes
                        and node.get("stage") == milestone.get("after_stage")
                        for node in nodes
                    ): errors.append(f"{label}.related_nodes must include a node from after_stage")
                if not isinstance(milestone.get("checks"),list): errors.append(f"{label}.checks must be an array")
    detect_cycles(graph,errors); return errors
def main()->int:
    parser=argparse.ArgumentParser(); parser.add_argument("roadmap",type=Path); args=parser.parse_args()
    try: errors=validate(load(args.roadmap))
    except (OSError,json.JSONDecodeError,ValueError) as exc: print(f"ERROR: {exc}",file=sys.stderr); return 2
    if errors:
        for error in errors: print(f"ERROR: {error}",file=sys.stderr)
        return 1
    print("Roadmap is valid"); return 0
if __name__ == "__main__": raise SystemExit(main())
