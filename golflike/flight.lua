-- flight.lua
-- State handling the flight of a ball
local class      = require('30log')
local score_hole = require('golflike.score_hole')
local message    = require('golflike.message')
local map        = require('golflike.map')
local draw       = require('golflike.draw')
local termio     = require('golfterm.io')
local flight     = class("flight")

function flight:init(startpos, trajectory, club)
    self.club         = club       -- Club used to initiate flight
    self.trajectory   = trajectory -- Flight trajectory
    self.trj_position = 1          -- Current point along the trajectory
    self.flight_end   = false      -- Flag to indicate when flight has finished
    self.hole_scored  = false      -- Flag to indicate a hole has been scored
    self.hazard       = false      -- Flag to indicate a hazard was encountered
    self.hazard_tile  = nil        -- Name of the tile of the encountered hazard
end

--- Next step in 'simulation'.
function flight:tick(gstate)
    -- Sleep for a bit to limit framerate
    termio.sleep(0.15)
    -- Handle empty trajectories
    if #self.trajectory == 0 then
        self.flight_end = true
        return
    end
    -- Move along trajectory
    if self.trj_position < #self.trajectory then
        self.trj_position = self.trj_position + 1
    end
    -- Update the location of the ball
    gstate:move(self.trajectory[self.trj_position])
    -- Check for hole or hazards
    local finished_flight = self.trj_position == #self.trajectory
    if (finished_flight or self.club.kind == "ground") then
        self.hazard      = self:handle_hazard(gstate)
        self.hole_scored = self:handle_hole(gstate)
        if finished_flight or self.hazard or self.hole_scored then
            self.flight_end = true
        end
    end
end

function flight:render(gstate)
    local hole = gstate:current_hole()
    assert(hole ~= nil, "flight:render encountered a nil map")
    if #self.trajectory > 0 then
        draw.trajectory (hole, self.trajectory, self.trj_position - 3, self.trj_position,  self.club.trchar)
    end
    draw.ball(hole, gstate:ball_position())
    draw.rightstatus("Ball in flight")
end

function flight:control(gstate)
    -- Flight not yet finished
    if self.flight_end  == false then
        return true, false, nil
    end
    -- Flight finished with hole scored
    if self.hole_scored == true then
        -- Move to score_hole state
        return true, true, score_hole(gstate)
    end
    -- Flight finished in hazard
    if self.hazard == true then
        -- Encountered a hazard
        local aim = require('golflike.aim')
        gstate:lose_ball() -- Ball lost to hazard
        local nballs = gstate:available_balls()
        if nballs == 0 then
            local msg = "GAME OVER\n No balls remaining"
            gstate.terminate = true
            return true, true, message(gstate, nil, msg)
        else
            local msg = "Ball Lost: " .. self.hazard_name .. " Hazard!\n" .. tostring(nballs)
            if nballs > 1 then msg = msg .. " balls remaining"
            else msg = msg .. " ball remaining" end
            return true, true, message(gstate, aim, msg)
        end
    end
    -- Flight finished normally
    local aim = require('golflike.aim')
    return true, true, aim(gstate)
end

-- Handle ball hazards (water/trees/OOB)
-- Maybe you shouldn't be able to putt into trees?
function flight:handle_hazard(gstate)
    local hole = gstate:current_hole()
    local trj, itrj = self.trajectory, self.trj_position
    -- Fetch current position and test for hazard
    local tile = map.get(hole, trj[itrj].x, trj[itrj].y)
    if tile.hazard == true then
        self.hazard_name = tile.name
        -- Rewind flight until no longer on a (ground) hazard
        while tile.hazard == true do
            itrj = itrj - 1
            tile = map.get(hole, trj[itrj].x, trj[itrj].y)
        end
        -- Reset trajectory position to the last safe location
        self.trj_position = itrj
        -- Update the location of the ball
        gstate:move(self.trajectory[self.trj_position])
        -- Penalize score by hazard
        gstate:increment_stroke_count()
        -- Return the hazard and it's name
        return true
    end
    return false
end

-- Handle scoring a hole!
function flight:handle_hole(gstate)
    local hole = gstate:current_hole()
    local loc = gstate:ball_position()
    local tile = map.get(hole, loc.x, loc.y)
    if tile.name == "Hole" then
        return true
    end
    return false
end

return flight
