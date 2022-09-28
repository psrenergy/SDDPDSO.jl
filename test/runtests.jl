import SDDPDSO
const DSO    = SDDPDSO
const HiGHS  = DSO.HiGHS
const PSRIO  = DSO.PSRIO
const Random = DSO.Random

using Test

# ---
casepath = joinpath(".", "data", "case_studies", "case_06")

# --- initialize DSO
DSO.initialize(casepath)

# --- Solver definition
opt = HiGHS.Optimizer

Bin_set = [0,1]
execution_combinations = []
for a in Bin_set, b in Bin_set, c in Bin_set, d in Bin_set, e in Bin_set, f in Bin_set
    push!(execution_combinations,[a,b,c,d,e,f])
end

# # --- 
# @testset "SDDP DSO" begin

#     # --- Test 00 - 
#     @testset "Read database parameters" begin
#         @time include("read_database.jl")
#     end

#     x.max_iter = 1
#     println("Running tests with all possible executions")
#     for i in 1:lastindex(execution_combinations)
#         x.flag_export, x.flag_import, x.flag_dem_rsp, x.flag_bat, x.flag_sec_law, x.flag_losses = execution_combinations[i]
#         println("Configurations: [export, import, dem_rsp, bat, sec_law, losses]")
#         println("Actual configuration: $(execution_combinations[i]) \n")
#         # --- Test 01 - 
#         @testset "Setup problem" begin
#             @time include("setup_problem.jl")
#         end

#         # --- Test 03 - 
#         @testset "Run deterministic model" begin
#             @time include("run_deterministic_model.jl")
#         end
        
#         # --- Test 02 - 
#         @testset "Run SDDP model" begin
#             @time include("run_model.jl")
#         end

#         # --- Test 04 - 
#         @testset "Write results" begin
#             # @time include("write_results.jl")
#         end
        
#     end
# end
