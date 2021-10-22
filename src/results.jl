function export_results(x, p, n, d, sims)
    
    CSV.write(
        joinpath(x.PATH,"results","cirflw.csv"),
        simulate_create_result_table(sims,:flw,d.cirName)
    )

    CSV.write(
        joinpath(x.PATH,"results","usecir.csv"),
        export_result_usecir(sims,d.cir_capacity,d.cirName)
    )

    CSV.write(
        joinpath(x.PATH,"results","diesel_generation.csv"),
        simulate_create_result_table(sims,:gen_die,d.ter_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","renewable_generation.csv"),
        simulate_create_result_table(sims,:gen_sol,d.gnd_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","renewable_curtailment.csv"),
        simulate_create_result_dif_table(sims,:gen_sol_max,:gen_sol,d.gnd_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","load_deficit.csv"),
        simulate_create_result_table(sims,:def,["def$i" for i in 1:n.load])
    )

    CSV.write(
        joinpath(x.PATH,"results","bus_curtailment.csv"),
        simulate_create_result_table(sims,:cur,["cur$i" for i in 1:n.bus])
    )

    CSV.write(
        joinpath(x.PATH,"results","battery_discharge.csv"),
        simulate_create_result_table(sims,:bat_d,d.gnd_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","battery_charge.csv"),
        simulate_create_result_table(sims,:bat_c,d.gnd_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","battery_storage.csv"),
        simulate_create_result_table_state_var(sims,:storage,d.gnd_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","demand_response_accumulated_load.csv"),
        simulate_create_result_table_state_var(sims,:total_load,d.bus_name[d.lod2bus])
    )

    CSV.write(
        joinpath(x.PATH,"results","demand_response_load.csv"),
        simulate_create_result_table(sims,:dr,d.bus_name[d.lod2bus])
    )

    CSV.write(
        joinpath(x.PATH,"results","demand_response_deficit.csv"),
        simulate_create_result_table(sims,:dr_def,d.bus_name[d.lod2bus])
    )

    CSV.write(
        joinpath(x.PATH,"results","demand_response_curtailment.csv"),
        simulate_create_result_table(sims,:dr_cur,d.bus_name[d.lod2bus])
    )

    CSV.write(
        joinpath(x.PATH,"results","energy_import.csv"),
        simulate_create_result_table(sims,:imp,d.bus_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","energy_export.csv"),
        simulate_create_result_table(sims,:exp,d.bus_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","energy_import_capacity.csv"),
        simulate_create_result_table(sims,:imp_max,d.bus_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","energy_export_capacity.csv"),
        simulate_create_result_table(sims,:exp_max,d.bus_name)
    )

    CSV.write(
        joinpath(x.PATH,"results","stage_objective_function_0.csv"),
        simulate_create_result_table(sims,:stage_objective,["stage_objective_function"])
    )
    
end