"""
    import_csvfile
"""
function import_csvfile(path::String, name::String)
    filepath = joinpath(path,name)

    csvfile = isfile(filepath) ? CSV.read(filepath, DataFrame) : error("could not find "*filepath)

    return csvfile
end

"""
    import_file(path::String, name::String)

readlines from file on path.
"""
function import_file(path::String, name::String)
    iopath = joinpath(path , name )
    iofile = isfile(iopath) ? open( iopath , "r" ) : error("Coud not read "*iopath)
    iodata = readlines(iofile)
    close(iofile)
    return iodata
end

"""
    export_file
"""
function export_file(filepath::String, filename::String, lines::Array{String}, append::Bool=false)
    outfile = open(joinpath(filepath,filename), append ? "a" : "w+")

    for line in lines
        write(outfile, line*"\n")
    end
    
    close(outfile)
end

"""
    export_file
"""
function export_file(filepath::String, filename::String, lines::String, append::Bool=false)
    return export_file(filepath, filename, String[lines], append)
end


"""
    read_database
"""
function read_database(casepath::String, filepath::String="psrclasses.json"; summarize::Bool=false)

    # --- check file
    !isfile(joinpath(casepath, filepath)) && error("unable to find "*filepath)

    # --- import database from json
    data = PSRI.initialize_study(
        PSRClassesInterface.OpenInterface(),
        data_path = casepath
    );

    # --- list all elements
    summarize && list_all_max_elements(data);

    return data
end

"""
    import_dso_hrload
"""
function import_dso_hrload(x::Execution, d::Data)
    
    # --- read external hourly scenarios cost data
    hrload = import_csvfile(x.PATH,"dso_hrload.dat")
    
    hrload_scn = Dict(code => zeros(Float64, x.stages) for code in d.load_code)

    valid_load_codes = [code for code in d.load_code if hasproperty(hrload,"$code")]
    
    for i in 1:size(hrload,1)

        hrload_i = hrload[i,:]

        stg = hrload_i.stage

        (stg > x.stages) && continue
        
        for code in valid_load_codes
            hrload_scn[code][stg] = x.demand_factor * hrload_i["$code"]
        end
    end

    return hrload_scn
end


"""
    import_renewable_generation_scenarios
"""
function import_renewable_generation_scenarios(x::Execution, d::Data)
    
    # --- read external hourly scenarios cost data
    hrgnd = import_csvfile(x.PATH,"dso_hrgnd_scn.dat")
    
    hrgnd_scn = Dict(code => zeros(Float64, x.stages, x.scenarios) for code in d.gnd_code) #d.bus_code[d.bus2gnd])

    # CHANGE TO LOAD CODES
    valid_load_codes = [code for code in d.gnd_code if hasproperty(hrgnd,"$code")] #d.bus_code[d.bus2gnd]
    
    for i in 1:size(hrgnd,1)

        hrgnd_i = hrgnd[i,:]

        stg = hrgnd_i.stage
        scn = hrgnd_i.scenario

        if (stg > x.stages) | (scn > x.scenarios)
            continue
        end

        for code in valid_load_codes
            hrgnd_scn[code][stg, scn] = hrgnd_i["$code"]
        end
    end

    return hrgnd_scn
end

"""
    import_demand_response_shift
"""
function import_demand_response_shift(x::Execution, d::Data)
    
    # --- read external hourly scenarios cost data
    dr_shift = import_csvfile(x.PATH,"dso_dr_shift.dat")[1,:]
    
    # dr_shift_scn = Dict(code => 0.0 for code in d.bus_code[d.lod2bus])
    dr_shift_scn = Dict(code => 0.0 for code in d.load_code)

    # CHANGE TO LOAD CODES
    valid_load_codes = [code for code in d.load_code if hasproperty(dr_shift,"$code")]
    # valid_load_codes = [code for code in d.bus_code[d.lod2bus] if hasproperty(dr_shift,"$code")]
    
    for code in valid_load_codes
        dr_shift_scn[code] = dr_shift["$code"]
    end
    
    return dr_shift_scn
end

"""
    import_injections
"""
function import_injections(x::Execution, d::Data, is_export::Bool)

    name     = is_export ? "imp"    : "exp"
    fullname = is_export ? "import" : "export"

    # --- read external hourly cost data
    inj_cap = import_csvfile(x.PATH,"dso_hrcp_" * name * ".dat")
    inj_cst = import_csvfile(x.PATH,"dso_hrct_" * name * ".dat")

    # --- by-pass user input error
    valid_codes_cap = [code for code in d.bus_code if hasproperty(inj_cap,"$code")]
    valid_codes_cst = [code for code in d.bus_code if hasproperty(inj_cap,"$code")]
    valid_codes     = intersect(valid_codes_cap, valid_codes_cst)

    # error check 1
    if (length(valid_codes_cap) != length(valid_codes_cst))
        error(fullname * "capacity and costs are not compatible, please verify input data")
    end

    # error check 2
    if (length(valid_codes) != length(valid_codes_cst)) | (length(valid_codes) != length(valid_codes_cap))
        error(fullname * " capacity and costs are not compatible, please verify input data")
    end

    # ---
    capacity = Dict(code => zeros(Float64, x.stages, 1) for code in valid_codes)
    cost     = Dict(code => zeros(Float64, x.stages, 1) for code in valid_codes)


    for i in 1:size(inj_cap,1)

        # get row data
        cap, cst = inj_cap[i,:], inj_cst[i,:]

        stg, scn = cap.stage, cap.scenario

        if (stg > x.stages) | (scn > 1)
            continue
        end

        for code in valid_codes
            capacity[code][stg, 1] = cap["$code"]
            cost[code][stg, 1]     = cst["$code"]
        end
    end

    return capacity, cost
end

"""
    import_dso_markov_probabilities
"""
function import_dso_markov_probabilities(x::Execution)
    
    # --- read 
    prob = import_csvfile(x.PATH,"dso_markov_probabilities.dat")
    
    nrow, ncol = size(prob)

    markov_prob = zeros(x.stages, x.scenarios, x.flag_markov_states)

    for i in 1:nrow
        state = 0
        for j in 3:ncol
            stage     = prob.stage[i]
            scenario  = prob.scenario[i]
            state    += 1

            markov_prob[stage, scenario, state] = prob[i,j]
        end
    end

    return markov_prob
end

function import_dso_markov_transitions(x::Execution)
    
    # --- read 
    tran = import_csvfile(x.PATH,"dso_markov_transition.dat")

    nrow, ncol = size(tran)
    
    markov_trans = zeros(x.stages, x.flag_markov_states, x.flag_markov_states)

    for i in 1:nrow
        state_to = 0
        for j in 3:ncol
            stage       = tran.stage[i]
            state_from  = tran.state[i]
            state_to    += 1

            markov_trans[stage, state_from, state_to] = tran[i,j]
        end
    end

    markov_trans_reshape = Array{Float64,2}[]
    
    # --- initial stage (state 1 only)
    push!(markov_trans_reshape,[1.0]')

    # --- second stage (state 1 to 1/n)
    push!(markov_trans_reshape, reshape(markov_trans[2,1,:],1,2))

    # --- following stages (state n to 1/n)
    for stage in 3:x.stages
        push!(markov_trans_reshape,markov_trans[stage,:,:])
    end

    return markov_trans_reshape
end

function export_as_graf(x, results_sim, result_name, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_as_graf(results_sim, result_name, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_as_graf(results_sim, result_name, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
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

function export_dif_as_graf(x, results_sim, result_name1, result_name2, filepath, filename, AGENTS; UNIT::String="", CSV=false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_dif_as_graf(results_sim, result_name1, result_name2, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_dif_as_graf(results_sim, result_name1,result_name2, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV=false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS                
            PSRClassesInterface.write_registry(graf, results_sim[s][t][result_name1]-results_sim[s][t][result_name2], t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_StateVar_as_graf(x, results_sim, result_name, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_StateVar_as_graf(results_sim, result_name, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_StateVar_as_graf(results_sim, result_name, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

    FILE_NAME = joinpath(filepath, filename)

    # StateVar_AGENTS = String[]
    # for a in AGENTS
    #     push!(StateVar_AGENTS,String(Symbol(a.*"_in")))
    #     # push!(StateVar_AGENTS,String(Symbol(a.*"_out")))
    # end

    # --- open graf file
    graf = PSRClassesInterface.open(
        CSV ? PSRClassesInterface.OpenCSV.Writer : PSRClassesInterface.OpenBinary.Writer ,
        
        FILE_NAME              ,
        
        is_hourly = true       ,
        
        scenarios = SCENARIOS           ,
        stages    = STAGES              ,
        agents    = AGENTS              ,
        unit      = UNIT                ,
        # optional:
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS      
            aux = Float64[]
            for v in results_sim[s][t][result_name]
                push!(aux,v.in)
                # push!(aux,v.out)
            end
            PSRClassesInterface.write_registry(graf, aux, t, s,  1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_as_graf_convertingArray(x, results_sim, result_name, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_as_graf_convertingArray(results_sim, result_name, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_as_graf_convertingArray(results_sim, result_name, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS                
            len = length(results_sim[s][t][result_name])
            converted_results = Vector{Float64}(undef,len)
            for i in eachindex(results_sim[s][t][result_name])
                converted_results[i]= results_sim[s][t][result_name][i]
            end
            PSRClassesInterface.write_registry(graf, converted_results, t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_3D_Matrix_as_graf(x, D_Matrix, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_3D_Matrix_as_graf(D_Matrix, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_3D_Matrix_as_graf(D_Matrix, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS                
            results = D_Matrix[:,t,1]
            PSRClassesInterface.write_registry(graf, results, t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function TransformaDemandaMatriz(MapaDemanda,MatrizDemanda,qtd_buses,n_stages)
    Demand_Matrix=zeros(qtd_buses,n_stages,1)
    for bus in 1:qtd_buses, stg in 1:n_stages
        if haskey(MapaDemanda,bus)==true    

            mapa=MapaDemanda[bus][1]
            demanda=MatrizDemanda[mapa][stg]

            Demand_Matrix[bus,stg,1]=demanda
        else
            Demand_Matrix[bus,stg,1]=0
        end
    end
    return Demand_Matrix
end

function TransformaDemandaMatriz_UpperRD(MapaDemanda,MatrizDemanda,qtd_buses,n_stages,dem_rsp_buses,dem_rsp_shifts)
    Demand_Matrix=zeros(qtd_buses,n_stages,1)
    for bus in 1:qtd_buses, stg in 1:n_stages
        if haskey(MapaDemanda,bus)    
            mapa=MapaDemanda[bus][1]
            demanda=MatrizDemanda[mapa][stg]
            if mapa in dem_rsp_buses
                Demand_Matrix[bus,stg,1]=demanda*(1+dem_rsp_shifts[mapa])
            else
                Demand_Matrix[bus,stg,1]=demanda
            end
        else
            Demand_Matrix[bus,stg,1]=0
        end
    end
    return Demand_Matrix
end

function TransformaDemandaMatriz_LowerRD(MapaDemanda,MatrizDemanda,qtd_buses,n_stages,dem_rsp_buses,dem_rsp_shifts)
    Demand_Matrix=zeros(qtd_buses,n_stages,1)
    for bus in 1:qtd_buses, stg in 1:n_stages
        if haskey(MapaDemanda,bus)    
            mapa=MapaDemanda[bus][1]
            demanda=MatrizDemanda[mapa][stg]
            if mapa in dem_rsp_buses
                Demand_Matrix[bus,stg,1]=demanda*(1-dem_rsp_shifts[mapa])
            else
                Demand_Matrix[bus,stg,1]=demanda
            end
        else
            Demand_Matrix[bus,stg,1]=0
        end
    end
    return Demand_Matrix
end

function export_result_usecir(sims,cir_cap,header,nscn=length(sims),nstg=length(sims[1]))

    d = Dict(name => Float64[] for name in Symbol.(header))
    t = Int64[]
    s = Int64[]

    for scn in 1:nscn, stg in 1:nstg
        push!(s,scn)
        push!(t,stg)
        i=0

        cirflw = abs.(sims[scn][stg][:flw])

        usecir = (cirflw ./ cir_cap) .* 100

        for v in usecir                  
            i+=1
            push!(d[Symbol(header[i])], v == Inf ? 0.0 : v)
        end
    end

    r = DataFrame(scenario = s, stage = t)

    for name in Symbol.(header)
        r[!,name] = d[name]
    end

    return r
end

function export_result_usecir_as_graf(x, n, results_sim, cir_cap, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_result_usecir_as_graf(n, results_sim, cir_cap, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_result_usecir_as_graf(n, results_sim, cir_cap, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS         
            cirflw = abs.(results_sim[s][t][:flw])
            usecir = (cirflw ./ cir_cap) .* 100
            
            for i in 1:n.cir                  
                usecir[i] == Inf ? 0.0 : usecir[i]
            end
            PSRClassesInterface.write_registry(graf, usecir, t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_results_cost_as_graf(x, results_sim,result_name, results_cost, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_results_cost_as_graf(results_sim,result_name, results_cost, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end
 
function export_results_cost_as_graf(results_sim,result_name, results_cost, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS         
            results_calc_cost = results_sim[s][t][result_name].*results_cost
            PSRClassesInterface.write_registry(graf, results_calc_cost, t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_gen_die_use_as_graf(x, results_sim, die_cap, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_gen_die_use_as_graf(results_sim, die_cap, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_gen_die_use_as_graf(results_sim, die_cap, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS         
            die_use = (results_sim[s][t][:gen_die]./die_cap).*100
            PSRClassesInterface.write_registry(graf, die_use, t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end


function export_stage_objective_as_graf(x, results_sim, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_stage_objective_as_graf(results_sim, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_stage_objective_as_graf(results_sim, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS                

            PSRClassesInterface.write_registry(graf, [results_sim[s][t][:stage_objective]], t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_imp_exp_cost_as_graf(x, results_sim,result_name, imp_exp_cost_dict, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_imp_exp_cost_as_graf(results_sim,result_name, imp_exp_cost_dict, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end
 
function export_imp_exp_cost_as_graf(results_sim,result_name, imp_exp_cost_dict, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

    n_agents = length(AGENTS)
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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS         
            imp_exp_calc_costs = zeros(n_agents)
            for i in 1:n_agents
                if haskey(imp_exp_cost_dict,i)
                    imp_exp_calc_costs[i] = imp_exp_cost_dict[i][t,1]*results_sim[s][t][result_name][i]
                else
                    imp_exp_calc_costs[i] = 0
                end
            end
            PSRClassesInterface.write_registry(graf, imp_exp_calc_costs, t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end

function export_losses_as_graf(x, par, filepath, filename, AGENTS; UNIT::String="", CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)
    return export_losses_as_graf(par, filepath, filename, x.stages, x.sim_scenarios, AGENTS, UNIT; CSV, INITIAL_STAGE, INITIAL_YEAR)
end

function export_losses_as_graf(par, filepath, filename, STAGES, SCENARIOS, AGENTS, UNIT; CSV = false, INITIAL_STAGE=1, INITIAL_YEAR=1900)

    FILE_NAME = joinpath(filepath, filename)

    stage_average_losses = get_stagewise_losses(par)

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
        stage_type = PSRI.STAGE_DAY,
        initial_stage = INITIAL_STAGE,
        initial_year  = INITIAL_YEAR
    )

    # --- store data
    for t = 1:STAGES
        for s = 1:SCENARIOS                
            PSRClassesInterface.write_registry(graf, [stage_average_losses[t]], t, s, 1)
        end
    end

    # --- close graf
    PSRClassesInterface.close(graf)
end
