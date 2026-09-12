local api=require('wire_mod:api')
local viewer=require('wire_mod:logic_viewer')
local device_id=api.register({'advanced_logic:bus_splitter_4bit'},{inputs={bus={dir=0,offset=0,accept_bits={1,4,8,16}}},outputs={bit0={dir=2,offset=0,bits=1},bit1={dir=2,offset=1,bits=1},bit2={dir=1,offset=0,bits=1},bit3={dir=3,offset=0,bits=1}}})
api.register_signal_handler(device_id,function(read,write,_,_,origin)
    local group=math.floor(block.get_field(origin[1],origin[2],origin[3],'group') or 0)%4
    local value=math.floor((read('bus') or 0)/2^(group*4))%16
    for i=0,3 do write('bit'..i,math.floor(value/2^i)%2) end
end)
function on_placed(x, y, z, playerid)
    require('wire_mod:gate_mounts').prepare(x,y,z,playerid)
    api.on_placed(x,y,z,device_id)
end
function on_broken(x,y,z) api.on_broken(x,y,z,device_id) end
function on_interact(x,y,z,playerid) return require('advanced_logic:component_settings').open(x,y,z,playerid,'group') end
viewer.set_view(device_id,function(x,y,z)
 return {display_name='Отвод 4 бит',settings={{name='Диапазон',value=string.format('%d..%d',4*(block.get_field(x,y,z,'group') or 0),4*(block.get_field(x,y,z,'group') or 0)+3)}}}
end)
