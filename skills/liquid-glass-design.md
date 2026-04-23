# Skill: iOS 26 Liquid Glass Design System

## Trigger

Use when designing or reviewing SwiftUI UI on iOS 26 / macOS 26 that involves glass materials, translucent backgrounds, NavigationStack, TabView, toolbars, or the `.glassEffect()` modifier family.

## Pre-Design Checklist

Before applying Liquid Glass:
- [ ] Confirm the target is iOS 26+ — `.glassEffect()` does not exist on earlier OS.
- [ ] Identify the depth layer of each surface (background → content → overlay) to choose the right glass variant.
- [ ] Verify the feature works with `reduceTransparency` accessibility setting.
- [ ] Check the design in both light and dark mode — glass renders very differently.
- [ ] Confirm you are not stacking glass on glass (nested GlassEffectContainers are usually wrong).

## Process

### 1. Liquid Glass vs. standard materials — decision table

| Use case | Use Liquid Glass | Use standard material |
|----------|-----------------|----------------------|
| NavigationBar, TabBar (system) | Automatic in iOS 26 | — (system handles it) |
| Floating action panel over content | Yes | — |
| Card on a photographic/dynamic background | Yes | — |
| Card on a solid/static background | — | `.regularMaterial` |
| Modal sheet | — | System sheet handles it |
| List rows | Never | — |
| Toolbars with custom backgrounds | Yes | — |
| Full-screen overlays | Rarely — kills depth | `.ultraThinMaterial` |

### 2. glassEffect() modifier

The primary API. Applied to a view to give it a glass appearance.

```swift
import SwiftUI

struct FloatingPanel: View {
    var body: some View {
        VStack(spacing: 12) {
            Label("Now Playing", systemImage: "music.note")
                .font(.headline)
            Text("Some Artist — Some Track")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassEffect()           // default glass — adapts to light/dark, tint
    }
}
```

Variants:

```swift
// Default — fills the view's shape
.glassEffect()

// With explicit shape — rounded rect
.glassEffect(in: RoundedRectangle(cornerRadius: 20))

// With tint — glass takes on a color cast
.glassEffect(in: RoundedRectangle(cornerRadius: 20), tint: .blue.opacity(0.3))

// Interactive glass — responds to press state
.glassEffect(in: Capsule(), isEnabled: isActive)
```

### 3. GlassEffectContainer — depth coordination

When multiple glass elements appear in the same region, wrap them in `GlassEffectContainer` so the system can render depth correctly. Without it, glass surfaces compete and produce incorrect refraction.

```swift
struct PlayerOverlay: View {
    var body: some View {
        GlassEffectContainer {
            VStack {
                NowPlayingCard()      // each uses .glassEffect()
                ControlsBar()
            }
        }
    }
}
```

Rules for `GlassEffectContainer`:
- One container per visual depth layer — do not nest.
- Do not use as a general layout container — it has a rendering cost.
- Contents must all be at the same depth relative to the background.

### 4. NavigationBar and TabBar glass integration

iOS 26 automatically makes navigation and tab bars glass. You do not apply `.glassEffect()` to them — the system does it.

```swift
// NavigationStack — glass bar is automatic in iOS 26
NavigationStack {
    ContentView()
        .navigationTitle("Feed")
        // Do not add custom backgrounds to the navigation bar
        // .toolbarBackground() overrides glass — use only when you must
}

// TabView — glass tab bar is automatic
TabView {
    FeedView().tabItem { Label("Feed", systemImage: "house") }
    SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
}
// Do not set .toolbarBackground(.visible) on TabView — it kills glass
```

When you must customize the bar (e.g. for a specific background):

```swift
.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
// Use this instead of a solid color so glass-adjacent elements still render correctly
```

### 5. Custom shapes with glass effect

```swift
struct PillButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .glassEffect(in: Capsule())
    }
}

struct HexagonBadge: View {
    var body: some View {
        Image(systemName: "star.fill")
            .padding(24)
            .glassEffect(in: HexagonShape())    // custom Shape conformance works
    }
}
```

### 6. Animation patterns — spring + glass

Glass responds best to spring animations. Avoid linear transitions — they look mechanical against the glass refraction.

```swift
struct AnimatedPanel: View {
    @State private var isExpanded = false

    var body: some View {
        VStack {
            contentView
                .glassEffect(in: RoundedRectangle(cornerRadius: isExpanded ? 24 : 16))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
        }
    }
}

// Appear/disappear — use .transition with spring
struct ToastView: View {
    var body: some View {
        Text("Saved")
            .padding()
            .glassEffect()
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .opacity
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8))
            )
    }
}
```

### 7. Dark mode behavior

Glass renders differently in dark mode — it is lighter and more luminous in dark contexts (pulling light from the background), and more translucent-frosted in light mode.

```swift
// Do not hard-code foreground colors on glass — use semantic colors
// Good
Text("Title")
    .foregroundStyle(.primary)         // adapts correctly

// Bad
Text("Title")
    .foregroundStyle(.white)           // invisible in light mode glass
    .foregroundStyle(Color(hex: "333333"))  // invisible in dark mode glass
```

Test both appearances:

```swift
#Preview {
    FloatingPanel()
        .previewDisplayName("Light")

    FloatingPanel()
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark")
}
```

### 8. Accessibility — reduceTransparency

When the user enables Settings → Accessibility → Reduce Transparency, glass materials become opaque. Your layout must remain usable.

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var body: some View {
    content
        // Option A — let .glassEffect() degrade automatically (preferred)
        .glassEffect()

        // Option B — if you need control over the degraded appearance
        .background(
            reduceTransparency
                ? AnyShapeStyle(.regularMaterial)
                : AnyShapeStyle(.clear)
        )
}
```

Do not:
- Rely on glass for legibility (text must be readable over an opaque background too).
- Place interactive elements that are only discoverable through glass depth cues.

### 9. Hierarchy depth reference

```
Layer 0 — Wallpaper / live background
Layer 1 — App background (solid or gradient)
Layer 2 — Primary content (lists, cards, images)      ← most content lives here
Layer 3 — Glass panels / floating UI                  ← .glassEffect() here
Layer 4 — System chrome (nav bar, tab bar, sheets)    ← system glass, do not override
```

Glass only reads correctly when it has content behind it (Layer 2 or lower). A glass surface over a white background looks like a foggy rectangle — not the intended effect.

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| `.glassEffect()` on list rows | Overwhelming, defeats readability | Use solid row backgrounds |
| Nested `GlassEffectContainer` | Incorrect depth rendering, artifacts | One container per depth layer |
| Glass on a solid white/black background | No background to refract — looks broken | Ensure photographic or gradient background |
| `.toolbarBackground(.visible)` on TabView | Kills automatic glass tab bar | Remove or use `.ultraThinMaterial` |
| Hard-coded white/black text on glass | Breaks in opposite color scheme | Use `.primary`/`.secondary` |
| Applying glass to every element | Visual noise, defeats hierarchy | Reserve for elevated/floating surfaces only |
| Not testing with reduceTransparency | Layout may break when glass goes opaque | Always test with accessibility setting |
| Linear animations on glass | Looks mechanical against fluid glass | Use `.spring()` |

## Safe Behavior

- Read-only analysis in review context — does not modify source files.
- Does not approve its own output.
- Flags accessibility issues (reduceTransparency, contrast) as HIGH — they affect real users.
- Glass overuse is flagged as MEDIUM — it is a design quality issue, not a safety issue.
