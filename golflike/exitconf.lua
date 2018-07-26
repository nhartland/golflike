-- exitconf.lua
-- game exit confirmation window
local class  = require('30log')
local path = (...):match("(.-)[^%.]+$")
local termio = require(path..'term.io')
local keys   = require(path..'term.keys')
local draw   = require(path..'draw')
local keymap = require(path..'keymap')
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
        local aim = require(path..'aim')
        return true, true, aim(gstate)
    end
end

return exitconf
