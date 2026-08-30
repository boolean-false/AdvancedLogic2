-- 4-битный DEMUX 1:4. Sel 2-bit выбирает один из 4 выходов; остальные = 0.
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

local device_id = api.register({"advanced_logic_2:demux_1to4_4bit"}, {
    inputs = {
        x   = {dir = 0, offset = 0, bits = 4},
        sel = {dir = 5, offset = 0, bits = 2},
    },
    outputs = {
        a = {dir = 2, offset = 0, bits = 4},
        b = {dir = 3, offset = 0, bits = 4},
        c = {dir = 1, offset = 0, bits = 4},
        d = {dir = 4, offset = 0, bits = 4},
    }
})

api.register_signal_handler(device_id, function(read, write)
    local v   = (read("x")   or 0) % 16
    local sel = (read("sel") or 0) % 4

    write("a", sel == 0 and v or 0)
    write("b", sel == 1 and v or 0)
    write("c", sel == 2 and v or 0)
    write("d", sel == 3 and v or 0)
end)

function on_placed(x, y, z, _)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    return {
        display_name = "4-bit DEMUX 1:4",
        type = "gate",
    }
end)
