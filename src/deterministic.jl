function add_deterministic_variables_model!(m, par)
    par.flag_debug && println("> variables: control")
   
    # Define the control variables
    JuMP.@variables(m, begin
        
        # thermal
        gen_die[t=1:par.stages, i=1:par.ngen] >= 0
        
        # renewable
        gen_sol[t=1:par.stages, i=1:par.nsol]     >= 0
        gen_sol_max[t=1:par.stages, i=1:par.nsol] 
        
        # circuit energy flow
        flw[t=1:par.stages, i=1:par.nlin]     
        
        # bus angles
        bus_ang[t=1:par.stages, i=1:par.nbus] >= 0
    
        # slack variables
        def[t=1:par.stages, i=1:par.nload] >= 0
        cur[t=1:par.stages, i=1:par.nbus]  >= 0
    
    end)

    # battery
    if par.flag_bat
        JuMP.@variables(m, begin
            bat_e[t=1:(par.stages+1), i=1:par.nbat] >= 0
            bat_c[t=1:par.stages    , i=1:par.nbat] >= 0
            bat_d[t=1:par.stages    , i=1:par.nbat] >= 0
        end)
    end

    # import energy from higher level
    if par.flag_import
        JuMP.@variables(m, begin
            imp[t=1:par.stages, i=1:par.nbus] >= 0
            imp_max[t=1:par.stages, i=1:par.nbus]
        end)
    end

    # export energy to higher level
    if par.flag_export
        JuMP.@variables(m, begin
            exp[t=1:par.stages, i=1:par.nbus] >= 0
            exp_max[t=1:par.stages, i=1:par.nbus]
        end)
    end

    # demand response
    if par.flag_dem_rsp
        JuMP.@variables(m, begin
            total_load[t=1:(par.stages+1), i=par.set_dem_rsp] >= 0
            dr[t=1:par.stages, i=par.set_dem_rsp]         >= 0
            dr_cur[t=1:par.stages, i=par.set_dem_rsp]     >= 0
            dr_def[t=1:par.stages, i=par.set_dem_rsp]     >= 0
        end)
    end
end

function add_deterministic_import_constraints!(m, par)
    par.flag_debug && println("> constraints: energy import")

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
    JuMP.@constraint(m, import_capacity_1[t=1:par.stages, i=valid_buses]    , imp[t,i] <= sum(par.imp_max[j][t,1] for j in par.bus_map_imp[i]))
    JuMP.@constraint(m, import_capacity_2[t=1:par.stages, i=non_valid_buses], imp[t,i] <= 0.0       ) 

end

function add_deterministic_export_constraints!(m, par)
    par.flag_debug && println("> constraints: energy export")

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
    JuMP.@constraint(m, export_capacity_1[t=1:par.stages, i=valid_buses]    , exp[t,i] <= sum(par.exp_max[j][t,1] for j in par.bus_map_exp[i]))
    JuMP.@constraint(m, export_capacity_2[t=1:par.stages, i=non_valid_buses], exp[t,i] <= 0.0       )    

end

function add_deterministic_network_constraints!(m, par)
    par.flag_debug && println("> constraints: network")

    flw, ang = m[:flw], m[:bus_ang]
    
    JuMP.@constraint(m, kirchoff_second[t=1:par.stages, i=1:par.nlin],
        flw[t,i] == 100.0 * (1 / par.cir_x[i]) * (ang[t,par.cir_bus_to[i]] - ang[t,par.cir_bus_fr[i]])
    )
    
    if par.flag_sec_law
        JuMP.@constraint(m, flow_capacity_p[t=1:par.stages, i=1:par.nlin], flw[t,i] <= +par.cir_cap[i])
        JuMP.@constraint(m, flow_capacity_n[t=1:par.stages, i=1:par.nlin], flw[t,i] >= -par.cir_cap[i])
    end
end

function add_deterministic_generation_constraints!(m, par)
    par.flag_debug && println("> constraints: thermal operation")

    gen_die = m[:gen_die]

    JuMP.@constraint(m, gen_capacity_max[t=1:par.stages, i=1:par.ngen],gen_die[i] <= +par.gen_cap[i])
    JuMP.@constraint(m, gen_capacity_min[t=1:par.stages, i=1:par.ngen],gen_die[i] >= 0.0)
end

function add_deterministic_battery_constraints!(m, par)
    par.flag_debug && println("> constraints: battery operation")

    bat_c, bat_d, bat_e = m[:bat_c], m[:bat_d], m[:bat_e]

    # --- e_i = ? 
    JuMP.@constraint(m, bat_balance[t=1, i=1:par.nbat],
        bat_e[t,i] == par.bat_e_ini[i]
    )

    # --- e_i = e_f ? 
    JuMP.@constraint(m, [t=(par.stages+1), i=1:par.nbat],
        bat_e[t,i] == bat_e[1,i]
    )

    # --- battery storage constraint - upper bound
    JuMP.@constraint(m, [t=1:par.stages,i=1:par.nbat],
        bat_e[t,i] <= par.bat_e_max[i]
    )

    # --- battery storage constraint - lower bound
    JuMP.@constraint(m, bat_balance_lb[t=1:par.stages,i=1:par.nbat],
        bat_e[t,i] >= par.bat_e_min[i]
    )

    # --- battery energy balance constraint
    JuMP.@constraint(m, bat_balance_ub[t=1:par.stages,i=1:par.nbat],
        bat_e[t+1,i] == bat_e[t,i] + (bat_c[t,i] * par.bat_c_eff[i]) - (bat_d[t,i] / par.bat_d_eff[i])
    )
    
    # --- battery capacity constraint
    JuMP.@constraint(m, bat_cap_c_max[t=1:par.stages,i=1:par.nbat],
        bat_c[t,i] - (bat_d[t,i] / par.bat_d_eff[i]) <= par.bat_cap[i]
    )

    # --- battery capacity constraint
    JuMP.@constraint(m, bat_cap_d_max[t=1:par.stages,i=1:par.nbat],
        bat_d[t,i] - (bat_c[t,i] * par.bat_c_eff[i]) <= par.bat_cap[i]
    )
end

function add_deterministic_energy_balance_constraints!(m, par)
    par.flag_debug && println("> constraints: nodal energy balance")

    for t in 1:par.stages, i in 1:par.nbus

        # generation
        gen_sol = haskey(par.bus_map_sol,i) ? m[:gen_sol][t,par.bus_map_sol[i]] : 0.0
        gen_die = haskey(par.bus_map_gen,i) ? m[:gen_die][t,par.bus_map_gen[i]] : 0.0

        # battery
        if par.flag_bat
            bat_d   = haskey(par.bus_map_bat,i) ? m[:bat_d  ][t, par.bus_map_bat[i]] : 0.0
            bat_c   = haskey(par.bus_map_bat,i) ? m[:bat_c  ][t, par.bus_map_bat[i]] : 0.0
        else
            bat_d = 0.0
            bat_c = 0.0
        end

        # load
        dem     = haskey(par.bus_map_dem,i) ? sum(par.demand[j][t] for j in par.bus_map_dem[i]) : 0.0
        if par.flag_dem_rsp
            dem = haskey(par.bus_map_rsp,i) ? m[:dr][t, par.bus_map_rsp[i]] : dem
        end

        # losses
        losses  = 0.0
        # if par.flag_losses
        #     losses = par.losses[i][t]
        # end
        
        # slack
        def = haskey(par.bus_map_dem,i) ? m[:def][t, par.bus_map_dem[i]] : 0.0
        cur = m[:cur][t,i]

        # network
        h = par.cir_bus_to .== i
        cir_in  = any(h) ? m[:flw][t,h] : 0.0

        h = par.cir_bus_fr .== i
        cir_out = any(h) ? m[:flw][t,h] : 0.0

        # import/export
        imp = 0.0
        if par.flag_import 
            imp = haskey(par.bus_map_imp, i) ? m[:imp][t, i] : 0.0
        end

        exp = 0.0
        if par.flag_export
            exp = haskey(par.bus_map_exp, i) ? m[:exp][t, i] : 0.0
        end

        # elv

        # balance constraint
        energy_balance = JuMP.@constraint(m,
            + sum(cir_in ) - sum(cir_out)
            + sum(gen_sol) + sum(gen_die)
            + sum(bat_d  ) - sum(bat_c  )
            + sum(imp    ) - sum(exp    )
            == sum(dem) + sum(losses) 
            - sum(def) + cur
        )
        JuMP.set_name(energy_balance, "energy_balance_$(i)_$(t)")
    end
end

function add_deterministic_demand_response_constraints!(m, par)
    par.flag_debug && println("> constraints: demand response")

    dr, dr_def, dr_cur, total_load = m[:dr], m[:dr_def], m[:dr_cur], m[:total_load]

    # Load sum over periods
    JuMP.@constraint(m, dr_sum[t=par.stages, i=par.set_dem_rsp],
        total_load[t+1,i] == total_load[t,i] + dr[t,i] 
    )

    # Shift
    JuMP.@constraint(m, dr_shift_ub[t=par.stages,i=par.set_dem_rsp], dr[t,i] <= par.demand[i][t] * (1 + par.dem_rsp_shift[i]))
    JuMP.@constraint(m, dr_shift_lb[t=par.stages,i=par.set_dem_rsp], dr[t,i] >= par.demand[i][t] * (1 - par.dem_rsp_shift[i]))

    for T in 1:par.stages
        if mod(T,24) == 0
            JuMP.@constraint(m, [t = T,i=par.set_dem_rsp], total_load[t,i] == sum(par.demand[i][1:t]))
        end
    end
end

function add_deterministic_objective!(m, par)
    par.flag_debug && print("> objective:")

    # --- initialize expression
    expr = JuMP.AffExpr(0.0)
    
    set_objective_thermal!(m, par, expr)
    set_objective_deficit!(m, par, expr)
    set_objective_curtailment!(m, par, expr)
    set_objective_import!(m, par, expr)
    set_objective_export!(m, par, expr)

    # Define the objective for each stage `t`. Note that we can use `t` as an
    # index for t = 1, 2, ..., 24    
    JuMP.@objective(m, Min, expr)
end

function add_deterministic_renewable_capacity_constraints!(m, par)
    par.flag_debug && println("> constraints: renewable operation")

    gen_sol, gen_sol_max = m[:gen_sol], m[:gen_sol_max]

    # --- solar capacity constraint
    JuMP.@constraint(m, sol_cap_max[t=1:par.stages,i=1:par.nsol], gen_sol[t,i] <= gen_sol_max[t,i])   
end

function add_deterministic_renewable_generation!(m, par)
    par.flag_debug && println("> constraints: renewable scenario")

    gen_sol_max = m[:gen_sol_max]

    # Parameterize the subproblem.
    for t = 1:par.stages, i = 1:par.nsol
        JuMP.fix(gen_sol_max[t,i], mean(par.sol_scn[t,:,i]))
    end
end

function build_deterministic_model(par)

    m = JuMP.Model(par.optimizer)

    JuMP.set_silent(m)

    add_deterministic_variables_model!(m, par)

    add_deterministic_network_constraints!(m, par)

    add_deterministic_generation_constraints!(m, par)
    
    par.flag_bat && add_deterministic_battery_constraints!(m, par)

    add_deterministic_renewable_capacity_constraints!(m, par)

    add_deterministic_renewable_generation!(m, par)
    
    par.flag_dem_rsp && add_deterministic_demand_response_constraints!(m, par)
    
    par.flag_import && add_deterministic_import_constraints!(m, par)
    
    par.flag_export && add_deterministic_export_constraints!(m, par)
    
    add_deterministic_energy_balance_constraints!(m, par)
    
    add_deterministic_objective!(m, par)
 
    return m
end

function run_deterministic_model!(m, par)
    return JuMP.optimize!(m)
end