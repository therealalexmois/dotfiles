# Complexity: the overcomplication lens

Distilled from the `karpathy-coder` skill, which remains the standalone source with its detectors, anti-pattern catalog, and pre-commit hook. Use this lens during implementation review to catch the four LLM-specific pitfalls. For a deep complexity pass, defer to `karpathy-coder`.

LLMs reliably overcomplicate: they bloat abstractions, add unrequested flexibility, and leave dead code. Review against that bias.

## 1. Hidden assumptions

- Were assumptions made silently where the requirements were ambiguous?
- Are there multiple valid interpretations the change picked between without surfacing it?
- Flag a finding when the diff depends on an unstated assumption about a contract, input, or dependency.

## 2. Simplicity first

- Any feature beyond what was asked? Any speculative configurability or flexibility?
- Any abstraction wrapping single-use code?
- Error handling for impossible scenarios?
- Test: would a senior engineer call this overcomplicated? If 200 lines could be 50, that is a `Minor` or `Major` depending on the maintenance cost.

## 3. Surgical changes

- Does every changed line trace to the stated goal?
- Drive-by reformatting, renamed-for-taste symbols, refactors of untouched code, or deleted pre-existing dead code that the task did not ask to remove - all are scope creep. Flag them.
- Unused imports/variables/functions left behind by the change itself are a real finding.

## 4. Goal-driven execution

- Is "done" defined by a verifiable check, or by vibes? A change described as "fixed" or "validated" without a test that proves it is a `NO_EVIDENCE` or `Major` finding (see the Evidence Gate in `review-workflow.md`).

## Calibration

These principles bias toward caution. Relax them for trivial changes (typo fixes, obvious one-liners). They matter most on non-trivial implementations, code the author does not fully understand, and multi-step tasks with unclear requirements.
