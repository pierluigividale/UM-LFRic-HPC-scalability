# Strong-scaling data for the "Atmosphere-only GCMs at Δx ≈ 10 km" plots.
#
# This file holds ALL the numbers used by StrongScaling.jl (dual-axis plot) and
# StrongScaling_calibrated.jl (bandwidth / power / cost plots). Edit only this
# file, then regenerate every plot with:
#
#     ./make_strong_scaling_plots.sh
#
# Conventions for editors:
#   - τ = simulated days per (wall-clock) day; node counts are whole nodes.
#   - Use NaN for a missing or withheld value (the point is then not drawn);
#     node-count and τ vectors of one series must have the same length.
#   - Put the source or date of any number you change in a comment next to it.
#   - Values marked "derived" or "projected" are not measurements; keep their
#     labels saying so.
#   - Each series listed in SERIES (bottom of the file) is drawn; to drop a
#     series, comment out its line there.

# ---------------------------------------------------------------------------
# Per-node figures of merit (used by StrongScaling_calibrated.jl)
# ---------------------------------------------------------------------------
# bandwidth: peak theoretical memory bandwidth, GB/s per node
# power:     nominal node power, kW (from component TDPs - better: measured
#            node power, or the centre's charge per node-hour)
# cost:      k US$ per node at installation - SPECULATIVE: approximate list
#            prices of CPUs/GPUs and memory at the installation date plus
#            ~5 k$ for chassis, interconnect and integration; replace with
#            procurement figures if available
NODES_SPEC = Dict(
    # Levante CPU: 2 x EPYC 7763 (Milan), 8 x DDR4-3200 per socket; 2021
    "levante_cpu" => (bandwidth = 409.6,  power = 0.70, cost = 22.),
    # ARCHER2: 2 x EPYC 7742 (Rome), 8 x DDR4-3200 per socket; 2020
    "archer2"     => (bandwidth = 409.6,  power = 0.55, cost = 20.),
    # 2 x EPYC 9004 (Genoa), 12 x DDR5-4800 per socket - verify SKU/DIMMs; 2023
    "genoa"       => (bandwidth = 921.6,  power = 0.90, cost = 32.),
    # Cirrus: 2 x EPYC 9005 (Turin), 12 x DDR5-6000 per socket - verify SKU/DIMMs; 2025
    "turin"       => (bandwidth = 1152.0, power = 1.10, cost = 37.),
    # Levante GPU: 4 x A100-80GB SXM (2039 GB/s each) + host CPU; 2021-22
    "a100_node"   => (bandwidth = 8156.0, power = 2.40, cost = 90.),
    # 4 x GH200, H100 96 GB HBM3 at 4000 GB/s each - verify machine and memory
    # (144 GB HBM3e parts give 4900 GB/s); GPU HBM only; 2024
    "gh200_node"  => (bandwidth = 16000., power = 3.00, cost = 160.),
)
REFERENCE_NODE = "levante_cpu"   # the "equivalent nodes" unit

# Annual operating ("running") cost per node, used by the :running_cost basis
# in StrongScaling_calibrated.jl - this is overwhelmingly electricity, so
# approximated as:
#     running cost = nominal node power (kW) x hours/year x PUE x price ($/kWh)
# SPECULATIVE, like the capital `cost` field above: assumes continuous (24/7)
# operation all year at the node's nominal power, and a single representative
# electricity price and data-centre PUE across all these sites (actually a mix
# of UK and German centres with different billed rates) - replace with each
# centre's actual rate/PUE if available.
ELECTRICITY_PRICE_USD_PER_KWH = 0.20   # representative UK/EU industrial rate, 2025-26
DATACENTRE_PUE                = 1.2    # typical modern HPC data-centre overhead
HOURS_PER_YEAR                = 8760.
annual_running_cost_per_node(system) =   # k US$ per node per year
    NODES_SPEC[system].power * HOURS_PER_YEAR * DATACENTRE_PUE * ELECTRICITY_PRICE_USD_PER_KWH / 1000

# ---------------------------------------------------------------------------
# ICON (data: Daniel Klocke, Δx = 10 km, checked with him)
# ---------------------------------------------------------------------------
gpu_nodes        = [8,     16,  24,  32,  40,  48]
tau_levante_A100 = [115.2558145, 205.131322 , 279.3521875, 343.5882222, 380.8546484, 426.7003813]
tau_levante_H200 = [216.079193 , 406.6697606, 562.2964604, 688.0514764, 798.010884, NaN]

cpu_nodes_ICON   = [85, 200, 375, 490, 580, 650]
tau_levante_cpu  = [105.1735912, 250.4384122, 456.9591064, 580.0721062, 717.4917684, 785.883209]

# ---------------------------------------------------------------------------
# UM on ARCHER2 (128 cores per node)
# ---------------------------------------------------------------------------
# UM11.2 removed 2026-10-22 (superseded by UM13.9 below - too old to be a
# useful comparison point any more). If ever needed again it's in git history.

cpu_nodes_UM_AOsprey       = [ 196,  296, 386]
tau_UM_archer2_cpu_AOsprey = [365*0.56, 365*0.68, 365*0.71]

# not plotted
tau_UM_grace_cpu = [242., 482, NaN, NaN, NaN ]

# UM13.9 branch (parallelised I/O of atmospheric composition fields) - MEASURED.
#   nodes   runtime(s)   SYPD
#   200     9126.019     0.79   (ARCHER2)
#   302     7726.847     0.93   (ARCHER2)
#   100     6393.07      1.13   (Cirrus)
cpu_nodes_UM139_archer2   = [200, 302]
tau_UM139_archer2_cpu     = [365*0.79, 365*0.93]

cpu_nodes_UM139_cirrus    = [100]
tau_UM139_cirrus_cpu      = [365*1.13]

# UM on Cirrus (AMD Zen5 Turin) - DERIVED, not measured, now based on the
# latest (UM13.9) ARCHER2 data rather than the retired UM11.2 numbers. The
# theoretical basis: the UM is 2x faster per core and a Cirrus node has 2x
# the cores of an ARCHER2 node, i.e. 4x faster node for node, so a Cirrus run
# matching ARCHER2's core count at n nodes uses n/2 nodes and gives 2x the τ.
#
# RE-CHECKED 2026-10-22 against the one real UM13.9 Cirrus measurement above:
# this 4x/2x theory predicts tau=576.7 at 100 Cirrus nodes (2x the n=200
# ARCHER2 point, 288.4), but the measured value is only 412.4 - a realized
# speedup of ~1.43x, not the theoretical 2x (71% of predicted). So the
# formula/derivation logic itself is correct (verified: halving nodes while
# doubling tau is exactly "4x throughput per node at half the node count"),
# but the 4x assumption itself over-predicts actual UM13.9 performance on
# Cirrus by about 40% - likely other bottlenecks (memory bandwidth, I/O,
# interconnect) not scaling with core speed. Kept as a clearly-labelled
# "derived"/theoretical curve rather than silently recalibrated to the one
# real point, since one measurement isn't enough to refit the whole curve.
cpu_nodes_UM139_cirrus_derived = cpu_nodes_UM139_archer2 ./ 2
tau_UM139_cirrus_derived_cpu   = 2 .* tau_UM139_archer2_cpu

# ---------------------------------------------------------------------------
# LFRic - MEASURED at 49/98/196 nodes; PROJECTED beyond that
# ---------------------------------------------------------------------------
# Real measurements, superseding the earlier 49/66-node pair (2026-10-22
# update): C896 timestep-only scaling (no diagnostics), 2 threads/rank
# (fastest config at 49 nodes - OpenMP efficiency is still being improved,
# which should help more at higher node counts where MPI cost grows relative
# to compute). 49->196 nodes (4x) is 87% parallel efficiency.
#   nodes   SDPD
#   49      216
#   98      426
#   196     753
cpu_nodes_LFRic        = [49, 98, 196]
tau_LFRic_nextgen_cpu  = [216., 426., 753.]

# Projected continuation beyond the last measurement. The three real points
# above are NOT a constant power law - per-doubling efficiency drops from
# 98.6% (49->98) to 88.4% (98->196), i.e. MPI overhead growing relative to
# compute at scale, matching the explanation given with the data. Projecting
# with the overall 49->196 average (exponent 0.90) would understate that and
# be too optimistic beyond 196 nodes, so this uses the more recent, worse
# 98->196 segment's exponent instead:
#     τ = 753 * (n/196)^LFRIC_SCALING_EXPONENT
# (1.0 = ideal strong scaling; 0.82 = the measured 98->196 trend, i.e.
# assumes efficiency keeps degrading at roughly its most recently observed
# rate rather than levelling off)
LFRIC_SCALING_EXPONENT  = 0.822
cpu_nodes_LFRic_proj    = [196, 392, 588, 784, NaN]
tau_LFRic_proj_cpu      = tau_LFRic_nextgen_cpu[end] .* (cpu_nodes_LFRic_proj ./ cpu_nodes_LFRic_proj[1]) .^ LFRIC_SCALING_EXPONENT

# ---------------------------------------------------------------------------
# What is plotted: (node counts, τ, node type in NODES_SPEC, label, colour, line style)
# GPU node types (a100_node, gh200_node) go on the GPU axis of the dual-axis plot.
# ---------------------------------------------------------------------------
SERIES = [
    (gpu_nodes,            tau_levante_A100,           "a100_node",   "ICON GPU (A100-80)",                       "black",   "-s"),
    (gpu_nodes,            tau_levante_H200,           "gh200_node",  "ICON GPU (GH200)",                         "#5fc9cf", "-s"),
    (cpu_nodes_ICON,       tau_levante_cpu,            "levante_cpu", "ICON CPU (AMD Milan)",                     "0.6",     "-o"),
    (cpu_nodes_UM_AOsprey, tau_UM_archer2_cpu_AOsprey, "archer2",     "UM13.8, A2 CPU (AMD Rome)",                "orange",  "-o"),
    (cpu_nodes_UM139_cirrus_derived, tau_UM139_cirrus_derived_cpu, "turin", "UM13.9, Cirrus CPU (AMD Zen5 Turin), derived", "blue", "--o"),
    (cpu_nodes_LFRic,      tau_LFRic_nextgen_cpu,      "genoa",       "LFRic, CPU (AMD Genoa)",                   "green",   "-o"),
    (cpu_nodes_LFRic_proj, tau_LFRic_proj_cpu,         "genoa",       "LFRic, CPU (AMD Genoa), projected",        "green",   "--o"),
    (cpu_nodes_UM139_archer2, tau_UM139_archer2_cpu,   "archer2",     "UM13.9, A2 CPU (AMD Rome)",                "purple",  "-o"),
    # red: was freed up by removing UM11.2; picked for visibility - this
    # point otherwise gets lost against the other curves (2026-10-22).
    # Diamond marker (not "-o" like everything else): this run is COUPLED
    # atmosphere-ocean, unlike every other series in this file, which are all
    # atmosphere-only - its tau isn't directly comparable to the rest on that
    # basis alone, hence "coupled" in the label and the different symbol.
    (cpu_nodes_UM139_cirrus,  tau_UM139_cirrus_cpu,    "turin",       "UM13.9 (coupled to ORCA12), Cirrus CPU (AMD Zen5 Turin)", "red", "-D"),
]
GPU_NODE_TYPES = ("a100_node", "gh200_node")
TITLE = "Atmosphere-only GCMs at Δx ≈ 10 km"
