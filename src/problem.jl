function add_sddp_parameters!(par, x, opt)
    par.stages      = x.NSTG
    par.sense       = :Min
    par.optimizer   = JuMP.optimizer_with_attributes(opt, "OUTPUTLOG" => 0)
    par.upper_bound = 1e7
    par.lower_bound = 0.0 
    par.def_cost    = x.DEFC
    par.demand_factor = x.DFACT
end

function add_dimensions!(par, x, n)
    par.nscn   = x.NSCN       
    par.nbat   = n.bat       
    par.ngen   = n.ther
    par.nsol   = n.gnd
    par.nelv   = 0       
    par.nbus   = n.bus       
    par.nlin   = n.cir
    par.nload  = n.load
    par.nstate = x.NSTT 
end

function add_batteries!(par, d)
    par.bat_e_ini = d.batEinic .* d.batEmax  
    par.bat_e_min = d.batEmin  
    par.bat_e_max = d.batEmax
    par.bat_c_eff = d.batChargeEffic  
    par.bat_d_eff = d.batDischargeEffic 
    par.bat_cap   = d.batPmax   
end

function add_thermal_plants!(par, d)
    par.gen_cost = d.therCost # [$/MW]
    par.gen_cap  = d.therPot  # [MW]
end

function add_solar_plants!(par, x, n, d)
    par.sol_cap = d.gndPot                              # [MW]   : solar plant capacity
    gnd_scn = get_gnd_scenarios(x, d)                   # [p.u.] :
    par.sol_scn = zeros(Float64, x.NSTG, x.NSCN, n.gnd) # [p.u.] : rooftop generation cenarios scn => [stg x plant]
    for i in 1:n.gnd
        par.sol_scn[:,:,i] .= gnd_scn[d.gndCode[i]] .* d.gndPot[i]
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
    par.demand = [loads[d.loadCode[i]] for i in 1:n.load]
end

function add_losses!(par, x, n, d)
    par.losses = [zeros(Float64,x.NSTG) for i in 1:n.bus]
end

function add_demand_response!(par, x, n, d)
    par.dem_rsp_tariff = []
    par.dem_rsp_shift  = get_demand_response_shift(x, n, d) # d.dr_max_shift .* 0.2
end

function add_circuits!(par, d)
    par.cir_x      = d.cirX
    par.cir_cap    = d.cirRn
    par.cir_bus_fr = d.cirBusFrom
    par.cir_bus_to = d.cirBusTo
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
    par.bus_map_sol = Dict(d.bus2gnd[i]  => [i] for i in 1:n.gnd ) # swap bus
    par.bus_map_gen = Dict(d.bus2ther[i] => [i] for i in 1:n.ther) # swap bus
    par.bus_map_bat = Dict(d.bat2bus[i]  => [i] for i in 1:n.bat )
    par.bus_map_elv = Dict()
    par.bus_map_dem = Dict(d.load2bus[i] => [i] for i in 1:n.load)
    par.bus_map_rsp = Dict(d.load2bus[i] => [i] for i in 1:n.load)
    par.bus_map_imp = Dict(i => [d.busCode[i]] for i in 1:n.bus if haskey(par.imp_max,d.busCode[i]))    # mudar um dia, ta bem feio
    par.bus_map_exp = Dict(i => [d.busCode[i]] for i in 1:n.bus if haskey(par.imp_max,d.busCode[i]))    # mudar um dia, ta bem feio
end

function setup_parameters!(par, x, p, n, d, opt)
    # initialize solver 
    init_xpresspsr()

    # set up problem parameters
    add_sddp_parameters!(par, x, opt)

    # add flags
    par.use_cir_cap = true

    # problem dimensions
    add_dimensions!(par, x, n)   

    # problem variables 
    # batteries
    add_batteries!(par, d)

    # diesel generator
    add_thermal_plants!(par, d)

    # solar rooftop nbus => [stg x scn]
    add_solar_plants!(par, x, n, d)

    # import/export energy form transmission grid
    add_injections!(par, x, d)

    # electric vehicles
    add_electric_vehicles!(par, d)

    # demand
    add_demand!(par, x, n, d)

    # losses
    add_losses!(par, x, n, d)

    # demand response
    add_demand_response!(par, x, n, d)

    # circuit
    add_circuits!(par, d)

    # markov
    x.RMKV && add_markov!(par,x)

    # hrinj attributes (cost and cap)
    add_hrinj_attributes!(par, x, d)
    
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
    shift = SDDPMicrogrid.import_dso_dr_shift(x, d)

    for load in 1:n.load
        # d.dr_max_shift[load] = shift[d.load2bus[load]]
        d.dr_max_shift[load] = shift[d.loadCode[load]]
    end

    return d.dr_max_shift
end