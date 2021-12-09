function add_variables_model!(m, par)
    # Define the state variable
    
    # --- battery storage 
    if par.flag_bat
        JuMP.@variable(m, par.bat_e_max[i] >= storage[i=1:par.nbat] >= par.bat_e_min[i], SDDP.State, initial_value = par.bat_e_ini[i])
    end
    # --- demand response
    if par.flag_dem_rsp
        JuMP.@variable(m, sum(par.demand[i]) >= total_load[i=par.set_dem_rsp] >= 0.0, SDDP.State, initial_value = 0.0)
    end

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
    end)

    # import energy from higher level
    if par.flag_import
        JuMP.@variables(m, begin
            imp[i=1:par.nbus] >= 0
            imp_max[i=1:par.nbus]
        end)
    end

    # export energy to higher level
    if par.flag_export
        JuMP.@variables(m, begin
            exp[i=1:par.nbus] >= 0
            exp_max[i=1:par.nbus]
        end)
    end

    # demand response
    if par.flag_dem_rsp
        JuMP.@variables(m, begin
            dr[i=par.set_dem_rsp]     >= 0
            dr_cur[i=par.set_dem_rsp] >= 0
            dr_def[i=par.set_dem_rsp] >= 0
        end)
    end
end

function add_import_constraints!(m, par, t)
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
    JuMP.@constraint(m, import_capacity_1[i=valid_buses]    , imp[i] <= par.imp_max[i][t,1])
    JuMP.@constraint(m, import_capacity_2[i=non_valid_buses], imp[i] <= 0.0       ) 

end

function add_export_constraints!(m, par, t)
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
    JuMP.@constraint(m, export_capacity_1[i=valid_buses]    , exp[i] <= par.exp_max[i][t,1])
    JuMP.@constraint(m, export_capacity_2[i=non_valid_buses], exp[i] <= 0.0       )    

end

function add_network_constraints!(m, par)
    flw, ang = m[:flw], m[:bus_ang]
    
    JuMP.@constraint(m, kirchoff_second[i=1:par.nlin],flw[i] == 100.0 * (1 / par.cir_x[i]) * (ang[par.cir_bus_to[i]] - ang[par.cir_bus_fr[i]]))
    
    if par.flag_sec_law
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
        if par.flag_bat
            bat_d   = haskey(par.bus_map_bat,i) ? m[:bat_d  ][par.bus_map_bat[i]] : 0.0
            bat_c   = haskey(par.bus_map_bat,i) ? m[:bat_c  ][par.bus_map_bat[i]] : 0.0
        else
            bat_d = 0.0
            bat_c = 0.0
        end

        # load
        dem     = haskey(par.bus_map_dem,i) ? sum(par.demand[j][t] for j in par.bus_map_dem[i]) : 0.0
        if par.flag_dem_rsp
            dem = haskey(par.bus_map_rsp,i) ? m[:dr][par.bus_map_rsp[i]] : dem
        end

        # losses
        losses  = 0.0
        if par.flag_losses
            losses = par.losses[i][t]
        end
        
        # slack
        def = haskey(par.bus_map_dem,i) ? m[:def][par.bus_map_dem[i]] : 0.0
        cur = m[:cur][i]

        # network
        h = par.cir_bus_to .== i
        cir_in  = any(h) ? m[:flw][h] : 0.0

        h = par.cir_bus_fr .== i
        cir_out = any(h) ? m[:flw][h] : 0.0

        # import/export
        imp = 0.0
        if par.flag_import 
            imp = haskey(par.bus_map_imp, i) ? m[:imp][i] : 0.0
        end

        exp = 0.0
        if par.flag_export
            exp = haskey(par.bus_map_exp, i) ? m[:exp][i] : 0.0
        end

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
    JuMP.@constraint(m, dr_sum[i=par.set_dem_rsp],
        total_load[i].out == total_load[i].in + dr[i] + dr_def[i] - dr_cur[i] 
    )

    # Shift
    JuMP.@constraint(m, dr_shift_ub[i=par.set_dem_rsp], dr[i] <= par.demand[i][t] * (1 + par.dem_rsp_shift[i]))
    JuMP.@constraint(m, dr_shift_lb[i=par.set_dem_rsp], dr[i] >= par.demand[i][t] * (1 - par.dem_rsp_shift[i]))

    if mod(t,24) == 0
        JuMP.@constraint(m, dr_integral[i=par.set_dem_rsp], total_load[i].out == sum(par.demand[i][1:t]))
    end
end

function add_stageobjective!(m, par, t)
    
    obj_ter    = get_objective_thermal(m, par, t)
    
    obj_def    = get_objective_deficit(m, par, t)
    
    obj_cur    = get_objective_curtailment(m, par, t)
    
    obj_dr_def = get_objective_demand_response_deficit(m, par, t)
    
    obj_dr_cur = get_objective_demand_response_curtailment(m, par, t)
    
    obj_imp    = get_objective_import(m, par, t)
    
    obj_exp    = get_objective_export(m, par, t)

    # Define the objective for each stage `t`. Note that we can use `t` as an
    # index for t = 1, 2, ..., 24    
    SDDP.@stageobjective(m, 
        obj_ter
        + obj_def + obj_cur 
        + obj_dr_def + obj_dr_cur
        + obj_imp - obj_exp
    )
end

function parameterize_solar_generation_scenarios!(m, par, t)
    gen_sol_max = m[:gen_sol_max]

    # Parameterize the subproblem.
    SDDP.parameterize(m, 1:par.dso_scenarios) do ω
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
    SDDP.parameterize(m, 1:par.dso_scenarios) do ω
        
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
        
        par.flag_bat && add_battery_constraints!(subproblem, par)
    
        add_solar_generation_constraints!(subproblem, par)
    
        add_energy_balance_constraints!(subproblem, par, t)
    
        par.flag_dem_rsp && add_demand_response_constraints!(subproblem, par, t)

        par.flag_import && add_import_constraints!(subproblem, par, t)

        par.flag_export && add_export_constraints!(subproblem, par, t)

        parameterize_solar_generation_scenarios!(subproblem, par, t)
        
        add_stageobjective!(subproblem, par, t)

        # parameterize_scenarios!(subproblem, par, t)

    end

    return m
end