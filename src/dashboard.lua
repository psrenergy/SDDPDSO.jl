generic = Generic();
thermal_generation    = generic:load("DSO_thermal_generation");
renewable_generation  = generic:load("DSO_renewable_generation");
renewable_curtailment = generic:load("DSO_renewable_curtailment");
battery_charge        = generic:load("DSO_battery_charge");
battery_discharge     = generic:load("DSO_battery_discharge");
battery_storage       = generic:load("DSO_battery_storage");
Bus_Marginal_Cost     = generic:load("DSO_bus_marginal_cost");
original_demand       = generic:load("DSO_original_demand");
cir_use               = generic:load("DSO_cir_use");
demand_response_load  = generic:load("DSO_dr_load");
demand_original       = generic:load("DSO_original_demand");
demand_response       = demand_original:replace(demand_response_load);
demand_response_upper = generic:load("DSO_dr_upper_bound");
demand_response_lower = generic:load("DSO_dr_lower_bound");
average_losses        = generic:load("DSO_stage_average_losses");
thermal_cost          = generic:load("DSO_thermal_gen_cost");
imp_cost              = generic:load("DSO_energy_import_cost");
exp_cost              = generic:load("DSO_energy_export_cost");
energy_imp            = generic:load("DSO_energy_import");
energy_exp            = generic:load("DSO_energy_export");
stage_objective       = generic:load("DSO_stage_objective_function");
thermal_use           = generic:load("DSO_thermal_use");
imp_use               = generic:load("DSO_energy_import_use");
exp_use               = generic:load("DSO_energy_export_use");
convergence_data      = generic:load("DSO_convergence_data");

-- Model Convergence -- 
tab_convergence = Tab("Convergence Data");
tab_convergence:push("# Convergence Data");
tab_convergence:push("#### Graph 1");

chart = Chart("Simulation & Lower Bound x Iterations");
chart:add_line(convergence_data:set_stage_type(0):select_agents({"Simulation Value"}):aggregate_scenarios(BY_AVERAGE()),{xUnit="Iterations",color = "blue"});
chart:add_line(convergence_data:set_stage_type(0):select_agents({"Lower Bound"}):aggregate_scenarios(BY_AVERAGE()),{xUnit="Iterations",color = "red"});
tab_convergence:push(chart);

tab_convergence:push("#### Graph 2");
chart = Chart("Convergence (% Difference)");
chart:add_column(convergence_data:set_stage_type(0):select_agents({"Difference (%)"}):aggregate_scenarios(BY_AVERAGE()), {xUnit="Iterations",color="blue"});
tab_convergence:push(chart);

-- GENERATION -- 
tab_generation = Tab("Generation");
tab_generation:push("# Generation Dashboard");
tab_generation:push("#### Graph 1");

chart = Chart("Aggregated Generation");
bat_c = battery_charge:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(),    "Liquid Battery");
bat_d = battery_discharge:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Liquid Battery");
chart:add_area_stacking(bat_d - bat_c, {color="yellow"});
chart:add_area_stacking(thermal_generation:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Thermal"), {color="red"});
chart:add_area_stacking(renewable_generation:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Renewable"), {color="green"});

demand_response_values = demand_response:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Attended Demand")
demand_original_values = demand_original:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Demand")

if demand_response_values:loaded() then 
    chart:add_line_stacking(demand_response_values, {color="black"});
else
    chart:add_line_stacking(demand_original_values, {color="black"});
end

import = energy_imp:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy");
export = energy_exp:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy");

if export:loaded() then 
    if import:loaded() then 
        chart:add_area_stacking(import - export, {color="blue"});
    else
        chart:add_line_stacking(-export, {color="blue"});
    end
else
    if import:loaded() then 
        chart:add_area_stacking(import, {color="blue"});
    end
end

tab_generation:push(chart);

tab_generation:push("#### Graph 2");
chart = Chart("Renewable Generation x Scenarios");
chart:add_line(renewable_generation:aggregate_stages(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Renew. Gen."), {color="green"});
tab_generation:push(chart);

tab_generation:push("#### Graph 3");
chart = Chart("Renewable Curtailment x Stages");
chart:add_line(renewable_curtailment:aggregate_stages(BY_AVERAGE()):aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Renewable Curtailment"), {color="blue"});
tab_generation:push(chart);

-- DEMAND RESPONSE -- 
tab_DR = Tab("Demand Response");
tab_DR:push("# Demand Response Dashboard");
tab_DR:push("#### Graph 1");
chart = Chart("Demand Response x Stages");

DR_upper = demand_response_upper:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Upper DR");
DR_lower = demand_response_lower:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Lower DR");
chart:add_area_range(DR_upper,DR_lower);

if demand_response_load:loaded() then 
    chart:add_line(original_demand:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Original Demand"), {color="blue"});
end

chart:add_line(demand_response:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Attended Demand"), {color="black"});
tab_DR:push(chart);

-- Battery Operation -- 
tab_BatOperation = Tab("Battery Operation");
tab_BatOperation:push("# Battery Operation Dashboard");
tab_BatOperation:push("#### Graph 1");

chart = Chart("Battery Operation");
chart:add_area_stacking(battery_storage:aggregate_scenarios(BY_AVERAGE()):aggregate_stages(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Battery Storage"), {color="red"});
tab_BatOperation:push(chart);

-- System use results -- 
tab_CircuitResult = Tab("System Use");
tab_CircuitResult:push("# System Use Dashboard");
tab_CircuitResult:push("#### Graph 1");

chart = Chart("Thermal Avg Use x Stage");
chart:add_column(thermal_use:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Thermal Use"), {color="blue"});
tab_CircuitResult:push(chart);

tab_CircuitResult:push("#### Graph 2");
chart = Chart("Cir Avg Use x Stage");
chart:add_column(cir_use:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Cir Use"), {color="blue"});
tab_CircuitResult:push(chart);

-- Operation Costs -- 
tab_OpCosts = Tab("Operation Cost");
tab_OpCosts:push("# Operation Costs Dashboard");
tab_OpCosts:push("#### Graph 1");

chart = Chart("Bus Marginal Cost x Stages");
chart:add_column(Bus_Marginal_Cost:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Bus Marginal Cost"), {color="blue"});
tab_OpCosts:push(chart);

tab_OpCosts:push("#### Graph 2");
chart = Chart("Operational Costs x Stages");
chart:add_area_stacking(thermal_cost:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Thermal cost"), {color="red"});
import_cost = imp_cost:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy Cost");
export_cost = exp_cost:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy Cost");

if export_cost:loaded() then 
    if import_cost:loaded() then
        chart:add_area_stacking(import_cost - export_cost, {color="yellow"});
    else
        chart:add_area_stacking(-export_cost, {color="yellow"});
    end
else
    if import_cost:loaded() then
        chart:add_area_stacking(import_cost, {color="yellow"});
    end
end

-- chesf
-- if export_cost:loaded() then 
--     chart:add_area_stacking(import_cost - export_cost, {color="yellow"});
-- else
--     chart:add_area_stacking(import_cost, {color="yellow"});
-- end


chart:add_line(stage_objective:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Stage Objective"), {color="black"});

tab_OpCosts:push(chart);

-- Losses Results -- 
tab_Losses = Tab("Losses");
tab_Losses:push("# Losses Dashboard");
tab_Losses:push("#### Graph 1");

chart = Chart("Average Losses (%)");
chart:add_column(average_losses:aggregate_scenarios(BY_AVERAGE()), {color="red"});
tab_Losses:push(chart);

-- Dashboard -- 

-- Dashboard initialize
DSO_dashboard = Dashboard();

DSO_dashboard:push(tab_convergence);
DSO_dashboard:push(tab_generation);
DSO_dashboard:push(tab_DR);
DSO_dashboard:push(tab_BatOperation);
DSO_dashboard:push(tab_CircuitResult);
DSO_dashboard:push(tab_OpCosts);
DSO_dashboard:push(tab_Losses);
DSO_dashboard:save("DSO_Dashboard");