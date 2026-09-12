local api=require('wire_mod:api')
local viewer=require('wire_mod:logic_viewer')
local device_id=api.register({'advanced_logic:bus_join'},{inputs={low={dir=0,bits=4,bits_field="part_bits"},high={dir=1,bits=4,bits_field="part_bits"}},outputs={output={dir=2,bits=8,bits_field="data_bits"}}})
api.register_signal_handler(device_id,function(read,write,_,_,origin)
 local half=block.get_field(origin[1],origin[2],origin[3],'part_bits') or 0
 if half~=8 then half=4 end
 local modulus=2^half
 write('output',((read('low') or 0)%modulus)+((read('high') or 0)%modulus)*modulus)
end)
function on_placed(x, y, z, playerid)
 require('wire_mod:gate_mounts').prepare(x,y,z,playerid)
 block.set_field(x,y,z,'part_bits',4);block.set_field(x,y,z,'data_bits',8)
 api.on_placed(x,y,z,device_id)
end
function on_broken(x,y,z) api.on_broken(x,y,z,device_id) end
function on_interact(x,y,z,playerid)
 return require('advanced_logic:component_settings').open(x,y,z,playerid,'parts')
end
viewer.set_view(device_id,function(x,y,z)
 local half=block.get_field(x,y,z,'part_bits')==8 and 8 or 4
 return {display_name='Join',settings={{name='Части',value=half..' + '..half..' бит'},{name='LOW / HIGH',value='Младшая / старшая часть'}}}
end)
