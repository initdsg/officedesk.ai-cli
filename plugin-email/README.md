# @officedesk/plugin-email

Generic email integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Searches IMAP messages across all mailboxes, views threads, downloads attachments, sends fresh outbound emails, and replies via SMTP — no OAuth required.

## Installation

```bash
npm install -g @officedesk/plugin-email
```

## Quick start

```bash
# Configure credentials
officedesk-plugin-email configure

# Search
officedesk-plugin-email search-messages --query="from:billing@acme.com has:attachment"

# Discover mailboxes
officedesk-plugin-email list-mailboxes

# Inspect a full thread from one message
officedesk-plugin-email view-thread --mailbox=INBOX --uid=1234

# Download attachments
officedesk-plugin-email download-attachments --mailbox=INBOX --uid=1234

# Move or trash reviewed messages safely
officedesk-plugin-email move-message --mailbox=INBOX --uid=1234 --destination=Finance --dry-run
officedesk-plugin-email trash-message --mailbox=INBOX --uid=1235 --dry-run
officedesk-plugin-email mark-message --mailbox=INBOX --uid=1234 --seen

# Compose a new email
officedesk-plugin-email compose-message --to=vendor@example.com --subject="Invoice attached" --body="Please find attached."

# Reply to a thread
officedesk-plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks, approved."
```

## Authentication

IMAP uses username + password (or an app password). There are no OAuth consent flows.

Run `officedesk-plugin-email configure` once to set credentials. They are written to:

```
$OFFICEDESK_HOME/plugins/plugin-email/.env
```

`OFFICEDESK_HOME` defaults to `~/.officedesk/`.

| Variable | Required | Default | Description |
|---|---|---|---|
| `IMAP_HOST` | ✓ | — | IMAP server hostname (e.g. `imap.gmail.com`) |
| `IMAP_PORT` | — | 993 | IMAP port |
| `IMAP_SECURE` | — | `true` when port=993 | Use TLS (`true`/`false`) |
| `IMAP_USERNAME` | ✓ | — | Your email address |
| `IMAP_PASSWORD` | ✓ | — | Password or app password |
| `IMAP_DEFAULT_MAILBOX` | — | *(all)* | Restrict search to one mailbox by default |
| `IMAP_TLS_REJECT_UNAUTHORIZED` | — | `true` | Set to `false` for self-signed certificates |

Optional SMTP variables for `reply-thread` and `compose-message`:

| Variable | Required | Default | Description |
|---|---|---|---|
| `SMTP_HOST` | — | provider-specific auto-detect | SMTP hostname |
| `SMTP_PORT` | — | inferred from provider or `587` | SMTP port |
| `SMTP_SECURE` | — | inferred from provider or port | Implicit TLS (`true`) vs STARTTLS (`false`) |
| `SMTP_USERNAME` | — | `IMAP_USERNAME` | SMTP login user |
| `SMTP_PASSWORD` | — | `IMAP_PASSWORD` | SMTP login password |
| `SMTP_FROM_ADDRESS` | — | `SMTP_USERNAME` | From address on replies |
| `SMTP_FROM_NAME` | — | — | Optional display name |
| `SMTP_TLS_REJECT_UNAUTHORIZED` | — | `true` | Set to `false` for self-signed SMTP certificates |
| `SENT_MAILBOX_APPEND_ENABLED` | — | `true` | Append the outbound MIME message to Sent after SMTP success |
| `SENT_MAILBOX_NAME` | — | — | Sent mailbox override when auto-resolution is ambiguous |

When `reply-thread` or `compose-message` sends mail, the plugin builds one final MIME payload, sends it over SMTP, then appends the same bytes into the IMAP Sent mailbox. If SMTP succeeds but the append fails, `error.code = "SENT_APPEND_FAILED"` is surfaced.

> **⚠ Port 465 is SMTPS (outbound email sending), not IMAP.** IMAP-over-TLS uses port **993**. If you see "Failed to receive greeting from server", check your port first.

### Provider notes

| Provider | Host | Port | Notes |
|---|---|---|---|
| Gmail | `imap.gmail.com` | 993 | Enable IMAP and use an [App Password](https://support.google.com/accounts/answer/185833) |
| Outlook / Office 365 | `outlook.office365.com` | 993 | Use `IMAP_SECURE=true`; enable IMAP in Outlook settings |
| iCloud | `imap.mail.me.com` | 993 | Requires an [app-specific password](https://support.apple.com/en-gb/102654) |
| Generic / self-hosted | varies | 993 / 143 | TLS on 993, STARTTLS on 143 |

## Commands

### `list-mailboxes`

List all selectable IMAP mailboxes with delimiter, attributes, and special-use hints.

```bash
officedesk-plugin-email list-mailboxes
```

#### Output

```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "name": "INBOX",
      "path": "INBOX",
      "delimiter": "/",
      "attributes": [],
      "selectable": true,
      "specialUse": "Inbox"
    },
    {
      "name": "Trash",
      "path": "Trash",
      "delimiter": "/",
      "attributes": ["\\Trash"],
      "selectable": true,
      "specialUse": "Trash"
    }
  ],
  "meta": {
    "account": "ops@example.com",
    "selectableCount": 2,
    "nonSelectableCount": 0
  }
}
```

### `create-mailbox`

Create a new mailbox folder, with dry-run support.

```bash
officedesk-plugin-email create-mailbox --name=Finance --dry-run
officedesk-plugin-email create-mailbox --name=Finance
officedesk-plugin-email create-mailbox --parent=Projects --name=2026 --dry-run
officedesk-plugin-email create-mailbox --name="Projects/2026" --dry-run
```

| Option | Required | Description |
|---|---|---|
| `--name=NAME` | ✓ | Mailbox name or hierarchical path to create |
| `--parent=NAME` | — | Existing parent mailbox path |
| `--dry-run` | — | Validate without creating |

### `search-messages`

Search messages across all mailboxes using Gmail-style operators.

```bash
officedesk-plugin-email search-messages --query="from:billing@acme.com has:attachment"
officedesk-plugin-email search-messages --query="subject:invoice" --mailbox=INBOX --max=50
```

| Option | Description | Default |
|---|---|---|
| `--query=TEXT` | Gmail-style query string | *(all messages)* |
| `--max=N` | Maximum subject groups returned | 100 |
| `--mailbox=NAME` | Restrict to a mailbox | all (except Drafts, Spam, Trash) |
| `--max-per-mailbox=N` | Candidate cap per mailbox | 50 |
| `--save-cache` | Write grouped results to `cache/search-results.json` | disabled |

#### Supported query operators

| Operator | Example | IMAP mapping |
|---|---|---|
| `from:<address>` | `from:billing@acme.com` | Server-side `FROM` |
| `to:<address>` | `to:ops@acme.com` | Server-side `TO` |
| `subject:<phrase>` | `subject:"Purchase Order"` | Server-side `SUBJECT` |
| `after:YYYY/MM/DD` | `after:2024/01/01` | Server-side `SINCE` |
| `before:YYYY/MM/DD` | `before:2024/06/30` | Server-side `BEFORE` |
| `is:unread` | `is:unread` | Server-side `UNSEEN` flag |
| `has:attachment` | `has:attachment` | Client-side (MIME structure check) |
| *(free text)* | `overdue invoice` | Server-side `TEXT` |

### `download-attachments`

Download all attachments from a specific message identified by mailbox + IMAP UID.

```bash
officedesk-plugin-email download-attachments --mailbox=INBOX --uid=1234
officedesk-plugin-email download-attachments --mailbox=INBOX --uid=1234 --output=downloads/invoices
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Mailbox path |
| `--uid=N` | ✓ | IMAP UID of the message |
| `--output=DIR` | — | Base directory; files saved to `DIR/<uid>/` (default: `downloads/plugin-email/<uid>/`) |

Uses `BODY.PEEK` semantics — reading does **not** mark the message as `\Seen`.

### `view-thread`

Display every message in the same conversation as a seed message.

```bash
officedesk-plugin-email view-thread --mailbox=INBOX --uid=1234
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Mailbox containing the seed message |
| `--uid=N` | ✓ | IMAP UID of the seed message |

### `compose-message`

Compose and send a fresh outbound email.

```bash
officedesk-plugin-email compose-message --to=support@example.com --subject="Urgent request" --body="Please respond." --dry-run
officedesk-plugin-email compose-message --to=vendor@example.com --subject="Invoice attached" --body="Please find attached." --attachment=./invoice.pdf
```

| Option | Required | Description |
|---|---|---|
| `--to=EMAIL` | ✓ | Primary recipient; repeat or comma-separate values |
| `--subject=TEXT` | ✓ | Email subject line |
| `--body=TEXT` | ✓* | Plain-text body |
| `--body-file=PATH` | ✓* | Read plain-text body from a file |
| `--cc=EMAIL` | — | CC recipients |
| `--bcc=EMAIL` | — | BCC recipients |
| `--html=HTML` | — | HTML body |
| `--html-file=PATH` | — | Read HTML body from a file |
| `--signature=TEXT` | — | Append a plain-text signature |
| `--signature-file=PATH` | — | Read signature from a file |
| `--attachment=PATH` | — | Attach a file; repeat for multiple |
| `--dry-run` | — | Build the payload without sending |

`*` Provide either `--body` or `--body-file`.

### `reply-thread`

Reply to a thread using a seed message identified by mailbox + IMAP UID.

```bash
officedesk-plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks, approved."
officedesk-plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Draft reply" --dry-run
officedesk-plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="See attached." --attachments=./invoice.pdf
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Mailbox containing the seed message |
| `--uid=N` | ✓ | IMAP UID of the seed message |
| `--body=TEXT` | ✓* | Reply body |
| `--body-file=PATH` | ✓* | Read reply body from a file |
| `--html=HTML` | — | HTML reply body |
| `--html-file=PATH` | — | Read HTML reply body from a file |
| `--signature=TEXT` | — | Append a plain-text signature |
| `--signature-file=PATH` | — | Read signature from a file |
| `--reply-all` | — | Include original thread recipients |
| `--attachment=PATH` | — | Attach a file; repeat for multiple |
| `--quote-original=false` | — | Skip quoting the seed message |
| `--dry-run` | — | Build the reply without sending |

`*` Provide either `--body` or `--body-file`.

### `move-message`

Move a message from one mailbox to another.

```bash
officedesk-plugin-email move-message --mailbox=INBOX --uid=5676 --destination=Finance --dry-run
officedesk-plugin-email move-message --mailbox=INBOX --uid=5676 --destination=Finance
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Source mailbox path |
| `--uid=N` | ✓ | IMAP UID of the source message |
| `--destination=NAME` | ✓ | Destination mailbox path or display name |
| `--dry-run` | — | Validate without modifying mail |

### `trash-message`

Move a message into Trash.

```bash
officedesk-plugin-email trash-message --mailbox=INBOX --uid=5590 --dry-run
officedesk-plugin-email trash-message --mailbox=INBOX --uid=5590
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Source mailbox path |
| `--uid=N` | ✓ | IMAP UID of the message |
| `--trash-mailbox=NAME` | — | Override Trash mailbox discovery |
| `--dry-run` | — | Validate without modifying mail |

### `delete-message`

Permanently delete a message. Requires explicit confirmation.

```bash
officedesk-plugin-email delete-message --mailbox=Trash --uid=991 --expunge
officedesk-plugin-email delete-message --mailbox=Trash --uid=991 --confirm-permanent-delete --dry-run
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Mailbox containing the message |
| `--uid=N` | ✓ | IMAP UID of the message |
| `--expunge` | ✓* | Explicitly confirm permanent deletion |
| `--confirm-permanent-delete` | ✓* | Verbose confirmation alias |
| `--dry-run` | — | Validate without modifying mail |

`*` Pass either flag. Regular housekeeping should use `trash-message`, not `delete-message`.

### `mark-message`

Update common IMAP flags.

```bash
officedesk-plugin-email mark-message --mailbox=INBOX --uid=5653 --seen
officedesk-plugin-email mark-message --mailbox=INBOX --uid=2240 --flagged
officedesk-plugin-email mark-message --mailbox=INBOX --uid=5653 --unseen --dry-run
```

| Option | Required | Description |
|---|---|---|
| `--mailbox=NAME` | ✓ | Mailbox containing the message |
| `--uid=N` | ✓ | IMAP UID of the message |
| `--seen` | ✓** | Add `\Seen` |
| `--unseen` | ✓** | Remove `\Seen` |
| `--flagged` | ✓** | Add `\Flagged` |
| `--unflagged` | ✓** | Remove `\Flagged` |
| `--dry-run` | — | Return projected flag state without updating |

`**` Pass exactly one flag operation.

### `apply-mailbox-plan`

Validate and execute a reviewed bulk housekeeping plan from JSON.

```bash
officedesk-plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json --dry-run
officedesk-plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json
```

Supported v1 actions: `move`, `trash`, `markSeen`, `markFlagged`.

```json
{
  "account": "ops@example.com",
  "actions": [
    { "action": "trash", "mailbox": "INBOX", "uid": 5590, "reason": "newsletter" },
    { "action": "move", "mailbox": "INBOX", "uid": 5676, "destination": "Finance", "reason": "bank alert" },
    { "action": "markSeen", "mailbox": "INBOX", "uid": 2240, "reason": "reviewed manually" }
  ]
}
```

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for credentials and config (default: `~/.officedesk/`) |

## License

ISC
