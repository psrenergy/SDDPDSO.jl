println("Running model")

# --- build sddp problem
m = DSO.build_model(par)

# --- export subproblems
for i in [1, 2, par.stages]
    DSO.SDDP.write_subproblem_to_file(m[i], joinpath(x.PATH,"debug","subproblem_$i.lp"))
end

# --- set seed
Random.seed!(1111)

# --- train model
DSO.SDDP.train(m, iteration_limit = par.max_iter, log_file = joinpath(x.PATH,"debug","sddp-dso.log"))

# --- simulate model
vars = [:bus_ang,:flw,:gen_die,:gen_sol,:gen_sol_max,:bat_c,:bat_d,:storage,:def,:cur,:dr,:dr_def,:dr_cur,:total_load,:imp,:exp,:imp_max,:exp_max]

sims = DSO.SDDP.simulate(m, 10, vars; skip_undefined_variables=true);

println("Dual variable CMO")
# a = JuMP.getdual(energyBalance_constraint[1])
# println(a)
