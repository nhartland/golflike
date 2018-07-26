--- par.lua
-- Determination of par
local path = (...):match("(.-)[^%.]+$")
local bresenham = require('alg.bresenham')
local astar	    = require('alg.astar')
local cell   	= require('forma.cell')
local clubs  	= require(path..'clubs')
local par = {}

-- Scans all locations that can be made with the wood club from the origin.
-- Only points in the `available` pattern are considered targets.
-- The `blocking` pattern defines what cells should block the trajectory.
local function compute_all_options(available, blocking)
    return function(origin)
        -- Bresenham passable check
        local function passable(x,y)
            return not blocking:has_cell(x,y)
        end
        local opt = {}
        local club = clubs[#clubs-1]
        for icell in available:cells() do
            if cell.euclidean2(icell, origin) < club.range*club.range then
                local pass = bresenham.line(origin, icell, passable)
                if pass then opt[#opt+1] = icell end
            end
        end
        return opt
    end
end

-- Computes par for the hole
-- Determined by Astar search of an optimal player armed with maximally a wood club
function par.compute(available, blocking, start, goal)
    assert(start and goal, "Incomplete map")
    local neighbours = compute_all_options(available, blocking)
    local function cost() return true,1 end -- Maybe add distance of shot as a cost here?
    local function heuristic() return 0 end -- Dijkstras algorithm is fine, better heuristics don't save time
    local route = astar.search(start, goal, neighbours, cost, heuristic)
    return route
end

return par
