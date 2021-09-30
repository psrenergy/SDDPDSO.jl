import SDDPDSO
using Test
const DSO = SDDPDSO

# ---
casepath = joinpath(".","test", "data", "example_00")

# --- 
@testset "SDDP DSO" begin

    # --- Test 00 - 
    @testset "Read database parameters" begin
        @time include("test/read_database.jl")
    end

    # --- Test 01 - 
    @testset "Setup problem" begin
        @time include("test/setup_problem.jl")
    end

    # --- Test 02 - 
    @testset "Run SDDP model" begin
        @time include("test/run_model.jl")
    end

    # --- Test 03 - 
    @testset "Write results" begin
        @time include("test/write_results.jl")
    end
end
