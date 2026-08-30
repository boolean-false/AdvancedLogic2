-- 4-битный мультиплексор 2:1
--
-- Порты:
--   A   (BACK,  dir=0, bits=4) — вход A (выбирается при SEL=0)
--   B   (RIGHT, dir=1, bits=4) — вход B (выбирается при SEL=1)
--   SEL (LEFT,  dir=3, bits=1) — выбор
--   Y   (FRONT, dir=2, bits=4) — выход
--
-- Поведение: Y = SEL ? B : A

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:mux_4bit"}, {
    inputs = {
        a   = {dir = 0, offset = 0, bits = 4},
        b   = {dir = 1, offset = 0, bits = 4},
        sel = {dir = 3, offset = 0, bits = 1},
    },
    outputs = {
        y = {dir = 2, offset = 0, bits = 4}
    }
})

api.register_signal_handler(device_id, function(read, write)
    local a   = read("a")   or 0
    local b   = read("b")   or 0
    local sel = read("sel") or 0
    write("y", sel ~= 0 and b or a)
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
        display_name = "4-bit MUX 2:1",
        type = "gate",
        -- inputs/outputs auto-filled (покажет A, B, SEL и Y с реальными значениями)
    }
end)
