#!/bin/bash
# Regenerate all five strong-scaling plots from StrongScaling_data.jl.
set -e
cd "$(dirname "$0")"
julia StrongScaling.jl                        # dual_axis_gpu_cpu_independent_2026.png
for basis in bandwidth power cost running_cost; do  # strong_scaling_equivalent_nodes_{bandwidth,power}.png,
    julia StrongScaling_calibrated.jl $basis  # strong_scaling_node_cost.png, strong_scaling_running_cost.png
done
