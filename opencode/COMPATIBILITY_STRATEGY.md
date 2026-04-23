# OpenCode Compatibility Strategy

## Goal

Keep Agent Runtime Guard loosely coupled to OpenCode so OpenCode updates do not force frequent rework.

## Core Rule

Do not rely on direct patching of global OpenCode config when a project-local config template or copied project config can achieve the same result.

## Avoid

- automatic overwrite of user-level OpenCode config;
- assumptions about unstable internal behavior;
- hidden plugin wiring;
- tight coupling to upstream runtime defaults.

## Prefer

- project-local config templates;
- project-local prompt references;
- explicit reviewed config copies;
- replaceable glue instead of core mutation.

## Compatibility Checks After OpenCode Updates

Review:

- config schema changes;
- role/tool model changes;
- plugin and MCP fields;
- permission semantics.

If OpenCode changes in one of these areas, adapt only the glue layer and templates.
