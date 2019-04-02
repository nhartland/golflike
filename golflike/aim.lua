-- aim.lua
-- State element for aiming, this handles most of the gameplay interation.
local class      = require('30log')
local cell       = require('forma.cell')
local map        = require('golflike.map')
local draw       = require('golflike.draw')
local geometry   = require('golflike.geometry')
local clubs      = require('golflike.clubs')
local keymap     = require('golflike.keymap')
local termio     = require('golfterm.io')
local aim = class("Aim")

-- Fairly obvious
local wind_descriptions = {
    {name = "N",   angle = 0},
    {name = "NE",  angle = 1.0*math.pi/8.0},
    {name = "NNE", angle = 2.0*math.pi/8.0},
    {name = "ENE", angle = 3.0*math.pi/8.0},
    {name = "E",   angle = 4.0*math.pi/8.0},
    {name = "ESE", angle = 5.0*math.pi/8.0},
    {name = "SE",  angle = 6.0*math.pi/8.0},
    {name = "SSE", angle = 7.0*math.pi/8.0},
    {name = "S",   angle = 8.0*math.pi/8.0},
    {name = "SSW", angle = 9.0*math.pi/8.0},
    {name = "SW",  angle = 10.0*math.pi/8.0},
    {name = "WSW", angle = 11.0*math.pi/8.0},
    {name = "W",   angle = 12.0*math.pi/8.0},
    {name = "WNW", angle = 13.0*math.pi/8.0},
    {name = "NW",  angle = 14.0*math.pi/8.0},
    {name = "NNW", angle = 15.0*math.pi/8.0}
}

local wind_speeds = {
    {name = "Light",    strength = 1},
    {name = "Moderate", strength = 2},
    {name = "Strong",   strength = 3}
}

-- Get the range for using a club at one point
local function get_club_range(hole, origin, club)
    local tile_name = map.get(hole, origin.x, origin.y).name
    return clubs.get_range(tile_name, club)
end

function aim:init(gstate)
    self.arc = nil           -- The arc of different target positions possible with a club
    self.trj = nil           -- The bresenham trajectory from the ball to the target arc point
    self.trj_block = nil     -- The point along the trajectory intersecting a blocking object
    self.arc_target = nil    -- The index of `arc` which the player is currently targetting
    self.trj_target = nil    -- The point on the trajectory `trj` that the player is aiming at
    self.selected_club = 1   -- Currently selected club
    self.wind_speed  = math.random(#wind_speeds)       -- Current wind speed [1,3]
    self.wind_angle  = math.random(#wind_descriptions) -- Current wind direction (1, 16)
    self.display_par = false -- DEBUG toggles the display of the optimal route

    -- Select optimum target angle
    self.target_angle = geometry.compute_angle(gstate:current_hole().hole, gstate:ball_position())
    local tdistance = cell.euclidean(gstate:current_hole().hole, gstate:ball_position())
    -- Select optimum club
    while true do if self:next_club() == false then break end end
    repeat if self:current_club().range < tdistance then break end
    until self:prev_club() == false
end

-- Recompute (if necessary) aim arc, targets etc
-- This operates on a 'fall through' mechanism.
-- If the arc is deleted, then all quanitites are recomputed.
function aim:tick(gstate)
    local hole  = gstate:current_hole()
    local plpos = gstate:ball_position()
    local club  = self:current_club()
    local range = get_club_range(hole, plpos, club)
    if self.arc == nil then
        self.arc = geometry.compute_arc(plpos, range)
        self.arc_target = geometry.get_arc_target(self.arc, plpos, self.target_angle)
        self.trj = nil     -- Recompute trajectory
    end
    if self.trj == nil then
        self.trj, self.trj_block = geometry.bresenham_trajectory(hole, club, plpos, self.arc[self.arc_target])
        self.trj_target = #self.trj
    end
end

-- Render the aim target, trajectory and ball
function aim:render(gstate)
    local hole = gstate:current_hole()
    local club = self:current_club()

    -- Draw aiming UI elements
    --draw.trajectory(hole, self.trj, self.trj_block, self.trj_target, club.trchar)
    draw.trajectory(hole, self.trj, math.huge, self.trj_target, club.trchar)
    local actual = self:get_trajectory(gstate)
    draw.trajectory(hole, actual, 0, #actual, club.trchar)
    draw.ball      (hole, gstate:ball_position())

    -- UI
    draw.rightstatus("Press [?] for help")
    local wind_desc = wind_descriptions[self.wind_angle].name
    local wind_spd  = wind_speeds[self.wind_speed].name
    draw.windstatus(club, wind_desc, wind_spd)

    -- DEBUG
    -- If the flag is set, draw the 'optimal' trajectory points
    if self.display_par then
        for i=1,#hole.opt_course - 1, 1 do
            local st  = hole.opt_course[i]
            local fn  = hole.opt_course[i+1]
            local trj = geometry.bresenham_trajectory(hole, club, self.wind_vector, fn, st)
            draw.trajectory(hole, trj, #trj, #trj, '%')
        end
    end
end

-- Compute the final (wind-adjusted) trajectory for a shot
function aim:get_trajectory(gstate)
    -- Overall setup
    local hole  = gstate:current_hole()
    local club = self:current_club()
    -- Route to the target, taking into account the wind
    local plpos    = gstate:ball_position()        -- Current player position
    local target   = self.trj[self.trj_target]     -- Target position
    -- No sensitivity to wind if we're on the ground
    if club.kind == "ground" then
        local trajectory = {}
        for i=1, self.trj_target, 1 do
            table.insert(trajectory, self.trj[i])
        end
        return trajectory
    end
    local distance = cell.euclidean(plpos, target) -- Range to target
    -- Computation of wind effect
    local wind_radius = math.floor(math.log10(10.0*self.wind_speed)*(distance / 7))
    if wind_radius > 0 then
        local wind_arc    = geometry.compute_arc(cell.new(0,0), wind_radius)
        local wind_angle  = wind_descriptions[self.wind_angle].angle - math.pi / 2.0 -- Need to sort out this -pi/2
        local wind_vector = wind_arc[geometry.get_arc_target(wind_arc, cell.new(0,0), wind_angle)]
        return geometry.bezier_trajectory(hole, club, wind_vector, plpos, target)
    else
        return geometry.bezier_trajectory(hole, club, cell.new(0,0), plpos, target)
    end
end


-- Control aim state, given a game state this polls for input and changes aim
-- state accordingly
function aim:control(gstate)
    local hole  = gstate:current_hole()
    local club = self:current_club()

    -- Quit if 10 over par
    if gstate:get_stroke_count() - #hole.opt_course == 9 then
        gstate.terminate=true
        local message = require("golflike.message")
        local text = "GAME OVER\n Retiring +9 over par"
        return true, true, message(gstate, nil, text)
    end

    -- Poll for input
    local input = termio.getInput()

    if input == keymap.aim_right then
        self:handle_aim(gstate, 1)
        return true
    elseif input == keymap.aim_left then
        self:handle_aim(gstate, -1)
        return true
    elseif input == keymap.next_club then
        self:next_club() self.arc = nil
        return true
    elseif input == keymap.prev_club then
        self:prev_club() self.arc = nil
        return true
    elseif input == keymap.precise_up then
        self:handle_precise_aim(1)
        return true
    elseif input == keymap.precise_dn then
        self:handle_precise_aim(-1)
        return true
    elseif input == keymap.strike then
        gstate:increment_stroke_count()
        local trajectory = self:get_trajectory(gstate)
        local flight = require('golflike.flight')
        return true, true, flight(plpos, trajectory, club)
    elseif input == keymap.help then
        local help = require('golflike.help')
        return true, false, help(self:current_club())
    elseif input == keymap.exit_game then
        local exitconf = require('golflike.exitconf')
        return true, true, exitconf(gstate)
    end

    -- Current standings
    if input == keymap.standings then
        local competition  = require("golflike.competition")
        local message      = require("golflike.message")
        local text, tcolour = competition.get_standings_message(gstate:get_scorecard(),
                             gstate:get_rivals(), gstate:total_holes())
        return true, false, message(gstate, nil, text, tcolour, {keymap.standings})
    end

    -- Debug controls
    if input == keymap.debug_next  then
        local score_hole = require("golflike.score_hole")
        return true, true, score_hole(gstate)
    elseif input == keymap.debug_par then
        self.display_par = not self.display_par
        return true
    end

end

-- Aiming ---------------------------------------------------------------------

-- Changes current aim state either clockwise (aimvec=1) or anti-clockwise (aimvec=-1)
function aim:handle_aim(gstate, aimvec)
    self.trj = nil -- Recompute trajectory
    self.arc_target = self.arc_target + aimvec
    if self.arc_target > #self.arc then self.arc_target = 1  end
    if self.arc_target == 0 then self.arc_target = #self.arc end
    self.target_angle = geometry.compute_angle(self.arc[self.arc_target], gstate:ball_position())
end

-- Handles target along current trajectory (precise aiming)
function aim:handle_precise_aim(aimvec)
    self.trj_target = self.trj_target + aimvec
    self.trj_target = math.min(#self.trj, self.trj_target)
    self.trj_target = math.max(1, self.trj_target)
end

-- Club handling ---------------------------------------------------------------

-- Return currently selected club
function aim:current_club()
    return clubs[self.selected_club]
end

-- Move to the next club
function aim:next_club()
    self.selected_club = math.min(self.selected_club+1, #clubs)
    return self.selected_club ~= #clubs
end

-- Move to the previous club
function aim:prev_club()
    self.selected_club = math.max(self.selected_club-1,1)
    return self.selected_club ~= 1
end


return aim
