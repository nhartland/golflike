-- Bresenham's line algorithm
local bresenham = {}

-- Draws a line between `start` and `finish`, taking
-- a callback to check if a tile is blocking.
function bresenham.line(start, finish, is_passable)
    local deltax = finish.x - start.x
    local sx = deltax / math.abs(deltax)
    deltax =  2*math.abs(deltax)

    local deltay = finish.y - start.y
    local sy = deltay / math.abs(deltay)
    deltay =  2*math.abs(deltay)

    local x,y = start.x, start.y
    if is_passable(x, y) == false then
        return false
    end

    if deltax >= deltay then
        local err = deltay - (deltax / 2)
        while x ~= finish.x do
            if err > 0 or (err == 0 and sx > 0 ) then
                err = err - deltax
                y = y + sy
            end
            err = err + deltay
            x = x + sx
            if is_passable(x, y) == false then
                return false
            end
        end
    else
        local err = deltax - (deltay / 2)
        while y ~= finish.y do
            if err > 0 or (err == 0 and sy > 0) then
                err = err - deltay
                x = x + sx
            end
            err = err + deltax
            y = y + sy
            if is_passable(x, y) == false then
                return false
            end
        end
    end
    return true -- Reached target
end

return bresenham
