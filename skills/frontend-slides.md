# Skill: frontend-slides

## Purpose

Build zero-dependency HTML presentations — self-contained slide decks that run in any browser, with optional PPTX export guidance.

## Trigger

- Creating a technical presentation, demo deck, or explainer
- Need a shareable single-file presentation without installing PowerPoint or Keynote
- Asked to generate slides for a feature, architecture, or project summary

## Trigger

`/frontend-slides` or `build slides for [topic]`

## Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Presentation Title</title>
  <style>
    /* Reset and base */
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #0f172a; color: #f8fafc; }

    /* Slide container */
    .deck { width: 100vw; height: 100vh; overflow: hidden; position: relative; }
    .slide {
      display: none; width: 100%; height: 100%;
      padding: 4rem; flex-direction: column; justify-content: center;
    }
    .slide.active { display: flex; }

    /* Typography */
    h1 { font-size: 3rem; font-weight: 700; margin-bottom: 1rem; }
    h2 { font-size: 2rem; font-weight: 600; margin-bottom: 0.75rem; }
    p, li { font-size: 1.25rem; line-height: 1.7; }
    ul { padding-left: 1.5rem; }

    /* Navigation */
    .nav { position: fixed; bottom: 2rem; right: 2rem; display: flex; gap: 0.5rem; }
    .nav button {
      padding: 0.5rem 1rem; background: #3b82f6; color: white;
      border: none; border-radius: 6px; cursor: pointer; font-size: 1rem;
    }
    .progress { position: fixed; bottom: 2rem; left: 2rem; color: #94a3b8; }

    /* Code blocks */
    pre { background: #1e293b; padding: 1.5rem; border-radius: 8px;
          overflow-x: auto; font-size: 1rem; margin: 1rem 0; }
    code { font-family: 'Fira Code', monospace; }
  </style>
</head>
<body>
  <div class="deck">
    <div class="slide active">
      <h1>Presentation Title</h1>
      <p>Subtitle or tagline</p>
    </div>

    <div class="slide">
      <h2>Slide Two</h2>
      <ul>
        <li>Point one</li>
        <li>Point two</li>
        <li>Point three</li>
      </ul>
    </div>

    <!-- Add more slides here -->
  </div>

  <div class="progress">
    <span id="current">1</span> / <span id="total"></span>
  </div>

  <div class="nav">
    <button onclick="prev()">←</button>
    <button onclick="next()">→</button>
  </div>

  <script>
    const slides = document.querySelectorAll('.slide');
    let current = 0;
    document.getElementById('total').textContent = slides.length;

    function show(n) {
      slides[current].classList.remove('active');
      current = (n + slides.length) % slides.length;
      slides[current].classList.add('active');
      document.getElementById('current').textContent = current + 1;
    }

    function next() { show(current + 1); }
    function prev() { show(current - 1); }

    document.addEventListener('keydown', e => {
      if (e.key === 'ArrowRight' || e.key === 'Space') next();
      if (e.key === 'ArrowLeft') prev();
    });
  </script>
</body>
</html>
```

## Viewport Rules

- Fix dimensions to `100vw × 100vh` — no scrolling inside a slide.
- If content overflows, reduce font size or split to a new slide.
- Use `overflow: hidden` on `.deck` and `overflow-x: auto` on code blocks only.

## PPTX Export

To convert to PowerPoint:
1. Open the HTML file in Chrome/Edge.
2. Print → Save as PDF (set paper size to 16:9 or A4 landscape).
3. Import PDF into PowerPoint → Insert → Photo Album or use `pdf2pptx` CLI.

Or use `decktape` CLI for headless PDF export:
```bash
npx decktape generic --slides 1-20 presentation.html presentation.pdf
```

## Safe Behavior

- All output is a single local HTML file — no external dependencies, no CDN requests.
- No JavaScript that makes network calls or accesses the filesystem.
