--- clubs.lua
-- Information on the clubs in the game
local clubs = {}

clubs[1] = {prefix = "", name = "Putter", 	range = 5,  accuracy = 1, kind = "ground"}
clubs[2] = {prefix = "", name = "Wedge", 	range = 10, accuracy = 2, kind = "air"}
clubs[3] = {prefix = "", name = "Iron",  	range = 20, accuracy = 3, kind = "air"}
clubs[4] = {prefix = "", name = "Wood", 	range = 30, accuracy = 4, kind = "air"}
clubs[5] = {prefix = "", name = "Driver", 	range = 40, accuracy = 5, kind = "air"}

-- Bonuses/Penalties for certain terrain
clubs[1].tile_bonus = { Rough = -2,  Bunker  = -4,  Fairway = 2 } -- Putter
clubs[2].tile_bonus = { Rough = -2,  Bunker = -4  }               -- Wedge
clubs[3].tile_bonus = { Rough = -5,  Bunker = -10 }               -- Iron
clubs[4].tile_bonus = { Rough = -10, Bunker = -20 }               -- Wood
clubs[5].tile_bonus = { Rough = -15, Bunker = -35, Tee = 5}       -- Driver

-- Fetch the longest club name in the bag
function clubs.max_name()
    local max_name = 0
    for _,c in ipairs(clubs) do max_name = math.max(max_name, #c.name+#c.prefix+1) end
    return max_name
end

-- Get the range for using a club on a certain tile
function clubs.get_range(tile_name, club)
    local club_bonus = club.tile_bonus[tile_name]
    return club.range + (club_bonus ~= nil and club_bonus or 0)
end

return clubs
