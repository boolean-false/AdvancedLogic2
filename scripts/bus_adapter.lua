local unpack = table.unpack or unpack
-- Explicit unsigned width conversion. Narrowing keeps the low bits, including bit 0.
local api = require('wire_mod_2:api')
local viewer = require('wire_mod_2:logic_viewer')
local settings = require('advanced_logic_2:adapter_settings')

local device_id = api.register({'advanced_logic_2:bus_adapter'}, {
    inputs = {input = {dir=0, offset=0, accept_bits={1,4,8,16}}},
    outputs = {output = {dir=2, offset=0, bits=4, bits_field='data_bits'}},
})

api.register_signal_handler(device_id, function(read, write, _, _, origin)
    write('output', math.floor(read('input') or 0) % 2^settings.width(unpack(origin)))
end)

function on_placed(x, y, z, playerid)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,playerid)
    block.set_field(x,y,z,'data_bits',4)
    api.on_placed(x,y,z,device_id)
end

function on_broken(x,y,z)
    api.on_broken(x,y,z,device_id)
end

function on_interact(x,y,z,playerid)
    if not require('advanced_logic_2:configurator_check').can_open_ui(playerid) then return false end
    x,y,z=block.seek_origin(x,y,z)
    session.entries=session.entries or {}
    session.entries.adapter_pos={x,y,z}
    hud.show_overlay('advanced_logic_2:bus_adapter',false)
    return true
end

viewer.set_view(device_id,function(x,y,z)
    local state=api.get_port_state('input',x,y,z)
    return {display_name='Адаптер разрядности',type='gate',settings={
        {name='Вход',value=state.connected and (state.bits..' бит') or 'Нет подключения'},
        {name='Выход',value=settings.width(x,y,z)..' бит'},
        {name='Правило',value='Младшие биты / расширение нулями'},
    }}
end)
