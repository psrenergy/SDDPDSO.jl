generic = Generic();
thermal_generation    = generic:load("DSO_thermal_generation");
renewable_generation  = generic:load("DSO_renewable_generation");
renewable_curtailment = generic:load("DSO_renewable_curtailment");
battery_charge        = generic:load("DSO_battery_charge");
battery_discharge     = generic:load("DSO_battery_discharge");
battery_storage       = generic:load("DSO_battery_storage");
Bus_Marginal_Cost     = generic:load("DSO_bus_marginal_cost");
original_demand       = generic:load("DSO_original_demand");
cir_use               = generic:load("DSO_cirUse");
demand_response_load  = generic:load("DSO_demand_response_load");
demand_response       = generic:load("DSO_original_demand");


demand_response = demand_response:replace(demand_response_load)
demand_response_upper = generic:load("DSO_DR_UpperBound");
demand_response_lower = generic:load("DSO_DR_LowerBound");

average_losses  = generic:load("DSO_stage_average_losses");

thermal_cost  = generic:load("DSO_thermal_gen_cost");
imp_cost      = generic:load("DSO_imp_cost");
exp_cost      = generic:load("DSO_energy_export");

energy_imp      = generic:load("DSO_energy_import");
energy_exp      = generic:load("DSO_energy_export");

stage_objective = generic:load("DSO_stage_objective_function");

thermal_use =  generic:load("DSO_thermal_use");
imp_use     =  generic:load("DSO_imp_use");
exp_use     =  generic:load("DSO_exp_use");

convergence_data  = generic:load("DSO_convergence_data");

-- Model Convergence -- 
dashboard_Convergence = Dashboard("Convergence Data");
dashboard_Convergence:push("# convergence_data");
dashboard_Convergence:push("#### bla bla bla.");

chart = Chart("convergence");
chart:add_line(convergence_data:select_agents({"Simulation Value"}):aggregate_scenarios(BY_AVERAGE()), {color = "blue"});
chart:add_line(convergence_data:select_agents({"Lower Bound"}):aggregate_scenarios(BY_AVERAGE()), {color = "red"});

dashboard_Convergence:push(chart);

chart = Chart("% Difference");
chart:add_column(convergence_data:select_agents({"Difference (%)"}):aggregate_scenarios(BY_AVERAGE()), {color="blue"});
dashboard_Convergence:push(chart);

-- GENERATION -- 
dashboard_generation = Dashboard("Generation");

dashboard_generation:push("# Generation Dashboard");
dashboard_generation:push("#### bla bla bla.");

chart = Chart("Aggregated Generation");
bat_c = battery_charge:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(),    "Liquid Battery");
bat_d = battery_discharge:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Liquid Battery");
chart:add_area_stacking(bat_d - bat_c, {color="yellow"});
chart:add_area_stacking(thermal_generation:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Thermal"), {color="red"});
chart:add_area_stacking(renewable_generation:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Renewable"), {color="green"});
chart:add_line_stacking(demand_response:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Demand Response"), {color="black"});

import = energy_imp:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy");
export = energy_exp:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy");
chart:add_area_stacking(import - export, {color="blue"});

dashboard_generation:push(chart);

chart = Chart("Renewable Generation x Scenarios");
chart:add_column(renewable_generation:aggregate_stages(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Renewable Generation"), {color="blue"});
dashboard_generation:push(chart);

chart = Chart("Renewable Curtailment x Stages");
chart:add_column(renewable_curtailment:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Renewable Curtailment"), {color="blue"});
dashboard_generation:push(chart);


-- DEMAND RESPONSE -- 
dashboard_DR = Dashboard("Demand Response");

dashboard_DR:push("# Demand Response");
dashboard_DR:push("#### bla bla bla.");

chart = Chart("DemandResponse");
DR_upper = demand_response_upper:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Upper DR"), {color="yellow"};
DR_lower = demand_response_lower:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Lower DR"), {color="yellow"};
chart:add_area_range(DR_lower,DR_upper)
chart:add_line(original_demand:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Original Demand"), {color="blue"});
chart:add_line(demand_response:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Demand Response"), {color="black"});
dashboard_DR:push(chart);


-- Battery Operation -- 
dashboard_BatOperation = Dashboard("Battery Operation");
dashboard_BatOperation:push("# Battery Operation");
dashboard_BatOperation:push("#### bla bla bla.");

chart = Chart("Battery Operation");

chart:add_area_stacking(battery_storage:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Battery Storage"), {color="red"});
chart:add_line(demand_response:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Demand Response"), {color="blue"});
chart:add_line(renewable_generation:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Renewable Generation"), {color="green"});

dashboard_BatOperation:push(chart);

-- System use results -- 
dashboard_CircuitResult = Dashboard("System use");
dashboard_CircuitResult:push("# System use");
dashboard_CircuitResult:push("#### bla bla bla.");

chart = Chart("Thermal Avg Use x Stage");

chart:add_column(thermal_use:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Thermal Use"), {color="blue"});

dashboard_CircuitResult:push(chart);

chart = Chart("Cir Avg Use x Stage");
chart:add_column(cir_use:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Cir Use"), {color="blue"});
dashboard_CircuitResult:push(chart);

chart = Chart("Cir Avg Use x Scenarios");
chart:add_column(cir_use:aggregate_stages(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Cir Use"), {color="blue"});
dashboard_CircuitResult:push(chart);

-- chart = Chart("Energy Import Use x Stage");
-- chart:add_column(imp_use:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Import Use"), {color="blue"});
-- dashboard_CircuitResult:push(chart);

-- chart = Chart("Energy Export Use x Stage");
-- chart:add_column(exp_use:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Export Use"), {color="blue"});
-- dashboard_CircuitResult:push(chart);

-- Operation Costs -- 

dashboard_OpCosts = Dashboard("Operation Cost");
dashboard_OpCosts:push("# Operation Costs");
dashboard_OpCosts:push("#### bla bla bla.");

chart = Chart("Bus_Marginal_Cost x Stage");
chart:add_column(Bus_Marginal_Cost:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Marginal Cost"), {color="blue"});
dashboard_OpCosts:push(chart);

chart = Chart("Stage Objective");
chart:add_line(stage_objective:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_AVERAGE(), "Stage Objective"), {color="blue"});
dashboard_OpCosts:push(chart);

chart = Chart("Thermal + Imp/Exp x Stage");
chart:add_area_stacking(thermal_cost:aggregate_scenarios(BY_AVERAGE()):aggregate_blocks(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Thermal cost"), {color="red"});
import_cost = imp_cost:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy Cost");
export_cost = exp_cost:aggregate_scenarios(BY_AVERAGE()):aggregate_agents(BY_SUM(), "Interchange Energy Cost");
chart:add_area_stacking(import_cost - export_cost, {color="yellow"});
dashboard_OpCosts:push(chart);

-- Losses Results -- 
dashboard_Losses = Dashboard("Losses Results");
dashboard_Losses:push("# Losses Results");
dashboard_Losses:push("#### bla bla bla.");

chart = Chart("Average Losses (%)");

chart:add_column(average_losses:aggregate_scenarios(BY_AVERAGE()), {color="red"});

dashboard_Losses:push(chart);

-- Dashboards -- 

(dashboard_Convergence + dashboard_generation + dashboard_DR + dashboard_BatOperation + dashboard_CircuitResult + dashboard_OpCosts + dashboard_Losses):save("dashboard");



