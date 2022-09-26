"""
    set_maps!
"""
function set_maps!(data, n, d)

    # --- Load maps
    d.lod2bus = PSRI.get_map(data, "PSRLoad", "PSRBus")

    # --- Generator maps
    d.gen2ter = PSRI.get_map(data, "PSRGenerator", "PSRThermalPlant")
    d.gen2gnd = PSRI.get_map(data, "PSRGenerator", "PSRGndPlant")
    d.gen2hid = PSRI.get_map(data, "PSRGenerator", "PSRHydroPlant")
    d.gen2bus = PSRI.get_map(data, "PSRGenerator", "PSRBus")
    
    d.ter2fue = PSRI.get_vector_map(data, "PSRThermalPlant", "PSRFuel"; relation_type = PSRI.RELATION_1_TO_N)

    # --- Network maps
    d.cir_bus_from = PSRI.get_map(data, "PSRSerie", "PSRBus", relation_type = PSRI.RELATION_FROM)
    d.cir_bus_to   = PSRI.get_map(data, "PSRSerie", "PSRBus", relation_type = PSRI.RELATION_TO)

    # ter > bar
    d.ter2bus = map_tec_bus(d.gen2bus, d.gen2ter, n.ther, n.gen) 
    d.hid2bus = map_tec_bus(d.gen2bus, d.gen2hid, n.hyd, n.gen) 
    d.gnd2bus = map_tec_bus(d.gen2bus, d.gen2gnd, n.gnd, n.gen) 
    d.bat2bus = PSRI.get_map(data, "PSRBattery", "PSRBus")
    d.lod2bus = PSRI.get_map(data, "PSRLoad", "PSRBus")
end

"""
    set_dimensions!
"""
function set_dimensions!(data, n)

    # --- Simulation Parameters
    n.stages    = PSRI.total_stages(data)   
    n.blocks    = PSRI.total_scenarios(data)
    n.scenarios = PSRI.total_blocks(data)

    # --- Systems
    n.sys = PSRI.max_elements(data, "PSRSystem")       

    # --- Areas
    n.are = PSRI.max_elements(data, "PSRArea")      

    # --- Demands
    n.dem = PSRI.max_elements(data, "PSRDemand")

    # --- Generators
    n.ther = PSRI.max_elements(data, "PSRThermalPlant")     
    n.hyd  = PSRI.max_elements(data, "PSRHydroPlant")     
    n.gnd  = PSRI.max_elements(data, "PSRGndPlant")     
    n.gen  = PSRI.max_elements(data, "PSRGenerator") 

    # --- Fuels
    n.fuel = PSRI.max_elements(data, "PSRFuel")   

    # --- Battery
    n.bat = PSRI.max_elements(data, "PSRBattery")       

    # --- Loads
    n.load = PSRI.max_elements(data, "PSRLoad")

    # --- Network
    n.bus = PSRI.max_elements(data, "PSRBus") 
    n.cir = PSRI.max_elements(data, "PSRSerie")
end

"""
    set_data!
"""
function set_data!(data, n, d)

    # --- get parameters of thermal plants
    (n.load > 0) && set_data_load!(data, d)

    # --- get parameters of thermal plants
    (n.ther > 0) && set_data_thermal!(data, d, n)

    # --- get parameters of gnd plants
    (n.hyd  > 0) && set_data_hydro!(data, d)

    # --- get parameters of gnd plants
    (n.gnd  > 0) && set_data_renewable!(data, d)

    # --- get parameters of bus
    (n.cir  > 0) && set_data_battery!(data, d)

    # --- get parameters of bus
    (n.bus  > 0) && set_data_bus!(data, d)

    # --- get parameters of circuit
    (n.cir  > 0) && set_data_circuit!(data, d)
end

"""
    set_data_load!
"""
function set_data_load!(data, d)
    d.load_name     = PSRI.get_name(data, "PSRLoad")
    d.load_code     = PSRI.get_code(data, "PSRLoad")
end

"""
    set_data_thermal!
"""
function set_data_thermal!(data, d, n)
    d.ter_name     = PSRI.get_name(data, "PSRThermalPlant")
    d.ter_code     = PSRI.get_code(data, "PSRThermalPlant")
    d.ter_exist    = PSRI.mapped_vector(data, "PSRThermalPlant", "Existing", Int32)
    d.ter_capacity = PSRI.mapped_vector(data, "PSRThermalPlant", "GerMax" , Float64)
    d.ter_cost     = Float64[]

    fue_cost = PSRI.mapped_vector(data, "PSRFuel", "Custo", Float64)

    for i in 1:n.ther
        cst = Float64[]
        for j in d.ter2fue[i]
            push!(cst, fue_cost[j])
        end
        push!(d.ter_cost, maximum(cst))
    end
end

"""
    set_data_renewable!
"""
function set_data_renewable!(data, d)
    d.gnd_name     = PSRI.get_name(data, "PSRGndPlant")
    d.gnd_code     = PSRI.get_code(data, "PSRGndPlant")
    d.gnd_exist    = PSRI.mapped_vector(data, "PSRGndPlant", "Existing", Int32)
    d.gnd_capacity = PSRI.mapped_vector(data, "PSRGndPlant", "PotInst", Float64)
end

"""
    set_data_hydro!
"""
function set_data_hydro!(data, d)
    d.hid_name     = PSRI.get_name(data, "PSRHydroPlant")
    d.hid_code     = PSRI.get_code(data, "PSRHydroPlant")
    d.hid_exist    = PSRI.mapped_vector(data, "PSRHydroPlant", "Existing", Int32)
    d.hid_capacity = PSRI.mapped_vector(data, "PSRHydroPlant", "PotInst", Float64)
end

"""
    set_data_bus!
"""
function set_data_bus!(data, d)
    d.bus_name     = PSRI.get_name(data, "PSRBus")
    d.bus_code     = PSRI.get_code(data, "PSRBus")
end

"""
    set_data_circuit!
"""
function set_data_circuit!(data, d)
    d.cir_name     = PSRI.get_name(data, "PSRSerie")
    d.cir_code     = PSRI.get_code(data, "PSRSerie")
    # d.cir_exist    = PSRI.mapped_vector(data, "PSRSerie", "Existing", Int32)
    # d.cir_status   = PSRI.mapped_vector(data, "PSRSerie", "Status", Int32)
    d.cir_capacity = PSRI.mapped_vector(data, "PSRSerie", "Rn", Float64)
    d.cir_x        = PSRI.mapped_vector(data, "PSRSerie", "X", Float64)
    d.cir_r        = PSRI.mapped_vector(data, "PSRSerie", "R", Float64)
end

"""
    set_data_battery!
"""
function set_data_battery!(data, d)
    d.bat_code             = PSRI.get_code(data, "PSRBattery")
    d.bat_name             = PSRI.get_name(data, "PSRBattery")
    d.bat_Eini             = PSRI.get_parms(data, "PSRBattery", "Einic", Float64)
    d.bat_Emin             = PSRI.mapped_vector(data, "PSRBattery", "Emin" , Float64)
    d.bat_Emax             = PSRI.mapped_vector(data, "PSRBattery", "Emax" , Float64)
    d.bat_Pmax             = PSRI.mapped_vector(data, "PSRBattery", "Pmax" , Float64)
    d.bat_charge_effic     = PSRI.mapped_vector(data, "PSRBattery", "ChargeEffic", Float64)
    d.bat_discharge_effic  = PSRI.mapped_vector(data, "PSRBattery", "DischargeEffic" , Float64)
    d.bat_charge_ramp      = PSRI.get_parms(data, "PSRBattery", "ChargeRamp", Float64)
    d.bat_discharge_ramp   = PSRI.get_parms(data, "PSRBattery", "DischargeRamp" , Float64)
    d.bat_reg_time         = PSRI.get_parms(data, "PSRBattery", "RegTime", Int32)
    d.bat_flag_inter_stage = PSRI.get_parms(data, "PSRBattery", "FlagInterStage" , Int32)
end


