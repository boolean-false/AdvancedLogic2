-- 4-битный MUX 4:1. Sel 2-bit выбирает один из 4 4-битных входов.
--
-- Порты:
--   BACK  (0, bits=4): a
--   LEFT  (3, bits=4): b
--   RIGHT (1, bits=4): c
--   UP    (4, bits=4): d
--   DOWN  (5, bits=2): sel  (00=a, 01=b, 10=c, 11=d)
--   FRONT (2, bits=4): y    (выход)

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:mux_4to1_4bit"}, {
    inputs = {
        a   = {dir = 0, offset = 0, bits = 4},
        b   = {dir = 3, offset = 0, bits = 4},
        c   = {dir = 1, offset = 0, bits = 4},
        d   = {dir = 4, offset = 0, bits = 4},
        sel = {dir = 5, offset = 0, bits = 2},
    },
    outputs = { y = {dir = 2, offset = 0, bits = 4} }
})

api.register_signal_handler(device_id, function(read, write)
    local sel = (read("sel") or 0) % 4
    local v = 0
    if     sel == 0 then v = read("a") or 0
    elseif sel == 1 then v = read("b") or 0
    elseif sel == 2 then v = read("c") or 0
    elseif sel == 3 then v = read("d") or 0
    end
    write("y", v % 16)
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
        display_name = "4-bit MUX 4:1",
        type = "gate",
    }
end)
