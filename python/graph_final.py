# ============================================================
# graph_final.py
# Place in: Desktop\MyFPGAProject\python\
# Run with: python graph_final.py
# ============================================================
import matplotlib.pyplot as plt
import numpy as np

# ── YOUR REAL NUMBERS — already filled in ──────────────────
S1_MAC   = 144       # Scenario 1 MAC
S1_SKIP  = 0         # Scenario 1 SKIP
S2_MAC   = 72        # Scenario 2 MAC
S2_SKIP  = 72        # Scenario 2 SKIP
S3_MAC   = 27        # Scenario 3 MAC
S3_SKIP  = 117       # Scenario 3 SKIP
LUT_USED = 561       # from Vivado Utilization
LUT_TOT  = 63400     # Artix-7 total
FF_USED  = 157       # from Vivado Utilization
FMAX     = 329       # MHz — from your timing report
POWER    = 0.201     # Watts — from your power report
AI_ACC   = 99.6      # TinyNet accuracy %
# ───────────────────────────────────────────────────────────

fig, axes = plt.subplots(1, 3, figsize=(16, 6))
fig.suptitle(
    'AI-Assisted Sparsity-Aware Systolic Array — Experimental Results\n'
    'Xilinx Artix-7 (xc7a100tcsg324-1) | Vivado 2025.2',
    fontsize=13, fontweight='bold'
)

# ── GRAPH 1: MAC vs SKIP counts ────────────────────────────
ax1 = axes[0]
x      = np.arange(3)
labels = ['Baseline\n(0 zeros)', 'Sparse\n(8 zeros)', 'High Sparse\n(12 zeros)']
macs   = [S1_MAC,  S2_MAC,  S3_MAC]
skips  = [S1_SKIP, S2_SKIP, S3_SKIP]

ax1.bar(x, macs,  0.5, label='Active MACs',      color='#2196F3', edgecolor='navy')
ax1.bar(x, skips, 0.5, bottom=macs,
        label='Skipped (AI LUT)', color='#FF9800', edgecolor='darkorange')

for i, (m, s) in enumerate(zip(macs, skips)):
    ax1.text(i, m / 2, str(m), ha='center', va='center',
             color='white', fontweight='bold', fontsize=12)
    if s > 0:
        ax1.text(i, m + s / 2, str(s), ha='center', va='center',
                 color='white', fontweight='bold', fontsize=11)
    total = m + s
    if s > 0:
        pct = round(s / total * 100)
        ax1.text(i, total + 6,
                 f'↓{pct}% saved',
                 ha='center', color='green',
                 fontweight='bold', fontsize=10)

ax1.set_xticks(x)
ax1.set_xticklabels(labels, fontsize=9)
ax1.set_ylabel('Operation Count')
ax1.set_title('MAC vs Skipped Operations', fontweight='bold')
ax1.legend(fontsize=9)
ax1.set_ylim(0, 210)
ax1.grid(axis='y', alpha=0.3)
ax1.spines['top'].set_visible(False)
ax1.spines['right'].set_visible(False)

# ── GRAPH 2: Skip rate per scenario ────────────────────────
ax2 = axes[1]
totals    = [m + s for m, s in zip(macs, skips)]
skip_pcts = [s / t * 100 if t > 0 else 0
             for s, t in zip(skips, totals)]
bar_clrs  = ['#4CAF50', '#FF9800', '#F44336']
bars2     = ax2.bar(x, skip_pcts, 0.5,
                    color=bar_clrs, edgecolor='black', linewidth=0.7)

for bar, val in zip(bars2, skip_pcts):
    ax2.text(bar.get_x() + bar.get_width() / 2,
             val + 1.5, f'{val:.0f}%',
             ha='center', fontweight='bold', fontsize=13)

ax2.set_xticks(x)
ax2.set_xticklabels(labels, fontsize=9)
ax2.set_ylabel('Skip Rate (%)')
ax2.set_title('AI-Driven Skip Rate\nby Sparsity Level', fontweight='bold')
ax2.set_ylim(0, 100)
ax2.axhline(y=21.5, color='blue', linestyle='--',
            linewidth=1.5, label='LUT base rate (21.5%)')
ax2.legend(fontsize=8)
ax2.grid(axis='y', alpha=0.3)
ax2.spines['top'].set_visible(False)
ax2.spines['right'].set_visible(False)

# ── GRAPH 3: Resource + performance summary ─────────────────
ax3 = axes[2]
categories = ['LUT\n(561/63400)', 'Flip-Flops\n(157/126800)',
              'DSP\n(0/240)', 'BRAM\n(0/135)']
pcts = [
    LUT_USED / LUT_TOT * 100,
    FF_USED  / 126800  * 100,
    0,
    0
]
clrs4 = ['#3F51B5', '#9C27B0', '#009688', '#FF5722']
bars3 = ax3.bar(np.arange(4), pcts, 0.55,
                color=clrs4, edgecolor='black', linewidth=0.7)

for bar, val, pct in zip(bars3, [LUT_USED, FF_USED, 0, 0], pcts):
    ax3.text(bar.get_x() + bar.get_width() / 2,
             max(pct, 0.08) + 0.05,
             f'{val}\n({pct:.2f}%)',
             ha='center', fontsize=8, fontweight='bold')

ax3.set_xticks(np.arange(4))
ax3.set_xticklabels(categories, fontsize=8)
ax3.set_ylabel('Utilization (%)')
ax3.set_title(
    f'FPGA Resource Utilization\n'
    f'Fmax = {FMAX} MHz  |  Power = {POWER} W  |  AI Acc = {AI_ACC}%',
    fontweight='bold', fontsize=9
)
ax3.set_ylim(0, 2.5)
ax3.grid(axis='y', alpha=0.3)
ax3.spines['top'].set_visible(False)
ax3.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('final_results.png', dpi=150, bbox_inches='tight')
print("")
print("✅ Graph saved as: final_results.png")
print("")
print("=== YOUR COMPLETE RESULTS FOR PAPER ===")
print(f"Scenario 1 — Baseline:     MAC={S1_MAC}, SKIP={S1_SKIP}, Rate=0%")
print(f"Scenario 2 — Sparse:       MAC={S2_MAC}, SKIP={S2_SKIP}, Rate=50%")
print(f"Scenario 3 — High Sparse:  MAC={S3_MAC}, SKIP={S3_SKIP}, Rate=81%")
print(f"LUT usage:   {LUT_USED} / {LUT_TOT} = {LUT_USED/LUT_TOT*100:.1f}%")
print(f"FF usage:    {FF_USED} / 126800 = {FF_USED/126800*100:.2f}%")
print(f"DSP used:    0")
print(f"BRAM used:   0")
print(f"Fmax:        {FMAX} MHz")
print(f"Power:       {POWER} W")
print(f"AI accuracy: {AI_ACC}%")