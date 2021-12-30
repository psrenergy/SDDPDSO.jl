function get_objective_thermal(m, par)
    brick = 0.0
    if par.ngen > 0
        par.flag_verbose && println("> objective: thermal")
        brick = sum(m[:gen_die][t,i] * par.gen_cost[i] for t in 1:par.stages for i in 1:par.ngen)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_deficit(m, par)
    brick = 0.0
    if true # should add flag here?
        par.flag_verbose && println("> objective: deficit")
        brick = sum(m[:def][t,i] .* par.def_cost for t in 1:par.stages for i in 1:par.nload)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_curtailment(m, par)
    brick = 0.0
    if true # should add flag here?
        par.flag_verbose && println("> objective: curtailment")
        brick = sum(m[:cur][t,i] .* par.def_cost .* 1.01 for t in 1:par.stages for i in 1:par.nbus)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_demand_response_deficit(m, par)
    brick = 0.0
    if par.flag_dem_rsp
        par.flag_verbose && println("> objective: demand response deficit")
        brick = sum(m[:dr_def][t,i] .* par.def_cost .* 1.02 for t in 1:par.stages for i in 1:par.nload)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_demand_response_curtailment(m, par)
    brick = 0.0
    if par.flag_dem_rsp
        par.flag_verbose && println("> objective: demand response curtailment")
        brick = sum(m[:dr_cur][t,i] .* par.def_cost .* 1.03 for t in 1:par.stages for i in 1:par.nload)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_import(m, par)
    brick = 0.0
    if par.flag_import
        par.flag_verbose && println("> objective: grid import")
        brick = sum(m[:imp][t,i] * sum(par.imp_cost[j][t,1] for j in par.bus_map_imp[i]) for i in keys(par.bus_map_imp) for t in 1:par.stages)
        par.flag_debug && begin @show brick end
    end
    return brick
end

function get_objective_export(m, par)
    brick = 0.0
    if par.flag_export
        par.flag_verbose && println("> objective: grid export")
        brick = sum(m[:exp][t,i] * sum(par.exp_cost[j][t,1] for j in par.bus_map_exp[i]) for i in keys(par.bus_map_exp) for t in 1:par.stages)
        par.flag_debug && begin @show brick end
    end
    return brick
end

