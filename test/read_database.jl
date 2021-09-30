println("Reading database...")

data = DSO.read_database(casepath; summarize=false);

n = DSO.Sizes();
DSO.set_dimensions!(data, n)

d = DSO.Data(n);
DSO.set_data!(data, n, d)

DSO.PSRI.get_name(data, "PSRBattery")
DSO.PSRI.get_code(data, "PSRBattery")
DSO.PSRI.mapped_vector(data, "PSRBattery", "Emin" , Float64)
DSO.PSRI.mapped_vector(data, "PSRBattery", "Emax" , Float64)
DSO.PSRI.mapped_vector(data, "PSRBattery", "Pmax" , Float64)
DSO.PSRI.mapped_vector(data, "PSRBattery", "ChargeEffic", Float64)
DSO.PSRI.mapped_vector(data, "PSRBattery", "DischargeEffic" , Float64)

# --- error
DSO.PSRI.mapped_vector(data, "PSRBattery", "Einic", Float64)
DSO.PSRI.mapped_vector(data, "PSRBattery", "ChargeRamp", Float64)
DSO.PSRI.mapped_vector(data, "PSRBattery", "DischargeRamp" , Float64)