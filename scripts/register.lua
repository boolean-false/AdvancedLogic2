-- Universal Register (flex-width). Принимает 4/8/16-битные шины.
-- Ширина определяется в runtime по подключённым цепям.
--
-- Порты:
--   D    (RIGHT, dir=1, flexible): вход данных
--   CLK  (LEFT,  dir=3, bits=1):   тактовый сигнал
--   LOAD (BACK,  dir=0, bits=1):   разрешение записи
--   Q    (FRONT, dir=2, flexible): выход

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge         = require('advanced_logic_2:edge')

local device_id = api.register({"advanced_logic_2:register"}, {
    inputs = {
        d    = {dir = 1, offset = 0, bits = 16, flexible = true},
        clk  = {dir = 3, offset = 0, bits = 1},
        load = {dir = 0, offset = 0, bits = 1},
    },
    outputs = {
        q = {dir = 2, offset = 0, bits = 16, flexible = true}
    }
})

local function port_width(x, y, z)
    local d_bits = api.get_port_chain_bits("d", x, y, z) or 0
    local q_bits = api.get_port_chain_bits("q", x, y, z) or 0
    local w = math.max(d_bits, q_bits)
    if w == 0 then return 4 end  -- fallback
    return w
end

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = port_width(x, y, z)
    local mask  = 2 ^ width - 1

    local d    = (read("d")    or 0) % (mask + 1)
    local clk  = read("clk")  or 0
    local load = read("load") or 0

    local q = block.get_field(x, y, z, "q") or 0

    if edge.rising(x, y, z, clk, "prev_clk") and load ~= 0 then
        q = d
    end

    -- Mask q к текущей ширине (на случай уменьшения ширины output цепи).
    q = q % (mask + 1)

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
    local width = port_width(x, y, z)
    return {
        display_name = string.format("Register (%d-bit)", width),
        type = "gate",
        settings = {
            {name = "Q", value = logic_viewer.format_bits(q, width)},
        }
    }
end)
