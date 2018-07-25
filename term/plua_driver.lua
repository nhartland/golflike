-- plt.lua
--
-- Code here based on `plterm`, but *heavily* modified
--

------------------------------------------------------------------------

local colour = require('term.colour')
local keys   = require('term.keys')

local plt = {
    tput  = "tput",
    stty  = "stty",
    out   = io.write,
    flush = io.flush
}

-- special chars (for parsing esc sequences)
local ESC, LETO, LBR, TIL= 27, 79, 91, 126  --  esc, [, ~

local getcode = function() return string.byte(io.read(1)) end

-- 16-color map
local foreground_16_colours = {}
foreground_16_colours[colour.black]   = 30
foreground_16_colours[colour.red]     = 31
foreground_16_colours[colour.green]   = 32
foreground_16_colours[colour.yellow]  = 33
foreground_16_colours[colour.blue]    = 34
foreground_16_colours[colour.magenta] = 35
foreground_16_colours[colour.cyan]    = 36
foreground_16_colours[colour.white]   = 37

foreground_16_colours[colour.b_black]   = 90
foreground_16_colours[colour.b_red]     = 91
foreground_16_colours[colour.b_green]   = 92
foreground_16_colours[colour.b_yellow]  = 93
foreground_16_colours[colour.b_blue]    = 94
foreground_16_colours[colour.b_magenta] = 95
foreground_16_colours[colour.b_cyan]    = 96
foreground_16_colours[colour.b_white]   = 97

local background_16_colours = {}
background_16_colours[colour.black]     = 40
background_16_colours[colour.red]       = 41
background_16_colours[colour.green]     = 42
background_16_colours[colour.yellow]    = 43
background_16_colours[colour.blue]      = 44
background_16_colours[colour.magenta]   = 45
background_16_colours[colour.cyan]      = 46
background_16_colours[colour.white]     = 47

background_16_colours[colour.b_black]   = 100
background_16_colours[colour.b_red]     = 101
background_16_colours[colour.b_green]   = 102
background_16_colours[colour.b_yellow]  = 103
background_16_colours[colour.b_blue]    = 104
background_16_colours[colour.b_magenta] = 105
background_16_colours[colour.b_cyan]    = 106
background_16_colours[colour.b_white]   = 107

--- Input escape codes ----------------------------------------------
-- These work a little differently from the keymaps for other drivers,
-- as they correspond explicitly to escape codes
local keymap = {}
keymap['A'] = keys.UP
keymap['B'] = keys.DOWN
keymap['C'] = keys.RIGHT
keymap['D'] = keys.LEFT

--- Escape codes ----------------------------------------------------
-- The following definitions (from term.clear to term.restore) are
-- based on public domain code by Luiz Henrique de Figueiredo
-- http://lua-users.org/lists/lua-l/2009-12/msg00942.html
--
-- Clearing screen
function plt.clear()    plt.out("\027[2J") end
function plt.cleareol() plt.out("\027[K") end
-- Cursor manipulation
function plt.golc(l,c)  plt.out("\027[",l,";",c,"H") end
function plt.up(n)      plt.out("\027[",n or 1,";","A") end
function plt.down(n)    plt.out("\027[",n or 1,";","B") end
function plt.right(n)   plt.out("\027[",n or 1,";","C") end
function plt.left(n)    plt.out("\027[",n or 1,";","D") end
-- hide / show cursor
function plt.hide()     plt.out("\027[?25l") end
function plt.show()     plt.out("\027[?25h") end
-- save/restore cursor position
function plt.save()     plt.out("\027[s") end
function plt.restore()  plt.out("\027[u") end
-- reset terminal (clear and reset default colors)
function plt.reset()    plt.out("\027c") end
---------------------------------------------------------------------

-- Initialise the terminal
function plt.init()
    os.execute(plt.tput .. " smcup") -- Enable alternate buffer
    os.execute(plt.stty .. " cbreak -echo 2> /dev/null")
    plt.hide()
    plt.clear()
end

-- Should restore old settings really (see plterm)
function plt.close()
    os.execute(plt.tput .. " rmcup") -- Disable alternate buffer
    os.execute(plt.stty .. " sane")
end

-- return current screen dimensions (line, coloumn as integers)
function plt.size()
    local rep = io.popen( plt.stty .. " size"):read()
    local ls, cs = rep:match("(%d+) (%d+)")
    local l, c = tonumber(ls), tonumber(cs)
    return l, c
end

-- Move to (l,c) and add print ch
function plt.mvaddch(l,c,ch)
    plt.golc(l+1,c+1) -- +1 needed to harmonise with ncurses
    plt.out(ch)
end

--- Set colour attributes
-- Requires a 256 colour capable terminal
-- @param f foreground colour
-- @param b background colour
function plt.setcolour(f,b)
    if f < 16 and b < 16 then
        local fgcode = foreground_16_colours[f]
        local bgcode = background_16_colours[b]
        plt.out("\027[",fgcode,";",bgcode,"m")
    else -- 256 colour fallback
        plt.out("\027[38;5;",f,"m")
        plt.out("\027[48;5;",b,"m")
    end
end

--- Processes arrow key escape codes.
-- Called when an escape is encountered in plt.getInput. Not ideal as getcode()
-- is blocking: pushing escape will then block the next keypress. Not sure as
-- to best approach.
local function handle_escape()
    local c2 = getcode()
    if c2 == ESC then -- Handle EscEsc
        return handle_escape()
    end
    if c2 ~= LETO and c2 ~= LBR then -- Invalid code
        return nil -- Maybe return Esc, c2?
    end
    local c3 = getcode()
    if c3 == nil then  -- Invalid code
        return nil -- Maybe return Esc, c2?
    end
    -- Should now be a genuine code
    return keymap[string.char(c3)]
end

--- Get keyboard input
function plt.getInput()
    while true do
        local code = getcode()
        if code == ESC then
            return handle_escape()
        elseif code ~= nil then
            local keycode = keys.findKey(code)
            if keycode ~= "NULL" then
                return keys[keycode]
            end
        end
    end
end

-- No obvious way to do this yet
function plt.flushInput() end

--- Sleep for `s` seconds
function plt.sleep(s)
    os.execute("sleep " .. tostring(s))
end

-- Flush results to terminal
function plt.draw()
    plt.flush()
end

return plt
