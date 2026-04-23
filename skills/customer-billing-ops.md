# Skill: Customer Billing Ops

## Trigger

Use when managing billing operations for a SaaS product: setting up Stripe subscriptions, handling billing events, managing customer lifecycle (trials, upgrades, downgrades, cancellations, refunds), or building a billing portal.

## Stripe Integration Patterns

### Setup

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
    apiVersion: '2024-12-18.acacia',
});
```

### Subscription Lifecycle

```typescript
// Create a customer
const customer = await stripe.customers.create({
    email: user.email,
    name: user.name,
    metadata: { userId: user.id },
});

// Create subscription (with trial)
const subscription = await stripe.subscriptions.create({
    customer: customer.id,
    items: [{ price: process.env.STRIPE_PRICE_ID }],
    trial_period_days: 14,
    payment_behavior: 'default_incomplete',
    payment_settings: { save_default_payment_method: 'on_subscription' },
    expand: ['latest_invoice.payment_intent'],
});

// Upgrade/downgrade
await stripe.subscriptions.update(subscriptionId, {
    items: [
        { id: currentItemId, deleted: true },
        { price: newPriceId },
    ],
    proration_behavior: 'always_invoice', // or 'create_prorations'
});

// Cancel at period end
await stripe.subscriptions.update(subscriptionId, {
    cancel_at_period_end: true,
});

// Immediate cancel with refund
await stripe.subscriptions.cancel(subscriptionId);
```

### Webhook Handling

```typescript
// Verify and parse webhook
app.post('/webhook/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'] as string;
    let event: Stripe.Event;

    try {
        event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
    } catch (err) {
        return res.status(400).send(`Webhook Error: ${err}`);
    }

    switch (event.type) {
        case 'customer.subscription.created':
        case 'customer.subscription.updated':
            await syncSubscription(event.data.object as Stripe.Subscription);
            break;

        case 'customer.subscription.deleted':
            await handleCancellation(event.data.object as Stripe.Subscription);
            break;

        case 'invoice.payment_succeeded':
            await handlePaymentSuccess(event.data.object as Stripe.Invoice);
            break;

        case 'invoice.payment_failed':
            await handlePaymentFailure(event.data.object as Stripe.Invoice);
            break;
    }

    res.json({ received: true });
});
```

### Billing Portal (Customer Self-Serve)

```typescript
// Create a billing portal session
const portalSession = await stripe.billingPortal.sessions.create({
    customer: stripeCustomerId,
    return_url: `${process.env.APP_URL}/settings/billing`,
});

// Redirect user to portalSession.url
```

## Billing Database Schema

```sql
-- Track subscription state in your DB (source of truth: Stripe webhooks)
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    stripe_customer_id TEXT NOT NULL UNIQUE,
    stripe_subscription_id TEXT UNIQUE,
    plan TEXT NOT NULL,               -- 'free', 'pro', 'enterprise'
    status TEXT NOT NULL,             -- 'trialing', 'active', 'past_due', 'canceled'
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## Refund Operations

```typescript
// Full refund
await stripe.refunds.create({
    payment_intent: paymentIntentId,
    reason: 'requested_by_customer', // or 'duplicate', 'fraudulent'
});

// Partial refund
await stripe.refunds.create({
    payment_intent: paymentIntentId,
    amount: 2500, // $25.00 in cents
});
```

## Constraints

- Never store Stripe secret keys in version control — use environment variables.
- Always verify webhook signatures — don't process unverified events.
- Stripe is the source of truth for subscription state — sync via webhooks, don't rely on API calls at request time.
- Test all billing flows in Stripe test mode before going live — use test card numbers from Stripe docs.
- GDPR: handle data deletion requests — Stripe allows customer data deletion via API.
