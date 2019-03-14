--- geometry.lua
-- This module computes ball trajectories and aiming arcs
local primitives = require('forma.primitives')
local cell       = require('forma.cell')
local bresenham  = require('golflike.bresenham')
local clubs      = require('golflike.clubs')
local map        = require("golflike.map")
local geometry = {}

function geometry.compute_angle(vec, origin)
    return math.atan2(vec.y-origin.y, vec.x-origin.x)
end

-- Compute the arc of travel for a player, with a start position close to tvec
-- Compute an arc of points
function geometry.compute_arc(origin, range)
    -- Compute disc of cells in range of club
    local disc = primitives.circle(range):shift(origin.x, origin.y)
    -- Form a list of cells from the disc
    local arc = disc:cell_list()
    -- Sort possible targets by angle
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
function geometry.bresenham_trajectory(hole, club, origin, target)
    local trj = {}
    local block_point = math.huge
    local function push_point(x,y)
        trj[#trj+1] = cell.new(x,y)
        local tile = map.get(hole, x, y)
        -- Set the flag to identify where the trajectory is blocked
        if tile.block[club.kind] == true then
            block_point = math.min(block_point, #trj)
        end
    end
    local check = bresenham.line(origin, target, push_point)
    return trj, block_point
end

-- Computes the bezier trajectory between the origin and target, stopping on
-- hitting a blocking tile
function geometry.bezier_trajectory(hole, club, wind, origin, target)
    -- Find a control point half way between the target and the origin
    local vector = (target - origin)
    local nx = math.floor(vector.x / 3) -- 3 seems like a good number
    local ny = math.floor(vector.y / 3)
    local half_vector = cell.new(nx, ny)
    local control = origin + half_vector
    bezier = primitives.quad_bezier(origin, control, target+wind, 5)
    local trj = {}
    for np in bezier:cells() do
        trj[#trj+1] = np
        local tile = map.get(hole, np.x, np.y)
        local blocking = tile.block[club.kind]
        if blocking == true then
            return trj
        end
    end
    return trj
end

return geometry
