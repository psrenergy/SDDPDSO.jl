"""
    string_converter
"""
function string_converter( self::String , tipo::Type , msg::String )
    try
        parse( tipo , self )
    catch
        error( msg )
    end
end

"""
    string_converter
"""
function string_converter( self::SubString{String} , tipo::Type , msg::String )
    try
        parse( tipo , self )
    catch
        @show self
        error( msg )
    end
end

"""
    list_all_max_elements
"""
function list_all_max_elements(data)

    elements = String[
        "PSRSystem"      ,
        "PSRArea"        ,
        "PSRLoad"        ,
        "PSRDemand"      , "PSRDemandSegment" , 
        "PSRHydroPlant"  , 
        "PSRThermalPlant", "PSRFuel"          , 
        "PSRGndPlant"    , "PSRGaugingStation",
        "PSRBattery"   ,
        "PSRBus"         , "PSRSerie"         ,
        "PSRDCLinks"     ,
        "PSRPowerInjection"
    ]

    for element in elements
        println(element * ": $(PSRI.max_elements(data, element))")
    end
end

"""
    get_map_bus
"""
function get_map_bus(nbus::Integer, gen2tec::Vector{Int32}, gen2bus::Vector{Int32})
    (length(gen2tec) != length(gen2bus)) && error("maps of different length")

    map_bus = zeros(Integer, nbus)

    for i in 1:length(gen2tec)
        # tec index
        tec = gen2tec[i]
        if tec != 0
            # bus index
            bus = gen2bus[i]

            # for bus "b" attribute tec "t"
            map_bus[bus] = tec
        end
    end
    return map_bus
end

"""
    map_tec_bus
"""
function map_tec_bus(gen2bus::Vector{Int32}, gen2tec::Vector{Int32}, ntec, ngen)
    (ntec <= 0) && return Int32[]

    tec2bus = zeros(Int32, ntec)

    for i in 1:ngen
        tec_i = gen2tec[i]
        if tec_i != 0
            tec2bus[tec_i] = gen2bus[i]
        end
    end

    return tec2bus
end

"""
    reverse_map_to_dict
"""
function reverse_map_to_dict(tec_map::Vector{Int32}, ntec)
    rev_map = Dict{Int32, Vector{Int32}}(i => Int32[] for i in unique(tec_map))
    for i in 1:ntec
        push!(rev_map[tec_map[i]],i)
    end
    return rev_map
end

function clear_results(casepath)
    rm(joinpath(casepath,"results"), recursive = true)
    mkdir(joinpath(casepath,"results"))
    return
end