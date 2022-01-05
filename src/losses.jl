function calculate_losses_rf2(r, f, pu=true)
    r = pu ? r : r / 100
    f = pu ? f : f / 100
    return r * f * f 
end

function calculate_losses_gtheta2(g, Δ)
    return r * Δ * Δ
end

"""
    calculate_g(r, x) : [%]

    calculate the series conductance of a circuit

    r : [%] resistance of the circuit 
    x : [%] reactance of the circuit
"""
function calculate_g(r::Float64, x::Float64)
    return r / (x^2 + r^2)
end

"""
    calculate_b(r, x) : [%]

    calculate the series susceptance of a circuit

    r : [%] resistance of the circuit 
    x : [%] reactance of the circuit
"""
function calculate_b(r::Float64, x::Float64)
    return -x / (x^2 + r^2)
end

function calculate_AC_flow(g_km::Float64, b_km::Float64, θ_km::Float64, v_k::Float64=1.0, v_m::Float64=1.0)
    return (g_km * v_k^2) - (v_k * v_m * g_km * cos(θ_km)) - (v_k * v_m * b_km * sin(θ_km)) 
end

"""
    calculate_AC_losses(g_km, θ_km, v_k, v_m) : [pu]

    calculate the AC losses of a circuit, based on : losses = Pkm + Pmk

    g_km : [%  ] series conductance of circuit 
    θ_km : [rad] angle ?opening? between buses
    v_k  : [pu ] voltage level of bus k
    v_m  : [pu ] voltage level of bus m
"""
function calculate_AC_losses(g_km::Float64, θ_km::Float64, v_k::Float64=1.0, v_m::Float64=1.0)
    return g_km * ( v_k^2 + v_m^2 - 2 * v_k * v_m * cos(θ_km) )
end

"""
    get_AC_losses_from_deterministc(par, m) : [pu]

    ...

    par : DSO.Problem 
    m   : JuMP.Model
"""
function get_bus_losses_from_deterministc(par, m) # change name...
    
    bus_losses = [zeros(Float64, par.stages) for i in 1:par.nbus]

    cir_flw = JuMP.value.(m[:flw])

    for t in 1:par.stages

        for c in 1:par.nlin
            # losses per circuit [p.u.]
            cir_losses = calculate_losses_rf2(par.cir_r[c], cir_flw[t,c], false)

            # convert to MVA (or MW if f_cnv=1.0)
            cir_losses *= 100.0

            # distribute half of the losses for each bus
            bus_losses[par.cir_bus_fr[c]][t] += cir_losses ./ 2
            bus_losses[par.cir_bus_to[c]][t] += cir_losses ./ 2
        end 
    end

    return bus_losses
end

function get_stagewise_losses(par)
    return 100.0 .* Float64[sum(par.losses[i][t] for i in 1:par.nload) / sum(par.demand[i][t] for i in 1:par.nload) for t in 1:par.stages]
end