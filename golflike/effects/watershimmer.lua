-- watershimmer.lua
-- Animation of water shimmering.
local class    = require('30log')
local colour     = require('golfterm.colour')
local common     = require('golflike.common')
local map        = require('golflike.map')
local draw       = require('golflike.draw')
local pattern    = require('forma.pattern')
local subpattern = require('forma.subpattern')
local WaterShimmer = class("WaterShimmerEffect")

function WaterShimmer:init(hole)
    self.water_tiles = pattern.new()
    for ix = 0, common.mapsize_x-1, 1 do
        for iy = 0, common.mapsize_y - 1, 1 do
            local tile = map.get(hole, ix, iy)
            if tile.name == "Water" then
                self.water_tiles:insert(ix, iy)
            end
        end
    end
    local nshimmer = math.ceil(0.4*self.water_tiles:size())
    self.shimmer_tiles = subpattern.random(self.water_tiles, nshimmer)
end

function WaterShimmer:draw()
    for ix, iy in self.shimmer_tiles:cell_coordinates() do
        draw.to_map(ix, iy, '~', colour.white, colour.blue)
    end
end

function WaterShimmer:tick()
    local non_shimmer = self.water_tiles - self.shimmer_tiles
    local n_add  = math.random(math.ceil(0.1*non_shimmer:size()))
    local n_rem  = math.random(math.ceil(0.1*self.shimmer_tiles:size()))
    if n_add > 0 then
        self.shimmer_tiles = self.shimmer_tiles + subpattern.random(non_shimmer, n_add)
    end
    if n_rem > 0 then
        self.shimmer_tiles = self.shimmer_tiles - subpattern.random(self.shimmer_tiles, n_rem)
    end
end

return WaterShimmer
