-- Created by Krock to stop mass-account-creators
-- License: CC0

if not minetest.safe_file_write then
	error("[simple_protection] Your Minetest version is no longer supported."
		.. " (version < 0.4.17)")
end

ipnames = {}
ipnames.data = {}
ipnames.whitelist = {}
ipnames.changes = false
ipnames.file = minetest.get_worldpath().."/ipnames.data"
ipnames.whitelist_file = minetest.get_worldpath().."/ipnames_whitelist.data"

-- Limit 2 = maximal 2 accounts, the 3rd under the same IP gets blocked
ipnames.name_per_ip_limit = tonumber(minetest.settings:get("max_names_per_ip")) or 2
-- 2 + 3 = 5 accounts as limit for "ignored" players
ipnames.extended_limit = 3

-- Interval where the IP list gets saved/updated
ipnames.save_interval = 240

dofile(minetest.get_modpath("names_per_ip").."/functions.lua")

minetest.register_chatcommand("ipnames", {
	description = "Get the features of names_per_ip",
	privs = {ban=true},
	func = function(name, param)
		if param == "" then
			return true,
				"Available commands:\n" ..
				"Get all accounts of <name>: /ipnames whois <name>\n" ..
				"Show all whitelisted names: /ipnames list\n" ..
				"Add/remove whitelist entry: /ipnames (un)ignore <name>"
		end
		if param == "list" then
			return ipnames.command_list(name)
		end

		-- Commands with two arguments
		local args = param:split(" ")
		if #args < 2 then
			return false, "Error: Too few command arguments."
		end

		local func = ipnames["command_" .. args[1]]
		if func then
			return func(name, args[2])
		end

		return false, "Error: No known action for argument #1 ('"..args[1].."')"
	end
})

-- Get IP if player tries to join, ban if there are too much names per IP
minetest.register_on_prejoinplayer(function(name, ip)
	-- Only stop new accounts
	if ipnames.data[name] or ipnames.is_registered(name) then
		return
	end

	local names = {} -- faster than string concat
	local count_bonus = nil
	for k, v in pairs(ipnames.data) do
		if v[1] == ip then
			if not count_bonus and ipnames.whitelist[k] then
				count_bonus = ipnames.extended_limit
			end
			names[#names + 1] = k
		end
	end

	-- Return error message if too many accounts have been created
	if #names > ipnames.name_per_ip_limit + (count_bonus or 0) then
		return "\nYou exceeded the limit of accounts.\n" ..
			"You already own the following accounts:\n" .. table.concat(names, ", ")
	end
end)

-- Save IP if player joined
local function update_player_address(name, recursive)
	local info = minetest.get_player_information(name)
	local address = info and info.address

	if not address then
		minetest.log("warning", "[names_per_ip] minetest.get_player_information(\"" ..
			name .. "\"): " .. dump(info) .. ". This is probably an engine bug.")
		if not recursive then
			-- Delay, hope it works next time
			minetest.after(0.5, update_player_address, name, true)
			return
		end
	end

	ipnames.data[name] = {
		address or "??",
		os.time()
	}

	ipnames.changes = true
end

minetest.register_on_joinplayer(function(player)
	update_player_address(player:get_player_name())
end)

-- Data saving routine
-- Save changes at a fixed interval
local function save_data_job()
	ipnames.save_data()
	minetest.after(ipnames.save_interval, save_data_job)
end
minetest.after(ipnames.save_interval, save_data_job)
minetest.register_on_shutdown(ipnames.save_data)

-- Due to use of minetest.player_exists, the data loading must be delayed
-- until ServerEnvironment is set up. register_on_mods_loaded is still too early.
minetest.after(0, ipnames.load_data)

ipnames.load_whitelist()
