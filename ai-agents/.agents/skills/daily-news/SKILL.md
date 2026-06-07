---
name: daily-news
description: "Get today's relevant news headlines from the web, based on configured topics. Returns 3-5 recent stories, each with a one-sentence summary, source, and link. Use when the user asks: daily news, headlines, what's happening, news briefing. Web-only, no vault or external accounts required."
---

# Daily News

Search for today's most relevant news headlines based on configured topics. Web-only —
no vault, Notion, or calendar required, so it is fully portable across machines.

## Config — topics
Search for news related to these subjects. Edit this list to match your interests:

- Artificial intelligence and AI tools
- Business leadership and management
- Productivity and workflow automation

Examples to add/swap: Healthcare technology · Cybersecurity · Marketing · Real estate · Education technology.

## What to do

When the user asks for "daily news" or headlines:

1. **Search the web** for recent news on each configured topic.
2. **Select 3–5 stories** most relevant and recent (within the last 24–48 hours).
3. **For each story, provide:** a one-sentence summary, the source name, and a link.

## Output format

Numbered list:

```
1. **[Headline summary]** — *Source Name* ([link])
2. **[Headline summary]** — *Source Name* ([link])
```

Keep it to 3–5 items. No commentary or analysis — just headlines, sources, and links.
