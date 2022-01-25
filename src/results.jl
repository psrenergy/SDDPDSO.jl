function export_results(x, n, d, par, sims, m)
    
    D_Matrix = TransformaDemandaMatriz(par.bus_map_dem,par.demand,n.bus,par.stages)
    export_3D_Matrix_as_graf(x,D_Matrix, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_original_demand", d.bus_name)

    if n.cir > 0
        CSV.write(
            joinpath(x.PATH,"results","cirflw.csv"),
            simulate_create_result_table(sims,:flw,d.cir_name)
        )

        export_as_graf(x, sims, :flw, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_cirflw", d.cir_name)

        CSV.write(
            joinpath(x.PATH,"results","usecir.csv"),
            export_result_usecir(sims,d.cir_capacity,d.cir_name)
        )
        export_result_usecir_as_graf(x, n, sims, d.cir_capacity, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_cir_use", d.cir_name)

    end

    if n.ther > 0
        CSV.write(
            joinpath(x.PATH,"results","thermal_generation.csv"),
            simulate_create_result_table(sims,:gen_die,d.ter_name)
        )
        export_as_graf(x, sims, :gen_die, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_thermal_generation", d.ter_name)
        export_gen_die_use_as_graf(x, sims, par.gen_cap, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_thermal_use", d.ter_name)
        export_results_cost_as_graf(x, sims,:gen_die, par.gen_cost, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_thermal_gen_cost", d.ter_name)
    end

    if n.gnd > 0
        CSV.write(
            joinpath(x.PATH,"results","renewable_generation.csv"),
            simulate_create_result_table(sims,:gen_sol,d.gnd_name)
        )
        export_as_graf(x, sims, :gen_sol, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_renewable_generation", d.gnd_name)

        CSV.write(
            joinpath(x.PATH,"results","renewable_curtailment.csv"),
            simulate_create_result_dif_table(sims,:gen_sol_max,:gen_sol,d.gnd_name)
        )
        export_dif_as_graf(x, sims, :gen_sol_max,:gen_sol, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_renewable_curtailment", d.gnd_name)
 
    end

    CSV.write(
        joinpath(x.PATH,"results","load_deficit.csv"),
        simulate_create_result_table(sims,:def,["def$i" for i in 1:n.load])
    )
    export_as_graf(x, sims, :def, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_load_deficit", ["def$i" for i in 1:n.load])

    CSV.write(
        joinpath(x.PATH,"results","bus_curtailment.csv"),
        simulate_create_result_table(sims,:cur,["cur$i" for i in 1:n.bus])
    )
    export_as_graf(x, sims, :cur, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_bus_curtailment", ["cur$i" for i in 1:n.bus])

    if n.bat > 0 && (par.flag_bat)
        CSV.write(
            joinpath(x.PATH,"results","battery_discharge.csv"),
            simulate_create_result_table(sims,:bat_d,d.bat_name)
        )
        export_as_graf(x, sims, :bat_d, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_battery_discharge", d.bat_name)

        CSV.write(
            joinpath(x.PATH,"results","battery_charge.csv"),
            simulate_create_result_table(sims,:bat_c,d.bat_name)
        )
        export_as_graf(x, sims, :bat_c, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_battery_charge", d.bat_name)

        CSV.write(
            joinpath(x.PATH,"results","battery_storage.csv"),
            simulate_create_result_table_state_var(sims,:storage,d.bat_name)
        )
        export_StateVar_as_graf(x, sims, :storage, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_battery_storage", d.bat_name)
    end

    if par.flag_dem_rsp
        Upper_DR = TransformaDemandaMatriz_UpperRD(par.bus_map_dem,par.demand,n.bus,par.stages,par.set_dem_rsp,par.dem_rsp_shift)
        export_3D_Matrix_as_graf(x,Upper_DR, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_dr_upper_bound", d.bus_name)
    
        Lower_DR = TransformaDemandaMatriz_LowerRD(par.bus_map_dem,par.demand,n.bus,par.stages,par.set_dem_rsp,par.dem_rsp_shift)
        export_3D_Matrix_as_graf(x,Lower_DR, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_dr_lower_bound", d.bus_name)
    
        CSV.write(
            joinpath(x.PATH,"results","dr_accumulated_load.csv"),
            simulate_create_result_table_state_var(sims,:total_load,d.load_name[par.set_dem_rsp])
        )
        export_StateVar_as_graf(x, sims, :total_load, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_dr_accumulated_load", d.load_name[par.set_dem_rsp])

        CSV.write(
            joinpath(x.PATH,"results","dr_load.csv"),
            simulate_create_result_table(sims,:dr,d.load_name[par.set_dem_rsp])
        )
        export_as_graf_convertingArray(x, sims, :dr, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_dr_load", d.load_name[par.set_dem_rsp])
        
        CSV.write(
            joinpath(x.PATH,"results","dr_deficit.csv"),
            simulate_create_result_table(sims,:dr_def,d.load_name[par.set_dem_rsp])
        )
        export_as_graf_convertingArray(x, sims, :dr_def, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_dr_deficit", d.load_name[par.set_dem_rsp])

        CSV.write(
            joinpath(x.PATH,"results","dr_curtailment.csv"),
            simulate_create_result_table(sims,:dr_cur,d.load_name[par.set_dem_rsp])
        )
        export_as_graf_convertingArray(x, sims, :dr_cur, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_dr_curtailment", d.load_name[par.set_dem_rsp])
    end

    #Marginal cost export 
    # export_as_graf(x, sims, :shadow_price, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_bus_marginal_cost", d.bus_name)
    export_weighted_shadow_price_as_graf(x, sims, D_Matrix, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_bus_marginal_cost", ["Bus Marginal Cost"])

    if par.flag_import
        CSV.write(
            joinpath(x.PATH,"results","energy_import.csv"),
            simulate_create_result_table(sims,:imp,d.bus_name)
        )
        export_as_graf(x, sims, :imp, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_import", d.bus_name)

        CSV.write(
            joinpath(x.PATH,"results","energy_import_capacity.csv"),
            simulate_create_result_table(sims,:imp_max,d.bus_name)
        )
        export_as_graf(x, sims, :imp_max, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_import_capacity", d.bus_name)
        export_imp_exp_cost_as_graf(x, sims, :imp, par.imp_cost, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_import_cost", d.bus_name)
        export_imp_exp_use_as_graf(x, sims, :imp, par.imp_max, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_import_use", d.bus_name)
    end

    if par.flag_export
        CSV.write(
            joinpath(x.PATH,"results","energy_export.csv"),
            simulate_create_result_table(sims,:exp,d.bus_name)
        )
        export_as_graf(x, sims, :exp, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_export", d.bus_name)
        CSV.write(
            joinpath(x.PATH,"results","energy_export_capacity.csv"),
            simulate_create_result_table(sims,:exp_max,d.bus_name)
        )
        export_as_graf(x, sims, :exp_max, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_export_capacity", d.bus_name)
        export_imp_exp_cost_as_graf(x, sims, :exp, par.exp_cost, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_export_cost", d.bus_name)
        export_imp_exp_use_as_graf(x, sims, :exp, par.exp_max, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_energy_export_use", d.bus_name)

    end

    CSV.write(
        joinpath(x.PATH,"results","stage_objective_function.csv"),
        simulate_create_result_table(sims,:stage_objective,["stage_objective_function"])
    )
    export_stage_objective_as_graf(x, sims, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_stage_objective_function", ["stage_objective_function"])

    if par.flag_bat || par.flag_dem_rsp
        convergence_table = calculate_convergence_table(x,m);
        export_conv_table_as_graf(x, convergence_table, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_convergence_data", ["Simulation Value", "Lower Bound", "Difference (%)"]);                                  
    end
    
    #losses
    if par.flag_losses
        export_losses_as_graf(x, par, joinpath(x.PATH,"results"),CSV = par.flag_CSV, "DSO_stage_average_losses", ["stage_average_losses (%)"])
    end

end

function simulate_create_result_table(sims,result,header,nscn=length(sims),nstg=length(sims[1]))

    d = Dict(name => [] for name in Symbol.(header))
    t = Int64[]
    s = Int64[]

    for scn in 1:nscn, stg in 1:nstg
        push!(s,scn)
        push!(t,stg)
        i=0
        for v in sims[scn][stg][result]
            i+=1
            push!(d[Symbol(header[i])], v)
        end
    end

    r = DataFrame(scenario = s, stage = t)

    for name in Symbol.(header)
        r[!,name] = d[name]
    end

    return r
end

function simulate_create_result_table_state_var(sims,result,header,nscn=length(sims),nstg=length(sims[1]))

    d = Dict(name => [] for name in Symbol.([header.*"_in";header.*"_out"]))
    t = Int64[]
    s = Int64[]

    for scn in 1:nscn, stg in 1:nstg
        push!(s,scn)
        push!(t,stg)
        i=0
        for v in sims[scn][stg][result]
            i+=1
            push!(d[Symbol(header[i]*"_in" )], v.in)
            push!(d[Symbol(header[i]*"_out")], v.out)
        end
    end

    r = DataFrame(scenario = s, stage = t)

    for name in Symbol.([header.*"_in";header.*"_out"])
        r[!,name] = d[name]
    end

    return r
end

function simulate_create_result_dif_table(sims,result_ref,result_dif,header,nscn=length(sims),nstg=length(sims[1]))

    d = Dict(name => [] for name in Symbol.(header))
    t = Int64[]
    s = Int64[]

    for scn in 1:nscn, stg in 1:nstg
        push!(s,scn)
        push!(t,stg)
        i=0

        v_ref = Float64[]

        for v in sims[scn][stg][result_ref]
            push!(v_ref, v)
        end

        for v in sims[scn][stg][result_dif]
            i+=1
            push!(d[Symbol(header[i])], v_ref[i] - v)
        end
    end

    r = DataFrame(scenario = s, stage = t)

    for name in Symbol.(header)
        r[!,name] = d[name]
    end

    return r
end

