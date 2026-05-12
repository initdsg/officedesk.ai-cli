# plugin-odoo Agent Tutorial

This tutorial is written for an AI agent that needs to operate `plugin-odoo` safely and predictably from the repo root using the `officedesk` binary from the shell `PATH`.

## Goal

Use `plugin-odoo` to:

- configure access to an Odoo instance
- inspect which Odoo profiles are available
- verify the target server version before broader work
- call public Odoo model methods through JSON-2 or XML-RPC
- use typed wrappers for `res.partner`, `account.move`, and `sale.order`
- prefer read operations first, then perform write operations only when the user clearly requested them
- use shorthand flags for common payload fields while keeping the request reviewable

## Preferred Invocation

From the workspace root, invoke the master CLI directly and delegate to `plugin-odoo`:

```bash
officedesk plugin-odoo configure
officedesk plugin-odoo configure --profile=production
officedesk plugin-odoo list-profiles
officedesk plugin-odoo version
officedesk plugin-odoo version --profile=production
officedesk plugin-odoo call --model=res.users --method=context_get
officedesk plugin-odoo call --model=res.partner --method=search_read --domain='is_company = true' --fields=name,email --limit=10
officedesk plugin-odoo list-contacts --company-only --limit=10
officedesk plugin-odoo get-contact --id=7
officedesk plugin-odoo create-contact --name='Acme Pte Ltd' --email='ops@example.com' --is-company
officedesk plugin-odoo list-invoices --states=posted --limit=10
officedesk plugin-odoo get-invoice --id=42
officedesk plugin-odoo list-orders --states=draft,sale --limit=10
officedesk plugin-odoo get-order --id=77
officedesk plugin-odoo confirm-order --id=77
```

Assume `officedesk` is already installed or otherwise available on the shell `PATH`.

Set `OFFICEDESK_HOME=$PWD` when you want plugin state and profile env files to stay inside the current workspace.

The delegated command shape is always:

```bash
officedesk plugin-odoo <command> [args]
```

If `officedesk` is not available, use the package directly:

```bash
pnpm --filter @officedesk/plugin-odoo <command> [args]
```

In this tutorial, all examples use `officedesk plugin-odoo ...`.

## Flag Syntax

All flags accept both `--flag=value` and `--flag value` forms interchangeably. `-h` is a short form for `--help`.

## Core Rules

1. Run `version` before the first live API call unless you already know the target instance and profile are correct.
2. Treat the configured `profile` as the stable identifier for one Odoo environment.
3. Use `list-profiles` before live work unless you already know which profile you need.
4. Prefer read only model methods first, such as `context_get`, `search`, `read`, `search_read`, `search_count`, and `fields_get`.
5. Do not use write methods such as `create`, `write`, `unlink`, or action methods unless the user explicitly asked for a change.
6. Prefer typed wrapper commands and shorthand flags for common operations before falling back to raw `--json`.
7. Expect JSON output envelopes from the plugin. Inspect `data` for results and `meta` for execution context.
8. The plugin auto detects JSON-2 for Odoo 19+ and uses XML-RPC fallback for older instances unless `ODOO_API_MODE` is set explicitly.
9. When a deployment has multiple databases on one host, ensure `ODOO_DATABASE` is configured.
10. When a call fails with authentication or access errors, stop and fix credentials or permissions before retrying broader operations.

## Command Selection

| Need | Command |
|---|---|
| Set up Odoo connection settings | `configure` |
| Discover available profiles | `list-profiles` |
| Verify the target server version | `version` |
| Run any public model method through JSON-2 or XML-RPC | `call` |
| List or inspect contacts | `list-contacts`, `get-contact` |
| Create or update contacts | `create-contact`, `update-contact` |
| List or inspect invoices | `list-invoices`, `get-invoice` |
| List or inspect sale orders | `list-orders`, `get-order` |
| Confirm a sale order | `confirm-order` |

## 1. Configure

Use `configure` when the plugin has not been set up yet or when the Odoo URL, database, or API key changed.

Default profile:

```bash
officedesk plugin-odoo configure
```

Named profile:

```bash
officedesk plugin-odoo configure --profile=production
officedesk plugin-odoo configure --profile=staging
```

What it prompts for:

- `ODOO_URL`
- `ODOO_DATABASE`
- `ODOO_API_KEY`
- `ODOO_USERNAME`
- `ODOO_PASSWORD`
- `ODOO_API_MODE`

Where config is written:

- default profile: `$OFFICEDESK_HOME/plugins/plugin-odoo/.env`
- named profile: `$OFFICEDESK_HOME/plugins/plugin-odoo/.env.<profile>`

What an agent should know:

- `ODOO_URL` should be the base URL, for example `https://erp.example.com`
- `ODOO_DATABASE` is optional for single database deployments but recommended for multi database hosts
- `ODOO_API_KEY` is needed for JSON-2 profiles
- `ODOO_USERNAME` and `ODOO_PASSWORD` are needed for XML-RPC profiles
- leave `ODOO_API_MODE` empty unless you need to force `json2` or `xmlrpc`
- profile names only allow letters, numbers, dots, underscores, and hyphens

Use it when:

- the plugin throws missing `ODOO_URL`, `ODOO_API_KEY`, or XML-RPC credentials
- the user needs a new environment such as `production` or `staging`
- the instance URL, database name, or API key changed

## 2. List Profiles

Use `list-profiles` before doing live work when you are not certain which environments are configured.

```bash
officedesk plugin-odoo list-profiles
```

What it does:

- discovers plugin env files for the default and named profiles
- returns structured profile metadata

What an agent should inspect:

- `plugin`
- `profiles`
- `count`
- `profiles[].name`
- `profiles[].profile`
- `profiles[].isDefault`
- `profiles[].hasEnv`
- `profiles[].envPath`

Use it when:

- the user mentions a specific environment and you need to confirm the profile exists
- you need to determine whether a default profile is configured
- you want to verify which env file path the plugin will load

## 3. Version

Use `version` as the first live check against an Odoo environment.

```bash
officedesk plugin-odoo version
officedesk plugin-odoo version --profile=production
```

What it does:

- calls `/web/version`
- returns the reported Odoo version and parsed major version

What the JSON looks like:

```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "version": "19.0",
      "versionInfo": [19, 0, 0, "final", 0, ""],
      "major": 19
    }
  ],
  "meta": {
    "profile": "production"
  }
}
```

What an agent should inspect:

- `data[0].version`
- `data[0].major`
- `meta.profile`

Use it when:

- confirming you are pointed at the intended Odoo server
- checking whether the instance will use JSON-2 or XML-RPC
- validating that the selected profile is healthy before broader API calls

## 4. Generic Call

Use `call` for public Odoo model methods exposed by JSON-2 or XML-RPC.

```bash
officedesk plugin-odoo call --model=res.users --method=context_get
officedesk plugin-odoo call --model=res.partner --method=search_read --domain='is_company = true' --fields=name,email --limit=10
officedesk plugin-odoo call --model=res.partner --method=read --ids=7 --fields=name,email,phone
officedesk plugin-odoo call --model=res.partner --method=create --values='{"name":"Acme Pte Ltd","email":"ops@example.com"}'
officedesk plugin-odoo call --model=account.move --method=search_count --domain='move_type = out_invoice'
```

Rules for argument placement:

- plugin flags and command flags all go in the normal CLI position
- use shorthand flags for common payload parts
- use `--json` when shorthand is not expressive enough

Required flags:

- `--model=MODEL`
- `--method=METHOD`

Optional flags:

- `--json={...}`
- `--ids=1,2`
- `--fields=name,email`
- `--domain='name ilike acme; is_company = true'`
- `--context=lang=en_US,active=true`
- `--limit=10`
- `--offset=5`
- `--order='name asc'`
- `--values={...}`
- `--args=[...]`
- `--kwargs={...}`
- `--profile=NAME`

What the plugin returns:

```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "id": 7,
      "name": "Acme Pte Ltd"
    },
    {
      "id": 9,
      "name": "Deco Addict"
    }
  ],
  "meta": {
    "model": "res.partner",
    "method": "search_read",
    "profile": "production",
    "rawResultType": "array"
  }
}
```

What an agent should inspect:

- `data`
- `count`
- `meta.model`
- `meta.method`
- `meta.profile`
- `meta.rawResultType`

Recommended read first commands:

```bash
officedesk plugin-odoo call --model=res.users --method=context_get
officedesk plugin-odoo call --model=res.partner --method=fields_get --attributes=string,type,help
officedesk plugin-odoo list-contacts --company-only --limit=10
officedesk plugin-odoo list-invoices --states=posted --limit=10
officedesk plugin-odoo list-orders --states=draft,sale --limit=10
```

Write operations require more care:

- `create`
- `write`
- `unlink`
- model specific actions such as `action_confirm`

For those calls:

1. confirm the exact model and method
2. review the full `--json` body
3. prefer a read first check to confirm target records
4. execute the write only when the user explicitly asked for it

## Typed Wrapper Commands

Prefer these wrappers for common high value models:

Contacts:

```bash
officedesk plugin-odoo list-contacts --company-only --limit=10
officedesk plugin-odoo get-contact --id=7
officedesk plugin-odoo create-contact --name='Acme Pte Ltd' --email='ops@example.com' --is-company
officedesk plugin-odoo update-contact --id=7 --email='finance@example.com'
```

Invoices:

```bash
officedesk plugin-odoo list-invoices --states=posted --limit=10
officedesk plugin-odoo get-invoice --id=42
```

Orders:

```bash
officedesk plugin-odoo list-orders --states=draft,sale --limit=10
officedesk plugin-odoo get-order --id=77
officedesk plugin-odoo confirm-order --id=77
```

## Payload Patterns

Common request body shapes:

Search:

```json
{
  "domain": [["is_company", "=", true]],
  "limit": 10,
  "order": "name asc"
}
```

Read specific ids:

```json
{
  "ids": [7, 9],
  "fields": ["name", "email", "phone"]
}
```

Search and read in one call:

```json
{
  "domain": [["move_type", "=", "out_invoice"]],
  "fields": ["name", "partner_id", "amount_total"],
  "limit": 10
}
```

Create a record:

```json
{
  "values": {
    "name": "Acme Pte Ltd",
    "email": "ops@example.com"
  }
}
```

Update a record:

```json
{
  "ids": [7],
  "values": {
    "email": "finance@example.com"
  }
}
```

Context aware call:

```json
{
  "context": {
    "lang": "en_US"
  },
  "domain": [["name", "ilike", "acme"]],
  "fields": ["name"]
}
```

## Safe Workflow

For a new environment:

1. `officedesk plugin-odoo list-profiles`
2. `officedesk plugin-odoo version --profile=<name>`
3. `officedesk plugin-odoo call --model=res.users --method=context_get --profile=<name>`
4. `officedesk plugin-odoo call --model=<target> --method=fields_get --json='{"attributes":["string","type"]}' --profile=<name>`
5. run the intended read or write call

For a record lookup before editing:

1. `search` or `search_read` equivalent via `call`
2. verify record ids and fields
3. run `write` only after the target is confirmed

## Current Limitations

- JSON-2 is the preferred transport for Odoo 19 and newer, but older deployments may require XML-RPC credentials and different method support.
- The typed convenience commands cover contacts, invoices, and sale orders. Use `call` for other models or unsupported operations.
- There is no dry run mode. Treat write methods as live changes.

## Good Defaults For Agents

- start with `list-profiles` when profile state is unknown
- start with `version` when the selected environment has not been verified yet
- prefer `search_read` over separate `search` then `read` when possible
- use small `limit` values during exploration
- request only the fields you need
- stop after permission errors and ask for corrected access rather than retrying broader calls