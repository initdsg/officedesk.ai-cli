# plugin-email Agent Tutorial

This tutorial is written for an AI agent that needs to operate `plugin-email` safely and predictably from the repo root using the `officedesk` binary from the shell `PATH`.

## Goal

Use `plugin-email` to:

- configure IMAP and SMTP credentials
- discover available destination folders before moving mail
- create a destination folder when housekeeping needs a new mailbox
- search for relevant messages
- inspect an email conversation in context
- download attachments from a specific message
- compose and send a fresh outbound email
- move important mail out of `INBOX`
- move junk mail to Trash instead of deleting it permanently
- mark reviewed mail as read or flagged
- apply a reviewed cleanup plan in bulk
- prepare or send a reply to a thread

## Preferred Invocation

From the workspace root, invoke the master CLI directly and delegate to `plugin-email`:

```bash
officedesk plugin-email configure
officedesk plugin-email list-mailboxes
officedesk plugin-email create-mailbox --name=Finance --dry-run
officedesk plugin-email search-messages --query="from:billing@acme.com"
officedesk plugin-email view-thread --mailbox=INBOX --uid=1234
officedesk plugin-email download-attachments --mailbox=INBOX --uid=1234
officedesk plugin-email compose-message --to=vendor@example.com --subject="Invoice attached" --body="Please find attached."
officedesk plugin-email move-message --mailbox=INBOX --uid=1234 --destination=Finance --dry-run
officedesk plugin-email trash-message --mailbox=INBOX --uid=1235 --dry-run
officedesk plugin-email mark-message --mailbox=INBOX --uid=1234 --seen
officedesk plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json --dry-run
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks"
officedesk plugin-email configure
officedesk plugin-email list-mailboxes
officedesk plugin-email create-mailbox --name=Finance --dry-run
officedesk plugin-email search-messages --query="from:billing@acme.com"
officedesk plugin-email view-thread --mailbox=INBOX --uid=1234
officedesk plugin-email download-attachments --mailbox=INBOX --uid=1234
officedesk plugin-email compose-message --to=vendor@example.com --subject="Invoice attached" --body="Please find attached."
officedesk plugin-email move-message --mailbox=INBOX --uid=1234 --destination=Finance --dry-run
officedesk plugin-email trash-message --mailbox=INBOX --uid=1235 --dry-run
officedesk plugin-email mark-message --mailbox=INBOX --uid=1234 --seen
officedesk plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json --dry-run
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks"
```

Assume `officedesk` is already installed or otherwise available on the shell `PATH`.

Set `OFFICEDESK_HOME=$PWD` when you want plugin state, downloads, caches, and config files to stay inside the current workspace.

The delegated command shape is always:

```bash
officedesk plugin-email <command> [args]
```

In this tutorial, all examples use `officedesk plugin-email ...`.

## Flag Syntax

All flags accept both `--flag=value` and `--flag value` forms interchangeably. `-h` is a short form for `--help`.

## Core Rules

1. Treat `mailbox` + `uid` as the stable identifier for a specific message.
2. Use `search-messages` to discover candidate messages, then carry forward the exact `mailbox` and `uid` into other commands.
3. Run `list-mailboxes` before moving mail unless you already know the destination folder exists.
4. Use `create-mailbox --dry-run` before creating a new destination folder unless the user explicitly wants immediate mailbox creation.
5. Use `view-thread` before replying when context matters.
6. Use `--dry-run` first for `move-message`, `trash-message`, `apply-mailbox-plan`, `compose-message`, and `reply-thread` unless the user explicitly wants immediate execution.
7. Default housekeeping to moving messages to Trash, not permanent deletion.
8. Do not assume Drafts, Spam/Junk, or Trash are searched by default. Pass `--mailbox` explicitly when those folders matter.
9. Expect JSON output. Parse `data` for results and `meta` for execution context.
10. After a live `compose-message` or `reply-thread` send succeeds, expect the plugin to append the exact outbound MIME payload to `Sent`; `compose-message` treats that Sent copy as required.

## Command Selection

| Need | Command |
|---|---|
| Set up credentials | `configure` |
| Discover destination folders | `list-mailboxes` |
| Create a destination folder | `create-mailbox` |
| Find candidate emails | `search-messages` |
| Read the full conversation around one message | `view-thread` |
| Save files attached to one message | `download-attachments` |
| Compose and send a new email | `compose-message` |
| Move one reviewed message | `move-message` |
| Move one message to Trash | `trash-message` |
| Mark a message read or flagged | `mark-message` |
| Apply a reviewed cleanup plan | `apply-mailbox-plan` |
| Draft or send a reply | `reply-thread` |

## 1. Configure

Use `configure` when credentials are missing or the plugin has not been set up yet.

```bash
officedesk plugin-email configure
```

What it does:

- prompts for IMAP connection settings
- optionally prompts for SMTP settings used by `reply-thread` and `compose-message`
- writes configuration to `$OFFICEDESK_HOME/plugins/plugin-email/.env`

What an agent should know:

- IMAP usually uses port `993` with TLS
- SMTP port `465` is valid for sending mail, but not for IMAP
- if SMTP settings are omitted, outbound email commands try to infer them for common providers

Common required variables:

- `IMAP_HOST`
- `IMAP_USERNAME`
- `IMAP_PASSWORD`

Optional but important for outbound email:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_FROM_ADDRESS`

Optional Sent append controls:

- `SENT_MAILBOX_APPEND_ENABLED`
- `SENT_MAILBOX_NAME`

## 2. Search Messages

Use `search-messages` to locate candidate emails across one mailbox or many mailboxes.

```bash
officedesk plugin-email search-messages --query="from:billing@acme.com has:attachment"
```

Useful options:

- `--query=TEXT`
- `--mailbox=NAME`
- `--max=N`
- `--max-per-mailbox=N`
- `--save-cache`

Useful query operators:

- `from:<address>`
- `to:<address>`
- `subject:<phrase>`
- `after:YYYY/MM/DD`
- `before:YYYY/MM/DD`
- `is:unread`
- `has:attachment`
- free text such as `invoice overdue`

Important behavior:

- results are grouped by exact subject line
- each subject group contains one or more messages
- each message includes `mailbox` and `uid`, which you need for follow-up commands
- default broad search excludes Drafts, Spam/Junk, and Trash

Example workflow:

```bash
officedesk plugin-email search-messages --query="subject:\"Invoice 042\" has:attachment" --max=10
```

What to extract from the JSON:

- `data[].subject`
- `data[].messages[].mailbox`
- `data[].messages[].uid`
- `data[].messages[].attachments`
- `data[].messages[].date`

When to use it:

- the user asks for an email by sender, subject, attachment, or timeframe
- you need the `uid` before downloading or replying

When not to rely on it alone:

- when you need the full conversation and not just one matching message

## 3. View Thread

Use `view-thread` once you already know one message in the conversation.

```bash
officedesk plugin-email view-thread --mailbox=INBOX --uid=1234
```

You can restrict the scan to known folders:

```bash
officedesk plugin-email view-thread --mailbox=INBOX --uid=1234 --mailbox=INBOX --mailbox="Sent Items"
```

What it does:

- loads the seed message identified by `mailbox` and `uid`
- finds related messages using thread ID when available
- falls back to `Message-ID`, `In-Reply-To`, and normalized subject matching
- returns the full decoded body for each matched message

What an agent should inspect:

- `data[].isSeedMessage`
- `data[].from`
- `data[].to`
- `data[].date`
- `data[].body`
- `data[].attachments`
- `meta.matchStrategy`
- `meta.mailboxesSearched`

When to use it:

- before drafting a reply
- when the user asks for the entire thread
- when a subject search returned too many similarly named messages

## 4. Download Attachments

Use `download-attachments` when you already know which message contains the files you need.

```bash
officedesk plugin-email download-attachments --mailbox=INBOX --uid=1234
```

Optional custom output directory:

```bash
officedesk plugin-email download-attachments --mailbox=INBOX --uid=1234 --output=/tmp/email-files
```

What it does:

- fetches the MIME structure for the target message
- downloads every attachment from that one message
- saves files under `downloads/plugin-email/<uid>/` by default

What an agent should extract:

- `data[].filename`
- `data[].mimeType`
- `data[].size`
- `data[].filePath`

Important limitation:

- this command downloads attachments for one message only, not for an entire thread

Recommended sequence:

1. run `search-messages` or `view-thread`
2. choose the exact message containing the attachment
3. run `download-attachments` with that `mailbox` and `uid`

## 5. Reply Thread

## 5A. Compose Message

Use `compose-message` when you need to send a brand new email and there is no existing thread to anchor a reply.

Dry-run first:

```bash
officedesk plugin-email compose-message --to=support@mishu.my --subject="Urgent request" --body="Please respond." --dry-run
```

Send for real:

```bash
officedesk plugin-email compose-message --to=support@mishu.my --subject="Urgent request" --body-file=letter.txt --html-file=letter.html
```

With signatures, inline assets, and file attachments:

```bash
officedesk plugin-email compose-message --to=vendor@example.com --cc=finance@example.com --subject="Invoice attached" --body-file=letter.txt --html-file=letter.html --signature-file=signature.txt --signature-html-file=signature.html --inline-cid=logo=./assets/logo.png --attachment=./invoice.pdf --dry-run
```

Useful options:

- `--to=EMAIL`
- `--subject=TEXT`
- `--body=TEXT`
- `--body-file=PATH`
- `--cc=EMAIL`
- `--bcc=EMAIL`
- `--html=HTML`
- `--html-file=PATH`
- `--signature=TEXT`
- `--signature-file=PATH`
- `--signature-html=HTML`
- `--signature-html-file=PATH`
- `--inline-cid=CID=PATH`
- `--attachment=PATH`
- `--from=EMAIL`
- `--from-name=TEXT`
- `--dry-run`

What dry run does:

- builds the final plain-text and optional HTML body
- appends explicit or env-backed signatures
- includes inline CID assets and file attachments in the preview
- generates the final MIME payload and `Message-ID`
- does not create an SMTP transport
- does not deliver mail
- does not append anything to `Sent`

For live sends, `compose-message` requires `SENT_MAILBOX_APPEND_ENABLED=true`. If SMTP delivery succeeds but the Sent append fails, the command returns failure so you know the Sent copy was not created.

Use `reply-thread` to respond to the conversation anchored by one seed message.

Dry-run first:

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Draft reply" --dry-run
```

Send for real:

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks, approved."
```

Reply all with extra recipients:

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Looping in finance." --reply-all --cc=finance@example.com
```

HTML reply with an inline CID image:

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --html-file=reply.html --inline-cid=logo=./assets/logo.png --dry-run
```

Reply with a regular file attachment:

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Please see attached." --attachments=./files/invoice.pdf --dry-run
```

Reply with reusable signature files:

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --signature-file=signature.txt --signature-html-file=signature.html --html-file=reply.html --dry-run
```

Useful options:

- `--body=TEXT`
- `--body-file=PATH`
- `--html=HTML`
- `--html-file=PATH`
- `--signature=TEXT`
- `--signature-file=PATH`
- `--signature-html=HTML`
- `--signature-html-file=PATH`
- `--subject=TEXT`
- `--reply-all`
- `--to=EMAIL`
- `--cc=EMAIL`
- `--bcc=EMAIL`
- `--inline-cid=CID=PATH`
- `--attachment=PATH`
- `--attachments=PATH`
- `--quote-original=false`
- `--dry-run`

How recipients are chosen:

1. If `--to` is provided, it overrides derived primary recipients.
2. If `--reply-all` is set, the plugin includes the original reply target plus original `To` and `Cc` recipients, excluding the configured sender identity.
3. `--cc` and `--bcc` append explicit secondary recipients.

What dry run does:

- resolves recipients
- computes the final subject
- builds the quoted reply body
- builds the optional HTML reply body
- appends explicit or env-backed signatures before quoting
- fills `In-Reply-To` and `References`
- includes inline CID image attachments when requested
- includes regular file attachments when requested
- returns the exact payload preview
- does not create an SMTP transport
- does not deliver mail
- does not append anything to `Sent`

When the seed message has an HTML body, the quoted HTML section reuses that original HTML body. If that quoted original HTML references inline CID assets, the plugin reattaches those original inline parts and remaps their CIDs to avoid colliding with any new inline assets in your reply.

What an agent should inspect in dry run output:

- `data.from`
- `data.to`
- `data.cc`
- `data.bcc`
- `data.subject`
- `data.text`
- `data.html`
- `data.inReplyTo`
- `data.references`
- `data.inlineAttachments`
- `data.dryRun`

When inspecting `data.inlineAttachments`, distinguish:

- explicit assets you passed with `--inline-cid`, which show `source: explicit`
- quoted original assets copied from the seed message, which show `source: quoted-original`

Quoted original assets may also include a remapped CID such as `quoted-original-logo` plus the original MIME `partId` that was copied from the source message.

Recommended sending policy:

1. Run `view-thread` first if the user has not already supplied enough context.
2. Run `reply-thread --dry-run`.
3. Show or summarize the draft for approval when the user has not explicitly authorized sending.
4. Re-run `reply-thread` without `--dry-run` only after approval.
5. Inspect `data.smtp` and `data.sentMailboxAppend` in the live JSON response to confirm both delivery and Sent visibility.

Sent append behavior after a live send:

- the plugin sends the final raw MIME payload via SMTP
- if SMTP succeeds, it resolves `Sent` using IMAP special-use first, then exact `Sent`, then `SENT_MAILBOX_NAME` when configured
- it appends the same raw MIME payload to that mailbox
- `data.sentMailboxAppend.uid` is `null` when the server does not expose an append UID
- if SMTP succeeds but append fails, `success` becomes `false` with `error.code: SENT_APPEND_FAILED`

## 6. List Mailboxes

Use `list-mailboxes` before housekeeping so you do not hardcode folder names.

```bash
officedesk plugin-email list-mailboxes
```

What it does:

- lists all selectable IMAP mailboxes
- includes delimiter and mailbox attributes
- includes special-use hints such as `Inbox`, `Trash`, `Archive`, `Sent`, `Drafts`, or `Junk` when the server provides them

What an agent should inspect:

- `data[].path`
- `data[].name`
- `data[].delimiter`
- `data[].attributes`
- `data[].selectable`
- `data[].specialUse`

Use it when:

- choosing a destination folder for `move-message`
- deciding whether you need to run `create-mailbox`
- verifying the Trash mailbox before `trash-message`
- validating folders referenced by a bulk cleanup plan

## 7. Create Mailbox

Use `create-mailbox` when the destination folder does not exist yet.

Dry-run first:

```bash
officedesk plugin-email create-mailbox --name=Finance --dry-run
```

Create for real:

```bash
officedesk plugin-email create-mailbox --name=Finance
```

Create a child mailbox under an existing parent:

```bash
officedesk plugin-email create-mailbox --parent=Projects --name=2026 --dry-run
officedesk plugin-email create-mailbox --name="Projects/2026" --dry-run
```

What it does:

- validates the mailbox path before creating it
- rejects empty mailbox names and empty path segments
- rejects the reserved mailbox segment `INBOX`
- requires the parent mailbox to already exist for hierarchical creates
- refreshes mailbox inventory after creation so the returned path matches the server

What an agent should inspect:

- `data.name`
- `data.path`
- `data.delimiter`
- `data.selectable`
- `data.operation`
- `data.mode`

When to use it:

- before `move-message` when the reviewed destination mailbox does not exist
- when a housekeeping workflow needs folders such as `Finance`, `Compliance`, `Internal`, `Vendors`, or `Reference`

## 8. Move Message

Use `move-message` to relocate one reviewed message from its source mailbox into a specific destination mailbox.

Dry-run first:

```bash
officedesk plugin-email move-message --mailbox=INBOX --uid=5676 --destination=Finance --dry-run
```

Apply for real:

```bash
officedesk plugin-email move-message --mailbox=INBOX --uid=5676 --destination=Finance
```

What it does:

- verifies the source message exists
- verifies the destination mailbox exists
- prefers IMAP `MOVE`
- falls back to copy plus delete only when that can be done without expunging unrelated deleted messages
- returns the destination mailbox and destination UID when the server exposes one
- returns `data.destination.uid = null` when the server does not expose a destination UID

What an agent should inspect:

- `data.source.mailbox`
- `data.source.uid`
- `data.destination.mailbox`
- `data.destination.uid`
- `meta.usedMoveExtension`

## 9. Trash Message

Use `trash-message` when housekeeping should stay reversible.

```bash
officedesk plugin-email trash-message --mailbox=INBOX --uid=5590 --dry-run
officedesk plugin-email trash-message --mailbox=INBOX --uid=5590
```

Optional explicit Trash override:

```bash
officedesk plugin-email trash-message --mailbox=INBOX --uid=5590 --trash-mailbox="Deleted Items"
```

Important behavior:

- resolves Trash from special-use hints when possible
- falls back to common names such as `Trash`, `Deleted Items`, or `Bin`
- requires `--trash-mailbox` when Trash cannot be inferred safely
- returns the destination Trash mailbox and destination UID when available
- returns `data.destination.uid = null` when the server does not expose a destination UID

## 10. Mark Message

Use `mark-message` after review.

```bash
officedesk plugin-email mark-message --mailbox=INBOX --uid=5653 --seen
officedesk plugin-email mark-message --mailbox=INBOX --uid=2240 --flagged
officedesk plugin-email mark-message --mailbox=INBOX --uid=5653 --unseen --dry-run
```

Supported state changes:

- `--seen`
- `--unseen`
- `--flagged`
- `--unflagged`

What an agent should inspect:

- `data.flags`
- `data.isSeen`
- `data.isFlagged`

## 11. Apply Mailbox Plan

Use `apply-mailbox-plan` when you already have a reviewed JSON cleanup plan.

```bash
officedesk plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json --dry-run
officedesk plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json
```

Optional runtime behavior:

- `--continue-on-error`
- `--trash-mailbox=NAME`

Supported plan actions in v1:

- `move`
- `trash`
- `markSeen`
- `markFlagged`

What it does:

- validates the full plan before applying anything
- verifies mailbox names and source UIDs up front
- rejects duplicate source identifiers in the plan
- returns per-action status on dry run and live execution

Recommended sequence:

1. run `search-messages` and optionally `view-thread`
2. build a plan file for the messages you reviewed
3. run `apply-mailbox-plan --dry-run`
4. inspect the returned per-action results
5. run `apply-mailbox-plan` only after approval

## 12. Delete Message

Use `delete-message` only for explicit permanent deletion.

```bash
officedesk plugin-email delete-message --mailbox=Trash --uid=991 --expunge
```

Rules:

- this is not the default housekeeping path
- require `--expunge` or `--confirm-permanent-delete`
- prefer `trash-message` unless the user clearly requested irreversible deletion

## End-to-End Workflows

### Find an invoice email and inspect the thread

```bash
officedesk plugin-email search-messages --query="from:billing@acme.com subject:invoice has:attachment" --max=5
officedesk plugin-email view-thread --mailbox=INBOX --uid=1234
```

### Download a PDF from a discovered message

```bash
officedesk plugin-email search-messages --query="subject:\"Invoice 042\" has:attachment"
officedesk plugin-email download-attachments --mailbox=INBOX --uid=1234
```

### Draft a reply with review before sending

```bash
officedesk plugin-email view-thread --mailbox=INBOX --uid=1234
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks, approved." --dry-run
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body="Thanks, approved."
```

### Draft a branded HTML reply with an inline logo

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --html-file=reply.html --inline-cid=logo=./assets/logo.png --dry-run
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --html-file=reply.html --inline-cid=logo=./assets/logo.png
```

### Draft a branded HTML reply with reusable signature files

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --html-file=reply.html --signature-file=signature.txt --signature-html-file=signature.html --inline-cid=logo=./assets/logo.png --dry-run
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --html-file=reply.html --signature-file=signature.txt --signature-html-file=signature.html --inline-cid=logo=./assets/logo.png
```

### Draft a reply that preserves quoted original inline CID assets

Use this when the seed message already contains inline HTML images and your new reply also includes its own inline CID assets.

```bash
officedesk plugin-email reply-thread --mailbox=INBOX --uid=1234 --body-file=reply.txt --html-file=reply.html --inline-cid=logo=./assets/new-logo.png --dry-run
```

What to look for in the dry-run output:

- your new inline asset remains on the CID you chose, for example `logo`
- copied quoted-original assets are reattached automatically
- copied quoted-original assets use remapped CIDs such as `quoted-original-logo`
- copied quoted-original assets appear in `data.inlineAttachments` with `source: quoted-original`

### Move UOB alerts and invoices into Finance with review first

```bash
officedesk plugin-email list-mailboxes
officedesk plugin-email create-mailbox --name=Finance --dry-run
officedesk plugin-email search-messages --mailbox=INBOX --query="from:no-reply@uobgroup.com"
officedesk plugin-email move-message --mailbox=INBOX --uid=5676 --destination=Finance --dry-run
officedesk plugin-email move-message --mailbox=INBOX --uid=5676 --destination=Finance
```

### Trash newsletter-style mail safely

```bash
officedesk plugin-email search-messages --mailbox=INBOX --query="subject:webinar"
officedesk plugin-email trash-message --mailbox=INBOX --uid=5590 --dry-run
officedesk plugin-email trash-message --mailbox=INBOX --uid=5590
```

### Dry-run a mixed cleanup plan

```bash
officedesk plugin-email apply-mailbox-plan --plan-file=cleanup-plan.json --dry-run
```

### Flag an application email for manual follow-up

```bash
officedesk plugin-email mark-message --mailbox=INBOX --uid=2240 --flagged
```

## Failure Handling

If a command fails, inspect the error and apply the likely fix.

| Symptom | Likely Cause | Agent Response |
|---|---|---|
| Missing required IMAP credentials | Plugin not configured | Run `configure` or request credentials |
| IMAP greeting or timeout failure on port `465` | Wrong protocol/port | Switch IMAP to `993` or `143` as appropriate |
| Message UID not found | Wrong mailbox or stale UID | Re-run `search-messages` and carry forward the exact mailbox |
| Parent mailbox not found during create | Hierarchical target folder does not exist yet | Create the parent first or use an existing parent mailbox |
| Destination mailbox not found | Folder name mismatch | Run `list-mailboxes` and retry with the exact path |
| Trash mailbox could not be inferred | Server did not expose a usable Trash folder | Re-run with `--trash-mailbox=<name>` |
| Move fallback refused due to existing `\Deleted` mail | Server lacks `MOVE` and `UIDPLUS`, so expunge would remove unrelated mail | Use a mailbox with no other deleted messages or move manually in smaller controlled steps |
| No recipients could be determined for reply | Seed message lacks usable reply targets | Provide explicit `--to` |
| Search missed Spam or Trash | Default exclusion behavior | Re-run with explicit `--mailbox` |

## Minimal Decision Tree

1. Need credentials or connection setup: run `configure`.
2. Need to know which folders exist: run `list-mailboxes`.
3. Need to create a missing destination folder: run `create-mailbox --dry-run`, then `create-mailbox`.
4. Need to find an email: run `search-messages`.
5. Need full context around one message: run `view-thread`.
6. Need files from one message: run `download-attachments`.
7. Need to move reviewed mail: run `move-message --dry-run`, then `move-message`.
8. Need reversible cleanup: run `trash-message --dry-run`, then `trash-message`.
9. Need to mark review state: run `mark-message`.
10. Need to apply many reviewed actions: run `apply-mailbox-plan --dry-run`, then `apply-mailbox-plan`.
11. Need to respond: run `reply-thread --dry-run`, then `reply-thread`, then verify `data.sentMailboxAppend`.

## Recommended Agent Defaults

1. Prefer narrow searches over scanning every mailbox.
2. Preserve exact `mailbox` and `uid` values from command output.
3. Run `list-mailboxes` before moving mail into a new destination folder.
4. Run `create-mailbox --dry-run` when the reviewed destination mailbox does not exist yet.
5. Use `view-thread` before replying to avoid context loss.
6. Default to `--dry-run` for autonomous workflows.
7. Treat Trash as the default cleanup target; reserve permanent delete for explicit approval.
8. Treat SMTP delivery as a separate approval step unless the user clearly asked to send immediately.