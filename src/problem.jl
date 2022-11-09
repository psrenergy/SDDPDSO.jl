function add_dso_flags!(par, x)
    par.flag_sec_law      = x.flag_sec_law      == 1
    par.flag_import       = x.flag_import       == 1
    par.flag_export       = x.flag_export       == 1
    par.flag_markov       = x.flag_markov       == 1
    par.flag_losses       = x.flag_losses       == 1
    par.flag_rd_active    = x.flag_rd_active    == 1
    par.flag_bat          = x.flag_bat          == 1
    par.flag_debug        = x.flag_debug        == 1
    par.flag_CSV          = x.flag_CSV          == 1
    par.flag_rd_integral  = x.flag_rd_integral  == 1
    par.flag_rd_incentive = x.flag_rd_incentive == 1
    par.flag_verbose      = par.flag_debug ? true : (x.flag_verbose == 1)
end

function add_sddp_parameters!(par, x, opt)
    par.stages        = x.stages
    par.sense         = :Min
    par.optimizer     = JuMP.optimizer_with_attributes(opt) #, "OUTPUTLOG" => 0)
    par.upper_bound   = 1e9
    par.lower_bound   = par.flag_export ? -1e9 : 0.0 
    par.def_cost      = x.deficit_cost
    par.demand_factor = x.demand_factor
    par.max_iter      = x.max_iter
    par.max_time      = x.max_time
end

function add_dimensions!(par, x, n)
    par.scenarios     = x.scenarios 
    par.sim_scenarios = x.sim_scenarios      
    par.nbat          = n.bat       
    par.ngen          = n.ther
    par.nsol          = n.gnd
    par.nelv          = 0       
    par.nbus          = n.bus       
    par.nlin          = n.cir
    par.nload         = n.load
    par.nstate        = x.markov_states 
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
    par.sol_scn = zeros(Float64, x.stages, x.scenarios, n.gnd) # [p.u.] : rooftop generation cenarios scn => [stg x plant]
    for i in 1:n.gnd
        par.sol_scn[:,:,i] .= gnd_scn[d.gnd_code[i]] .* d.gnd_capacity[i]
    end
end

function add_injections!(par, x, d)
    if par.flag_import
        # --- N2 is importing energy from N1 at cost $/MWh
        par.imp_max, par.imp_cost = import_injections(x, d, false)
    end

    if par.flag_export
        # --- N2 is expoting energy to N1 at cost $/MWh
        par.exp_max, par.exp_cost = import_injections(x, d, true)
    end
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
    par.losses = [zeros(Float64,x.stages) for i in 1:n.bus]
end

function add_demand_response!(par, x, n, d)
    par.dr_ub, par.dr_lb = get_demand_response_shift(x, n, d)
    par.dr_incentive     = get_demand_response_incentive(x, n, d)
end

function add_circuits!(par, d)
    par.cir_x      = d.cir_x
    par.cir_r      = d.cir_r
    par.cir_cap    = d.cir_capacity
    par.cir_bus_fr = d.cir_bus_from
    par.cir_bus_to = d.cir_bus_to
end

function add_markov!(par, x)
    par.markov_probabilities = import_dso_markov_probabilities(x)
    par.transition_matrices  = import_dso_markov_transitions(x)
end

function map_elements!(par, n, d)
    par.bus_map_sol = reverse_map_to_dict(d.gnd2bus, n.gnd) 
    par.bus_map_gen = reverse_map_to_dict(d.ter2bus, n.ther)
    par.bus_map_bat = reverse_map_to_dict(d.bat2bus, n.bat) 
    par.bus_map_elv = Dict()
    par.bus_map_dem = reverse_map_to_dict(d.lod2bus, n.load)

    if par.flag_rd_active
        par.bus_map_rsp = reverse_map_to_dict(d.lod2bus, n.load)
        for i in keys(par.bus_map_rsp)
            filter!(x -> x ∈ par.set_dem_rsp, par.bus_map_rsp[i])
            
            isempty(par.bus_map_rsp[i]) && delete!(par.bus_map_rsp, i) 
        end
    end

    if par.flag_import
        par.bus_map_imp = Dict(i => [d.bus_code[i]] for i in 1:n.bus if haskey(par.imp_max,d.bus_code[i]))    # mudar um dia, ta bem feio
    end

    if par.flag_export
        par.bus_map_exp = Dict(i => [d.bus_code[i]] for i in 1:n.bus if haskey(par.exp_max,d.bus_code[i]))    # mudar um dia, ta bem feio
    end
end

function filter_sets!(par)
    # set
    par.set_bus     = collect(1:par.nbus)
    par.set_cir     = collect(1:par.nlin)
    par.set_dem     = collect(1:par.nload)
    par.set_bat     = collect(1:par.nbat)
    par.set_gnd     = collect(1:par.nsol)
    par.set_ter     = collect(1:par.ngen)
    
    if par.flag_rd_active
        par.set_dem_rsp = Int64[i for i in 1:par.nload if any(par.dr_ub[:,i] .> 0.0)]
    end
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
    (par.nbat > 0) && (par.flag_bat) && add_batteries!(par, d)

    # diesel generator
    (par.ngen > 0) && add_thermal_plants!(par, d)

    # solar rooftop nbus => [stg x scn]
    (par.nsol > 0) && add_solar_plants!(par, x, n, d)

    # import/export energy form transmission grid
    (par.flag_import | par.flag_export) && add_injections!(par, x, d)

    # electric vehicles
    (par.nelv > 0) && add_electric_vehicles!(par, d)

    # demand
    (par.nload > 0) && add_demand!(par, x, n, d)

    # losses
    par.flag_losses && add_losses!(par, x, n, d)

    # demand response
    par.flag_rd_active && add_demand_response!(par, x, n, d)

    # circuit   
    (par.nlin > 0) && add_circuits!(par, d)

    # markov
    par.flag_markov && add_markov!(par,x)

    # filter necessary set
    filter_sets!(par)

    # map : bus => gen 
    # (must change loop to consider 1 -> N)
    map_elements!(par, n, d)
end

function get_gnd_scenarios(x, d)
    return import_renewable_generation_scenarios(x, d)
end

function get_load(x, d)
    return import_dso_hrload(x, d)
end

function get_demand_response_shift(x, n, d)
    # --- 
    ub = import_demand_response_shift(x, n, d, true)
    lb = import_demand_response_shift(x, n, d, false)

    # ---
    d.dr_ub, d.dr_lb = zeros(Float64, x.stages, n.load), zeros(Float64, x.stages, n.load)

    # ---
    for t in 1:x.stages, l in 1:n.load
        d.dr_ub[t,l] = ub[d.load_code[l]][t]
        d.dr_lb[t,l] = lb[d.load_code[l]][t]
    end

    return d.dr_ub, d.dr_lb
end

function get_demand_response_incentive(x, n, d)
    # --- 
    incetive = import_demand_response_incentive(x, n, d)

    # ---
    d.dr_incentive = zeros(Float64, x.stages, n.load)

    # ---
    for t in 1:x.stages, l in 1:n.load
        d.dr_incentive[t,l] = incetive[d.load_code[l]][t]
    end

    return d.dr_incentive
end

