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