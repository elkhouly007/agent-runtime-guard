# Skill: pytorch-patterns

## Purpose

Apply PyTorch best practices — dataset pipelines, model definition, training loops, checkpointing, and evaluation for deep learning projects.

## Trigger

- Starting or reviewing a PyTorch training pipeline
- Implementing a custom model, dataset, or loss function
- Asked about PyTorch training, GPU setup, or model export

## Trigger

`/pytorch-patterns` or `apply pytorch patterns to [target]`

## Agents

- `python-reviewer` — Python code quality
- `gan-planner` or `gan-evaluator` — for GAN-specific work

## Patterns

### Project Structure

```
project/
├── data/
│   └── dataset.py       # Custom Dataset classes
├── models/
│   └── model.py         # nn.Module subclasses
├── training/
│   ├── trainer.py       # Training loop
│   └── losses.py        # Custom loss functions
├── evaluation/
│   └── metrics.py
├── configs/
│   └── base.yaml        # Hydra or dataclass config
└── train.py             # Entry point
```

### Dataset and DataLoader

```python
from torch.utils.data import Dataset, DataLoader

class MyDataset(Dataset):
    def __init__(self, root: str, transform=None):
        self.files = list(Path(root).glob("*.jpg"))
        self.transform = transform

    def __len__(self) -> int:
        return len(self.files)

    def __getitem__(self, idx: int):
        img = Image.open(self.files[idx]).convert("RGB")
        if self.transform:
            img = self.transform(img)
        return img

loader = DataLoader(dataset, batch_size=32, shuffle=True, num_workers=4, pin_memory=True)
```

- Use `num_workers > 0` and `pin_memory=True` for GPU training.
- Normalize images to match pretrained model expectations (`mean=[0.485,0.456,0.406]` for ImageNet).

### Model Definition

```python
import torch.nn as nn

class MyModel(nn.Module):
    def __init__(self, in_features: int, num_classes: int):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(in_features, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)
```

### Training Loop

```python
model = MyModel(512, 10).to(device)
optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=num_epochs)

for epoch in range(num_epochs):
    model.train()
    for batch in train_loader:
        x, y = batch[0].to(device), batch[1].to(device)
        optimizer.zero_grad()
        loss = criterion(model(x), y)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        optimizer.step()
    scheduler.step()
```

- Use `torch.nn.utils.clip_grad_norm_` to prevent gradient explosion.
- Call `model.train()` before training loop, `model.eval()` before evaluation.

### Checkpointing

```python
# Save
torch.save({
    "epoch": epoch,
    "model_state_dict": model.state_dict(),
    "optimizer_state_dict": optimizer.state_dict(),
    "loss": best_loss,
}, "checkpoint.pt")

# Load
checkpoint = torch.load("checkpoint.pt", map_location=device)
model.load_state_dict(checkpoint["model_state_dict"])
```

- Always save `model.state_dict()`, not the full model object.
- Use `map_location=device` when loading on different hardware.

### Mixed Precision

```python
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()
with autocast():
    output = model(x)
    loss = criterion(output, y)
scaler.scale(loss).backward()
scaler.step(optimizer)
scaler.update()
```

### Model Export (ONNX / TorchScript)

```python
# TorchScript
scripted = torch.jit.script(model)
scripted.save("model.pt")

# ONNX
torch.onnx.export(model, dummy_input, "model.onnx", opset_version=17)
```

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/python/coding-style.md`.
- Large file downloads (datasets, pretrained weights) require explicit confirmation.
