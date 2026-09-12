-- Побитовая логика AND/OR/XOR/NOT для шин 4/8/16 бит.

local api          = require("wire_mod:api")
local bit          = require("wire_mod:bit")
local logic_viewer = require("wire_mod:logic_viewer")
local bus          = require("advanced_logic:bus_common")

local OPERATIONS = {"AND", "OR", "XOR", "NOT"}

local function operation_at(value)
    local index = math.floor(value or 0) % #OPERATIONS + 1
    return index, OPERATIONS[index]
end

local device_id = api.register({"advanced_logic:bus_logic"}, {
    inputs = {
        a = {dir = 0, offset = 0, bits = 4, bits_field = "data_bits"},
        b = {dir = 3, offset = 0, bits = 4, bits_field = "data_bits", disabled_field="operation", disabled_value=3},
    },
    outputs = {
        y = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"},
    },
})

api.register_signal_handler(device_id, function(read, write, _, _, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = bus.get_width(x, y, z)
    local a = bus.clamp(read("a"), width)
    local b = bus.clamp(read("b"), width)
    local operation = operation_at(block.get_field(x, y, z, "operation"))
    block.set_variant(x,y,z,operation-1)
    local result
    if operation == 1 then result = bit.band(a, b)
    elseif operation == 2 then result = bit.bor(a, b)
    elseif operation == 3 then result = bit.bxor(a, b)
    else result = bit.bnot(a)
    end
    write("y", bus.clamp(result, width))
end)

function on_placed(x, y, z, _)
    require('wire_mod:gate_mounts').prepare(x,y,z,_)
    bus.init_width(x, y, z)
    if block.get_field(x, y, z, "operation") == nil then
        block.set_field(x, y, z, "operation", 0)
    end
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    return require('advanced_logic:component_settings').open(x,y,z,playerid)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local width = bus.get_width(x, y, z)
    local _, operation = operation_at(block.get_field(x, y, z, "operation"))
    return {
        display_name = string.format("Bus Logic (%s, %d-bit)", operation, width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = "Операция", value = operation, color = "#FFFF88"},
            {name = "ПКМ с конфигуратором - настройки", color = "#888888"},
        },
    }
end)
