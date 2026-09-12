-- D Flip-Flop (положительный фронт CLK)
--
-- Порты:
--   D   (RIGHT, dir=1) - вход данных
--   CLK (LEFT,  dir=3) - тактовый сигнал
--   RST (BACK,  dir=0) - асинхронный сброс (active high)
--   Q   (FRONT, dir=2) - выход

local api          = require('wire_mod:api')
local logic_viewer = require('wire_mod:logic_viewer')
local edge         = require('advanced_logic:edge')

local device_id = api.register({"advanced_logic:d_flip_flop"}, {
    inputs = {
        d   = {dir = 1, offset = 0, bits = 1},
        clk = {dir = 3, offset = 0, bits = 1},
        rst = {dir = 0, offset = 0, bits = 1},
    },
    outputs = {
        q = {dir = 2, offset = 0, bits = 1}
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]

    local d   = read("d")   or 0
    local clk = read("clk") or 0
    local rst = read("rst") or 0

    local q = block.get_field(x, y, z, "q") or 0

    if rst ~= 0 then
        q = 0
        edge.update(x, y, z, clk, "prev_clk")
    elseif edge.rising(x, y, z, clk, "prev_clk") then
        q = (d ~= 0) and 1 or 0
    end

    block.set_field(x, y, z, "q", q)
    write("q", q)
end)

function on_placed(x, y, z, _)
    require('wire_mod:gate_mounts').prepare(x,y,z,_)
    block.set_field(x, y, z, "q", 0)
    block.set_field(x, y, z, "prev_clk", 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local q        = block.get_field(x, y, z, "q")        or 0
    local prev_clk = block.get_field(x, y, z, "prev_clk") or 0
    return {
        display_name = "D Flip-Flop",
        type = "gate",
        settings = {
            {name = "Q",   value = tostring(q),
             color = q ~= 0 and "#00FF88" or "#AAAAAA"},
            {name = "CLK", value = prev_clk ~= 0 and "HIGH" or "LOW",
             color = prev_clk ~= 0 and "#FFFF44" or "#888888"},
        }
    }
end)
