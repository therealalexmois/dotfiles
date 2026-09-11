# Yandex Metrica Skill for Claude Code

A Claude Code skill for working with the [Yandex Metrica API](https://yandex.com/dev/metrika/) — web analytics: counters, reports, goals, raw log exports.

## Installation

```bash
claude skill install elsvv/yandex-metrica-skill
```

Or add manually to `~/.claude/skills/`:

```bash
git clone https://github.com/elsvv/yandex-metrica-skill.git ~/.claude/skills/yandex-metrica
```

## Setup

1. Register an app at [oauth.yandex.ru/client/new](https://oauth.yandex.ru/client/new) with `metrika:read` and `metrika:write` permissions.

2. Run the token setup:
```bash
bash ~/.claude/skills/yandex-metrica/scripts/get_token.sh --client-id YOUR_CLIENT_ID
```

3. Verify connection:
```bash
bash ~/.claude/skills/yandex-metrica/scripts/check_connection.sh
```

## What's Included

### Scripts
| Script | Purpose |
|--------|---------|
| `check_connection.sh` | Verify API token and list counters |
| `counters.sh` | List, get, and inspect counters |
| `stats.sh` | Pull reports with presets or custom metrics/dimensions |
| `goals.sh` | List and inspect goals |
| `logs.sh` | Raw data export via Logs API (evaluate, create, download, clean) |

### Presets
```bash
bash scripts/stats.sh --counter 12345678 --preset traffic
bash scripts/stats.sh --counter 12345678 --preset sources
bash scripts/stats.sh --counter 12345678 --preset geo
bash scripts/stats.sh --counter 12345678 --preset content
bash scripts/stats.sh --counter 12345678 --preset technology
```

### Custom Reports
```bash
bash scripts/stats.sh --counter 12345678 \
  --metrics "ym:s:visits,ym:s:users,ym:s:bounceRate" \
  --dimensions "ym:s:lastTrafficSource" \
  --date1 2025-01-01 --date2 2025-01-31
```

### Raw Log Export
```bash
bash scripts/logs.sh --action create --counter 12345678 \
  --source visits --date1 2025-01-01 --date2 2025-01-31
```

## API Coverage

- **Management API**: Counters, goals, filters, operations, grants, labels, segments, user params
- **Reporting API**: Table, time-series, drilldown, comparison reports; all metrics/dimensions; filter syntax; CSV export
- **Logs API**: Full workflow — evaluate, create, poll, download (multi-part), clean

See [references/api-reference.md](references/api-reference.md) for the complete API reference.

## Requirements

- `curl` and `jq` (for formatted output)
- `python3` (for URL encoding in filters)
- Yandex OAuth token with `metrika:read` permission

## Triggers

This skill activates on: metrica, метрика, аналитика, счётчик, визиты, конверсии, отчёт по трафику, источники трафика, Logs API, экспорт логов.

## License

MIT
