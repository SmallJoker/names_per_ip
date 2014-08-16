function ipnames.command_list(name)
	local names = ""
	for k, v in pairs(ipnames.whitelist) do
		names = names.." "..k
	end
	minetest.chat_send_player(name, "All exceptions: "..names)
end

function ipnames.command_whois(name, param)
	if not ipnames.data[param] then
		minetest.chat_send_player(name, "The player '"..param.."' did not join yet.")
		return
	end
	
	local ip = ipnames.data[param][1]
	local names = ""
	for k, v in pairs(ipnames.data) do
		if v[1] == ip then
			names = names.." "..k
		end
	end
	minetest.chat_send_player(name, "Following players share an IP: "..names)
end

function ipnames.command_ignore(name, param)
	if not ipnames.data[param] then
		minetest.chat_send_player(name, "The player '"..param.."' did not join yet.")
		return
	end
	
	ipnames.whitelist[param] = true
	minetest.chat_send_player(name, "Added an exception!")
	ipnames.save_whitelist()
end

function ipnames.command_unignore(name, param)
	if not ipnames.whitelist[param] then
		minetest.chat_send_player(name, "The player '"..param.."' is not on the whitelist.")
		return
	end
	
	ipnames.whitelist[param] = nil
	minetest.chat_send_player(name, "Removed an exception!")
	ipnames.save_whitelist()
end

function ipnames.load_data()
	local file = io.open(ipnames.file, "r")
	if not file then
		return
	end
	local t = os.time()
	for line in file:lines() do
		if line ~= "" then
			local data = line:split("|")
			if #data >= 2 then
				-- Special stuff - only save if player has not been deleted yet
				local ignore = false
				if not minetest.auth_table[data[1]] then
					ignore = true
				end
				if not ignore then
					data[3] = tonumber(data[3]) or 0
					-- Remove IP after 2 weeks
					if data[3] > 0 and t - data[3] > (3600 * 24 * 14) then
						ignore = true
					end
				end
				if not ignore then
					ipnames.data[data[1]] = {data[2], data[3]}
				end
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
	local file = io.open(ipnames.file, "w")
	for k, v in pairs(ipnames.data) do
		if v[2] > 0 then
			file:write(k.."|"..v[1].."|"..v[2].."\n")
		else
			file:write(k.."|"..v[1].."\n")
		end
	end
	io.close(file)
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
end

function ipnames.save_whitelist()
	local file = io.open(ipnames.whitelist_file, "w")
	for k, v in pairs(ipnames.whitelist) do
		if v ~= nil then
			file:write(k.."\n")
		end
	end
	io.close(file)
end