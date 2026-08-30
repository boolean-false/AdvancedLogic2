-- RAM Large: 64 ячейки физически, данные 4/8/16 бит.
-- Используется в CPU-сборках где 16 ячеек мало (программа, стек).
--
-- Пины (как в обычной RAM):
--   BACK  (dir=0): addr[6]
--   RIGHT (dir=1): we[1]
--   FRONT (dir=2): data_out[db]
--   LEFT  (dir=3): data_in[db]
--   DOWN  (dir=5): clk[1]

local api          = require("wire_mod_2:api")
local logic_viewer = require("wire_mod_2:logic_viewer")
local mem          = require("advanced_logic_2:memory_common")
local edge         = require("advanced_logic_2:edge")
local cfg_check    = require("advanced_logic_2:configurator_check")

local LAYOUT_ID  = "advanced_logic_2:memory_editor"
local PHYS_CELLS = 64

local device_id = api.register({"advanced_logic_2:ram_large"}, {
    inputs  = {
        addr     = {dir = 0, bits = 6},
        we       = {dir = 1, bits = 1},
        data_in  = {dir = 0, offset = 2, bits = 4, bits_field = "data_bits"},
        clk      = {dir = 3, bits = 1},
    },
    outputs = { data_out = {dir = 2, bits = 4, bits_field = "data_bits"} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin, block_id)
    local x, y, z = origin[1], origin[2], origin[3]
    local data_bits = mem.get_data_bits(x, y, z)
    local addr      = math.floor(read("addr") or 0) % PHYS_CELLS
    local we        = read("we")  or 0
    local clk       = read("clk") or 0

    local clk_rising = edge.rising(x, y, z, clk, "prev_clk")
    local we_rising  = edge.rising(x, y, z, we,  "prev_we")

    if (clk_rising and we == 1) or (we_rising and clk == 1) then
        local data_in = mem.clamp_value(read("data_in") or 0, data_bits)
        block.set_field(x, y, z, "mem", data_in, addr)
    end

    local value = mem.clamp_value(block.get_field(x, y, z, "mem", addr) or 0, data_bits)
    write("data_out", value)
end)

function on_placed(x, y, z, _)
    mem.init_fields(x, y, z, PHYS_CELLS)
    block.set_field(x, y, z, "prev_clk", 0, 0)
    block.set_field(x, y, z, "prev_we",  0, 0)
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
    session.entries["mem_editor_is_rom"]     = false
    session.entries["mem_editor_type"]       = "RAM"
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
        {name = string.format("RAM-Large  addr:%db  data:%db  cells:%d", ab, db, PHYS_CELLS)},
    }
    for _, row in ipairs(mem.build_memory_dump(x, y, z, db, PHYS_CELLS)) do
        table.insert(settings, row)
    end
    table.insert(settings, {name = "<spacer>"})
    table.insert(settings, {name = "[ ПКМ+конф = редактор ]", color = "#888888"})
    return {display_name = string.format("RAM-Large %db/%db", ab, db), settings = settings}
end)
