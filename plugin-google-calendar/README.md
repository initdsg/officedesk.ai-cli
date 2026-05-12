# @officedesk/plugin-google-calendar

Google Calendar integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Manages calendars and events across multiple Google Calendar account profiles.

## Installation

```bash
npm install -g @officedesk/plugin-google-calendar
```

## Quick start

```bash
# Authenticate your Google account
officedesk-plugin-google-calendar login

# List your calendars
officedesk-plugin-google-calendar list-calendars

# List events on the primary calendar
officedesk-plugin-google-calendar list-events --calendar-id=primary
```

## Configuration

Token files are stored under `OFFICEDESK_HOME` (defaults to `~/.officedesk/`):

| Path | Description |
|---|---|
| `$OFFICEDESK_HOME/plugins/plugin-google-calendar/tokens/token-set.json` | Default account token |
| `$OFFICEDESK_HOME/plugins/plugin-google-calendar/tokens/token-set.<profile>.json` | Named profile token |

## CLI reference

```
officedesk-plugin-google-calendar <command> [options]
```

### `login`

Authenticate a Google Calendar account via the browser OAuth flow.

```bash
officedesk-plugin-google-calendar login
officedesk-plugin-google-calendar login --profile=work
```

### `list-profiles`

List all configured Google Calendar profiles.

```bash
officedesk-plugin-google-calendar list-profiles
```

Returns JSON describing every detected default or named profile and whether each one has a token file.

### `list-calendars`

List all calendars accessible to the authenticated account.

```bash
officedesk-plugin-google-calendar list-calendars
officedesk-plugin-google-calendar list-calendars --profile=work
```

### `list-events`

List events for a calendar.

```bash
officedesk-plugin-google-calendar list-events --calendar-id=primary
officedesk-plugin-google-calendar list-events --calendar-id=primary --max=25 --profile=work
```

**Options**

| Flag | Description |
|---|---|
| `--calendar-id=ID` | **(Required)** Calendar ID (`primary` for the main calendar) |
| `--max=N` | Maximum number of events to return |
| `--profile=NAME` | Named profile to use |

### `create-event`

Create a new calendar event.

```bash
officedesk-plugin-google-calendar create-event \
  --calendar-id=primary \
  --summary="Team Sync" \
  --start="2026-04-17T10:00:00" \
  --end="2026-04-17T11:00:00"
```

**Options**

| Flag | Description |
|---|---|
| `--calendar-id=ID` | **(Required)** Calendar ID |
| `--summary=TEXT` | **(Required)** Event title |
| `--start=DATETIME` | **(Required)** Start date-time (ISO 8601) |
| `--end=DATETIME` | **(Required)** End date-time (ISO 8601) |
| `--profile=NAME` | Named profile to use |

### `delete-event`

Delete a calendar event.

```bash
officedesk-plugin-google-calendar delete-event --calendar-id=primary --event-id=EVENT_ID
officedesk-plugin-google-calendar delete-event --calendar-id=primary --event-id=EVENT_ID --profile=work
```

### `free-busy`

Query free/busy availability for a calendar.

```bash
officedesk-plugin-google-calendar free-busy --calendar-id=primary
```

## Multiple profiles

```bash
officedesk-plugin-google-calendar login
officedesk-plugin-google-calendar login --profile=work

officedesk-plugin-google-calendar list-events --calendar-id=primary --profile=work
```

## Environment variables

| Variable | Description |
|---|---|
| `OFFICEDESK_HOME` | Base directory for tokens and config (default: `~/.officedesk/`) |

## License

ISC
