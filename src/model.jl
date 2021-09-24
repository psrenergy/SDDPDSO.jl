function add_variables_model!(m, par)
    # Define the state variable
    JuMP.@variable(m, par.bat_e_max[i] >= storage[i=1:par.nbat] >= par.bat_e_min[i], SDDP.State, initial_value = par.bat_e_ini[i])

    JuMP.@variable(m, sum(par.demand[i]) >= total_load[i=1:par.nload] >= 0.0, SDDP.State, initial_value = 0.0)

    # Define the control variables
    JuMP.@variables(m, begin
        bat_c[i=1:par.nbat]       >= 0
        bat_d[i=1:par.nbat]       >= 0
            
        gen_die[i=1:par.ngen]     >= 0
            
        gen_sol[i=1:par.nsol]     >= 0
        gen_sol_max[i=1:par.nsol] 
        
        flw[i=1:par.nlin]         
    
        def[i=1:par.nload]        >= 0
        cur[i=1:par.nbus]         >= 0
    
        bus_ang[i=1:par.nbus]     >= 0

        # import and export energy to N1
        imp[i=1:par.nbus]     >= 0
        imp_max[i=1:par.nbus]

        exp[i=1:par.nbus]     >= 0
        exp_max[i=1:par.nbus]

        # should there be a flag here?
        dr[i=1:par.nload]     >= 0
        dr_cur[i=1:par.nload] >= 0
        dr_def[i=1:par.nload] >= 0
    end)
end

function add_import_constraints!(m, par)
    imp, imp_max = m[:imp], m[:imp_max]

    # --- limiting energy import capacity for frontier buses  
    valid_buses, non_valid_buses = [], []

    for i in 1:par.nbus
        if haskey(par.bus_map_imp, i)
            push!(valid_buses, i)
        else
            push!(non_valid_buses, i)
        end
    end

    # --- add constraint
    JuMP.@constraint(m, import_capacity_1[i=valid_buses]    , imp[i] <= imp_max[i])
    JuMP.@constraint(m, import_capacity_2[i=non_valid_buses], imp[i] <= 0.0       ) 

end

function add_export_constraints!(m, par)
    exp, exp_max = m[:exp], m[:exp_max]

    # --- limiting energy export capacity for frontier buses
    valid_buses, non_valid_buses = [], []

    for i in 1:par.nbus
        if haskey(par.bus_map_exp, i)
            push!(valid_buses, i)
        else
            push!(non_valid_buses, i)
        end
    end

    # --- add constraint
    JuMP.@constraint(m, export_capacity_1[i=valid_buses]    , exp[i] <= exp_max[i])
    JuMP.@constraint(m, export_capacity_2[i=non_valid_buses], exp[i] <= 0.0       )    

end

function add_network_constraints!(m, par)
    flw, ang = m[:flw], m[:bus_ang]
    
    JuMP.@constraint(m, kirchoff_second[i=1:par.nlin],flw[i] == 100.0 * (1 / par.cir_x[i]) * (ang[par.cir_bus_to[i]] - ang[par.cir_bus_fr[i]]))
    
    if par.use_cir_cap
        JuMP.@constraint(m, flow_capacity_p[i=1:par.nlin],flw[i] <= +par.cir_cap[i])
        JuMP.@constraint(m, flow_capacity_n[i=1:par.nlin],flw[i] >= -par.cir_cap[i])
    end
end

function add_generation_constraints!(m, par)
    gen_die = m[:gen_die]

    JuMP.@constraint(m, gen_capacity_max[i=1:par.ngen],gen_die[i] <= +par.gen_cap[i])
    JuMP.@constraint(m, gen_capacity_min[i=1:par.ngen],gen_die[i] >= 0.0)
end

function add_battery_constraints!(m, par)
    bat_c, bat_d, storage = m[:bat_c], m[:bat_d], m[:storage]

    JuMP.@constraint(m, bat_balance[i=1:par.nbat],
        storage[i].out == storage[i].in + (bat_c[i] * par.bat_c_eff[i]) - (bat_d[i] / par.bat_d_eff[i])
    )
    
    # --- battery capacity constraint
    JuMP.@constraint(m, bat_cap_c_max[i=1:par.nbat], bat_c[i] - (bat_d[i] / par.bat_d_eff[i]) <= par.bat_cap[i])
    JuMP.@constraint(m, bat_cap_d_max[i=1:par.nbat], bat_d[i] - (bat_c[i] * par.bat_c_eff[i]) <= par.bat_cap[i])     
end

function add_solar_generation_constraints!(m, par)
    gen_sol, gen_sol_max = m[:gen_sol], m[:gen_sol_max]

    # --- solar capacity constraint
    JuMP.@constraint(m, sol_cap_max[i=1:par.nsol], gen_sol[i] <= gen_sol_max[i])   
end

function add_energy_balance_constraints!(m, par, t)

    for i in 1:par.nbus

        # generation
        gen_sol = haskey(par.bus_map_sol,i) ? m[:gen_sol][par.bus_map_sol[i]] : 0.0
        gen_die = haskey(par.bus_map_gen,i) ? m[:gen_die][par.bus_map_gen[i]] : 0.0

        # battery
        bat_d   = haskey(par.bus_map_bat,i) ? m[:bat_d  ][par.bus_map_bat[i]] : 0.0
        bat_c   = haskey(par.bus_map_bat,i) ? m[:bat_c  ][par.bus_map_bat[i]] : 0.0
        
        # load
        losses  = par.losses[i][t]
        dem     = haskey(par.bus_map_rsp,i) ? m[:dr][par.bus_map_rsp[i]] : 0.0
        
        # slack
        def     = haskey(par.bus_map_dem,i) ? m[:def][par.bus_map_dem[i]] : 0.0
        cur     = m[:cur][i]

        # network
        h = par.cir_bus_to .== i
        cir_in  = any(h) ? m[:flw][h] : 0.0

        h = par.cir_bus_fr .== i
        cir_out = any(h) ? m[:flw][h] : 0.0

        # import/export
        imp = haskey(par.bus_map_imp, i) ? m[:imp][i] : 0.0
        exp = haskey(par.bus_map_exp, i) ? m[:exp][i] : 0.0

        # elv

        # balance constraint
        JuMP.@constraint(m, [i],
            + sum(cir_in ) - sum(cir_out)
            + sum(gen_sol) + sum(gen_die)
            + sum(bat_d  ) - sum(bat_c  )
            + sum(imp    ) - sum(exp    )
            == sum(dem) + sum(losses) 
            - sum(def) + cur
        )

    end
end

function add_demand_response_constraints!(m, par, t)
    dr, dr_def, dr_cur, total_load = m[:dr], m[:dr_def], m[:dr_cur], m[:total_load]

    # Load sum over periods
    JuMP.@constraint(m, dr_sum[i=1:par.nload],
        total_load[i].out == total_load[i].in + dr[i] + dr_def[i] - dr_cur[i] 
    )

    # Shift
    JuMP.@constraint(m, dr_shift_ub[i=1:par.nload], dr[i] <= par.demand[i][t] * (1 + par.dem_rsp_shift[i]))
    JuMP.@constraint(m, dr_shift_lb[i=1:par.nload], dr[i] >= par.demand[i][t] * (1 - par.dem_rsp_shift[i]))

    # Load Integral
    if t == par.stages
        JuMP.@constraint(m, dr_integral[i=1:par.nload], total_load[i].out == sum(par.demand[i]))
    end
end

function add_stageobjective!(m, par) # having problems here...
    gen_die, def, cur, dr_def, dr_cur = m[:gen_die], m[:def], m[:cur], m[:dr_def], m[:dr_cur]

    # Define the objective for each stage `t`. Note that we can use `t` as an
    # index for t = 1, 2, ..., 24    
    SDDP.@stageobjective(m, 
        par.gen_cost'gen_die 
        + sum(def * par.def_cost) + sum(cur * par.def_cost)
        + sum(dr_def * par.def_cost * 2) + sum(dr_cur * par.def_cost * 2)
    )
end

function parameterize_solar_generation_scenarios!(m, par, t)
    gen_sol_max = m[:gen_sol_max]

    # Parameterize the subproblem.
    SDDP.parameterize(m, 1:par.nscn) do ω
        for i = 1:par.nsol
            JuMP.fix(gen_sol_max[i], par.sol_scn[t,ω,i])
        end
    end
end

function parameterize_scenarios!(m, par, t)
    
    # renewable
    gen_sol_max = m[:gen_sol_max]
    
    # import/export
    imp, exp, imp_max, exp_max = m[:imp], m[:exp], m[:imp_max], m[:exp_max]

    # thermal generation
    gen_die = m[:gen_die]

    # defict and curtailment
    gen_die, def, cur, dr_def, dr_cur = m[:gen_die], m[:def], m[:cur], m[:dr_def], m[:dr_cur]

    # Parameterize the subproblem.
    SDDP.parameterize(m, 1:par.nscn) do ω
        
        # parametrize renewable generation scenarios
        for i = 1:par.nsol
            JuMP.fix(gen_sol_max[i], par.sol_scn[t,ω,i])
        end

        # parametrize import/export capacity scenarios
        for i = 1:par.nbus
            haskey(par.bus_map_imp,i) && JuMP.fix(imp_max[i], par.imp_max[par.bus_map_imp[i][1]][t,ω])
            haskey(par.bus_map_exp,i) && JuMP.fix(exp_max[i], par.exp_max[par.bus_map_exp[i][1]][t,ω])            
        end

        # parametrize the objective function
        SDDP.@stageobjective(m, 
            par.gen_cost'gen_die
            + sum(imp[i] * par.imp_cost[par.bus_map_imp[i][1]][t,ω] for i in 1:par.nbus if haskey(par.bus_map_imp, i)) 
            - sum(exp[i] * par.exp_cost[par.bus_map_exp[i][1]][t,ω] for i in 1:par.nbus if haskey(par.bus_map_exp, i)) 
            + sum(def * par.def_cost) + sum(cur * par.def_cost)
            + sum(dr_def * par.def_cost * 2) + sum(dr_cur * par.def_cost * 2)
    )

    end
end

function build_model(par)
    m = SDDP.LinearPolicyGraph(
        stages = par.stages, sense = par.sense, lower_bound = par.lower_bound, optimizer = par.optimizer
    ) do subproblem, t
    
        add_variables_model!(subproblem, par)
    
        add_network_constraints!(subproblem, par)
    
        add_generation_constraints!(subproblem, par)
        
        add_battery_constraints!(subproblem, par)
    
        add_solar_generation_constraints!(subproblem, par)
    
        add_energy_balance_constraints!(subproblem, par, t)
    
        add_demand_response_constraints!(subproblem, par, t)

        add_import_constraints!(subproblem, par)

        add_export_constraints!(subproblem, par)

        parameterize_scenarios!(subproblem, par, t)
    end

    return m
end