-- 4-битный Shift Register PISO (Parallel In, Serial Out).
-- LOAD=1 + фронт CLK: q ← parallel_in (загрузка)
-- LOAD=0 + фронт CLK: q ← q >> 1 (сдвиг вправо, MSB заполняется нулём)
-- serial_out = q & 1 (LSB)
--
-- Порты:
--   BACK  (0, bits=4): parallel_in
--   LEFT  (3, bits=1): clk
--   RIGHT (1, bits=1): load
--   FRONT (2, bits=1): serial_out

local api  = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge = require('advanced_logic_2:edge')
local bit  = require('wire_mod_2:bit')

local device_id = api.register({"advanced_logic_2:shift_register_4bit_piso"}, {
    inputs = {
        parallel_in = {dir = 0, offset = 0, bits = 4},
        clk         = {dir = 3, offset = 0, bits = 1},
        load        = {dir = 1, offset = 0, bits = 1},
    },
    outputs = { serial_out = {dir = 2, offset = 0, bits = 1} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local pin  = (read("parallel_in") or 0) % 16
    local clk  = read("clk") or 0
    local load = (read("load") or 0) ~= 0
    local q    = block.get_field(x, y, z, "q") or 0

    if edge.rising(x, y, z, clk, "prev_clk") then
        if load then
            q = pin
        else
            q = math.floor(q / 2)
        end
    end

    block.set_field(x, y, z, "q", q)
    write("serial_out", bit.band(q, 1))
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "q", 0)
    block.set_field(x, y, z, "prev_clk", 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local q = block.get_field(x, y, z, "q") or 0
    return {
        display_name = "Shift Register PISO (4-bit)",
        type = "gate",
        settings = {
            {name = "Q", value = logic_viewer.format_bits(q, 4)},
        }
    }
end)
