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

    function Data(p::Pointers, n::Sizes)
        return new(
            # --- Chronological Data
            PSRTimeController_getStageType(p.ictrl)  , # stage_type    :: Int32
            PSRTimeController_getFirstMonth(p.ictrl) , # initial_stage :: Int32
            PSRTimeController_getFirstYear(p.ictrl)  , # initial_year  :: Int32

            # --- Current Step
            1 , # c_stg :: Int32
            1 , # c_scn :: Int32
            1 , # c_blk :: Int32
            0 , # c_ctg :: Int32

            # --- Selected Step
            [1] , # s_stg :: Array{Int32}
            [1] , # s_scn :: Array{Int32}
            [1] , # s_blk :: Array{Int32}
            [0] , # s_ctg :: Array{Int32}

            # --- Circuit Data
            zeros(Int32, n.cir)   , # cir_code      :: Array{Int32} 
            ["" for i in 1:n.cir] , # cir_name      :: Array{String} 
            zeros(Int32, n.cir)   , # cir_status    :: Array{Int32} 
            zeros(Int32, n.cir)   , # cir_exist     :: Array{Int32}
            zeros(Int32, n.cir)   , # cir_monitored       :: Array{Int32}
            zeros(Float64, n.cir) , # cir_r         :: Array{Float64}
            zeros(Float64, n.cir) , # cir_x         :: Array{Float64}
            zeros(Float64, n.cir) , # cir_capacity        :: Array{Float64}
            zeros(Float64, n.cir) , # cir_volt      :: Array{Float64} 
            zeros(Int32, n.cir)   , # cirBusFrom   :: Array{Int32}
            zeros(Int32, n.cir)   , # cirBusTo     :: Array{Int32}
            zeros(Int32, n.cir)   , # cirSortOrder :: Array{Int32}

            # --- Bus Data
            zeros(Int32, n.bus)   , # busCode      :: Array{Int32}
            ["" for i in 1:n.bus] , # busName      :: Array{String}
            zeros(Float64, n.bus) , # busVolt      :: Array{Float64}
            zeros(Float64, n.bus) , # busVMin      :: Array{Float64}
            zeros(Float64, n.bus) , # busVMax      :: Array{Float64}
            zeros(Int32, n.bus)   , # busSortOrder :: Array{Int32}

            # --- Demand Data
            zeros(Float64, n.dem) , # demandHour    :: Array{Float64}
            zeros(Float64, n.dem) , # demandBlock   :: Array{Float64}
            zeros(Float64, n.dem) , # demandElHour  :: Array{Float64}
            zeros(Float64, n.dem) , # demandElBlock :: Array{Float64}
            zeros(Float64, n.dem) , # demandElCost  :: Array{Float64}

            # --- Demand Response
            zeros(Float64, n.load) , # dr_max_shift :: Array{Float64}

            # --- Load Data
            zeros(Int32, n.load)   , # loadCode     :: Array{Int32}
            ["" for i in 1:n.load] , # loadName     :: Array{String}
            zeros(Float64, n.load) , # loadP        :: Array{Float64}
            zeros(Float64, n.load) , # loadQ        :: Array{Float64}

            # --- Generator Data : General
            zeros(Int32, n.gen)   , # gen_code      :: Array{Int32}
            ["" for i in 1:n.gen] , # gen_name      :: Array{String}
            zeros(Int32, n.gen)   , # genOper      :: Array{Int32}
            zeros(Float64, n.gen) , # genPmn       :: Array{Float64}
            zeros(Float64, n.gen) , # genQmn       :: Array{Float64}
            zeros(Float64, n.gen) , # genPmx       :: Array{Float64}
            zeros(Float64, n.gen) , # genQmx       :: Array{Float64}
            zeros(Float64, n.gen) , # genPg        :: Array{Float64}

            # --- Plant: thermal
            zeros(Int32, n.ther)   , # ter_code  :: Array{Int32}
            ["" for i in 1:n.ther] , # ter_name  :: Array{String}
            zeros(Float64, n.ther) , # ter_capacity   :: Array{Float64}
            zeros(Float64, n.ther) , # ter_cost  :: Array{Float64}
            zeros(Int32, n.ther)   , # ter_exist :: Array{Int32}

            # --- Plant: hydro
            zeros(Int32, n.hyd)   , # hid_code  :: Array{Int32}
            ["" for i in 1:n.hyd] , # hid_name  :: Array{String}
            zeros(Float64, n.hyd) , # hid_capacity   :: Array{Float64}
            zeros(Int32, n.hyd)   , # hid_exist :: Array{Int32}

            # --- Plant: renewables
            zeros(Int32, n.gnd)   , # gnd_code  :: Array{Int32}
            ["" for i in 1:n.gnd] , # gnd_name  :: Array{String}
            zeros(Float64, n.gnd) , # gnd_capacity   :: Array{Float64}
            zeros(Int32, n.gnd)   , # gnd_exist :: Array{Int32}
            zeros(Float64, n.gnd) , # gnd_scn   :: Array{Int32}

            # # --- fuel
            zeros(Int32, n.fuel)   , # fuel_code  :: Array{Int32}
            ["" for i in 1:n.fuel] , # fuel_code  :: Array{String}
            zeros(Float64, n.fuel) , # fuel_cost  :: Array{Float64}

            # # --- Battery
            zeros(Int32, n.bat)   , # gnd_code           :: Array{Int32}
            ["" for i in 1:n.bat] , # gnd_name           :: Array{String}
            zeros(Float64, n.bat) , # bat_Eini          :: Array{Float64}
            zeros(Int32, n.bat)   , # bat_reg_time        :: Array{Int32}
            zeros(Int32, n.bat)   , # bat_flag_inter_stage :: Array{Int32}
            zeros(Float64, n.bat) , # bat_charge_ramp     :: Array{Float64}
            zeros(Float64, n.bat) , # bat_discharge_ramp  :: Array{Float64}
            zeros(Float64, n.bat) , # bat_Emin           :: Array{Float64}
            zeros(Float64, n.bat) , # bat_Emax           :: Array{Float64}
            zeros(Float64, n.bat) , # bat_Pmax           :: Array{Float64}
            zeros(Float64, n.bat) , # bat_charge_effic    :: Array{Float64}
            zeros(Float64, n.bat) , # bat_discharge_effic :: Array{Float64}

            # --- Mapping Data
            zeros(Int32, n.ther) , # therm2gen   :: Array{Int32}
            zeros(Int32, n.hyd)  , # hyd2gen     :: Array{Int32}
            zeros(Int32, n.gnd)  , # gnd2gen     :: Array{Int32}
            zeros(Int32, n.bat)  , # bat2gen     :: Array{Int32}
            zeros(Int32, n.gen)  , # ger2bus     :: Array{Int32}
            zeros(Int32, n.bat)  , # bat2bus     :: Array{Int32}
            zeros(Int32, n.bus)  , # bus2gnd     :: Array{Int32}
            zeros(Int32, n.bus)  , # bus2hyd     :: Array{Int32}
            zeros(Int32, n.bus)  , # bus2bat     :: Array{Int32}
            zeros(Int32, n.bus)  , # bus2ther    :: Array{Int32}
            zeros(Int32, n.bus)  , # bus2load    :: Array{Int32}
            zeros(Int32, n.ther) , # ther2fuel   :: Array{Int32}

            zeros(Int32, n.dsg)    , # dsg2dem    :: Array{Int32}
            zeros(Int32, n.dsgels) , # dsgels2dem :: Array{Int32}
            zeros(Int32, n.load)   , # load2dem   :: Array{Int32}
            zeros(Int32, n.load)     # load2bus   :: Array{Int32}
        )
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