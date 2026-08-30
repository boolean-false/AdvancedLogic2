-- Настраиваемый постоянный источник для шин 4/8/16 бит.

local api          = require("wire_mod_2:api")
local logic_viewer = require("wire_mod_2:logic_viewer")
local bus          = require("advanced_logic_2:bus_common")
local cfg_check    = require("advanced_logic_2:configurator_check")

local LAYOUT_ID = "advanced_logic_2:bus_constant"

local device_id = api.register({"advanced_logic_2:bus_constant"}, {
    outputs = {
        value = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"},
    },
})

api.register_signal_handler(device_id, function(_, write, _, _, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    write("value", bus.clamp(block.get_field(x, y, z, "value") or 0, bus.get_width(x, y, z)))
end)

function on_placed(x, y, z, _)
    bus.init_width(x, y, z)
    if block.get_field(x, y, z, "value") == nil then
        block.set_field(x, y, z, "value", 0)
    end
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    if not cfg_check.can_open_ui(playerid) then return false end
    if hud.is_open(LAYOUT_ID) then return true end
    if not session.entries then session.entries = {} end
    session.entries["bus_constant_pos"] = {x, y, z}
    hud.show_overlay(LAYOUT_ID, false, {x, y, z})
    return true
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local width = bus.get_width(x, y, z)
    local value = bus.clamp(block.get_field(x, y, z, "value") or 0, width)
    return {
        display_name = string.format("Bus Constant (%d-bit)", width),
        type = "source",
        settings = {
            bus.viewer_width(width),
            {name = "DEC", value = tostring(value)},
            {name = "HEX", value = string.format("0x%X", value), color = "#FFFF88"},
            {name = "ПКМ+конф = изменить", color = "#888888"},
        },
    }
end)
