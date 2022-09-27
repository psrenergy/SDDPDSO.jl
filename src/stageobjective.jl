function set_stageobjective_thermal!(m, par, expr)
    if par.nter > 0
        par.flag_debug && print(" + thermal")

        for i in 1:par.nter
            JuMP.add_to_expression!(expr, par.ter_cost[i], m[:gen_die][i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_stageobjective_deficit!(m, par, expr)
    if true # should add flag here?
        par.flag_debug && print(" + deficit")

        for i in 1:par.nload
            JuMP.add_to_expression!(expr, par.def_cost, m[:def][i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_stageobjective_curtailment!(m, par, expr)
    if true # should add flag here?
        par.flag_debug && print(" + curtailment")

        for i in 1:par.nbus
            JuMP.add_to_expression!(expr, par.def_cost * 1.01, m[:cur][i])
        end

        brick = sum(m[:cur] .* par.def_cost .* 1.01)
        par.flag_debug && begin @show brick end
    end
end

function set_stageobjective_demand_response_deficit!(m, par, expr)
    if par.flag_dem_rsp
        par.flag_debug && print(" + demand response deficit")

        for i in par.set_dem_rsp
            JuMP.add_to_expression!(expr, par.def_cost * 1.02, m[:dr_def][i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_stageobjective_demand_response_curtailment!(m, par, expr)
    if par.flag_dem_rsp
        par.flag_debug && print(" + demand response curtailment")

        for i in par.set_dem_rsp
            JuMP.add_to_expression!(expr, par.def_cost * 1.03, m[:dr_cur][i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_stageobjective_import!(m, par, expr, t)
    if par.flag_import
        par.flag_debug && print(" + grid import")

        for i in keys(par.bus_map_imp)
            cst = sum(par.imp_cost[j][t,1] for j in par.bus_map_imp[i])
            
            JuMP.add_to_expression!(expr, cst, m[:imp][i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_stageobjective_export!(m, par, expr, t)
    if par.flag_export
        par.flag_debug && print(" - grid export")

        for i in keys(par.bus_map_exp)
            cst = sum(par.exp_cost[j][t,1] for j in par.bus_map_exp[i])
            
            JuMP.add_to_expression!(expr, -cst, m[:exp][i])
        end

        # par.flag_debug && begin @show brick end
    end
end

