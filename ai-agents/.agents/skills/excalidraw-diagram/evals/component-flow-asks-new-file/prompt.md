---
tags: [skill-creator]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Нарисуй в excalidraw схему выбора LLM-токена запуска: /mcp analyze_data и POST /public/v2/agent-runs кладут ключ квоты в run_context, StreamAgentRunner.run один раз на старте вызывает LlmAccessPort.token_for(quota_key), адаптер VaultLlmAccess читает Vault по пути на ключ, токен уходит в RunChatModelFactory и дальше в LLM Proxy на учетку топов, Proteus или агента.
