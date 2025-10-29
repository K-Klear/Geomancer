local COL = {}

local colour_function = {}

function COL.rgb_to_hsv(colour, r, g, b)
	r, g, b = r or colour.x, g or colour.y, b or colour.z
	local M, m = math.max(r, g, b), math.min(r, g, b)
	local C = M - m
	local K = 1.0/(6.0 * C)
	local h = 0.0
	if C ~= 0.0 then
		if M == r then     h = ((g - b) * K) % 1.0
		elseif M == g then h = (b - r) * K + 1.0/3.0
		else               h = (r - g) * K + 2.0/3.0
		end
	end
	return h, (M == 0.0 and 0.0 or C / M), M
end

function COL.hsv_to_rgb(h, s, v)
	local C = v * s
	local m = v - C
	local r, g, b = m, m, m
	if h == h then
		local h_ = (h % 1.0) * 6
		local X = C * (1 - math.abs(h_ % 2 - 1))
		C, X = C + m, X + m
		if     h_ < 1 then r, g, b = C, X, m
		elseif h_ < 2 then r, g, b = X, C, m
		elseif h_ < 3 then r, g, b = m, C, X
		elseif h_ < 4 then r, g, b = m, X, C
		elseif h_ < 5 then r, g, b = X, m, C
		else               r, g, b = C, m, X
		end
	end
	return vmath.vector4(r, g, b, 1)
end

local function hex_to_num(hex)
	local col = tonumber("0x"..hex)
	return col / 255
end

function COL.str_to_colour(str)
	local r, g, b = string.sub(str, 1, 2), string.sub(str, 3, 4), string.sub(str, 5, 6)
	return vmath.vector4(hex_to_num(r), hex_to_num(g), hex_to_num(b), 1)
end

function COL.str_to_hsv(str)
	local r, g, b = string.sub(str, 1, 2), string.sub(str, 3, 4), string.sub(str, 5, 6)
	local h, s, v = COL.rgb_to_hsv(nil, hex_to_num(r), hex_to_num(g), hex_to_num(b))
	return {h = h, s = s, v = v}
end

return COL