--- random.lua
-- A wrapper for Ilya Kolbin's lcmwc.
-- Implements multiple RNG streams and provides a
-- closure-based interface that appears like math.random.
local cmwc = require('golflike.lib.cmwc')

local random = {
    generators = {}
}

-- Add a stream with `name` and `seed`
function random.add_generator(name, seed)
    assert(random.generators[name] == nil, "Collision with generator name")
    local state, index = cmwc.make(seed)
    random.generators[name] = {state = state, index = index}
end

-- Returns a function imitating math.random, for a given RNG `name`
function random.get_generator(name)
    local rng = random.generators[name]
    assert(rng~=nil, "No RNG found")
    return function(a, b)
        local retval, newstate, newindex =  cmwc.random32(rng.state, rng.index, a, b)
        rng.state = newstate
        rng.index = newindex
        return retval
    end
end

return random



