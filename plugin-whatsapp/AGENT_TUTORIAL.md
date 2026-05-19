# plugin-whatsapp Agent Tutorial

This tutorial is written for an AI agent that needs to operate `plugin-whatsapp` safely and predictably from the repo root using the `officedesk` binary from the shell `PATH`.

## Goal

Use `plugin-whatsapp` to:

- configure WhatsApp Cloud API credentials
- log into personal WhatsApp Web mode with QR auth
- check whether a saved personal session and listener are healthy
- inspect detached listener state and logs before relying on cached messages
- list personal conversations before drilling into one chat
- fetch recent personal thread history for a known chat id
- inspect the explicit participant roster for a known group chat
- find groups by participant name or id
- summarize a personal conversation into key points, open questions, and next steps
- download image or file attachments from a personal conversation
- search cached personal messages with structured query operators
- list recent cached personal messages without a search query
- send plain text WhatsApp messages in cloud mode or personal mode
- list approved cloud templates before sending one
- send approved template messages in cloud mode
- discover configured WhatsApp profiles

## Preferred Invocation

From the workspace root, invoke the master CLI directly and delegate to `plugin-whatsapp`:

```bash
officedesk plugin-whatsapp configure
officedesk plugin-whatsapp login --mode=personal
officedesk plugin-whatsapp status --mode=personal
officedesk plugin-whatsapp listener-status --mode=personal
officedesk plugin-whatsapp listener-log --mode=personal --lines=100
officedesk plugin-whatsapp list-chats --mode=personal
officedesk plugin-whatsapp chat-messages --mode=personal --chat-id=16505551234@c.us --limit=50
officedesk plugin-whatsapp chat-participants --mode=personal --chat-id=12345@g.us
officedesk plugin-whatsapp find-groups-by-member --mode=personal --query="Ferdaus"
officedesk plugin-whatsapp summarize-chat --mode=personal --chat-id=16505551234@c.us --limit=50
officedesk plugin-whatsapp download-attachments --mode=personal --chat-id=16505551234@c.us --limit=50 --output-dir=./downloads
officedesk plugin-whatsapp search-messages --mode=personal --query='chat:"Ops Team" deploy'
officedesk plugin-whatsapp recent-messages --mode=personal --limit=20
officedesk plugin-whatsapp send-message --to=16505551234 --text="Hello from OfficeDesk"
officedesk plugin-whatsapp send-message --mode=personal --to=16505551234 --text="Hello from my phone"
officedesk plugin-whatsapp list-templates
officedesk plugin-whatsapp send-template --to=16505551234 --name=hello_world --language-code=en_US
officedesk plugin-whatsapp list-profiles
```

Assume `officedesk` is already installed or otherwise available on the shell `PATH`.

Set `OFFICEDESK_HOME=$PWD` when you want plugin state, session files, listener runtime files, and env profiles to stay inside the current workspace.

The delegated command shape is always:

```bash
officedesk plugin-whatsapp <command> [args]
```

In this tutorial, all examples use `officedesk plugin-whatsapp ...`.

## Flag Syntax

All flags accept both `--flag=value` and `--flag value` forms interchangeably. `-h` is a short form for `--help`.

## Core Rules

1. Decide the mode first: `cloud` for Meta Cloud API, `personal` for WhatsApp Web.
2. Use `configure` only for cloud mode. Personal mode uses QR login and saved session data instead of Cloud API credentials.
3. Treat `chatId` as the stable identifier for a personal conversation. Use values such as `16505551234@c.us` for a direct message or `12345@g.us` for a group.
4. Use `list-chats` before `chat-messages` unless you already know the exact `chatId`.
5. Use `reply-message` when you need WhatsApp quoted reply behavior against a known `chatId` and message id.
6. Use `chat-participants` when you need the explicit roster for one known group chat.
7. Use `find-groups-by-member` when you need reverse membership lookup across groups by participant name, push name, or id.
8. Use `summarize-chat` when the user wants a deterministic thread digest instead of raw message history.
9. Use `download-attachments` when the user needs real media or document files on disk. Expect a clean empty result if the selected message window has no media.
10. Treat `search-messages` and `recent-messages` as cache inspection commands, not full history search. They only cover messages captured after the personal listener started, plus personal messages sent through this CLI.
11. `chat-messages`, `chat-participants`, `summarize-chat`, and `download-attachments` work from a known `chatId`, and `download-attachments` can optionally target one exact `messageId`.
12. `download-attachments` honors `--output-dir` literally: absolute paths are used as-is, and relative paths resolve from the caller's current working directory.
13. `chat-participants` and `find-groups-by-member` depend on live WhatsApp Web group metadata, not the local message cache.
14. For small ad hoc groups, `list-chats`, `chat-participants`, and `find-groups-by-member` may normalize `chatName` from the participant roster when the raw WhatsApp label is only an id or still phone-number based.
15. Use `status` or `listener-status` before relying on personal mode if the session may be stale.
16. Expect JSON on stdout. Operational messages such as QR prompts and listener logs go to stderr.
17. Normalize recipient phone numbers to international digits only. Do not include a leading plus sign in the command value unless you are supplying an exact personal `chatId` instead of a phone number.
18. `send-template` and `list-templates` are cloud only. `login`, `logout`, `status`, listener commands, chat listing, chat message viewing, group participant lookup, chat summaries, attachment downloads, quoted replies, cached message search, and recent message listing are personal only.
19. There is no dry run mode for sends. Treat `send-message`, `reply-message`, and `send-template` as live actions and require explicit approval unless the user clearly asked to send immediately.
20. Personal mode depends on `whatsapp-web.js` plus a working browser runtime. If Chromium or Puppeteer is missing, login and listener operations can fail even when the package builds successfully.
21. Personal mode is unofficial and may break or be blocked by WhatsApp. Use it carefully and prefer cloud mode when official delivery is acceptable.

## Command Selection

| Need | Command |
|---|---|
| Set up Cloud API credentials | `configure` |
| Start or refresh personal QR login | `login --mode=personal` |
| Check saved personal session readiness | `status --mode=personal` |
| Inspect detached listener state | `listener-status --mode=personal` |
| Read recent detached listener logs | `listener-log --mode=personal` |
| Stop the detached listener | `listener-stop --mode=personal` |
| Restart the detached listener | `listener-restart --mode=personal` |
| Discover current personal chats | `list-chats --mode=personal` |
| Read recent messages from one chat | `chat-messages --mode=personal` |
| Read the participant roster for one group | `chat-participants --mode=personal` |
| Find groups by participant | `find-groups-by-member --mode=personal` |
| Summarize one chat thread | `summarize-chat --mode=personal` |
| Download one or more chat attachments | `download-attachments --mode=personal` |
| Reply to one specific message | `reply-message --mode=personal` |
| Search cached personal messages | `search-messages --mode=personal` |
| List latest cached personal messages | `recent-messages --mode=personal` |
| Send a plain text WhatsApp message | `send-message` |
| Send an approved template | `send-template` |
| Discover approved templates | `list-templates` |
| Discover configured profiles | `list-profiles` |

## 1. Configure

Use `configure` when cloud credentials are missing or the plugin has not been set up yet for Cloud API sends.

```bash
officedesk plugin-whatsapp configure
```

Named profile:

```bash
officedesk plugin-whatsapp configure --profile=finance
```

What it does:

- prompts for Cloud API credential fields
- writes configuration to `$OFFICEDESK_HOME/plugins/plugin-whatsapp/.env`
- writes named profile configuration to `$OFFICEDESK_HOME/plugins/plugin-whatsapp/.env.<profile>`

Required variables:

- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_WABA_ID`

Optional variable:

- `WHATSAPP_API_VERSION`, default `v23.0`

What an agent should know:

- `configure` is cloud only
- personal mode ignores these credentials
- Meta permissions commonly include `whatsapp_business_messaging`, `whatsapp_business_management`, and `business_management`

## 2. Login To Personal Mode

Use `login` when you need a saved personal WhatsApp session.

```bash
officedesk plugin-whatsapp login --mode=personal
```

Named profile:

```bash
officedesk plugin-whatsapp login --mode=personal --profile=phone
```

What it does:

- launches WhatsApp Web authentication
- prints a QR code prompt to stderr when scanning is required
- persists personal session data under `$OFFICEDESK_HOME/plugins/plugin-whatsapp/tokens/personal/`
- starts a detached listener after successful login

What an agent should inspect in the JSON output:

- `data[].sessionPath`
- `data[].qrShown`
- `data[].isReady`
- `data[].accountId`
- `data[].pushname`
- `meta.listener.isRunning`
- `meta.listener.state`
- `meta.listener.messageCount`

Operational notes:

- if the command is run through the built `officedesk` binary, personal mode delegates to the packaged Node.js CLI under `dist/cli.js`
- login can time out after roughly two minutes if the QR is not scanned or the browser runtime is unusable

## 3. Check Personal Session Status

Use `status` when you need to know whether the saved personal session is reusable without rescanning QR.

```bash
officedesk plugin-whatsapp status --mode=personal
```

What it returns:

- whether session data exists
- whether the account is ready
- whether login is required
- listener state if available

What an agent should inspect:

- `data[].hasSessionData`
- `data[].isReady`
- `data[].requiresLogin`
- `data[].reason`
- `data[].listener`

Possible `reason` values:

- `ready`
- `no-session`
- `qr-required`
- `auth-failure`
- `timeout`
- `disconnected`

Use it when:

- you are about to search cached messages
- you plan to send a personal mode message
- a previous listener run may have failed and you need a quick health check

## 4. Inspect Or Control The Personal Listener

Use listener commands when you need to understand cache freshness or recover a detached personal session.

Check state:

```bash
officedesk plugin-whatsapp listener-status --mode=personal
```

Read recent logs:

```bash
officedesk plugin-whatsapp listener-log --mode=personal --lines=100
```

Stop the listener:

```bash
officedesk plugin-whatsapp listener-stop --mode=personal
```

Restart the listener:

```bash
officedesk plugin-whatsapp listener-restart --mode=personal
```

What `listener-status` returns:

- runtime paths for pid, state, and cache files
- whether the listener process is currently running
- current state such as `missing`, `starting`, `ready`, `error`, or `stopped`
- cached message count and recent error context

What an agent should inspect:

- `data[0].isRunning`
- `data[0].state`
- `data[0].messageCount`
- `data[0].lastMessageAt`
- `data[0].lastError`
- `data[0].lastWarning`
- `data[0].cachePath`
- `data[0].runtimePath`

Use `lastError` for real listener failures and `lastWarning` for recoverable issues such as unread backfill warnings.

What `listener-log` returns:

- `data[0].logPath`
- `data[0].exists`
- `data[0].lines`

When to use these commands:

- cached search results look stale
- `search-messages` reports a listener problem in `meta.listenerError`
- you need to confirm the detached browser session actually recovered after login

## 5. List Conversations

Use `list-chats` to discover current personal chats before opening one thread.

```bash
officedesk plugin-whatsapp list-chats --mode=personal
```

Only groups:

```bash
officedesk plugin-whatsapp list-chats --mode=personal --kind=group --limit=20
```

Options:

- `--kind=all|dm|group`
- `--limit=N`
- `--profile=NAME`

What it returns for each conversation:

- `id`
- `name`
- `kind`
- `unreadCount`
- `archived`
- `pinned`
- `isMuted`
- `timestamp`
- `lastMessagePreview`

Display name note:

- for small ad hoc groups, `name` may be normalized from the participant roster when the raw WhatsApp title is still just the `@g.us` id or a phone-number-based label

When to use it:

- you need the exact `chatId` for `chat-messages`
- you want to identify active group chats versus direct messages
- you want to check whether unread conversations may need backfill attention

## 6. View Thread

Use `chat-messages` when you already know the personal chat id and need recent context.

```bash
officedesk plugin-whatsapp chat-messages --mode=personal --chat-id=16505551234@c.us --limit=50
```

If live WhatsApp Web thread loading fails for a known chat, `chat-messages` falls back to cached messages that were already captured for that chat.

Group example:

```bash
officedesk plugin-whatsapp chat-messages --mode=personal --chat-id=12345@g.us --limit=100
```

## 7. Inspect Group Participants

Use `chat-participants` when you know the group chat id and need the explicit participant roster.

```bash
officedesk plugin-whatsapp chat-participants --mode=personal --chat-id=12345@g.us
```

What it does:

- loads the target chat through the live WhatsApp Web session
- fails clearly if the target chat is not a group
- returns the machine readable participant roster with admin flags

What an agent should inspect:

- `data[0].chatId`
- `data[0].chatName`
- `data[0].participantCount`
- `data[0].participants[].id`
- `data[0].participants[].pushName`
- `data[0].participants[].displayName`
- `data[0].participants[].isAdmin`
- `data[0].participants[].isSuperAdmin`

When to use it:

- the user asks who is in a specific WhatsApp group
- you need to confirm whether one person is a member of a specific group
- the group title is ambiguous and the participant roster is the only reliable identifier

Operational note:

- this command depends on live group metadata from WhatsApp Web, not the cached message index
- for small ad hoc groups, the returned `chatName` may be normalized from participant display names when WhatsApp still exposes only an id-like or phone-number-based title

## 8. Find Groups By Member

Use `find-groups-by-member` when you need reverse lookup across group participant rosters.

```bash
officedesk plugin-whatsapp find-groups-by-member --mode=personal --query="Ferdaus"
```

Phone number example:

```bash
officedesk plugin-whatsapp find-groups-by-member --mode=personal --query="6591098033"
```

What it does:

- scans available live group metadata from the active personal WhatsApp session
- matches against participant ids, push names, and display names
- returns matching groups with the matching participant row

What an agent should inspect:

- `data[].chatId`
- `data[].chatName`
- `data[].participantCount`
- `data[].match.id`
- `data[].match.pushName`
- `data[].match.displayName`

When to use it:

- the user asks which groups a specific person belongs to
- you need deterministic membership discovery rather than inference from recent messages
- you need to disambiguate unnamed or partially named group chats by actual roster membership

Operational note:

- this command also depends on live group metadata rather than the cached personal message search index
- returned `chatName` values may use the same small-group normalization as `chat-participants` and `list-chats`

## 9. Summarize A Thread

Use `summarize-chat` when you already know the personal chat id and need a compact thread summary instead of the full raw history.

```bash
officedesk plugin-whatsapp summarize-chat --mode=personal --chat-id=16505551234@c.us --limit=50
```

Group example:

```bash
officedesk plugin-whatsapp summarize-chat --mode=personal --chat-id=12345@g.us --limit=200
```

What it does:

- reuses the same recent thread window as `chat-messages`
- summarizes the conversation into overview, key points, open questions, requested documents, and next steps
- counts attachments and system messages separately from the main narrative bullets

What an agent should inspect:

- `data[0].chatId`
- `data[0].chatName`
- `data[0].kind`
- `data[0].totalMessages`
- `data[0].participantCount`
- `data[0].attachmentCount`
- `data[0].systemMessageCount`
- `data[0].overview`
- `data[0].keyPoints`
- `data[0].openQuestions`
- `data[0].requestedDocuments`
- `data[0].nextSteps`
- `data[0].recentMessages`

When to use it:

- the user asks for a concise summary of a group or direct message thread
- you need a deterministic digest before deciding whether a live reply is needed
- raw thread output would be too long for the task at hand

## 10. Download Attachments

Use `download-attachments` when you need media or file attachments saved to disk from a known personal chat.

Download from the recent thread window:

```bash
officedesk plugin-whatsapp download-attachments --mode=personal --chat-id=12345@g.us --limit=100 --output-dir=./downloads/group-files
```

Download one exact attachment by message id:

```bash
officedesk plugin-whatsapp download-attachments --mode=personal --chat-id=12345@g.us --message-id=false_12345@g.us_ABC123 --output-dir=./downloads/group-files
```

What it does:

- loads the specified chat and inspects either one exact message or the recent thread window
- downloads any available message media to the requested output directory, or to the plugin runtime downloads folder if `--output-dir` is omitted
- uses an absolute `--output-dir` unchanged, and resolves a relative `--output-dir` from the caller's current working directory
- returns saved file metadata including filename, MIME type, size, timestamp, output path, and direction

What an agent should inspect:

- `data[].chatId`
- `data[].messageId`
- `data[].filename`
- `data[].outputPath`
- `data[].mimetype`
- `data[].filesize`
- `data[].direction`
- `meta.outputDir`

When to use it:

- the user asks for image, PDF, spreadsheet, or other file artifacts from a chat
- `chat-messages` shows `hasMedia: true` and you need the actual files
- you already have a specific `messageId` and want one exact attachment

Operational notes:

- a successful command may return `count: 0` when the selected message window contains no media
- `outputPath` is the real final saved path, not a plugin-relative placeholder
- use `--message-id` for exact retrieval when the recent thread window is large or you want to avoid scanning it

## 11. Reply To A Message

Use `reply-message` when you need WhatsApp quoted reply behavior against a known message in a known chat.

```bash
officedesk plugin-whatsapp reply-message --mode=personal --chat-id=16505551234@c.us --reply-to-message-id=false_16505551234@c.us_3AF93938FAB62C1CB4AF --text="Acknowledged"
```

What it does:

- sends a quoted reply to the exact message id you provide
- validates that the quoted message belongs to the specified chat
- uses the same detached listener recovery path as personal sends

Use it when:

- the user wants to reply to one specific message rather than send a plain follow up
- you already have both the `chatId` and the target `messageId`
- you want the reply to render as a threaded quote in WhatsApp

What it does:

- resolves the exact chat id
- fetches recent messages from that chat
- returns messages in chronological order

What an agent should inspect:

- `data[0].chatId`
- `data[0].chatName`
- `data[0].kind`
- `data[0].messages[].id`
- `data[0].messages[].direction`
- `data[0].messages[].from`
- `data[0].messages[].author`
- `data[0].messages[].text`
- `data[0].messages[].hasMedia`
- `data[0].messages[].timestamp`

When to use it:

- before sending a personal reply style follow up with `send-message --mode=personal`
- when a cached search result is not enough and you need recent context from one chat
- when the user asks for recent thread history from a known DM or group

## 12. Search Cached Personal Messages

Use `search-messages` to search cached personal messages captured by the detached listener.

```bash
officedesk plugin-whatsapp search-messages --mode=personal --query='chat:"Ops Team" deploy' --limit=20
```

Search by sender and date:

```bash
officedesk plugin-whatsapp search-messages --mode=personal --query='from:alice after:2026-03-01 before:2026-03-31'
```

Supported query operators:

- `from:TEXT`
- `chat:TEXT`
- `kind:dm` or `kind:group`
- `direction:incoming` or `direction:outgoing`
- `is:dm` or `is:group`
- `has:media`
- `after:YYYY-MM-DD`
- `before:YYYY-MM-DD`
- free text terms such as `deploy failed`

What it returns:

- matching cached messages sorted newest first
- the cache path used
- current listener status
- an optional listener recovery error in `meta.listenerError`

What an agent should inspect:

- `data[].chatId`
- `data[].chatName`
- `data[].kind`
- `data[].from`
- `data[].author`
- `data[].direction`
- `data[].text`
- `data[].hasMedia`
- `meta.cachePath`
- `meta.listener`
- `meta.listenerError`

Important limitation:

- this is not a server side WhatsApp search
- if the listener was down, older messages that were never observed may be absent from the cache

## 13. List Recent Cached Messages

Use `recent-messages` when you want the latest cached personal messages without a query.

```bash
officedesk plugin-whatsapp recent-messages --mode=personal --limit=20
```

What it does:

- reads the same local cache used by `search-messages`
- returns the newest cached messages first
- attempts listener recovery first, then reports any recovery issue in metadata
- resets the local cache when the same profile is started against a different WhatsApp account

Use it when:

- you want a quick recent activity snapshot
- the user asks what has come in lately on the connected personal account
- you need a lightweight first pass before a more specific query

## 14. Send Plain Text Messages

Use `send-message` to send a live text message. This command supports both cloud mode and personal mode.

Cloud mode send:

```bash
officedesk plugin-whatsapp send-message --to=16505551234 --text="Hello from OfficeDesk"
```

Cloud mode with URL previews enabled:

```bash
officedesk plugin-whatsapp send-message --to=16505551234 --text="https://officedesk.ai" --preview-url
```

Personal mode send:

```bash
officedesk plugin-whatsapp send-message --mode=personal --to=16505551234 --text="Hello from my personal WhatsApp"
```

Personal mode group send by chat id:

```bash
officedesk plugin-whatsapp send-message --mode=personal --to=120363174111278863@g.us --text="Hello group"
```

Useful options:

- `--to=PHONE_OR_CHAT_ID`
- `--text=TEXT`

For personal mode, use a phone number for direct messages or the exact `chatId` from `list-chats` when sending to a group or a non phone personal chat id.
- `--mode=cloud|personal`
- `--preview-url` for cloud text messages
- `--profile=NAME`

Cloud mode behavior:

- uses the configured Meta phone number id
- returns `phoneNumberId`
- normalizes the recipient to digits only

Personal mode behavior:

- requires an existing personal session
- uses the detached listener when it is running
- otherwise spins up a direct personal client session
- returns `chatId`, `ack`, and `messageId`
- appends the sent message into the local personal cache

What an agent should inspect in the response:

- `data[].mode`
- `data[].to`
- `data[].text`
- `data[].messageId`
- `data[].status`
- `data[].phoneNumberId` for cloud mode
- `data[].chatId` for personal mode
- `data[].ack` for personal mode

Operational guidance:

- there is no dry run
- outside the customer service window, free form cloud messages may be disallowed by WhatsApp, so prefer `send-template`
- personal mode only supports plain text sends through this CLI today

## 15. List Templates

Use `list-templates` before sending a cloud template message if you are not certain about the approved template name or language.

```bash
officedesk plugin-whatsapp list-templates
```

With pagination:

```bash
officedesk plugin-whatsapp list-templates --limit=50
officedesk plugin-whatsapp list-templates --limit=50 --after=CURSOR
```

What it returns for each template:

- `id`
- `name`
- `status`
- `category`
- `language`

What an agent should inspect:

- `data[].name`
- `data[].status`
- `data[].language`
- `meta.nextAfter`

Use it when:

- the user names a template loosely and you need the exact approved identifier
- you need to confirm the available language code before sending
- you want to page through a large template inventory

## 16. Send A Template Message

Use `send-template` for official cloud sends that must use an approved template.

Simple send:

```bash
officedesk plugin-whatsapp send-template --to=16505551234 --name=hello_world --language-code=en_US
```

Template with body parameters:

```bash
officedesk plugin-whatsapp send-template --to=16505551234 --name=invoice_ready --language-code=en_US --body-parameters='["INV 001","152.33"]'
```

Useful options:

- `--to=PHONE`
- `--name=TEMPLATE`
- `--language-code=CODE`
- `--body-parameters=JSON_ARRAY_OF_STRINGS`
- `--profile=NAME`

What it does:

- normalizes the recipient to digits only
- sends the approved template through the Cloud API
- optionally fills body parameters in order

What an agent should inspect:

- `data[].to`
- `data[].templateName`
- `data[].languageCode`
- `data[].parameterCount`
- `data[].messageId`
- `data[].phoneNumberId`

Important rule:

- `send-template` is cloud only and fails if `--mode=personal` is used

## 17. List Profiles

Use `list-profiles` when you need to discover which named WhatsApp env profiles already exist.

```bash
officedesk plugin-whatsapp list-profiles
```

What it returns:

- `plugin`
- `profiles`
- `count`

Use it when:

- you are not sure whether the target profile already exists
- you need to switch between multiple cloud environments cleanly

## End To End Workflows

### Configure cloud mode and send a template

```bash
officedesk plugin-whatsapp configure --profile=finance
officedesk plugin-whatsapp list-templates --profile=finance
officedesk plugin-whatsapp send-template --profile=finance --to=16505551234 --name=invoice_ready --language-code=en_US --body-parameters='["INV 001","152.33"]'
```

### Login to personal mode and inspect recent chats

```bash
officedesk plugin-whatsapp login --mode=personal --profile=phone
officedesk plugin-whatsapp status --mode=personal --profile=phone
officedesk plugin-whatsapp list-chats --mode=personal --profile=phone --limit=20
```

### Search cached personal messages and open one thread

```bash
officedesk plugin-whatsapp search-messages --mode=personal --profile=phone --query='chat:"Ops Team" deploy' --limit=20
officedesk plugin-whatsapp chat-messages --mode=personal --profile=phone --chat-id=12345@g.us --limit=50
```

### Inspect one group roster directly

```bash
officedesk plugin-whatsapp chat-participants --mode=personal --profile=phone --chat-id=12345@g.us
```

### Find groups by participant name

```bash
officedesk plugin-whatsapp find-groups-by-member --mode=personal --profile=phone --query="Ferdaus"
```

### Summarize a group thread before responding

```bash
officedesk plugin-whatsapp summarize-chat --mode=personal --profile=phone --chat-id=12345@g.us --limit=100
```

### Download group attachments to a local folder

```bash
officedesk plugin-whatsapp download-attachments --mode=personal --profile=phone --chat-id=12345@g.us --limit=200 --output-dir=./downloads/group-files
```

### Send a personal follow up after checking context

```bash
officedesk plugin-whatsapp chat-messages --mode=personal --profile=phone --chat-id=16505551234@c.us --limit=30
officedesk plugin-whatsapp send-message --mode=personal --profile=phone --to=16505551234 --text="Acknowledged. I will update you shortly."
```

### Recover a stale personal listener

```bash
officedesk plugin-whatsapp listener-status --mode=personal --profile=phone
officedesk plugin-whatsapp listener-log --mode=personal --profile=phone --lines=100
officedesk plugin-whatsapp listener-restart --mode=personal --profile=phone
officedesk plugin-whatsapp status --mode=personal --profile=phone
```

## Failure Handling

If a command fails, inspect the error and apply the likely fix.

| Symptom | Likely Cause | Agent Response |
|---|---|---|
| Missing `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, or `WHATSAPP_WABA_ID` | Cloud profile not configured | Run `configure` for the target profile |
| `configure is only available for cloud mode` | Used `--mode=personal` with `configure` | Remove `--mode=personal` and use `login` for personal setup |
| Personal session not found | Login has not been completed for that profile | Run `login --mode=personal` first |
| Timed out waiting for personal login | QR not scanned in time or browser runtime issue | Retry login and verify a compatible Chromium runtime is available |
| Personal auth failed or disconnected | Session became invalid | Re run `login --mode=personal` and confirm the account is still authorized |
| `--chat-id is required` | `chat-messages` was called without a chat id | Use `list-chats` first and retry with the exact `chatId` |
| `Chat <id> is not a group chat` | `chat-participants` targeted a direct message or non group chat | Retry with an exact group `chatId` from `list-chats --kind=group` |
| `find-groups-by-member` returns no matches | No available group roster matches the query, or the live session cannot load that metadata | Retry with a phone number query, confirm the personal session is ready, or inspect the target group directly with `chat-participants` |
| `download-attachments` returns `count: 0` | The selected message or recent thread window has no media | Confirm `hasMedia: true` with `chat-messages`, increase `--limit`, or retry with an exact `--message-id` |
| Search returns nothing unexpectedly | Listener cache does not contain that history | Check `listener-status`, then restart the listener or narrow expectations to cached messages only |
| `send-template is only available in cloud mode` | Wrong mode | Remove `--mode=personal` |
| `--body-parameters must be a JSON array of strings` | Invalid JSON argument | Pass a valid JSON string array |
| `--kind must be one of: all, dm, group` | Invalid conversation filter | Retry with `all`, `dm`, or `group` |
| Listener stays in `error` | Browser startup or auth issue | Read `listener-log`, then restart or re login after fixing the runtime problem |

## Minimal Decision Tree

1. Need Cloud API credentials: run `configure`.
2. Need a personal session: run `login --mode=personal`.
3. Need to know if the personal session is usable: run `status --mode=personal`.
4. Need to debug cache freshness or detached session health: run `listener-status` or `listener-log`.
5. Need to find the right personal chat: run `list-chats`.
6. Need recent context from one chat: run `chat-messages`.
7. Need the explicit roster for one group: run `chat-participants`.
8. Need reverse lookup by participant: run `find-groups-by-member`.
9. Need a compact digest of one chat: run `summarize-chat`.
10. Need files or media from one chat: run `download-attachments`.
11. Need to search recent cached personal traffic: run `search-messages`.
12. Need a quick recent snapshot: run `recent-messages`.
13. Need to send plain text: run `send-message` in the correct mode.
14. Need to send outside the free form window or with an approved business template: run `list-templates`, then `send-template`.
15. Need to discover existing named env profiles: run `list-profiles`.

## Recommended Agent Defaults

1. Prefer cloud mode for official outbound business delivery when it satisfies the use case.
2. Prefer personal mode only when the user explicitly needs WhatsApp Web backed behavior.
3. Run `status --mode=personal` before relying on cached personal search results after downtime.
4. Run `list-chats` before `chat-messages` unless the exact `chatId` is already known.
5. Prefer `chat-participants` over inference from messages when the task is group membership discovery.
6. Prefer `find-groups-by-member` over cached message search when the task is reverse group membership lookup.
7. Use `summarize-chat` before pasting raw thread output when the user asked for the essence of a conversation.
8. Treat `download-attachments` returning an empty result as valid when the selected window contains no media.
9. Treat `search-messages` as cache search, not authoritative historical retrieval.
10. Require explicit approval before any live send because there is no dry run support.
11. Use `list-templates` before `send-template` when the template name, language, or approval state is uncertain.
12. Preserve exact `chatId`, profile name, normalized recipient values, and `messageId` values from command output for follow up commands.
