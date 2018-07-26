--- state.lua
-- class containing global game state
local competition = require('game.competition')
local cell        = require('forma.cell')
local class       = require('30log')
local state       = class("GameState", {})

-- Initialise a new game state class
-- @param seed_type ('r'/'d'/'m') specifies how the game should be seeded
function state:init(name)
    self.course_name = name
    self.initialised = false -- Flag specifying whether a course is initialised or not
    self.course_length = 9   -- Total length of the course
    self.terminate = false   -- End of the game flag
    self.balls = 3           -- Number of available golf balls
    self.stroke_count = 0 	 -- Total number of strokes played
    self.scorecard = {}      -- Player scorecard
    self.course = {}         -- List of holes in course
    self.location = nil      -- Current ball location
    -- List of rivals in the game
    self.rival_list = competition.get_rivals(8, math)
end
-- Return the name of the course
function state:name() return self.course_name end
-- Return the current position of the ball
function state:ball_position() return cell.clone(self.location) end
-- Return the total number of holes
function state:total_holes() return self.course_length end
-- Return list of rivals
function state:get_rivals() return self.rival_list end
-- Hole ----------------------------------------------------------------------
-- Currently playing hole is always at the top of the stack
function state:current_hole() return self.course[#self.course] end
-- Number of remaining holes is just the number of elements in the hole stack
function state:remaining_holes() return #self.course end
-- Move to the next hole (pop a hole from the stack)
function state:increment_hole() table.remove(self.course) end
-- HP ------------------------------------------------------------------------
function state:available_balls() return self.balls end
function state:lose_ball() self.balls = self.balls - 1 end
-- Movement ------------------------------------------------------------------
function state:move(target) self.location = cell.clone(target)	end
-- Score ---------------------------------------------------------------------
function state:get_scorecard() return self.scorecard end
function state:get_stroke_count() return self.stroke_count end
function state:increment_stroke_count() self.stroke_count = self.stroke_count + 1 end
------------------------------------------------------------------------------
return state
