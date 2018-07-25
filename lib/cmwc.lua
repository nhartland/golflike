--[[

 cmwc4096 -- v0.3.0 public domain Lua persistent CMWC4096 PRNG
 no warranty implied; use at your own risk

 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/lbase64

 Initial state is generated by LCG with glib constants. Includes verison for
 32 and 64 bits percision (53 actually) number generation. API is not very
 convinient because of functional style. Generates new chunk each cycle (4096
 numbers), so GC won't be choking. Simple benchmarks show that 32-bit random
 is about 6 times slower than math.random (or 2-3 times slower than LuaJIT
 random).

 COMPATIBILITY

 Lua 5.1, 5.2, 5.3, LuaJIT 1, 2

 LICENSE

 This software is dual-licensed to the public domain and under the following
 license: you are granted a perpetual, irrevocable license to copy, modify,
 publish, and distribute this file as you see fit.

--]]

local floor = math.floor

local Cmwc = {}

local zeros4097 = (function()
	return (_G.loadstring or load)( 'return {0' .. (',0'):rep(4096) .. '}' )
end)()

local function nextstate( qc, i, newqc )
	if i < 4096 then
		return qc, i + 1
	else
		local c = qc[4097]
		newqc = newqc or zeros4097()
		for j = 1, 4096 do
			local t = 18782 * qc[j] + c
			c = floor( t * (1.0/4294967296.0))
			local x = (t + c) % 0x100000000
			if x < c then
				x, c = x + 1, c + 1
			end
			if x > 0xfffffffe then
				newqc[j] = 8589934590 - x
			else
				newqc[j] = 0xfffffffe - x
			end
		end
		newqc[4097] = c
		return newqc, 1
	end
end

function Cmwc.make( seed )
	local qc = zeros4097()
	local c = seed or 433494437
	for i = 1, 4097 do
		c = c * 129749
		c = c % 0x100000000
		c = c * 8505
		c = c + 12345
		c = c % 0x100000000
		qc[i] = c
	end
	qc[4097] = c % 809430660
	return nextstate( qc, 4096, qc )
end

function Cmwc.rand( qc, i )
	return qc[i], nextstate( qc, i )
end

function Cmwc.random32( qc, i, min, max )
	if max == nil then
		if min == nil then
			return qc[i] * (1/4294967296.0), nextstate( qc, i )
		elseif min >= 1 then
			return qc[i] % floor( min ) + 1, nextstate( qc, i )
		else
			error( 'bad argument #1 to \'random\' (interval is empty)' )
		end
	else
		if min < max then
			return qc[i] % floor( max - min ) + min, nextstate( qc, i )
		elseif min == max then
			return min, nextstate( qc, i )
		else
			error( 'bad argument #2 to \'random\' (interval is empty)' )
		end
	end
end

function Cmwc.random64( qc, i, min, max )
	local a = qc[i] * 67108864
	qc, i = nextstate( qc, i )
	a = a + qc[i]
	qc, i = nextstate( qc, i )
	if max == nil then
		if min == nil then
			return a * (1.0/9007199254740992.0), qc, i
		elseif min >= 1 then
			return a % floor( min ) + 1, qc, i
		else
			error( 'bad argument #1 to \'random\' (interval is empty)' )
		end
	else
		if min < max then
			return a % floor( max - min ) + min, qc, i
		elseif min == max then
			return min, qc, i
		else
			error( 'bad argument #2 to \'random\' (interval is empty)' )
		end
	end
end

return Cmwc
