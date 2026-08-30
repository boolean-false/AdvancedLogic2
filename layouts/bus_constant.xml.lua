local api = require("wire_mod_2:api")
local bus = require("advanced_logic_2:bus_common")

local LAYOUT_ID = "advanced_logic_2:bus_constant"
local bx, by, bz
local selected_width = bus.DEFAULT_WIDTH

local function update_width_labels()
    local width_label = document["width_label"]
    local range_label = document["range_label"]
    if width_label then width_label.text = tostring(selected_width) .. " бит" end
    if range_label then
        range_label.text = string.format("Диапазон: 0..%d (0x%X)", bus.mask(selected_width), bus.mask(selected_width))
    end
end

function set_width(width)
    selected_width = bus.safe_width(width)
    local input = document["value_input"]
    if input then input.text = tostring(bus.clamp(tonumber(input.text) or 0, selected_width)) end
    update_width_labels()
end

function apply_constant()
    if not bx then return end
    local input = document["value_input"]
    local value = bus.clamp(input and tonumber(input.text) or 0, selected_width)
    block.set_field(bx, by, bz, "value", value)
    block.set_field(bx, by, bz, "data_bits", selected_width, 0)
    if input then input.text = tostring(value) end
    api.refresh_device(bx, by, bz)
end

function close_constant()
    hud.close(LAYOUT_ID)
end

function on_open(...)
    local args = {...}
    if session.entries and session.entries["bus_constant_pos"] then
        local position = session.entries["bus_constant_pos"]
        bx, by, bz = position[1], position[2], position[3]
    elseif #args >= 3 then
        bx, by, bz = args[1], args[2], args[3]
    else
        hud.close(LAYOUT_ID)
        return
    end

    selected_width = bus.get_width(bx, by, bz)
    local input = document["value_input"]
    if input then input.text = tostring(bus.clamp(block.get_field(bx, by, bz, "value") or 0, selected_width)) end
    update_width_labels()
end

function on_close(_)
end
