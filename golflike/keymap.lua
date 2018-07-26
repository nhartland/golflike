--- Game key mappings
local keymap = {}
local keys = require("golfterm.keys")

-- General key mappings
keymap.continue  = keys.SPACE
keymap.confirm   = keys.y
keymap.deny      = keys.n

keymap.strike    = keys.RETURN
keymap.next_club = keys.k
keymap.prev_club = keys.j

keymap.aim_left  = keys.h
keymap.aim_right = keys.l

keymap.precise_up = keys.K
keymap.precise_dn = keys.J

keymap.help       = keys.QUESTION
keymap.standings  = keys.s
keymap.exit_game  = keys.x

-- Debug keys
keymap.debug_next = keys.w -- Skip to next hole
keymap.debug_par  = keys.p -- Switch on par rendering

return keymap
