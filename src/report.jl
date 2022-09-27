"""
    reports
"""
function reports(x, n, d, par, list::Vector{String}=String[])
    report_avg_load_per_bus(x, n, d, par)
    report_gnd_gen_per_bus(x, n, d, par)
    report_ter_att_per_bus(x, n, d, par)

    return 
end

"""
    report_avg_load_per_bus
"""
function report_avg_load_per_bus(x, n, d, par)

    report_lines = String[]

    push!(report_lines, "bus_name,bus_code,load_code,load_name,load_avg")

    for i in 1:par.nbus
        if haskey(par.bus_map_dem, i)
            agt_name = d.bus_name[i]
            agt_code = d.bus_code[i]
            agt_nref = length(par.bus_map_dem[i])

            for j in 1:agt_nref
                agt_ref_code = d.load_code[par.bus_map_dem[i][j]]
                agt_ref_name = d.load_name[par.bus_map_dem[i][j]]
                agt_ref_avg  = mean(par.demand[par.bus_map_dem[i][j]])

                push!(report_lines, agt_name * ",$agt_code," * agt_ref_name * ",$agt_ref_code,$agt_ref_avg")
            end
        end
    end

    export_file(joinpath(x.PATH,"reports"), "report_load_attributes.csv", report_lines)

    return report_lines
end

"""
    report_gnd_gen_per_bus
"""
function report_gnd_gen_per_bus(x, n, d, par)

    report_lines = String[]

    push!(report_lines, "bus_name,bus_code,gnd_code,gnd_name,gnd_avg")

    for i in 1:par.nbus
        if haskey(par.bus_map_sol, i)
            agt_name = d.bus_name[i]
            agt_code = d.bus_code[i]
            agt_nref = length(par.bus_map_sol[i])

            for j in 1:agt_nref
                agt_ref_code = d.gnd_code[par.bus_map_sol[i][j]]
                agt_ref_name = d.gnd_name[par.bus_map_sol[i][j]]
                agt_ref_avg  = mean(par.ren_scn[:,:,par.bus_map_sol[i][j]])

                push!(report_lines, agt_name * ",$agt_code," * agt_ref_name * ",$agt_ref_code,$agt_ref_avg")
            end
        end
    end

    export_file(joinpath(x.PATH,"reports"), "report_renewable_attributes.csv", report_lines)

    return report_lines
end

"""
    report_gnd_gen_per_bus
"""
function report_ter_att_per_bus(x, n, d, par)

    report_lines = String[]

    push!(report_lines, "bus_name,bus_code,ter_code,ter_name,ter_cap,ter_cst")

    for i in 1:par.nbus
        if haskey(par.bus_map_ter, i)
            agt_name = d.bus_name[i]
            agt_code = d.bus_code[i]
            agt_nref = length(par.bus_map_ter[i])

            for j in 1:agt_nref
                agt_ref_code = d.ter_code[par.bus_map_ter[i][j]]
                agt_ref_name = d.ter_name[par.bus_map_ter[i][j]]
                agt_ref_cap  = d.ter_capacity[par.bus_map_ter[i][j]]
                agt_ref_cst  = d.ter_cost[par.bus_map_ter[i][j]]

                push!(report_lines, agt_name * ",$agt_code," * agt_ref_name * ",$agt_ref_code,$agt_ref_cap,$agt_ref_cst")
            end
        end
    end

    export_file(joinpath(x.PATH,"reports"), "report_thermal_attributes.csv", report_lines)

    return report_lines
end