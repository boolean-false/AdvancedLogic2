local api          = require("wire_mod_2:api")
local logic_viewer = require("wire_mod_2:logic_viewer")
local mem          = require("advanced_logic_2:memory_common")
local cfg_check    = require("advanced_logic_2:configurator_check")

local LAYOUT_ID = "advanced_logic_2:memory_editor"
local PHYS_CELLS = 64

local device_id = api.register({"advanced_logic_2:rom"}, {
    inputs  = { addr = {dir = 0, accept_bits = {1,4,8,16}} },
    outputs = { data = {dir = 2, bits = 4, bits_field = "data_bits"} }
})

api.register_config_schema(device_id,{"addr_bits","data_bits"})
api.register_schematic_codec(device_id,{
    capture=function(x,y,z)
        local cells={}
        for i=0,PHYS_CELLS-1 do cells[i+1]=mem.read_cell(x,y,z,i) end
        return {cells=cells}
    end,
    restore=function(x,y,z,data)
        for i,value in ipairs(data.cells or {}) do
            if i<=PHYS_CELLS then mem.write_cell(x,y,z,value,i-1) end
        end
    end
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin, block_id)
    local x, y, z = origin[1], origin[2], origin[3]
    local data_bits = mem.get_data_bits(x, y, z)
    local addr  = math.floor(read("addr") or 0) % mem.get_cells(x,y,z)
    local value = mem.clamp_value(mem.read_cell(x, y, z, addr), data_bits)
    write("data", value)
end)

function on_placed(x, y, z, _)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,_)
    mem.init_fields(x, y, z, PHYS_CELLS)
    block.set_field(x,y,z,"addr_bits",4)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    x,y,z=block.seek_origin(x,y,z)
    -- ПКМ с конфигуратором -> редактор. data_bits меняется внутри UI кнопкой "Data: Nb".
    if not cfg_check.can_open_ui(playerid) then return false end
    if hud.is_open(LAYOUT_ID) then return true end

    if not session.entries then session.entries = {} end
    -- Legacy keys (без pkey) для совместимости с layout - он читает их.
    session.entries["mem_editor_pos"]        = {x, y, z}
    session.entries["mem_editor_is_rom"]     = true
    session.entries["mem_editor_type"]       = "ROM"
    session.entries["mem_editor_addr_bits"]  = mem.get_addr_bits(x, y, z)
    session.entries["mem_editor_data_bits"]  = mem.get_data_bits(x, y, z)
    session.entries["mem_editor_phys_cells"] = mem.get_cells(x,y,z)
    hud.show_overlay(LAYOUT_ID, false, {x, y, z})
    return true
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local ab = mem.get_addr_bits(x, y, z)
    local db = mem.get_data_bits(x, y, z)

    local settings = {
        {name = "<spacer>"},
        {name = string.format("ROM  addr:%db  data:%db", ab, db)},
        {name = string.format("Ячеек: %d", mem.get_cells(x,y,z))},
    }
    for _, row in ipairs(mem.build_memory_dump(x, y, z, db, mem.get_cells(x,y,z))) do
        table.insert(settings, row)
    end
    table.insert(settings, {name = "<spacer>"})
    table.insert(settings, {name = "[ Вход: BACK=addr Выход: FRONT=data ]", color = "#888888"})
    table.insert(settings, {name = "[ ПКМ+конф = редактор ]", color = "#888888"})
    return {display_name = string.format("ROM %db/%db", ab, db), settings = settings}
end)
