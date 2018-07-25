--- term/io.lua
-- Wrapper for various terminal I/O drivers.
-- Switches between a `love` renderer and an lcurses renderer
-- depending on the availability of the global `love` table

local colour = require("term.colour")

local driver
if love ~= nil then
driver = require("term.love_driver") else
driver = require("term.lcurses_driver") end

-- Should convert worigin, wsize from tables to normal x,y numbers (rows/cols)
local termio = {
    centre = true,             -- Centre window in current terminal
    worig  = {x=0, y=0},       -- Origin of window in terminal
    wsize  = {x=0, y=0},       -- Requested window size
}

-- Drawing buffers: stores character and foreground/background
-- colour arrays such that only changed points need to be updated.
-- Current frame drawing buffers. Not strictly neccesary for ncurses
-- as it does it's own buffering.
local current_chBuffer = {}
local current_fgBuffer = {}
local current_bgBuffer = {}
-- Previous frame drawing buffers
local rendered_chBuffer = {}
local rendered_fgBuffer = {}
local rendered_bgBuffer = {}

--- Initialise a new terminal window
-- @param x requested cells in x
-- @param y requested cells in y
-- @param title the window title
function termio.init(x, y, title)
    assert(x > 0, "term.io init requires an x size > 0")
    assert(y > 0, "term.io init requires a y size > 0")
    termio.wsize.x = x
    termio.wsize.y = y
    driver.init(x, y, title)
    -- Also initialises buffers
    termio.clear_buffer()
    termio.clear_terminal()
    -- Sets screen origin etc
    repeat until termio.check_terminal_dimensions()
end

-- Close window and clear buffers
function termio.close()
    -- Buffers being drawn to
    current_chBuffer = {}
    current_fgBuffer = {}
    current_bgBuffer = {}
    -- Characters previously rendered
    rendered_chBuffer = {}
    rendered_fgBuffer = {}
    rendered_bgBuffer = {}
    driver.close()
end

-- Draw the contents of the current rendering buffer to the underlying driver
function termio.draw()
    -- Loop through current drawing buffer, identifying cases where an update
    -- has been made, and drawing those to the terminal.
    local fgCursor = -1
    local bgCursor = -1
    for y=0, termio.wsize.y-1, 1 do
        for x=0, termio.wsize.x-1, 1 do
            local index = x+y*termio.wsize.x + 1
            local char = current_chBuffer[index]
            local fg   = current_fgBuffer[index]
            local bg   = current_bgBuffer[index]
            if rendered_chBuffer[index] ~= char or
                rendered_fgBuffer[index] ~= fg or
                rendered_bgBuffer[index] ~= bg then
                -- Update colour
                if fgCursor ~= fg or bgCursor ~= bg then
                    driver.setcolour(fg,bg)
                    fgCursor = fg
                    bgCursor = bg
                end
                -- Draw new character
                driver.mvaddch( termio.worig.y + y, termio.worig.x + x, char)
                -- Update rendered buffer
                rendered_chBuffer[index] = char
                rendered_fgBuffer[index] = fg
                rendered_bgBuffer[index] = bg
            end
        end
    end
    driver.draw()
end

-- Clears the rendering buffer
function termio.clear_buffer()
    -- Clear current buffer
    current_chBuffer={}
    current_fgBuffer={}
    current_bgBuffer={}
    for _=1, termio.wsize.x*termio.wsize.y, 1 do
        -- Drawing buffers
        table.insert(current_chBuffer, " ")
        table.insert(current_fgBuffer, colour.white)
        table.insert(current_bgBuffer, colour.black)
    end
end

-- Clears the terminal directly, along with all buffers
function termio.clear_terminal()
    termio.clear_buffer()
    driver.clear()
    -- Clear rendered buffer
    rendered_chBuffer={}
    rendered_fgBuffer={}
    rendered_bgBuffer={}
end

-- Print char to buffer
function termio.putchar(x, y, char, fg, bg)
    assert(x >= 0 and x < termio.wsize.x, "term.io: x out-of-bounds")
    assert(y >= 0 and y < termio.wsize.y, "term.io: y out-of-bounds")
    assert(type(char) == 'string' and char:len() == 1, "term.io: invalid char to putchar")
    assert(char:byte() > 0 and char:byte() < 255, "term.io: putchar supports only 8-bit chars")
    local index = x+y*termio.wsize.x + 1
    current_chBuffer[index] = char
    current_fgBuffer[index] = fg
    current_bgBuffer[index] = bg
end

-- Print string to buffer
function termio.putstr(x, y, str, fg, bg)
    assert(type(x) == 'number' and type(y) == 'number')
    assert(type(str) == 'string')
    assert(fg and bg, str)
    for i=1,#str,1 do
        termio.putchar(x+i-1, y, str:sub(i,i), fg, bg)
    end
end

-- Functions that pass straight through to the underlying driver
function termio.sleep(s)                  driver.sleep(s)           end -- Sleep for `s` seconds
function termio.getInput(blocking) return driver.getInput(blocking) end -- Get input from terminal
function termio.flushInput()       return driver.flushInput()       end -- Flush input in terminal

-- Check terminal dimensions ----------------------------------------------
-- Returns true if the driver provides a sufficiently large terminal, false if not
function termio.check_terminal_dimensions()
    local ty, tx = driver.size()
    local size_check_x = tx >= termio.wsize.x
    local size_check_y = ty >= termio.wsize.y
    local valid =  (size_check_x and size_check_y)

    if valid == false then
        termio.worig = {x=0, y=0}
        termio.clear_terminal()
        local msg =  "("..tx.."/"..termio.wsize.x.."), "
        msg = msg .. "("..ty.."/"..termio.wsize.y..")"
        termio.putstr(0,0, "Please resize terminal",
                      colour.white, colour.black)
        termio.putstr(0,1, msg,
                      colour.white, colour.black)
        termio.draw()
        driver.sleep(0.1) -- Should figure out something better here
        termio.clear_terminal()
        return false
    end

    -- Recompute window origin
    if termio.centre == true then
        local newx = math.floor((tx - termio.wsize.x)/2)
        local newy =  math.floor((ty - termio.wsize.y)/2)
        -- Update origin
        if termio.worig.x ~= newx or termio.worig.y ~= newy then
            termio.worig.x = newx
            termio.worig.y = newy
            termio.clear_terminal() -- Redraw scene as origin has changed
        end
    else
        termio.worig = {x=0, y=0}
    end

    return true
end

-- Helpers ------------------------------------------------------------------
-- These print text to the display justified either centrally or to the right
function termio.centre_justify(ypos, string, fg, bg)
    assert(type(ypos) == "number", "termio.centre_justify requires a number as a position")
    assert(type(string) == "string", "termio.centre_justify requires a string argument")
    termio.putstr(math.floor((termio.wsize.x - #string)/2), ypos, string, fg, bg)
end
function termio.right_justify(ypos, string, fg, bg)
    assert(type(ypos) == "number", "termio.right_justify requires a number as a position")
    assert(type(string) == "string", "termio.right_justify requires a string argument")
    termio.putstr(termio.wsize.x - #string, ypos, string, fg, bg)
end

return termio
