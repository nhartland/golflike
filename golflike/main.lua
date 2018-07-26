-- main.lua
-- Game loop
local path = (...):match("(.-)[^%.]+$")
local common      = require(path..'common')
local competition = require(path..'competition')
local state       = require(path..'state')
local maprender   = require(path..'maprender')
local menu        = require(path..'menu')
local termio      = require(path..'term.io')
local log         = require(path..'lib.log')

local game = {}
if love ~= nil then
    game = love
end

--- Game initialisation
function game.load()
--    log.outfile='log.txt'
    log.level='trace'

    -- Setup game state
    game.state = state()
    game.stack = {maprender(game.state), menu(game.state)}
    game.tick = true

    -- Initialise viewable area +2 needed for status lines
    termio.init(common.mapsize_x, common.mapsize_y + 2, "golflike")
end

-- Render game
function game.draw()
    repeat until termio.check_terminal_dimensions()
    termio.draw()
end

-- Main game loop
function game.update()
    -- Main loop, continues until state stack is empty
    if #game.stack == 0 then
        game.close()
        return false
    end
    if game.tick == true then
        termio.clear_buffer() -- Prepare for rendering
        game.stack[#game.stack]:tick(game.state)
        for _,gs in ipairs(game.stack) do gs:render(game.state) end
        game.draw()
    end
    -- Get input from player
    local kill, push
    game.tick, kill, push = game.stack[#game.stack]:control(game.state)
    -- Pop state stack element
    if kill == true then table.remove(game.stack) end
    if push ~= nil  then
        termio.flushInput() -- Flush input on change of state
        game.stack[#game.stack+1] = push
    end
    return true
end

-- Wrap things up
function game.close()
    -- Exit game
    termio.close()
    -- Trigger love quit event
    if love ~= nil then
        love.event.quit( )
    end
end

-- Terminal mode
if love == nil then
    game.load()

    -- Disable logging to stdout when in terminal
    log.stdout = false

    -- Main loop terminal mode
    local running
    local function loop()
        running = game.update()
    end
    -- Terminal mode error handling
    local function err (_err)
        termio.close()
        print "Caught an error:"
        print (debug.traceback (_err, 2))
        os.exit(2)
    end

    -- Run main loop
    repeat
        xpcall (loop, err)
    until running == false

    -- Finalise by writing scoreboard entry
    local exitstring = os.date("%c").." v"..common.version.." - Course: \'" ..tostring(game.state:name())
    exitstring = exitstring .. "\'. completed " .. #game.state.scorecard .. "/" .. game.state:total_holes() .. " holes."
    exitstring = exitstring .. competition.get_scorestring(game.state.scorecard, game.state:total_holes()) .. '\n'
    local scoreboard = io.open ("scoreboard.txt", "a+" )
    io.output(scoreboard) io.write(exitstring) io.close(scoreboard)
    print(exitstring)

    -- Exit when finished
    os.exit(0)
end
