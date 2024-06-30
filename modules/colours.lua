local MEM = require "modules.memory"
local SET = require "modules.settings"
local COL = {}

COL.current_colours = {main = SET.custom_colour_main, fog = SET.custom_colour_fog, glow = SET.custom_colour_glow, enemy = SET.custom_colour_enemy}

local colour_function = {}

local function rgb_to_hsv(colour)
	local r, g, b = colour.x, colour.y, colour.z
	local M, m = math.max( r, g, b ), math.min( r, g, b )
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

local function hsv_to_rgb(h, s, v)
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

function COL.set_current(tab)
	COL.current_colours = {main = tab.main, fog = tab.fog, glow = tab.glow, enemy = tab.enemy}
	msg.post("/model_viewer", hash("colours_changed"))
end

function COL.set_current_to_default()
	local colour_tab = MEM.art_data.colours
	if SET.default_colour_set < 1 then
		COL.set_current(colour_tab[#colour_tab])
	else
		COL.set_current(colour_tab[math.min(SET.default_colour_set, #colour_tab - 1)])
	end
end

function COL.get_current(colour)
	return colour_function[colour]()
end

function colour_function.main() return COL.str_to_colour(COL.current_colours.main) end
function colour_function.glow() return COL.str_to_colour(COL.current_colours.glow) end
function colour_function.glow_invert()
	local h, s, v = rgb_to_hsv(COL.str_to_colour(COL.current_colours.glow))
	h = (h - 0.5) % 1
	return hsv_to_rgb(h, s, v)
end
function colour_function.white() return vmath.vector4(1, 1, 1, 1) end
function colour_function.black() return vmath.vector4(0, 0, 0, 1) end
function colour_function.light_black() return vmath.vector4(0.1, 0.1, 0.1, 1) end
function colour_function.transparent()
	local c = COL.str_to_colour(COL.current_colours.fog)
	local h, s, v = rgb_to_hsv(c)
	c.w = v
	return c
end
function colour_function.fog() return COL.str_to_colour(COL.current_colours.fog) end
function colour_function.enemy() return COL.str_to_colour(COL.current_colours.enemy) end
function colour_function.shields() return vmath.vector4(0.654, 1, 1, 1) end
function colour_function.dead() return vmath.vector4(0.827, 0, 0.459, 1) end

local tex_glow = hash("glow")
local tex_prop = hash("prop")
local tex_shaded = hash("shaded")
local tex_cont_1 = hash("cont_1")
local tex_cont_2 = hash("cont_2")
local tex_ped = hash("ped")
local tex_shield = hash("shield")
local tex_funky = hash("funky")


COL.materials = {
	-- default
	["(DoNotEdit)LiveMat_Props"] = {tint = colour_function.main},
	["(DoNotEdit)LiveMat_LevelGeoSimple"] = {tint = colour_function.main},
	["(DoNotEdit)LiveMat_Glow"] = {tint = colour_function.glow, texture = tex_glow},
	["(DoNotEdit)LiveMat_GlowInvert"] = {tint = colour_function.glow_invert, texture = tex_glow},
	--variants of standard
	["(DoNotEdit)LiveMat_Pedestrians_Dissolve"] = {tint = colour_function.fog, texture = tex_glow},
	["(DoNotEdit)LiveMat_Continental Interior 1"] = {tint = colour_function.main, texture = tex_cont_1},
	["(DoNotEdit)LiveMat_Continental Interior 2"] = {tint = colour_function.main, texture = tex_cont_2},
	["(DoNotEdit)LiveMat_FrontEnd_Building"] = {tint = colour_function.main, texture = tex_cont_1},
	["(DoNotEdit)LiveMat_LevelGeoComplex"] = {tint = colour_function.main},
	["(DoNotEdit)LiveMat_Enemies_Targets"] = {tint = colour_function.enemy},
	--white
	["(DoNotEdit)LiveMat_EnemyGlow"] = {tint = colour_function.white, texture = tex_glow},
	["(DoNotEdit)LiveMat_EnemyGlow_Gun"] = {tint = colour_function.white, texture = tex_glow},
	["(DoNotEdit)LiveMat_ParticleMesh_EnviroColor"] = {tint = colour_function.white, texture = tex_glow},
	["(DoNotEdit)LiveMat_ParticleMesh_Glow"] = {tint = colour_function.white, texture = tex_glow},
	--black
	["(DoNotEdit)LiveMat_MegaHitTrail"] = {tint = colour_function.black, texture = tex_glow},
	["(DoNotEdit)LiveMat_Gunmat New Three Color"] = {tint = colour_function.light_black, texture = tex_shaded},
	--transparent
	["(DoNotEdit)LiveMat_Player_MuzzleFlashSquirtgun"] = {tint = colour_function.transparent, texture = tex_glow},
	["(DoNotEdit)LiveMat_Squirtgun_drops"] = {tint = colour_function.transparent, texture = tex_glow},
	-- combinations
	["(DoNotEdit)LiveMat_Obstacles"] = {tint = colour_function.main},
	["(DoNotEdit)LiveMat_MRObstacles"] = {tint = colour_function.main},
	["(DoNotEdit)LiveMat_Props_NoDistortion"] = {tint = colour_function.main},
	["(DoNotEdit)LiveMat_ParticleMesh_GlowMultiply"] = {tint = colour_function.fog, texture = tex_glow},
	["(DoNotEdit)LiveMat_Pedestrians"] = {tint = colour_function.main, texture = tex_ped},
	["(DoNotEdit)LiveMat_PedestriansAlt"] = {tint = colour_function.enemy, texture = tex_ped},
	-- unique
	["(DoNotEdit)LiveMat_Enemies_Shielded"] = {tint = colour_function.shields, texture = tex_shield},
	["(DoNotEdit)LiveMat_Beatcubes_mat"] = {tint = colour_function.glow, texture = tex_shaded},
	["(DoNotEdit)LiveMat_Enemies_DeadBody"] = {tint = colour_function.dead, texture = tex_funky},
	-- chaotic
	["(DoNotEdit)LiveMat_Enemies"] = {tint = colour_function.main, texture = tex_funky},
	["(DoNotEdit)LiveMat_Boss"] = {tint = colour_function.main, texture = tex_funky},
	["(DoNotEdit)LiveMat_PlayerRingOuter2"] = {tint = colour_function.main, texture = tex_funky},
}



return COL