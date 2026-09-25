fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Grupo Capital"
description "Resource desenvolvido por Grupo Capital"
version "1.0.0"

shared_scripts { "@vrp/lib/utils.lua", "*.config.lua" }
client_scripts { "*.client.lua" }
server_scripts { "@oxmysql/lib/MySQL.lua", "*.server.lua", "*.sconfig.lua" }

ui_page "nui/dist/index.html"

files { "nui/dist/**/*" }
