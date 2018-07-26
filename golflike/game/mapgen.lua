--- standard.lua
-- Standard map layout
-- Common to `classic` `links` and `forest`
local neighbourhood = require('forma.neighbourhood')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local cell          = require('forma.cell')

--- Pop-and-swap for unordered lists.
-- @param lst input list.
-- @param t target to be removed from list.
-- @return true if target is found and removed, false if not
local function popandswap(lst, t)
    for i=1,#lst,1 do
        if lst[i] == t then
            lst[i] = lst[#lst]
            lst[#lst] = nil
            return true
        end
    end
    return false
end

-- Performs a uniform sampling of the domain
local function uniform(seedfrac)
    return function(rng, domain)
    local desired_cells = math.max(1,math.floor(domain:size()*seedfrac))
    return subpattern.random(domain, desired_cells, rng)
    end
end

-- Perform sampling of domain with voronoi relaxation
-- This performs a voronoi tesselation of the domain,
-- sorts it by x centre-of-mass, then samples every other
-- segment uniformly.
-- The idea here is to gauruntee an even distribution of fairway
local function voronoi(seedfrac)
    -- (30,2) is very fast, but (20,3) is pretty good
    -- Measure probably not that important
    local n_segments = 20
    local sample_every = 3
    local measure = cell.manhattan
    return function(rng, domain)
    local seeds = subpattern.random(domain, n_segments, rng)
    -- Chunk level into voronoi segments - should probably floodfill first
    local segments, _, _  = subpattern.voronoi_relax(seeds, domain, measure, 5)
    table.sort(segments, function(a,b) return a:centroid().x < b:centroid().x end)
    -- Sample uniformly these segments
    local sample = uniform(seedfrac)(rng, segments[1] + segments[#segments])
    for i=2, #segments-1, sample_every do
       sample = sample + uniform(seedfrac)(rng, segments[i])
    end
    return sample
    end
end

-- Run the CA until either convergence or 20 iterations
local function cellular_automata(rng, domain, rulesig, sampling)
    local ruleset = {automata.rule(neighbourhood.moore(), rulesig)}
    local new_pat = sampling(rng, domain)
    local converged, iterations = false, 0
    repeat
        new_pat, converged = automata.iterate(new_pat, domain, ruleset)
        iterations = iterations + 1
    until converged == true or iterations > 20
    return new_pat
end


-- Generate a 'standard' map distribution from a base type
return function(base)
    -- Level generation requires a domain and an RNG table with signature as math.random
    return function(domain, rng)
        local patternSpec = {}

        local hazards = {"Water", "Tree", "Bunker"}
        assert(popandswap(hazards, base)) -- Remove base type from hazards
        local hazard1 = hazards[rng(#hazards)] assert(popandswap(hazards, hazard1))
        local hazard2 = hazards[rng(#hazards)] assert(popandswap(hazards, hazard2))

        patternSpec[base]      = domain
        patternSpec["Rough"]   = cellular_automata(rng, patternSpec[base], "B5678/S345678", uniform(0.5))

        local fairway_domain = patternSpec["Rough"] - patternSpec["Rough"]:surface()
        patternSpec["Fairway"] = cellular_automata(rng, fairway_domain, "B5678/S45678", voronoi(0.8))

        -- Clear double-counts
        patternSpec[base] = patternSpec[base] - patternSpec["Rough"]
        patternSpec["Rough"] = patternSpec["Rough"] - patternSpec["Fairway"]

        local domain1 = patternSpec["Rough"] - patternSpec["Rough"]:surface(neighbourhood.moore())
        patternSpec[hazard1] = cellular_automata(rng, domain1, "B678/S345678", uniform(0.4))
        patternSpec["Rough"] = patternSpec["Rough"] - patternSpec[hazard1]

        local domain2 = patternSpec["Rough"] - patternSpec["Rough"]:surface(neighbourhood.moore())
        patternSpec[hazard2] = cellular_automata(rng, domain2, "B5678/S345678", uniform(0.8))
        patternSpec["Rough"] = patternSpec["Rough"] - patternSpec[hazard2]

        return patternSpec
    end
end
