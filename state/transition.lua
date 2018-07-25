-- transition.lua
-- The state handling hole transitions
-- Increments the hole number, and moves the player to the new tee.
local message  = require('state.message')
local class    = require('30log')
local transition  = class("TransitionScreen")

-- Perform transition to next hole
function transition:init(gstate)
    -- Set stroke count to zero
    gstate.stroke_count = 0
    -- Don't increment on first initialisation
    -- This is measured by checking the scorecard
    if #gstate.scorecard > 0 then
        gstate:increment_hole()
    else
        gstate.initialised = true
    end
end

function transition:tick(_) end
function transition:render(_) end

function transition:control(gstate)
    local hole = gstate:current_hole()
    if hole == nil then -- Game over
        gstate.terminate = true
        return true, true, nil
    else
        -- Move player to new starting point
        gstate:move(hole.tee)
        -- Print new hole message
        local msg = gstate:name() .. '\n'
        msg = msg .. "Hole ".. #gstate:get_scorecard() + 1 .. ", Par " .. #hole.opt_course
        return true, true, message(gstate, require('state.aim'), msg)
    end
end

return transition