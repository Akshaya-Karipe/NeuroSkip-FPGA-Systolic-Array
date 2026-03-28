# ============================================================
# lenet5_extract.py  FIXED VERSION
# Place in: Desktop\MyFPGAProject\python\
# ============================================================
import torch
import torch.nn as nn
from torchvision import datasets, transforms
import numpy as np

print("=" * 50)
print("LeNet-5 FC Layer Extraction for Hardware")
print("=" * 50)

print("\nStep 1: Loading MNIST...")
transform = transforms.ToTensor()
train_data = datasets.MNIST('./mnist_data', train=True,
                             download=True, transform=transform)
test_data  = datasets.MNIST('./mnist_data', train=False,
                             download=True, transform=transform)
train_loader = torch.utils.data.DataLoader(train_data,
                                           batch_size=64, shuffle=True)
test_loader  = torch.utils.data.DataLoader(test_data, batch_size=1000)
print("MNIST loaded!")

class FC_Network(nn.Module):
    def __init__(self):
        super().__init__()
        self.flatten = nn.Flatten()
        self.fc1     = nn.Linear(784, 16)
        self.relu    = nn.ReLU()
        self.fc2     = nn.Linear(16, 10)
    def forward(self, x):
        x = self.flatten(x)
        x = self.relu(self.fc1(x))
        return self.fc2(x)

model     = FC_Network()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
criterion = nn.CrossEntropyLoss()

print("\nStep 2: Training FC network (5 epochs)...")
for epoch in range(5):
    model.train()
    total_loss = 0
    for images, labels in train_loader:
        optimizer.zero_grad()
        output = model(images)
        loss   = criterion(output, labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    print(f"  Epoch {epoch+1}/5 | Loss: {total_loss/len(train_loader):.4f}")

model.eval()
correct = 0
with torch.no_grad():
    for images, labels in test_loader:
        correct += (model(images).argmax(1) == labels).sum().item()
accuracy = correct / len(test_data) * 100
print(f"\nTest accuracy: {accuracy:.1f}%")

# ── Extract FC1 weights ──
print("\nStep 3: Extracting FC1 weights...")
fc1_w_float = model.fc1.weight.detach().numpy()   # shape (16, 784)

# Take 4x4 submatrix from float weights
w_sub_float = fc1_w_float[:4, :4]

# Quantize float weights to 8-bit and 4-bit
# Float weights are typically in range -0.1 to +0.1 after training
w_int8 = np.clip((w_sub_float * 127).astype(int), -127, 127)

# FIX: quantize properly from float to 4-bit
# Scale by 7 then clamp to -7..7
w_int4 = np.clip((w_sub_float * 50).astype(int), -7, 7)

print(f"4x4 weight submatrix (8-bit quantized):")
print(w_int8)
print(f"\n4x4 weight submatrix (4-bit quantized):")
print(w_int4)

# Use absolute values for hardware (testbench uses unsigned)
w_abs = np.abs(w_int4)
w_flat = [int(w_abs[r][c]) for r in range(4) for c in range(4)]
print(f"\nHardware weights (4-bit, absolute value):")
print(w_flat)

# ── Compute FC1 activations ──
print("\nStep 4: Computing FC1 output activations...")
sample_images = next(iter(test_loader))[0][:16]
sample_labels = next(iter(test_loader))[1][:16]

with torch.no_grad():
    flat    = model.flatten(sample_images)
    fc1_out = model.relu(model.fc1(flat))

act_float = fc1_out.detach().numpy()
max_val   = act_float.max()
if max_val > 0:
    act_4bit = np.clip((act_float * 15 / max_val).astype(int), 0, 15)
else:
    act_4bit = np.zeros_like(act_float, dtype=int)

zeros    = (act_4bit == 0).sum()
total    = act_4bit.size
sparsity = zeros / total * 100

print(f"FC1 output shape: {fc1_out.shape}")
print(f"After ReLU + 4-bit quantization:")
print(f"  Zero activations: {zeros}/{total} = {sparsity:.1f}%")
print(f"  Non-zero:         {total-zeros}/{total} = {100-sparsity:.1f}%")

# First image 16 activation values
act_16 = act_4bit[0][:16].tolist()
print(f"\nFC1 activations for first image (16 values):")
print(act_16)
print(f"Hardware weights (4-bit, flat):")
print(w_flat)

# Expected skips
skips = sum(1 for a, b in zip(act_16, w_flat) if a * b < 10)
print(f"\nExpected hardware skips: {skips}/16 = {skips/16*100:.0f}%")

# ── Save testbench file ──
print("\nStep 5: Saving lenet5_values.txt...")
# FIX: Use encoding='utf-8' and avoid special unicode characters
with open("lenet5_values.txt", "w", encoding="utf-8") as f:
    f.write("=" * 50 + "\n")
    f.write("LeNet-5 FC Layer Hardware Values\n")
    f.write("=" * 50 + "\n\n")
    f.write(f"Model: FC Network (784->16->10)\n")
    f.write(f"Test accuracy: {accuracy:.1f}%\n")
    f.write(f"FC1 activation sparsity: {sparsity:.1f}%\n")
    f.write(f"Expected hardware skip rate: {skips/16*100:.0f}%\n\n")
    f.write("--- PASTE INTO VERILOG TESTBENCH ---\n\n")
    for i in range(16):
        row = i // 4
        col = i % 4
        f.write(f"set_a({row},{col},{act_16[i]}); "
                f"set_b({row},{col},{w_flat[i]});\n")
    f.write("\n--- END ---\n")

print("Saved to lenet5_values.txt")

# ── Final summary ──
print("\n" + "=" * 50)
print("COPY THESE NUMBERS INTO YOUR PAPER")
print("=" * 50)
print(f"Model:            FC Network (784->16->10)")
print(f"Training epochs:  5")
print(f"Test accuracy:    {accuracy:.1f}%")
print(f"FC1 act sparsity: {sparsity:.1f}% zero after ReLU+4bit quant")
print(f"Expected skips:   {skips}/16 = {skips/16*100:.0f}%")
print(f"Sample labels:    {sample_labels.tolist()}")
print(f"\nActivations:  {act_16}")
print(f"Weights:      {w_flat}")