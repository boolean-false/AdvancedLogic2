local api = require('wire_mod_2:api')
local bit = require('wire_mod_2:bit')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:bus_bit_reader_4bit"}, {
    inputs = {
        input = {dir = 2, offset = 0, bits = 4},  -- 4-битная шина на входе
    },
    outputs = {
        output = { dir = 0, offset = 0, bits = 1}  -- 1-битный выход
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin, block_id)
    local bus_value = read("input") or 0
    
    -- Получаем выбранный бит из поля блока
    local x, y, z = origin[1], origin[2], origin[3]
    local selected_bit = block.get_field(x, y, z, "selected_bit") or 0
    
    -- Ограничиваем selected_bit диапазоном 0-3 для 4-битной шины
    if selected_bit < 0 then selected_bit = 0 end
    if selected_bit > 3 then selected_bit = 3 end
    
    -- Извлекаем выбранный бит из шины
    -- Используем bit.band для получения нужного бита
    local bit_value = bit.band(bit.rshift(bus_value, selected_bit), 1)
    
    write("output", bit_value)
end)

function on_placed(x, y, z, playerid)
    api.on_placed(x, y, z, device_id)
    -- Инициализируем selected_bit если его нет
    if block.get_field(x, y, z, "selected_bit") == nil then
        block.set_field(x, y, z, "selected_bit", 0)
    end
end

function on_broken(x, y, z, playerid)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    local selected_bit = block.get_field(x, y, z, "selected_bit") or 0
    selected_bit = selected_bit + 1
    if selected_bit > 3 then
        selected_bit = 0
    end
    block.set_field(x, y, z, "selected_bit", selected_bit)
    
    -- КРИТИЧНО: Помечаем устройство для пересчета после изменения selected_bit
    -- Это необходимо, чтобы устройство пересчитало выход на основе нового selected_bit
    api.mark_device_for_update(x, y, z)
end

logic_viewer.set_view(device_id, function(x, y, z)
    local block_id = block.get(x, y, z)
    if block_id == 0 then
        return nil
    end
    
    local selected_bit = block.get_field(x, y, z, "selected_bit") or 0
    local bus_width = 4

    return {
        display_name = "Читатель бита шины",
        inputs = {
        },
        outputs = {
        },
        settings = {
            {name = "Выбранный бит", value = selected_bit .. " / " .. (bus_width - 1)},
        }
    }
end)

