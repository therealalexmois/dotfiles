---
name: distill-thoughts
description: Distill raw user-authored thoughts and text transcripts into concise, coherent text while preserving every material claim, qualifier, uncertainty, tone, and intended meaning. Use when the user explicitly asks to distill, formulate, organize, clean up, or turn rambling, repetitive, or disjointed thoughts or voice-to-text transcripts into clear text. Do not use for generic proofreading, creative rewriting, summarizing external source material, or expanding or strengthening ideas.
---

# Distill Thoughts

Transform raw thoughts into the shortest clear text that preserves their full material meaning.

## Workflow

1. Identify the intended message, material claims, conditions, qualifications, uncertainties, and independent topics in the source.
2. Determine the natural form from the content: for example, a problem statement, message, idea, decision, explanation, or note. Ask the user only if choosing the form would materially change the result.
3. Check for contradictions or ambiguities that permit materially different interpretations. If one blocks faithful rewriting, ask one focused clarification question and stop. Preserve non-critical uncertainty in the result.
4. Rewrite the source:
   - remove filler words, false starts, self-corrections, repetitions, and irrelevant digressions;
   - merge repeated fragments without dropping unique details;
   - reorder fragments when needed for coherence, without inventing causal or logical connections;
   - separate independent thoughts into distinct semantic blocks;
   - preserve the source language, tone, point of view, and degree of formality;
   - retain material examples, constraints, reservations, and confidence levels;
   - correct only unambiguous transcription, spelling, and grammar errors;
   - compress as far as possible without losing meaning.
5. Verify that every statement in the result is traceable to the source and that every material source idea remains represented.

## Guardrails

- Do not add facts, arguments, conclusions, intentions, or context.
- Do not strengthen, soften, or resolve the author's position.
- Do not infer missing reasoning or silently choose among materially different interpretations.
- Do not turn an informal note into professional prose unless the source or requested use calls for it.
- Do not explain the editing process or list removed content.
- Do not optimize for a fixed reduction ratio; optimize for clarity and semantic fidelity.

## Output

Return only the distilled text, with no preface, commentary, change log, or analysis. Use headings or lists only when they are natural to the content. If a critical clarification is required, return only the focused question instead.
