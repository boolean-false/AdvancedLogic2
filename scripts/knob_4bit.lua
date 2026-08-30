-- 4-bit Knob: ручной регулятор. Хранит значение 0-15.
-- ПКМ → +1, Shift+ПКМ → -1 (mod 16).
-- Выход: 4-bit на все стороны (фронт обычно).

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:knob_4bit"}, {
    outputs = { value = {dir = 2, offset = 0, bits = 4} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local v = block.get_field(x, y, z, "value") or 0
    write("value", v % 16)
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "value", 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    local shift = false
    pcall(function()
        shift = input.is_pressed("key:left-shift") or input.is_pressed("key:right-shift")
    end)

    local v = block.get_field(x, y, z, "value") or 0
    if shift then
        v = (v - 1) % 16
    else
        v = (v + 1) % 16
    end
    block.set_field(x, y, z, "value", v)

    -- send_signal обновит цепи (writer-style — knob это source-устройство)
    api.send_signal(x, y, z, v)
    return true
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local v = block.get_field(x, y, z, "value") or 0
    return {
        display_name = "4-bit Knob",
        type = "source",
        settings = {
            {name = "Значение", value = string.format("0x%X (%d)", v, v),
             color = "#FFFF88"},
            {name = "<spacer>"},
            {name = "ПКМ → +1, Shift+ПКМ → -1", color = "#888888"},
        }
    }
end)
