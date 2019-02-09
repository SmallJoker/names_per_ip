-- Created by Krock to stop mass-account-creators
-- License: CC0

if not minetest.safe_file_write then
	error("[simple_protection] Your Minetest version is no longer supported."
		.. " (version < 0.4.17)")
end

ipnames = {}
ipnames.data = {}
ipnames.tmp_data = {}
ipnames.whitelist = {}
ipnames.changes = false
ipnames.save_time = 0
ipnames.file = minetest.get_worldpath().."/ipnames.data"
ipnames.whitelist_file = minetest.get_worldpath().."/ipnames_whitelist.data"

-- Limit 2 = maximal 2 accounts, the 3rd under the same IP gets blocked
ipnames.name_per_ip_limit = tonumber(minetest.setting_get("max_names_per_ip")) or 2
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
	ipnames.tmp_data[name] = ip
	
	if ipnames.data[name] then
		return
	end

	local names = {} -- faster than string concat
	local limit_ext = false
	for k, v in pairs(ipnames.data) do
		if v[1] == ip then
			if not limit_ext and ipnames.whitelist[k] then
				count = count - ipnames.extended_limit
				limit_ext = true
			end
			names[#names + 1] = k
		end
	end
	-- Return error message if too many accounts have been created
	if #names > ipnames.name_per_ip_limit then
		ipnames.tmp_data[name] = nil
		return "\nYou exceeded the limit of accounts.\n" ..
			"You already own the following accounts:\n" .. table.concat(names, ", ")
	end
end)

-- Save IP if player joined
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local t = os.time()
	ipnames.data[name] = {ipnames.tmp_data[name], t}
	ipnames.tmp_data[name] = nil
	ipnames.changes = true
end)

minetest.register_globalstep(function(t)
	ipnames.save_time = ipnames.save_time + t
	if ipnames.save_time < ipnames.save_interval then
		return
	end
	ipnames.save_time = 0
	ipnames.save_data()
end)

minetest.register_on_shutdown(ipnames.save_data)

minetest.after(3, ipnames.load_data)
minetest.after(3, ipnames.load_whitelist)