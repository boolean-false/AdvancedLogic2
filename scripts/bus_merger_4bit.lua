-- Универсальный merger: отдельные однобитные линии -> шина 4/8/16 бит.
-- ID сохранён для совместимости со старыми мирами.

local api          = require("wire_mod_2:api")
local bit          = require("wire_mod_2:bit")
local logic_viewer = require("wire_mod_2:logic_viewer")
local bus          = require("advanced_logic_2:bus_common")

local function make_inputs()
    local inputs = {}
    for index = 0, 15 do
        inputs["bit" .. index] = {
            dir = 0,
            offset = index % 4,
            offset_y = math.floor(index / 4),
            bits = 1,
        }
    end
    return inputs
end

local device_id = api.register({"advanced_logic_2:bus_merger_4bit"}, {
    inputs = make_inputs(),
    outputs = {
        bus = {dir = 2, offset = 0, offset_y = 0, bits = 4, bits_field = "data_bits"},
    },
})

api.register_signal_handler(device_id, function(read, write, _, _, origin)
    local width = bus.get_width(origin[1], origin[2], origin[3])
    local value = 0
    for index = 0, width - 1 do
        if (read("bit" .. index) or 0) ~= 0 then
            value = bit.bor(value, bit.lshift(1, index))
        end
    end
    write("bus", bus.clamp(value, width))
end)

function on_placed(x, y, z, _)
    bus.init_width(x, y, z)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    return bus.try_cycle_width(x, y, z, playerid)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("Bus Merger (%d-bit)", width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = string.format("Используются bit0..bit%d", width - 1)},
        },
    }
end)
