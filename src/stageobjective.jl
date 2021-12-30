function get_stageobjective_thermal(m, par, t)
    brick = 0.0
    if par.ngen > 0
        par.flag_verbose && print("> stage objective ($t): thermal")
        brick = sum(m[:gen_die][i] * par.gen_cost[i] for i in 1:par.ngen)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_stageobjective_deficit(m, par, t)
    brick = 0.0
    if true # should add flag here?
        par.flag_verbose && print("> stage objective ($t): deficit")
        brick = sum(m[:def] .* par.def_cost)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_stageobjective_curtailment(m, par, t)
    brick = 0.0
    if true # should add flag here?
        par.flag_verbose && print("> stage objective ($t): curtailment")
        brick = sum(m[:cur] .* par.def_cost .* 1.01)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_stageobjective_demand_response_deficit(m, par, t)
    brick = 0.0
    if par.flag_dem_rsp
        par.flag_verbose && print("> stage objective ($t): demand response deficit")
        brick = sum(m[:dr_def] .* par.def_cost .* 1.02)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_stageobjective_demand_response_curtailment(m, par, t)
    brick = 0.0
    if par.flag_dem_rsp
        par.flag_verbose && print("> stage objective ($t): demand response curtailment")
        brick = sum(m[:dr_cur] .* par.def_cost .* 1.03)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_stageobjective_import(m, par, t)
    brick = 0.0
    if par.flag_import
        par.flag_verbose && print("> stage objective ($t): grid import")
        brick = sum(m[:imp][i] * sum(par.imp_cost[j][t,1] for j in par.bus_map_imp[i]) for i in keys(par.bus_map_imp))
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_stageobjective_export(m, par, t)
    brick = 0.0
    if par.flag_export
        par.flag_verbose && print("> stage objective ($t): grid export")
        brick = sum(m[:exp][i] * sum(par.exp_cost[j][t,1] for j in par.bus_map_exp[i]) for i in keys(par.bus_map_exp))
        par.flag_debug && begin @show brick end
    end
    return brick
end

