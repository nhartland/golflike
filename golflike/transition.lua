-- transition.lua
-- The state handling hole transitions
-- Increments the hole number, and moves the player to the new tee.
local class    = require('30log')
local message  = require('golflike.message')
local transition  = class("TransitionScreen")

-- Perform transition to next hole
function transition:init(gstate)
    -- Set stroke count to zero
    gstate.stroke_count = 0
    -- Move to next hole
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
    -- If there is no current hole, the game is over
    if hole == nil then
        gstate.terminate = true
        return true, true, nil
    end
    -- If there is an active current hole, move player to new starting point
    gstate:move(hole.tee)
    -- Print new hole message
    local msg = gstate:name() .. '\n'
    msg = msg .. "Hole ".. #gstate:get_scorecard() + 1 .. ", Par " .. #hole.opt_course
    local aim = require('golflike.aim')
    return true, true, message(gstate, aim, msg)
end

return transition
