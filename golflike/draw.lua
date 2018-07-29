--- draw.lua
-- Handling of terminal I/O
local common      = require("golflike.common")
local competition = require('golflike.competition')
local map         = require("golflike.map")
local termio      = require("golfterm.io")
local colour      = require('golfterm.colour')

local draw = {}

-- Coordinate transforms -----------------------------------------------------------------------------
-- These functions offset the game space from the terminal space by 1 (size of top menu bar)
local function in_game_bounds(gamevec)
    local xbounds  = gamevec.x >= 0 and gamevec.x < common.mapsize_x
    local ybounds  = gamevec.y >= 0 and gamevec.y < common.mapsize_y
    return xbounds and ybounds
end

-- UI -------------------------------------------------------------------------------------------------
-- Render the top (information) line
function draw.infoline(scorecard, nholes, nballs)
    -- Score string
    local scstring  = competition.get_scorestring(scorecard, nholes)
    termio.putstr(0, 0, scstring, colour.b_white, colour.black)
    -- Available balls
    local hpstring = "Balls remaining: "..tostring(nballs)
    termio.right_justify(0, hpstring, colour.b_white, colour.black)

end

-- Draw left-part of lower (status) line
function draw.leftstatus(hole, par, strokes)
    -- Hole and par status
    local statusline_y = termio.wsize.y - 1
    local status = "Hole " .. hole .. ", Par " .. par .. ", Strokes " .. strokes
    termio.putstr(0, statusline_y, status, colour.b_white, colour.black)
end

-- Draw a right-status string
function draw.centrestatus(str, fg)
    if fg == nil then fg = colour.b_white end
    local statusline_y = termio.wsize.y - 1
    termio.centre_justify (statusline_y, str, fg, colour.black)
end

-- Draw a centre-status string
function draw.rightstatus(str, fg)
    if fg == nil then fg = colour.b_white end
    local statusline_y = termio.wsize.y - 1
    termio.right_justify(statusline_y, str, fg, colour.black)
end

-- Draw hazard indicator (right part) of statusline
function draw.hazardstatus(club, hazardfraction)
    local display_hzd = 10*math.floor(hazardfraction*10.0 + 0.5)
    if hazardfraction == 0 then
        draw.centrestatus(club.name .. ": No Hazard ", colour.b_white)
    elseif display_hzd == 0 then
        draw.centrestatus(club.name .. ": Hazard risk < 10%", colour.b_white)
    elseif display_hzd < 60 then
        draw.centrestatus(club.name .. ": Hazard risk "..display_hzd.."%", colour.b_yellow)
    else
        draw.centrestatus(club.name .. ": Hazard risk "..display_hzd.."%", colour.b_red)
    end
end


-- Game rendering -------------------------------------------------------------------------------------

-- Draw the map
function draw.map(hole)
    for ix = 0, common.mapsize_x-1, 1 do
        for iy = 0, common.mapsize_y - 1, 1 do
            local tile = map.get(hole, ix, iy)
            if tile ~= map.tiles[0] then
                local fg, bg = tile.fg, tile.bg
                -- +1 to offset from menu bar
                termio.putchar(ix, iy+1, tile.char, fg, bg)
            end
        end
    end
end

-- Draw the red target area for aiming
function draw.target(hole, target)
    for itrg = 1, #target, 1 do
        local vtarget = target[itrg]
        if in_game_bounds(vtarget) then
            local tile = map.get(hole, vtarget.x, vtarget.y)
            if tile.block.air == false then
                termio.putchar(vtarget.x, vtarget.y+1, '=', colour.red, tile.bg)
            else
                termio.putchar(vtarget.x, vtarget.y+1, tile.char, colour.magenta, tile.bg)
            end
        end
    end
end

-- Draw the planned trajectory for aiming
function draw.trajectory(hole, trajectory, char)
    for itrj = 1, #trajectory, 1 do
        local vtrj = trajectory[itrj]
        if in_game_bounds(vtrj) then
            local tile = map.get(hole, vtrj.x, vtrj.y)
            termio.putchar(vtrj.x, vtrj.y+1, char, colour.red, tile.bg)
        end
    end
end

-- Draw the ball
function draw.ball(hole, ball)
    local tile = map.get(hole, ball.x, ball.y)
    termio.putchar(ball.x, ball.y+1, 'o', colour.b_white, tile.bg)
end


return draw
