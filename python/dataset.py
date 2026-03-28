# ============================================================
# dataset.py  — MyFPGAProject/python/
# FIX: Values now 0-15 (matching the LUT 4-bit range)
# FIX: Skip rule is a*b < 10 (gives ~21% skip rate)
# ============================================================
import numpy as np

def generate_dataset(samples=5000):
    # Values 0-15 exactly matching [3:0] Verilog ports
    A = np.random.randint(0, 16, (samples,))
    B = np.random.randint(0, 16, (samples,))
    
    # Skip rule: product is small (near-zero means skip)
    # a*b < 10 gives ~21% skip rate — good for demo
    labels = (A * B < 10).astype(int)
    
    return A, B, labels

A, B, labels = generate_dataset()
np.savez('dataset.npz', A=A, B=B, labels=labels)

skip_pct = labels.mean() * 100
print(f"Dataset saved as dataset.npz")
print(f"Samples: {len(A)}")
print(f"Skip rate: {skip_pct:.1f}%  (should be ~21%)")
print(f"Value range: 0 to 15  (matches [3:0] Verilog ports)")
print(f"\nRun next: python train.py")