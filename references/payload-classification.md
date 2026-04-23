# Payload Classification

## Goal

Classify outbound payloads before external sends so approval boundaries are easier to enforce consistently.

## Classes

### Class A: Non-sensitive operational

Examples:

- public docs summary requests;
- generic planning prompts;
- non-personal technical questions.

Default:

- may proceed after payload review.

### Class B: Sensitive operational

Examples:

- internal project details that are not personal but still confidential;
- non-public code snippets;
- internal architecture notes.

Default:

- review carefully;
- proceed only when destination is trusted and the send remains within policy.

### Class C: Personal or secret

Examples:

- names, customer records, private messages, credentials, API keys;
- confidential HR, financial, or legal data;
- any secret material.

Default:

- do not send without user approval.

## Review Questions

- what destination is receiving this payload;
- does the payload include public, internal, or personal information;
- is the action read-like or write-like;
- can the payload be reduced or redacted.
