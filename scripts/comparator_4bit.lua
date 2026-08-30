-- 4-bit Comparator. Сравнивает A и B (4 бита).
--
-- Порты:
--   BACK  (dir=0, bits=4): a
--   LEFT  (dir=3, bits=4): b
--   FRONT (dir=2, bits=1): eq    — A == B
--   RIGHT (dir=1, bits=1): gt    — A >  B
--   UP    (dir=4, bits=1): lt    — A <  B

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:comparator_4bit"}, {
    inputs = {
        a = {dir = 0, offset = 0, bits = 4},
        b = {dir = 3, offset = 0, bits = 4},
    },
    outputs = {
        eq = {dir = 2, offset = 0, bits = 1},
        gt = {dir = 1, offset = 0, bits = 1},
        lt = {dir = 4, offset = 0, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write)
    local a = (read("a") or 0) % 16
    local b = (read("b") or 0) % 16
    write("eq", a == b and 1 or 0)
    write("gt", a >  b and 1 or 0)
    write("lt", a <  b and 1 or 0)
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
        display_name = "4-bit Comparator",
        type = "gate",
    }
end)
