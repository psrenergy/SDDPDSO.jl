module SDDPDSO

    # --- packages
    using PSRClassesInterface
    using SDDP
    using JuMP
    using CSV
    using DataFrames
    using Statistics
    using PSRIO

    const PSRI = PSRClassesInterface
    # using Statistics
    # using Libdl

    # --- version check
    @static if VERSION < v"1.6"
        error("Julia version $VERSION not supported by SDDP-DSO, upgrade to 1.6 or later")
    end

    # --- includes
    include("types.jl")
    include("io.jl")
    include("utils.jl")
    include("model.jl")
    include("deterministic.jl")
    include("stageobjective.jl")
    include("objective.jl")
    include("problem.jl")
    include("losses.jl")
    include("results.jl")
    include("statistics.jl")
    include("psrclasses.jl")
    include("report.jl")

    # --- main
    function main(ARGS)
        @show ARGS

        psrio = PSRIO.create()

        PSRIO.run(psrio, [raw"d:\Downloads\Example_PSRIO"], 
        recipes=[raw".\deps\psrio-scripts\sddpdso\dashboard.lua"], 
        model="none", 
        verbose=3)
    end

    # --- initialize
    function initialize(casepath::String)
        !isdir(joinpath(casepath,"debug"))   && mkdir(joinpath(casepath,"debug"))
        !isdir(joinpath(casepath,"reports")) && mkdir(joinpath(casepath,"reports"))
        !isdir(joinpath(casepath,"results")) && mkdir(joinpath(casepath,"results"))
    end
end # module
