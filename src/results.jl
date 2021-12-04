function export_results(x, n, d, par, sims)
    
    if n.cir > 0
        CSV.write(
            joinpath(x.PATH,"results","cirflw.csv"),
            simulate_create_result_table(sims,:flw,d.cir_name)
        )

        # CSV.write(
        #     joinpath(x.PATH,"results","usecir.csv"),
        #     export_result_usecir(sims,d.cir_capacity,d.cir_name)
        # )
    end

    if n.ther > 0
        CSV.write(
            joinpath(x.PATH,"results","diesel_generation.csv"),
            simulate_create_result_table(sims,:gen_die,d.ter_name)
        )
    end

    if n.gnd > 0
        CSV.write(
            joinpath(x.PATH,"results","renewable_generation.csv"),
            simulate_create_result_table(sims,:gen_sol,d.gnd_name)
        )

        CSV.write(
            joinpath(x.PATH,"results","renewable_curtailment.csv"),
            simulate_create_result_dif_table(sims,:gen_sol_max,:gen_sol,d.gnd_name)
        )
    end

    CSV.write(
        joinpath(x.PATH,"results","load_deficit.csv"),
        simulate_create_result_table(sims,:def,["def$i" for i in 1:n.load])
    )

    CSV.write(
        joinpath(x.PATH,"results","bus_curtailment.csv"),
        simulate_create_result_table(sims,:cur,["cur$i" for i in 1:n.bus])
    )

    if n.bat > 0
        CSV.write(
            joinpath(x.PATH,"results","battery_discharge.csv"),
            simulate_create_result_table(sims,:bat_d,d.bat_name)
        )

        CSV.write(
            joinpath(x.PATH,"results","battery_charge.csv"),
            simulate_create_result_table(sims,:bat_c,d.bat_name)
        )

        CSV.write(
            joinpath(x.PATH,"results","battery_storage.csv"),
            simulate_create_result_table_state_var(sims,:storage,d.bat_name)
        )
    end

    if x.flag_dem_rsp == 1
        CSV.write(
            joinpath(x.PATH,"results","demand_response_accumulated_load.csv"),
            simulate_create_result_table_state_var(sims,:total_load,d.load_name[par.set_dem_rsp])
        )

        CSV.write(
            joinpath(x.PATH,"results","demand_response_load.csv"),
            simulate_create_result_table(sims,:dr,d.load_name[par.set_dem_rsp])
        )

        CSV.write(
            joinpath(x.PATH,"results","demand_response_deficit.csv"),
            simulate_create_result_table(sims,:dr_def,d.load_name[par.set_dem_rsp])
        )

        CSV.write(
            joinpath(x.PATH,"results","demand_response_curtailment.csv"),
            simulate_create_result_table(sims,:dr_cur,d.load_name[par.set_dem_rsp])
        )
    end

    if x.flag_import == 1
        CSV.write(
            joinpath(x.PATH,"results","energy_import.csv"),
            simulate_create_result_table(sims,:imp,d.bus_name)
        )

        CSV.write(
            joinpath(x.PATH,"results","energy_import_capacity.csv"),
            simulate_create_result_table(sims,:imp_max,d.bus_name)
        )
    end

    if x.flag_export == 1
        CSV.write(
            joinpath(x.PATH,"results","energy_export.csv"),
            simulate_create_result_table(sims,:exp,d.bus_name)
        )

        CSV.write(
            joinpath(x.PATH,"results","energy_export_capacity.csv"),
            simulate_create_result_table(sims,:exp_max,d.bus_name)
        )
    end

    CSV.write(
        joinpath(x.PATH,"results","stage_objective_function_0.csv"),
        simulate_create_result_table(sims,:stage_objective,["stage_objective_function"])
    )
    
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

function export_as_graf(x, results_sim, result_name, filepath, filename, AGENTS; UNIT::String="", CSV=false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_as_graf(results_sim, result_name, filepath, filename, x.NSTG, x.NSCN, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_as_graf(results_sim, result_name, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV=false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

    FILE_NAME = joinpath(filepath, filename)

    # --- open graf file
    graf = PSRClassesInterface.open(
        CSV ? PSRClassesInterface.OpenCSV.Writer : PSRClassesInterface.OpenBinary.Writer ,
        
        FILE_NAME              ,
        
        is_hourly = true       ,
        
        scenarios = SCENARIOS  ,
        stages    = STAGES     ,
        agents    = AGENTS     ,
        unit      = UNIT       ,
        # optional:
        initial_stage = INITIAL_STAGE,
        initial_year = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS                
            PSRClassesInterface.write_registry(graf, results_sim[s][t][result_name], t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end