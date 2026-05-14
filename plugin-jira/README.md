# @officedesk/plugin-jira

Jira Cloud integration plugin for [OfficeDesk AI](https://github.com/initdsg/officedesk.ai). Manages boards, tickets, comments, and issue attributes via the Jira REST API with OAuth 2.0 (3LO) authentication.

## Installation

```bash
npm install -g @officedesk/plugin-jira
```

## Setup

```bash
officedesk-plugin-jira login
```

The CLI opens the browser, completes the OAuth exchange, then writes the token to `$OFFICEDESK_HOME/plugins/plugin-jira/tokens/token-set.json`. `OFFICEDESK_HOME` defaults to `~/.officedesk/`.

After login, the CLI also lists your accessible Jira sites. Set `JIRA_HOST` in `$OFFICEDESK_HOME/plugins/plugin-jira/.env` to either the site URL or the Atlassian API URL:

```env
JIRA_HOST=https://yoursite.atlassian.net
```

## CLI reference

```
officedesk-plugin-jira <command> [options]
```

### `login`

Authenticate via the browser OAuth flow.

```bash
officedesk-plugin-jira login
```

### `list-boards`

List all Jira boards accessible to the authenticated user.

```bash
officedesk-plugin-jira list-boards
officedesk-plugin-jira list-boards --type=scrum --max-results=10
officedesk-plugin-jira list-boards --name="My Project"
```

### `list-board-tickets`

List all issues on a specific board.

```bash
officedesk-plugin-jira list-board-tickets --board-id=42
officedesk-plugin-jira list-board-tickets --board-id=42 --jql="status = 'In Progress'" --max-results=20
```

### `get-ticket`

View detailed information about a specific issue.

```bash
officedesk-plugin-jira get-ticket --issue=PROJ-123
officedesk-plugin-jira get-ticket --issue=PROJ-123 --fields=summary,status,assignee
officedesk-plugin-jira get-ticket --issue=PROJ-123 --expand=renderedFields
```

### `add-ticket`

Create a new issue in a Jira project.

```bash
officedesk-plugin-jira add-ticket --project=PROJ --summary="New task"
officedesk-plugin-jira add-ticket --project=PROJ --summary="Investigate bug" --type=Bug
officedesk-plugin-jira add-ticket --project=PROJ --summary="New task" --file=issue-fields.json
```

### `add-comment`

Add a new top-level comment to a Jira issue.

```bash
officedesk-plugin-jira add-comment --issue=PROJ-123 --body="Investigating now"
```

### `reply-comment`

Add a reply to an existing comment.

```bash
officedesk-plugin-jira reply-comment --issue=PROJ-123 --comment-id=10000 --body="I will take this"
```

### `update-ticket`

Modify issue fields and/or transition the issue status.

```bash
# Update fields
officedesk-plugin-jira update-ticket --issue=PROJ-123 --fields='{"summary":"Updated title","priority":{"name":"High"}}'

# Update fields from a file
officedesk-plugin-jira update-ticket --issue=PROJ-123 --file=issue-fields.json

# Transition status
officedesk-plugin-jira update-ticket --issue=PROJ-123 --transition=31

# Both
officedesk-plugin-jira update-ticket --issue=PROJ-123 --fields='{"labels":["urgent"]}' --transition=31
```

> To find available transition IDs: `GET /rest/api/3/issue/{issueIdOrKey}/transitions`

## Programmatic API

```typescript
import {
    listBoards,
    listBoardTickets,
    getTicket,
    addTicket,
    addComment,
    replyComment,
    updateTicket,
} from '@officedesk/plugin-jira';

const result = await listBoards({ type: 'scrum', maxResults: 10 });

const ticket = await getTicket({ issueIdOrKey: 'PROJ-123' });

const created = await addTicket({
    project: 'PROJ',
    summary: 'New task',
    issueType: 'Task',
    fields: { labels: ['automation'] },
});

await updateTicket({
    issueIdOrKey: 'PROJ-123',
    fields: { summary: 'Updated title' },
    transition: '31',
});
```

## Environment variables

| Variable | Description |
|---|---|
| `JIRA_HOST` | Jira site URL (e.g. `https://yoursite.atlassian.net`) |
| `OFFICEDESK_HOME` | Base directory for tokens and config (default: `~/.officedesk/`) |

## License

This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.
