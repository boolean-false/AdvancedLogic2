-- CPU Register File: 8 регистров × 4 бит. 1 write port + 2 read ports.
--
-- Размер блока: 2×1×1.
--
-- Пины:
--   BACK   offset=0 (dir=0, bits=3): write_addr
--   BACK   offset=1 (dir=0, bits=4): write_data
--   LEFT            (dir=3, bits=1): we
--   RIGHT           (dir=1, bits=1): clk
--   DOWN   offset=0 (dir=5, bits=3): read_addr_a
--   DOWN   offset=1 (dir=5, bits=3): read_addr_b
--   FRONT  offset=0 (dir=2, bits=4): read_data_a
--   FRONT  offset=1 (dir=2, bits=4): read_data_b
--
-- Запись по фронту CLK при WE=1: regs[write_addr] = write_data.
-- Чтение асинхронное (continuous): read_data = regs[read_addr].
-- Регистр R0 не специальный (без "always-zero" hardwire) — игроку проще.

local api  = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge = require('advanced_logic_2:edge')

local NUM_REGS = 8

local device_id = api.register({"advanced_logic_2:cpu_register_file_8x4"}, {
    inputs = {
        write_addr  = {dir = 0, offset = 0, bits = 3},
        write_data  = {dir = 0, offset = 1, bits = 4},
        we          = {dir = 3, offset = 0, bits = 1},
        clk         = {dir = 1, offset = 0, bits = 1},
        read_addr_a = {dir = 5, offset = 0, bits = 3},
        read_addr_b = {dir = 5, offset = 1, bits = 3},
    },
    outputs = {
        read_data_a = {dir = 2, offset = 0, bits = 4},
        read_data_b = {dir = 2, offset = 1, bits = 4},
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]

    local clk = read("clk") or 0
    local we  = (read("we") or 0) ~= 0
    local wa  = (read("write_addr") or 0) % NUM_REGS
    local wd  = (read("write_data") or 0) % 16
    local ra  = (read("read_addr_a") or 0) % NUM_REGS
    local rb  = (read("read_addr_b") or 0) % NUM_REGS

    if edge.rising(x, y, z, clk, "prev_clk") and we then
        block.set_field(x, y, z, "regs", wd, wa)
    end

    local va = (block.get_field(x, y, z, "regs", ra) or 0) % 16
    local vb = (block.get_field(x, y, z, "regs", rb) or 0) % 16

    write("read_data_a", va)
    write("read_data_b", vb)
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "prev_clk", 0)
    for i = 0, NUM_REGS - 1 do
        if block.get_field(x, y, z, "regs", i) == nil then
            block.set_field(x, y, z, "regs", 0, i)
        end
    end
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local settings = {{name = "Регистры (HEX):"}}
    local line = "  "
    for i = 0, NUM_REGS - 1 do
        local v = (block.get_field(x, y, z, "regs", i) or 0) % 16
        line = line .. string.format("R%d=%X  ", i, v)
        if i == 3 then
            table.insert(settings, {name = line})
            line = "  "
        end
    end
    if line ~= "  " then table.insert(settings, {name = line}) end
    return {
        display_name = "CPU Register File 8×4",
        type = "gate",
        settings = settings,
    }
end)
