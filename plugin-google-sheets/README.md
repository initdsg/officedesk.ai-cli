# @officedesk/plugin-google-sheets

Google Sheets integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Provides handlers for reading and writing Google Sheets data.

## Installation

```bash
npm install -g @officedesk/plugin-google-sheets
```

## Setup

Sign in with the browser OAuth flow before using the plugin:

```bash
officedesk-plugin-sheets login
```

The token is written to `$OFFICEDESK_HOME/plugins/plugin-google-sheets/tokens/token-set.json`. `OFFICEDESK_HOME` defaults to `~/.officedesk/`.

The plugin requires the `https://www.googleapis.com/auth/spreadsheets` scope.

## CLI reference

```
officedesk-plugin-sheets <command> [options]
```

### `add-sheet`

Create a new sheet tab in a spreadsheet, optionally seeding row 1 with headers.

```bash
officedesk-plugin-sheets add-sheet \
    --spreadsheet-id=<SHEET_ID> \
    --sheet="Serverless Comparison" \
    --headers='["#","Category","Traditional (RM/year)","Serverless (RM/year)","Difference","Notes"]'
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `--spreadsheet-id` | Yes | — | The spreadsheet ID from the sheet URL |
| `--sheet` | Yes | — | The new sheet/tab name |
| `--headers` | No | — | JSON array of headers to write into row 1 after creation |

### `append-row`

Append a single row by mapping object keys to column headers in row 1.

```bash
officedesk-plugin-sheets append-row \
    --spreadsheet-id=<SHEET_ID> \
    --sheet=Sheet1 \
    --data='{"Name":"John","Amount":42}'
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `--spreadsheet-id` | Yes | — | The spreadsheet ID |
| `--sheet` | No | `Sheet1` | The sheet/tab name |
| `--data` | Yes | — | JSON object with keys matching column headers |

### `get-header`

Read row 1 from a sheet and return the current column headers.

```bash
officedesk-plugin-sheets get-header \
    --spreadsheet-id=<SHEET_ID> \
    --sheet=Sheet1
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `--spreadsheet-id` | Yes | — | The spreadsheet ID |
| `--sheet` | No | `Sheet1` | The sheet/tab name |

### `delete-rows`

Delete one or more rows and shift remaining rows up.

```bash
officedesk-plugin-sheets delete-rows \
    --spreadsheet-id=<SHEET_ID> \
    --rows=16,21,26 \
    --sheet=Sheet1
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `--spreadsheet-id` | Yes | — | The spreadsheet ID |
| `--rows` | Yes | — | Comma-separated 1-indexed row numbers to delete |
| `--sheet` | No | `Sheet1` | The sheet/tab name |

Row 1 (headers) cannot be deleted. Multiple rows are deleted from highest to lowest in a single `batchUpdate` request.

### `set-header`

Write headers into row 1 of a sheet.

```bash
officedesk-plugin-sheets set-header \
    --spreadsheet-id=<SHEET_ID> \
    --headers='["Company","Contact Name","Role","Email","Phone","Website","Notes"]'
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `--spreadsheet-id` | Yes | — | The spreadsheet ID |
| `--headers` | Yes | — | JSON array of header names |
| `--sheet` | No | `Sheet1` | The sheet/tab name |

Returns `success: false` if row 1 already contains headers. `set-headers` is accepted as a legacy alias.

### `update-cell`

Update a single cell using `USER_ENTERED` or `RAW` input mode.

```bash
officedesk-plugin-sheets update-cell \
    --spreadsheet-id=<SHEET_ID> \
    --cell=B16 \
    --value="=== DEVELOPMENT MANPOWER ===" \
    --sheet="Phase 2" \
    --raw
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `--spreadsheet-id` | Yes | — | The spreadsheet ID |
| `--cell` | Yes | — | Cell reference in A1 notation |
| `--value` | Yes | — | New value to write |
| `--sheet` | No | `Sheet1` | The sheet/tab name |
| `--raw` | No | `false` | Use `RAW` mode instead of `USER_ENTERED` |

Use `--raw` when text such as `=== heading ===` should be written literally rather than interpreted as a formula.

## Programmatic API

```typescript
import {
    addSheet,
    appendRow,
    getHeader,
    deleteRows,
    setHeaders,
    updateCell,
} from '@officedesk/plugin-google-sheets';

const result = await addSheet({
    spreadsheetId: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms',
    sheetName: 'Serverless Comparison',
    headers: ['#', 'Category', 'Traditional (RM/year)', 'Serverless (RM/year)', 'Difference', 'Notes'],
});

await appendRow({
    spreadsheetId: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms',
    sheetName: 'Sheet1',
    rowData: { Name: 'John', Email: 'john@example.com', Amount: 42 },
});
```

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for tokens and config (default: `~/.officedesk/`) |

## License

This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.
