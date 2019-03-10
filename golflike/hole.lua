--- hole.lua
-- The generation and verification of a hole for a golf course. This module
-- calls various hole `generators` stored in `mapgen`. Once a hole is
-- generated, a number of post-processing checks are performed here. If they
-- pass, the hole is printed to the representation in `map` and returned.
local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')
local pattern    = require('forma.pattern')
local cell       = require('forma.cell')
local log        = require('golflike.lib.log')
local map        = require('golflike.map')
local par        = require('golflike.par')
local mapgen     = require('golflike.mapgen')
local common     = require('golflike.common')
local hole     = {}

local generators = {
    links   = mapgen('Bunker'),
    classic = mapgen('Water'),
    forest  = mapgen('Tree'),
}


-- Generation statistics and reporting ------------------------
local generation_stats = {
    ntries = 0, -- Attempts at generating holes
    nfails = 0, -- Number of failed hole attempts
    reasons = {}
}

local function fail_gen(reason)
    generation_stats.nfails = generation_stats.nfails + 1
    local reasons = generation_stats.reasons
    if reasons[reason] == nil then
        reasons[reason] = 1
    else
        reasons[reason] = reasons[reason] + 1
    end
end

function hole.stats_report()
    local gs = generation_stats
    local report = log.debug
    report()
    report("Generation statistics")
    report(gs.ntries .. " attempts at hole generation")
    report(gs.nfails .. " failures at hole generation")
    report("Failure breakdown:")
    for k, v in pairs(gs.reasons) do
        report(k ..': '.. v)
    end
end
---------------------------------------------------------------
-- Check pattern specification for irregularities.
-- Checks a) That all specified patters correspond to map tiles
--        b) That there are no overlapping patterns
local function verify_patterns(patterns)
    for k,_ in pairs(patterns) do
        assert(map.dict[k] ~= nil, "Unrecognised pattern: " .. k )
    end
    for k,v in ipairs(map.tiles) do
        if patterns[v.name] ~= nil then
            for t=k+1,#map.tiles,1 do
                local tname = map.tiles[t].name
                local tpat = patterns[tname]
                if tpat ~= nil then
                    local inter = pattern.intersection(patterns[v.name], tpat)
                    assert(inter:size() == 0, "Element overlap " .. v.name .. " " .. tname)
                end
            end
        end
    end
    return true
end

--- Print a generated tile list to a `map` coordinate system
local function level_print(game, patterns)
    for k,v in pairs(patterns) do
        for _,p in pairs(v:cell_list()) do
            map.set(game, p.x, p.y, map.dict[k])
        end
    end
end

--- Find farthest two points in pattern
-- Can probably speed this up with triangle inequality
-- Maybe import to forma (something like forma.subpoints?)
-- @param ip input pattern
-- @param measure distance measure to use
local function max_separated_points(points, measure)
    assert(#points > 1, "max_separated_points requires at least two points")
    local mi, mj = -1, -1
    local maxdist = -1
    for i=1, #points-1, 1 do
        for j=i+1, #points, 1 do
            local dist = measure(points[i], points[j])
            if dist > maxdist then
                maxdist = dist
                mi, mj = i, j
            end
        end
    end
    return points[mi], points[mj]
end

-- Find locations for the hole and tee on the fairway
-- returns nil if no satisfactory location can be found
local function place_hole_tee(fairway)
    local segments = subpattern.bsp(fairway, 10)
    local candidates = {}
    for i=1, #segments, 1 do
        if segments[i]:size() > 3 then
            candidates[#candidates+1] = segments[i]:medoid()
        end
    end
    if #candidates < 2 then return nil end
    local p1, p2 = max_separated_points(candidates, cell.euclidean2)
    -- Can remove this if changing left-right is occasionally interesting
    if p1.x > p2.x then
        return p1, p2
    else
        return p2, p1
    end
end

--- Compute the optimal course for par determination
-- This function takes a patternspec, prints it to a map,
-- then plays that map in an optimal (A*) way.
-- If the map is solveable, this function returns the optimum path.
-- If not, it returns nil.
local function compute_par(patterns, target_hole, target_tee)
    --- Build blocking area
    -- Disallow the edges of all blocking patterns
    local blocking = pattern.new()
    for k,p in pairs(patterns) do
        local map_index = map.dict[k]
        if map.tiles[map_index].block.air == true then
            blocking = blocking + p:surface()
        end
    end

    -- Build available target area
    local available = patterns["Fairway"] + patterns["Hole"]

    -- Compute par
    -- If a hole cannot be found, or the par is > 8 then re-generate
    local opt_course = par.compute(available, blocking, target_tee, target_hole)
    if opt_course == nil then
        return fail_gen("A*-traversable")
    end
    if #opt_course < 4 then
        return fail_gen("Par too low")
    end
    if #opt_course > 8 then
        return fail_gen("Par too high")
    end
    -- Return optimal course
    return opt_course
end

-- This trims all blocking tiles that border the optimium course
-- ensuring that you don't have to make any 'trick shots' through
-- 1-wide openings in blocking tiles.
local function trim_blocking(patterns, opt_course)
    local trajectory = pattern.new()
    for i=1, #opt_course-1, 1 do
        local tbegin = opt_course[i]
        local tend   = opt_course[i+1]
        trajectory = trajectory + primitives.line(tbegin, tend)
    end

    -- Compute edge of trajectory
    trajectory = trajectory:edge()

    local blocking = pattern.new()
    for k,p in pairs(patterns) do
        local map_index = map.dict[k]
        if map.tiles[map_index].block.air == true then
            blocking = blocking + p:surface()
            patterns[k] = patterns[k] - trajectory
        end
    end

    -- Add rough tiles to locations where blocked tiles have been removed
    patterns["Rough"] = patterns["Rough"] + pattern.intersection(trajectory, blocking)
end

--- Compute locations for bonus items
-- If a course has fairway segments that are not used
-- in the computation of the par, put an item on it.
--TODO
local function add_items(patterns, opt_course)
--    local fairways = pattern.sum(patterns["Fairway"], patterns["Hole"], patterns["Tee"])
--    for _,v in ipairs(opt_course) do
--        local vcell = cell.new(v.x, v.y)
--        fairways = fairways - subpattern.floodfill(fairways, vcell)
--        if fairways:size() == 0 then return end
--    end
--
--    local segments = subpattern.segments(fairways)
--    local selected = segments[#segments]
    --local medoid = selected:medoid()
--    patterns["Item"] = pattern.new():insert(medoid.x, medoid.y)
--    patterns["Fairway"] = patterns["Fairway"] - patterns["Item"]
    return
end


--- Process a specification for a level.
-- Determines tee, hole locations and par, verifies that the specification is
-- acceptable and if so prints and returns a new map object. If any checks fail
-- this returns `nil`
function hole.process(patternSpec)
    -- Place hole and tee
    local target_hole, target_tee = place_hole_tee(patternSpec["Fairway"])
    if target_hole == nil then
        return fail_gen("Too few fairways")
    end

    -- Fail if map is too small
    if cell.euclidean(target_hole, target_tee) < 40 then
        return fail_gen("Map too short")
    end

    -- Manage hole and tee patterns
    patternSpec["Hole"] = pattern.new():insert(target_hole.x, target_hole.y)
    patternSpec["Tee"]  = pattern.new():insert(target_tee.x,  target_tee.y )
    patternSpec["Fairway"] = patternSpec["Fairway"] - ( patternSpec["Hole"] + patternSpec["Tee"] )

    -- Verify pattern integrity
    if verify_patterns(patternSpec) == false then
        assert("Fatal error, patterns unverifiable")
        return nil
    end

    -- Compute par
    local opt_course = compute_par(patternSpec, target_hole, target_tee)
    if opt_course == nil then return nil end

    -- Generate level and print to map
    local game = map.new(common.mapsize_x, common.mapsize_y)
    game.hole, game.tee = target_hole, target_tee
    game.opt_course = opt_course

    -- Trim back blocking tiles
    trim_blocking(patternSpec, game.opt_course)

    -- Add bonus items
    --add_items(patternSpec, opt_course)

    -- Print to level
    level_print(game, patternSpec)

    return game
end

-- Generate a new hole for a course
-- Picks a random map generator, generates a hole specification
-- in the form of a list of `forma.patterns` indexed by tile type.
-- If the specification passed processing, returns the new map,
-- otherwise returns `nil`.
function hole.new(rng, mapname)
    local generator = generators[mapname]
    generation_stats.ntries = generation_stats.ntries + 1
    local domain = primitives.square(common.mapsize_x, common.mapsize_y)
    local mapspec = generator(domain, rng)
    local new_map   = hole.process(mapspec)
    if new_map ~= nil then
        return map.finalise(new_map)
    else -- Mapgen failed
        return nil
    end
end

return hole
