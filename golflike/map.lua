--- map.lua
-- This contains the basic representation of the map and tiles
local map = {}
local colour = require("golfterm.colour")

-- List of tiles in the game
-- Fields are mostly self-explanatory.
-- 'hazard' specified whether a ball should be lost if it lands on this tile.
-- 'block' specifies whether a (airbourne or grounded) ball is blocked by this tile.
map.tiles = {
    {name = "OOB",	   char = '#', hazard = true,  block = {air = true,  ground = true }, fg = colour.b_white, bg = colour.b_black},
    {name = "Tee", 	   char = 'T', hazard = false, block = {air = false, ground = false}, fg = colour.cyan,    bg = colour.b_green},
    {name = "Hole",    char = 'F', hazard = false, block = {air = false, ground = false}, fg = colour.b_white, bg = colour.b_black},
    {name = "Fairway", char = '.', hazard = false, block = {air = false, ground = false}, fg = colour.green,   bg = colour.b_green},
    {name = "Rough",   char = '"', hazard = false, block = {air = false, ground = false}, fg = colour.black,   bg = colour.green},
    {name = "Bunker",  char = ',', hazard = false, block = {air = false, ground = true }, fg = colour.yellow,  bg = colour.b_yellow},
    {name = "Water",   char = '~', hazard = true,  block = {air = false, ground = true }, fg = colour.white,   bg = colour.blue},
    {name = "Tree",    char = 'Y', hazard = true,  block = {air = true,  ground = true }, fg = colour.b_black, bg = colour.green},
}

-- Dictionary to map a tile name to a category
map.dict = {}
for k,v in ipairs(map.tiles) do
    map.dict[v.name] = k
end

-- Generate a new map object
function map.new(sx, sy)
    local newmap = {}
    newmap.coordinates = {}
    for i=0,sx-1,1 do
        newmap.coordinates[i] = {}
        for j = 0, sy-1, 1 do
            newmap.coordinates[i][j] = 0
        end
    end
    return newmap
end

-- Return the map.tiles entry corresponding to the point (x,y)
function map.get(m, x, y)
    if m.coordinates[x] == nil    then return map.tiles[1] end
    if m.coordinates[x][y] == nil then return map.tiles[1] end
    return map.tiles[m.coordinates[x][y]]
end

-- Set a map element to a specified tile type
function map.set(m, x, y, v)
    assert(map.tiles[v] ~= nil, "Attempting to add a unrecognised tile: " .. v)
    if m.coordinates[x] == nil then return false end
    if m.coordinates[x][y] == nil then return false end
    m.coordinates[x][y] = v return true
end

return map
