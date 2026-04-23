# Skill: fal.ai Media

## Trigger

Use when generating images, video, or audio via the fal.ai API — running image generation models (Flux, SDXL), video generation, speech synthesis, or other AI media models through fal's unified API.

## Setup

```bash
npm install @fal-ai/client
# or
pip install fal-client
```

```typescript
import { fal } from '@fal-ai/client';

fal.config({
    credentials: process.env.FAL_KEY,
});
```

## Image Generation

```typescript
// Flux (high quality, fast)
const result = await fal.subscribe('fal-ai/flux/schnell', {
    input: {
        prompt: 'A photorealistic mountain landscape at golden hour',
        image_size: 'landscape_16_9',  // or 'square', 'portrait_4_3', etc.
        num_inference_steps: 4,        // schnell: 4, dev: 20-28
        num_images: 1,
    },
    logs: true,
});

console.log(result.data.images[0].url);

// SDXL
const sdxl = await fal.subscribe('fal-ai/stable-diffusion-xl', {
    input: {
        prompt: 'Abstract geometric art, vibrant colors',
        negative_prompt: 'blurry, low quality',
        image_size: 'square_hd',
        num_inference_steps: 30,
    },
});
```

### Image Sizes

| Size | Dimensions | Use for |
|---|---|---|
| `square` | 512×512 | Icons, avatars |
| `square_hd` | 1024×1024 | High-res square |
| `landscape_4_3` | 1024×768 | Standard landscape |
| `landscape_16_9` | 1280×720 | Widescreen / YouTube |
| `portrait_4_3` | 768×1024 | Mobile portrait |
| `portrait_16_9` | 720×1280 | Mobile / Reels |

## Video Generation

```typescript
// Kling — text-to-video
const video = await fal.subscribe('fal-ai/kling-video/v1.6/standard/text-to-video', {
    input: {
        prompt: 'A drone shot flying over a coastal city at sunset',
        duration: '5',   // seconds
        aspect_ratio: '16:9',
    },
});

console.log(video.data.video.url);

// Image-to-video
const i2v = await fal.subscribe('fal-ai/kling-video/v1.6/standard/image-to-video', {
    input: {
        prompt: 'The camera slowly zooms in',
        image_url: 'https://example.com/image.jpg',
        duration: '5',
    },
});
```

## Speech Synthesis

```typescript
// ElevenLabs via fal
const speech = await fal.subscribe('fal-ai/elevenlabs/tts', {
    input: {
        text: 'Hello, this is a test of the text-to-speech system.',
        voice_id: 'rachel',  // voice name or ID
    },
});

// Download the audio
const audioUrl = speech.data.audio.url;
```

## Downloading and Saving Generated Media

```typescript
import { writeFile } from 'fs/promises';
import { fetch } from 'undici';

async function saveMedia(url: string, path: string) {
    const response = await fetch(url);
    const buffer = await response.arrayBuffer();
    await writeFile(path, Buffer.from(buffer));
    console.log(`Saved to ${path}`);
}

// Usage
await saveMedia(result.data.images[0].url, './output/image.jpg');
```

## Error Handling

```typescript
try {
    const result = await fal.subscribe('fal-ai/flux/schnell', { input: { prompt } });
    return result.data;
} catch (err: any) {
    if (err.status === 422) {
        throw new Error(`Invalid input: ${err.body?.detail}`);
    }
    if (err.status === 429) {
        throw new Error('Rate limited — reduce request frequency or upgrade plan');
    }
    throw err;
}
```

## Constraints

- Always store `FAL_KEY` in environment variables — never hardcode.
- Generated images are stored on fal's CDN temporarily — download and store locally if persistence is needed.
- Video generation takes longer (20s-3min) — use `fal.subscribe` (polls for completion) not `fal.run` (single shot) for video.
- Respect fal's content policy — do not generate explicit, illegal, or harmful content.
- Cache results for identical prompts — media generation is expensive in both cost and latency.
