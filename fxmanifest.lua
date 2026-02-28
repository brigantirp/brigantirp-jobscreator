fx_version 'cerulean'
game 'gta5'

name 'brigantirp-jobscreator'
author 'brigantirp'
description 'Advanced FiveM Job Creator with modern NUI interface'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/styles.css',
    'web/app.js'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
