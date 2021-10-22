println("Reading database...")

data = DSO.read_database(casepath; summarize=false);

x = DSO.Execution(casepath)

n = DSO.Sizes();
DSO.set_dimensions!(data, n)

d = DSO.Data(n);
DSO.set_data!(data, n, d)

DSO.set_maps!(data, d, n)