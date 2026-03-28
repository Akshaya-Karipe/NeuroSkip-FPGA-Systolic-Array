# ============================================================
# train.py  — MyFPGAProject/python/
# FIX: Trains on correct A,B pairs (not matrix slices)
# FIX: 500 epochs for better convergence (loss should reach ~0.05)
# ============================================================
import torch
import numpy as np

# Load dataset
data   = np.load('dataset.npz')
A      = torch.tensor(data['A'], dtype=torch.float32).unsqueeze(1)
B      = torch.tensor(data['B'], dtype=torch.float32).unsqueeze(1)
labels = torch.tensor(data['labels'], dtype=torch.float32)

print(f"Loaded {len(A)} training pairs")
print(f"A range: {data['A'].min()} to {data['A'].max()}")
print(f"B range: {data['B'].min()} to {data['B'].max()}")
print(f"Skip rate: {labels.mean()*100:.1f}%")

# TinyNet: 2 inputs (a, b) → predict skip decision
class TinyNet(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = torch.nn.Linear(2, 8)   # increased to 8 neurons
        self.fc2 = torch.nn.Linear(8, 4)
        self.fc3 = torch.nn.Linear(4, 1)
    def forward(self, a, b):
        x = torch.cat([a, b], dim=-1)
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        return torch.sigmoid(self.fc3(x))

model     = TinyNet()
optimizer = torch.optim.Adam(model.parameters(), lr=0.005)
criterion = torch.nn.BCELoss()

print("\nTraining TinyNet...")
best_loss = 999
for epoch in range(500):
    optimizer.zero_grad()
    output = model(A, B)
    loss   = criterion(output.squeeze(), labels)
    loss.backward()
    optimizer.step()
    if loss.item() < best_loss:
        best_loss = loss.item()
    if epoch % 50 == 0:
        acc = ((output.squeeze() > 0.5).float() == labels).float().mean() * 100
        print(f"  Epoch {epoch:3d} | Loss: {loss.item():.4f} | Accuracy: {acc:.1f}%")

# Final accuracy
with torch.no_grad():
    preds = (model(A, B).squeeze() > 0.5).float()
    acc   = (preds == labels).float().mean() * 100

print(f"\nFinal Loss:     {best_loss:.4f}  (good if < 0.15)")
print(f"Final Accuracy: {acc:.1f}%  (good if > 85%)")
torch.save(model.state_dict(), "tiny_net.pth")
print("Model saved as tiny_net.pth")
print("\nRun next: python lut_export.py")