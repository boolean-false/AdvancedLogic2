-- 4-битный шестнадцатеричный индикатор
-- Отображает значение 0–15 (0–F) переключением модели через set_variant
--
-- Вход:
--   input (BACK, dir=0, offset=0, bits=4) — отображаемое значение

local api = require('wire_mod_2:api')

local device_id = api.register({"advanced_logic_2:indicator_4bit"}, {
    inputs = {
        input = {dir = 0, offset = 0, bits = 4}
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local value = math.max(0, math.min(15, read("input") or 0))
    block.set_variant(x, y, z, value)
end)

function on_placed(x, y, z, _)
    block.set_variant(x, y, z, 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end
