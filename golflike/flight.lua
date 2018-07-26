-- flight.lua
-- State handling the flight of a ball
local score_hole = require('golflike.score_hole')
local message    = require('golflike.message')
local map        = require('golflike.map')
local draw       = require('golflike.draw')
local termio     = require('term.io')
local class      = require('30log')
local flight     = class("flight")

function flight:init(startpos, trajectory, club)
    self.club         = club       -- Club used to initiate flight
    self.trajectory   = trajectory -- Flight trajectory
    self.path_history = {startpos} -- Elapsed trajectory
    self.hole_scored  = false      -- Flag for scoring a hole
    self.hazard       = false      -- Flag for a encountering a hazard
    self.hazard_tile  = nil        -- Name of the tile of encountered hazard
end

--- Next step in 'simulation'.
function flight:tick(gstate)
    -- Sleep for a bit to limit framerate
    termio.sleep(0.15)
    -- Move along trajectory
    if #self.trajectory > 0 then
        gstate:move(self.trajectory[1])
        table.remove(self.trajectory, 1)
    end
    -- Push onto path history
    table.insert(self.path_history, gstate:ball_position())
    -- Check for hole or hazards
    if (#self.trajectory == 0 or self.club.kind == "ground") then
    -- Check for hazard
        self:handle_hazard(gstate)
        self:handle_hole(gstate)
    end
end

function flight:render(gstate)
    local hole = gstate:current_hole()
    assert(hole ~= nil, "flight:render encountered a nil map")
    draw.trajectory (hole, self.path_history)
    draw.ball(hole, gstate:ball_position())
    draw.rightstatus("Ball in flight")
end

function flight:control(gstate)
    if #self.trajectory  ~= 0 then
        -- Still more trajectory to go
        return true, false, nil
    end
    if self.hole_scored == true then
        -- Move to score_hole state
        return true, true, score_hole(gstate)
    elseif self.hazard == true then
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
    else
        -- If we've landed, return to aiming
        local aim = require('golflike.aim')
        return true, true, aim(gstate)
    end
end

-- Handle ball hazards (water/trees/OOB)
-- Maybe you shouldn't be able to putt into trees?
function flight:handle_hazard(gstate)
    local hole = gstate:current_hole()
    local trj, itrj = self.path_history, #self.path_history
    -- Fetch current position and test for hazard
    local tile = map.get(hole, trj[itrj].x, trj[itrj].y)
    if tile.hazard == true then
        self.hazard_name = tile.name
        self.hazard = true
        -- Rewind flight until no longer on a (ground) hazard
        while tile.hazard == true do
            itrj = itrj - 1
            tile = map.get(hole, trj[itrj].x, trj[itrj].y)
        end
        -- Move to previous safe location
        self.trajectory = {}
        gstate:move(trj[itrj])
        gstate:increment_stroke_count()
    end
end

-- Handle scoring a hole!
function flight:handle_hole(gstate)
    local hole = gstate:current_hole()
    local loc = gstate:ball_position()
    local tile = map.get(hole, loc.x, loc.y)
    if tile.name == "Hole" then
        self.trajectory = {}
        self.hole_scored = true
        return true
    end
    return false
end

return flight
