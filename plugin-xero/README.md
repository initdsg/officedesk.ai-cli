# @officedesk/plugin-xero

Xero accounting integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Manages contacts, invoices, bills, accounts, bank transactions, and reconciliation via the Xero API.

## Installation

```bash
npm install -g @officedesk/plugin-xero
```

## Setup

Sign in to Xero via the browser OAuth flow:

```bash
officedesk-plugin-xero login
```

If you need exact statement-line reconciliation, also capture the browser-authenticated Xero session:

```bash
officedesk-plugin-xero browser-login
```

If Playwright is installed but Chromium is missing:

```bash
npx playwright install chromium
```

## CLI reference

```
officedesk-plugin-xero <command> [options]
```

### `login`

Authenticate with Xero via the browser OAuth flow.

```bash
officedesk-plugin-xero login
```

### `browser-login`

Capture a browser-authenticated Xero session for bank reconciliation.

```bash
officedesk-plugin-xero browser-login
```

### `get-accounts`

```bash
officedesk-plugin-xero get-accounts
```

### `get-contacts` / `get-contact` / `create-contact` / `update-contact`

```bash
officedesk-plugin-xero get-contacts
officedesk-plugin-xero get-contact --id=CONTACT_ID
officedesk-plugin-xero create-contact --name="Acme Ltd" --email="ops@acme.com"
officedesk-plugin-xero update-contact --id=CONTACT_ID --name="Acme Pte Ltd"
```

### `get-tax-rates`

```bash
officedesk-plugin-xero get-tax-rates
```

### `get-branding-themes`

```bash
officedesk-plugin-xero get-branding-themes
```

### `draft-invoice` / `update-invoice` / `authorise-invoice` / `send-invoice` / `delete-invoice`

```bash
officedesk-plugin-xero draft-invoice --contact-id=CONTACT_ID --amount=150.00
officedesk-plugin-xero update-invoice --id=INVOICE_ID --amount=200.00
officedesk-plugin-xero authorise-invoice --id=INVOICE_ID
officedesk-plugin-xero send-invoice --id=INVOICE_ID
officedesk-plugin-xero delete-invoice --id=INVOICE_ID
```

### `list-invoice-attachments` / `download-invoice-pdf` / `download-invoice-attachment`

```bash
officedesk-plugin-xero list-invoice-attachments --id=INVOICE_ID
officedesk-plugin-xero download-invoice-pdf --id=INVOICE_ID
officedesk-plugin-xero download-invoice-attachment --id=INVOICE_ID --attachment-id=ATTACHMENT_ID
```

### `draft-bill` / `get-bills` / `update-bill` / `submit-bill` / `authorise-bill` / `pay-bill` / `void-bill` / `delete-bill` / `attach-to-bill`

```bash
officedesk-plugin-xero get-bills
officedesk-plugin-xero draft-bill --contact-id=CONTACT_ID --amount=500.00
officedesk-plugin-xero authorise-bill --id=BILL_ID
officedesk-plugin-xero pay-bill --id=BILL_ID --account-id=ACCOUNT_ID --date=2026-04-14 --amount=500.00
officedesk-plugin-xero attach-to-bill --id=BILL_ID --file=./invoice.pdf
```

### `get-bank-statement-lines`

Retrieve imported bank statement lines with `statementLineId`, `bankStatementId`, and `bankAccountId`.

```bash
officedesk-plugin-xero get-bank-statement-lines --bankAccountId=<BANK_ACCOUNT_ID>
```

**Options**

| Flag | Description |
|---|---|
| `--bankAccountId=ID` | **(Required)** Bank account ID |
| `--tenantId=ID` | Tenant ID override |
| `--status=STATUS` | Line status (default: `unreconciled`) |
| `--limit=N` | Maximum results (default: `50`) |
| `--offset=N` | Pagination offset (default: `0`) |
| `--output=PATH` | Override the cache output path |

After you capture the browser session once, `get-bank-statement-lines` reuses the saved Xero auth data and does not launch a browser for each fetch.

### `reconcile`

Reconcile a bank transaction against a specific statement line.

```bash
officedesk-plugin-xero reconcile \
  --type=SPEND \
  --contactId=<CONTACT_ID> \
  --accountCode=<ACCOUNT_CODE> \
  --taxType=<TAX_TYPE> \
  --date=2026-04-14 \
  --amount=600.00 \
  --description="Director loan repayment" \
  --statementLineId=<STATEMENT_LINE_ID> \
  --bankAccountId=<BANK_ACCOUNT_ID> \
  --bankStatementId=<BANK_STATEMENT_ID>
```

If the saved browser session is missing, the reconcile flow can prompt for `browser-login` or run it automatically with `--auto-login`.

## Exact reconciliation flow

1. Create or identify the bank transaction you want to reconcile.
2. Run `get-bank-statement-lines` to find the matching `statementLineId` and `bankStatementId`.
3. Run `reconcile` against that exact line.

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for tokens and config (default: `~/.officedesk/`) |

## License

This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.
