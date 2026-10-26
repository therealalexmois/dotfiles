---
tags: [skill-creator]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

покажи схемой, как идет один запрос Proteus: Proteus -> agent-runs router -> CallerAppResolverPort.resolve_caller_app_id -> Introspector (кеш 300с) -> StreamAgentRunner.run -> LlmAccessPort.token_for -> ProductEvents handle_start, который снова зовет resolve_caller_app_id и получает cache hit. хочу понять порядок вызовов
