# plugin-xero Agent Tutorial

This tutorial is written for an AI agent that needs to operate `plugin-xero` safely and predictably from the repo root using the `officedesk` binary from the shell `PATH`.

## Goal

Use `plugin-xero` to:

- authenticate against Xero and refresh tenant access
- fetch reference data before accounting writes
- inspect bank transactions before reconciliation work
- create or update Xero accounts and contacts
- reconcile bank transactions with validated accounting inputs
- list invoice branding themes before drafting invoices
- create draft accounts receivable invoices
- authorise draft invoices as a separate accounting step
- send authorised invoices to the customer as a separate delivery step
- download the rendered invoice PDF for external delivery workflows
- list and download uploaded invoice attachments

## Preferred Invocation

From the workspace root, invoke the master CLI directly and delegate to `plugin-xero`:

```bash
officedesk plugin-xero login
officedesk plugin-xero get-accounts
officedesk plugin-xero get-contacts
officedesk plugin-xero get-tax-rates
officedesk plugin-xero get-branding-themes
officedesk plugin-xero get-bank-transactions --account="Main Bank" --unreconciled
officedesk plugin-xero create-account --code=200 --name="Sales" --type=REVENUE --taxType=OUTPUT
officedesk plugin-xero create-contact "Acme Pte Ltd"
officedesk plugin-xero update-contact --contactId=<contact-id> --email=accounts@example.com --phone="+65 6000 0000"
officedesk plugin-xero update-account --accountId=<account-id> --taxType=OUTPUT
officedesk plugin-xero reconcile --file=uploads/reconcile.json
officedesk plugin-xero draft-invoice --file=uploads/draft-invoice.json
officedesk plugin-xero update-invoice --invoiceId=<invoice-id> --reference=INV-001-REV1
officedesk plugin-xero authorise-invoice --invoiceId=<invoice-id>
officedesk plugin-xero delete-invoice --invoiceId=<invoice-id>
officedesk plugin-xero send-invoice --invoiceId=<invoice-id>
officedesk plugin-xero download-invoice-pdf --invoiceId=<invoice-id>
officedesk plugin-xero list-invoice-attachments --invoiceId=<invoice-id>
officedesk plugin-xero download-invoice-attachment --invoiceId=<invoice-id> --attachmentId=<attachment-id>
```

Assume `officedesk` is already installed or otherwise available on the shell `PATH`.

Set `OFFICEDESK_HOME=$PWD` when you want plugin state, token files, downloads, caches, and config files to stay inside the current workspace.

The delegated command shape is always:

```bash
officedesk plugin-xero <command> [args]
```

In this tutorial, all examples use `officedesk plugin-xero ...`.

## Flag Syntax

All flags accept both `--flag=value` and `--flag value` forms interchangeably. `-h` is a short form for `--help`.

Commands that accept `--file` also accept `-f` as a short form. Pass `--file -` or `-f -` to read the JSON payload from stdin. This is useful with a heredoc or a pipe:

```bash
# Heredoc
officedesk plugin-xero draft-bill --file - << 'EOF'
{
  "contactId": "fa7121d0-80b6-402f-beb5-d6533fc1cc1a",
  "date": "2026-05-06",
  "dueDate": "2026-06-05",
  "lineItems": [
    { "description": "Consulting", "quantity": 1, "unitAmount": 1200, "accountCode": "400", "taxType": "INPUT" }
  ]
}
EOF

# Pipe
cat uploads/draft-invoice.json | officedesk plugin-xero draft-invoice -f -
```

## Core Rules

1. Read reference data before write operations unless you already have verified IDs and enum values.
2. Treat `contactId`, `accountId`, `accountCode`, `brandingThemeId`, and `invoiceId` as the stable identifiers you carry between commands.
3. Do not guess tax types, account codes, or contact IDs.
4. Use `get-contacts`, `get-accounts`, `get-tax-rates`, and `get-branding-themes` to validate input before creating transactions or invoices.
5. Treat `draft-invoice`, `authorise-invoice`, and `send-invoice` as three distinct stages.
6. Do not assume authorising an invoice sends it to the customer. It does not.
7. Prefer `--file` payloads for multi line invoices or any payload you may need to inspect or reuse.
8. Expect JSON output. Parse `data` for results and `meta` for execution context.
9. Assume write commands are live. There is no general dry run mode for Xero writes in this plugin.
10. Report the resulting `invoiceId` after drafting so later steps can reuse it safely.

## Command Selection

| Need | Command |
|---|---|
| Authenticate with Xero | `login` |
| Refresh cached accounts | `get-accounts` |
| Refresh cached contacts | `get-contacts` |
| Refresh cached tax rates | `get-tax-rates` |
| Discover invoice themes | `get-branding-themes` |
| Inspect bank transactions | `get-bank-transactions` |
| Create a chart of accounts entry | `create-account` |
| Create a contact | `create-contact` |
| Update a contact | `update-contact` |
| Update an account | `update-account` |
| Reconcile a bank transaction | `reconcile` |
| Create a draft invoice | `draft-invoice` |
| Update a draft invoice | `update-invoice` |
| Move a draft invoice to authorised | `authorise-invoice` |
| Delete a draft invoice | `delete-invoice` |
| Email an authorised invoice | `send-invoice` |
| Download the rendered invoice PDF | `download-invoice-pdf` |
| List uploaded invoice attachments | `list-invoice-attachments` |
| Download one uploaded invoice attachment | `download-invoice-attachment` |

## 1. Authenticate

Use `login` when tokens are missing, expired, or not yet created for the current workspace or runtime home.

```bash
officedesk plugin-xero login
```

What it does:

- starts the Xero OAuth flow
- stores the resulting token set under the plugin runtime files
- prepares future CLI commands to call the Accounting API

What an agent should know:

- the authenticated account must have access to at least one Xero tenant
- many handler failures with `No tenants found` are authentication or tenant access problems, not payload problems
- when state should remain inside the repo workspace, set `OFFICEDESK_HOME=$PWD`

## 2. Get Accounts

Use `get-accounts` before reconciliation or invoice work when you need a verified revenue, expense, or bank account code.

```bash
officedesk plugin-xero get-accounts
```

What it does:

- fetches the Chart of Accounts from Xero
- normalizes the response
- writes the local cache file
- prints a JSON envelope with the account list

What an agent should inspect:

- `data[].accountID`
- `data[].code`
- `data[].name`
- `data[].type`
- `data[].taxType`
- `data[].status`
- `meta.cacheFile`

Cache output:

```text
<plugin-cache-dir>/accounts.json
```

When to use it:

- before `reconcile`
- before `draft-invoice`
- before `create-account` if you need to check for duplicates by code or name

## 3. Get Contacts

Use `get-contacts` before any workflow that needs a verified customer or supplier identifier.

```bash
officedesk plugin-xero get-contacts
```

What it does:

- fetches contacts from Xero across all pages
- normalizes the response
- writes a local contact cache
- prints a JSON envelope with the contact list

What an agent should inspect:

- `data[].contactID`
- `data[].name`
- `data[].emailAddress`
- `data[].contactStatus`
- `data[].isSupplier`
- `data[].isCustomer`
- `meta.cacheFile`

Cache output:

```text
<plugin-cache-dir>/contacts.json
```

When to use it:

- before `draft-invoice`
- before `reconcile` if you plan to set `contactId`
- before `create-contact` when you need to check for an existing contact
- before `update-contact` when you need to confirm the target contact ID

`get-contacts` is a summary listing. Use `get-contact` when you need the authoritative stored website, phone, tax number, or address fields for one specific contact.

## 3. Get Contact

Use `get-contact` when you need a full contact snapshot for verification.

```bash
officedesk plugin-xero get-contact --contactId=<contact-id>
```

What it does:

- fetches a single contact from Xero by ID
- returns the stored website, phone, tax number, and address fields
- gives you an authoritative post update verification view

What an agent should inspect:

- `data.website`
- `data.emailAddress`
- `data.defaultPhone`
- `data.mobile`
- `data.street`
- `data.city`
- `data.region`
- `data.postalCode`
- `data.country`

## 3A. Update Contact

Use `update-contact` to add or revise operational contact details after the contact already exists in Xero.

```bash
officedesk plugin-xero update-contact \
  --contactId=<contact-id> \
  --firstName="Ash" \
  --lastName="Ang" \
  --email=accounts@example.com \
  --phone="+65 6000 0000" \
  --mobile="+65 8111 1111" \
  --street="1 Raffles Place" \
  --city="Singapore" \
  --postalCode="048616" \
  --country="Singapore"
```

What it does:

- fetches the existing contact first
- updates only the fields you pass
- preserves unrelated phone and address entries already stored on the contact
- re fetches the contact after the update and only reports persisted changes

Current limitation:

- `website` is read only on Xero contacts through this API path, so `update-contact` rejects `--website` instead of reporting a false success

What an agent should inspect:

- `contactId`
- `changes[]`
- `name`
- `contactStatus`

Supported person fields:

- `--firstName`
- `--lastName`

## 4. Get Tax Rates

Use `get-tax-rates` when the correct `taxType` is not already known.

```bash
officedesk plugin-xero get-tax-rates
```

What it does:

- fetches tax rates from Xero
- normalizes the rate list
- writes a local tax rate cache
- prints a JSON envelope for later machine use

What an agent should inspect:

- `data[].name`
- `data[].taxType`
- `data[].displayTaxRate`
- `data[].status`

Use it when:

- you are unsure whether `NONE`, `OUTPUT`, `OUTPUT2`, `INPUT`, or another code is correct
- a reconciliation or invoice payload needs a validated tax type

## 5. Get Branding Themes

Use `get-branding-themes` before drafting invoices if invoice presentation matters.

```bash
officedesk plugin-xero get-branding-themes
```

What it does:

- fetches invoice branding themes from Xero
- normalizes the response
- writes a local branding theme cache
- prints a JSON envelope with available themes

What an agent should inspect:

- `data[].brandingThemeID`
- `data[].name`
- `data[].type`
- `data[].sortOrder`
- `meta.cacheFile`

Cache output:

```text
<plugin-cache-dir>/branding-themes.json
```

When to use it:

- before `draft-invoice` if the user asks for a particular invoice look or template
- when the agent needs to present theme choices before creating an invoice

## 6. Get Bank Transactions

Use `get-bank-transactions` when you need to inspect candidate transactions before reconciliation.

```bash
officedesk plugin-xero get-bank-transactions --account="Main Bank" --unreconciled --limit=50 --page=1
```

Useful options:

- `--account=NAME`
- `--unreconciled`
- `--limit=N`
- `--page=N`

What an agent should inspect:

- transaction date
- amount
- bank account context
- reconciliation state
- any transaction identifiers returned by the handler

When to use it:

- before `reconcile`
- when the user asks which transactions are still unreconciled
- when you need to narrow a candidate transaction set by bank account and date range

## 7. Create Account

Use `create-account` to add a new chart of accounts entry.

```bash
officedesk plugin-xero create-account --code=200 --name="Sales" --type=REVENUE --taxType=OUTPUT
```

Optional description:

```bash
officedesk plugin-xero create-account --code=610 --name="Software" --type=EXPENSE --taxType=INPUT --description="Software subscriptions"
```

Required inputs:

- `--code`
- `--name`
- `--type`
- `--taxType`

When to use it:

- when reconciliation or invoice posting needs a missing account code
- when the user explicitly wants a new Xero account created

Recommended sequence:

1. run `get-accounts`
2. check whether the code or name already exists
3. run `create-account` only if the account is genuinely missing

## 8. Create Contact

Use `create-contact` when the customer or supplier does not already exist.

```bash
officedesk plugin-xero create-contact --name="Acme Pte Ltd" --firstName="Ash" --lastName="Ang"
```

What it does:

- creates a Xero contact by name
- optionally sets the contact person's first and last name
- returns the created contact object

Recommended sequence:

1. run `get-contacts`
2. check whether the contact already exists by name or email
3. run `create-contact` only if needed

## 9. Update Account

Use `update-account` when a known Xero account needs to be amended.

```bash
officedesk plugin-xero update-account --accountId=<account-id> --taxType=OUTPUT --name="Updated Sales"
```

Useful optional fields:

- `--name`
- `--code`
- `--type`
- `--description`

What an agent should inspect first:

- the existing account from `get-accounts`
- whether the user asked to change tax treatment only or also code and naming

## 10. Reconcile

Use `reconcile` when posting a bank transaction against a validated contact, account code, tax type, and amount.

Direct flags example:

```bash
officedesk plugin-xero reconcile --type=SPEND --contactName="Acme Pte Ltd" --accountCode=610 --taxType=INPUT --date=2026-03-31 --amount=108 --description="Software purchase"
```

File based example:

```bash
officedesk plugin-xero reconcile --file=uploads/reconcile.json
```

Useful inputs:

- `--type=SPEND|RECEIVE`
- `--contactId=ID`
- `--contactName=NAME`
- `--accountCode=CODE`
- `--accountName=NAME`
- `--taxType=TYPE`
- `--date=YYYY-MM-DD`
- `--amount=N`
- `--description=TEXT`
- `--reference=TEXT`
- `--lineAmountTypes=Exclusive|Inclusive|NoTax`
- `--attachment=PATH`
- `--statementLineId=ID`
- `--bankAccountId=ID`
- `--bankStatementId=ID`
- `--dry-run`

What an agent should know:

- reconciliation is a live accounting write
- direct flags are fine for one simple transaction payload
- file payloads are safer when input comes from another tool or a multi step workflow
- exact statement-line targeting validates the unreconciled line before creating the bank transaction
- `--dry-run` previews the resolved target line and final bank transaction payload without writing to Xero

Recommended sequence:

1. run `get-bank-transactions` if you need transaction context
2. run `get-accounts` and `get-tax-rates` if codes are not already verified
3. run `get-contacts` if you need a stable contact ID
4. build the reconcile payload
5. run `reconcile`

## 11. Draft Invoice

Use `draft-invoice` to create an accounts receivable invoice in `DRAFT` state.

Simple one line invoice with direct flags:

```bash
officedesk plugin-xero draft-invoice \
  --contactId=<contact-id> \
  --date=2026-03-31 \
  --dueDate=2026-04-30 \
  --description="Monthly retainer" \
  --unitAmount=1200 \
  --accountCode=200 \
  --taxType=NONE \
  --quantity=1 \
  --reference=INV-001 \
  --brandingThemeId=<theme-id>
```

Recommended file based flow for multi line invoices:

```bash
officedesk plugin-xero draft-invoice --file=uploads/draft-invoice.json
```

Example file payload:

```json
{
  "contactId": "contact-id",
  "date": "2026-03-31",
  "dueDate": "2026-04-30",
  "reference": "INV-001",
  "invoiceNumber": "INV-001",
  "currencyCode": "SGD",
  "brandingThemeId": "theme-id",
  "lineAmountTypes": "NoTax",
  "attachmentPath": "uploads/invoice.pdf",
  "lineItems": [
    {
      "description": "Monthly retainer",
      "quantity": 1,
      "unitAmount": 1200,
      "accountCode": "200",
      "taxType": "NONE"
    },
    {
      "description": "Support block",
      "quantity": 2,
      "unitAmount": 150,
      "accountCode": "200",
      "taxType": "NONE"
    }
  ]
}
```

Useful inputs:

- `contactId`
- `date`
- `dueDate`
- `lineItems[]`
- `reference`
- `invoiceNumber`
- `currencyCode`
- `brandingThemeId`
- `lineAmountTypes`
- `attachmentPath`

What it does:

- creates an `ACCREC` invoice
- sets invoice status to `DRAFT`
- uploads an attachment if `attachmentPath` is provided
- returns the created invoice object

What an agent should inspect:

- `invoiceID`
- `invoiceNumber`
- `status`
- any returned validation errors from Xero if creation fails

Important behavior:

- direct flags only model one line item conveniently
- multiple line items should use `--file`
- invalid `lineAmountTypes` values are rejected before the API call
- once the invoice is draft, `update-invoice` can change mutable fields before authorisation
- if a draft should be removed entirely, use `delete-invoice`

Recommended sequence:

1. run `get-contacts` to resolve `contactId`
2. run `get-accounts` to validate revenue account codes
3. run `get-tax-rates` to validate `taxType`
4. run `get-branding-themes` if presentation matters
5. create the draft invoice
6. capture and report `invoiceID`

## 12. Authorise Invoice

Use `authorise-invoice` to move an existing draft invoice to `AUTHORISED`.

Direct form:

```bash
officedesk plugin-xero authorise-invoice --invoiceId=<invoice-id>
```

File based form:

```bash
officedesk plugin-xero authorise-invoice --file=uploads/authorise-invoice.json
```

Example file payload:

```json
{
  "invoiceId": "invoice-id"
}
```

What it does:

- updates the invoice status to `AUTHORISED`
- returns the updated invoice object

What an agent should know:

- this is an accounting status change only
- this does not send the invoice email
- `invoiceId` is required and validated before the API call

When to use it:

- after a draft invoice has been reviewed and approved for authorisation
- before `send-invoice`

## 13. Send Invoice

Use `send-invoice` only when the invoice is ready to be delivered to the customer contact by email.

Direct form:

```bash
officedesk plugin-xero send-invoice --invoiceId=<invoice-id>
```

File based form:

```bash
officedesk plugin-xero send-invoice --file=uploads/send-invoice.json
```

Example file payload:

```json
{
  "invoiceId": "invoice-id"
}
```

Expected success shape:

```json
{
  "success": true,
  "invoiceId": "invoice-id",
  "message": "Invoice email requested successfully"
}
```

What an agent should know:

- this uses Xero invoice email delivery
- it requires a valid `invoiceId`
- it should generally be treated as a user approval boundary unless the user explicitly asked to send immediately

## 14. Download Invoice Files

Use `download-invoice-pdf` when you need the rendered invoice document as a PDF.

```bash
officedesk plugin-xero download-invoice-pdf --invoiceId=<invoice-id>
```

Optional output controls:

```bash
officedesk plugin-xero download-invoice-pdf --invoiceId=<invoice-id> --output=downloads/invoices --fileName=customer-copy.pdf
```

Use `list-invoice-attachments` when you need to inspect files that were uploaded onto the invoice record.

```bash
officedesk plugin-xero list-invoice-attachments --invoiceId=<invoice-id>
```

Use `download-invoice-attachment` when you want one uploaded supporting file rather than the rendered invoice PDF.

```bash
officedesk plugin-xero download-invoice-attachment --invoiceId=<invoice-id> --attachmentId=<attachment-id>
officedesk plugin-xero download-invoice-attachment --invoiceId=<invoice-id> --fileName=supporting-doc.pdf
```

What an agent should know:

- `download-invoice-pdf` downloads the generated invoice document
- `download-invoice-attachment` downloads a file uploaded to the invoice record
- attachment download can infer mime type from the invoice attachment list when the attachment exists in Xero metadata

## 15. When To Use Direct Flags Versus Files

Use direct flags when:

- the payload is small
- there is only one logical record to send
- the action is a quick operator command

Use `--file` when:

- there are multiple invoice line items
- the payload is generated by another tool or workflow
- you need a reusable artifact in `uploads/`
- you want a stable record of what was sent to the plugin

## 16. Output Expectations

Most commands:

- print progress and summaries to stderr
- print machine readable JSON to stdout

Read commands commonly return an envelope shaped like this:

```json
{
  "success": true,
  "count": 0,
  "data": [],
  "meta": {}
}
```

Common read command cache files include:

- `accounts.json`
- `contacts.json`
- `branding-themes.json`

Write commands typically return:

- a created or updated Xero object
- or a concise success envelope in the case of `send-invoice`

## 17. End To End Workflows

### Prepare reference data for invoice work

```bash
officedesk plugin-xero get-contacts
officedesk plugin-xero get-accounts
officedesk plugin-xero get-tax-rates
officedesk plugin-xero get-branding-themes
```

### Create and send a branded invoice

```bash
officedesk plugin-xero get-contacts
officedesk plugin-xero get-accounts
officedesk plugin-xero get-tax-rates
officedesk plugin-xero get-branding-themes
officedesk plugin-xero draft-invoice --file=uploads/draft-invoice.json
officedesk plugin-xero authorise-invoice --invoiceId=<invoice-id>
officedesk plugin-xero send-invoice --invoiceId=<invoice-id>
```

### Revise a draft invoice before approval

```bash
officedesk plugin-xero draft-invoice --file=uploads/draft-invoice.json
officedesk plugin-xero update-invoice --invoiceId=<invoice-id> --reference=INV-001-REV1 --description="Updated retainer" --unitAmount=1350
officedesk plugin-xero authorise-invoice --invoiceId=<invoice-id>
```

### Download the invoice PDF for a separate email workflow

```bash
officedesk plugin-xero authorise-invoice --invoiceId=<invoice-id>
officedesk plugin-xero download-invoice-pdf --invoiceId=<invoice-id>
```

### Reconcile a transaction with validated accounting inputs

```bash
officedesk plugin-xero get-bank-transactions --account="Main Bank" --unreconciled
officedesk plugin-xero get-accounts
officedesk plugin-xero get-tax-rates
officedesk plugin-xero get-contacts
officedesk plugin-xero reconcile --file=uploads/reconcile.json
```

### Add a missing supplier then reconcile

```bash
officedesk plugin-xero get-contacts
officedesk plugin-xero create-contact "New Vendor Pte Ltd"
officedesk plugin-xero get-accounts
officedesk plugin-xero get-tax-rates
officedesk plugin-xero reconcile --type=SPEND --contactName="New Vendor Pte Ltd" --accountCode=610 --taxType=INPUT --date=2026-03-31 --amount=54 --description="Subscription"
```

## 18. Failure Handling

If a command fails, inspect the error and apply the likely fix.

| Symptom | Likely Cause | Agent Response |
|---|---|---|
| `No tenants found` | Authentication succeeded but there is no accessible tenant for the account | Re run `login` and confirm tenant access in Xero |
| `invoiceId is required` | Missing or empty invoice identifier | Re run the command with a real `invoiceId` or a valid JSON file |
| Only DRAFT invoices can be updated or deleted | Invoice is already authorised, paid, voided, or deleted | Stop the draft only flow and choose the correct status transition instead |
| Invalid `lineAmountTypes` error | Unsupported enum value in invoice payload | Use `Exclusive`, `Inclusive`, or `NoTax` only |
| Contact or account validation failure from Xero | Unknown `contactId`, `accountCode`, or `taxType` | Re run `get-contacts`, `get-accounts`, or `get-tax-rates` and rebuild the payload |
| Attachment file read failure | Wrong local file path | Verify the file exists relative to the repo root or use an absolute path |
| Authorise succeeded but customer received nothing | Invoice was authorised only | Run `send-invoice` explicitly |
| Send invoice failed | Invalid invoice state or Xero email rejection | Inspect the API response body and confirm the invoice is ready to send |
| Download invoice attachment failed with unknown content type | Attachment metadata could not be resolved | Re run `list-invoice-attachments` and provide `--contentType` if needed |

## 19. Minimal Decision Tree

1. Need access or fresh tokens: run `login`.
2. Need a contact identifier: run `get-contacts`.
3. Need an account code or account ID: run `get-accounts`.
4. Need a valid tax type: run `get-tax-rates`.
5. Need invoice presentation choices: run `get-branding-themes`.
6. Need transaction context: run `get-bank-transactions`.
7. Need to create or update accounting master data: run `create-account`, `create-contact`, or `update-account`.
8. Need to post a bank reconciliation: run `reconcile`.
9. Need a new customer invoice: run `draft-invoice`.
10. Need to revise a draft invoice before approval: run `update-invoice`.
11. Need to remove a draft invoice entirely: run `delete-invoice`.
12. Need to approve the draft in Xero terms: run `authorise-invoice`.
13. Need to deliver the invoice to the customer: run `send-invoice`.
14. Need the rendered invoice PDF: run `download-invoice-pdf`.
15. Need an uploaded supporting file on the invoice: run `list-invoice-attachments`, then `download-invoice-attachment`.

## 20. Recommended Agent Defaults

1. Prefer read commands before write commands.
2. Carry forward exact Xero identifiers from command output instead of retyping names.
3. Treat every write as live and potentially irreversible from the plugin point of view.
4. Use file payloads for multi step workflows and anything with multiple invoice lines.
5. Separate invoice drafting, authorisation, and delivery in both reasoning and execution.
6. Surface the created `invoiceID` immediately after drafting.
7. Ask for confirmation before `send-invoice` unless the user explicitly asked to send immediately.
8. Prefer `download-invoice-pdf` for customer facing invoice documents and `download-invoice-attachment` for supporting uploaded files.