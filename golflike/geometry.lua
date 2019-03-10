--- geometry.lua
-- This module computes ball trajectories and aiming arcs
local primitives = require('forma.primitives')
local cell       = require('forma.cell')
local bresenham  = require('golflike.bresenham')
local clubs      = require('golflike.clubs')
local map        = require("golflike.map")
local geometry = {}

-- Get the range for using a club at one point
local function get_club_range(hole, origin, club)
    local tile_name = map.get(hole, origin.x, origin.y).name
    return clubs.get_range(tile_name, club)
end

function geometry.compute_angle(vec, origin)
    return math.atan2(vec.y-origin.y, vec.x-origin.x)
end

-- Compute the arc of travel for a player, with a start position close to tvec
function geometry.compute_arc(hole, origin, club)
    -- Compute disc of cells in range of club
    local range = get_club_range(hole, origin, club)
    local disc = primitives.circle(range):shift(origin.x, origin.y)

    -- Loop through disc and find bresenham end-points of each shot
    local arc = {}
    local arc_angles = {}
    for np in disc:cells() do
        local trj = geometry.compute_trajectory(hole, club, origin, np)
        local angle = geometry.compute_angle(trj[#trj], origin)
        -- Check that the new element does not match in angle any existing elements
        local permissable = true
        for i=1,#arc_angles,1 do
            -- This might have to be made up to a certain precision, rather than a straight ==
            if arc_angles[i] == angle then
                permissable = false
                break
            end
        end
        if permissable == true then
            table.insert(arc, trj[#trj])
            table.insert(arc_angles, angle)
        end
    end
    -- Sort possible targets by angle to target
    table.sort(arc, function(a,b)
        return geometry.compute_angle(a,origin) < geometry.compute_angle(b,origin)
    end)
    return arc
end

-- Return the point on an arc which has an angle closest to target_angle
function geometry.get_arc_target(arc, origin, target_angle)
    -- Find closest target point
    local arc_target = 1
    local ga = geometry.compute_angle
    for i=1,#arc,1 do
        local test = math.abs(ga(arc[i], origin) - target_angle)
        local current = math.abs(ga(arc[arc_target], origin) - target_angle)
        if test < current then arc_target = i end
    end
    return arc_target
end

-- Computes a bresenham trajectory between the origin and target,
-- stopping on hitting a block or water (if using the putter)
function geometry.compute_trajectory(hole, club, origin, target)
    local trj = {}
    local function push_point(x,y)
        trj[#trj+1] = cell.new(x,y)
        local tile = map.get(hole, x, y)
        local blocking = tile.block[club.kind]
        return blocking == false
    end
    local check = bresenham.line(origin, target, push_point)
    return trj, check
end

return geometry
