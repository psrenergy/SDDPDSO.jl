module SDDPDSO

    # --- packages
    using PSRClassesInterface
    using SDDP
    using JuMP
    using CSV
    using DataFrames
    using Statistics

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
    include("stageobjective.jl")
    include("problem.jl")
    include("results.jl")
    include("statistics.jl")
    include("psrclasses.jl")
    include("report.jl")

    # --- main
    function main(ARGS)
        @show ARGS
    end

    # --- initialize
    function initialize(casepath::String)
        !isdir(joinpath(casepath,"debug"))   && mkdir(joinpath(casepath,"debug"))
        !isdir(joinpath(casepath,"reports")) && mkdir(joinpath(casepath,"reports"))
        !isdir(joinpath(casepath,"results")) && mkdir(joinpath(casepath,"results"))
    end
end # module
