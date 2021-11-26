println("Running model")

# --- build sddp problem
m = DSO.build_model(par)

# --- export subproblems
for i in [1, 2, par.stages]
    DSO.SDDP.write_subproblem_to_file(m[i], joinpath(x.PATH,"debug","subproblem_$i.lp"))
end

# --- set seed


# --- rodar o modelo
DSO.SDDP.train(m, iteration_limit = 10, log_file = joinpath(x.PATH,"debug","sddp-dso.log"))