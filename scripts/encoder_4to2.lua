-- Priority Encoder 4-to-2. Возвращает индекс самого высокоприоритетного активного входа.
-- Приоритет: in3 > in2 > in1 > in0. valid=1 если хоть один вход активен.
--
-- Порты:
--   BACK  (0, bits=1): in0   (приоритет 0, низший)
--   LEFT  (3, bits=1): in1
--   RIGHT (1, bits=1): in2
--   UP    (4, bits=1): in3   (приоритет 3, высший)
--   FRONT (2, bits=2): addr  — индекс активного входа
--   DOWN  (5, bits=1): valid — 1 если есть активный вход

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:encoder_4to2"}, {
    inputs = {
        in0 = {dir = 0, offset = 0, bits = 1},
        in1 = {dir = 3, offset = 0, bits = 1},
        in2 = {dir = 1, offset = 0, bits = 1},
        in3 = {dir = 4, offset = 0, bits = 1},
    },
    outputs = {
        addr  = {dir = 2, offset = 0, bits = 2},
        valid = {dir = 5, offset = 0, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write)
    local i0 = (read("in0") or 0) ~= 0
    local i1 = (read("in1") or 0) ~= 0
    local i2 = (read("in2") or 0) ~= 0
    local i3 = (read("in3") or 0) ~= 0

    local addr  = 0
    local valid = 0
    -- Highest-priority wins
    if i3 then addr = 3; valid = 1
    elseif i2 then addr = 2; valid = 1
    elseif i1 then addr = 1; valid = 1
    elseif i0 then addr = 0; valid = 1
    end

    write("addr",  addr)
    write("valid", valid)
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
        display_name = "4-to-2 Priority Encoder",
        type = "gate",
    }
end)
