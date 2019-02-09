-- WARNING: ipnames.command_* are reserved for chat commands!

function ipnames.command_list(name)
	local names = {} -- faster than string concat
	for k, v in pairs(ipnames.whitelist) do
		if v then
			names[#names + 1] = k
		end
	end
	return true, "All exceptions: " .. table.concat(names, ", ")
end

function ipnames.command_whois(name, param)
	if not ipnames.data[param] then
		return false, "The player '" .. param .. "' did not join yet."
	end
	
	local ip = ipnames.data[param][1]
	local names = ""
	for k, v in pairs(ipnames.data) do
		if v[1] == ip then
			names = names .. " " .. k
		end
	end
	return true, "Following players share an IP: " .. names
end

function ipnames.command_ignore(name, param)
	if not ipnames.data[param] then
		return false, "The player '" .. param .. "' did not join yet."
	end
	
	ipnames.whitelist[param] = true
	ipnames.save_whitelist()
	return true, "Added '" .. param .. "' to the name whitelist."
end

function ipnames.command_unignore(name, param)
	if not ipnames.whitelist[param] then
		return false, "The player '" .. param .. "' is not on the whitelist."
	end
	
	ipnames.whitelist[param] = nil
	ipnames.save_whitelist()
	return true, "Removed '" .. param .. "' from the name whitelist."
end

local player_auth_exists = minetest.player_exists
	or function(name)
		-- 0.4.x support: If you get a nil error here -> update Minetest
		return minetest.auth_table[name]
	end

-- TODO: Use mod storage
function ipnames.load_data()
	local file = io.open(ipnames.file, "r")
	if not file then
		return
	end
	local t = os.time()
	for line in file:lines() do
		local data = line:split("|")
		if #data >= 2 then
			-- Ignore players which were removed (according to auth)
			local player_exists = player_auth_exists(data[1])

			if player_exists then
				data[3] = tonumber(data[3]) or 0
				-- Remove IP after 2 weeks: Expired
				if data[3] > 0 and t - data[3] > (3600 * 24 * 14) then
					player_exists = false
				end
			end
			if player_exists then
				ipnames.data[data[1]] = {data[2], data[3]}
			end
		end
	end
	io.close(file)
end

function ipnames.save_data()
	if not ipnames.changes then
		return
	end
	ipnames.changes = false

	local contents = {} -- faster than string concat
	for k, v in pairs(ipnames.data) do
		v[2] = v[2] or os.time()
		contents[#contents + 1] = k.."|"..v[1].."|"..v[2]
	end
	minetest.safe_file_write(ipnames.file, table.concat(contents, "\n"))
end

function ipnames.load_whitelist()
	local file = io.open(ipnames.whitelist_file, "r")
	if not file then
		return
	end
	for line in file:lines() do
		if line ~= "" then
			ipnames.whitelist[line] = true
		end
	end
	io.close(file)
end

function ipnames.save_whitelist()
	local names = {} -- faster than string concat
	for k, v in pairs(ipnames.whitelist) do
		if v then
			names[#names + 1] = k
		end
	end
	minetest.safe_file_write(ipnames.whitelist_file, table.concat(names, "\n"))
end
