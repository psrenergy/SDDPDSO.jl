"""
    import_csvfile
"""
function import_csvfile(path::String, name::String)
    filepath = joinpath(path,name)

    csvfile = isfile(filepath) ? CSV.read(filepath, DataFrame) : error("could not find "*filepath)

    return csvfile
end

"""
    import_file
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
    
    hrload_scn = Dict(code => zeros(Float64, x.dso_stages) for code in d.load_code)

    valid_load_codes = [code for code in d.load_code if hasproperty(hrload,"$code")]
    
    for i in 1:size(hrload,1)

        hrload_i = hrload[i,:]

        stg = hrload_i.stage

        (stg > x.dso_stages) && continue
        
        for code in valid_load_codes
            hrload_scn[code][stg] = x.demand_factor * hrload_i["$code"]
        end
    end

    return hrload_scn
end


"""
    import_dso_hrgnd_scn
"""
function import_dso_hrgnd_scn(x::Execution, d::Data)
    
    # --- read external hourly scenarios cost data
    hrgnd = import_csvfile(x.PATH,"dso_hrgnd_scn.dat")
    
    hrgnd_scn = Dict(code => zeros(Float64, x.dso_stages, x.dso_scenarios) for code in d.gnd_code) #d.bus_code[d.bus2gnd])

    # CHANGE TO LOAD CODES
    valid_load_codes = [code for code in d.gnd_code if hasproperty(hrgnd,"$code")] #d.bus_code[d.bus2gnd]
    
    for i in 1:size(hrgnd,1)

        hrgnd_i = hrgnd[i,:]

        stg = hrgnd_i.stage
        scn = hrgnd_i.scenario

        if (stg > x.dso_stages) | (scn > x.dso_scenarios)
            continue
        end

        for code in valid_load_codes
            hrgnd_scn[code][stg, scn] = hrgnd_i["$code"]
        end
    end

    return hrgnd_scn
end

"""
    import_dso_dr_shift
"""
function import_dso_dr_shift(x::Execution, d::Data)
    
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
    import_dso_hrinj_cst
"""
function import_dso_hrinj_cst(x::Execution, d::Data)
    
    # --- read external hourly scenarios cost data
    hrinj = import_csvfile(x.PATH,"dso_hrinj_cst_scn.dat")
    
    # --- 
    valid_codes = [code for code in d.bus_code if hasproperty(hrinj,"$code")]
    
    # --- 
    hrinj_scn = Dict(code => zeros(Float64, x.dso_stages, x.dso_scenarios) for code in valid_codes)
    hrinj_stg = Dict(code => zeros(Float64, x.dso_stages) for code in valid_codes)

    for i in 1:size(hrinj,1)

        hrinj_i = hrinj[i,:]

        stg = hrinj_i.stage
        scn = hrinj_i.scenario

        if (stg > x.dso_stages) | (scn > x.dso_scenarios)
            continue
        end

        for code in valid_codes
            hrinj_scn[code][stg, scn]  = hrinj_i["$code"]
            hrinj_stg[code][stg]      += hrinj_i["$code"]/x.dso_scenarios
        end
    end


    return hrinj_scn
end

"""
    import_dso_hrinj_cap
"""
function import_dso_hrinj_cap(x::Execution, d::Data)
    
    # --- read external hourly scenarios cost data
    hrinj = import_csvfile(x.PATH,"dso_hrinj_cap_scn.dat")
    
    # --- 
    valid_codes = [code for code in d.bus_code if hasproperty(hrinj,"$code")]
    
    # --- 
    hrinj_scn = Dict(code => zeros(Float64, x.dso_stages, x.dso_scenarios) for code in valid_codes)

    for i in 1:size(hrinj,1)

        hrinj_i = hrinj[i,:]

        stg = hrinj_i.stage
        scn = hrinj_i.scenario

        if (stg > x.dso_stages) | (scn > x.dso_scenarios)
            continue
        end

        for code in valid_codes
            hrinj_scn[code][stg, scn] = hrinj_i["$code"]
        end
    end

    return hrinj_scn
end

function import_dso_markov_probabilities(x::Execution)
    
    # --- read 
    prob = import_csvfile(x.PATH,"dso_markov_probabilities.dat")
    
    nrow, ncol = size(prob)

    markov_prob = zeros(x.dso_stages, x.dso_scenarios, x.flag_markov_states)

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
    
    markov_trans = zeros(x.dso_stages, x.flag_markov_states, x.flag_markov_states)

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
    for stage in 3:x.dso_stages
        push!(markov_trans_reshape,markov_trans[stage,:,:])
    end

    return markov_trans_reshape
end