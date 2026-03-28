# ============================================================
# lut_export.py  — MyFPGAProject/python/
# Exports 256-entry LUT matching [3:0] Verilog ports
# ============================================================
import torch
import numpy as np

class TinyNet(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = torch.nn.Linear(2, 8)
        self.fc2 = torch.nn.Linear(8, 4)
        self.fc3 = torch.nn.Linear(4, 1)
    def forward(self, a, b):
        x = torch.cat([a, b], dim=-1)
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        return torch.sigmoid(self.fc3(x))

model = TinyNet()
model.load_state_dict(torch.load("tiny_net.pth"))
model.eval()

# Generate LUT for 4-bit inputs (0 to 15)
LUT_SIZE   = 16
lut        = np.zeros((LUT_SIZE, LUT_SIZE), dtype=int)
skip_count = 0

with torch.no_grad():
    for a in range(LUT_SIZE):
        for b in range(LUT_SIZE):
            inp_a  = torch.tensor([[float(a)]], dtype=torch.float32)
            inp_b  = torch.tensor([[float(b)]], dtype=torch.float32)
            output = model(inp_a, inp_b).item()
            lut[a, b] = 1 if output >= 0.5 else 0
            if lut[a, b] == 1:
                skip_count += 1

# Write exactly 256 lines to ai_lut.mem
output_path = "../mem/ai_lut.mem"
with open(output_path, "w") as f:
    for a in range(LUT_SIZE):
        for b in range(LUT_SIZE):
            f.write(f"{lut[a, b]}\n")

total = LUT_SIZE * LUT_SIZE
print(f"LUT exported to {output_path}")
print(f"Total entries:          {total}")
print(f"Skip decisions (1):     {skip_count}  ({skip_count/total*100:.1f}%)")
print(f"Compute decisions (0):  {total-skip_count}  ({(total-skip_count)/total*100:.1f}%)")

# Show LUT table
print(f"\n=== LUT Preview (1=skip, 0=compute) ===")
print(f"   b→  ", end="")
for b in range(LUT_SIZE):
    print(f"{b:2}", end=" ")
print()
for a in range(LUT_SIZE):
    print(f"a={a:2}:  ", end="")
    for b in range(LUT_SIZE):
        print(f"{lut[a,b]:2}", end=" ")
    print()

if skip_count < 5:
    print("\n⚠️  WARNING: Very few skips detected!")
    print("   This means training did not converge well.")
    print("   Try running dataset.py and train.py again.")
else:
    print(f"\n✅ Good! AI will skip ~{skip_count/total*100:.0f}% of multiplications")
    print("   Copy ai_lut.mem to your Vivado project folder and simulate")