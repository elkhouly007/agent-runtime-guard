# Skill: Manim Video

## Trigger

Use when creating mathematical or technical explainer animations with Manim — visualizing algorithms, data structures, equations, graph transformations, or any concept that benefits from animated visual explanation.

## Core Concepts

Manim renders Python-defined animations to video. Each scene is a Python class:

```python
from manim import *

class HelloWorld(Scene):
    def construct(self):
        text = Text("Hello, World!")
        self.play(Write(text))
        self.wait(1)
        self.play(FadeOut(text))
```

```bash
# Render at medium quality (720p)
manim -pql scene.py HelloWorld

# Render at high quality (1080p)
manim -pqh scene.py HelloWorld

# Render at 4K
manim -pqk scene.py HelloWorld

# Preview without saving
manim -p scene.py HelloWorld
```

## Common Mobjects

```python
# Text
text = Text("Label", font_size=48, color=BLUE)
latex = MathTex(r"\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}")

# Shapes
circle = Circle(radius=1, color=RED, fill_opacity=0.5)
rect = Rectangle(width=4, height=2, color=GREEN)
arrow = Arrow(LEFT, RIGHT, color=YELLOW)
line = Line(ORIGIN, UP * 2)

# Graphs
axes = Axes(x_range=[-3, 3, 1], y_range=[-2, 2, 1])
graph = axes.plot(lambda x: np.sin(x), color=BLUE)
```

## Animation Patterns

```python
class AlgorithmDemo(Scene):
    def construct(self):
        # Create and position objects
        title = Text("Binary Search", font_size=60).to_edge(UP)
        array = VGroup(*[Square().shift(RIGHT * i) for i in range(8)])

        # Animate in
        self.play(Write(title))
        self.play(Create(array))
        self.wait(0.5)

        # Transform
        self.play(array[3].animate.set_fill(YELLOW, opacity=0.8))
        self.wait(0.5)

        # Move objects
        self.play(array.animate.shift(DOWN))

        # Fade out
        self.play(FadeOut(title), FadeOut(array))
```

### Key Animation Methods

| Method | What it does |
|---|---|
| `Write(mob)` | Writes text stroke by stroke |
| `Create(mob)` | Draws shape outline |
| `FadeIn(mob)` | Fades in from transparent |
| `FadeOut(mob)` | Fades out to transparent |
| `Transform(a, b)` | Morphs one shape into another |
| `mob.animate.shift(v)` | Moves smoothly to new position |
| `mob.animate.scale(s)` | Scales smoothly |
| `mob.animate.set_color(c)` | Changes color |

### Graph and Function Visualization

```python
class FunctionPlot(Scene):
    def construct(self):
        axes = Axes(
            x_range=[-2 * PI, 2 * PI, PI],
            y_range=[-1.5, 1.5, 0.5],
            axis_config={"color": WHITE},
        ).add_coordinates()

        sin_graph = axes.plot(np.sin, color=BLUE, x_range=[-2*PI, 2*PI])
        cos_graph = axes.plot(np.cos, color=RED, x_range=[-2*PI, 2*PI])

        sin_label = axes.get_graph_label(sin_graph, label="\\sin(x)")
        cos_label = axes.get_graph_label(cos_graph, label="\\cos(x)", direction=UP)

        self.play(Create(axes))
        self.play(Create(sin_graph), Write(sin_label))
        self.play(Create(cos_graph), Write(cos_label))
        self.wait(2)
```

## Scene Structure Template

```python
from manim import *

class ExplainerScene(Scene):
    def construct(self):
        # 1. Title card
        title = Text("Concept Name", font_size=60)
        self.play(Write(title))
        self.wait(1)
        self.play(title.animate.scale(0.5).to_edge(UP))

        # 2. Setup — introduce the elements
        # ...

        # 3. Demonstration — animate the key insight
        # ...

        # 4. Conclusion — highlight the result
        # ...

        self.wait(2)
```

## Installation

```bash
pip install manim
# macOS: brew install cairo pango ffmpeg
# Ubuntu: apt-get install libcairo2-dev libpango1.0-dev ffmpeg
```

## Constraints

- Manim rendering is CPU-intensive for complex scenes — use `-ql` (low quality) during development, `-qh` for final render.
- LaTeX expressions require a LaTeX installation (`texlive` or `miktex`). Use `MathTex` for equations, `Text` for plain text.
- Keep scenes under 2 minutes — longer animations are better split into a series.
