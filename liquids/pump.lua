--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	TA3/TA4 Pump

]]--

local S2P = minetest.string_to_pos
local P2S = minetest.pos_to_string
local M = minetest.get_meta
local S = techage.S
local Pipe = techage.LiquidPipe
local networks = techage.networks
local liquid = techage.liquid
local Flip = techage.networks.Flip

local STANDBY_TICKS = 10
local COUNTDOWN_TICKS = 10
local CYCLE_TIME = 2
local CAPA = 4

local State3 = techage.NodeStates:new({
	node_name_passive = "techage:t3_pump",
	node_name_active = "techage:t3_pump_on",
	infotext_name = S("TA3 Pump"),
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
})

local State4 = techage.NodeStates:new({
	node_name_passive = "techage:t4_pump",
	node_name_active = "techage:t4_pump_on",
	infotext_name = S("TA4 Pump"),
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
})

local function pumping(pos, mem, state, capa)
	local outdir = M(pos):get_int("outdir")
	local taken, name = liquid.take(pos, Flip[outdir], nil, capa)
	if taken > 0 then
		local leftover = liquid.put(pos, outdir, name, taken)
		if leftover and leftover > 0 then
			liquid.put(pos, Flip[outdir], name, leftover)
			state:blocked(pos, mem)
			return
		end
		state:keep_running(pos, mem, COUNTDOWN_TICKS)
		return
	end
	state:idle(pos, mem)
end

local function after_place_node3(pos, placer)
	local mem = tubelib2.init_mem(pos)
	local number = techage.add_node(pos, "techage:t3_pump")
	State3:node_init(pos, mem, number)
	M(pos):set_int("outdir", networks.side_to_outdir(pos, "R"))
	Pipe:after_place_node(pos)
end

local function after_place_node4(pos, placer)
	local mem = tubelib2.init_mem(pos)
	local number = techage.add_node(pos, "techage:t4_pump")
	State4:node_init(pos, mem, number)
	M(pos):set_int("outdir", networks.side_to_outdir(pos, "R"))
	Pipe:after_place_node(pos)
end

local function node_timer3(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	pumping(pos, mem, State3, CAPA)
	return true
end	

local function node_timer4(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	pumping(pos, mem, State4, CAPA * 2)
	return true
end	

local function on_rightclick(pos, node, clicker)
	local mem = tubelib2.get_mem(pos)
	if node.name == "techage:t3_pump" then
		State3:start(pos, mem)
	elseif node.name == "techage:t3_pump_on" then
		State3:stop(pos, mem)
	elseif node.name == "techage:t4_pump" then
		State4:start(pos, mem)
	elseif node.name == "techage:t4_pump_on" then
		State4:stop(pos, mem)
	end
end

local function tubelib2_on_update2(pos, outdir, tlib2, node)
	liquid.update_network(pos, outdir)
end

local function after_dig_node(pos, oldnode, oldmetadata, digger)
	Pipe:after_dig_node(pos)
end

local ta3_tiles_pas = {
	-- up, down, right, left, back, front
	"techage_filling_ta3.png^techage_frame_ta3_top.png^techage_appl_arrow.png",
	"techage_filling_ta3.png^techage_frame_ta3.png",
	"techage_filling_ta3.png^techage_appl_hole_pipe.png^techage_frame_ta3.png",
	"techage_filling_ta3.png^techage_appl_hole_pipe.png^techage_frame_ta3.png",
	"techage_filling_ta3.png^techage_appl_pump.png^techage_frame_ta3.png^[transformFX",
	"techage_filling_ta3.png^techage_appl_pump.png^techage_frame_ta3.png",
}

local ta4_tiles_pas = {
	-- up, down, right, left, back, front
	"techage_filling_ta4.png^techage_frame_ta4_top.png^techage_appl_arrow.png",
	"techage_filling_ta4.png^techage_frame_ta4.png",
	"techage_filling_ta4.png^techage_appl_hole_pipe.png^techage_frame_ta4.png",
	"techage_filling_ta4.png^techage_appl_hole_pipe.png^techage_frame_ta4.png",
	"techage_filling_ta4.png^techage_appl_pump.png^techage_frame_ta4.png^[transformFX",
	"techage_filling_ta4.png^techage_appl_pump.png^techage_frame_ta4.png",
}

local ta3_tiles_act = {
	-- up, down, right, left, back, front
	"techage_filling_ta3.png^techage_frame_ta3_top.png^techage_appl_arrow.png",
	"techage_filling_ta3.png^techage_frame_ta3.png",
	"techage_filling_ta3.png^techage_appl_hole_pipe.png^techage_frame_ta3.png",
	"techage_filling_ta3.png^techage_appl_hole_pipe.png^techage_frame_ta3.png",
	{
		image = "techage_filling8_ta3.png^techage_appl_pump8.png^techage_frame8_ta3.png^[transformFX",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 2.0,
		},
	},
	{
		image = "techage_filling8_ta3.png^techage_appl_pump8.png^techage_frame8_ta3.png",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 2.0,
		},
	},
}

local ta4_tiles_act = {
	-- up, down, right, left, back, front
	"techage_filling_ta4.png^techage_frame_ta4_top.png^techage_appl_arrow.png",
	"techage_filling_ta4.png^techage_frame_ta4.png",
	"techage_filling_ta4.png^techage_appl_hole_pipe.png^techage_frame_ta4.png",
	"techage_filling_ta4.png^techage_appl_hole_pipe.png^techage_frame_ta4.png",
	{
		image = "techage_filling8_ta4.png^techage_appl_pump8.png^techage_frame8_ta4.png^[transformFX",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 2.0,
		},
	},
	{
		image = "techage_filling8_ta4.png^techage_appl_pump8.png^techage_frame8_ta4.png",
		backface_culling = false,
		animation = {
			type = "vertical_frames",
			aspect_w = 32,
			aspect_h = 32,
			length = 2.0,
		},
	},
}

local nworks = {
	pipe = {
		sides = {L = 1, R = 1}, -- Pipe connection side
		ntype = "pump",
	},
}

minetest.register_node("techage:t3_pump", {
	description = S("TA3 Pump"),
	tiles = ta3_tiles_pas,
	after_place_node = after_place_node3,
	on_rightclick = on_rightclick,
	tubelib2_on_update2 = tubelib2_on_update2,
	--on_timer = node_timer3,
	after_dig_node = after_dig_node,
	on_rotate = screwdriver.disallow,
	networks = nworks,
	paramtype2 = "facedir",
	on_rotate = screwdriver.disallow,
	groups = {cracky=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("techage:t3_pump_on", {
	description = S("TA3 Pump"),
	tiles = ta3_tiles_act,
	--after_place_node = after_place_node3,
	on_rightclick = on_rightclick,
	tubelib2_on_update2 = tubelib2_on_update2,
	on_timer = node_timer3,
	after_dig_node = after_dig_node,
	on_rotate = screwdriver.disallow,
	networks = nworks,
	paramtype2 = "facedir",
	on_rotate = screwdriver.disallow,
	diggable = false,
	groups = {not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("techage:t4_pump", {
	description = S("TA4 Pump"),
	tiles = ta4_tiles_pas,
	after_place_node = after_place_node4,
	on_rightclick = on_rightclick,
	tubelib2_on_update2 = tubelib2_on_update2,
	--on_timer = node_timer4,
	after_dig_node = after_dig_node,
	on_rotate = screwdriver.disallow,
	networks = nworks,
	paramtype2 = "facedir",
	on_rotate = screwdriver.disallow,
	groups = {cracky=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("techage:t4_pump_on", {
	description = S("TA4 Pump"),
	tiles = ta4_tiles_act,
	--after_place_node = after_place_node4,
	on_rightclick = on_rightclick,
	tubelib2_on_update2 = tubelib2_on_update2,
	on_timer = node_timer4,
	after_dig_node = after_dig_node,
	on_rotate = screwdriver.disallow,
	networks = nworks,
	paramtype2 = "facedir",
	on_rotate = screwdriver.disallow,
	diggable = false,
	groups = {not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

techage.register_node({"techage:t3_pump", "techage:t3_pump_on"}, {
	on_recv_message = function(pos, src, topic, payload)
		local resp = State3:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		State3:on_node_load(pos)
	end,
})

techage.register_node({"techage:t4_pump", "techage:t4_pump_on"}, {
	on_recv_message = function(pos, src, topic, payload)
		local resp = State4:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		State4:on_node_load(pos)
	end,
})

Pipe:add_secondary_node_names({
	"techage:t3_pump", "techage:t3_pump_on",
	"techage:t4_pump", "techage:t4_pump_on",
})
 
  