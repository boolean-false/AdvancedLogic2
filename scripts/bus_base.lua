local api = require('wire_mod_2:api')

api.register_wire_variants("advanced_logic_2", {
    wire_type = "bus",
    color = "orange",
    bits = 4
})

function on_placed(x, y, z, playerid)
    api.on_wire_placed(x, y, z)
end

function on_broken(x, y, z, playerid) 
    api.on_wire_broken(x, y, z)
end

function on_interact(x, y, z, playerid)
    -- Обычная логика взаимодействия (если нужно, можно добавить сюда)
end

