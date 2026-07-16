# officedesk

Master CLI for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Discovers and delegates to `officedesk-plugin-*` executables in `$PATH` using the Git-style delegation pattern.

## Installation

```bash
npm install -g officedesk
```

## How it works

The `officedesk` CLI scans `$PATH` for executables matching the `officedesk-plugin-*` naming convention and delegates commands to them:

```
officedesk <plugin> <command> [options]
```

This means you can install any OfficeDesk plugin globally and use it immediately through the master CLI without any additional configuration.

## Quick start

```bash
# Install the CLI and a plugin
npm install -g officedesk @officedesk/plugin-gmail

# Delegate a command to the plugin
officedesk plugin-gmail search-messages --query="subject:invoice"

# List all discovered plugins
officedesk --list

# Show aggregated help from all discovered plugins
officedesk --help
```

## Usage

```
officedesk <plugin> <command> [options]
officedesk --help
officedesk --list
officedesk list-profiles
officedesk mcp-serve
```

### Delegate to a plugin

```bash
officedesk plugin-jira get-ticket --issue=PROJ-123
officedesk plugin-xero get-accounts
officedesk plugin-gmail search-messages --query="from:boss"
officedesk plugin-slack send-message --text="Build complete"
officedesk plugin-google-drive list-files --folder-path=Finance
officedesk plugin-odoo list-invoices
```

The plugin name can be passed with or without the `plugin-` prefix:

```bash
officedesk plugin-gmail search-messages --query="subject:invoice"
officedesk gmail search-messages --query="subject:invoice"   # same thing
```

### Plugin aliases

Some plugins have short aliases:

| Alias | Resolves to |
|---|---|
| `sheets` | `plugin-google-sheets` |
| `google-sheets` | `plugin-google-sheets` |
| `plugin-sheets` | `plugin-google-sheets` |

```bash
officedesk sheets append-row --spreadsheet-id=ID --sheet=Sheet1 --data='{"Name":"John"}'
```

## Global commands

### `--help`

Show aggregated help output from all discovered plugins.

```bash
officedesk --help
```

### `--list`

List all discovered plugins and their binary paths.

```bash
officedesk --list
```

### `list-profiles`

Aggregate and display configured profiles across all profile-aware plugins (`plugin-aws`, `plugin-gmail`, `plugin-google-drive`, `plugin-slack`).

```bash
officedesk list-profiles
```

Returns JSON with profiles from each plugin that supports the `list-profiles` command.

### `--version`

Print the CLI version.

```bash
officedesk --version
```

### `mcp-serve`

Start an MCP (Model Context Protocol) server over stdio, exposing the plugin surface as MCP tools. This is what Claude Desktop launches — no separate bridge, Python runtime, or install step is required; the server is built into the CLI binary on all platforms (macOS, Linux, Windows).

```bash
officedesk mcp-serve
```

Tools exposed:

| Tool | Description |
|---|---|
| `officedesk_run` | Run a CLI command: `args[0]` must be a discovered plugin (or `--version`/`--help`); anything else is refused. Returns `{ exitCode, stdout, stderr }` as JSON. Accepts an optional `timeout_seconds` (default 120). |
| `officedesk_doctor` | Report the resolved binary path, `OFFICEDESK_HOME`, CLI version, and the discovered plugin list. |

Plugins are rediscovered on every tool call, so a newly installed plugin is callable immediately — no restart or configuration change needed.

To connect Claude Desktop, add this to `claude_desktop_config.json` (Claude Desktop → Settings → Developer → Edit Config):

```json
{
  "mcpServers": {
    "officedesk": {
      "command": "/Users/<you>/.officedesk/bin/officedesk",
      "args": ["mcp-serve"],
      "env": { "OFFICEDESK_HOME": "/Users/<you>/.officedesk" }
    }
  }
}
```

## Plugin discovery

The CLI scans the following locations for `officedesk-plugin-*` executables, in order:

1. All directories in `$PATH`
2. `./dist/bin/` relative to the current working directory
3. The directory containing the `officedesk` binary itself

The first matching executable found for each plugin name wins. Platform-specific variants (e.g. `officedesk-plugin-gmail-linux`) and `.exe` suffixes are handled automatically.

## Installing plugins

Each OfficeDesk plugin is a separate npm package. Install the ones you need globally alongside the CLI:

```bash
npm install -g officedesk \
  @officedesk/plugin-gmail \
  @officedesk/plugin-slack \
  @officedesk/plugin-google-drive \
  @officedesk/plugin-jira \
  @officedesk/plugin-xero
```

Once installed, they are automatically discovered the next time you run `officedesk`.

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for plugin config and tokens (default: `~/.officedesk/`) |

`OFFICEDESK_HOME` is passed through to each plugin binary when commands are delegated.

## License

This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.
