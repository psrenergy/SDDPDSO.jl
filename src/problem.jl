function add_dso_flags!(par, x)
    par.flag_sec_law = x.flag_sec_law == 1
    par.flag_import  = x.flag_import  == 1
    par.flag_export  = x.flag_export  == 1
    par.flag_markov  = x.flag_markov  == 1
    par.flag_losses  = false # x.flag_losses  == 1
    par.flag_dem_rsp = x.flag_dem_rsp == 1
end

function add_sddp_parameters!(par, x, opt)
    par.stages      = x.dso_stages
    par.sense       = :Min
    par.optimizer   = JuMP.optimizer_with_attributes(opt, "OUTPUTLOG" => 0)
    par.upper_bound = 1e7
    par.lower_bound = 0.0 
    par.def_cost    = x.deficit_cost
    par.demand_factor = x.demand_factor
end

function add_dimensions!(par, x, n)
    par.dso_scenarios   = x.dso_scenarios       
    par.nbat   = n.bat       
    par.ngen   = n.ther
    par.nsol   = n.gnd
    par.nelv   = 0       
    par.nbus   = n.bus       
    par.nlin   = n.cir
    par.nload  = n.load
    par.nstate = x.markov_states 
end

function add_batteries!(par, d)
    par.bat_e_ini = d.bat_Eini .* d.bat_Emax  
    par.bat_e_min = d.bat_Emin  
    par.bat_e_max = d.bat_Emax
    par.bat_c_eff = d.bat_charge_effic  
    par.bat_d_eff = d.bat_discharge_effic 
    par.bat_cap   = d.bat_Pmax   
end

function add_thermal_plants!(par, d)
    par.gen_cost = d.ter_cost # [$/MW]
    par.gen_cap  = d.ter_capacity  # [MW]
end

function add_solar_plants!(par, x, n, d)
    par.sol_cap = d.gnd_capacity                              # [MW]   : solar plant capacity
    gnd_scn = get_gnd_scenarios(x, d)                   # [p.u.] :
    par.sol_scn = zeros(Float64, x.dso_stages, x.dso_scenarios, n.gnd) # [p.u.] : rooftop generation cenarios scn => [stg x plant]
    for i in 1:n.gnd
        par.sol_scn[:,:,i] .= gnd_scn[d.gnd_code[i]] .* d.gnd_capacity[i]
    end
end

function add_injections!(par, x, d)
    hrinj_cst = import_dso_hrinj_cst(x, d)
    hrinj_cap = import_dso_hrinj_cap(x, d)

    # --- N2 is importing energy from N1 at cost $/MWh
    par.imp_cost = deepcopy(hrinj_cst)
    par.imp_max  = deepcopy(hrinj_cap)

    # --- N2 is expoting energy to N1 at cost $/MWh
    par.exp_cost = deepcopy(hrinj_cst)
    par.exp_max  = deepcopy(hrinj_cap)
end

function add_electric_vehicles!(par, d)
    par.elv_e_ini = []
    par.elv_e_max = []
    par.elv_cap   = []
    par.elv_c_hrs = []
    par.elv_c_eff = []
end

function add_demand!(par, x, n, d)
    loads = get_load(x, d)
    par.demand = [loads[d.load_code[i]] for i in 1:n.load]
end

function add_losses!(par, x, n, d)
    par.losses = [zeros(Float64,x.dso_stages) for i in 1:n.bus]
end

function add_demand_response!(par, x, n, d)
    par.dem_rsp_tariff = []
    par.dem_rsp_shift  = get_demand_response_shift(x, n, d) # d.dr_max_shift .* 0.2
end

function add_circuits!(par, d)
    par.cir_x      = d.cir_x
    par.cir_cap    = d.cir_capacity
    par.cir_bus_fr = d.cir_bus_from
    par.cir_bus_to = d.cir_bus_to
end

function add_markov!(par, x)
    par.markov_probabilities = import_dso_markov_probabilities(x)
    par.transition_matrices  = import_dso_markov_transitions(x)
end

function add_hrinj_attributes!(par, x, d)
    par.hrinj_cst = import_dso_hrinj_cst(x,d)
    par.hrinj_cap = import_dso_hrinj_cap(x, d)
end

function map_elements!(par, n, d)
    par.bus_map_sol = reverse_map_to_dict(d.gnd2bus, n.gnd) 
    par.bus_map_gen = reverse_map_to_dict(d.ter2bus, n.ther)
    par.bus_map_bat = reverse_map_to_dict(d.bat2bus, n.bat) 
    par.bus_map_elv = Dict()
    par.bus_map_dem = reverse_map_to_dict(d.lod2bus, n.load)
    par.bus_map_rsp = reverse_map_to_dict(d.lod2bus, n.load)
    par.bus_map_imp = Dict(i => [d.bus_code[i]] for i in 1:n.bus if haskey(par.imp_max,d.bus_code[i]))    # mudar um dia, ta bem feio
    par.bus_map_exp = Dict(i => [d.bus_code[i]] for i in 1:n.bus if haskey(par.imp_max,d.bus_code[i]))    # mudar um dia, ta bem feio
end

function setup_parameters!(par, x, n, d, opt)
    # initialize solver 
    # init_xpresspsr()

    # set up flags
    add_dso_flags!(par, x)

    # set up problem parameters
    add_sddp_parameters!(par, x, opt)

    # problem dimensions
    add_dimensions!(par, x, n)
    
    # problem variables 
    # batteries
    (par.nbat > 0) && add_batteries!(par, d)

    # diesel generator
    (par.ngen > 0) && add_thermal_plants!(par, d)

    # solar rooftop nbus => [stg x scn]
    (par.nsol > 0) && add_solar_plants!(par, x, n, d)

    # import/export energy form transmission grid
    (par.nload > 0) && add_injections!(par, x, d)

    # electric vehicles
    (par.nelv > 0) && add_electric_vehicles!(par, d)

    # demand
    (par.nload > 0) && add_demand!(par, x, n, d)

    # losses
    par.flag_losses && add_losses!(par, x, n, d)

    # demand response
    par.flag_dem_rsp && add_demand_response!(par, x, n, d)

    # circuit   
    (par.nlin > 0) && add_circuits!(par, d)

    # markov
    par.flag_markov && add_markov!(par,x)

    # hrinj attributes (cost and cap)
    par.flag_import && add_hrinj_attributes!(par, x, d)
    
    # map : bus => gen 
    # (must change loop to consider 1 -> N)
    map_elements!(par, n, d)
end

function get_gnd_scenarios(x, d)
    return import_dso_hrgnd_scn(x, d)
end

function get_load(x, d)
    return import_dso_hrload(x, d)
end

function get_demand_response_shift(x, n, d)
    shift = import_dso_dr_shift(x, d)

    d.dr_max_shift = zeros(Float64, n.load)

    for load in 1:n.load
        d.dr_max_shift[load] = shift[d.load_code[load]]
    end

    return d.dr_max_shift
end