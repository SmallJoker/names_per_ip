-- Created by Krock to stop mass-account-creators
-- License: WTFPL
ipnames = {}
ipnames.data = {}
ipnames.tmp_data = {}
ipnames.whitelist = {}
ipnames.changes = false
ipnames.save_time = 0
ipnames.file = minetest.get_worldpath().."/ipnames.data"
ipnames.whitelist_file = minetest.get_worldpath().."/ipnames_whitelist.data"

-- Limit 2 = maximal 2 accounts, the 3rd under the same IP gets blocked
ipnames.name_per_ip_limit = 2

-- Interval where the IP list gets saved/updated
ipnames.save_interval = 240

dofile(minetest.get_modpath("names_per_ip").."/functions.lua")

minetest.register_chatcommand("ipnames", {
	description = "Get the features of names_per_ip",
	privs = {ban=true},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name, "Available commands: ")
			minetest.chat_send_player(name, "Get all accounts of <name>: /ipnames whois <name>")
			minetest.chat_send_player(name, "List all exceptions:        /ipnames list")
			minetest.chat_send_player(name, "Remove/add an exception:    /ipnames (un)ignore <name>")
			return
		end
		if param == "list" then
			ipnames.command_list(name)
			return
		end
		
		local args = param:split(" ")
		if #args < 2 then
			minetest.chat_send_player(name, "Error: Please check again '/ipnames' for correct usage.")
			return
		end
		
		if args[1] == "whois" then
			ipnames.command_whois(name, args[2])
		elseif args[1] == "ignore" then
			ipnames.command_ignore(name, args[2])
		elseif args[1] == "unignore" then
			ipnames.command_unignore(name, args[2])
		else
			minetest.chat_send_player(name, "Error: No known argument for #1 '"..args[1].."'")
		end
	end
})

-- Get IP if player tries to join, ban if there are too much names per IP
minetest.register_on_prejoinplayer(function(name, ip)
	-- Only stop new accounts
	ipnames.tmp_data[name] = ip
	
	if ipnames.data[name] then
		return
	end
	
	local count = 1
	local names = ""
	for k, v in pairs(ipnames.data) do
		if v[1] == ip then
			if ipnames.whitelist[k] then
				count = 0
				break
			end
			count = count + 1
			names = names..k..", "
		end
	end
	-- Return error message if too many accounts have been created
	if count > ipnames.name_per_ip_limit then
		ipnames.tmp_data[name] = nil
		return ("\nYou exceeded the limit of accounts.\nYou already own the following accounts:\n"..names)
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

minetest.register_on_shutdown(function() ipnames.save_data() end)

minetest.after(3, function() ipnames.load_data() end)
minetest.after(3, function() ipnames.load_whitelist() end)