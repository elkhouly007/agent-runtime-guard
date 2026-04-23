# Skill: VideoDB Video and Audio Operations

## Trigger

Use when writing or reviewing Python code that uses the `videodb` SDK for video ingestion, indexing, semantic search, timeline editing, clip generation, or streaming playback.

## Pre-Implementation Checklist

Before writing VideoDB code:
- [ ] Confirm `VIDEODB_API_KEY` is set in the environment — never hardcode it.
- [ ] Identify the indexing type needed: spoken words (transcription), visual scenes, or both.
- [ ] Understand that indexing is async and takes time proportional to video duration.
- [ ] For large files (>500 MB), use the URL-based upload path — direct upload has size limits.
- [ ] Plan error handling for rate limits (429) and long-running operations.

## Process

### 1. Connection setup

```python
import videodb
from videodb import connect

# Always load from environment — never hardcode
import os
conn = connect(api_key=os.environ["VIDEODB_API_KEY"])

# Verify connection
coll = conn.get_collection()   # default collection
print(f"Connected. Collection ID: {coll.id}")
```

Collections are workspaces. Use the default for most work; create named collections to separate projects.

```python
# Named collection
coll = conn.create_collection(name="product-demos", description="Customer demo recordings")

# List all collections
for c in conn.get_collections():
    print(c.id, c.name)
```

### 2. Video upload and indexing

```python
from videodb import MediaType

# Upload from URL (preferred for large files)
video = coll.upload(url="https://example.com/interview.mp4")
print(f"Uploaded: {video.id} — duration: {video.length}s")

# Upload local file
with open("recording.mp4", "rb") as f:
    video = coll.upload(file=f)

# Index spoken words (enables transcript search)
video.index_spoken_words()

# Index visual scenes (enables visual/semantic scene search)
video.index_scenes()

# Index both — do both before searching
video.index_spoken_words()
video.index_scenes()
```

Indexing is synchronous in the SDK (blocks until complete). For long videos in a web context, run in a background thread or async task:

```python
import concurrent.futures

def index_video(video_id: str):
    v = coll.get_video(video_id)
    v.index_spoken_words()
    v.index_scenes()

with concurrent.futures.ThreadPoolExecutor() as executor:
    future = executor.submit(index_video, video.id)
    # ... do other work ...
    future.result()  # wait for completion
```

### 3. Semantic search over video

```python
from videodb import SearchType

# Search spoken words (requires index_spoken_words first)
results = video.search("product pricing", search_type=SearchType.spoken_word)

for shot in results.get_shots():
    print(f"  {shot.start:.1f}s – {shot.end:.1f}s: {shot.text}")

# Search visual scenes (requires index_scenes first)
results = video.search("person writing on whiteboard", search_type=SearchType.scene)

# Search across all videos in a collection
results = coll.search("quarterly revenue", search_type=SearchType.spoken_word)

for shot in results.get_shots():
    print(f"  Video: {shot.video_id}  {shot.start:.1f}s–{shot.end:.1f}s")
```

`get_shots()` returns a list of `Shot` objects with `.start`, `.end`, `.text`, `.video_id`.

### 4. Timeline editing — assemble clips

`Timeline` is the editing primitive. Build a sequence of `VideoAsset` segments, then compile.

```python
from videodb import play_stream
from videodb.timeline import Timeline, VideoAsset, AudioAsset

timeline = Timeline(conn)

# Add clips from different videos
timeline.add_inline(VideoAsset(asset_id=video1.id, start=10, end=30))
timeline.add_inline(VideoAsset(asset_id=video2.id, start=0, end=15))
timeline.add_inline(VideoAsset(asset_id=video1.id, start=60, end=90))

# Generate a streaming URL for the compiled timeline
stream_url = timeline.generate_stream()
print(stream_url)        # HLS URL ready for playback
play_stream(stream_url)  # opens in browser (useful in notebooks)
```

Adding audio overlay (e.g. background music):

```python
audio = coll.upload(url="https://example.com/music.mp3", media_type=MediaType.audio)

timeline.add_overlay(
    start=0,
    audio_asset=AudioAsset(asset_id=audio.id, start=0, end=30, disable_other_tracks=False)
)
```

Removing segments (cut a section out):

```python
# There is no direct "cut" API — rebuild the timeline without the unwanted segment
# If you want to remove 20s–30s from a 60s video:
timeline.add_inline(VideoAsset(asset_id=video.id, start=0, end=20))
timeline.add_inline(VideoAsset(asset_id=video.id, start=30, end=60))
```

### 5. Generate clips from search results

The most common pattern: search → get shots → compile hits into a highlight reel.

```swift
```python
def make_highlight_reel(video_id: str, query: str, padding: float = 1.0) -> str:
    """
    Search a video, add padding around each hit, compile to a streaming URL.
    Returns the stream URL.
    """
    video = coll.get_video(video_id)
    results = video.search(query, search_type=SearchType.spoken_word)
    shots = results.get_shots()

    if not shots:
        raise ValueError(f"No results for query: {query!r}")

    timeline = Timeline(conn)
    for shot in shots:
        start = max(0, shot.start - padding)
        end = min(video.length, shot.end + padding)
        timeline.add_inline(VideoAsset(asset_id=video.id, start=start, end=end))

    return timeline.generate_stream()
```

### 6. RAG over video content — video Q&A with LLM

Use transcript search to retrieve relevant segments, then pass to an LLM for synthesis.

```python
import anthropic

def video_qa(video_id: str, question: str) -> str:
    video = coll.get_video(video_id)

    # Retrieve relevant transcript segments
    results = video.search(question, search_type=SearchType.spoken_word)
    shots = results.get_shots()

    if not shots:
        return "No relevant content found in the video."

    # Build context from retrieved shots
    context_parts = []
    for shot in shots[:5]:   # top 5 segments
        context_parts.append(
            f"[{shot.start:.0f}s–{shot.end:.0f}s]: {shot.text}"
        )
    context = "\n".join(context_parts)

    # Send to LLM
    client = anthropic.Anthropic()
    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": (
                f"Based on these transcript segments from a video:\n\n{context}\n\n"
                f"Answer this question: {question}"
            )
        }]
    )
    return response.content[0].text
```

### 7. Streaming playback URLs

All video operations that produce output return HLS streaming URLs (`.m3u8`). These are time-limited (typically 6 hours).

```python
# Direct video stream
stream_url = video.generate_stream()
print(stream_url)  # https://stream.videodb.io/.../<video_id>/index.m3u8

# Stream with time range
stream_url = video.generate_stream(timeline=[(10, 40), (60, 90)])

# Search result stream (pre-built by VideoDB)
results = video.search("product demo")
stream_url = results.compile_shots()   # compile hits into a stream directly
play_stream(stream_url)
```

### 8. Rate limits and large file handling

| Limit | Detail |
|-------|--------|
| Upload size (direct) | ~500 MB — use URL upload above this |
| API rate limit | 429 status — exponential backoff |
| Concurrent uploads | 3 per account on free tier |
| Indexing time | ~1× real-time for spoken words, ~2× for scenes |
| Search results | Max 10 shots returned by default |

```python
import time

def upload_with_retry(url: str, max_attempts: int = 3) -> object:
    for attempt in range(max_attempts):
        try:
            return coll.upload(url=url)
        except videodb.RateLimitError:
            wait = 2 ** attempt   # 1s, 2s, 4s
            print(f"Rate limited. Waiting {wait}s...")
            time.sleep(wait)
    raise RuntimeError(f"Upload failed after {max_attempts} attempts")
```

For files too large to index in one call, segment them first using ffmpeg before uploading:

```bash
# Split into 10-minute segments before uploading
ffmpeg -i large_file.mp4 -c copy -map 0 -segment_time 600 -f segment part_%03d.mp4
```

### 9. List and manage videos

```python
# List all videos in collection
for v in coll.get_videos():
    print(f"{v.id:20s}  {v.name:40s}  {v.length:.0f}s")

# Get specific video
video = coll.get_video("vid_abc123")

# Delete video
video.delete()

# Get transcript
transcript = video.get_transcript()
for seg in transcript:
    print(f"{seg['start']:.1f}s: {seg['text']}")
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| Hardcoded API key in source | Security leak | `os.environ["VIDEODB_API_KEY"]` |
| Searching before indexing | Empty results silently | Always index before searching |
| Blocking main thread during indexing | UI freeze, timeout | Use background thread or async task |
| Uploading >500 MB directly | SDK error or silent failure | Use URL-based upload |
| Not adding padding to search shots | Clips start/end abruptly | Add 1–2s padding around each shot |
| Caching stream URLs long-term | URLs expire (~6 hours) | Generate fresh URL at playback time |
| Ignoring 429 errors | Requests permanently fail | Exponential backoff retry |
| `results.get_shots()` without checking length | IndexError or empty compile | Check `if not shots` before using |

## Safe Behavior

- Does not log or store video content or transcript text from user uploads.
- Does not approve its own output.
- API key handling must use environment variables — flagged as CRITICAL if hardcoded.
- Large file operations (>500 MB, >1 hour video) should be flagged for Ahmed's review before running in production.
