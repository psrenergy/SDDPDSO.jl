"""
    add_bus!
"""
function add_bus!(case::Problem)
    # --- validate parameters
    # validate(x)
    
    # --- increase dimension
    case.nbus += 1    
end

"""
    add_circuit!
"""
function add_circuit!(case::Problem, x::T, r::T, cap::T, bus_fr::U, bus_to::U)::{T,U}
    # --- validate parameters
    if !validate()
        println("Unvalid element! Unable to add to system.")
        return
    end
    
    # --- increase dimension
    case.ncir += 1

    # --- record circuit data
    push!(cir_x     , x     )
    push!(cir_r     , r     )
    push!(cir_cap   , cap   )
    push!(cir_bus_fr, bus_fr)
    push!(cir_bus_to, bus_to)
end

"""
    add_demand!
"""
function add_demand!(case::Problem, demand::Vector{Float64}, bus::Int64)
    # --- validate parameters
    # validate(x)
    
    # --- increase dimension
    case.nload += 1

    # --- record circuit data
    push!(case.demand, demand)

    # --- map into the grid
    push!(bus_map_dem[bus], case.nload)
end

"""
    add_termal_plant!
"""
function add_thermal_plant!(case::Problem, p_max::T, cost::T, bus::Int64)::T
    # --- validate parameters
    # validate(x)
    
    # --- increase dimension
    case.nter += 1

    # --- record themal plant data
    push!(case.ter_p_max, p_max)
    push!(case.ter_cost , cost)

    # --- map into the grid
    push!(bus_map_ter[bus], case.nter)
end

"""
    add_hydro_plant!
"""
function add_hydro_plant!()
end

"""
    add_renewable_plant!
"""
function add_renewable_plant!(case::Problem, p_max::T, scn::Matrix{Float64}, bus::Int64)::T
    # --- validate parameters
    # validate(x)
    
    # --- increase dimension
    case.nren += 1

    # --- record battery data
    push!(case.ren_p_max, p_max)
    
    # --- record renewable scenarios
    push!(case.ren_scn, scn)

    # --- map device into the grid
    push!(bus_map_sol[bus], case.nren)
end

"""
    add_battery!
"""
function add_battery!(case::Problem, e_ini::T, e_min::T, e_max::T, p_max::T, c_eff::T, d_eff::T, bus::Int64)::T
    # --- validate parameters
    # validate(x)
    
    # --- increase dimension
    case.nbat += 1

    # --- record battery data
    push!(case.bat_e_ini, e_ini)
    push!(case.bat_e_min, e_min)
    push!(case.bat_e_max, e_max)
    push!(case.bat_p_max, p_max)   
    push!(case.bat_c_eff, c_eff)
    push!(case.bat_d_eff, d_eff)

    # --- map device into the grid
    push!(bus_map_bat[bus], case.nbat)
end