--- util.lua
-- General utilities
local util = {}

--- Pop-and-swap for unordered lists.
-- @param lst input list.
-- @param t target to be removed from list.
-- @return true if target is found and removed, false if not
function util.popandswap(lst, t)
    for i=1,#lst,1 do
        if lst[i] == t then
            lst[i] = lst[#lst]
            lst[#lst] = nil
            return true
        end
    end
    return false
end

-- Returns true if element e is present in list t, false otherwise
function util.intable(e, t)
    assert(type(t) == 'table')
    for i=1,#t,1 do
        if e == t[i] then return true end
    end return false
end

-- Sum all elements in a table
function util.sum(t)
    assert(type(t) == 'table')
    local sum = 0
    for i=1,#t,1 do
        sum = sum+t[i]
    end
    return sum
end

-- Convert cardinal to ordinal number string
-- i.e 3 -> 3rd
function util.make_ordinal(number)
    local last_digit = tostring(number):sub(-1)
    last_digit = tonumber(last_digit)
    local suffix = {"st","nd","rd"}

    if suffix[last_digit] ~= nil then
        return number .. suffix[last_digit]
    else
        return number .. "th"
    end
end

return util
