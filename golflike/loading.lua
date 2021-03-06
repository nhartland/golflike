--- loading.lua
-- State to manage and display the loading of a course
local class      = require('30log')
local transition = require('golflike.transition')
local hole       = require('golflike.hole')
local common     = require('golflike.common')
local termio     = require('golfterm.io')
local colour     = require('golfterm.colour')
local loading    = class("loading")

-- Initialise RNG for loadstate
function loading:init(gstate, rng)
    self.wheel = {'|','/','-','\\'}
    self.wheelpos = 1
    self.rng = rng
    self.firsttick = true
end

-- Get the map type for the hole
local function getmaptype(ihole, nholes)
    local maptype = "forest"
    if ihole > 2*nholes/3 then
        maptype = "links"
    elseif ihole > nholes/3 then
        maptype = "classic"
    end
    return maptype
end

function loading:tick(gstate)
    if self.firsttick == true then
        self.firsttick = false
        return
    end
    -- Required map type
    local mt = getmaptype(#gstate.course+1, gstate:total_holes())
    -- The loading tick generates new holes for a course
    if #gstate.course < gstate:total_holes() then
        local ite = 0
        local new_hole
        repeat
            ite = ite + 1
            new_hole = hole.new(self.rng, mt)
        until new_hole ~= nil or ite > 10
        table.insert(gstate.course, new_hole)
    end
end

function loading:render(gstate)
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
        hole.stats_report() -- Report on generation stats
        return true, true, transition(gstate, true)
    else
        return true, false, nil
    end
end

return loading
