-- exitconf.lua
-- game exit confirmation window
local class  = require('30log')
local draw   = require('golflike.draw')
local keymap = require('golflike.keymap')
local termio = require('golfterm.io')
local keys   = require('golfterm.keys')
local exitconf = class("ExitConf")

function exitconf:init(_) end
function exitconf:tick(_) end

function exitconf:render(_)
    local confkey = keys.findKey(keymap.confirm)
    local denykey = keys.findKey(keymap.deny)
    local confirm_text = "Are you sure you want to exit? ("..confkey.."/"..denykey..")"
    draw.rightstatus(confirm_text)
end

function exitconf:control(gstate)
    local key = termio.getInput()
    if key == keymap.confirm then
        gstate.terminate = true
        return true, true, nil
    elseif key == keymap.deny then
        local aim = require('golflike.aim')
        return true, true, aim(gstate)
    end
end

return exitconf
