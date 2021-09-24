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


function string_converter( self::String , tipo::Type , msg::String )
    try
        parse( tipo , self )
    catch
        error( msg )
    end
end

function string_converter( self::SubString{String} , tipo::Type , msg::String )
    try
        parse( tipo , self )
    catch
        @show self
        error( msg )
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