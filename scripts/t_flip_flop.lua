-- T Flip-Flop (rising-edge triggered toggle)
--
-- Порты:
--   RIGHT (dir=1): T   — toggle enable
--   BACK  (dir=0): CLK
--   FRONT (dir=2): Q

local api  = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge = require('advanced_logic_2:edge')

local device_id = api.register({"advanced_logic_2:t_flip_flop"}, {
    inputs = {
        t   = {dir = 1, offset = 0, bits = 1},
        clk = {dir = 0, offset = 0, bits = 1},
    },
    outputs = { q = {dir = 2, offset = 0, bits = 1} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local t   = (read("t")   or 0) ~= 0
    local clk = read("clk") or 0
    local q   = block.get_field(x, y, z, "q") or 0

    if edge.rising(x, y, z, clk, "prev_clk") and t then
        q = (q == 0) and 1 or 0
    end

    block.set_field(x, y, z, "q", q)
    write("q", q)
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
        display_name = "T Flip-Flop",
        type = "gate",
        settings = {
            {name = "Q", value = tostring(q),
             color = q ~= 0 and "#00FF88" or "#AAAAAA"},
        }
    }
end)
