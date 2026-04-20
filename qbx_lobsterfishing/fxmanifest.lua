fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Cascade'
description 'Lobster Fishing Script for QBX'
version '1.0.0'

shared_scripts {
    '@qbx_core/shared/locale.lua',
    '@ox_lib/init.lua',
    'locales/en.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@qbx_core/server/player.lua',
    'server/main.lua'
}

dependencies {
    'qbx_core',
    'ox_lib'
}
