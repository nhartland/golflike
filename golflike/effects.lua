-- effects.lua
-- Animation effects.
-- These are managed by an instance of an effects `layer`.
-- This layer stores a list of active effects and manages/updates them.
local log      = require('golflike.lib.log')
local class    = require('30log')
local elayer   = class("elayer")

local common     = require('golflike.common')
local map        = require('golflike.map')
local termio     = require('golfterm.io')
local pattern    = require('forma.pattern')
local subpattern = require('forma.subpattern')
local WaterShimmerEffect   = class("WaterShimmerEffect")

function WaterShimmerEffect:init(hole)
    self.water_tiles = pattern.new()
    for ix = 0, common.mapsize_x-1, 1 do
        for iy = 0, common.mapsize_y - 1, 1 do
            local tile = map.get(hole, ix, iy)
            if tile.name == "Water" then
                self.water_tiles:insert(ix, iy)
            end
        end
    end
    local nshimmer = math.floor(0.2*self.water_tiles:size())
    self.shimmer_tiles = subpattern.random(self.water_tiles, nshimmer)
    log.debug("Initialised WaterShimmerEffect")
    log.debug(self.water_tiles)
end

function WaterShimmerEffect:draw()
end

-- Generate a new effects layer for a hole
function elayer:init(hole)
    self.activeEffects = {
        WaterShimmerEffect(hole)
    }
end

function elayer:clock_tick(deltaT)
end

return elayer
