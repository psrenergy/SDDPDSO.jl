module SDDPDSO

    # --- packages
    using PSRClassesInterface
    using SDDP
    using JuMP

    const PSRI = PSRClassesInterface
    # using Statistics
    # using Libdl
    # using CSV
    # using DataFrames

    # --- version check
    @static if VERSION < v"1.6"
        error("Julia version $VERSION not supported by SDDP-DSO, upgrade to 1.6 or later")
    end

    # --- includes
    include("types.jl")
    include("io.jl")
    include("utils.jl")
    include("model.jl")
    include("problem.jl")
    include("statistics.jl")
    include("psrclasses.jl")

end # module
