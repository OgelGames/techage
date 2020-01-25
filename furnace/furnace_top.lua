--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	TA3 Industrial Furnace Top

]]--

-- for lazy programmers
local M = minetest.get_meta
local S = techage.S
local D = techage.Debug

-- Consumer Related Data
local CRD = function(pos) return (minetest.registered_nodes[techage.get_node_lvm(pos).name] or {}).consumer end

local STANDBY_TICKS = 6
local COUNTDOWN_TICKS = 6
local CYCLE_TIME = 2

local smelting = techage.furnace.smelting
local get_output = techage.furnace.get_output
local num_recipes = techage.furnace.get_num_recipes
local reset_cooking = techage.furnace.reset_cooking
local get_ingredients = techage.furnace.get_ingredients
local check_if_worth_to_wakeup = techage.furnace.check_if_worth_to_wakeup
local range = techage.in_range


local function update_recipe_menu(pos, mem)
	local ingr = get_ingredients(pos)
	mem.rp_num = num_recipes(ingr)
	mem.rp_idx = range(mem.rp_idx or 1, 0, mem.rp_num)
	mem.rp_outp = get_output(mem, ingr, mem.rp_idx)
end

local function formspec(self, pos, mem)
	local idx = mem.rp_idx or 1
	local num = mem.rp_num or 1
	local outp = mem.rp_outp or ""
	return "size[8,7.2]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;src;0,0;2,2;]"..
		"image[2,0.5;1,1;techage_form_arrow_bg.png^[lowpart:"..
		(mem.item_percent or 0)..":techage_form_arrow_fg.png^[transformR270]"..
		"image_button[2,2;1,1;".. self:get_state_button_image(mem) ..";state_button;]"..
		"tooltip[2,2;1,1;"..self:get_state_tooltip(mem).."]"..

		"list[context;dst;3,0;2,2;]"..
		
		"label[6,0;"..S("Outp")..": "..idx.."/"..num.."]"..
		"item_image_button[6.5,0.5;1,1;"..outp..";b1;]"..
		"button[6,1.5;1,1;priv;<<]"..
		"button[7,1.5;1,1;next;>>]"..
		
		"list[current_player;main;0,3.5;8,4;]" ..
		"listring[current_player;main]"..
		"listring[context;src]" ..
		"listring[current_player;main]"..
		"listring[context;dst]" ..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 3.5)
end

local function on_rightclick(pos, node, clicker)
	local mem = tubelib2.get_mem(pos)
	M(pos):set_string("formspec", formspec(CRD(pos).State, pos, mem))
end

local function firebox_cmnd(pos, cmnd)
	return techage.transfer(
		{x=pos.x, y=pos.y-1, z=pos.z}, 
		nil,  -- outdir
		cmnd,  -- topic
		nil,  -- payload
		nil,  -- network
		{"techage:furnace_firebox", "techage:furnace_firebox_on",
		 "techage:furnace_heater", "techage:furnace_heater_on"})
end

local function cooking(pos, crd, mem, elapsed)
	if mem.techage_state == techage.RUNNING or check_if_worth_to_wakeup(pos, mem) then
		if firebox_cmnd(pos, "fuel") then
			local state, err = smelting(pos, mem, elapsed)
			if state == techage.RUNNING then
				crd.State:keep_running(pos, mem, COUNTDOWN_TICKS)
			elseif state == techage.BLOCKED then
				crd.State:blocked(pos, mem)
			elseif state == techage.FAULT then
				crd.State:fault(pos, mem, err)
			elseif state == techage.STANDBY then
				crd.State:idle(pos, mem)
			end
		else
			crd.State:idle(pos, mem)
		end
	end
end

local function keep_running(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	local crd = CRD(pos)
	cooking(pos, crd, mem, elapsed)
	mem.toggle = not mem.toggle
	if mem.toggle then -- progress bar/arrow
		M(pos):set_string("formspec", formspec(crd.State, pos, mem))
	end
	return crd.State:is_active(mem)
end	

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if listname == "src" then
		local mem = tubelib2.get_mem(pos)
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function on_metadata_inventory(pos)
	local mem = tubelib2.get_mem(pos)
	local crd = CRD(pos)
	M(pos):set_string("formspec", formspec(crd.State, pos, mem))
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	mem.rp_idx = mem.rp_idx or 1
	if fields.next == ">>" then
		local ingr = get_ingredients(pos)
		mem.rp_idx = math.min(mem.rp_idx + 1, num_recipes(ingr))
		update_recipe_menu(pos, mem)
		M(pos):set_string("formspec", formspec(CRD(pos).State, pos, mem))
		reset_cooking(mem)
	elseif fields.priv == "<<" then
		local ingr = get_ingredients(pos)
		mem.rp_idx = range(mem.rp_idx - 1, 1, num_recipes(ingr))
		update_recipe_menu(pos, mem)
		M(pos):set_string("formspec", formspec(CRD(pos).State, pos, mem))
		reset_cooking(mem)
	end
	CRD(pos).State:state_button_event(pos, mem, fields)
end

local function can_dig(pos, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return false
	end
	local inv = M(pos):get_inventory()
	return inv:is_empty("dst") and inv:is_empty("src")
end

local function can_start(pos, mem, state)
	if D.dbg2 then D.dbg("can_start", state, firebox_cmnd(pos, "fuel")) end
	if not firebox_cmnd(pos, "fuel") then
		return S("no fuel or no power")
	end
	return true
end

local function on_node_state_change(pos, old_state, new_state)
	if D.dbg2 then D.dbg("on_node_state_change", new_state) end
	local pwr1 = techage.needs_power2(old_state)
	local pwr2 = techage.needs_power2(new_state)
	if pwr1 ~= pwr2 then
		if pwr2 then
			firebox_cmnd(pos, "start")
		else
			firebox_cmnd(pos, "stop")
		end
	end
	local mem = tubelib2.get_mem(pos)
	reset_cooking(mem)
end

local tiles = {}

-- '#' will be replaced by the stage number
tiles.pas = {
	-- up, down, right, left, back, front
	"techage_concrete.png^techage_frame_ta#_top.png",
	"techage_concrete.png^techage_frame_ta#_top.png",
	"techage_concrete.png^techage_frame_ta#.png",
	"techage_concrete.png^techage_frame_ta#.png",
	"techage_concrete.png^techage_frame_ta#.png",
	"techage_concrete.png^techage_appl_furnace.png^techage_frame_ta#.png",
}
tiles.act = tiles.pas

local tubing = {
	on_pull_item = function(pos, in_dir, num)
		local meta = minetest.get_meta(pos)
		if meta:get_int("pull_dir") == in_dir then
			local inv = M(pos):get_inventory()
			return techage.get_items(inv, "dst", num)
		end
	end,
	on_push_item = function(pos, in_dir, stack)
		local meta = minetest.get_meta(pos)
		if meta:get_int("push_dir") == in_dir  or in_dir == 5 then
			local inv = M(pos):get_inventory()
			return techage.put_items(inv, "src", stack)
		end
	end,
	on_unpull_item = function(pos, in_dir, stack)
		local meta = minetest.get_meta(pos)
		if meta:get_int("pull_dir") == in_dir then
			local inv = M(pos):get_inventory()
			return techage.put_items(inv, "dst", stack)
		end
	end,
	on_recv_message = function(pos, src, topic, payload)
		local resp = CRD(pos).State:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		CRD(pos).State:on_node_load(pos)
	end,
}

local _, node_name_ta3, _ = 
	techage.register_consumer("furnace", S("Furnace Top"), tiles, {
		drawtype = "normal",
		cycle_time = CYCLE_TIME,
		standby_ticks = STANDBY_TICKS,
		formspec = formspec,
		tubing = tubing,
		can_start = can_start,
		on_state_change = on_node_state_change,
		after_place_node = function(pos, placer)
			local inv = M(pos):get_inventory()
			inv:set_size("src", 2*2)
			inv:set_size("dst", 2*2)
		end,
		can_dig = can_dig,
		node_timer = keep_running,
		on_receive_fields = on_receive_fields,
		allow_metadata_inventory_put = allow_metadata_inventory_put,
		allow_metadata_inventory_move = allow_metadata_inventory_move,
		allow_metadata_inventory_take = allow_metadata_inventory_take,
		on_metadata_inventory_put = on_metadata_inventory,
		on_metadata_inventory_take = on_metadata_inventory,
		on_metadata_inventory_move = on_metadata_inventory,
		groups = {choppy=2, cracky=2, crumbly=2},
		sounds = default.node_sound_wood_defaults(),
		num_items = {0,1,1,1},
	},
	{false, false, true, false})  -- TA3 only



minetest.register_craft({
	output = node_name_ta3,
	recipe = {
		{"", "techage:usmium_nuggets", ""},
		{"default:steel_ingot", "default:furnace", "default:steel_ingot"},
		{"", "techage:vacuum_tube", ""},
	},
})

