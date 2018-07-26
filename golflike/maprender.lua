-- maprender.lua
-- This class renders the map and statuslines to screen.
local class  = require('30log')
local path = (...):match("(.-)[^%.]+$")
local termio = require(path..'term.io')
local draw   = require(path..'game.draw')
local maprender = class("maprender")

function maprender:init() end
function maprender:tick(_) end

function maprender:render(gstate)
    local hole = gstate:current_hole()
    if hole == nil then return end -- Game finished
    if gstate.initialised == false then return end -- Game not loaded yet
    draw.map(hole) -- Draw Map
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
    local aim    = require(path..'aim')
    return true, false, aim(gstate)
end

return maprender
