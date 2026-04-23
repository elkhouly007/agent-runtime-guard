# Claude Code Compatibility Strategy

## Goal

Keep Agent Runtime Guard loosely coupled to Claude Code so updates do not force frequent rework.

## Core Rule

Do not rely on direct patching of global Claude Code config when project-local AGENTS references, hook files, or copied local snippets can achieve the same result.

## Avoid

- automatic overwrite of user-level Claude Code config;
- assumptions about unstable internal behavior;
- hidden hook wiring;
- tight coupling to upstream runtime defaults.

## Prefer

- project-local AGENTS references;
- project-local hook files;
- explicit reviewed config snippets;
- replaceable glue instead of core mutation.

## Compatibility Checks After Claude Code Updates

Review:

- AGENTS instruction loading conventions;
- hook invocation format;
- permission semantics;
- config schema or hook registration changes.

If Claude Code changes in one of these areas, adapt only the glue layer and templates.
