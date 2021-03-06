import SDDPDSO
using Test
using GLPK
using Random
using PSRIO

const DSO = SDDPDSO

using PSRIO
@show psrio = PSRIO.create()

# ---
casepath = joinpath(".", "data", "example_00")

# --- initialize DSO
DSO.initialize(casepath)

# ---
opt = GLPK.Optimizer

#par.flag_dem_rsp, par.flag_import, par.flag_export, par.flag_sec_law

Bin_set = [0,1]
# for a in Bin_set, b in Bin_set, c in Bin_set
#     println([a,b,c])
# end

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

    # --- Test 03 - 
    @testset "Run deterministic model" begin
        @time include("run_deterministic_model.jl")
    end
    
    # --- Test 02 - 
    @testset "Run SDDP model" begin
        @time include("run_model.jl")
    end

    # --- Test 04 - 
    @testset "Write results" begin
        # @time include("write_results.jl")
    end

end
