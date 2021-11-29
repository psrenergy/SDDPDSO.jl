import SDDPDSO
using Test
using GLPK
const DSO = SDDPDSO

# ---
casepath = joinpath(".", "data", "example_00")

# ---
opt = GLPK.Optimizer

# --- 
@testset "SDDP DSO" begin

    # --- Test 00 - 
    @testset "Read database parameters" begin
        @time include("read_database.jl")
    end

    # --- Test 01 - 
    @testset "Setup problem" begin
        @time include("setup_problem.jl")
    end

    # --- Test 02 - 
    @testset "Run SDDP model" begin
        # @time include("run_model.jl")
    end

    # --- Test 03 - 
    @testset "Write results" begin
        # @time include("write_results.jl")
    end
end
