names_per_ip
============

A mod for Minetest to stop annoyed kids
It will limit the accounts to 2 per IP (if the player is not whitelisted) and delete old IPs.

Initial mod creator: Krock

License: WTFPL

Depends: nothing

Chat commands
-------------

	/ipnames

		whois <name>		-> Gets all accounts of <name>

		list				-> Lists all exceptions/whitelist entries (players which can have "unlimited" accounts)

		ignore <name>		-> Adds an exception/whitelist entry for <name>
	
		unignore <name>		-> Removes an exception/whitelist entry for <name>
