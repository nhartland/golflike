--- lcurses_driver.lua
-- Underlying terminal driver via lcurses and luaposix.
-- This mostly translates term.io calls to ncurses calls,
-- but also abstracts away the ncurses 'color_pairs'.
local path   = (...):match("(.-)[^%.]+$")
local curses = require("curses")
local keys   = require(path..'keys')
local time   = require("posix.sys.time")

local lc_driver = {
    keyMap = {},  -- Maps ncurses codes to term.key codes
    colMap = {},  -- Map of fg/bg colors to curses color_pairs
    colKey = 100, -- Current color_pair index
}

-- Handles alphanumeric keycodes
for k,v in pairs(keys) do
    local char = string.byte(k)
    if char < 255 then lc_driver.keyMap[char] = v end
end

-- Keymap
lc_driver.keyMap[13] = keys.RETURN
lc_driver.keyMap[9]  = keys.TAB
lc_driver.keyMap[32] = keys.SPACE

lc_driver.keyMap[56] = keys.UP
lc_driver.keyMap[50] = keys.DOWN
lc_driver.keyMap[52] = keys.LEFT
lc_driver.keyMap[54] = keys.RIGHT

lc_driver.keyMap[49] = keys.NUM1
lc_driver.keyMap[66] = keys.NUM2
lc_driver.keyMap[51] = keys.NUM3
lc_driver.keyMap[68] = keys.NUM4
lc_driver.keyMap[67] = keys.NUM6
lc_driver.keyMap[55] = keys.NUM7
lc_driver.keyMap[65] = keys.NUM8
lc_driver.keyMap[57] = keys.NUM9

lc_driver.keyMap[92] = keys.BSLASH
lc_driver.keyMap[63] = keys.QUESTION
lc_driver.keyMap[46] = keys.DOT
lc_driver.keyMap[47] = keys.FSLASH


-- Looks up existing colour pairs for (fg, bg) and creates one if non-existent.
-- Returns the colour pair ID.
local function get_color_pair(fg,bg)
    if lc_driver.colMap[fg] == nil then
        lc_driver.colMap[fg] = {}
    end
    if lc_driver.colMap[fg][bg] == nil then
        assert(lc_driver.colKey < 255, "Out of curses color pairs!")
        lc_driver.colMap[fg][bg] = lc_driver.colKey
        curses.init_pair(lc_driver.colKey, fg, bg)
        lc_driver.colKey = lc_driver.colKey + 1
    end
    return lc_driver.colMap[fg][bg]
end

--- Initialise a new terminal window
function lc_driver.init(_)
    lc_driver.display = curses.initscr() -- Initialise screen
    curses.echo 	(false)		   -- Disable echoing of each print
    curses.nl 		(false)		   -- Disable return being interpreted as newline
    curses.halfdelay(2)            -- 1/10th of a second halfdelay
    curses.curs_set	(0)		       -- Disable cursor
    curses.start_color()           -- Setup colours
    curses.use_default_colors()
end

--- Utils
function lc_driver.clear() lc_driver.display:clear()           end -- Clear the terminal
function lc_driver.draw()  lc_driver.display:refresh()         end -- Flush the drawing buffer to the terminal
function lc_driver.close() curses.endwin()                     end -- Close the terminal window
function lc_driver.size()  return lc_driver.display:getmaxyx() end -- Return (y, x) the size of the terminal
-- Using mcaddch here instead of duplicating mvaddstr causes wierd rendering of digits
function lc_driver.mvaddch (r,c,chr) lc_driver.display:mvaddstr(r,c,chr) end
function lc_driver.mvaddstr(r,c,str) lc_driver.display:mvaddstr(r,c,str) end

-- Get elapsed time in milliseconds
function lc_driver.getTime()
    local CurrentTime = time.gettimeofday()
    local ElapsedTime = 1000*CurrentTime.tv_sec + CurrentTime.tv_usec/1000
    return ElapsedTime
end

--- Set current drawing colour (foreground/background)
function lc_driver.setcolour(fg, bg)
    local colorpair = get_color_pair(fg, bg)
    lc_driver.display:attron(curses.color_pair(colorpair))
end

--- Poll for keyboard input
function lc_driver.getInput(_)
    local key = lc_driver.display:getch()
    return lc_driver.keyMap[key]
end

--- Flush keyboard input
function lc_driver.flushInput()
    curses.flushinp ()
end

return lc_driver
