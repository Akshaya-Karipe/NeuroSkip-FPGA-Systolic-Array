# ============================================================
# generate_8bit_luts.py
# Generates two 256-entry LUTs for 8-bit hierarchical skip
# ============================================================
import torch
import sys
sys.path.append('.')

# Load your trained TinyNet model
# (reuse from train.py)
import torch.nn as nn

class TinyNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(2, 8), nn.ReLU(),
            nn.Linear(8, 4), nn.ReLU(),
            nn.Linear(4, 1), nn.Sigmoid()
        )
    def forward(self, x):
        return self.net(x)

# ── Generate HIGH nibble LUT ──────────────────────────────
# For 8-bit: high nibble represents values 0-15 (same range)
# Skip if high_a * high_b < threshold_high
# For 8-bit inputs, threshold scales: if a,b in [0,255]
# then a_high * b_high < 1 means both high nibbles are 0
# which means a < 16 and b < 16 (truly small values)

print("Generating high-nibble LUT...")
with open("../mem/ai_lut_high.mem", "w") as f:
    for a_high in range(16):
        for b_high in range(16):
            # If either high nibble is nonzero, product could be large
            # Only skip if both high nibbles are 0
            # (meaning both a and b are below 16 — truly 4-bit range)
            if a_high == 0 and b_high == 0:
                f.write("1\n")  # skip — values definitely small
            else:
                f.write("0\n")  # compute — high bits are significant

print("Saved ai_lut_high.mem — 256 entries")

# ── Verify ────────────────────────────────────────────────
with open("../mem/ai_lut_high.mem") as f:
    lines = f.readlines()
skip_count = sum(1 for l in lines if l.strip() == '1')
print(f"High LUT skip entries: {skip_count}/256 = {skip_count/256*100:.1f}%")
print("Low LUT (ai_lut.mem) already exists from original training")
print("\nBoth LUTs ready for ai_skip_lut_8bit.v")
