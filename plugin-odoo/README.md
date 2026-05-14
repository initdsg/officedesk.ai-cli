# @officedesk/plugin-odoo

Odoo integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Supports both Odoo 19 JSON-2 and legacy XML-RPC instances, with typed wrappers for contacts, invoices, and orders.

## Installation

```bash
npm install -g @officedesk/plugin-odoo
```

## Commands

- `configure` — prompts for Odoo connection settings and stores them in the profile `.env` file
- `login` — validates Odoo connection settings non-interactively and writes them to the profile `.env` file
- `list-profiles` — lists configured default and named profiles
- `version` — reads `/web/version`
- `call` — executes a public Odoo model method through JSON-2 or XML-RPC
- `list-contacts`, `get-contact`, `create-contact`, `update-contact` — wrap `res.partner`
- `list-invoices`, `get-invoice` — wrap `account.move`
- `list-orders`, `get-order`, `confirm-order` — wrap `sale.order`

## Configuration

```bash
officedesk-plugin-odoo configure
```

Or validate and save the connection in one step:

```bash
officedesk-plugin-odoo login --url=https://erp.example.com --api-key=secret --api-mode=json2
```

Credentials are written to:

- Default profile: `$OFFICEDESK_HOME/plugins/plugin-odoo/.env`
- Named profile: `$OFFICEDESK_HOME/plugins/plugin-odoo/.env.<profile>`

`OFFICEDESK_HOME` defaults to `~/.officedesk/`.

| Variable | Required | Description |
|---|---|---|
| `ODOO_URL` | ✓ | Odoo host root (e.g. `http://localhost:8069`) |
| `ODOO_DATABASE` | ✓ | Database name |
| `ODOO_API_KEY` | ✓ | API key |
| `ODOO_USERNAME` | — | Username |
| `ODOO_PASSWORD` | — | Password |
| `ODOO_API_MODE` | — | `json2` or `xmlrpc`; auto-detected when omitted |

`ODOO_URL` should be the Odoo host root, not the API path (e.g. `http://localhost:8069`, not `http://localhost:8069/json/2`).

Named profiles are supported via `--profile=<name>` and write to `.env.<profile>`.

## CLI reference

```
officedesk-plugin-odoo <command> [options]
```

### `version`

Read the server version:

```bash
officedesk-plugin-odoo version
```

### `call`

Execute a generic ORM method:

```bash
officedesk-plugin-odoo call --model=res.partner --method=search_read --json='{"domain":[["is_company","=",true]],"fields":["name","email"],"limit":10}'
```

Shorthand payload flags are also supported:

```bash
officedesk-plugin-odoo call --model=res.partner --method=search_read --domain='is_company = true' --fields=name,email --limit=10 --order='name asc'
```

Supported shorthand flags: `--ids`, `--fields`, `--domain`, `--context`, `--limit`, `--offset`, `--order`, `--values`.

For XML-RPC specific cases, use `--args` and `--kwargs`. For advanced methods, fall back to `--json`.

### `list-contacts` / `get-contact` / `create-contact` / `update-contact`

```bash
officedesk-plugin-odoo list-contacts --company-only --limit=10
officedesk-plugin-odoo get-contact --id=42
officedesk-plugin-odoo create-contact --name='Acme Pte Ltd' --email='ops@example.com' --is-company
officedesk-plugin-odoo update-contact --id=7 --email='finance@example.com'
```

### `list-invoices` / `get-invoice`

```bash
officedesk-plugin-odoo list-invoices
officedesk-plugin-odoo get-invoice --id=42
```

### `list-orders` / `get-order` / `confirm-order`

```bash
officedesk-plugin-odoo list-orders --states=draft,sale --limit=10
officedesk-plugin-odoo get-order --id=77
officedesk-plugin-odoo confirm-order --id=77
```

### `list-profiles`

```bash
officedesk-plugin-odoo list-profiles
```

## Notes

- JSON output is written to stdout only.
- Errors and status messages are written to stderr only.
- When `ODOO_API_MODE` is not set, the plugin auto-detects JSON-2 for Odoo 19+ and XML-RPC for older instances.

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for credentials and config (default: `~/.officedesk/`) |

## License

This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.
