-- Universal unsigned indicator. Block ID retained for existing inventories/worlds.
local api=require('wire_mod_2:api')
local display=require('advanced_logic_2:indicator_display')
local configurator=require('advanced_logic_2:configurator_check')
local device_id=api.register({'advanced_logic_2:indicator_4bit'},{
    inputs={input={dir=0,offset=0,accept_bits={1,4,8,16}}}
})
api.register_signal_handler(device_id,function(_,_,_,_,origin)
    display.ensure(origin[1],origin[2],origin[3])
end)
function on_placed(x,y,z,_)
    api.on_placed(x,y,z,device_id)
    display.ensure(x,y,z)
end
function on_block_present(x,y,z)
    display.ensure(x,y,z)
end
function on_update(x,y,z)
    display.ensure(x,y,z)
end
function on_broken(x,y,z,_)
    display.remove(x,y,z)
    api.on_broken(x,y,z,device_id)
end
function on_replaced(x,y,z,_)
    display.remove(x,y,z)
    api.on_broken(x,y,z,device_id)
end
function on_block_removed(x,y,z)
    display.remove(x,y,z)
end

function on_interact(x,y,z,playerid)
    if not configurator.can_open_ui(playerid) then return false end
    x,y,z=block.seek_origin(x,y,z)
    local mode=block.get_field(x,y,z,'display_mode') or 0
    block.set_field(x,y,z,'display_mode',mode==1 and 0 or 1)
    display.ensure(x,y,z)
    return true
end
