using Base: Float64
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
            PSRCollectionElement_maxElements(p.lstsys) , # sys       :: Int32

            # # --- Areas
            PSRCollectionElement_maxElements(p.lstare) , # are       :: Int32

            # # --- Demands
            PSRCollectionElement_maxElements(p.lstdem)    , # dem       :: Int32
            PSRCollectionElement_maxElements(p.lstdsg)    , # dsg       :: Int32
            PSRCollectionElement_maxElements(p.lstdsgels) , # dsgels    :: Int32

            # # --- Generators
            PSRCollectionElement_maxElements(p.lsthyd)  , # hyd       :: Int32
            PSRCollectionElement_maxElements(p.lstther) , # ther      :: Int32
            PSRCollectionElement_maxElements(p.lstgnd)  , # gnd       :: Int32
            PSRCollectionElement_maxElements(p.lstgen)  , # gen       :: Int32

            0.0 , # PSRIOElementHourlyScenarios_totalStages(p.lstgndscn)    ,
            0.0 , # PSRIOElementHourlyScenarios_totalScenarios(p.lstgndscn) ,
            0.0 , # PSRIOElementHourlyScenarios_totalHours(p.lstgndscn)     ,

            # # --- Fuels
            PSRCollectionElement_maxElements(p.lstfuel) , # fuel      :: Int32

            # # --- Battery
            PSRCollectionElement_maxElements(p.lstbat)  , # bat       :: Int32

            # # --- Loads
            PSRCollectionElement_maxElements(p.lstload) , # load      :: Int32

            # # --- Network
            PSRCollectionElement_maxElements(p.lstbus) , # bus       :: Int32
            PSRCollectionElement_maxElements(p.lstcir) , # cir       :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstbusdc) , # busdc     :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstldc)   , # lnkdc     :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstcirdc) , # cirdc     :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstcnv)   , # cnv       :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstlin)   , # lin       :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lsttrf)   , # trf       :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstcap)   , # cap       :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstrea)   , # rea       :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstsca)   , # sercap    :: Int32
            sddp ? 0 : PSRCollectionElement_maxElements(p.lstlre)     # linrea    :: Int32
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
    s_stg :: Array{Int32}
    s_scn :: Array{Int32}
    s_blk :: Array{Int32}
    s_ctg :: Array{Int32}

    # --- Circuit Data
    cir_code      :: Array{Int32} 
    cir_name      :: Array{String} 
    cir_status    :: Array{Int32} 
    cir_exist     :: Array{Int32}
    cir_monitored :: Array{Int32}
    cir_r         :: Array{Float64}
    cir_x         :: Array{Float64}
    cir_capacity  :: Array{Float64}
    cir_volt      :: Array{Float64} 
    cirBusFrom   :: Array{Int32}
    cirBusTo     :: Array{Int32}
    cirSortOrder :: Array{Int32}

    # --- Bus Data
    busCode      :: Array{Int32}
    busName      :: Array{String}
    busVolt      :: Array{Float64}
    busVMin      :: Array{Float64}
    busVMax      :: Array{Float64}
    busSortOrder :: Array{Int32}

    # --- Demand Data
    demandHour    :: Array{Float64}
    demandBlock   :: Array{Float64}
    demandElHour  :: Array{Float64}
    demandElBlock :: Array{Float64}
    demandElCost  :: Array{Float64}

    # --- Demand Response
    dr_max_shift :: Array{Float64}

    # --- Load Data
    loadCode     :: Array{Int32}
    loadName     :: Array{String}
    loadP        :: Array{Float64}
    loadQ        :: Array{Float64}

    # --- Generator Data : General
    gen_code      :: Array{Int32}
    gen_name      :: Array{String}
    genOper      :: Array{Int32}
    genPmn       :: Array{Float64}
    genQmn       :: Array{Float64}
    genPmx       :: Array{Float64}
    genQmx       :: Array{Float64}
    genPg        :: Array{Float64}

    # --- Plant: thermal
    ter_code     :: Array{Int32}
    ter_name     :: Array{String}
    ter_capacity :: Array{Float64}
    ter_cost     :: Array{Float64}
    ter_exist    :: Array{Int32}

    # --- Plant: hydro
    hid_code     :: Array{Int32}
    hid_name     :: Array{String}
    hid_capacity :: Array{Float64}
    hid_exist    :: Array{Int32}

    # --- Plant: renewables
    gnd_code     :: Array{Int32}
    gnd_name     :: Array{String}
    gnd_capacity :: Array{Float64}
    gnd_exist    :: Array{Int32}
    gnd_scn      :: Array{Float64}

    # --- fuel
    fuel_code  :: Array{Int32}
    fuel_name  :: Array{String}
    fuel_cost  :: Array{Float64}

    # --- Battery
    bat_code             :: Array{Int32}
    bat_name             :: Array{String}
    bat_Eini             :: Array{Float64}
    bat_reg_time         :: Array{Int32}
    bat_flag_inter_stage :: Array{Int32}
    bat_charge_ramp      :: Array{Float64}
    bat_discharge_ramp   :: Array{Float64}
    bat_Emin             :: Array{Float64}
    bat_Emax             :: Array{Float64}
    bat_Pmax             :: Array{Float64}
    bat_charge_effic     :: Array{Float64}
    bat_discharge_effic  :: Array{Float64}

    # --- Mapping Data
    therm2gen   :: Array{Int32}
    hyd2gen     :: Array{Int32}
    gnd2gen     :: Array{Int32}
    bat2gen     :: Array{Int32}
    ger2bus     :: Array{Int32}
    bat2bus     :: Array{Int32}
    bus2gnd     :: Array{Int32}
    bus2hyd     :: Array{Int32}
    bus2bat     :: Array{Int32}
    bus2ther    :: Array{Int32}
    bus2load    :: Array{Int32}
    ther2fuel   :: Array{Int32}


    dsg2dem    :: Array{Int32}
    dsgels2dem :: Array{Int32}
    load2dem   :: Array{Int32}
    load2bus   :: Array{Int32}

    function Data(n::Sizes)
        return new()
    end
end
mutable struct Execution
    PATH  :: String
    DEBUG :: Int64
    NSTG  :: Int64
    NSCN  :: Int64
    NSTT  :: Int64
    RTSL  :: Bool
    ELOD  :: Bool
    ESCN  :: Bool
    RMKV  :: Bool
    DEFC  :: Float64
    DFACT :: Float64
    function Execution()
        return new(
            ""   ,
            0    ,
            0    ,
            0    ,
            0    ,
            false,
            false,
            false,
            false,
            1e4 
        )
    end
    function Execution(path::String)
        !isdir(path) && error("Unable to locate case path: "*path)
        
        sddp_dso = read_execution_parameters(path::String)

        return new(
            path                                             ,
            0                                                ,
            sddp_dso.sddp_stages                             ,
            sddp_dso.sddp_scenarios                          ,
            sddp_dso.markov_states                           ,
            sddp_dso.read_tsl_scenarios == 1                 ,
            sddp_dso.read_external_hourly_load == 1          ,
            sddp_dso.read_external_hourly_gnd_scenarios == 1 ,
            sddp_dso.run_markov_model == 1                   ,
            sddp_dso.deficit_cost                            ,
            sddp_dso.demand_factor
        )
    end
    function read_execution_parameters(path::String)
        dat = import_csvfile(path,"dso_sddp.dat")
        return dat[1,:]
    end
end
mutable struct SDDPParameters

    # problem parameters
    stages      :: Int64
    sense       # :: Symbol
    optimizer   # :: Float64
    upper_bound :: Float64
    lower_bound :: Float64

    # problem dimensions
    nscn   :: Int64
    nbat   :: Int64
    ngen   :: Int64
    nsol   :: Int64
    nelv   :: Int64
    nbus   :: Int64
    nlin   :: Int64
    nload  :: Int64
    nstate :: Int64

    # problem variables 
    # batteries        
    bat_e_ini   :: Array{Float64} # [p.u.]
    bat_e_min   :: Array{Float64} # [MWh ]
    bat_e_max   :: Array{Float64} # [MWh ]
    bat_c_eff   :: Array{Float64} # [%   ]
    bat_d_eff   :: Array{Float64} # [%   ]
    bat_cap     :: Array{Float64} # [MW  ]
    
    # diesel generator
    gen_cost :: Array{Float64}
    gen_cap  :: Array{Float64}

    # solar rooftop
    sol_cap :: Array{Float64}
    sol_scn :: Array{Float64,3}

    # import/export energy form transmission grid
    imp_cost :: Dict{Int64, Matrix{Float64}}
    imp_max  :: Dict{Int64, Matrix{Float64}}
    exp_cost :: Dict{Int64, Matrix{Float64}}
    exp_max  :: Dict{Int64, Matrix{Float64}}

    # electric vehicles
    elv_e_ini :: Array{Float64} # initial storage
    elv_e_max :: Array{Float64} # maximum storage
    elv_cap   :: Array{Float64} # capacity
    elv_c_hrs :: Array{Int64}   # charging hours
    elv_c_eff :: Array{Float64} # charging efficiency

    # demand    
    demand        :: Array{Array{Float64}}
    demand_factor :: Float64
    
    # losses    
    losses        :: Array{Array{Float64}}
    
    # slack
    def_cost      :: Float64
    
    # demand response
    dem_rsp_tariff :: Array{Float64} # [$/MWh] tariff
    dem_rsp_shift  :: Array{Float64} # [  MWh]

    # circuit
    cir_x      :: Array{Float64}
    cir_cap    :: Array{Float64}
    cir_bus_fr :: Array{Int64}
    cir_bus_to :: Array{Int64}

    # map
    bus_map_sol :: Dict{Int64,Array{Int64}}
    bus_map_gen :: Dict{Int64,Array{Int64}}
    bus_map_bat :: Dict{Int64,Array{Int64}}
    bus_map_elv :: Dict{Int64,Array{Int64}}
    bus_map_dem :: Dict{Int64,Array{Int64}}
    bus_map_rsp :: Dict{Int64,Array{Int64}}
    bus_map_imp :: Dict{Int64,Array{Int64}}
    bus_map_exp :: Dict{Int64,Array{Int64}}

    # markov
    transition_matrices  :: Array{Array{Float64,2},1}
    markov_probabilities :: Array{Float64}
    
    # hrinj attributes
    hrinj_cst :: Dict{Int64, Matrix{Float64}}
    hrinj_cap :: Dict{Int64, Matrix{Float64}}

    # flags
    use_cir_cap :: Bool

    SDDPParameters() = new()
end