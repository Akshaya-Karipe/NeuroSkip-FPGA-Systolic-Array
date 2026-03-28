import torch
import numpy as np

# TinyNet same as before
class TinyNet(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = torch.nn.Linear(2,4)
        self.fc2 = torch.nn.Linear(4,1)
    def forward(self, a, b):
        x = torch.cat([a,b], dim=-1)
        x = torch.relu(self.fc1(x))
        return torch.sigmoid(self.fc2(x))

# Load trained model
model = TinyNet()
model.load_state_dict(torch.load("tiny_net.pth"))
model.eval()

# LUT size for 16x16
lut_size = 16
lut = np.zeros((lut_size, lut_size), dtype=int)

with torch.no_grad():
    for a in range(lut_size):
        for b in range(lut_size):
            inp_a = torch.tensor([[a]], dtype=torch.float32)
            inp_b = torch.tensor([[b]], dtype=torch.float32)
            output = model(inp_a, inp_b).item()
            lut[a, b] = 1 if output >= 0.5 else 0

# Save as FPGA-ready .mem
with open("ai_lut.mem", "w") as f:
    for i in range(lut_size):
        for j in range(lut_size):
            f.write(f"{lut[i,j]}\n")

print("16x16 LUT exported to ai_lut.mem successfully!")