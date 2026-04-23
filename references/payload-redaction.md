# Payload Redaction

## Goal

Reduce outbound payload risk before external sends by removing or replacing sensitive content that is not needed.

## Redaction Rules

Replace or remove when possible:

- names of private individuals when not needed;
- email addresses;
- phone numbers;
- account numbers;
- credentials, tokens, or secrets;
- private file paths;
- customer or employee identifiers;
- confidential financial, HR, legal, or private operational details.

## Redaction Patterns

- replace secrets with `[REDACTED_SECRET]`
- replace personal names with `[REDACTED_NAME]` when identity is not needed
- replace emails with `[REDACTED_EMAIL]`
- replace phone numbers with `[REDACTED_PHONE]`
- replace private paths with `[REDACTED_PATH]`
- summarize sensitive records instead of quoting them directly

## Safe Workflow

1. classify payload sensitivity;
2. redact unnecessary sensitive content;
3. preview the final payload again;
4. confirm whether approval is required.
