# Import Checklist

Use this checklist before adopting any upstream feature or external repo fragment.

## Identify

- Source repo or module name
- Exact files under review
- Whether the change is docs, config, hook, plugin, MCP, installer, wrapper, or daemon

## Inspect

- Outbound network paths
- Package download or install behavior
- File write targets
- Delete or overwrite behavior
- Permission model changes
- Prompt rewriting or payload mutation

## Classify

- Local-safe
- External-safe after payload review
- Approval-required
- Reject

## Decide

- Adopt directly
- Adapt into safe-plus
- Defer
- Reject

## Verify

- Audit passes
- Docs updated
- Policy match confirmed
