local api=require('wire_mod:api')
local viewer=require('wire_mod:logic_viewer')
local device_id=api.register({'advanced_logic:bus_merger_4bit'},{inputs={bit0={dir=2,offset=0,bits=1},bit1={dir=2,offset=1,bits=1},bit2={dir=1,offset=0,bits=1},bit3={dir=3,offset=0,bits=1}},outputs={bus={dir=0,offset=0,bits=4}}})
api.register_signal_handler(device_id,function(read,write,_,_,origin)
    local value=0
    for i=0,3 do if (read('bit'..i) or 0)~=0 then value=value+2^i end end
    write('bus',value)
end)
function on_placed(x, y, z, playerid)
    require('wire_mod:gate_mounts').prepare(x,y,z,playerid)
    api.on_placed(x,y,z,device_id)
end
function on_broken(x,y,z) api.on_broken(x,y,z,device_id) end
function on_interact(x,y,z,playerid) return false end
viewer.set_view(device_id,function(x,y,z)
 return {display_name='Сборщик 4 бит',settings={{name='Порядок',value='bit0 - младший, bit3 - старший'}}}
end)
