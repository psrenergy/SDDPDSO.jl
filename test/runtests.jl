import SDDPDSO
using Test
const dso = SDDPDSO

# ---
casepath = joinpath(".", "data", "example_00")

# --- 
@testset "SDDP DSO" begin

    # --- Test 00 - 
    @testset "Read database parameters" begin
        @time include("read_database.jl")
    end

    # --- Test 01 - 
    @testset "Read database parameters" begin
        @time include("setup_problem.jl")
    end

    # --- Test 02 - 
    @testset "Read database parameters" begin
        @time include("run_model.jl")
    end

    # --- Test 03 - 
    @testset "Read database parameters" begin
        @time include("write_results.jl")
    end
end
