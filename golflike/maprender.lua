-- maprender.lua
-- This class renders the map and statuslines to screen.
local class  = require('30log')
local common = require('golflike.common')
local termio = require('golfterm.io')
local map    = require('golflike.map')
local aim    = require('golflike.aim')
local draw   = require('golflike.draw')
local maprender = class("maprender")

function maprender:init() end
function maprender:tick(_) end

function maprender:render(gstate)
    local hole    = gstate:current_hole()
    if hole == nil then return end -- Game finished
    if gstate.initialised == false then return end -- Game not loaded yet
    -- Draw the map
    for ix = 0, common.mapsize_x-1, 1 do
        for iy = 0, common.mapsize_y - 1, 1 do
            local tile = map.get(hole, ix, iy)
            if tile ~= map.tiles[0] then
                local fg, bg = tile.fg, tile.bg
                draw.to_map(ix, iy, tile.char, fg, bg)
            end
        end
    end
    -- Draw map effects
    for _, effect in ipairs(hole.active_effects) do
        effect:draw()
    end
    -- Draw status and infolines
    local scorecard = gstate:get_scorecard()
    draw.infoline(scorecard, gstate:total_holes(), gstate:available_balls())
    draw.leftstatus(#scorecard+1, #hole.opt_course, gstate:get_stroke_count())
end

function maprender:control(gstate)
    termio.sleep(0.2) -- Just to add a bit of animation
    if gstate.terminate == true then
        return true, true, nil
    end
    -- If not terminating, push an aim element onto the stack
    return true, false, aim(gstate)
end

return maprender
