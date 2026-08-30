-- 4-битный Shift Register SIPO (Serial In, Parallel Out).
-- На фронте CLK: q ← (q << 1) | serial_in, обрезка до 4 бит.
-- Старший бит выталкивается, новый бит входит в LSB.
--
-- Порты:
--   RIGHT (1, bits=1): serial_in
--   LEFT  (3, bits=1): clk
--   FRONT (2, bits=4): parallel_out

local api  = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge = require('advanced_logic_2:edge')
local bit  = require('wire_mod_2:bit')

local device_id = api.register({"advanced_logic_2:shift_register_4bit_sipo"}, {
    inputs = {
        serial_in = {dir = 1, offset = 0, bits = 1},
        clk       = {dir = 3, offset = 0, bits = 1},
    },
    outputs = { parallel_out = {dir = 2, offset = 0, bits = 4} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local sin = (read("serial_in") or 0) ~= 0 and 1 or 0
    local clk = read("clk") or 0
    local q   = block.get_field(x, y, z, "q") or 0

    if edge.rising(x, y, z, clk, "prev_clk") then
        q = bit.band(bit.bor(bit.lshift(q, 1), sin), 15)
    end

    block.set_field(x, y, z, "q", q)
    write("parallel_out", q)
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
        display_name = "Shift Register SIPO (4-bit)",
        type = "gate",
        settings = {
            {name = "Q", value = logic_viewer.format_bits(q, 4)},
        }
    }
end)
