function get_objective_thermal(m, par, t)
    brick = 0.0
    if par.ngen > 0
        par.flag_verbose && print("> stage objective ($t): thermal")
        brick = sum(m[:gen_die][i] * par.gen_cost[i] for i in 1:par.ngen)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_deficit(m, par, t)
    brick = 0.0
    if true # should add flag here?
        par.flag_verbose && print("> stage objective ($t): deficit")
        brick = sum(m[:def] .* par.def_cost)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_curtailment(m, par, t)
    brick = 0.0
    if true # should add flag here?
        par.flag_verbose && print("> stage objective ($t): curtailment")
        brick = sum(m[:cur] .* par.def_cost .* 1.01)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_demand_response_deficit(m, par, t)
    brick = 0.0
    if par.flag_dem_rsp
        par.flag_verbose && print("> stage objective ($t): demand response deficit")
        brick = sum(m[:dr_def] .* par.def_cost .* 1.02)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_demand_response_curtailment(m, par, t)
    brick = 0.0
    if par.flag_dem_rsp
        par.flag_verbose && print("> stage objective ($t): demand response curtailment")
        brick = sum(m[:dr_cur] .* par.def_cost .* 1.03)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_import(m, par, t)
    brick = 0.0
    if par.flag_import
        par.flag_verbose && print("> stage objective ($t): grid import")
        brick = sum(m[:imp][i] * par.imp_cost[i][t,1] for i in 1:par.nbus if haskey(par.bus_map_imp, i))
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_export(m, par, t)
    brick = 0.0
    if par.flag_import
        par.flag_verbose && print("> stage objective ($t): grid export")
        brick = sum(m[:exp][i] * par.exp_cost[i][t,1] for i in 1:par.nbus if haskey(par.bus_map_exp, i))
        par.flag_debug && begin @show brick end
    end
    return brick
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