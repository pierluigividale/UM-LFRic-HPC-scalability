using PyPlot

# Strong scaling of ICON (data: Daniel Klocke) and the UM/LFRic on UK machines,
# on ONE x axis in a common unit, instead of independent GPU/CPU node axes.
#
# Node counts are converted to "equivalent Levante CPU nodes" (2x AMD EPYC 7763
# Milan) using a per-node figure of merit, chosen with BASIS:
#   :bandwidth  peak memory bandwidth per node (atmosphere models are mostly
#               memory-bandwidth bound) - from published hardware specs
#   :power      nominal node power, a proxy for energy/allocation cost
#   :cost       SPECULATIVE hardware cost per node at installation; this basis
#               plots against the total cost of the nodes used (M US$) instead
#               of equivalent nodes
#   :running_cost  SPECULATIVE annual running cost per node (electricity,
#               assuming continuous operation at nominal power, a
#               representative price and data-centre PUE - see
#               StrongScaling_data.jl); plots against the total annual running
#               cost of the nodes used (M US$/year), instead of equivalent
#               nodes - this is OPEX for one year, as opposed to :cost's CAPEX
#               at installation
# Run once per basis; each writes its own PNG.
#
# CHECK THE NODE TABLE (NODES_SPEC in StrongScaling_data.jl): the values are nominal specs (peak theoretical
# bandwidth; power from component TDPs), not measurements, and a few depend on
# the exact configuration of each machine (marked "verify"). For :power, the
# centres' node-hour charging rates or measured node power would be better.

BASIS = length(ARGS) > 0 ? Symbol(ARGS[1]) : :bandwidth

# All data, labels and per-node figures live in StrongScaling_data.jl
include(joinpath(@__DIR__, "StrongScaling_data.jl"))
nodes_spec, REFERENCE, series = NODES_SPEC, REFERENCE_NODE, SERIES

# per-node figure of merit on the current BASIS, in whatever unit that basis uses
# (k US$ for :cost and :running_cost, native spec units otherwise)
basis_value(system) = BASIS == :cost ? nodes_spec[system].cost :
    BASIS == :running_cost ? annual_running_cost_per_node(system) :
    getfield(nodes_spec[system], BASIS)

# x coordinate: equivalent Levante CPU nodes, or (cost / running_cost bases)
# total node cost / annual running cost in M US$(/year)
equiv(nodes, system) = BASIS in (:cost, :running_cost) ? nodes .* basis_value(system) ./ 1000 :
    nodes .* basis_value(system) ./ basis_value(REFERENCE)

# ---------------------------
# Plot: one x axis, legend outside the data area
# ---------------------------
fig, ax = subplots(figsize=(7.5, 4.2), dpi=300)
for (n, tau, system, lbl, col, style) in series
    ax.plot(equiv(n, system), tau, style, color=col, label=lbl, lw=2.0, ms=5)
end

if BASIS == :cost
    ax.set_xlabel("Hardware cost of the nodes used\n(M US\$, speculative estimate at installation)", fontsize=10)
elseif BASIS == :running_cost
    ax.set_xlabel("Annual running cost of the nodes used\n(M US\$/year, speculative - electricity only, continuous operation)", fontsize=10)
else
    basis_text = BASIS == :bandwidth ? "peak memory bandwidth" : "nominal node power"
    ax.set_xlabel("Equivalent Levante CPU nodes (by $basis_text)", fontsize=11)
end
ax.set_title(TITLE, fontsize=12)
ax.set_ylabel("τ (simulated days per day)", fontsize=11)
# log-x so the crowded low end isn't squeezed by the few points out past
# ~400 equivalent nodes; left bound just below the smallest real x value
# instead of 0 (undefined on a log axis).
all_equiv = filter(v -> !isnan(v) && v > 0, vcat([equiv(n, system) for (n, _, system, _, _, _) in series]...))
ax.set_xscale("log")
ax.set_xlim(left = 0.9 * minimum(all_equiv))
ax.xaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
ax.xaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
ax.set_ylim(0, 1000)  # most data above this is speculative (LFRic projection)
ax.grid(true, linestyle="--", alpha=0.3)
ax.tick_params(labelsize=9)
ax.spines["top"].set_visible(false)
ax.spines["right"].set_visible(false)

# what one GPU node counts as, on this basis - placed clear of the plot,
# below the main legend (both anchored at the same x so they line up)
ratios = join(["1 $(lbl) node = $(round(basis_value(s) / basis_value(REFERENCE), digits=1)) Levante CPU nodes" *
               (BASIS == :cost ? " by cost" : BASIS == :running_cost ? " by running cost" : " eq.")
               for (s, lbl) in [("a100_node", "A100"), ("gh200_node", "GH200")]], "\n")

leg = ax.legend(frameon=false, fontsize=7, loc="center left", bbox_to_anchor=(1.01, 0.5))
# draw once so the legend's extent is known, then place the ratios text just
# below its lower edge (both in axes-fraction coordinates)
fig.canvas.draw()
leg_bottom_axes = leg.get_window_extent().transformed(ax.transAxes.inverted()).y0
ax.text(1.01, leg_bottom_axes - 0.05, ratios, transform=ax.transAxes, ha="left", va="top", fontsize=7, color="0.35")
fig.tight_layout()
out = BASIS == :cost ? "strong_scaling_node_cost.png" :
    BASIS == :running_cost ? "strong_scaling_running_cost.png" :
    "strong_scaling_equivalent_nodes_$(BASIS).png"
savefig(out, bbox_inches="tight")
println("wrote ", out)
