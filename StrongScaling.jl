using PyPlot

# Dual-axis strong-scaling plot: GPU runs against GPU nodes (bottom axis), CPU
# runs against CPU nodes (top axis). NOTE the two axes are independent, so the
# horizontal position of a GPU curve relative to a CPU curve has no meaning -
# see StrongScaling_calibrated.jl for plots on a common axis.
#
# All data, labels and colours live in StrongScaling_data.jl.

include(joinpath(@__DIR__, "StrongScaling_data.jl"))

fig, ax_gpu = subplots(figsize=(8.5, 4.2), dpi=300)
ax_cpu = ax_gpu.twiny()

for (nodes, tau, system, lbl, col, style) in SERIES
    ax = system in GPU_NODE_TYPES ? ax_gpu : ax_cpu
    ax.plot(nodes, tau, style, color=col, label=lbl, lw=2.2, ms=6)
end

# GPU (bottom) axis - log-x so the crowded low-node-count region (where most
# of the series sit) gets more room than the few points out past 400 nodes.
ax_gpu.set_xlabel("n / GPU nodes", fontsize=11)
ax_gpu.set_ylabel("τ (simulated days per day)", fontsize=11)
ax_gpu.grid(true, linestyle="--", alpha=0.3)
ax_gpu.set_xscale("log")
ax_gpu.set_xlim(6, 50)
ax_gpu.set_ylim(20, 1000)  # most data above this is speculative (LFRic projection)
ax_gpu.set_xticks(gpu_nodes)
ax_gpu.xaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
ax_gpu.xaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
ax_gpu.tick_params(axis="x", which="major", pad=4, labelsize=9)
ax_gpu.tick_params(axis="y", labelsize=9)

# CPU (top) axis
ax_cpu.set_xlabel("n / CPU nodes", fontsize=11)
ax_cpu.set_xscale("log")
ax_cpu.set_xlim(30, 700)
ax_cpu.set_xticks(cpu_nodes_ICON)
ax_cpu.xaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
ax_cpu.xaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
ax_cpu.tick_params(axis="x", which="major", pad=6, labelsize=9)
ax_gpu.spines["top"].set_visible(false)
ax_cpu.spines["bottom"].set_visible(false)
ax_cpu.xaxis.set_label_position("top")
ax_cpu.xaxis.tick_top()

# one legend for both axes, outside the data area
lines1, labels1 = ax_gpu.get_legend_handles_labels()
lines2, labels2 = ax_cpu.get_legend_handles_labels()
ax_gpu.legend(vcat(lines1, lines2), vcat(labels1, labels2),
              frameon=false, fontsize=7, loc="center left", bbox_to_anchor=(1.01, 0.5))

fig.tight_layout(rect=(0, 0, 1, 0.94))
fig.suptitle(TITLE, fontsize=12, y=0.99)
savefig("dual_axis_gpu_cpu_independent_2026.png", bbox_inches="tight")
println("wrote dual_axis_gpu_cpu_independent_2026.png")
