-- Настраиваемый DEMUX 1:4 для шин 4/8/16 бит.
--
-- Порты:
--   BACK  (0, bits=4): x     — вход
--   DOWN  (5, bits=2): sel   (00=a, 01=b, 10=c, 11=d)
--   FRONT (2, bits=4): a
--   LEFT  (3, bits=4): b
--   RIGHT (1, bits=4): c
--   UP    (4, bits=4): d

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bus = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:demux_1to4_4bit"}, {
    inputs = {
        x   = {dir = 0, offset = 0, bits = 4, bits_field = "data_bits"},
        -- Выбор использует младшие 2 бита любой многобитной шины.
        sel = {dir = 5, offset = 0, bits = 2, flexible = true},
    },
    outputs = {
        a = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"},
        b = {dir = 3, offset = 0, bits = 4, bits_field = "data_bits"},
        c = {dir = 1, offset = 0, bits = 4, bits_field = "data_bits"},
        d = {dir = 4, offset = 0, bits = 4, bits_field = "data_bits"},
    }
})

api.register_signal_handler(device_id, function(read, write, _, _, origin)
    local width = bus.get_width(origin[1], origin[2], origin[3])
    local v   = bus.clamp(read("x"), width)
    local sel = (read("sel") or 0) % 4

    write("a", sel == 0 and v or 0)
    write("b", sel == 1 and v or 0)
    write("c", sel == 2 and v or 0)
    write("d", sel == 3 and v or 0)
end)

function on_placed(x, y, z, _)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,_)
    bus.init_width(x, y, z)
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
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("DEMUX 1:4 (%d-bit)", width),
        type = "gate",
        settings = {bus.viewer_width(width)},
    }
end)
