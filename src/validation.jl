"""
    validate
"""
function validate()
    return true
end

"""
    validate
"""
function validate(element::Battery)
    ok = true

    if element.p_max < 0.0
        println("warning: installed capacity bellow 0.0")
        element.p_max = 0.0
    end

    if element.e_max <= 0.0
        println("warning: maximum storage capacity less or equato to 0.0")
        element.e_max = 0.0
        ok = false
    end

    return ok
end

"""
    validate
"""
function validate(element::Thermal)
    ok = true

    if element.p_max < 0.0
        println("warning: installed capacity bellow 0.0")
        element.p_max = 0.0
    end

    return ok
end

"""
    validate
"""
function validate(element::Renewable)
    ok = true

    if element.p_max < 0.0
        println("warning: installed capacity bellow 0.0")
        element.p_max = 0.0
    end

    return ok
end


"""
    validate
"""
function validate(element::Circuit)
    ok = true

    if abs(element.x) <= MIN_X
        println("warning: circuit reactance bellow 0.05")
        element.x = (element.x < 0.0) ? -MIN_X : MIN_X
    end

    if element.r < MIN_R
        println("warning: circuit resistance bellow 0.0")
        element.r = MIN_R
    end

    return ok
end

"""
    validate
"""
function validate(element::Circuit, case::Problem)
    # ---
    ok = validate(element)

    # ---
    ok = (ok) bus_exists(element.bus_fr, case)
    ok = (ok) bus_exists(element.bus_fr, case)

    return ok
end

"""
    bus_exists
"""
function bus_exists(bus::Int64, case::Problem)
    return bus <= case.nbus
end