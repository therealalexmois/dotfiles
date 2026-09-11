#!/usr/bin/env python3
"""Check HTTP availability of every selected roadmap source."""
from __future__ import annotations
import argparse,json,ssl,sys,urllib.error,urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any
def source_urls(data:dict[str,Any])->list[str]:
    urls:set[str]=set()
    for node in data.get("nodes",[]):
        for sources in node.get("sources",{}).values():
            for source in sources:
                if source.get("url"): urls.add(str(source["url"]))
    return sorted(urls)
def check(url:str,timeout:float)->tuple[str,bool,str]:
    headers={"User-Agent":"create-learning-roadmap-link-checker/1.0"}; context=ssl.create_default_context()
    for method in ("HEAD","GET"):
        request=urllib.request.Request(url,headers=headers,method=method)
        try:
            with urllib.request.urlopen(request,timeout=timeout,context=context) as response:
                code=response.getcode(); return url,200 <= code < 400,str(code)
        except urllib.error.HTTPError as exc:
            if method == "HEAD" and exc.code in {403,405,501}: continue
            return url,False,f"HTTP {exc.code}"
        except (urllib.error.URLError,TimeoutError,ValueError) as exc:
            if method == "HEAD": continue
            return url,False,str(exc)
    return url,False,"unreachable"
def main()->int:
    parser=argparse.ArgumentParser(); parser.add_argument("roadmap",type=Path); parser.add_argument("--timeout",type=float,default=15.0); parser.add_argument("--workers",type=int,default=8); args=parser.parse_args()
    with args.roadmap.open(encoding="utf-8") as file: data=json.load(file)
    urls=source_urls(data)
    with ThreadPoolExecutor(max_workers=args.workers) as pool: results=list(pool.map(lambda url:check(url,args.timeout),urls))
    failed=False
    for url,ok,detail in results: print(f"{'OK' if ok else 'FAIL'} {detail} {url}"); failed=failed or not ok
    if not urls: print("FAIL no source URLs found",file=sys.stderr); return 1
    return 1 if failed else 0
if __name__ == "__main__": raise SystemExit(main())
