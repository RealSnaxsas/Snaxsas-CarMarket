fx_version "cerulean"
game "gta5"

author "Snaxsas"
description "Lithiux automobiliu turgus"
version "1.1.0"

shared_script "@es_extended/imports.lua"
shared_script "@oxmysql/lib/MySQL.lua"

client_scripts {
    "config.lua",
    "client/main.lua"
}

server_scripts {
    "config.lua",
    "server/main.lua"
}

dependencies {
    "es_extended",
    "oxmysql"
}