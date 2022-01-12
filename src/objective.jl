function set_objective_thermal!(m, par, expr)
   
    if par.ngen > 0
        par.flag_debug && print(" + thermal")

        for t in 1:par.stages, i in 1:par.ngen
            JuMP.add_to_expression!(expr, par.gen_cost[i], m[:gen_die][t,i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_objective_deficit!(m, par, expr)
    if true # should add flag here?
        par.flag_debug && print(" + deficit")

        for t in 1:par.stages, i in 1:par.nload
            JuMP.add_to_expression!(expr, par.def_cost, m[:def][t,i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_objective_curtailment!(m, par, expr)
    if true # should add flag here?
        par.flag_debug && print(" + curtailment")

        for t in 1:par.stages, i in 1:par.nbus
            JuMP.add_to_expression!(expr, par.def_cost * 1.01, m[:cur][t,i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_objective_import!(m, par, expr)
    if par.flag_import
        par.flag_debug && print(" + grid import")

        for t in 1:par.stages, i in keys(par.bus_map_imp)
            cst = sum(par.imp_cost[j][t,1] for j in par.bus_map_imp[i])
            
            JuMP.add_to_expression!(expr, cst, m[:imp][t,i])
        end

        # par.flag_debug && begin @show brick end
    end
end

function set_objective_export!(m, par, expr)
    if par.flag_export
        par.flag_debug && print(" - grid export")

        for t in 1:par.stages, i in keys(par.bus_map_exp)
            cst = sum(par.exp_cost[j][t,1] for j in par.bus_map_exp[i])
            
            JuMP.add_to_expression!(expr, -cst, m[:exp][t,i])
        end

        # par.flag_debug && begin @show brick end
    end
end

