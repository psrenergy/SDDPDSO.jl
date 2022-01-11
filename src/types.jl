function _check_input(data, column::Symbol, default, type, message::String, throw_error::Bool=false, force::Bool=true)
    if hasproperty(data,column)
        default = _check_type(data[column],type,message,force)
    elseif throw_error
        error("unable to find key "*string(column))
    end
    return default
end

function _check_input(data, column::String, default, type, message::String, throw_error::Bool=false, force::Bool=true)
    return _check_input(data, Symbol(column), default, type, message, throw_error, force)
end

function _check_type(dt,ty,msg,force)
    if typeof(dt) != ty
        if force
            convert(ty,dt)
        else
            error(msg)
        end
    end
    return dt
end

mutable struct Sizes

    # --- Execution Parameters
    procs     :: Int32

    # --- Simulation Parameters
    stages    :: Int32
    blocks    :: Int32
    scenarios :: Int32

    # --- Systems
    sys       :: Int32

    # --- Areas
    are       :: Int32

    # --- Demands
    dem       :: Int32
    dsg       :: Int32
    dsgels    :: Int32


    # --- Generators
    hyd       :: Int32
    ther      :: Int32
    gnd       :: Int32
    gen       :: Int32

    # --- Gnd Scenario
    gndscn_stages    :: Int32
    gndscn_scenarios :: Int32
    gndscn_hours     :: Int32

    # --- Fuels
    fuel      :: Int32

    # --- Battery
    bat       :: Int32

    # --- Loads
    load      :: Int32

    # --- Network
    bus       :: Int32
    cir       :: Int32
    busdc     :: Int32
    lnkdc     :: Int32
    cirdc     :: Int32
    cnv       :: Int32
    lin       :: Int32
    trf       :: Int32
    cap       :: Int32
    rea       :: Int32
    sercap    :: Int32
    linrea    :: Int32

    function Sizes()
        return new(
            # # --- Execution Parameters
            1 , # procs     :: Int32

            # # --- Simulation Parameters
            1 , # stages    :: Int32
            1 , # blocks    :: Int32
            1 , # scenarios :: Int32

            # # --- Systems
            1 , # sys       :: Int32

            # # --- Areas
            1 , # are       :: Int32

            1 , # dem       :: Int32

            # # --- Generators
            1 , # hyd       :: Int32
            1 , # ther      :: Int32
            1 , # gnd       :: Int32
            1 , # gen       :: Int32

            # # --- Fuels
            1 , # fuel      :: Int32

            # # --- Battery
            0 , # bat       :: Int32

            # # --- Loads
            1 , # load      :: Int32

            # # --- Network
            1 , # bus       :: Int32
            1 , # cir       :: Int32
            0 , # busdc     :: Int32
            0 , # lnkdc     :: Int32
            0 , # cirdc     :: Int32
            0 , # cnv       :: Int32
            0 , # lin       :: Int32
            0 , # trf       :: Int32
            0 , # cap       :: Int32
            0 , # rea       :: Int32
            0 , # sercap    :: Int32
            0   # linrea    :: Int32
        )
    end

    function Sizes(data,sddp=true)
        return new(
            # # --- Execution Parameters
            1 , # procs     :: Int32

            # # --- Simulation Parameters
            PSRStudy_getNumberStages(p.istdy)      , # stages    :: Int32
            PSRStudy_getNumberBlocks(p.istdy)      , # blocks    :: Int32
            PSRStudy_getNumberSimulations(p.istdy) , # scenarios :: Int32

            # # --- Systems
            PSRI.max_elements(data, "PSRSystem"),

            # # --- Areas
            PSRI.max_elements(data, "PSRArea"), # are       :: Int32

            # # --- Demands
            PSRI.max_elements(data, "PSRDemand")    , # dem       :: Int32
            0                                       , # dsg       :: Int32
            0                                       , # dsgels    :: Int32

            # # --- Generators
            PSRI.max_elements(data, "PSRHydroPlantSystem")  , # hyd       :: Int32
            PSRI.max_elements(data, "PSRThermalPlant")      , # ther      :: Int32
            PSRI.max_elements(data, "PSRGndPlant")          , # gnd       :: Int32
            PSRI.max_elements(data, "PSRGenerator")         , # gen       :: Int32

            0.0 , # PSRIOElementHourlyScenarios_totalStages(p.lstgndscn)    ,
            0.0 , # PSRIOElementHourlyScenarios_totalScenarios(p.lstgndscn) ,
            0.0 , # PSRIOElementHourlyScenarios_totalHours(p.lstgndscn)     ,

            # # --- Fuels
            PSRI.max_elements(data, "PSRFuel") , # fuel      :: Int32

            # # --- Battery
            PSRI.max_elements(data, "PSRBattery")  , # bat       :: Int32

            # # --- Loads
            PSRI.max_elements(data, "PSRLoad") , # load      :: Int32

            # # --- Network
            PSRI.max_elements(data, "PSRBus")                       , # bus       :: Int32
            PSRI.max_elements(data, "PSRSerie")                     , # cir       :: Int32
            sddp ? 0 : 0 , # busdc     :: Int32
            sddp ? 0 : 0 , # lnkdc     :: Int32
            sddp ? 0 : 0 , # cirdc     :: Int32
            sddp ? 0 : 0 , # cnv       :: Int32
            sddp ? 0 : 0 , # lin       :: Int32
            sddp ? 0 : 0 , # trf       :: Int32
            sddp ? 0 : 0 , # cap       :: Int32
            sddp ? 0 : 0 , # rea       :: Int32
            sddp ? 0 : 0 , # sercap    :: Int32
            sddp ? 0 : 0   # linrea    :: Int32
        )
    end
end
mutable struct Data

    # --- Chronological Data
    stage_type    :: Int32
    initial_stage :: Int32
    initial_year  :: Int32

    # --- Current Step
    c_stg :: Int32
    c_scn :: Int32
    c_blk :: Int32
    c_ctg :: Int32

    # --- Selected Step
    s_stg :: Vector{Int32}
    s_scn :: Vector{Int32}
    s_blk :: Vector{Int32}
    s_ctg :: Vector{Int32}

    # --- Circuit Data
    cir_code       :: Vector{Int32} 
    cir_name       :: Vector{String} 
    cir_status     :: Vector{Int32} 
    cir_exist      :: Vector{Int32}
    cir_monitored  :: Vector{Int32}
    cir_r          :: Vector{Float64}
    cir_x          :: Vector{Float64}
    cir_capacity   :: Vector{Float64}
    cir_volt       :: Vector{Float64} 
    cir_bus_from   :: Vector{Int32}
    cir_bus_to     :: Vector{Int32}
    cir_sort_order :: Vector{Int32}

    # --- Bus Data
    bus_code       :: Vector{Int32}
    bus_name       :: Vector{String}
    bus_volt       :: Vector{Float64}
    bus_vmin       :: Vector{Float64}
    bus_vmax       :: Vector{Float64}
    bus_sort_order :: Vector{Int32}

    # --- Demand Data
    demandHour    :: Vector{Float64}
    demandBlock   :: Vector{Float64}
    demandElHour  :: Vector{Float64}
    demandElBlock :: Vector{Float64}
    demandElCost  :: Vector{Float64}

    # --- Demand Response
    dr_max_shift :: Vector{Float64}

    # --- Load Data
    load_code     :: Vector{Int32}
    load_name     :: Vector{String}
    load_p        :: Vector{Float64}
    load_q        :: Vector{Float64}

    # --- Generator Data : General
    gen_code      :: Vector{Int32}
    gen_name      :: Vector{String}
    genOper      :: Vector{Int32}
    genPmn       :: Vector{Float64}
    genQmn       :: Vector{Float64}
    genPmx       :: Vector{Float64}
    genQmx       :: Vector{Float64}
    genPg        :: Vector{Float64}

    # --- Plant: thermal
    ter_code     :: Vector{Int32}
    ter_name     :: Vector{String}
    ter_capacity :: Vector{Float64}
    ter_cost     :: Vector{Float64}
    ter_exist    :: Vector{Int32}

    # --- Plant: hydro
    hid_code     :: Vector{Int32}
    hid_name     :: Vector{String}
    hid_capacity :: Vector{Float64}
    hid_exist    :: Vector{Int32}

    # --- Plant: renewables
    gnd_code     :: Vector{Int32}
    gnd_name     :: Vector{String}
    gnd_capacity :: Vector{Float64}
    gnd_exist    :: Vector{Int32}
    gnd_scn      :: Vector{Float64}

    # --- fuel
    fuel_code  :: Vector{Int32}
    fuel_name  :: Vector{String}
    fuel_cost  :: Vector{Float64}

    # --- Battery
    bat_code             :: Vector{Int32}
    bat_name             :: Vector{String}
    bat_Eini             :: Vector{Float64}
    bat_reg_time         :: Vector{Int32}
    bat_flag_inter_stage :: Vector{Int32}
    bat_charge_ramp      :: Vector{Float64}
    bat_discharge_ramp   :: Vector{Float64}
    bat_Emin             :: Vector{Float64}
    bat_Emax             :: Vector{Float64}
    bat_Pmax             :: Vector{Float64}
    bat_charge_effic     :: Vector{Float64}
    bat_discharge_effic  :: Vector{Float64}

    # --- Mapping Data
    gen2ter :: Vector{Int32}
    gen2hid :: Vector{Int32}
    gen2gnd :: Vector{Int32}
    gen2bus :: Vector{Int32}

    ter2bus :: Vector{Int32}
    hid2bus :: Vector{Int32}
    gnd2bus :: Vector{Int32}
    bat2bus :: Vector{Int32}
    
    bus2gnd :: Vector{Int32}
    bus2hid :: Vector{Int32}
    bus2bat :: Vector{Int32}
    bus2ter :: Vector{Int32}
    bus2lod :: Vector{Int32}
    
    ter2fue :: Vector{Vector{Int32}}

    lod2bus :: Vector{Int32}

    function Data(n::Sizes)
        return new()
    end
end
mutable struct Execution
    PATH          :: String
    DEBUG         :: Int64
    stages        :: Int64
    scenarios     :: Int64
    sim_scenarios :: Int64
    markov_states :: Int64
    deficit_cost  :: Float64
    demand_factor :: Float64
    max_iter      :: Int64
    max_time      :: Float64
    flag_markov   :: Int64
    flag_export   :: Int64
    flag_import   :: Int64
    flag_dem_rsp  :: Int64
    flag_bat      :: Int64
    flag_sec_law  :: Int64
    flag_losses   :: Int64
    flag_debug    :: Int64
    flag_verbose  :: Int64
    flag_CSV      :: Int64

    function Execution()
        return new(
            ""   ,
            1    ,
            1    ,
            1    ,
            1    ,
            0    ,
            1.0e4,
            1.0  ,
            10   ,
            60.0 ,
            0    ,
            0    ,
            0    ,
            0    ,
            0    ,
            1    ,
            0
        )
    end

    function Execution(path::String)
        !isdir(path) && error("Unable to locate case path: "*path)
        
        sddp_dso = read_execution_parameters(path::String)

        return new(
            path                           ,
            0                              ,
            _check_input(sddp_dso, "sddp_stages"      ,     1,   Int64,                 "", true),
            _check_input(sddp_dso, "sddp_scenarios"   ,     1,   Int64,                 "", true),
            _check_input(sddp_dso, "sim_scenarios"    ,     1,   Int64,                 "", false),
            _check_input(sddp_dso, "markov_states"    ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "deficit_cost"     , 1.0e3, Float64, "expected float"  , false),
            _check_input(sddp_dso, "demand_factor"    ,   1.0, Float64, "expected float"  , false),
            _check_input(sddp_dso, "max_iter"         ,    50,   Int64, "expected integer", false),
            _check_input(sddp_dso, "max_time"         ,  60.0, Float64, "expected float"  , false),
            _check_input(sddp_dso, "flag_markov"      ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_export"      ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_import"      ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_dem_rsp"     ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_bat"         ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_sec_law"     ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_losses"      ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_debug"       ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_verbose"     ,     0,   Int64, "expected integer", false),
            _check_input(sddp_dso, "flag_csv"         ,     1,   Int64, "expected integer", false)
        )
    end 
    function read_execution_parameters(path::String)
        dat = import_csvfile(path,"dso_sddp.dat")
        return dat[1,:]
    end
end
mutable struct Problem

    # problem parameters
    sense       # :: Symbol
    optimizer   # :: Float64
    upper_bound :: Float64
    lower_bound :: Float64
    max_iter    :: Int64
    max_time    :: Float64
    
    # problem dimensions
    stages        :: Int64
    scenarios     :: Int64
    sim_scenarios :: Int64

    # number of elements
    nbat   :: Int64
    ngen   :: Int64
    nsol   :: Int64
    nelv   :: Int64
    nbus   :: Int64
    nlin   :: Int64
    nload  :: Int64
    nstate :: Int64
    ndays  :: Int64

    # problem variables 
    # batteries        
    bat_e_ini   :: Vector{Float64} # [p.u.]
    bat_e_min   :: Vector{Float64} # [MWh ]
    bat_e_max   :: Vector{Float64} # [MWh ]
    bat_c_eff   :: Vector{Float64} # [%   ]
    bat_d_eff   :: Vector{Float64} # [%   ]
    bat_cap     :: Vector{Float64} # [MW  ]
    
    # diesel generator
    gen_cost :: Vector{Float64}
    gen_cap  :: Vector{Float64}

    # solar rooftop
    sol_cap :: Vector{Float64}
    sol_scn :: Array{Float64,3}

    # import/export energy form transmission grid
    imp_cost :: Dict{Int64, Matrix{Float64}}
    imp_max  :: Dict{Int64, Matrix{Float64}}
    exp_cost :: Dict{Int64, Matrix{Float64}}
    exp_max  :: Dict{Int64, Matrix{Float64}}

    # electric vehicles
    elv_e_ini :: Vector{Float64} # initial storage
    elv_e_max :: Vector{Float64} # maximum storage
    elv_cap   :: Vector{Float64} # capacity
    elv_c_hrs :: Vector{Int64}   # charging hours
    elv_c_eff :: Vector{Float64} # charging efficiency

    # demand    
    demand        :: Vector{Vector{Float64}}
    demand_factor :: Float64
    
    # losses    
    losses        :: Vector{Vector{Float64}}
    
    # slack
    def_cost      :: Float64
    
    # demand response
    dem_rsp_tariff :: Vector{Float64} # [$/MWh] tariff
    dem_rsp_shift  :: Vector{Float64} # [  MWh]

    # circuit
    cir_x      :: Vector{Float64}
    cir_r      :: Vector{Float64}
    cir_cap    :: Vector{Float64}
    cir_bus_fr :: Vector{Int64}
    cir_bus_to :: Vector{Int64}

    # set
    set_bus     :: Vector{Int64}
    set_cir     :: Vector{Int64}
    set_dem     :: Vector{Int64}
    set_dem_rsp :: Vector{Int64}
    set_bat     :: Vector{Int64}
    set_gnd     :: Vector{Int64}
    set_ter     :: Vector{Int64}

    # map
    bus_map_sol :: Dict{Int64,Vector{Int64}}
    bus_map_gen :: Dict{Int64,Vector{Int64}}
    bus_map_bat :: Dict{Int64,Vector{Int64}}
    bus_map_elv :: Dict{Int64,Vector{Int64}}
    bus_map_dem :: Dict{Int64,Vector{Int64}}
    bus_map_rsp :: Dict{Int64,Vector{Int64}}
    bus_map_imp :: Dict{Int64,Vector{Int64}}
    bus_map_exp :: Dict{Int64,Vector{Int64}}

    # markov
    transition_matrices  :: Vector{Matrix{Float64}}
    markov_probabilities :: Vector{Float64}
    
    # hrinj attributes
    hrinj_cst :: Dict{Int64, Matrix{Float64}}
    hrinj_cap :: Dict{Int64, Matrix{Float64}}

    # flags
    flag_sec_law  :: Bool
    flag_import   :: Bool
    flag_export   :: Bool
    flag_markov   :: Bool
    flag_losses   :: Bool
    flag_dem_rsp  :: Bool
    flag_bat      :: Bool
    flag_debug    :: Bool
    flag_verbose  :: Bool
    flag_CSV      :: Bool
    flag_add_days :: Bool

    Problem() = new()
end