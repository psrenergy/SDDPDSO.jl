module SDDPDSO

    # --- packages
    using PSRClassesInterface
    using SDDP
    using JuMP
    # using Statistics
    # using Libdl
    # using CSV
    # using DataFrames

    # --- version check
    @static if VERSION < v"1.6"
        error("Julia version $VERSION not supported by SDDP-DSO, upgrade to 1.6 or later")
    end

    # --- includes
    include("model.jl")
    include("problem.jl")
    include("statistics.jl")

end # module
