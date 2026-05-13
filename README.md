# OfficeDesk.ai

Master CLI for [OfficeDesk AI](https://officedesk.ai). Discovers and delegates to `officedesk-plugin-*` executables in `$PATH` using the Git-style delegation pattern.

## Installation

### macOS & Linux (bash/zsh)

```bash
curl -fsSL https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install | bash
```

This installs `officedesk` to `~/.officedesk/bin` (or `%USERPROFILE%\.officedesk\bin` on Windows) and adds it to your PATH.

To install specific plugins alongside the CLI, pass them as arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install | bash -s officedesk plugin-gmail plugin-jira
```

### Windows (PowerShell)

```powershell
# With OfficeDesk CLI only:
iwr https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install.ps1 | iex

# Install CLI and specific plugins at once:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install.ps1))) officedesk plugin-gmail plugin-jira
```

- Installation must be done through **PowerShell** (`powershell.exe`), not Command Prompt.
- If you encounter `running scripts is disabled on this system`, use one of:
  - **Temporary Fix (Safest)**

    Allows scripts for just the current session:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
    ```
  - **Permanent Fix (For Developers)**

    Run PowerShell **as Administrator** to allow local scripts permanently:
    ```powershell
    Set-ExecutionPolicy RemoteSigned
    ```
    `RemoteSigned` means scripts you wrote locally will run, but scripts downloaded from the internet must be signed by a trusted publisher.
- Installs to `%USERPROFILE%\.officedesk\bin` and adds it to the User PATH.
- You may need to restart your terminal for the PATH update to take effect.
- Downloads the latest `.exe` for each product (no architecture suffix required).


Available products:

| Product | Description |
|---|---|
| `officedesk` | Master CLI |
| `plugin-email` | Email |
| `plugin-gmail` | Gmail |
| `plugin-google-calendar` | Google Calendar |
| `plugin-google-sheets` | Google Sheets |
| `plugin-jira` | Jira |
| `plugin-odoo` | Odoo |
| `plugin-xero` | Xero |

## How it works

### Notes for Windows Users
- All executables are installed as `.exe` files (no platform/arch suffix is needed).
- Installation directory is `%USERPROFILE%\.officedesk\bin` and added to your PATH (user scope).
- If you install new plugins or CLI, restart your terminal to refresh the PATH.
- Usage, plugin discovery, and commands are otherwise identical.


The `officedesk` CLI scans `$PATH` for executables matching the `officedesk-plugin-*` naming convention and delegates commands to them:

```
officedesk <plugin> <command> [options]
```

This means you can install any OfficeDesk plugin globally and use it immediately through the master CLI without any additional configuration.

## Quick start

```bash
# Install the CLI and a plugin
curl -fsSL https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install | bash -s officedesk plugin-gmail

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

## Plugin discovery

The CLI scans the following locations for `officedesk-plugin-*` executables, in order:

1. All directories in `$PATH`
2. `./dist/bin/` relative to the current working directory
3. The directory containing the `officedesk` binary itself

The first matching executable found for each plugin name wins. Platform-specific variants (e.g. `officedesk-plugin-gmail-linux`) and `.exe` suffixes are handled automatically.

## Installing plugins

Install additional plugins by passing their names to the installer:

**macOS/Linux**:
```bash
curl -fsSL https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install | bash -s plugin-gmail plugin-google-calendar plugin-google-sheets plugin-jira plugin-email plugin-odoo plugin-xero
```

**Windows (PowerShell)**:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install.ps1))) plugin-gmail plugin-google-calendar plugin-google-sheets plugin-jira plugin-email plugin-odoo plugin-xero
```

Once installed, they are automatically discovered the next time you run `officedesk`.

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for plugin config and tokens (default: `~/.officedesk/`) |

`OFFICEDESK_HOME` is passed through to each plugin binary when commands are delegated.

## License

ISC
