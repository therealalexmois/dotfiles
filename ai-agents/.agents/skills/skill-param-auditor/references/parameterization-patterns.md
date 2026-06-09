# Parameterization patterns

How to move a brittle value out of `SKILL.md`, and how to pick the cheapest option
that still works. Read this when you have a confirmed finding and need to recommend
a concrete extraction strategy.

## Table of contents

- [Choosing a strategy](#choosing-a-strategy)
- [Strategy reference](#strategy-reference)
- [Fail-closed patterns](#fail-closed-patterns)
- [Worked example 1: messenger bot/thread IDs](#worked-example-1-messenger-botthread-ids)
- [Worked example 2: release-manager Kubernetes namespaces](#worked-example-2-release-manager-kubernetes-namespaces)
- [Worked example 3: hardcoded API URL](#worked-example-3-hardcoded-api-url)
- [Worked example 4: a value that should stay hardcoded](#worked-example-4-a-value-that-should-stay-hardcoded)

## Choosing a strategy

Walk down this list and stop at the first one that fits. The goal is the simplest
mechanism that survives change, not the most powerful.

1. **Does the caller already know the value at invocation time?** Use an
   **argument**. One value -> positional. Several optional -> named. This is the
   default and the cheapest; reach for it before anything heavier.
2. **Is it sensitive (token, key, credential)?** Use a **secret** via env var or a
   secret manager. Never a committed file, never inline. This rule wins over every
   other consideration.
3. **Is it stable per environment but differs across repos/machines/users?** Use
   **config**, local project config when it belongs to the repo, user-level config
   when it follows the person.
4. **Does the surrounding shell or CI already export it?** Read the **env var**.
5. **Can a small deterministic lookup produce it?** Use a **resolver script** or
   **repository metadata discovery** (git remote, CI-provided project id).
6. **Does the underlying infra change often?** Use **runtime discovery**, a k8s
   label selector instead of a namespace literal, a service lookup instead of a host.
7. **Is there a reusable, operationally important integration boundary?** Use an
   **MCP/tool call**. Do not introduce this abstraction just to avoid a literal; the
   boundary has to earn its keep.
8. **Is it actually illustrative?** Keep it as a **documented example**, clearly
   labeled so no one mistakes it for a live default.
9. **Is it a stable part of the skill contract?** **Leave it as-is.**

KISS/YAGNI throughout: do not propose a config file when one argument does the job,
and do not propose discovery when the value never changes.

## Strategy reference

| Strategy | Mechanism | Cost | Watch out for |
| --- | --- | --- | --- |
| Positional argument | Caller passes it in the invocation | Lowest | Document the order and meaning |
| Named argument | `--key value` style | Low | Define defaults explicitly, no silent prod default |
| Local project config | `./.skillrc`, repo `config.toml`, etc. | Low-medium | Must not contain secrets; document keys |
| User-level config | `~/.config/<tool>/...` | Medium | Per-user; document where it lives and how to set it |
| Environment variable | Read from process env | Low | Fail closed if unset; never print it if sensitive |
| Secret manager / env secret | Vault, CI secret, env var | Medium | Never log, never commit, never echo |
| Resolver script | Deterministic lookup at run time | Medium | Keep it side-effect free; fail loudly if it cannot resolve |
| Runtime discovery | Query infra (k8s selectors, DNS, service registry) | Medium-high | Scope the query; ambiguous match -> stop and ask |
| Repo metadata discovery | Read git remote, CI vars, manifest | Low-medium | Handle the "not in a repo / no CI" case |
| MCP / tool call | Call an existing integration | Varies | Only if the boundary is reusable/important |
| Documented example | Label as example, do not execute against it | Lowest | Make "example only" unmistakable |
| Leave as-is | Keep the literal | Zero | Justify why it is part of the contract |

## Fail-closed patterns

A brittle skill that guesses is worse than one that stops. When a value cannot be
resolved:

- **Stop and report.** Do not substitute a default that could hit the wrong target.
- **Never fall back from prod to non-prod or the reverse silently.** A
  `namespace = namespace or "prod"` default is a Critical finding, an operator
  forgetting the argument should fail, not deploy to prod.
- **Never guess identity.** Do not pick "the first namespace", "the only bot", "the
  current cluster" unless the skill explicitly and safely scopes that choice.
- **Make ambiguity loud.** Two matching namespaces, no config key, an unset env var:
  surface it as an Open question, do not paper over it.

## Worked example 1: messenger bot/thread IDs

**Before** (in `SKILL.md`):

```markdown
Post the release summary by calling the messenger API with bot ID `bot_8f31a` to
channel `C0193ALERTS`, in thread `1718000000.001900`.
```

**Problem.** The bot ID and channel ID are physical identifiers tied to one
workspace; they change when the bot is recreated or the channel is renamed/rotated.
The thread ID is even shorter-lived, it identifies one specific message and is
meaningless on the next run. Hardcoding it means the skill posts into a stale thread
or fails outright. Risk: Major (bot/channel IDs), and the thread ID is essentially a
per-run value that must never be static.

**After.**

- Thread/root ID -> **invocation argument** (`--thread <id>`), or omit to start a new
  thread. It is a per-run value by nature.
- Bot identity -> **config or env** (`MESSENGER_BOT` / a logical alias resolved to the
  physical ID at run time). Prefer referring to the bot by a logical name the skill
  maps, not the raw `bot_8f31a`.
- Channel -> **named argument or config alias** (`--channel release-alerts`), resolved
  to the channel ID via the messenger tool, not pasted as `C0193ALERTS`.

`SKILL.md` keeps the stable part: "post a release summary to the configured release
channel, threading under the provided root if given". The volatile IDs leave the file.

## Worked example 2: release-manager Kubernetes namespaces

**Before** (in `SKILL.md`):

```markdown
Roll out the new image:
`kubectl -n payments-prod set image deploy/api api=$IMAGE && kubectl -n payments-prod rollout status deploy/api`
If anything looks wrong, scale it down: `kubectl -n payments-prod scale deploy/api --replicas=0`.
```

**Problem.** `payments-prod` is baked into commands that change and can take down a
running service. The namespace differs per environment and per team; a second team
copying this skill silently operates on the wrong namespace, or worse, on prod.
Destructive commands (`set image`, `scale --replicas=0`) wired to a hardcoded prod
namespace is a Critical finding.

**After.**

- Namespace -> **required argument** with no default (`--namespace <ns>`). Missing
  argument fails closed, never defaults to prod.
- For fleets that change often, **runtime discovery**: select by label
  (`-l app=api,env=<env>`) where `<env>` is an argument, instead of naming the
  namespace literally.
- Keep the destructive step behind an explicit confirmation the skill already
  documents, so a fat-fingered target cannot scale prod to zero unprompted.

`SKILL.md` keeps the workflow ("set the image, watch rollout, on failure scale down
after confirmation") and the safety rule; the namespace and env become inputs.

## Worked example 3: hardcoded API URL

**Before** (in a script the skill ships):

```python
BASE_URL = "https://api.internal.acme.corp/v1"
resp = httpx.get(f"{BASE_URL}/reports/{report_id}")
```

**Problem.** The host is environment-specific (staging vs prod vs a colleague's local
gateway) and org-specific. A new environment or a renamed gateway breaks every run.
Risk: Major.

**After.**

- Base URL -> **environment variable** with no silent default:
  `BASE_URL = os.environ["REPORTS_API_BASE_URL"]`. If it is unset, fail with a clear
  message rather than reaching for a baked-in host.
- If several deployments are common, allow a **named argument** that overrides the env
  var for one run.
- Document the variable and an example value in the skill, clearly labeled as an
  example, not a live default.

## Worked example 4: a value that should stay hardcoded

**Before** (in a commit-message skill's `SKILL.md`):

```markdown
Use only these Conventional Commits types:
`feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`.
```

**Why this is NOT a finding.** This set is the skill's contract, the whole point of
the skill is to enforce exactly these types. It is not environment-specific, not
secret, and does not change when infra changes; if it changed, that would be a
deliberate redefinition of the skill, not silent rot. Making it "configurable" would
add a knob nobody needs and weaken the guarantee the skill exists to provide
(KISS/YAGNI). 

Report it, if at all, only as an informational note ("intentional contract value,
leave as-is"), never as a Major or Critical issue. The discipline of *not* flagging
stable contract values is what keeps the audit trustworthy: an auditor that flags
everything teaches people to ignore it.
