module SDDPDSO

    # --- packages
    using PSRClassesInterface
    using SDDP
    using JuMP
    using CSV
    using DataFrames
    using Statistics
    using PSRIO
    using Random

    const PSRI = PSRClassesInterface
    # using Statistics
    # using Libdl

    # --- version check
    @static if VERSION < v"1.6"
        error("Julia version $VERSION not supported by SDDP-DSO, upgrade to 1.6 or later")
    end

    # --- includes
    include("types.jl")
    include("io.jl")
    include("utils.jl")
    include("model.jl")
    include("deterministic.jl")
    include("stageobjective.jl")
    include("objective.jl")
    include("problem.jl")
    include("losses.jl")
    include("results.jl")
    include("statistics.jl")
    include("psrclasses.jl")
    include("report.jl")

    # --- main
    function main(ARGS)
        @show ARGS

        # psrio = PSRIO.create()

        # PSRIO.run(psrio, [joinpath(casepath,"results")], 
        # recipes=[raw".\deps\psrio-scripts\sddpdso\dashboard.lua"], 
        # model="none", 
        # verbose=3)
    end

    # --- run
    function run(casepath::String, solver)

        # ===================
        # 1. READING DATABASE
        # ===================
        println("Reading database")

        # --- initialize
        initialize(casepath)

        # --- reading database
        data = read_database(casepath; summarize=false);

        # --- execution parameters
        x = Execution(casepath)

        # --- setting dimensions
        n = Sizes();
        set_dimensions!(data, n)

        # --- setting data
        d = Data(n);
        set_maps!(data, n, d)
        set_data!(data, n, d)

        # --- setup_problem script
        par = Problem();
        setup_parameters!(par, x, n, d, solver)

        # --- write reports
        par.flag_debug && reports(x, n, d, par)



        # =========================
        # 2. PRE-CALCULATING LOSSES
        # =========================
        if par.flag_losses
            println("Estimating grid losses")
            
            # --- pre-calculate losses
            set_deterministic_losses!(par, x)
        end



        # ================
        # 3. RUNNING MODEL
        # ================
        println("Running model")

        # --- build sddp problem
        m = build_model(par)

        # --- export subproblems
        if par.flag_debug
            for i in 1:par.stages
                SDDP.write_subproblem_to_file(m[i], joinpath(casepath,"debug","subproblem_$i.lp"))
            end
        end

        # --- set seed
        Random.seed!(1111)

        # --- train model
        SDDP.train(m, iteration_limit = par.max_iter, log_file = joinpath(casepath,"debug","sddp-dso.log"))

        # --- simulate model
        vars = [:bus_ang,:flw,:gen_die,:gen_sol,:gen_sol_max,:bat_c,:bat_d,:storage,:def,:cur,:dr,:dr_def,:dr_cur,:total_load,:imp,:exp,:imp_max,:exp_max]

        sims = SDDP.simulate(
            m,
            5,
            custom_recorders = Dict{Symbol,Function}(
                :shadow_price => (sp::JuMP.Model) -> Float64[JuMP.dual(JuMP.constraint_by_name(sp,"energy_balance_$i")) for i in 1:par.nbus],
            ), 
            vars;
            skip_undefined_variables=true
        );



        # ==================
        # 4. WRITING RESULTS
        # ==================
        println("Writing results")

        clear_results(casepath)
        export_results(x, n, d, par, sims)



        # =====================
        # 5. WRITING DASHBOARD
        # =====================

        psrio = PSRIO.create()

        PSRIO.run(psrio, [joinpath(casepath,"results")], 
        recipes=[raw".\deps\psrio-scripts\sddpdso\dashboard.lua"], 
        model="none", 
        verbose=3)

        return x, par, m, sims
        
    end

    function set_deterministic_losses!(par, x)
        
        # REQUIRES UPDATE!
        par.flag_dem_rsp = false # falta implementar
        # 
        
        # --- build deterministic model
        m = build_deterministic_model(par)
        
        # --- export lp
        par.flag_debug && JuMP.write_to_file(m, joinpath(x.PATH,"debug","deterministic.lp"))
        
        # --- run deterministic model
        run_deterministic_model!(m, par)
        
        # --- set losses per bus
        par.losses = get_bus_losses_from_deterministc(par, m);

        # REQUIRES UPDATE!
        par.flag_dem_rsp = x.flag_dem_rsp == 1
        # 
    end

    # --- initialize
    function initialize(casepath::String)
        !isdir(joinpath(casepath,"debug"))   && mkdir(joinpath(casepath,"debug"))
        !isdir(joinpath(casepath,"reports")) && mkdir(joinpath(casepath,"reports"))
        !isdir(joinpath(casepath,"results")) && mkdir(joinpath(casepath,"results"))
    end
end # module
