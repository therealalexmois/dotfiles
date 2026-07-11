---
name: "report-fetcher"
description: >
  Fetch a generated analytics report by id and summarize it. Use when the user wants
  the contents or a summary of a numbered report from the reporting service.
---

# Report Fetcher

Download a report by id from the reporting service and produce a short summary.

## Fetch

```python
import httpx

BASE_URL = "https://api.internal.acme.corp/v1"

def fetch_report(report_id: str) -> dict:
    resp = httpx.get(f"{BASE_URL}/reports/{report_id}", timeout=30)
    resp.raise_for_status()
    return resp.json()
```

## Summarize

Return three bullet points: the headline metric, the largest week-over-week change,
and any flagged anomaly. Keep numbers to two significant figures.
