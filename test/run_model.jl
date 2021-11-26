println("Running model")

# --- build sddp problem
m = DSO.build_model(par)

# --- export subproblems
for i in [1, 2, par.stages]
    DSO.SDDP.write_subproblem_to_file(m[i], joinpath(x.PATH,"lp","subproblem_$i.lp"))
end

# --- set seed


# --- rodar o modelo
