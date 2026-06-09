# Audit checklist

Detection cues per category, the example-vs-real heuristic, and the risk rubric.
Read this when scanning a skill so you know what each category actually looks like
in the wild and how to score it.

## The example-vs-real heuristic

The hardest judgment is whether a literal is a live default the skill acts on, or an
illustration. Treat a value as a **real target** (and therefore a finding) when:

- it appears inside a command, API call, or code path the skill executes;
- it is used as a default when an argument is missing;
- it is presented as "the" channel/namespace/host, not "for example".

Treat it as an **example** (not a finding, at most Minor "label it") when:

- it sits under an "Example:" / "for instance" framing;
- it is obviously a placeholder (`<your-namespace>`, `example.com`, `C0EXAMPLE`);
- it is in a sample block demonstrating format, not driving behavior.

When the same value is both documented as an example and used as a live default,
the live-default use wins, report it.

## Categories and detection cues

| Category | Cues to look for | Typical risk |
| --- | --- | --- |
| Messenger bot/user/channel/thread IDs | `bot_...`, `C0...`/`U0...` style IDs, long numeric thread/root IDs, `thread_ts`, `root_id` | Major (thread IDs are per-run, treat static ones as wrong) |
| Kubernetes namespace | `-n <name>`, `--namespace <name>`, `namespace:` in YAML, repeated env-suffixed names (`*-prod`, `*-stage`) | Major; Critical if tied to destructive verbs |
| Kubernetes context/cluster | `--context`, `kubectl config use-context`, cluster ARNs/names | Major |
| Deployment/service names | `deploy/<name>`, `svc/<name>` baked into commands | Major when project-specific |
| Environment names/aliases | `prod`, `production`, `stage`, `staging`, `dev`, `qa` used as live targets | Critical if a prod default or silent fallback; else Major |
| URLs / endpoints / hosts / ports | `http(s)://`, `*.internal.*`, `:8080`, bare hostnames in calls | Major |
| Absolute local paths | `/Users/...`, `/home/...`, `/opt/...`, `C:\...` | Major (machine-specific) |
| Org-specific identifiers | company domains, internal product codenames as live values | Major |
| Project/repo/board IDs, Jira keys | numeric project/repo IDs, `PROJ-` keys, board IDs | Major |
| Secrets / tokens / keys | `token`, `api_key`, `secret`, `Bearer ...`, `AKIA...`, long base64/hex blobs, `xox...` | Critical, always |
| Model / provider / inference endpoint | hardcoded model IDs or provider hosts where they should be configurable | Major if it should be configurable; Minor/leave if contractual |
| Feature-flag / release identifiers | flag names, release tags, version literals driving behavior | Major when they change per release |
| Project-specific filenames | a specific config/report filename assumed universal | Minor-Major |
| Magic constants | unexplained numeric thresholds, timeouts, limits controlling behavior | Minor (Major if changing infra breaks them) |
| Tool-installed assumption | calls `kubectl`/`gh`/`jq`/etc. with no preflight check | Minor |
| Current branch/namespace/service/cluster assumption | "the current namespace", "this cluster", implicit context | Major (silent wrong-target risk) |

## Risk rubric

Apply consistently so the report is comparable across skills.

**Critical**
- Any secret, credential, token, or API key in any shipped file.
- A default that targets production, or a silent fallback between prod and non-prod.
- A destructive command (`delete`, `scale --replicas=0`, `rollout`, `drop`, `rm -rf`,
  force-push) wired to a hardcoded target.

**Major**
- A physical identifier that breaks the skill or sends it at the wrong target when it
  changes: bot/channel/thread IDs, namespaces, clusters/contexts, URLs/hosts,
  project/repo/board IDs, Jira keys, absolute paths, configurable-but-fixed model names.

**Minor**
- Maintainability and clarity: unlabeled example values, weak names, unexplained magic
  constants, missing "how to update this value" docs, missing preflight tool checks.

When a value sits between two levels, choose the higher and state the reason in the
Problem field.

## What NOT to flag

Keeping the report trustworthy means not crying wolf. Do not raise findings for:

- Stable contract values the skill exists to enforce (the commit-type set, a fixed
  output template, a standard algorithm constant).
- Clearly labeled placeholders and examples that never drive behavior.
- Language/format keywords, standard library names, well-known protocol constants.
- Values the user has already extracted (argument names, documented env vars,
  config keys), note them as "already parameterized" if relevant, not as problems.

If everything in a skill is clean, say so plainly. A short "no findings" report is a
valid and useful result.
