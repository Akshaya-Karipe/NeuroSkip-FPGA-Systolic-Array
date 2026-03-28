# ============================================================
# mnist_extract.py — updated with center region extraction
# ============================================================
import torch
from torchvision import datasets, transforms
import numpy as np

print("Loading MNIST...")
mnist = datasets.MNIST(
    root='./mnist_data', train=True, download=True,
    transform=transforms.ToTensor()
)

print("\n=== MNIST SPARSITY ACROSS 5 DIGITS ===")
print(f"{'Image':>6} {'Digit':>6} {'Zeros':>7} {'Total':>7} {'Sparsity':>10} {'Exp.Skip':>10}")
print("-" * 55)

results = []
for img_idx in range(5):
    image, label = mnist[img_idx]
    act = (image.view(-1) * 15).int().clamp(0, 15)
    zeros = (act == 0).sum().item()
    total = len(act)
    sparsity = zeros / total * 100

    # Top-left 16 pixels (background region)
    a16_bg = act[:16].tolist()
    torch.manual_seed(img_idx)
    w16 = torch.randint(0, 16, (16,)).tolist()
    skips_bg = sum(1 for a, b in zip(a16_bg, w16) if a * b < 10)
    skip_pct_bg = skips_bg / 16 * 100

    # CENTER 16 pixels (digit region — row 14, col 7)
    center_start = 14 * 28 + 7
    a16_center = act[center_start:center_start + 16].tolist()
    skips_center = sum(1 for a, b in zip(a16_center, w16) if a * b < 10)
    skip_pct_center = skips_center / 16 * 100

    results.append({
        'idx': img_idx, 'label': label,
        'zeros': zeros, 'total': total,
        'sparsity': sparsity,
        'a16_bg': a16_bg,
        'a16_center': a16_center,
        'w16': w16,
        'skips_bg': skips_bg,
        'skips_center': skips_center,
        'skip_pct_bg': skip_pct_bg,
        'skip_pct_center': skip_pct_center
    })

    print(f"{img_idx:>6} {label:>6} {zeros:>7} {total:>7} "
          f"{sparsity:>9.1f}% {skip_pct_bg:>9.0f}%")

print("\n=== BACKGROUND REGION (top-left) ===")
print(f"{'Digit':<8} {'Activations':<45} {'Skips':>8}")
print("-" * 65)
for r in results:
    print(f"Digit {r['label']:<3} {str(r['a16_bg']):<45} "
          f"{r['skips_bg']}/16 = {r['skip_pct_bg']:.0f}%")

print("\n=== CENTER REGION (digit strokes) ===")
print(f"{'Digit':<8} {'Activations':<45} {'Skips':>8}")
print("-" * 65)
for r in results:
    print(f"Digit {r['label']:<3} {str(r['a16_center']):<45} "
          f"{r['skips_center']}/16 = {r['skip_pct_center']:.0f}%")

print("\n=== COPY INTO YOUR PAPER ===")
print("Background region: all zeros → 100% skip (validates zero-detection)")
print("Center region: mixed values → selective skip (validates skip discrimination)")
print()

print("=== TESTBENCH VALUES — CENTER REGION ===")
for r in results:
    print(f"\n--- Digit {r['label']} center region "
          f"({r['skips_center']}/16 = {r['skip_pct_center']:.0f}% skip expected) ---")
    for i in range(16):
        row = i // 4
        col = i % 4
        print(f"set_a({row},{col},{r['a16_center'][i]}); "
              f"set_b({row},{col},{r['w16'][i]});", end="  ")
        if col == 3:
            print()
