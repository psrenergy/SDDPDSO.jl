mutable struct Battery
    id    :: Int64
    name  :: String
    e_ini :: Float64
    e_min :: Float64
    e_max :: Float64
    c_eff :: Float64
    d_eff :: Float64
    p_max :: Float64
    Battery() = new()
end

mutable struct Renewable
    id    :: Int64
    name  :: String
    p_max :: Float64
    Renewable() = new()
end

mutable struct Thermal
    id    :: Int64
    name  :: String
    p_max :: Float64
    cost  :: Float64
    Thermal() = new()
end

mutable struct Circuit
    id     :: Int64
    name   :: String
    x      :: Float64
    r      :: Float64
    p_max  :: Float64
    bus_fr :: Int64
    bus_to :: Int64
    Circuit() = new()
end