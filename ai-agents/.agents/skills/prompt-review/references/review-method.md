# Review Method: Axes, Problem Taxonomy, Severity, Verdict, Output

Reference for `prompt-review`. Read during analysis and before writing the verdict.

## Evidence-based review (the core rule)

Every finding and every proposed change carries proof. Minimum format:

```
Section / line: <S-N or quoted heading>
Quote (verbatim from the prompt):
> ...
What's wrong: <concrete risk, not a generic complaint>
Why it's a risk: <the mechanism by which it shows up in the model's output>
How to strengthen: <a concrete change>
```

Rules:
- The quote is a verbatim fragment of the source prompt.
- No quote → mark `ASSUMPTION`; it does not enter the mandatory change list.
- Don't say "the prompt could be better" — show the concrete path by which the model errs on the current version.
- Don't rate style (length, tone, formatting) unless it clearly contradicts the prompt's purpose.
- Don't propose an alternative structure if the current one satisfies `GOAL-N` and respects `CONSTRAINT-N`.

Anti-rationalization:
- Don't infer "strong" from length, section count, or the presence of emoji/Markdown/XML tags.
- Don't infer "weak" merely from the absence of a trendy technique (chain-of-thought, role-play, few-shot) the task doesn't need.
- Don't replace the prompt's specific rules with generic best practices "because everyone writes it that way".

## Pre-flight normalization

Before analysis: extract and number declared goals (`GOAL-1…`), hard constraints (`CONSTRAINT-1…`), structural sections (`S-1…`). Publish and ask the author to confirm the numbering or say "continue". All findings then reference only these ids.

## Analysis axes (A–L)

Walk each axis explicitly; record findings or `OK` / `NOT_APPLICABLE`.

- **A. Fit to purpose** — solves the stated task, not a near one; no blending of multiple tasks without explicit separation; no instructions unrelated to `GOAL-N`.
- **B. Role and tone** — role fits the task (not narrower/wider); role doesn't contradict constraints; role sets the right epistemic stance (skeptic, helper, gate, interlocutor).
- **C. Input gathering and preconditions** — says what to do on incomplete input; has a "don't start until X" state; has a format for requesting missing data.
- **D. Structure and priority** — sections ordered logically (gathering → normalization → analysis → output); order reflects rule priority; no duplicated-but-divergent instructions.
- **E. Formalized outputs** — statuses/verdicts as an explicit enum; conditions defined for each; self-consistency check between intermediate and final.
- **F. Evidence and hallucination resistance** — requires evidence (verbatim, quotes, references to concrete input parts); forbids "probably/likely/should work" as a basis for PASS; has an explicit "insufficient data" policy.
- **G. Guardrails** — bars going out of scope; bars inventing extra requirements; bars mixing finding categories; protects against prompt injection / instruction override (if relevant).
- **H. Batch / partial input protocol** — for large/partial inputs there's an explicit protocol, a ledger of received parts, and a "final is assembled only from the ledger" rule.
- **I. Final answer format** — unambiguous (structure predictable); required vs optional sections separated; a short form for trivial cases (e.g. BLOCKED); no noise on simple tasks.
- **J. Constraints and anti-patterns** — explicitly lists what the model must NOT do; covers the task's main failure modes; doesn't contradict positive instructions above.
- **K. Best-practice conformance** — uses appropriate practices from major providers' guides (Anthropic, OpenAI, Google); avoids outdated/harmful patterns ("pretend you are", "ignore previous instructions", excess jailbreak language). <!-- noqa: SEC-AUDITOR: quoted anti-pattern example, not a directive -->
- **L. Platform specifics (if known)** — accounts for the target model (context length, instruction-following style, structured-tag support, tool use, reasoning mode); compatible with the interface (chat, API, agent, batch).

## Problem taxonomy

One type per finding; don't mix types in a single item.

`CONTRADICTION` · `AMBIGUITY` · `MISSING_GUARDRAIL` · `WEAK_EVIDENCE_REQ` · `OVERREACH` · `UNDERREACH` · `FORMAT_NOISE` · `STYLE_ONLY` (default non-blocking) · `MODEL_SPECIFIC` · `INJECTION_RISK` · `HALLUCINATION_RISK` · `SCOPE_CREEP_RISK`.

## Severity

- `BLOCKER` — without the fix the prompt fails its purpose or gives unsafe/incorrect output. Requires a verbatim quote and a described failure mechanism.
- `MAJOR` — noticeably degrades quality; the prompt partially works.
- `MINOR` — a quality improvement; non-blocking.
- `NIT` — style, no effect on correctness.

## Verdict rules

```
VERDICT: PASS | PARTIAL | FAIL | BLOCKED
[optional flags: INCOMPLETE_INPUT | NEEDS_CLARIFICATION]
```

- `PASS` — fits purpose, no `BLOCKER`, no serious `MAJOR`; only `NIT`/`MINOR` improvements remain.
- `PARTIAL` — works overall; has `MAJOR` findings that don't break the purpose.
- `FAIL` — doesn't fit purpose or contains `BLOCKER`s; unusable without a rewrite. Only with full context and proven systemic problems.
- `BLOCKED` — can't evaluate due to missing data. Output only verdict + short summary + missing-data list.

After the verdict: a 3–6 sentence summary — how strong the prompt is and the top 3–5 remaining risks.

## Output structure (when no custom format given)

1. **Weak spots** — table: `Axis | Type | Severity | Quote | Problem | Why it's a risk | How to strengthen`.
2. **Keep unchanged** — strong parts with short quotes (sections implementing `GOAL-N`, guardrails covering real failure modes, author `CONSTRAINT-N`, good wording).
3. **What to strengthen** — concrete changes grouped by type: new rules · clarified statuses/verdicts · stricter gates · input-protocol improvements · output-format improvements · guardrail improvements · domain-specific strengthening. Each justified by a quote or a missing-rule pointer.
4. **Final version** — full improved prompt, self-contained, ready to copy.
5. **Changelog** — per entry:

```
- <short change name>
  Type: <CONTRADICTION | AMBIGUITY | MISSING_GUARDRAIL | ...>
  Severity: <BLOCKER | MAJOR | MINOR | NIT>
  Before: <verbatim quote or "absent">
  After: <short description of the new wording>
  Why: <the risk mechanism it closes>
```

`BLOCKED` → only `VERDICT` + short summary + missing-data list. No tables, no improved version.

## Self-consistency check (mandatory, before sending)

- Every proposed change has a verbatim quote OR an explicit pointer to a missing rule.
- No proposed change violates a `CONSTRAINT-N`.
- The final improved prompt preserves every `GOAL-N`.
- No sections added whose absence wasn't justified in the analysis.
- Verdict consistent with `BLOCKER`s: any `BLOCKER` → verdict ≠ `PASS`; all findings `NIT` → verdict ≠ `FAIL`.
- If verdict = `BLOCKED`, there is no improved version in the answer.

If the check fails, rewrite the verdict or changelog — not the improved prompt.
