---
description: Add or update MCP (Model Context Protocol) servers in .config/mcp.json for symlinked tool configurations
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

The text the user typed after the command may specify:
- Server name and type to add
- Connection details (URL, credentials, paths)
- Whether to list existing servers
- Specific configuration options

---

# MCP Server Configuration

This command manages MCP server entries in `.config/mcp.json`. Since this file is symlinked to opencode and antigravity configurations, changes automatically propagate to both tools.

## Target File

**Location:** `.config/mcp.json` (relative to this repository root)

**Symlink Targets:**
- `~/.config/opencode/mcp.json`
- `~/.gemini/antigravity/mcp.json`

---

## Phase 1: Read Current Configuration

### 1.1 Check for Existing Config

```bash
cat .config/mcp.json 2>/dev/null || echo "{}"
```

**If file doesn't exist:** Create `.config/` directory and initialize with empty config:
```json
{
  "mcpServers": {}
}
```

### 1.2 Display Current Servers

Output a summary table of existing servers:

```
## Current MCP Servers

| Domain | Server | Status |
|--------|--------|--------|
| [domain] | [server_name] | Configured |
```

---

## Phase 2: Determine Action

Based on user input, determine the action:

1. **Add new server** - User specifies server type and details
2. **Update existing server** - User specifies server name to modify
3. **Remove server** - User explicitly requests removal
4. **List servers** - User wants to see current configuration

**If no input provided:** Prompt user for what they want to add.

---

## Phase 3: Server Configuration

### 3.1 Common Server Templates

Use these templates based on server type:

#### Kubernetes
```json
{
  "kubernetes": {
    "command": "npx",
    "args": ["-y", "@anthropic/kubernetes-mcp-server@latest"]
  }
}
```

#### GitHub
```json
{
  "github": {
    "command": "npx",
    "args": ["-y", "@anthropic/github-mcp-server@latest"],
    "env": {
      "GITHUB_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

#### Gitea
```json
{
  "gitea": {
    "command": "npx",
    "args": ["-y", "gitea-mcp-server@latest"],
    "env": {
      "GITEA_URL": "${GITEA_URL}",
      "GITEA_TOKEN": "${GITEA_TOKEN}"
    }
  }
}
```

#### Custom Server
For servers not listed above, prompt for:
- Server name
- Command to run
- Arguments
- Environment variables needed

---

## Phase 4: Update Configuration

### 4.1 Merge New Server

Read existing config, add/update the server entry, preserve existing servers:

```bash
# Ensure .config directory exists
mkdir -p .config
```

### 4.2 Write Updated Config

Write the merged JSON to `.config/mcp.json` with proper formatting (2-space indent).

### 4.3 Validate JSON

```bash
cat .config/mcp.json | jq .
```

---

## Phase 5: Output Summary

```
## MCP Configuration Updated

| Domain | Server | Status |
|--------|--------|--------|
| [domain] | [server_name] | [Added/Updated/Already existed] |

**Environment variables you'll need to set:**
- VAR_NAME - Description of what this variable is for
```

### 5.1 Symlink Reminder

```
Since this file is symlinked to opencode and antigravity configs, both tools should pick up these new servers.

**Symlink verification:**
- ~/.config/opencode/mcp.json -> .config/mcp.json
- ~/.gemini/antigravity/mcp.json -> .config/mcp.json
```

---

## Error Handling

### Invalid JSON
```
❌ Error: Invalid JSON in .config/mcp.json

**Suggested fix:** Check for syntax errors or restore from backup
```

### Missing Environment Variables
```
⚠️ Warning: The following environment variables are required but may not be set:
- VAR_NAME

Set these in your shell profile or .env file before using the MCP server.
```

---

## Examples

**Add Kubernetes MCP:**
```
/create_mcp kubernetes
```

**Add custom server:**
```
/create_mcp my-server command="python" args="-m my_mcp_server"
```

**List current servers:**
```
/create_mcp list
```
