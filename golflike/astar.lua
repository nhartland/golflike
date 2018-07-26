-- astar.lua
-- Basic implementation of a-star pathfinding
local pqueue = require('golflike.pqueue')
local astar = {}

-- A-star pathfinding ---------------------------------------------------------------------------

-- Convert vector to string hash
local function vector_hash(vector)
    return vector.x .. ":"..vector.y
end

-- Rebuilds the path
local function reconstruct_path(cameFrom, current)
    local total_path = {current}
    while true do
        current = cameFrom[vector_hash(current)]
        if current == nil then break end
        table.insert(total_path, current)
    end return total_path
end

--- Perform an a-star pathfind
-- @param start Position of origin (can be any 2D vector-like object)
-- @param goal Position of target (can be any 2D vector-like object)
-- @param dirs a function that returns the neighbours to a point used as it's argument
-- @param canMove a function that returns if it's possible to move and the move cost (target, source)
-- @param heuristic a function that returns the heuristic cost from a given cell to the target
function astar.search(start, goal, dirs, canMove, heuristic)
    local open_set = pqueue.new()
    local cameFrom  = {}
    local gScore    = {}
    pqueue.push(open_set, start, 0) gScore[vector_hash(start)] = 0

    while pqueue.isempty(open_set) == false do
        local current = pqueue.pop(open_set)
        if current == goal then return reconstruct_path(cameFrom, current) end
        local current_string = vector_hash(current)

        local neighbours = dirs(current)
        for i=1,#neighbours,1 do
            local neighbour = neighbours[i]
            local moveTest, moveCost = canMove(neighbour, current)
            if moveTest == true then
                local neighbour_string = vector_hash(neighbour)
                local new_gScore = gScore[current_string] + moveCost
                local old_gScore = gScore[neighbour_string]
                if old_gScore == nil or new_gScore < old_gScore then
                    local new_fScore = new_gScore + heuristic(goal, neighbour)
                    pqueue.push(open_set, neighbour, new_fScore)
                    gScore[neighbour_string]   = new_gScore
                    cameFrom[neighbour_string] = current
                end
            end
        end
    end
end

return astar
