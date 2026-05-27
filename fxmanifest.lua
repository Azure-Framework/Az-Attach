fx_version 'cerulean' 
game 'gta5'

author 'Valencia Modifications'
description 'Attach Vehicles'
version '0.0.1'
lua54 'yes' 

client_scripts {
    'source/attach_c.lua'  
}

server_scripts {
    'source/attach_s.lua',  
}

shared_scripts {
    "@ox_lib/init.lua",   
    "config.lua"     
}
