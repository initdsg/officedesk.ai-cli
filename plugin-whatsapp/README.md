# @officedesk/plugin-whatsapp

WhatsApp integration plugin for officedesk-ai.

It supports two execution modes:

- cloud mode through Meta's official WhatsApp Cloud API
- personal mode through WhatsApp Web with QR login

Current capabilities include:

- profile based cloud configuration
- QR login with persisted personal sessions
- detached personal listener management
- personal session status inspection and logout
- listener diagnostics for state and logs
- listing personal conversations including direct messages and groups
- viewing recent message history for a known chat id
- inspecting the explicit participant roster for a known group chat
- finding groups by participant name or id through live group metadata
- replying to a specific personal WhatsApp message by message id
- searching cached personal messages with structured query operators
- listing recent cached personal messages without a query
- sending plain text messages in cloud mode or personal mode
- listing approved templates in cloud mode
- sending approved template messages in cloud mode

## Preferred Invocation

```bash
officedesk plugin-whatsapp configure
officedesk plugin-whatsapp login --mode=personal
officedesk plugin-whatsapp status --mode=personal
officedesk plugin-whatsapp list-chats --mode=personal
officedesk plugin-whatsapp chat-participants --mode=personal --chat-id=120363425647096616@g.us
officedesk plugin-whatsapp find-groups-by-member --mode=personal --query="Ferdaus"
officedesk plugin-whatsapp send-message --to=16505551234 --text="Hello from OfficeDesk"
officedesk plugin-whatsapp send-template --to=16505551234 --name=hello_world --language-code=en_US
```

## Mode Overview

Use cloud mode when you need official business delivery through Meta APIs.

Use personal mode when you explicitly need WhatsApp Web backed behavior from a logged in personal session.

Mode specific rules:

- `configure`, `list-templates`, and `send-template` are cloud only
- `login`, `logout`, `status`, listener commands, `list-chats`, `chat-messages`, `chat-participants`, `find-groups-by-member`, `reply-message`, `search-messages`, and `recent-messages` are personal only
- `send-message` works in both modes

## Configuration

Default profile:

```bash
officedesk plugin-whatsapp configure
```

Named profile:

```bash
officedesk plugin-whatsapp configure --profile=finance
```

The plugin writes configuration into:

- default profile: `$OFFICEDESK_HOME/plugins/plugin-whatsapp/.env`
- named profile: `$OFFICEDESK_HOME/plugins/plugin-whatsapp/.env.<profile>`

Supported cloud variables:

- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_WABA_ID`
- `WHATSAPP_API_VERSION` optional, defaults to `v23.0`

Personal mode stores session data under:

- `$OFFICEDESK_HOME/plugins/plugin-whatsapp/tokens/personal/`

Personal mode does not use the cloud credentials.

Meta permissions commonly include:

- `whatsapp_business_messaging`
- `whatsapp_business_management`
- `business_management`

## Developer Notes

For an implementation walkthrough of the personal mode runtime, including listener lifecycle, cache flow, RPC handling, and recovery behavior, see [personal-session.md](./personal-session.md).

## Personal Mode Workflow

Login with QR auth:

```bash
officedesk plugin-whatsapp login --mode=personal
```

After login succeeds, the plugin starts a detached listener that keeps the browser session alive and appends observed messages into a local cache.

Check personal session status:

```bash
officedesk plugin-whatsapp status --mode=personal
```

Inspect detached listener state:

```bash
officedesk plugin-whatsapp listener-status --mode=personal
```

Read recent listener logs:

```bash
officedesk plugin-whatsapp listener-log --mode=personal --lines=100
```

Stop the detached listener without removing the saved session:

```bash
officedesk plugin-whatsapp listener-stop --mode=personal
```

Restart the detached listener against the saved session:

```bash
officedesk plugin-whatsapp listener-restart --mode=personal
```

Remove the persisted personal session:

```bash
officedesk plugin-whatsapp logout --mode=personal
```

Logout also clears the local runtime data for that profile, including cached messages, listener state, and pending listener RPC files.

## Personal Conversation And Message Inspection

List current personal chats:

```bash
officedesk plugin-whatsapp list-chats --mode=personal
```

List only groups:

```bash
officedesk plugin-whatsapp list-chats --mode=personal --kind=group --limit=20
```

Filter chats by a simple text match plus common state flags:

```bash
officedesk plugin-whatsapp list-chats --mode=personal --search='ops' --kind=group --unread-only --not-archived --limit=20
```

Use the advanced chat query syntax when you want richer combinations:

```bash
officedesk plugin-whatsapp list-chats --mode=personal --query='chat:"Ops Team" is:archived is:pinned has:unread deploy'
```

Fetch recent message history for a specific chat id:

```bash
officedesk plugin-whatsapp chat-messages --mode=personal --chat-id=16505551234@c.us --limit=50
```

Fetch the explicit participant roster for a known group chat:

```bash
officedesk plugin-whatsapp chat-participants --mode=personal --chat-id=120363425647096616@g.us
```

Find groups by participant name or id using live group metadata:

```bash
officedesk plugin-whatsapp find-groups-by-member --mode=personal --query="Ferdaus"
```

Summarize a chat thread into key points, open questions, and next steps:

```bash
officedesk plugin-whatsapp summarize-chat --mode=personal --chat-id=120363409228246808@g.us --limit=200
```

Download all recent attachments from a chat:

```bash
officedesk plugin-whatsapp download-attachments --mode=personal --chat-id=120363409228246808@g.us --limit=200 --output-dir=./downloads/kpt
```

Download one specific attachment by message id:

```bash
officedesk plugin-whatsapp download-attachments --mode=personal --chat-id=120363409228246808@g.us --message-id=false_120363409228246808@g.us_ABC123 --output-dir=./downloads/kpt
```

If WhatsApp Web thread loading fails for a known chat, `chat-messages` falls back to cached messages already captured for that chat.

Reply to a specific message in a known chat:

```bash
officedesk plugin-whatsapp reply-message --mode=personal --chat-id=16505551234@c.us --reply-to-message-id=false_16505551234@c.us_3AF93938FAB62C1CB4AF --text="Acknowledged"
```

Search cached personal messages:

```bash
officedesk plugin-whatsapp search-messages --mode=personal --query='chat:"Ops Team" deploy' --limit=20
```

List the latest personal messages without a query:

```bash
officedesk plugin-whatsapp recent-messages --mode=personal --limit=20
```

Useful list-chats filters:

- `--search=TEXT`
- `--kind=all|dm|group`
- `--archived` or `--not-archived`
- `--pinned` or `--not-pinned`
- `--muted` or `--not-muted`
- `--unread-only`
- `--query='...'`

Useful list-chats query operators:

- bare text terms match chat id, display name, and last message preview
- `chat:TEXT`
- `kind:dm` or `kind:group`
- `is:dm` or `is:group`
- `is:archived` or `is:active`
- `is:pinned`
- `is:muted`
- `has:unread`

Useful search operators:

- `from:TEXT`
- `chat:TEXT`
- `kind:dm` or `kind:group`
- `direction:incoming` or `direction:outgoing`
- `is:dm` or `is:group`
- `has:media`
- `after:2026-03-01`
- `before:2026-03-31`

Thread summary notes:

- `summarize-chat` reuses the recent thread window from `chat-messages`
- the summary is deterministic and built from message content, questions, document requests, and next-step style phrasing
- system events such as group metadata changes are counted separately from the main summary bullets

Group participant notes:

- `chat-participants` returns the explicit live roster for a group chat and fails clearly when the target chat is not a group
- `find-groups-by-member` searches participant names, push names, and ids across available live group metadata, not the cached message index
- unlike `search-messages`, these membership commands do not depend on whether the participant has posted recently
- these membership commands require a live personal WhatsApp Web session because participant rosters are not read from the local cache
- for small ad hoc groups, `chatName` and conversation `name` may be normalized from participant display names when WhatsApp still exposes only an id-like or phone-number-based title

Attachment download notes:

- `download-attachments` saves files to the provided `--output-dir`, or to the plugin runtime downloads folder when omitted
- absolute `--output-dir` values are used as-is, and relative `--output-dir` values resolve from the caller's current working directory
- `outputPath` in the JSON response is the real final saved path
- use `--message-id` when you want one exact attachment instead of scanning the recent thread window
- `chat-messages` and cached search results include `hasMedia`, and live thread fetches also include media filename and MIME metadata when available

Personal search notes:

- search uses the local cache, not a remote WhatsApp search API
- cache coverage starts when the personal listener begins observing messages
- messages sent through the personal CLI are also appended to that cache
- when the listener becomes ready it backfills unread messages from chats that currently show unread counts
- if unread backfill hits a WhatsApp Web fetch issue, the listener stays ready and records the warning in `lastWarning` rather than `lastError`
- cached personal data is reset when you log out or when the same profile starts against a different WhatsApp account

## Sending Messages

Cloud mode plain text message:

```bash
officedesk plugin-whatsapp send-message --to=16505551234 --text="Hello from OfficeDesk"
```

Cloud mode with URL preview:

```bash
officedesk plugin-whatsapp send-message --to=16505551234 --text="https://officedesk.ai" --preview-url
```

Personal mode plain text message:

```bash
officedesk plugin-whatsapp send-message --mode=personal --to=16505551234 --text="Hello from my personal WhatsApp"
```

Personal mode group message by exact chat id:

```bash
officedesk plugin-whatsapp send-message --mode=personal --to=120363174111278863@g.us --text="Hello group"
```

For personal sends, `--to` accepts either a phone number for direct messages or an exact personal `chatId` such as `12345@g.us`, `16505551234@c.us`, or `142081930604660@lid`.

For `reply-message`, use the exact `chatId` plus the message id returned by `chat-messages`, `recent-messages`, or `search-messages`.

Send a cloud template message:

```bash
officedesk plugin-whatsapp send-template --to=16505551234 --name=hello_world --language-code=en_US
```

Send a template with body parameters:

```bash
officedesk plugin-whatsapp send-template --to=16505551234 --name=invoice_ready --language-code=en_US --body-parameters='["INV 001","152.33"]'
```

List approved templates:

```bash
officedesk plugin-whatsapp list-templates
```

List configured profiles:

```bash
officedesk plugin-whatsapp list-profiles
```

Delivery notes:

- free form cloud messages are only allowed during the customer service window, so use approved templates when needed
- phone numbers must be provided in international format without a leading plus sign
- `send-template` requires cloud mode and approved template metadata
- there is no dry run support for sends, so treat send commands as live actions

## JSON Output

Structured results are written to stdout as JSON.

Operational messages such as QR prompts, listener diagnostics, and runtime logs are written to stderr.

Useful response patterns:

- `send-message` returns delivery records including `messageId`, plus `phoneNumberId` in cloud mode or `chatId` and `ack` in personal mode
- `send-template` returns `templateName`, `languageCode`, `parameterCount`, and `messageId`
- personal inspection commands include listener metadata, cache paths, or runtime paths where relevant

## Operational Notes

- personal mode uses `whatsapp-web.js`, which is unofficial and can break or be blocked by WhatsApp
- personal mode requires a working browser runtime; if Puppeteer install scripts were skipped, you may need to install or point to a compatible Chromium manually
- when running through the compiled `officedesk-plugin-whatsapp` binary, personal mode delegates to the packaged Node.js CLI under `dist/cli.js`; the plugin runtime must include `package.json`, `dist/`, and the required npm `node_modules/` for personal mode to work without any workspace package fallback
- if cached results look stale, inspect `listener-status` or `listener-log` before assuming the search index is complete

## See Also

- [AGENT_TUTORIAL.md](AGENT_TUTORIAL.md) for the full agent workflow guide