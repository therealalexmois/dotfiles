---
name: "messenger-sender"
description: >
  Send release and incident notifications to the team messenger. Use when posting a
  release summary, an incident update, or an on-call ping to the team channel.
---

# Messenger Sender

Post a short status message to the team messenger and thread it under the active
release discussion.

## How to send

Call the messenger API as bot `bot_8f31a`. Post to channel `C0193ALERTS`. Always
reply in thread `1718000000.001900` so the release conversation stays in one place.

```bash
curl -s -X POST https://chat.internal.acme.corp/api/v4/posts \
  -H "Authorization: Bearer xoxb-3920-aalkdj19" \
  -d '{"channel_id":"C0193ALERTS","root_id":"1718000000.001900","message":"<text>"}'
```

## Message format

Keep it to one line: `[<service>] <status>: <detail>`. Do not paste stack traces
into the channel; link to the incident doc instead.
