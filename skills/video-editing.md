# Skill: Video Editing

## Trigger

Use when editing videos programmatically: trimming, concatenating, adding overlays, generating captions, extracting clips, or automating repetitive video editing tasks with FFmpeg and/or Remotion.

## FFmpeg Patterns

### Basic Operations

```bash
# Trim: extract 30-second clip starting at 1:20
ffmpeg -i input.mp4 -ss 00:01:20 -t 30 -c copy output.mp4

# Concatenate multiple clips
# First, create a list file:
cat > filelist.txt << EOF
file 'clip1.mp4'
file 'clip2.mp4'
file 'clip3.mp4'
EOF
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4

# Extract audio
ffmpeg -i video.mp4 -vn -acodec mp3 -q:a 2 audio.mp3

# Convert to web-optimized MP4 (H.264 + AAC)
ffmpeg -i input.mov -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k output.mp4

# Create GIF from video clip
ffmpeg -i input.mp4 -ss 00:00:05 -t 3 -vf "fps=15,scale=640:-1:flags=lanczos" output.gif
```

### Adding Overlays

```bash
# Add a watermark image
ffmpeg -i video.mp4 -i logo.png \
    -filter_complex "overlay=10:10" \
    output.mp4

# Add text overlay
ffmpeg -i input.mp4 \
    -vf "drawtext=text='My Title':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=h-100:box=1:boxcolor=black@0.5" \
    output.mp4

# Add subtitles from SRT file
ffmpeg -i video.mp4 -vf subtitles=captions.srt output.mp4
```

### Batch Processing

```bash
#!/usr/bin/env bash
# Convert all MOV files in current directory to MP4
for f in *.mov; do
    ffmpeg -i "$f" -c:v libx264 -crf 23 -c:a aac "${f%.mov}.mp4" -y
done
```

## Remotion Patterns

Remotion renders React components to video — ideal for programmatic, data-driven videos:

```tsx
// src/HelloWorld.tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from 'remotion';

export function HelloWorld() {
    const frame = useCurrentFrame();
    const opacity = interpolate(frame, [0, 30], [0, 1]); // fade in over 1 second

    return (
        <AbsoluteFill style={{ backgroundColor: '#000', justifyContent: 'center', alignItems: 'center' }}>
            <h1 style={{ color: 'white', fontSize: 80, opacity }}>Hello World</h1>
        </AbsoluteFill>
    );
}
```

```tsx
// src/Root.tsx
import { Composition } from 'remotion';
import { HelloWorld } from './HelloWorld';

export function RemotionRoot() {
    return (
        <Composition
            id="HelloWorld"
            component={HelloWorld}
            durationInFrames={150}  // 5 seconds at 30fps
            fps={30}
            width={1920}
            height={1080}
        />
    );
}
```

```bash
# Preview in browser
npx remotion preview

# Render to file
npx remotion render HelloWorld output.mp4

# Render with custom props
npx remotion render HelloWorld output.mp4 --props='{"title":"Custom Title"}'
```

## AI-Assisted Captioning

```bash
# Generate SRT captions using Whisper (OpenAI)
pip install openai-whisper
whisper video.mp4 --output_format srt --language en

# Burn captions into video
ffmpeg -i video.mp4 -vf subtitles=video.srt output-captioned.mp4
```

## Output Formats Reference

| Format | Use case | Command flag |
|---|---|---|
| H.264/MP4 | Web, social media | `-c:v libx264 -crf 23` |
| H.265/MP4 | Higher compression | `-c:v libx265 -crf 28` |
| WebM/VP9 | Web (open format) | `-c:v libvpx-vp9 -b:v 0 -crf 30` |
| GIF | Short loops, no audio | `-vf fps=15,scale=640:-1` |
| ProRes | Editing intermediate | `-c:v prores_ks -profile:v 3` |

## Constraints

- Always verify FFmpeg is installed before running commands: `ffmpeg -version`.
- Use `-c copy` when not re-encoding — it's lossless and fast. Only re-encode when transforming.
- Large video operations (4K, long duration) are CPU/RAM intensive — warn the user and suggest background execution.
- Never include copyrighted music, logos, or footage in outputs without verifying licensing.
