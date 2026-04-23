# Skill: Exa Search

## Trigger

Use when performing high-quality web search that requires semantic understanding — finding recent documentation, researching companies, discovering similar content, or searching for technical resources that simple keyword search misses.

## What Exa Is

Exa is a neural search API that understands query intent semantically, not just keyword matches. It excels at:
- "Find documentation for X library" → returns actual docs, not SEO noise
- "Find companies similar to Stripe" → understands the conceptual space
- "Latest research on X topic" → finds recent, authoritative content
- "Find codebases using pattern X" → code and technical content search

## MCP Integration

Exa is available as an MCP server. If configured in `mcp_config.json`:

```json
{
    "mcpServers": {
        "exa": {
            "command": "npx",
            "args": ["-y", "@modelcontextprotocol/server-exa"],
            "env": { "EXA_API_KEY": "${EXA_API_KEY}" }
        }
    }
}
```

Available tools after MCP connection:
- `exa_search` — general web search
- `exa_find_similar` — find pages similar to a URL
- `exa_get_contents` — retrieve full page content

## Direct API Usage

```typescript
import Exa from 'exa-js';

const exa = new Exa(process.env.EXA_API_KEY);

// Basic search
const results = await exa.search('React Server Components best practices', {
    numResults: 5,
    type: 'neural',         // neural (semantic) or keyword
    useAutoprompt: true,    // Exa rewrites query for better results
});

// Search with full content
const withContent = await exa.searchAndContents(
    'Stripe webhooks implementation guide',
    {
        numResults: 3,
        text: true,                   // include full text
        highlights: { numSentences: 3 }, // include highlights
        startPublishedDate: '2024-01-01', // recent only
    }
);

// Find similar to a URL
const similar = await exa.findSimilar('https://stripe.com/docs/webhooks', {
    numResults: 5,
    text: { maxCharacters: 2000 },
});

for (const result of similar.results) {
    console.log(result.title, result.url);
    console.log(result.text?.slice(0, 500));
}
```

## Search Query Patterns

```typescript
// BAD — keyword search (use Google for this)
'stripe webhook nodejs'

// GOOD — semantic/intent search (use Exa)
'how to implement Stripe webhook verification in Node.js'
'companies building developer tools similar to Vercel'
'research papers on RAG retrieval augmented generation 2024'
'open source projects using Rust for database storage engines'
```

## Research Workflow

```typescript
async function deepResearch(topic: string) {
    // 1. Overview search
    const overview = await exa.searchAndContents(topic, {
        numResults: 5,
        useAutoprompt: true,
        text: { maxCharacters: 3000 },
        startPublishedDate: '2023-01-01',
    });

    // 2. Find authoritative sources
    const authoritative = await exa.search(`"${topic}" documentation site:github.com OR site:docs`, {
        numResults: 3,
    });

    // 3. Recent developments
    const recent = await exa.searchAndContents(topic, {
        numResults: 5,
        startPublishedDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString(),
        text: { maxCharacters: 2000 },
    });

    return { overview, authoritative, recent };
}
```

## Constraints

- Exa requires an API key from exa.ai — do not hardcode it, use environment variables.
- Results include full text content — large result sets consume significant tokens. Limit `maxCharacters` and `numResults` to what's needed.
- `useAutoprompt: true` rewrites queries — disable it if you need exact-match behavior.
- Rate limits depend on your Exa plan — cache results for identical queries.
