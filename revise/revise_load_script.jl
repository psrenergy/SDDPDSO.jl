import Pkg
Pkg.instantiate()

using Revise

Pkg.activate(dirname(@__DIR__))

using SDDPDSO
@info("""
This session is using SDDPDSO with Revise.jl.
For more information visit https://timholy.github.io/Revise.jl/stable/.
""")