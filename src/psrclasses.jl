"""
    set_maps!
"""
function set_maps!(data)
end

"""
    set_dimensions!
"""
function set_dimensions!(data, n)

    # --- Simulation Parameters
    # n.stages    = PSRI.max_elements(data, element)   
    # n.blocks    = PSRI.max_elements(data, element)
    # n.scenarios = PSRI.max_elements(data, element)

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
    (n.ther > 0) && set_data_thermal!(data, d)

    # --- get parameters of gnd plants
    (n.hyd  > 0) && set_data_hydro!(data, d)

    # --- get parameters of gnd plants
    (n.gnd  > 0) && set_data_renewable!(data, d)

    # --- get parameters of bus
    (n.cir  > 0) && set_data_battery!(data, d)

    # --- get parameters of bus
    (n.bus  > 0) && set_data_bus!(data, d)

    # --- get parameters of circuit
    (n.cir  > 0) && set_data_circuits!(data, d)
end

"""
    set_data_thermal!
"""
function set_data_thermal!(data, d)
    d.ter_name     = PSRI.get_name(data, "PSRThermalPlant")
    d.ter_code     = PSRI.get_code(data, "PSRThermalPlant")
    d.ter_exist    = PSRI.mapped_vector(data, "PSRThermalPlant", "Existing", Int32)
    d.ter_capacity = PSRI.mapped_vector(data, "PSRThermalPlant", "PotInst", Float64)
    # cost
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
    d.cir_status   = PSRI.mapped_vector(data, "PSRSerie", "Status", Int32)
    d.cir_capacity = PSRI.mapped_vector(data, "PSRSerie", "Rn", Float64)
    d.cir_x        = PSRI.mapped_vector(data, "PSRSerie", "X", Float64)
    d.cir_r        = PSRI.mapped_vector(data, "PSRSerie", "R", Float64)
end

"""
    set_data_battery!
"""
function set_data_battery!(data, d)
    d.bat_code            = PSRI.get_code(data, "PSRBattery")
    d.bat_name            = PSRI.get_name(data, "PSRBattery")
    # d.bat_Eini            = PSRI.mapped_vector(data, "PSRBattery", "Einic", Float64)
    d.bat_Emin            = PSRI.mapped_vector(data, "PSRBattery", "Emin" , Float64)
    d.bat_Emax            = PSRI.mapped_vector(data, "PSRBattery", "Emax" , Float64)
    d.bat_Pmax            = PSRI.mapped_vector(data, "PSRBattery", "Pmax" , Float64)
    d.bat_charge_effic    = PSRI.mapped_vector(data, "PSRBattery", "ChargeEffic", Float64)
    d.bat_discharge_effic = PSRI.mapped_vector(data, "PSRBattery", "DischargeEffic" , Float64)
    # d.bat_charge_ramp     = PSRI.mapped_vector(data, "PSRBattery", "ChargeRamp", Float64)
    # d.bat_discharge_ramp  = PSRI.mapped_vector(data, "PSRBattery", "DischargeRamp" , Float64)
    # d.bat_reg_time        = PSRI.mapped_vector(data, "PSRBattery", "RegTime", Int32)
    # d.bat_flag_inter_stage = PSRI.mapped_vector(data, "PSRBattery", "FlagInterStage" , Int32)
end


