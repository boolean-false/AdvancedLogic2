-- Регистр с разрядностью 4, 8 или 16 бит.
--
-- Порты:
--   D    (RIGHT, dir=1, flexible): вход данных
--   CLK  (FRONT, dir=2, bits=1):   тактовый сигнал
--   LOAD (BACK,  dir=0, bits=1):   разрешение записи
--   Q    (RIGHT, dir=3, flexible): выход

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge         = require('advanced_logic_2:edge')
local bus          = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:register"}, {
    inputs = {
        d    = {dir = 1, offset = 0, bits = 4, bits_field = "data_bits"},
        clk  = {dir = 2, offset = 0, bits = 1},
        load = {dir = 0, offset = 0, bits = 1},
    },
    outputs = {
        q = {dir = 3, offset = 0, bits = 4, bits_field = "data_bits"}
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = bus.get_width(x, y, z)
    local mask  = bus.mask(width)

    local d    = (read("d")    or 0) % (mask + 1)
    local clk  = read("clk")  or 0
    local load = read("load") or 0

    local q = block.get_field(x, y, z, "q") or 0

    if edge.rising(x, y, z, clk, "prev_clk") and load ~= 0 then
        q = d
    end

    -- Ограничиваем q текущей разрядностью выхода.
    q = q % (mask + 1)

    block.set_field(x, y, z, "q", q)
    write("q", q)
end)

function on_placed(x, y, z, _)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,_)
    bus.init_width(x, y, z)
    block.set_field(x, y, z, "q", 0)
    block.set_field(x, y, z, "prev_clk", 0)
    api.on_placed(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    return bus.try_cycle_width(x, y, z, playerid)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local q = block.get_field(x, y, z, "q") or 0
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("Register (%d-bit)", width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = "Q", value = logic_viewer.format_bits(q, width)},
        }
    }
end)
