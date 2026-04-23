# Skill: X API

## Trigger

Use when integrating with the X (Twitter) API v2: posting tweets, reading timelines, searching tweets, managing accounts, or building automation that interacts with X.

## Authentication

X API v2 uses OAuth 2.0 (for user context) or Bearer token (for app-only read access):

```typescript
// App-only (read tweets, search) — Bearer token
const headers = {
    'Authorization': `Bearer ${process.env.X_BEARER_TOKEN}`,
};

// User context (post, like, follow) — OAuth 2.0 PKCE
// Requires user authorization flow — use a library:
// Node.js: twitter-api-v2, @types/twitter-api-v2
import { TwitterApi } from 'twitter-api-v2';

const client = new TwitterApi({
    appKey: process.env.X_API_KEY,
    appSecret: process.env.X_API_SECRET,
    accessToken: process.env.X_ACCESS_TOKEN,
    accessSecret: process.env.X_ACCESS_SECRET,
});
```

## Core Operations

### Post a Tweet

```typescript
const tweet = await client.v2.tweet({
    text: 'Hello from the API!',
});
console.log(tweet.data.id);

// Post a thread
const tweet1 = await client.v2.tweet({ text: 'First tweet in thread' });
const tweet2 = await client.v2.tweet({
    text: 'Second tweet',
    reply: { in_reply_to_tweet_id: tweet1.data.id },
});
```

### Search Tweets

```typescript
// Recent search (last 7 days — Basic tier)
const results = await client.v2.search('from:elonmusk lang:en', {
    max_results: 10,
    'tweet.fields': ['created_at', 'public_metrics', 'author_id'],
    expansions: ['author_id'],
    'user.fields': ['name', 'username'],
});

for (const tweet of results.data.data) {
    console.log(tweet.text, tweet.public_metrics?.like_count);
}
```

### Read Timeline

```typescript
// Home timeline (requires user context)
const timeline = await client.v2.homeTimeline({
    max_results: 20,
    'tweet.fields': ['created_at', 'public_metrics'],
});
```

### Get User Info

```typescript
const user = await client.v2.userByUsername('username', {
    'user.fields': ['public_metrics', 'description', 'created_at'],
});
console.log(user.data.public_metrics?.followers_count);
```

## Rate Limits (v2)

| Endpoint | Free tier | Basic tier |
|---|---|---|
| POST /tweets | 1,500/month | 3,000/month |
| GET /tweets/search/recent | 10/15min | 60/15min |
| GET /users/:id/tweets | 5/15min | 100/15min |

- Check `x-rate-limit-remaining` header in responses.
- Implement exponential backoff on `429` errors.
- Cache read results aggressively — most data doesn't need fresh-per-request reads.

```typescript
// Rate limit handling
async function withRetry<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fn();
        } catch (err: any) {
            if (err.code === 429) {
                const resetTime = err.rateLimit?.reset * 1000 || Date.now() + 15 * 60 * 1000;
                await new Promise(r => setTimeout(r, resetTime - Date.now()));
                continue;
            }
            throw err;
        }
    }
    throw new Error('Max retries exceeded');
}
```

## Webhooks (Account Activity API)

For real-time events (mentions, DMs, follows) — requires Enterprise or Elevated access:

```typescript
// Register webhook URL
await client.v1.registerAccountActivityWebhook(
    process.env.X_WEBHOOK_ENV!,
    `${process.env.PUBLIC_URL}/webhook/twitter`
);

// Subscribe user to webhook
await client.v1.subscribeAccountActivityWebhook(process.env.X_WEBHOOK_ENV!);
```

## Constraints

- Never store OAuth tokens in plaintext — use environment variables or a secret manager.
- Never post on behalf of a user without explicit authorization through the OAuth flow.
- Respect X's automation rules — do not post duplicate content, spam mentions, or automate follows/unfollows in bulk.
- Rate limit compliance is mandatory — X will suspend apps that consistently exceed limits.
