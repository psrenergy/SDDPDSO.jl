println("Running deterministic model")

# --- build sddp problem
m = DSO.build_deterministic_model(par)

# --- export subproblems
DSO.JuMP.write_to_file(m, joinpath(x.PATH,"debug","deterministic.lp"))

# --- train model
DSO.run_deterministic_model!(m, par)