-- help.lua
-- Help screen, displays a map key, controls and club ranges.
local cell   = require('forma.cell')
local clubs  = require('game.clubs')
local map    = require('game.map')
local draw   = require('game.draw')
local termio = require('term.io')
local keys   = require('term.keys')
local colour = require('term.colour')
local keymap = require('game.keymap')
local class  = require('30log')
local help = class("help")

function help:init() end
function help:tick(_) end

-- Returns a list of tiles in the game (except OOB).
-- If `filter` is true, returns only tiles that can
-- be used for playing a ball.
local function get_tiles(filter)
    local tiles = {}
    for _, tile in ipairs(map.tiles) do
        if tile.name ~= "OOB" and
            filter == false or (
            tile.hazard == false and
            tile.name ~= "Hole") then
            table.insert(tiles, tile)
        end
    end return tiles
end

function help:render(_)
    -- Length in y of the help screen
    local helpscreen_y_size = 10
    local helpscreen_y_origin = math.floor((termio.wsize.y - helpscreen_y_size)/2)

    -- Fill in background of help screen
    local background = string.rep(" ", termio.wsize.x)
    for y=helpscreen_y_origin-1, helpscreen_y_origin + helpscreen_y_size, 1 do
        termio.centre_justify(y, background, colour.white, colour.black)
    end

    -- Render various components
    self:render_clubs(   cell.new(2, helpscreen_y_origin))
    self:render_key(     cell.new(30,helpscreen_y_origin))
    self:render_controls(cell.new(45,helpscreen_y_origin))
    self:render_uitips()

    -- Print continue message
    local continue   = " press "..keys.findKey(keymap.continue).." to continue "
    draw.rightstatus(continue)
end

-- Render the map key
function help:render_key(origin)
    termio.putstr(origin.x, origin.y,"Map Key",  colour.green, colour.black)
    termio.putstr(origin.x, origin.y+1,"-------",  colour.white, colour.black)
    local tiles   = get_tiles(false)
    for it,tile in ipairs(tiles) do
        local h = origin + cell.new(0,it+1)
        termio.putchar(h.x,   h.y, tile.char, tile.fg, tile.bg)
        if tile.hazard == true then
            termio.putstr (h.x+2, h.y, tile.name, colour.red, colour.black)
        else
            termio.putstr (h.x+2, h.y, tile.name, colour.white, colour.black)
        end
    end
end

-- Render the club information
function help:render_clubs(origin)
    termio.putstr(origin.x+1, origin.y,   "Club range by Terrain ",  colour.green, colour.black)
    termio.putstr(origin.x+1, origin.y+1, "----------------------", colour.white, colour.black)
    termio.putstr(origin.x+1, origin.y+2, "Club   ACC" ,colour.yellow, colour.black)
    local p0 = origin + cell.new(1,2)
    local tiles = get_tiles(true)
    for i, club in ipairs(clubs) do
        local n0 = p0 + cell.new(0,i)
        local s0 = p0 + cell.new(1 + clubs.max_name(),i)
        termio.putstr(n0.x, n0.y, club.name, colour.green, colour.black)
        termio.putstr(s0.x, s0.y, tostring(club.accuracy), colour.white, colour.black)
        for it,tile in ipairs(tiles) do
            local p = p0 + cell.new(3*it+clubs.max_name()+1,i)
            local h = p0 + cell.new(3*it+clubs.max_name()+1,0)
            termio.putchar(h.x, h.y,  tile.char,tile.fg,tile.bg)
            termio.putchar(h.x+1, h.y,tile.char,tile.fg,tile.bg)
            termio.putstr(p.x, p.y, tostring(clubs.get_range(tile.name, club)), colour.white, colour.black)
        end
    end
    termio.putstr(origin.x+1, origin.y+3+#clubs, "----------------------", colour.white, colour.black)
    termio.putstr(origin.x+1, origin.y+4+#clubs, "ACC: Accuracy / Spread", colour.yellow, colour.black)
end

-- Render control information
function help:render_controls(origin)
    termio.putstr(origin.x, origin.y,  "Controls:", colour.green, colour.black)
    local rl, rr = keys.findKey(keymap.aim_left),   keys.findKey(keymap.aim_right)
    local nc, pc = keys.findKey(keymap.next_club),  keys.findKey(keymap.prev_club)
    local pu, pd = keys.findKey(keymap.precise_up), keys.findKey(keymap.precise_dn)
    ------------------------
    local strike    = keys.findKey(keymap.strike)
    local standings = keys.findKey(keymap.standings)
    local exit_game = keys.findKey(keymap.exit_game)
    ------------------------
    local fg, bg = colour.white, colour.black
    termio.putstr(origin.x, origin.y + 1,"  ------------------------------  ", fg, bg)
    termio.putstr(origin.x, origin.y + 2,"  "..rl..","..rr..": Rotate counter-/clockwise", fg, bg)
    termio.putstr(origin.x, origin.y + 3,"  "..nc..","..pc..": Choose next/previous club", fg, bg)
    termio.putstr(origin.x, origin.y + 4,"  "..pu..","..pd..": Precision aim up/down", fg, bg)
    termio.putstr(origin.x, origin.y + 5,"  ".. strike    .. ": Strike the ball", fg, bg)
    termio.putstr(origin.x, origin.y + 6,"  ------------------------------  ", fg, bg)
    termio.putstr(origin.x, origin.y + 7,"  ".. standings .. ": View scoreboard", fg, bg)
    termio.putstr(origin.x, origin.y + 8,"  ".. exit_game .. ": Exit game", fg, bg)
end

-- Render UI tips
function help:render_uitips()
    local background = string.rep(" ", termio.wsize.x)
    termio.putstr(0,  1, background, colour.white, colour.black)
    termio.putstr(10, 1,"^^  Your Scorecard  ^^", colour.yellow, colour.black)
    termio.putstr(44, 1,"Game over at zero balls remaining ^^", colour.yellow, colour.black)
    termio.putstr(0,  termio.wsize.y-2, background, colour.white, colour.black)
    termio.putstr(2,  termio.wsize.y-2,"vv  Hole Stats  vv", colour.yellow, colour.black)
    termio.putstr(35, termio.wsize.y-2,"vv Chance of losing ball to a hazard", colour.yellow, colour.black)
end

function help:control(_)
    local key = termio.getInput()
    if key == keymap.help or
        key == keymap.continue then
        return true, true, nil
    end
    return true, false, nil
end

return help
