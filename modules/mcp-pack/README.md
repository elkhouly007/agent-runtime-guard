# MCP Pack

This pack defines a reviewed MCP capability layer for Agent Runtime Guard.

## Goal

Recover practical MCP power without allowing hidden endpoints, silent package downloads, or unclear outbound data flow.

## Pack Structure

- `registry.json`: reviewed MCP module registry
- `local/`: local-first MCP module notes
- `external/`: external MCP module notes
- `MCP_APPLY_CHECKLIST.md`: apply checklist before enabling any MCP entry

## Default Position

- local MCP is preferred first;
- external MCP is allowed only after payload review and clear data-flow understanding;
- `npx -y` or equivalent auto-download execution is not allowed.
