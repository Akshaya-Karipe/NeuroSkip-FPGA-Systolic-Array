# NeuroSkip: AI-Assisted Sparsity-Aware Adaptive Precision Systolic Array
## for Embedded FPGA AI Acceleration

**Author:** Akshaya Karipe  
**Institution:** Sreenidhi Institute of Science and Technology, Hyderabad  

---

## Project Overview

NeuroSkip is an AI-assisted systolic array accelerator implemented on Xilinx FPGA.  
It leverages a lightweight TinyNet neural network (trained in Python) to predict and skip unnecessary multiply operations during matrix computation.  

The trained model is exported as a 256-entry Lookup Table (LUT) and integrated into Verilog hardware using `$readmemb`, enabling real-time inference directly on FPGA.

---

## Key Innovation

NeuroSkip introduces a novel integration of machine learning with digital hardware by embedding a TinyNet-based predictor inside a systolic array.  

Instead of executing all multiply-accumulate (MAC) operations, the system intelligently skips redundant computations based on data sparsity, resulting in:

- Reduced computational workload  
- Increased execution speed  
- Improved energy efficiency  

---

## Key Results

| Metric | Value |
|---|---|
| TinyNet Accuracy | 99.6% |
| Skip Rate (50% sparsity) | 50% |
| Skip Rate (81% sparsity) | 81% |
| Digit 4 Center (Key Result) | 25% skip — 75% active |
| Slice LUT Utilization | 561 / 63,400 (0.88%) |
| Maximum Frequency | 329 MHz |
| Total Power Consumption | 0.201 W |
| Speedup (81% sparsity) | 5.33× |
| Energy Efficiency | 137.8 GOPS/W |

---

## Architecture

- 4×4 Systolic Array for matrix multiplication  
- Processing Elements (PEs) with AI-driven skip logic  
- TinyNet neural network trained in Python  
- LUT-based inference integrated into Verilog hardware  
- Adaptive precision support (4-bit / 8-bit modes)  

**Dataflow:**
- Matrix A → Horizontal flow  
- Matrix B → Vertical flow  
- Partial sums → Accumulated across PEs  

---

## Project Structure

```
verilog/    - Verilog HDL design files  
tb/         - Simulation testbenches  
python/     - TinyNet training and LUT generation  
mem/        - Memory initialization files  
```

---

## How to Run

1. Train TinyNet:
   ```
   python python/train.py
   ```

2. Export LUT:
   ```
   python python/lut_export.py
   ```

3. Open Xilinx Vivado  
4. Add all files from `verilog/` and `tb/`  
5. Set `tb_top` as simulation top  
6. Run behavioral simulation  

---

## Tools Used

- Xilinx Vivado  
- Python 3 (PyTorch)  
- Target FPGA: Zynq-7020 (ZedBoard) / Artix-7 (portable across Xilinx 7-series)  

---

## Conclusion

NeuroSkip demonstrates an efficient co-design of AI and hardware by integrating machine learning-based decision-making into FPGA architectures.  

The approach significantly reduces redundant computations while maintaining accuracy, making it highly suitable for embedded AI acceleration.

---

## Author

**Akshaya Karipe**
