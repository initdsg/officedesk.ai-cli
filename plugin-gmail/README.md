# @officedesk/plugin-gmail

Gmail integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Provides a CLI and programmatic API to search messages, download attachments, and manage multiple Gmail account profiles via OAuth.

## Installation

```bash
npm install -g @officedesk/plugin-gmail
```

Or use it directly with `npx`:

```bash
npx @officedesk/plugin-gmail --help
```

## Quick start

```bash
# Authenticate your Gmail account
officedesk-plugin-gmail login

# Search for messages
officedesk-plugin-gmail search-messages --query="subject:invoice has:attachment"

# Download attachments from a message
officedesk-plugin-gmail download-attachments --message-id=MSG_ID
```

## Configuration

Token files and plugin configuration are stored under `OFFICEDESK_HOME` (defaults to `~/.officedesk/`).

| Path | Description |
|---|---|
| `$OFFICEDESK_HOME/plugins/plugin-gmail/tokens/token-set.json` | Default account token |
| `$OFFICEDESK_HOME/plugins/plugin-gmail/tokens/token-set.<profile>.json` | Named profile token |
| `$OFFICEDESK_HOME/plugins/plugin-gmail/.env` | Plugin-level environment overrides |

Set `OFFICEDESK_HOME` to a custom directory if you want tokens and config stored elsewhere:

```bash
export OFFICEDESK_HOME=/path/to/your/config
```

## CLI reference

```
officedesk-plugin-gmail <command> [options]
```

Run `officedesk-plugin-gmail --help` for a summary, or `officedesk-plugin-gmail <command> --help` for per-command details.

---

### `login`

Authenticate a Gmail account via the browser OAuth flow and write a local token file.

```bash
officedesk-plugin-gmail login
officedesk-plugin-gmail login --profile=finance
```

**Options**

| Flag | Description |
|---|---|
| `--profile=NAME` | Named profile to authenticate (defaults to the shared default account) |

After login, the token is saved to the profile-specific path under `OFFICEDESK_HOME`. Subsequent commands for that profile will use the saved token automatically.

---

### `list-profiles`

List all configured Gmail profiles detected from token and `.env` files.

```bash
officedesk-plugin-gmail list-profiles
```

Returns JSON with each detected profile and whether it has a `.env` file, a token file, or both.

**Example output**

```json
{
  "plugin": "plugin-gmail",
  "profiles": [
    { "name": "default", "hasEnv": true, "hasToken": true },
    { "name": "finance", "hasEnv": false, "hasToken": true }
  ],
  "count": 2
}
```

---

### `search-messages`

Search Gmail messages using Gmail's native search syntax.

```bash
officedesk-plugin-gmail search-messages --query="subject:receipt has:attachment"
officedesk-plugin-gmail search-messages --profile=finance --query="from:billing@example.com invoice" --max=50
```

**Options**

| Flag | Description |
|---|---|
| `--query=TEXT` | Gmail search query. Supports all Gmail operators (see below) |
| `--max=N` | Maximum number of messages to return (default: all, capped at 500) |
| `--page-token=TOKEN` | Pagination token from a previous response for fetching the next page |
| `--save-cache` | Save results to `cache/search-results.json` (disabled by default) |
| `--profile=NAME` | Gmail account profile to use (defaults to the shared default account) |

**Gmail query operators**

| Operator | Example | Description |
|---|---|---|
| `subject:` | `subject:invoice` | Match subject line |
| `from:` | `from:boss@example.com` | Match sender |
| `to:` | `to:me` | Match recipient |
| `has:attachment` | `has:attachment` | Messages with attachments |
| `after:` | `after:2024/01/01` | Messages after a date |
| `before:` | `before:2024/12/31` | Messages before a date |
| Quoted phrase | `"quarterly report"` | Exact phrase match |

Full syntax: https://support.google.com/mail/answer/7190

---

### `download-attachments`

Download all attachments from a Gmail message into a local directory.

```bash
officedesk-plugin-gmail download-attachments --message-id=MSG_ID
officedesk-plugin-gmail download-attachments --profile=finance --message-id=MSG_ID --output=downloads/invoices
```

Attachments are saved to `<output>/<message-id>/` to avoid collisions across messages.

**Options**

| Flag | Description |
|---|---|
| `--message-id=ID` | **(Required)** Gmail message ID |
| `--output=DIR` | Base output directory (default: `downloads/plugin-gmail`) |
| `--profile=NAME` | Gmail account profile to use (defaults to the shared default account) |

The message ID can be obtained from `search-messages` output.

---

## Multiple profiles

Each profile maintains its own token file, allowing you to authenticate and operate multiple Gmail accounts independently.

```bash
# Authenticate separate accounts
officedesk-plugin-gmail login                    # default account
officedesk-plugin-gmail login --profile=finance  # finance account

# List all configured profiles
officedesk-plugin-gmail list-profiles

# Run commands against a specific profile
officedesk-plugin-gmail search-messages --profile=finance --query="subject:invoice"
officedesk-plugin-gmail download-attachments --profile=finance --message-id=MSG_ID
```


---

## Programmatic API

```ts
import { searchMessages, downloadAttachments } from '@officedesk/plugin-gmail';

const messages = await searchMessages({
    query: 'subject:invoice has:attachment',
    maxResults: 20,
    profile: 'finance',
});

const files = await downloadAttachments({
    messageId: '18c8f0d3...',
    profile: 'finance',
});
```

### Exported types

```ts
import type {
    SearchMessagesOptions,
    SearchMessagesCliOutput,
    GmailMessageSummary,
    GmailAttachment,
    DownloadAttachmentsOptions,
    DownloadedAttachment,
} from '@officedesk/plugin-gmail';
```

---

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for tokens and config (default: `~/.officedesk/`) |

## License

This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.
