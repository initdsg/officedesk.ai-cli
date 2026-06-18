# plugin-xero Agent Tutorial

This tutorial is written for an AI agent that needs to operate `plugin-xero` safely and predictably from the repo root using the `officedesk` binary from the shell `PATH`.

## Goal

Use `plugin-xero` to:

- authenticate against Xero and refresh tenant access
- fetch reference data before accounting writes
- inspect bank transactions before reconciliation work
- inspect and filter accounts payable bills
- create or update Xero accounts and contacts
- reconcile bank transactions with validated accounting inputs
- list invoice branding themes before drafting invoices
- create draft accounts receivable invoices
- authorise draft invoices as a separate accounting step
- send authorised invoices to the customer as a separate delivery step
- download the rendered invoice PDF for external delivery workflows
- list and download uploaded invoice attachments
- list, void, pay, and attach files to AR invoices
- create, authorise, allocate, void, and delete credit notes
- list and reverse payments applied to invoices or credit notes
- fetch financial reports including Profit & Loss, Balance Sheet, Trial Balance, Aged Receivables, Aged Payables, Bank Summary, and Executive Summary

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
officedesk plugin-xero get-invoices --status=AUTHORISED --from=2026-04-01
officedesk plugin-xero draft-invoice --file=uploads/draft-invoice.json
officedesk plugin-xero update-invoice --invoiceId=<invoice-id> --reference=INV-001-REV1
officedesk plugin-xero authorise-invoice --invoiceId=<invoice-id>
officedesk plugin-xero pay-invoice --invoiceId=<invoice-id> --accountCode=090 --date=2026-05-01 --amount=1200
officedesk plugin-xero void-invoice --invoiceId=<invoice-id>
officedesk plugin-xero attach-to-invoice --invoiceId=<invoice-id> --file=uploads/signed-contract.pdf
officedesk plugin-xero delete-invoice --invoiceId=<invoice-id>
officedesk plugin-xero send-invoice --invoiceId=<invoice-id>
officedesk plugin-xero download-invoice-pdf --invoiceId=<invoice-id>
officedesk plugin-xero list-invoice-attachments --invoiceId=<invoice-id>
officedesk plugin-xero download-invoice-attachment --invoiceId=<invoice-id> --attachmentId=<attachment-id>
officedesk plugin-xero get-credit-notes --type=ACCRECCREDIT --status=AUTHORISED
officedesk plugin-xero draft-credit-note --type=ACCRECCREDIT --contactId=<contact-id> --description="Overcharge refund" --unitAmount=200 --accountCode=200 --taxType=OUTPUT
officedesk plugin-xero authorise-credit-note --creditNoteId=<credit-note-id>
officedesk plugin-xero allocate-credit-note --creditNoteId=<credit-note-id> --invoiceId=<invoice-id> --amount=200
officedesk plugin-xero void-credit-note --creditNoteId=<credit-note-id>
officedesk plugin-xero delete-credit-note --creditNoteId=<credit-note-id>
officedesk plugin-xero get-payments --invoiceId=<invoice-id>
officedesk plugin-xero delete-payment --paymentId=<payment-id>
officedesk plugin-xero get-report --reportName=profit-loss --fromDate=2026-01-01 --toDate=2026-03-31
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
| **Accounts** | |
| Refresh cached accounts | `get-accounts` |
| Filter accounts by type or status | `get-accounts --type=REVENUE` |
| Create a chart of accounts entry | `create-account` |
| Update an account | `update-account` |
| **Contacts** | |
| Refresh cached contacts | `get-contacts` |
| Search contacts by name | `get-contacts --searchTerm=Acme` |
| Fetch contacts by IDs | `get-contacts --ids=ID1,ID2` |
| Create a contact | `create-contact` |
| Update a contact | `update-contact` |
| **Tax & Themes** | |
| Refresh cached tax rates | `get-tax-rates` |
| Discover invoice themes | `get-branding-themes` |
| **Bank** | |
| Inspect bank transactions | `get-bank-transactions` |
| Reconcile a bank transaction | `reconcile` |
| **AR Invoices** | |
| List AR invoices | `get-invoices` |
| Create a draft invoice | `draft-invoice` |
| Update a draft invoice | `update-invoice` |
| Move a draft invoice to authorised | `authorise-invoice` |
| Record payment against an AR invoice | `pay-invoice` |
| Void an authorised AR invoice | `void-invoice` |
| Attach a file to an AR invoice | `attach-to-invoice` |
| Email an authorised invoice | `send-invoice` |
| Download the rendered invoice PDF | `download-invoice-pdf` |
| List uploaded invoice attachments | `list-invoice-attachments` |
| Download one uploaded invoice attachment | `download-invoice-attachment` |
| Delete a draft invoice | `delete-invoice` |
| **AP Bills** | |
| List accounts payable bills | `get-bills` |
| **Credit Notes** | |
| List credit notes | `get-credit-notes` |
| Create a draft credit note | `draft-credit-note` |
| Authorise a credit note | `authorise-credit-note` |
| Allocate a credit note against an invoice | `allocate-credit-note` |
| Void an authorised credit note | `void-credit-note` |
| Delete a draft credit note | `delete-credit-note` |
| **Payments** | |
| List payments on invoices or credit notes | `get-payments` |
| Reverse a payment | `delete-payment` |
| **Reports** | |
| Fetch a financial report | `get-report` |

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

Use `get-accounts` before reconciliation or invoice work when you need a verified revenue, expense, or bank account code. Pass filters to narrow results server-side instead of fetching the full chart every time.

```bash
# Fetch all accounts
officedesk plugin-xero get-accounts

# Filter by type
officedesk plugin-xero get-accounts --type=REVENUE
officedesk plugin-xero get-accounts --type=BANK

# Filter by status
officedesk plugin-xero get-accounts --status=ACTIVE
officedesk plugin-xero get-accounts --status=ARCHIVED

# Filter by class
officedesk plugin-xero get-accounts --class=EXPENSE

# Filter by exact name or code
officedesk plugin-xero get-accounts --name="Sales"
officedesk plugin-xero get-accounts --code=200
```

Available filters (all single-value; comma input is rejected):

- `--type=TYPE` — account type, e.g. `REVENUE`, `EXPENSE`, `BANK`
- `--status=STATUS` — `ACTIVE` or `ARCHIVED`
- `--class=CLASS` — `ASSET`, `LIABILITY`, `EQUITY`, `REVENUE`, or `EXPENSE`
- `--name=NAME` — exact account name match
- `--code=CODE` — exact account code match

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

Use `get-contacts` before any workflow that needs a verified customer or supplier identifier. Pass filters to avoid fetching all contacts when you only need a subset.

```bash
# Fetch all contacts (paginated)
officedesk plugin-xero get-contacts

# Full-text search (name, email, etc.)
officedesk plugin-xero get-contacts --searchTerm="Acme"

# Batch fetch by known IDs (single API call, no pagination)
officedesk plugin-xero get-contacts --ids=ID1,ID2,ID3

# Exact filter clause matches
officedesk plugin-xero get-contacts --name="Acme Pte Ltd"
officedesk plugin-xero get-contacts --email=accounts@example.com

# Include archived contacts or return summary fields only
officedesk plugin-xero get-contacts --includeArchived
officedesk plugin-xero get-contacts --summaryOnly
```

Available filters:

- `--searchTerm=TEXT` — Xero full-text search across name, email, and other contact fields
- `--ids=ID1,ID2,...` — comma-separated contact IDs; triggers a single batch API call and skips pagination
- `--name=NAME` — exact name match via filter clause
- `--email=EMAIL` — exact email match via filter clause
- `--includeArchived` — include archived contacts in results
- `--summaryOnly` — return lightweight summary fields only

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

## 3B. Get Contact

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

Use `get-bank-transactions` when you need to inspect candidate transactions before reconciliation. All filters are applied server-side.

```bash
# Unreconciled transactions by bank account ID (preferred)
officedesk plugin-xero get-bank-transactions --bankAccountId=<account-id> --unreconciled
officedesk plugin-xero get-bills --status=AUTHORISED --from=2026-04-01 --to=2026-04-30

# Legacy: filter by bank account name (resolved to ID via a secondary lookup)
officedesk plugin-xero get-bank-transactions --account="Main Bank" --unreconciled

# Filter by date range
officedesk plugin-xero get-bank-transactions --from=2026-04-01 --to=2026-04-30

# Filter by transaction type or status
officedesk plugin-xero get-bank-transactions --type=SPEND --status=AUTHORISED

# Filter by contact
officedesk plugin-xero get-bank-transactions --contactId=<contact-id>

# Pagination
officedesk plugin-xero get-bank-transactions --limit=50 --page=2
```

Available options (all single-value; comma input is rejected):

- `--bankAccountId=ID` — filter by bank account ID (preferred; avoids extra API round-trip)
- `--account=NAME` — legacy: resolve bank account by name to an ID (use `--bankAccountId` when the ID is known)
- `--type=TYPE` — transaction type: `SPEND`, `RECEIVE`, `SPEND-PREPAYMENT`, `RECEIVE-PREPAYMENT`, etc.
- `--status=STATUS` — `AUTHORISED` or `DELETED`
- `--contactId=ID` — filter by contact ID
- `--unreconciled` — shorthand for `IsReconciled==false`
- `--from=YYYY-MM-DD` — transactions on or after this date (server-side)
- `--to=YYYY-MM-DD` — transactions on or before this date (server-side)
- `--limit=N` — maximum results (default: 100)
- `--page=N` — page number (default: 1)

Output is a structured JSON envelope (`GetBankTransactionsResult`) with `success`, `count`, `data[]`, and `meta`.

## 7. Get Bills

Use `get-bills` to list accounts payable (ACCPAY) invoices with server-side filtering. All date and amount ranges are applied by Xero, not client-side.

```bash
# All bills
officedesk plugin-xero get-bills

# Filter by one or more statuses (comma-separated)
officedesk plugin-xero get-bills --status=AUTHORISED
officedesk plugin-xero get-bills --status=DRAFT,AUTHORISED

# Filter by date range (server-side)
officedesk plugin-xero get-bills --from=2026-04-01 --to=2026-04-30

# Filter by due date range
officedesk plugin-xero get-bills --dueDateFrom=2026-05-01 --dueDateTo=2026-05-31

# Filter by contact
officedesk plugin-xero get-bills --contactId=<contact-id>
officedesk plugin-xero get-bills --contactIds=ID1,ID2

# Batch fetch by bill ID or supplier invoice number
officedesk plugin-xero get-bills --ids=ID1,ID2
officedesk plugin-xero get-bills --invoiceNumbers=INV-001,INV-002

# Full-text search
officedesk plugin-xero get-bills --searchTerm="consulting"

# Amount range filter
officedesk plugin-xero get-bills --amountDueMin=100 --amountDueMax=5000

# Lightweight response
officedesk plugin-xero get-bills --summaryOnly

# Pagination
officedesk plugin-xero get-bills --limit=50 --page=2
```

Available options:

- `--status=S1,S2` — one or more of `DRAFT`, `SUBMITTED`, `AUTHORISED`, `PAID`, `VOIDED` (comma-separated)
- `--contactId=ID` — single contact ID (alias for `--contactIds`)
- `--contactIds=ID1,ID2` — comma-separated contact IDs (batch)
- `--ids=ID1,ID2` — comma-separated bill IDs (batch fetch)
- `--invoiceNumbers=N1,N2` — comma-separated supplier invoice/reference numbers
- `--searchTerm=TEXT` — Xero full-text search
- `--from=YYYY-MM-DD` — bill date on or after (server-side)
- `--to=YYYY-MM-DD` — bill date on or before (server-side)
- `--dueDateFrom=YYYY-MM-DD` — due date on or after (server-side)
- `--dueDateTo=YYYY-MM-DD` — due date on or before (server-side)
- `--amountDueMin=N` — amount due ≥ N (server-side)
- `--amountDueMax=N` — amount due ≤ N (server-side)
- `--summaryOnly` — omit line items, payments, and attachments
- `--limit=N` — maximum results (default: 100)
- `--page=N` — page number (default: 1)
- `--file=PATH` — JSON file with filter payload

What an agent should inspect:

- `data[].billId`
- `data[].invoiceNumber`
- `data[].status`
- `data[].contactName`
- `data[].date`
- `data[].dueDate`
- `data[].total`
- `data[].amountDue`

## 8. Create Account

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

## 9. Create Contact

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

## 10. Update Account

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

## 11. Reconcile

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

## 12. Draft Invoice

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

## 13. Authorise Invoice

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

## 14. Send Invoice

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

## 15. Download Invoice Files

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

## 16. Get AR Invoices

Use `get-invoices` to list accounts receivable (ACCREC) invoices with server-side filtering. Mirrors `get-bills` but targets the AR side of the ledger.

```bash
# All AR invoices
officedesk plugin-xero get-invoices

# Filter by one or more statuses (comma-separated)
officedesk plugin-xero get-invoices --status=AUTHORISED
officedesk plugin-xero get-invoices --status=DRAFT,AUTHORISED

# Filter by date range (server-side)
officedesk plugin-xero get-invoices --from=2026-04-01 --to=2026-04-30

# Filter by contact
officedesk plugin-xero get-invoices --contactId=<contact-id>
officedesk plugin-xero get-invoices --contactIds=ID1,ID2

# Batch fetch by invoice ID or invoice number
officedesk plugin-xero get-invoices --ids=ID1,ID2
officedesk plugin-xero get-invoices --invoiceNumbers=INV-001,INV-002

# Full-text search
officedesk plugin-xero get-invoices --searchTerm="retainer"

# Amount range filter
officedesk plugin-xero get-invoices --amountDueMin=100 --amountDueMax=5000

# Lightweight response
officedesk plugin-xero get-invoices --summaryOnly

# Pagination
officedesk plugin-xero get-invoices --limit=50 --page=2
```

Available options:

- `--status=S1,S2` — one or more of `DRAFT`, `SUBMITTED`, `AUTHORISED`, `PAID`, `VOIDED` (comma-separated)
- `--contactId=ID` — single contact ID
- `--contactIds=ID1,ID2` — comma-separated contact IDs
- `--ids=ID1,ID2` — comma-separated invoice IDs
- `--invoiceNumbers=N1,N2` — comma-separated invoice numbers
- `--searchTerm=TEXT` — Xero full-text search
- `--from=YYYY-MM-DD` — invoice date on or after (server-side)
- `--to=YYYY-MM-DD` — invoice date on or before (server-side)
- `--dueDateFrom=YYYY-MM-DD` — due date on or after (server-side)
- `--dueDateTo=YYYY-MM-DD` — due date on or before (server-side)
- `--amountDueMin=N` — amount due ≥ N (server-side)
- `--amountDueMax=N` — amount due ≤ N (server-side)
- `--summaryOnly` — omit line items and payments
- `--limit=N` — maximum results (default: 100)
- `--page=N` — page number (default: 1)

What an agent should inspect:

- `data[].billId` (the Xero invoiceID)
- `data[].invoiceNumber`
- `data[].status`
- `data[].contactName`
- `data[].date`
- `data[].dueDate`
- `data[].total`
- `data[].amountDue`

## 17. AR Invoice Actions

### Void an Invoice

Use `void-invoice` to void an `AUTHORISED` AR invoice. Only authorised invoices can be voided.

```bash
officedesk plugin-xero void-invoice --invoiceId=<invoice-id>
```

What an agent should know:

- the invoice must be `AUTHORISED` — draft invoices should be deleted with `delete-invoice` instead
- voiding is permanent and cannot be undone through the plugin

### Pay an Invoice

Use `pay-invoice` to record a payment against an `AUTHORISED` AR invoice.

```bash
officedesk plugin-xero pay-invoice \
  --invoiceId=<invoice-id> \
  --accountCode=090 \
  --date=2026-05-01 \
  --amount=1200
```

Optional inputs:

- `--reference=TEXT` — payment reference
- `--currencyRate=N` — exchange rate for foreign currency invoices

What an agent should know:

- the invoice must be `AUTHORISED`
- the account code must correspond to a bank or clearing account — use `get-accounts --type=BANK` to identify the correct code
- a partial payment leaves the invoice `AUTHORISED` with a reduced `amountDue`; a full payment moves it to `PAID`
- use `get-payments --invoiceId=<id>` to inspect existing payments before adding another

What an agent should inspect in the response:

- `data[].paymentId`
- `data[].status`
- `data[].paidAmount`
- `data[].remainingAmount`

### Attach a File to an Invoice

Use `attach-to-invoice` to upload a supporting document to an existing AR invoice.

```bash
officedesk plugin-xero attach-to-invoice --invoiceId=<invoice-id> --file=uploads/signed-contract.pdf
```

Optional:

- `--filename=NAME` — override the filename shown in Xero (defaults to the local file name)

What an agent should know:

- the invoice must exist in Xero (any non-deleted status)
- mime type is inferred from the file extension
- use `list-invoice-attachments` to confirm upload success

## 18. Credit Notes

Credit notes reduce the amount a customer owes (`ACCRECCREDIT`) or reduce what you owe a supplier (`ACCPAYCREDIT`).

### Get Credit Notes

Use `get-credit-notes` to list credit notes with optional filtering.

```bash
# All credit notes
officedesk plugin-xero get-credit-notes

# Filter by type
officedesk plugin-xero get-credit-notes --type=ACCRECCREDIT
officedesk plugin-xero get-credit-notes --type=ACCPAYCREDIT

# Filter by status
officedesk plugin-xero get-credit-notes --status=AUTHORISED

# Filter by date range (server-side)
officedesk plugin-xero get-credit-notes --from=2026-04-01 --to=2026-04-30

# Filter by contact or ID (client-side)
officedesk plugin-xero get-credit-notes --contactIds=ID1,ID2
officedesk plugin-xero get-credit-notes --ids=ID1,ID2

# Pagination
officedesk plugin-xero get-credit-notes --limit=50 --page=2
```

Available options:

- `--type=ACCRECCREDIT|ACCPAYCREDIT|ALL` — credit note type (default: `ALL`)
- `--status=S1,S2` — one or more of `DRAFT`, `SUBMITTED`, `AUTHORISED`, `PAID`, `VOIDED`
- `--contactIds=ID1,ID2` — comma-separated contact IDs (filtered client-side)
- `--ids=ID1,ID2` — comma-separated credit note IDs (filtered client-side)
- `--from=YYYY-MM-DD` — date on or after (server-side)
- `--to=YYYY-MM-DD` — date on or before (server-side)
- `--summaryOnly` — lightweight response
- `--limit=N` — maximum results (default: 100)
- `--page=N` — page number (default: 1)

What an agent should inspect:

- `data[].creditNoteId`
- `data[].creditNoteNumber`
- `data[].type`
- `data[].status`
- `data[].contactName`
- `data[].total`
- `data[].remainingCredit`

### Draft a Credit Note

Use `draft-credit-note` to create a new credit note in `DRAFT` state.

```bash
officedesk plugin-xero draft-credit-note \
  --type=ACCRECCREDIT \
  --contactId=<contact-id> \
  --description="Overcharge refund" \
  --unitAmount=200 \
  --accountCode=200 \
  --taxType=OUTPUT
```

For multi-line credit notes use `--file`:

```json
{
  "type": "ACCRECCREDIT",
  "contactId": "contact-id",
  "date": "2026-05-01",
  "reference": "CN-001",
  "lineItems": [
    { "description": "Overcharge refund", "quantity": 1, "unitAmount": 200, "accountCode": "200", "taxType": "OUTPUT" }
  ]
}
```

Required inputs:

- `type` — `ACCRECCREDIT` (AR) or `ACCPAYCREDIT` (AP)
- `contactId`
- `description`, `unitAmount`, `accountCode`, `taxType` (or `lineItems[]` via `--file`)

What an agent should know:

- run `get-contacts`, `get-accounts`, and `get-tax-rates` before drafting
- capture the returned `creditNoteId` for subsequent steps

### Authorise a Credit Note

Use `authorise-credit-note` to move a `DRAFT` or `SUBMITTED` credit note to `AUTHORISED`.

```bash
officedesk plugin-xero authorise-credit-note --creditNoteId=<credit-note-id>
```

The credit note must be `AUTHORISED` before it can be allocated against an invoice.

### Allocate a Credit Note

Use `allocate-credit-note` to apply an authorised credit note against an outstanding invoice.

```bash
officedesk plugin-xero allocate-credit-note \
  --creditNoteId=<credit-note-id> \
  --invoiceId=<invoice-id> \
  --amount=200 \
  --date=2026-05-01
```

What an agent should know:

- both the credit note and the invoice must be `AUTHORISED`
- `amount` cannot exceed the credit note's `remainingCredit` or the invoice's `amountDue` — check both with `get-credit-notes` and `get-invoices --ids=<id>` first
- the allocation date defaults to today if omitted

### Void a Credit Note

Use `void-credit-note` to void an `AUTHORISED` credit note that has not been fully allocated.

```bash
officedesk plugin-xero void-credit-note --creditNoteId=<credit-note-id>
```

### Delete a Credit Note

Use `delete-credit-note` to permanently delete a `DRAFT` or `SUBMITTED` credit note.

```bash
officedesk plugin-xero delete-credit-note --creditNoteId=<credit-note-id>
```

## 19. Payments

### Get Payments

Use `get-payments` to list payments applied to invoices or credit notes.

```bash
# All recent payments
officedesk plugin-xero get-payments

# Filter by invoice
officedesk plugin-xero get-payments --invoiceId=<invoice-id>

# Filter by payment type
officedesk plugin-xero get-payments --paymentType=ACCRECPAYMENT
officedesk plugin-xero get-payments --paymentType=ACCPAYPAYMENT

# Filter by status
officedesk plugin-xero get-payments --status=AUTHORISED

# Filter by date range
officedesk plugin-xero get-payments --from=2026-04-01 --to=2026-04-30

# Filter by bank account
officedesk plugin-xero get-payments --accountId=<account-id>

# Pagination
officedesk plugin-xero get-payments --limit=50 --page=2
```

Available options:

- `--invoiceId=ID` — filter by invoice ID
- `--accountId=ID` — filter by bank or clearing account ID
- `--status=STATUS` — `AUTHORISED` or `DELETED`
- `--paymentType=TYPE` — `ACCRECPAYMENT` (AR) or `ACCPAYPAYMENT` (AP)
- `--from=YYYY-MM-DD` — payment date on or after (server-side)
- `--to=YYYY-MM-DD` — payment date on or before (server-side)
- `--limit=N` — maximum results (default: 100)
- `--page=N` — page number (default: 1)

What an agent should inspect:

- `data[].paymentId`
- `data[].invoiceId`
- `data[].invoiceNumber`
- `data[].type`
- `data[].status`
- `data[].amount`
- `data[].date`
- `data[].reference`

### Delete (Reverse) a Payment

Use `delete-payment` to reverse a payment. This sets the payment status to `DELETED` in Xero and restores the invoice's outstanding balance.

```bash
officedesk plugin-xero delete-payment --paymentId=<payment-id>
```

What an agent should know:

- this reverses the payment record, not the invoice
- the invoice returns to `AUTHORISED` with its original or partial `amountDue`
- run `get-payments --invoiceId=<id>` first to identify the correct `paymentId`

## 20. Reports

Use `get-report` to fetch a Xero financial report. Pass `--reportName` to select the report type.

```bash
# Profit & Loss for a date range
officedesk plugin-xero get-report --reportName=profit-loss --fromDate=2026-01-01 --toDate=2026-03-31

# Balance Sheet at a point in time
officedesk plugin-xero get-report --reportName=balance-sheet --date=2026-03-31

# Trial Balance
officedesk plugin-xero get-report --reportName=trial-balance --date=2026-03-31

# Aged Receivables by Contact (contactId required)
officedesk plugin-xero get-report --reportName=aged-receivables --contactId=<contact-id>

# Aged Payables by Contact (contactId required)
officedesk plugin-xero get-report --reportName=aged-payables --contactId=<contact-id>

# Bank Summary
officedesk plugin-xero get-report --reportName=bank-summary --fromDate=2026-01-01 --toDate=2026-03-31

# Executive Summary
officedesk plugin-xero get-report --reportName=executive-summary --date=2026-03-31

# Cash basis reporting
officedesk plugin-xero get-report --reportName=profit-loss --fromDate=2026-01-01 --toDate=2026-03-31 --paymentsOnly

# Periodic comparisons
officedesk plugin-xero get-report --reportName=profit-loss --fromDate=2026-01-01 --toDate=2026-03-31 --periods=3 --timeframe=MONTH
```

Available report names:

| Report Name | Description | Required Options |
|---|---|---|
| `profit-loss` | Profit & Loss | `--fromDate`, `--toDate` |
| `balance-sheet` | Balance Sheet | `--date` |
| `trial-balance` | Trial Balance | `--date` |
| `aged-receivables` | Aged Receivables by Contact | `--contactId` |
| `aged-payables` | Aged Payables by Contact | `--contactId` |
| `bank-summary` | Bank Summary | `--fromDate`, `--toDate` |
| `executive-summary` | Executive Summary | `--date` |

Common options:

- `--fromDate=YYYY-MM-DD` — start date (profit-loss, bank-summary, aged-*)
- `--toDate=YYYY-MM-DD` — end date (profit-loss, bank-summary, aged-*)
- `--date=YYYY-MM-DD` — balance date (balance-sheet, trial-balance, executive-summary, aged-*)
- `--periods=N` — number of comparison periods (profit-loss, balance-sheet)
- `--timeframe=MONTH|QUARTER|YEAR` — period granularity
- `--paymentsOnly` — cash basis reporting (profit-loss, balance-sheet, trial-balance)
- `--contactId=ID` — required for aged-receivables and aged-payables

What an agent should inspect:

- `data[]` — raw report rows as returned by Xero (section headers, row types, cells)
- `meta.reportTitle`
- `meta.reportDate`
- `meta.reportName`

What an agent should know:

- reports return raw Xero row data; the agent is responsible for interpreting row types and cell values
- `aged-receivables` and `aged-payables` require `--contactId` — fetch it from `get-contacts` first

## 21. When To Use Direct Flags Versus Files

Use direct flags when:

- the payload is small
- there is only one logical record to send
- the action is a quick operator command

Use `--file` when:

- there are multiple invoice or credit note line items
- the payload is generated by another tool or workflow
- you need a reusable artifact in `uploads/`
- you want a stable record of what was sent to the plugin

## 22. Output Expectations

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

## 23. End To End Workflows

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

### Record payment against an AR invoice

```bash
officedesk plugin-xero get-invoices --status=AUTHORISED --contactId=<contact-id>
officedesk plugin-xero get-accounts --type=BANK
officedesk plugin-xero pay-invoice --invoiceId=<invoice-id> --accountCode=090 --date=2026-05-01 --amount=1200
```

### Reverse an incorrect payment

```bash
officedesk plugin-xero get-payments --invoiceId=<invoice-id>
officedesk plugin-xero delete-payment --paymentId=<payment-id>
```

### Issue and apply an AR credit note

```bash
officedesk plugin-xero get-contacts
officedesk plugin-xero get-accounts
officedesk plugin-xero get-tax-rates
officedesk plugin-xero draft-credit-note --type=ACCRECCREDIT --contactId=<contact-id> --description="Overcharge refund" --unitAmount=200 --accountCode=200 --taxType=OUTPUT
officedesk plugin-xero authorise-credit-note --creditNoteId=<credit-note-id>
officedesk plugin-xero get-invoices --status=AUTHORISED --contactId=<contact-id>
officedesk plugin-xero allocate-credit-note --creditNoteId=<credit-note-id> --invoiceId=<invoice-id> --amount=200
```

### Fetch a Profit & Loss report for a quarter

```bash
officedesk plugin-xero get-report --reportName=profit-loss --fromDate=2026-01-01 --toDate=2026-03-31
```

### Review aged receivables for a contact

```bash
officedesk plugin-xero get-contacts --searchTerm="Acme"
officedesk plugin-xero get-report --reportName=aged-receivables --contactId=<contact-id>
```

## 24. Failure Handling

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
| `--status` rejected on `get-bank-statement-lines` | Value was not `unreconciled` or `reconciled`, or was comma-separated | Use a single valid status: `unreconciled` or `reconciled` |
| `--type` / `--status` rejected on `get-bank-transactions` with comma error | Multi-value input on a single-predicate filter | Pass one value only; use `--ids` or `--contactIds` for batch lookups |
| `get-bills` returns more results than expected with `--limit` | Date or amount filters not applied | Use `--from`, `--to`, `--amountDueMin`, `--amountDueMax` — all are server-side |
| `void-invoice` rejects with status error | Invoice is not `AUTHORISED` | Use `delete-invoice` for drafts; check current status with `get-invoices --ids=<id>` |
| `pay-invoice` fails with account code error | Account code is not a bank or clearing account | Re run `get-accounts --type=BANK` and use a valid code |
| `Only AUTHORISED invoices can be paid` | Invoice is in the wrong status | Authorise the invoice first with `authorise-invoice` |
| `creditNoteId is required` | Missing credit note identifier | Re run with a valid `--creditNoteId` from `get-credit-notes` |
| `Only AUTHORISED credit notes can be voided` | Credit note is not in `AUTHORISED` state | Check status with `get-credit-notes --ids=<id>` |
| `allocate-credit-note` fails with amount error | Allocation exceeds `remainingCredit` or invoice `amountDue` | Inspect both from `get-credit-notes` and `get-invoices --ids=<id>` |
| `delete-payment` returns payment not found | Payment ID is wrong or already reversed | Re run `get-payments --invoiceId=<id>` to locate the correct `paymentId` |
| `contactId is required for aged-receivables` | Report requires a contact | Run `get-contacts` and pass the resolved ID with `--contactId` |
| `Invalid reportName` | Unsupported report name string | Use one of: `profit-loss`, `balance-sheet`, `trial-balance`, `aged-receivables`, `aged-payables`, `bank-summary`, `executive-summary` |

## 25. Minimal Decision Tree

1. Need access or fresh tokens: run `login`.
2. Need a contact identifier: run `get-contacts`.
3. Need an account code or account ID: run `get-accounts`.
4. Need a valid tax type: run `get-tax-rates`.
5. Need invoice presentation choices: run `get-branding-themes`.
6. Need transaction context: run `get-bank-transactions`.
7. Need to review accounts payable bills: run `get-bills`.
8. Need to review accounts receivable invoices: run `get-invoices`.
9. Need to create or update accounting master data: run `create-account`, `create-contact`, or `update-account`.
10. Need to post a bank reconciliation: run `reconcile`.
11. Need a new customer invoice: run `draft-invoice`.
12. Need to revise a draft invoice before approval: run `update-invoice`.
13. Need to remove a draft invoice entirely: run `delete-invoice`.
14. Need to approve the draft in Xero terms: run `authorise-invoice`.
15. Need to record payment received against an invoice: run `pay-invoice`.
16. Need to void an authorised invoice: run `void-invoice`.
17. Need to deliver the invoice to the customer: run `send-invoice`.
18. Need the rendered invoice PDF: run `download-invoice-pdf`.
19. Need an uploaded supporting file on the invoice: run `list-invoice-attachments`, then `download-invoice-attachment`.
20. Need to attach a file to an AR invoice: run `attach-to-invoice`.
21. Need to issue a refund or reduce an outstanding balance: run `draft-credit-note`, `authorise-credit-note`, then `allocate-credit-note`.
22. Need to list existing credit notes: run `get-credit-notes`.
23. Need to void or delete a credit note: run `void-credit-note` (authorised) or `delete-credit-note` (draft or submitted).
24. Need to inspect payments on an invoice: run `get-payments --invoiceId=<id>`.
25. Need to reverse an incorrect payment: run `delete-payment`.
26. Need a financial report: run `get-report`.

## 26. Recommended Agent Defaults

1. Prefer read commands before write commands.
2. Carry forward exact Xero identifiers from command output instead of retyping names.
3. Treat every write as live and potentially irreversible from the plugin point of view.
4. Use file payloads for multi step workflows and anything with multiple invoice or credit note lines.
5. Separate invoice drafting, authorisation, and delivery in both reasoning and execution.
6. Surface the created `invoiceID` or `creditNoteId` immediately after drafting so later steps can reuse it.
7. Ask for confirmation before `send-invoice` unless the user explicitly asked to send immediately.
8. Prefer `download-invoice-pdf` for customer facing invoice documents and `download-invoice-attachment` for supporting uploaded files.
9. Run `get-invoices --ids=<id>` before `void-invoice`, `pay-invoice`, or `attach-to-invoice` to confirm the current invoice status.
10. Run `get-credit-notes --ids=<id>` before `allocate-credit-note` to confirm `remainingCredit` is sufficient.
11. Run `get-payments --invoiceId=<id>` before `delete-payment` to identify the correct `paymentId`.
12. Treat `get-report` output as raw Xero row data; interpret row types and cell values in context before presenting to the user.