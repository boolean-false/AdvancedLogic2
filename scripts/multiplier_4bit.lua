-- 4×4-битный умножитель. Результат 8 бит, выводится на 8-битную шину.
--
-- Порты:
--   BACK  (0, bits=4): a
--   LEFT  (3, bits=4): b
--   FRONT (2, bits=8): result   — A * B (0..225)

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:multiplier_4bit"}, {
    inputs = {
        a = {dir = 0, offset = 0, bits = 4},
        b = {dir = 3, offset = 0, bits = 4},
    },
    outputs = { result = {dir = 2, offset = 0, bits = 8} }
})

api.register_signal_handler(device_id, function(read, write)
    local a = (read("a") or 0) % 16
    local b = (read("b") or 0) % 16
    write("result", (a * b) % 256)
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
        display_name = "4×4 Multiplier",
        type = "gate",
    }
end)
