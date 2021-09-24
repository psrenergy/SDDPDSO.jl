function statistical_summary(model, simulations)
    objective_values = [sum(stage[:stage_objective] for stage in sim) for sim in simulations]

    # --- stats
    n  = length(simulations)
    μ  = round(mean(objective_values), digits = 2)
    ci = round(1.96 * std(objective_values) / sqrt(n), digits = 2)

    # --- display
    println("Confidence interval: ", μ, " ± ", ci)
    println("Lower bound: ", round(SDDP.calculate_bound(model), digits = 2))
end


