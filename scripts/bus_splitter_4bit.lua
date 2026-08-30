-- Универсальный splitter: шина 4/8/16 бит -> отдельные однобитные линии.
-- ID сохранён для совместимости со старыми мирами.

local api          = require("wire_mod_2:api")
local bit          = require("wire_mod_2:bit")
local logic_viewer = require("wire_mod_2:logic_viewer")
local bus          = require("advanced_logic_2:bus_common")

local function make_outputs()
    local outputs = {}
    for index = 0, 15 do
        outputs["bit" .. index] = {
            dir = 2,
            offset = index % 4,
            offset_y = math.floor(index / 4),
            bits = 1,
        }
    end
    return outputs
end

local device_id = api.register({"advanced_logic_2:bus_splitter_4bit"}, {
    inputs = {
        bus = {dir = 0, offset = 0, offset_y = 0, bits = 4, bits_field = "data_bits"},
    },
    outputs = make_outputs(),
})

api.register_signal_handler(device_id, function(read, write, _, _, origin)
    local width = bus.get_width(origin[1], origin[2], origin[3])
    local value = bus.clamp(read("bus"), width)
    for index = 0, 15 do
        local output = index < width and bit.band(bit.rshift(value, index), 1) or 0
        write("bit" .. index, output)
    end
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
        display_name = string.format("Bus Splitter (%d-bit)", width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = string.format("Активны bit0..bit%d", width - 1)},
        },
    }
end)
