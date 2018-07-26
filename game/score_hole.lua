-- score_hole.lua
-- This class handles the scoring of a hole
-- Adds the current score to the scorecard, resets stroke count,
-- and updates the competition
local class       = require('30log')
local message     = require('game.message')
local transition  = require('game.transition')
local competition = require("game.competition")
local score_hole  = class("score_hole")

function score_hole:init() end
function score_hole:tick(_) end
function score_hole:render() end

-- Add current score to scorecard, reset stroke count
local function increment_scorecard(gstate)
    local score = gstate:get_stroke_count() - #gstate:current_hole().opt_course
    table.insert(gstate.scorecard, score)
end


function score_hole:control(gstate)
    -- Increment scorecard
    increment_scorecard(gstate)
    -- Update rival progress
    competition.update(gstate:get_rivals(), gstate:total_holes())
    -- Send message with current standings and transition
    local text, tcolour = competition.get_standings_message(gstate:get_scorecard(),
                           gstate:get_rivals(), gstate:total_holes())
    if gstate:remaining_holes() == 1 then
        text[1] = "Course complete!"
    else
        text[1] = "Hole complete!"
    end
    return true, true, message(gstate, transition, text, tcolour)
end

return score_hole
