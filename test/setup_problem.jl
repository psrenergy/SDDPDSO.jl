println("Seting up the problem")

using GLPK

# --- create problem set
par = DSO.Problem();

# --- setup simulatoin parameters
DSO.setup_parameters!(par, x, n, d, GLPK.Optimizer)
