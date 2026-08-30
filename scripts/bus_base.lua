local api = require('wire_mod_2:api')

local function ensure_bus(color, bits)
    local base_name = string.format("advanced_logic_2:bus_%s_%d", color, bits)
    if api.get_wire_by_name(base_name) then return end
    api.register_wire_variants("advanced_logic_2", {
        wire_type = "bus",
        color = color,
        bits = bits
    })
end

-- bus_base назначен каждому геометрическому варианту, поэтому регистрация
-- должна быть идемпотентной без повторной генерации списков моделей.
ensure_bus("orange", 4)
ensure_bus("purple", 8)
ensure_bus("cyan", 16)

function on_placed(x, y, z, playerid)
    api.on_wire_placed(x, y, z)
end

function on_broken(x, y, z, playerid)
    api.on_wire_broken(x, y, z)
end

function on_interact(x, y, z, playerid)
end
