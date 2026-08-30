-- ROM Large: 64 ячейки физически, данные 4/8/16 бит.
-- Используется для программ CPU, lookup-таблиц и т.д.

local api          = require("wire_mod_2:api")
local logic_viewer = require("wire_mod_2:logic_viewer")
local mem          = require("advanced_logic_2:memory_common")
local cfg_check    = require("advanced_logic_2:configurator_check")

local LAYOUT_ID  = "advanced_logic_2:memory_editor"
local PHYS_CELLS = 64

local device_id = api.register({"advanced_logic_2:rom_large"}, {
    inputs  = { addr = {dir = 0, bits = 6} },
    outputs = { data = {dir = 2, bits = 4, bits_field = "data_bits"} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin, block_id)
    local x, y, z = origin[1], origin[2], origin[3]
    local data_bits = mem.get_data_bits(x, y, z)
    local addr  = math.floor(read("addr") or 0) % PHYS_CELLS
    local value = mem.clamp_value(mem.read_cell(x, y, z, addr), data_bits)
    write("data", value)
end)

function on_placed(x, y, z, _)
    mem.init_fields(x, y, z, PHYS_CELLS)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    local ox, oy, oz = block.seek_origin(x, y, z)

    if not cfg_check.can_open_ui(playerid) then return false end
    if hud.is_open(LAYOUT_ID) then return true end

    if not session.entries then session.entries = {} end
    session.entries["mem_editor_pos"]        = {ox, oy, oz}
    session.entries["mem_editor_is_rom"]     = true
    session.entries["mem_editor_type"]       = "ROM"
    session.entries["mem_editor_addr_bits"]  = mem.get_addr_bits(ox, oy, oz)
    session.entries["mem_editor_data_bits"]  = mem.get_data_bits(ox, oy, oz)
    session.entries["mem_editor_phys_cells"] = PHYS_CELLS
    hud.show_overlay(LAYOUT_ID, false, {ox, oy, oz})
    return true
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local ab = mem.get_addr_bits(x, y, z)
    local db = mem.get_data_bits(x, y, z)

    local settings = {
        {name = "<spacer>"},
        {name = string.format("ROM-Large  addr:%db  data:%db  cells:%d", ab, db, PHYS_CELLS)},
    }
    for _, row in ipairs(mem.build_memory_dump(x, y, z, db, PHYS_CELLS)) do
        table.insert(settings, row)
    end
    table.insert(settings, {name = "<spacer>"})
    table.insert(settings, {name = "[ ПКМ+конф = редактор ]", color = "#888888"})
    return {display_name = string.format("ROM-Large %db/%db", ab, db), settings = settings}
end)
