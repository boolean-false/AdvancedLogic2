-- Настраиваемый 4/8/16-bit tri-state bus driver.
--
-- Порты:
--   BACK  (dir=0, bits=4): data    — входные данные
--   LEFT  (dir=3, bits=1): oe      — Output Enable
--   FRONT (dir=2, bits=4): out     — выход
--
-- При oe=0 НЕ пишем в выход → simulation очистит драйв (high-Z).
-- При oe=1 пишем data на выход. Это позволяет нескольким bus_driver'ам разделять
-- одну цепь — активен только тот, у кого oe=1 (классический tri-state bus).

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bus = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:bus_driver_4bit"}, {
    inputs  = {
        data = {dir = 0, offset = 0, bits = 4, bits_field = "data_bits"},
        oe   = {dir = 3, offset = 0, bits = 1},
    },
    outputs = { out = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"} }
})

api.register_signal_handler(device_id, function(read, write, _, _, origin)
    local oe = read("oe") or 0
    if oe == 0 then
        -- НЕ пишем — simulation снимет драйв с порта (high-Z)
        return
    end
    local data = read("data") or 0
    write("out", bus.clamp(data, bus.get_width(origin[1], origin[2], origin[3])))
end)

function on_placed(x, y, z, _)
    bus.init_width(x, y, z)
    api.on_placed(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    return bus.try_cycle_width(x, y, z, playerid)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("Bus Driver (%d-bit, tri-state)", width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = "OE=1 → данные на выход"},
            {name = "OE=0 → высокоомный (Z)", color = "#888888"},
        }
    }
end)
