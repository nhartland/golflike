--- Competition.lua
-- Code for handling scores, and the generation of rivals.
--
-- Rivals should be: limited in number (so you can recognise them)
-- reproducibly skilled (good players are good, bad player are bad)
local utl    = require('golflike.util')
local colour = require('golfterm.colour')

local competition = {}

-- List of possible surnames
local all_surnames = require('golflike.surname_data')

--- Generate a new rival
-- Each rival has three properties
-- a) Their name
-- b) Their skill level (maximum shots over par)
-- c) Their scorecard (identical as to player's scorecard)
local function get_name(id, rng)
    local surname = all_surnames[rng.random(#all_surnames)]:lower()
    surname = surname:sub(1,1):upper() .. surname:sub(2)
    local surname_novowels = surname:gsub('[aeiou]','')
    local idx = 471 % #surname_novowels + 1
    local skill = (28621*idx + 1194) % 5 + 1
    return  {id = id, name = surname, skill = skill, scorecard = {}}
end

--- Generate a set of rivals
-- @param n_rivals number of requested rivals
-- @rng a random number generator
function competition.get_rivals(n_rivals, rng)
    assert(rng, "competition.get_rivals needs an rng")
    assert(n_rivals > 0 and n_rivals < 20,
    "number of rivals must be greater than 0 and less than 20")
    local field = {}
    repeat
        local new_rival = get_name(#field, rng)
        local found = false
        for _, old_rival in ipairs(field) do
            if old_rival.name == new_rival.name then
                found = true
                break
            end
        end
        if found == false then
            table.insert(field, new_rival)
        end
    until #field == n_rivals
    return field
end

--- Updates the scorecards of a set of rivals
-- Adds some numbers to the scorecard according to their skills
function competition.update(rival_list, nholes)
    for _, irival in ipairs(rival_list) do
        local nplayed = #irival.scorecard
        if nplayed < nholes then
            -- Number of holes to play
            local ntoplay = ( nholes - nplayed )
            local newscores = math.min(math.random(0,1)+1, ntoplay)
            for _=1, newscores, 1 do
                local score = math.random(-1, irival.skill)
                table.insert(irival.scorecard, score)
            end
        end
    end
end

--- Return a sorted list of the current players by score, and the player's standaing
function competition.rank(player_scorecard, rival_list)
    -- Form a merged list of player and rivals
    -- The id is used to break ties in the ranking: the player always has the lowest id (-1)
    local merged_list = {{id=-1, name="PLAYER", scorecard=player_scorecard}}
    for _,v in ipairs(rival_list) do
        assert(type(v.scorecard) == 'table', "Non-table scorecard: " .. type(v.scorecard) ..' ' ..v.name)
        table.insert(merged_list, v)
    end

    -- Sort players by score
    local scoresort = function(a,b)
        local suma = utl.sum(a.scorecard)
        local sumb = utl.sum(b.scorecard)
        assert(type(suma) == 'number', "scoresorta: non-number value " .. suma .. ' ' .. a.name)
        assert(type(sumb) == 'number', "scoresortb: non-number value " .. suma .. ' ' .. a.name)
        if suma == sumb then
            return a.id < b.id
        else
            return suma < sumb
        end
    end
    table.sort(merged_list, scoresort)

    -- Work out standing of the player
    local pl_standing
    for i, player in ipairs(merged_list) do
        if player.name == "PLAYER" then
            pl_standing = i
        end
    end

    return merged_list, pl_standing
end

-- Render a scorecard to a string
function competition.get_scorestring(scorecard, nholes)
    local function prefix(score)
        if score == '--' then return '' end
        if score >  0    then return '+' end
        if score == 0    then return ' ' end
        return '' -- negative
    end
    local scorestring = '| '
    for i=1, nholes, 1 do
        local score = scorecard[i] ~= nil and scorecard[i] or '--'
        scorestring = scorestring .. prefix(score) .. tostring(score) .. ' | '
    end
    local total = #scorecard == 0 and "--" or utl.sum(scorecard)
    total = prefix(total) .. total
    local padding = 3 - #tostring(total)
    scorestring = scorestring .. "TOTAL: " .. string.rep(' ', padding) ..  total
    return scorestring
end

--- Get a message with the current standings
-- Takes gamestate and returns a message text
function competition.get_standings_message(player_scorecard, rival_list, nholes)
    local players, pl_standing = competition.rank(player_scorecard, rival_list)

    -- Work out padding to align scorecard table
    local padspace = 0
    for _, player in ipairs(players) do
        padspace = math.max(padspace, #player.name)
    end

    -- Ordinal version of pl_standing
    pl_standing = utl.make_ordinal(pl_standing)

    -- Scorecard message
    local text, colours = {}, {}
    table.insert(text, " - COMPETITION STANDINGS - ") table.insert(colours, colour.b_red)
    if #player_scorecard == nholes then
        table.insert(text, "You finish in " .. pl_standing .. " place")
        table.insert(colours, colour.green)
    else
        table.insert(text, "You are in " .. pl_standing .. " place")
        table.insert(colours, colour.green)
    end

    table.insert(text, "")
    table.insert(colours, colour.green)

    for i, player in ipairs(players) do
        local padding = padspace - #player.name
        local msg = utl.make_ordinal(i) .. string.rep(' ', padding+1)
        msg = msg .. player.name .. ' '.. competition.get_scorestring(player.scorecard, nholes)
        table.insert(text, msg)
        if player.name == "PLAYER" then
            table.insert(colours, colour.green)
        else
            table.insert(colours, colour.b_white)
        end
    end
    table.insert(text, "") table.insert(colours, colour.green)
    table.insert(text, "") table.insert(colours, colour.green)
    return text, colours
end

return competition
