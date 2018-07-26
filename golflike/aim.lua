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

function aim:init(gstate)
    self.arc = nil           -- The arc of different target positions possible with a club
    self.trj = nil           -- The bresenham trajectory from the ball to the target arc point
    self.arc_target = nil    -- The index of `arc` which the player is currently targetting
    self.trj_target = nil    -- The point on the trajectory `trj` that the player is aiming at
    self.targets = nil       -- The possible final locations for the ball to land
    self.path_targets = nil  -- The list of `targets` where there is a line of sight
    self.hazardfraction = 0  -- The fraction of targets that are hazardous
    self.selected_club = 1   -- Currently selected club
    self.display_par = false -- DEBUG toggles the display of the optimal route

    -- Select optimum target angle
    self.target_angle = geometry.compute_angle(gstate:current_hole().hole, gstate:ball_position())
    local tdistance = cell.euclidean(gstate:current_hole().hole, gstate:ball_position())
    -- Select optimum club
    while true do if self:next_club() == false then break end end
    repeat if self:current_club().range < tdistance then break end
    until self:prev_club() == false
end

--- Compute the fraction of a list of targets that are hazardous
local function compute_hazard_fraction(targets, hole)
    local count = 0
    for i=1,#targets,1 do
        local tpt = targets[i]
        local tile = map.get(hole, tpt.x, tpt.y)
        if tile.hazard == true then
            count = count + 1
        end
    end
    return count / #targets
end

-- Recompute (if necessary) aim arc, targets etc
-- This operates on a 'fall through' mechanism.
-- If the arc is deleted, then all quanitites are recomputed.
function aim:tick(gstate)
    local hole  = gstate:current_hole()
    local plpos = gstate:ball_position()
    local club  = self:current_club()
    if self.arc == nil then
        self.arc = geometry.compute_arc(hole, plpos, club)
        self.arc_target = geometry.get_arc_target(self.arc, plpos, self.target_angle)
        self.trj = nil     -- Recompute trajectory
    end
    if self.trj == nil then
        self.trj = geometry.compute_trajectory(hole, club, plpos, self.arc[self.arc_target])
        self.trj_target = #self.trj
        self.targets = nil -- Recompute targets
    end
    if self.targets == nil then
        self.targets = geometry.compute_targets(self.trj[self.trj_target], club.accuracy)
        self.path_targets = geometry.compute_pathable_targets(hole, club, plpos, self.targets)
        self.hazardfraction = compute_hazard_fraction(self.path_targets, hole)
    end
end

-- Render the aim target, trajectory and ball
function aim:render(gstate)
    local hole = gstate:current_hole()
    local club = self:current_club()

    -- Draw aiming UI elements
    --draw.target      (hole, self.path_targets)
    draw.trajectory  (hole, self.trj)
    draw.target      (hole, self.targets)
    draw.ball        (hole, gstate:ball_position())

    -- UI
    draw.rightstatus("Press [?] for help")
    draw.hazardstatus(club, self.hazardfraction)

    -- DEBUG
    -- If the flag is set, draw the 'optimal' trajectory points
    if self.display_par then
        for i=1,#hole.opt_course - 1, 1 do
            local st  = hole.opt_course[i]
            local fn  = hole.opt_course[i+1]
            local trj = geometry.compute_trajectory(hole, club, fn, st)
            draw.trajectory(hole, trj)
        end
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
        -- Pick a random target from the list of options and route to it
        local target     = self.path_targets[math.random(#self.targets)]
        local trajectory = geometry.compute_trajectory(hole, club, gstate:ball_position(), target)
        gstate:increment_stroke_count()
        local flight = require('golflike.flight')
        return true, true, flight(gstate:ball_position(), trajectory, club)
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
    self.targets = nil -- Reset targets
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
