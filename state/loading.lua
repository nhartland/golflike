--- loading.lua
-- State to manage and display the loading of a course
local transition = require('state.transition')
local termio = require('term.io')
local colour = require('term.colour')
local hole   = require('game.hole')
local common = require('game.common')
local class  = require('30log')
local loading = class("loading")

-- Initialise RNG for loadstate
function loading:init(gstate, rng)
    self.wheel = {'|','/','-','\\'}
    self.wheelpos = 1
    self.rng = rng
end

function loading:tick(gstate)
    -- The loading tick generates new holes for a course
    if #gstate.course < gstate:total_holes() then
        local ite = 0
        local new_hole
        repeat
            ite = ite + 1
            new_hole = hole.new(self.rng)
        until new_hole ~= nil or ite > 10
        table.insert(gstate.course, new_hole)
    end
end

function loading:render(gstate)
    local xo = 22
    for k,v in ipairs(common.banner) do
        termio.putstr(xo, k-1, v, colour.green, colour.black)
    end
    local progressbar = '['
    for i=1,gstate:total_holes(),1 do
        if i <= #gstate.course then progressbar = progressbar .. '#'
        elseif i == #gstate.course+1 then
            progressbar = progressbar .. self.wheel[self.wheelpos]
        else
            progressbar = progressbar .. ' '
        end
    end
    progressbar = progressbar .. ']'

    termio.centre_justify(#common.banner + 1, gstate.course_name, colour.yellow, colour.black)
    termio.centre_justify(#common.banner + 2, progressbar, colour.b_white, colour.black)

    self.wheelpos = (self.wheelpos + 1) % #self.wheel
    self.wheelpos = math.max(1, self.wheelpos)
end

function loading:control(gstate)
    if #gstate.course == gstate:total_holes() then
        return true, true, transition(gstate, true)
    else
        return true, false, nil
    end
end

return loading
