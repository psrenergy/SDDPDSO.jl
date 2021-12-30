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

sims = DSO.SDDP.simulate(
    m,
    5,
    custom_recorders = Dict{Symbol,Function}(
        :shadow_price => (sp::DSO.JuMP.Model) -> Float64[DSO.JuMP.dual(DSO.JuMP.constraint_by_name(sp,"energy_balance_$i")) for i in 1:par.nbus],
    ), 
    vars;
    skip_undefined_variables=true
);