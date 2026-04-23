# Skill: Apple Foundation Models (On-Device LLM)

## Trigger

Use when writing or reviewing code that uses the `FoundationModels` framework (`import FoundationModels`) for on-device language model inference on Apple platforms (iOS 26+, macOS 26+).

## Pre-Implementation Checklist

Before writing FoundationModels code:
- [ ] Confirm deployment target is iOS 26+ / macOS 26+ — the framework does not exist on earlier OS.
- [ ] Check `SystemLanguageModel.default.isAvailable` at runtime before any session work.
- [ ] Decide: structured output (`@Generable`) or free-text — structured is more reliable for parsing.
- [ ] Plan a cloud fallback if on-device is unavailable or too slow for the use case.
- [ ] Confirm privacy requirement — on-device means no data leaves the device, document this if it matters to the user.

## Process

### 1. Availability check

Always check availability before creating a session. The model may not be downloaded yet or the device may not support it.

```swift
import FoundationModels

func canUseOnDeviceModel() async -> Bool {
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
        return true
    case .unavailable(let reason):
        // Reasons: .deviceNotSupported, .appleIntelligenceNotEnabled,
        //          .modelNotReady, .unknownError
        print("Model unavailable: \(reason)")
        return false
    }
}
```

### 2. Session setup

`LanguageModelSession` is the primary interaction point. It maintains conversation history automatically.

```swift
// Minimal session — uses default system model
let session = LanguageModelSession()

// Session with instructions (system prompt)
let session = LanguageModelSession(
    instructions: Instructions("You are a concise code reviewer. Respond in plain text only.")
)
```

Sessions are **not** thread-safe — create one per conversation, do not share across tasks.

### 3. generateContent() — single response

```swift
func summarize(text: String) async throws -> String {
    let session = LanguageModelSession(
        instructions: Instructions("Summarize the following text in 2-3 sentences.")
    )

    let response = try await session.respond(to: text)
    return response.content
}
```

Error handling:

```swift
do {
    let response = try await session.respond(to: prompt)
    return response.content
} catch let error as LanguageModelError {
    switch error {
    case .guardrailsViolation(let detail):
        // Prompt or output violated Apple's on-device guardrails
        // Do NOT retry the same prompt — rephrase or reject
        print("Guardrails: \(detail)")
        return nil
    case .modelUnavailable:
        // Model became unavailable mid-session (e.g. background eviction)
        // Trigger fallback to cloud
        return try await cloudFallback(prompt: prompt)
    default:
        throw error
    }
}
```

### 4. streamGeneratedContent() — streaming for UI responsiveness

Use streaming when responses may be long or latency matters:

```swift
@MainActor
func streamSummary(text: String) async {
    let session = LanguageModelSession()
    outputText = ""

    do {
        let stream = session.streamResponse(to: text)
        for try await partial in stream {
            outputText = partial.content   // partial contains full content so far, not delta
        }
    } catch let error as LanguageModelError where error == .guardrailsViolation {
        outputText = "[Content could not be generated]"
    }
}
```

Note: `partial.content` is the **cumulative** text, not a delta. Replace the displayed text on each update, do not append.

### 5. @Generable macro for structured output

`@Generable` lets you specify an output schema so the model returns typed Swift values instead of raw text. This is far more reliable than parsing free text.

```swift
import FoundationModels

@Generable
struct CodeReviewResult {
    @Guide(description: "Overall verdict: approve, request_changes, or block")
    var verdict: String

    @Guide(description: "List of issues found, each with severity and description")
    var issues: [ReviewIssue]

    @Guide(description: "Brief summary of what the code does")
    var summary: String
}

@Generable
struct ReviewIssue {
    @Guide(description: "Severity: critical, high, medium, low")
    var severity: String

    @Guide(description: "Short description of the issue")
    var description: String
}

// Usage
func review(code: String) async throws -> CodeReviewResult {
    let session = LanguageModelSession(
        instructions: Instructions("You are a senior code reviewer.")
    )

    let response = try await session.respond(
        to: "Review this code:\n\n\(code)",
        generating: CodeReviewResult.self
    )

    return response.content   // Typed CodeReviewResult, not a String
}
```

`@Guide` annotations are part of the schema sent to the model — write them like you would write a good field description in an API spec.

### 6. Prompt design for on-device models

On-device models are smaller than cloud models. Prompts need to be tighter.

| Principle | On-device guidance |
|-----------|-------------------|
| System prompt length | Keep under 200 tokens — long instructions degrade adherence |
| Few-shot examples | 1-2 max — model context window is smaller |
| Output format | Always use `@Generable` for structured data — free-text parsing is fragile |
| Chain of thought | Avoid — increases latency and token use |
| Temperature | Not user-configurable in current API — accept the default |
| Language | English performs best; other languages may degrade quality |

```swift
// Good — short, directive, specific
Instructions("Extract action items from meeting notes. Be concise.")

// Bad — too long, too vague
Instructions("""
You are a highly sophisticated AI assistant with deep expertise in business
communication. When given meeting notes, your task is to carefully read through
all the content and identify any actionable items that participants agreed to
complete, ensuring you capture all nuances...
""")
```

### 7. Performance considerations

| Factor | Detail |
|--------|--------|
| First-token latency | 500ms–2s on A17 Pro / M-series, varies by load |
| Throughput | ~30–60 tokens/sec on device |
| Memory | Model occupies ~2–4 GB of RAM; system may evict if under pressure |
| Thermal | Sustained inference on iPhone may throttle after ~60s — batch short |
| Background | Model is evicted when app backgrounds — catch `.modelUnavailable` |

```swift
// For latency-sensitive flows: stream to hide first-token latency
// For batch flows: process in background Task with low priority
Task(priority: .background) {
    let results = try await processBatch(items)
}
```

### 8. Privacy guarantees

- All inference runs on the Neural Engine — no network calls, no telemetry.
- Input text never leaves the device.
- Session history is in-process memory — cleared when session is deallocated.
- You can communicate this to users: "Processed on your device. Not sent to any server."

```swift
// Document the privacy guarantee in code for auditability
/// Summarizes the note using on-device inference.
/// Privacy: input data never leaves the device.
func summarizeNote(_ note: String) async throws -> String { ... }
```

### 9. Cloud fallback strategy

```swift
protocol TextSummarizer {
    func summarize(_ text: String) async throws -> String
}

struct OnDeviceSummarizer: TextSummarizer {
    func summarize(_ text: String) async throws -> String {
        let session = LanguageModelSession()
        let response = try await session.respond(to: "Summarize: \(text)")
        return response.content
    }
}

struct CloudSummarizer: TextSummarizer {
    func summarize(_ text: String) async throws -> String {
        // Call your cloud API (OpenAI, Claude, etc.)
        return try await CloudAPI.summarize(text)
    }
}

struct AdaptiveSummarizer: TextSummarizer {
    func summarize(_ text: String) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return try await CloudSummarizer().summarize(text)
        }
        do {
            return try await OnDeviceSummarizer().summarize(text)
        } catch LanguageModelError.modelUnavailable {
            return try await CloudSummarizer().summarize(text)
        }
    }
}
```

### 10. GuardrailsViolation handling

Apple's on-device model has built-in content guardrails. Violations are not errors in the traditional sense — they are expected on certain inputs.

```swift
// What triggers guardrails (non-exhaustive):
// - Requests for harmful content
// - Personally identifiable information extraction
// - Prompt injection attempts embedded in user content

// Safe handling
func safeRespond(to userInput: String) async -> String {
    let session = LanguageModelSession()
    do {
        let response = try await session.respond(to: userInput)
        return response.content
    } catch LanguageModelError.guardrailsViolation {
        // Do not log the input — it may contain sensitive content
        return "I'm not able to help with that."
    } catch {
        return "Something went wrong. Please try again."
    }
}
```

Do not retry a guardrails-violated prompt unchanged — it will fail again.

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| No availability check | Crash if model not ready | Always check `.availability` first |
| Sharing one session across multiple conversations | History bleeds between users | One session per conversation |
| Parsing free-text output with regex | Fragile, breaks on phrasing changes | Use `@Generable` |
| Appending streaming deltas | `partial.content` is cumulative, not delta | Replace, don't append |
| Retrying guardrails violations | Always fails the same way | Show user message, do not retry |
| Long system prompts | Degrades adherence on small model | Under 200 tokens |
| Using on-device for real-time latency-critical work | First-token latency 500ms+ | Stream or use cloud for sub-200ms SLA |

## Safe Behavior

- No network calls — on-device only.
- Does not log user inputs that trigger guardrails (may contain sensitive content).
- Does not approve its own output.
- Cloud fallback decisions require Ahmed's approval if they involve new external API integrations.
