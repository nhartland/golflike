--- message.lua
-- A message and continue prompt. This can be used for most transitions, as it
-- takes the next state element as an argument
local utl    = require('game.util')
local draw   = require('game.draw')
local termio = require('term.io')
local keys   = require('term.keys')
local colour = require('term.colour')
local keymap = require('keymap')
local class  = require('30log')
local message = class("message")

--- Initialise a message screen
-- This can be done in two ways, firstly with a simple text string
-- that is split into lines based on '\n' characters. Secondly
-- by providing a table of lines. In this case a table of colours
-- for each line to be rendered in is also required.
-- Additionally a 'kill table' of keys which trigger the message to close can be provided
function message:init(_, nextstate, text, colours_table, killtable)
    self.killtable = killtable and killtable or {}
    self.nextstate = nextstate
    if type(text) == "string" then
        assert(colours_table == nil,
               "message: Cannot use a colours table with a string message")
        self.text      = {}
        self.colours   = {}
        -- Parse message into a table, split by newlines
        for line in text:gmatch("([^\n]*)\n?") do
            table.insert(self.colours, colour.white)
            table.insert(self.text, line)
        end
        self.colours[1] = colour.b_red
    else
        assert(#text == #colours_table,
               "message: text table must have as many entries as colours table")
        self.text = text
        self.colours = colours_table

    end
end

function message:tick(_) end

function message:render(_)
    -- Print continue message
    local continue = " press "..keys.findKey(keymap.continue).." to continue "
    draw.rightstatus(continue)

    local ypos = math.ceil((termio.wsize.y - #self.text)/2)
    local background = string.rep(" ", termio.wsize.x)
    for i,t in ipairs(self.text) do
        assert(type(t) == "string")
        if (i < #self.text) or ( #t > 0 ) then -- Trim trailing newlines
            termio.centre_justify(ypos+i-1, background, colour.black, colour.black)
            termio.centre_justify(ypos+i-1, t, self.colours[i], colour.black)
        end
    end
end

function message:control(gstate)
    local key = termio.getInput()
    if key == keymap.continue or utl.intable(key, self.killtable) then
        if self.nextstate ~= nil then
            return true, true, self.nextstate(gstate)
        else
            return true, true, nil
        end
    end
end

return message
