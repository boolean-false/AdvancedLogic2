local lifecycle = require('wire_mod:conductor_lifecycle')
local api = require('wire_mod:api')

local function ensure_bus(color, bits)
    local base_name = string.format("advanced_logic:bus_%s_%d", color, bits)
    if api.get_wire_by_name(base_name) then return end
    api.register_wire_variants("advanced_logic", {
        wire_type = "bus",
        color = color,
        bits = bits,
        crossing = {
            lower_model='al_crossing/ribbon/lower',upper_model='al_crossing/ribbon/upper',
            upper_models={'al_crossing/ribbon/upper_1','al_crossing/ribbon/upper_2','al_crossing/ribbon/upper_3'},
            top='blocks:al_ribbon_'..bits..'_5',side='blocks:al_ribbon_'..bits..'_side'
        }
    })
end

-- bus_base назначен каждому геометрическому варианту, поэтому регистрация
-- должна быть идемпотентной без повторной генерации списков моделей.
ensure_bus("orange", 4)
ensure_bus("purple", 8)
ensure_bus("cyan", 16)

function on_placed(x, y, z, playerid)
    lifecycle.present(x, y, z)
end

function on_broken(x, y, z, playerid)
    lifecycle.broken(x, y, z)
end

function on_interact(x, y, z, playerid)
end

function on_block_present(x, y, z)
    lifecycle.present(x, y, z)
end
