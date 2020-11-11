name = ' auto_explore'
description = 'Client mod. Automatically explore map'
author = 'Flameleo'
version = '20200413'
forumthread = ''
api_version = 10
dst_compatible = true
client_only_mod = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
icon_atlas = 'modicon.xml'
icon = 'modicon.tex'
server_filter_tags = {}

local keys = {
	"None", "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"LSHIFT","LALT","LCTRL","TAB","BACKSPACE","PERIOD","SLASH","TILDE",
}

configuration_options = {
	{
		name = "MOUNT_KEY",
		label = "mount key",
		hover = "dismount or mount last",
		options = {
			--fill later
		},
		default = "H",
	},
	{
		name = "AUTO_DISMOUNT",
		label = "Auto Dismount",
		hover = "auto dismount beefalo when delay over",
		options = {
			{description = "enable", data = true},
			{description = "disable", data = false},
		},
		default = true,
	},
}
local function filltable(tbl)
	for i=1, #keys do
		tbl[i] = {description = keys[i], data = keys[i]}
	end
end
filltable(configuration_options[1].options)