# Skill: mcp-server-patterns

## Purpose

Build and review MCP (Model Context Protocol) servers — tool definitions, resource handlers, prompt templates, transport setup, and security for Claude-compatible MCP integrations.

## Trigger

- Building a new MCP server to extend Claude Code / OpenClaw
- Reviewing an existing MCP server for correctness and security
- Asked about MCP tool schemas, resource URIs, or transport configuration

## Trigger

`/mcp-server-patterns` or `apply mcp-server patterns to [target]`

## Agents

- `typescript-reviewer` or `python-reviewer` — language quality
- `security-reviewer` — tool input validation and injection risks

## Patterns

### Server Setup (TypeScript SDK)

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "my-server", version: "1.0.0" });

server.tool(
  "search_files",
  { query: z.string().min(1).max(200) },
  async ({ query }) => ({
    content: [{ type: "text", text: await searchFiles(query) }],
  })
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

### Tool Design

- **One tool, one action** — keep tools focused; avoid tools that do different things based on a `mode` parameter.
- **Validate all inputs** with Zod schemas — use `.min()`, `.max()`, `.regex()` to constrain strings.
- **Return structured content** — use `type: "text"` for prose, `type: "resource"` for file contents.
- **Error handling** — throw `McpError` with an appropriate `ErrorCode` for recoverable errors; let unhandled exceptions surface naturally.

```typescript
import { McpError, ErrorCode } from "@modelcontextprotocol/sdk/types.js";

if (!fs.existsSync(filePath)) {
  throw new McpError(ErrorCode.InvalidRequest, `File not found: ${filePath}`);
}
```

### Resources

```typescript
server.resource(
  "project://files/{path}",
  async (uri) => {
    const path = uri.pathname.slice(1);
    const safe = validatePath(path);  // path traversal check
    return { contents: [{ uri: uri.toString(), text: await fs.readFile(safe, "utf8") }] };
  }
);
```

### Prompts

```typescript
server.prompt(
  "code_review",
  { language: z.string(), code: z.string() },
  ({ language, code }) => ({
    messages: [{
      role: "user",
      content: { type: "text", text: `Review this ${language} code:\n\n${code}` },
    }],
  })
);
```

### Security

- **Path traversal**: always resolve and validate file paths against a base directory before reading/writing.
- **Command injection**: never pass tool input directly to `exec` or `spawn("sh", "-c", ...)`.
- **Secrets**: do not embed API keys in the server source — read from environment variables.
- **Scope**: only expose tools and resources that are necessary — principle of least privilege.
- **Transport**: prefer stdio for local tools; use SSE with authentication for networked MCP servers.

### MCP Config (Claude Code)

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["/path/to/server/dist/index.js"],
      "env": { "MY_API_KEY": "${MY_API_KEY}" }
    }
  }
}
```

## Safe Behavior

- Analysis only unless asked to modify code.
- All tool input must be validated — never trust raw strings from the model.
- External actions (file writes, API calls, shell commands) require explicit confirmation if they have side effects.
