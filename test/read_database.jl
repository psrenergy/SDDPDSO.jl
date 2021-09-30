println("Reading database...")

data = DSO.read_database(casepath; summarize=false);

n = DSO.Sizes();
DSO.set_dimensions!(data, n)

d = DSO.Data(n);
DSO.set_data!(data, n, d)

