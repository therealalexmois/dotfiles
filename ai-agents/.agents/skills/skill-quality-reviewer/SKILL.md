---
name: skill-quality-reviewer
description: Review a SKILL.md for predictability against the writing-great-skills doctrine and report findings by failure mode. Complements anthropic-skill-creator; invoke by name after drafting or editing a skill.
disable-model-invocation: true
---

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same _process_ every run, not producing the same output — is the root virtue you review for; every lever below serves it. Full definitions of the **bold terms** live in [`GLOSSARY.md`](GLOSSARY.md); consult it whenever a term's exact test matters.

This skill reviews one skill at a time. It pairs with `anthropic-skill-creator`, which drafts and improves: write there, review here.

## Get the target

The skill under review is a path to its `SKILL.md` plus any disclosed files, or a draft in the current conversation. Read the whole skill — `SKILL.md` and every file it points at — before any finding. A verdict on **progressive disclosure** or a **context pointer** needs both ends in view, so a partial read yields guesses, not findings.

## Run every pass

Each pass names the lever it applies and the **failure mode** it guards. Run all of them — a skipped pass is the failure mode you never report. For each finding, name the lever, the exact location (heading or line), and the fix: not "this could be tighter" but the specific edit.

### 1. Invocation

Read the frontmatter. Is the **description** present (**model-invoked**) or stripped (**user-invoked**)? Judge the choice: model-invocation is earned only when the agent or another skill must reach the skill on its own — otherwise it pays **context load** for nothing. If model-invoked, review the description as its own artifact: front-load the **leading word**, one trigger per **branch**, and cut identity already stated in the body. Synonyms that rename one branch are **duplication**.

### 2. Information hierarchy

Map each piece of content to its rung: **step**, in-file **reference**, or disclosed reference. Then test placement:

- Every **step** ends on a **completion criterion** — is it _checkable_ (can the agent tell done from not-done?) and, where it matters, _exhaustive_? A vague bound invites **premature completion**.
- Is in-file reference that only some **branches** need buried where **progressive disclosure** would push it down? Is a must-have target stranded behind a weakly worded **context pointer**?
- Is a concept's definition, rules, and caveats scattered where **co-location** would gather them?
- Step back: is the skill simply too long (**sprawl**) even with every line live and unique? The cure is the ladder, not rewriting.

### 3. Leading words

Hunt restatements a **leading word** would retire, in body and description alike: a triad spelled out at three sites, a description spending a sentence to gesture at one idea. Each begs to collapse into a single pretrained token (e.g. "fast, deterministic, low-overhead" → _tight_). Propose the word, not just the flag.

### 4. Pruning

Three lenses, in order:

- **Single source of truth** — does any meaning live in more than one place (**duplication**)? This is a repeated _meaning_, not a deliberately repeated **leading word**.
- **Relevance** — does every line still bear on what the skill does, or has **sediment** settled (stale, drifted, mere exposition)?
- **No-op** — sentence by sentence, does each change behaviour versus the model's default? A line can be perfectly relevant and still a no-op. When one fails, delete the whole sentence rather than trim its words.

## Diagnose and report

Collect the passes into a verdict organised by **failure mode** — **premature completion**, **duplication**, **sediment**, **sprawl**, **no-op** — because that is how the user experiences the problem. For each finding: name it, cite the location, give the fix.

Two rules keep the review honest:

- **Settle no-ops by running, not debate.** The no-op test is _model-relative_: whether a line beats the default is a question about the model, not the reader. When a no-op call is contested, the resolution is to run the skill with and without the line — flag it "verify by running," do not assert it.
- **Sharpen before you cut.** A must-have behind a weak pointer, a step that rushes — the first fix is to sharpen the wording or the **completion criterion** (local, cheap), not to restructure. Recommend splitting or inlining only when sharpening cannot work.

---

The doctrine and `GLOSSARY.md` are adapted from Matt Pocock's `writing-great-skills`
(github.com/mattpocock/skills). This skill adds the review process; the vocabulary is his.
