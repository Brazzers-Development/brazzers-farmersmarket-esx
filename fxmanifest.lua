fx_version 'cerulean'
game 'gta5'

name "Brazzers Farmers Market"
author "Brazzers Development | MannyOnBrazzers#6826"
version "1.0"

lua54 'yes'

client_scripts {
    'client/*.lua',
    '@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
    '@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
}

server_scripts {
    'server/*.lua',
    '@oxmysql/lib/MySQL.lua',
}

shared_scripts {
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'@ox_lib/init.lua',
	'locales/*.lua',
	'shared/*.lua',
}