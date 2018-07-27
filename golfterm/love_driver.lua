--- love2d rendering backend
-- Based in large part on the rotLove renderer, but heavily modified into
-- a lower-level driver
local path = (...):match("(.-)[^%.]+$")
local colour = require(path..'colour')
local keys   = require(path..'keys')

local scale = 1.0 -- Global scale factor

local l2d = {
    keybuf  = {},  -- Buffer for keyboard input
    currentFG = 7, -- Current foreground drawing colour
    currentBG = 0, -- Current background drawing colour
    size_x    = 0,    -- Size of window in x
    size_y    = 0,    -- Size of window in y
    charWidth = 9*scale,  -- Character Width
    charHeight= 16*scale, -- Character Height
    graphics = love.graphics  -- love2d rendering
}

--- Load rendering glyphs
local glyphs = {}
local glyphSprite = l2d.graphics.newImage('golfterm/cp437.png')
for i=0,255 do
    local sx=(i%32)*9
    local sy=math.floor(i/32)*16
    glyphs[i]=l2d.graphics.newQuad(sx, sy, 9, 16,
                                   glyphSprite:getWidth(),
                                   glyphSprite:getHeight())
end

-- General keymap
local keymap = {}
keymap["?"] = keys.QUESTION
keymap[" "] = keys.SPACE

-- Special character keymap
local s_keymap = {}
s_keymap["return"] = keys.RETURN
s_keymap["up"]     = keys.UP
s_keymap["down"]   = keys.DOWN
s_keymap["left"]   = keys.LEFT
s_keymap["right"]  = keys.RIGHT

-- ColourMap: Working with 16 colours atm
local colourmap = {}
-- Normal colours
colourmap[colour.black]     = {0,0,0}
colourmap[colour.red]       = {215,80,60}
colourmap[colour.green]     = {82,234,169}
colourmap[colour.yellow]    = {255,180,84}
colourmap[colour.blue]      = {38,107,133}
colourmap[colour.magenta]   = {203,37,61}
colourmap[colour.cyan]      = {137,150,168}
colourmap[colour.white]     = {254,254,254}
-- Bright colours
colourmap[colour.b_black]   = {35,50,63}
colourmap[colour.b_red]     = {240,94,51}
colourmap[colour.b_green]   = {118,255,205}
colourmap[colour.b_yellow]  = {255,231,146}
colourmap[colour.b_blue]    = {60,173,215}
colourmap[colour.b_magenta] = {215,60,77}
colourmap[colour.b_cyan]    = {175,196,219}
colourmap[colour.b_white]   = {255,255,255}

-- Process colourmap to [0,1] as per newer love versions
for _, v in pairs(colourmap) do
    v[1] = v[1]/255.
    v[2] = v[2]/255.
    v[3] = v[3]/255.
end

-- Keypresses work a bit differently in the love2d renderer.
-- love.textinput pushes keys to a buffer which are accessed by getInput
function love.textinput( key )
    -- Push a key onto the pressed stack
    table.insert(l2d.keybuf, key)
end

-- Handle special characters
function love.keypressed( key )
    if s_keymap[key] ~= nil then
        table.insert(l2d.keybuf, key)
    end
end

-- Initialise a love display
function l2d.init(x, y, title)
    l2d.size_x, l2d.size_y = x, y
    love.window.setMode(l2d.charWidth*l2d.size_x,
                        l2d.charHeight*l2d.size_y)
    l2d.canvas = l2d.graphics.newCanvas(l2d.charWidth*l2d.size_x,
                                        l2d.charHeight*l2d.size_y)
    love.keyboard.setKeyRepeat( true )
    if title ~= nil then
        love.window.setTitle( title )
    end
end

-- Render the display to screen
function l2d.draw()
    l2d.graphics.setCanvas()
    l2d.graphics.setColor(1,1,1,1)
    l2d.graphics.draw(l2d.canvas)
end

-- Clear the display
function l2d.clear()
    l2d.graphics.setCanvas(l2d.canvas)
    l2d.graphics.clear( )
    l2d.graphics.setCanvas()
end

function l2d.close()                                end -- Close the display
function l2d.size()   return l2d.size_y, l2d.size_x end -- Return the (y, x) size of the display
function l2d.sleep(s) love.timer.sleep( s )         end -- Sleep for `s` seconds

-- Print a character `ch` at line `l` column `c`
function l2d.mvaddch(l, c, ch)
    local x, y = c + 1, l + 1
    local fg = colourmap[l2d.currentFG]
    local bg = colourmap[l2d.currentBG]

    local byte = ch:byte()
    local px=(x-1)*l2d.charWidth
    local py=(y-1)*l2d.charHeight

    l2d.graphics.setCanvas(l2d.canvas)
    l2d.graphics.setColor(bg)
    l2d.graphics.rectangle('fill', px, py, l2d.charWidth, l2d.charHeight)
    if byte~=32 and byte~=255 then
        local qd = glyphs[byte]
        l2d.graphics.setColor(fg)
        l2d.graphics.draw(glyphSprite, qd, px, py, nil, l2d.scale)
    end
    l2d.graphics.setCanvas()
end

-- Set the (foreground, background) colour
function l2d.setcolour(f, b)
    l2d.currentFG = f
    l2d.currentBG = b
end

-- A bit different from the others, here it's mainly to translate
-- a love2d keycode to a term/io one
function l2d.getInput()
    if #l2d.keybuf > 0 then
       local keypop = table.remove(l2d.keybuf)
       if keymap[keypop] ~= nil then
           return keymap[keypop]
       elseif s_keymap[keypop] ~= nil then
           return s_keymap[keypop]
       else
           return keys[keypop]
       end
   else
       return nil
   end
end

-- Flush the input buffer
function l2d.flushInput() l2d.keybuf = {} end

return l2d
