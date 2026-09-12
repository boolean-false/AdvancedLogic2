local api = require('wire_mod:api')
local logic_viewer = require('wire_mod:logic_viewer')

local device_id = api.register({'advanced_logic:decoder_4to16'}, {
    inputs={addr={dir=0,offset=0,accept_bits={1,4,8,16}}},
    outputs={mask={dir=2,offset=0,bits=16}},
})
api.register_signal_handler(device_id,function(read,write)
    write('mask',2^((read('addr') or 0)%16))
end)

function on_placed(x, y, z, _)
    require('wire_mod:gate_mounts').prepare(x,y,z,_)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    return {
        display_name = "4-to-16 Decoder",
        type = "gate",
        settings = {
            {name='ADDR',value='Младшие 4 бита: 0..15'},
            {name='MASK',value='16 бит: 1 << ADDR'},
        }
    }
end)
