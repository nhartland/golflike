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

--- Draw windspeed indicator
function draw.windstatus(club, wind_direction, wind_strength)
    draw.centrestatus(club.name .. ": " .. wind_strength .. " " .. wind_direction .. " wind", colour.b_white)
end

-- Game rendering -------------------------------------------------------------------------------------

-- Draw a map character to terminal
function draw.to_map(x, y, char, fg, bg)
    -- +1 to offset from menu bar
    termio.putchar(x, y+1, char, fg, bg)
end

-- Draw the planned trajectory for aiming
function draw.trajectory(hole, trajectory, block_point, max_trajectory, char)
    for itrj = 1, max_trajectory, 1 do
        local vtrj = trajectory[itrj]
        if in_game_bounds(vtrj) then
            local tile = map.get(hole, vtrj.x, vtrj.y)
            -- By default use the trajectory character
            local s_char = char
            if tile.block.air == true then
                -- If it's an air blocking tile, use the tile character
                s_char = tile.char
            elseif itrj == max_trajectory then
                -- If it's the final tile, use the X  character
                s_char = 'X'
            end
            -- Draw in red until blocking point, white thereafter
            if itrj < block_point then
                draw.to_map(vtrj.x, vtrj.y, s_char, colour.red, tile.bg)
            else
                draw.to_map(vtrj.x, vtrj.y, s_char, colour.b_white, tile.bg)
            end
        end
    end
end

-- Draw the ball
function draw.ball(hole, ball)
    local tile = map.get(hole, ball.x, ball.y)
    draw.to_map(ball.x, ball.y, 'o', colour.b_white, tile.bg)
end


return draw
