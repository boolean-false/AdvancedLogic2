local api = require('wire_mod_2:api')
local bit = require('wire_mod_2:bit')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bus = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:bus_bit_writer_4bit"}, {
    inputs = {
        input_bit = {dir = 0, offset = 0, bits = 1},  -- 1-битный вход для записи
        input_bus = {dir = 1, offset = 0, bits = 4, bits_field = "data_bits"},
    },
    outputs = {
        output = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"}
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin, block_id)
    local input_bit_value = read("input_bit") or 0
    local input_bus_value = read("input_bus") or 0
    
    -- Получаем выбранный бит из поля блока
    local x, y, z = origin[1], origin[2], origin[3]
    local width = bus.get_width(x, y, z)
    local selected_bit = math.floor(block.get_field(x, y, z, "selected_bit") or 0) % width
    
    -- Нормализуем input_bit_value (0 или 1)
    local bit_to_write = (input_bit_value ~= 0) and 1 or 0
    
    -- Создаем маску для выбранного бита
    local bit_mask = bit.lshift(1, selected_bit)
    
    -- Очищаем выбранный бит в текущем значении шины
    local cleared_bus = bit.band(input_bus_value, bit.bnot(bit_mask))
    
    -- Устанавливаем новый бит
    local new_bus_value = bit.bor(cleared_bus, bit.lshift(bit_to_write, selected_bit))
    
    write("output", bus.clamp(new_bus_value, width))
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
    if bus.try_cycle_width(x, y, z, playerid) then return true end
    local width = bus.get_width(x, y, z)
    local selected_bit = block.get_field(x, y, z, "selected_bit") or 0
    selected_bit = selected_bit + 1
    if selected_bit >= width then
        selected_bit = 0
    end
    block.set_field(x, y, z, "selected_bit", selected_bit)
    
    -- КРИТИЧНО: Помечаем устройство для пересчета после изменения selected_bit
    -- Это необходимо, чтобы устройство пересчитало выход на основе нового selected_bit
    api.mark_device_for_update(x, y, z)
    return true
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end

    local selected_bit = block.get_field(x, y, z, "selected_bit") or 0
    local bus_width = bus.get_width(x, y, z)
    selected_bit = math.floor(selected_bit) % bus_width

    -- Visualize which bit will be written (MSB → LSB, left to right)
    local bit_vis = ""
    for i = bus_width - 1, 0, -1 do
        if i == selected_bit then
            bit_vis = bit_vis .. logic_viewer.color('^', '#FFFF00')
        else
            bit_vis = bit_vis .. logic_viewer.color('.', '#888888')
        end
    end

    -- inputs = nil  → auto-fill (shows input_bit and input_bus values)
    -- outputs = nil → auto-fill (shows output bus value)
    return {
        display_name = "Записыватель бита шины",
        settings = {
            bus.viewer_width(bus_width),
            {name = "Бит",     value = tostring(selected_bit) .. ' / ' .. tostring(bus_width - 1)},
            {name = "Позиция", value = bit_vis},
        }
    }
end)
