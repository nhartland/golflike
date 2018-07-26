--- menu.lua
-- Game menu, for course selection
local termio  = require('term.io')
local colour  = require('term.colour')
local keys    = require('term.keys')
local markov  = require('state.markov')
local loading = require('state.loading')
local random  = require('game.random')
local common  = require('game.common')
local keymap  = require('game.keymap')
local date    = require("date")
local class   = require('30log')
local menu = class("menu")


function menu:init(gstate)
    -- List of control chars for main menu control
    self.control_chars = {'a', 'b', 'c'}

    -- Setup Seeds
    local d = date(false);
    local seeds = {
        {stype = "Random", seed = os.time()},
        {stype = "Daily",  seed = d:getyearday()*d:getyear()},
        {stype = "Weekly", seed = 500*d:getweeknumber()*d:getyear()}
    }

    -- Setup club name information
    local towns      = require('data.towns')
    local extensions = require('data.extensions')
    local markov_chain = markov.init(towns, 3)

    -- Generate course names
    self.courses = {}
    for _,v in ipairs(seeds) do
        random.add_generator(v.stype, v.seed)
        local rng = random.get_generator(v.stype)
        local markov_name = markov.word(markov_chain, 12, rng)
        local uppercase = markov_name:sub(1,1):upper() .. markov_name:sub(2)
        local full_name = uppercase .. ' ' .. extensions[rng(#extensions)]
        table.insert(self.courses, {stype = v.stype, name = full_name})
    end

    -- Simple consistency check
    assert(#self.control_chars == #self.courses,
           "Mismatch in number of seeds and control chars")
end

function menu:tick(gstate) end

function menu:render(gstate)
    -- Print golflike banner
    local xo = 22
    for k,v in ipairs(common.banner) do
        termio.putstr(xo, k-1, v, colour.green, colour.black)
    end
    -- Print main heading
    local ic = #common.banner + 1
    termio.centre_justify(ic, "COURSE SELECT", colour.b_yellow, colour.black)
    ic = ic + 2
    -- Print course options
    for k,v in ipairs(self.courses) do
        termio.putstr(xo, ic, self.control_chars[k]..") "..v.stype.. " course:", colour.yellow, colour.black)
        termio.putstr(xo, ic+1, '    '..v.name, colour.white, colour.black)
        ic = ic + 3
    end
    -- Exit key
    local exit_key = keys.findKey(keymap.exit_game)
    termio.putstr(xo, ic, exit_key.. ") Quit game", colour.yellow, colour.black)
end

function menu:control(gstate)
    local input = termio.getInput()
    for k,v in pairs(self.control_chars) do
        if keys.findKey(input) == v then
            local course_type = self.courses[k].stype
            local course_name = self.courses[k].name
            gstate:init(course_name)
            local rng = random.get_generator(course_type)
            return true, true, loading(gstate, rng)
        end
    end
    if input == keymap.exit_game then
        gstate.terminate = true
        return true, true, nil
    end
    return false, false, nil
end

return menu
