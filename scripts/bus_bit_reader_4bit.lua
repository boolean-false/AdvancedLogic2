local api = require('wire_mod_2:api')
local bit = require('wire_mod_2:bit')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bus = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:bus_bit_reader_4bit"}, {
    inputs = {
        input = {dir = 2, offset = 0, accept_bits = {1,4,8,16}},
    },
    outputs = {
        output = { dir = 0, offset = 0, bits = 1}  -- 1-битный выход
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin, block_id)
    local bus_value = read("input") or 0
    
    -- Получаем выбранный бит из поля блока
    local x, y, z = origin[1], origin[2], origin[3]
    local width = api.get_port_state('input',x,y,z).bits or 16
    local selected_bit = math.floor(block.get_field(x, y, z, "selected_bit") or 0) % 16
    
    -- Извлекаем выбранный бит из шины
    -- Используем bit.band для получения нужного бита
    local bit_value = bit.band(bit.rshift(bus_value, selected_bit), 1)
    
    write("output", bit_value)
end)

function on_placed(x, y, z, playerid)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,playerid)
    bus.init_width(x, y, z)
    -- Инициализируем selected_bit если его нет
    if block.get_field(x, y, z, "selected_bit") == nil then
        block.set_field(x, y, z, "selected_bit", 0)
    end
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, playerid)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    return require('advanced_logic_2:component_settings').open(x,y,z,playerid)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end

    local selected_bit = block.get_field(x, y, z, "selected_bit") or 0
    local bus_width = api.get_port_state('input',x,y,z).bits or 16
    selected_bit = math.floor(selected_bit) % 16

    -- Показать выбранный бит (MSB -> LSB, слева направо)
    local bit_vis = ""
    for i = bus_width - 1, 0, -1 do
        if i == selected_bit then
            bit_vis = bit_vis .. logic_viewer.color('^', '#FFFF00')
        else
            bit_vis = bit_vis .. logic_viewer.color('.', '#888888')
        end
    end

    -- inputs = nil -> заполняются из device_system и показывают значение шины
    -- outputs = nil -> заполняются из device_system и показывают выходной бит
    return {
        display_name = "Читатель бита шины",
        settings = {
            bus.viewer_width(bus_width),
            {name = "Бит",     value = tostring(selected_bit) .. ' / ' .. tostring(bus_width - 1)},
            {name = "Позиция", value = bit_vis},
        }
    }
end)
