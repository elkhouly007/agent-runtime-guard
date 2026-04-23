# Skill: Remotion Video Creation

## Trigger

Use when creating programmatic, data-driven videos with Remotion: product demos, animated explainers, data visualizations, social media videos, or any video that benefits from React-based composition and reusability.

## Core Concepts

Remotion renders React components to video frames using Puppeteer. Every video element is a React component. Time is expressed as frames.

```
fps = 30           → 1 second = 30 frames
durationInFrames = 150  → 5-second video
```

## Project Setup

```bash
npm create video@latest my-video
cd my-video
npm install
npx remotion preview     # open browser preview at localhost:3000
```

## Building Compositions

```tsx
// src/Root.tsx — register all compositions here
import { Composition } from 'remotion';
import { ProductDemo } from './ProductDemo';
import { DataViz } from './DataViz';

export const RemotionRoot = () => (
    <>
        <Composition
            id="ProductDemo"
            component={ProductDemo}
            durationInFrames={300}  // 10 seconds
            fps={30}
            width={1920}
            height={1080}
            defaultProps={{ title: 'My Product' }}
        />
        <Composition
            id="DataViz"
            component={DataViz}
            durationInFrames={450}
            fps={30}
            width={1080}  // square for Instagram
            height={1080}
        />
    </>
);
```

## Animation Patterns

```tsx
import {
    AbsoluteFill,
    useCurrentFrame,
    useVideoConfig,
    interpolate,
    spring,
    Sequence,
    Audio,
    Video,
    Img,
    staticFile,
} from 'remotion';

export function ProductDemo() {
    const frame = useCurrentFrame();
    const { fps, durationInFrames } = useVideoConfig();

    // Linear interpolation
    const opacity = interpolate(frame, [0, 30], [0, 1], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
    });

    // Spring animation (physics-based)
    const scale = spring({
        frame,
        fps,
        config: { stiffness: 200, damping: 20 },
        from: 0,
        to: 1,
    });

    // Slide in from left
    const translateX = interpolate(frame, [0, 20], [-200, 0], {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
    });

    return (
        <AbsoluteFill style={{ backgroundColor: '#0f172a' }}>
            <div style={{ opacity, transform: `scale(${scale}) translateX(${translateX}px)` }}>
                <h1 style={{ color: 'white', fontSize: 80 }}>Product Title</h1>
            </div>
        </AbsoluteFill>
    );
}
```

## Sequences (Timed Sections)

```tsx
import { Sequence } from 'remotion';

export function MultiSection() {
    return (
        <AbsoluteFill>
            {/* Section 1: frames 0-89 (3 seconds) */}
            <Sequence from={0} durationInFrames={90}>
                <IntroSection />
            </Sequence>

            {/* Section 2: frames 90-209 (4 seconds) */}
            <Sequence from={90} durationInFrames={120}>
                <DemoSection />
            </Sequence>

            {/* Section 3: frames 210 to end */}
            <Sequence from={210}>
                <OutroSection />
            </Sequence>
        </AbsoluteFill>
    );
}
```

## Audio and Media

```tsx
import { Audio, Video, Img, staticFile } from 'remotion';

// Background music
<Audio src={staticFile('background.mp3')} volume={0.3} />

// Voice over (starts at frame 30)
<Audio src={staticFile('narration.mp3')} startFrom={30} />

// Background video
<Video src={staticFile('background.mp4')} style={{ width: '100%' }} />

// Static image
<Img src={staticFile('screenshot.png')} style={{ width: 800 }} />
```

Place media files in `public/` directory — reference with `staticFile('filename')`.

## Rendering

```bash
# Render single composition
npx remotion render ProductDemo output/product-demo.mp4

# Render with custom props
npx remotion render ProductDemo output/demo.mp4 --props='{"title":"Custom"}'

# Render specific frame range
npx remotion render ProductDemo output/demo.mp4 --frames=0-90

# Render as GIF
npx remotion render ProductDemo output/demo.gif --codec=gif

# Render in parallel (faster on multi-core)
npx remotion render ProductDemo output/demo.mp4 --concurrency=4
```

## Common Video Sizes

| Format | Width × Height | Use case |
|---|---|---|
| 1920×1080 | 16:9 | YouTube, demo videos |
| 1080×1920 | 9:16 | Reels, TikTok, Shorts |
| 1080×1080 | 1:1 | Instagram, LinkedIn |
| 1280×720 | 16:9 | Twitter/X, smaller files |

## Constraints

- Rendering is CPU-intensive — for 4K or long videos, use a cloud renderer or a beefy machine.
- External data fetched during rendering (APIs, databases) must use `delayRender`/`continueRender` — not raw async calls in components.
- All assets (`staticFile()`) must be in the `public/` directory before rendering — Remotion does not fetch external URLs at render time.
- Preview in browser before rendering — rendering a 10-minute video to find a layout bug is expensive.
