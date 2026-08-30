-- Priority Encoder 16-to-4. Возвращает индекс самого высокоприоритетного активного входа.
-- Приоритет: in_15 > in_14 > ... > in_0.
--
-- Размер блока: 4×4×1.
--
-- Пины:
--   BACK  (dir=0): in_0..in_15 — 16 входов на 4×4 grid (offset, offset_y)
--   FRONT (dir=2, offset=0, offset_y=0, bits=4): addr
--   FRONT (dir=2, offset=1, offset_y=0, bits=1): valid

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local function make_inputs()
    local ins = {}
    for i = 0, 15 do
        local col = i % 4
        local row = math.floor(i / 4)
        ins["in_" .. i] = {dir = 0, offset = col, offset_y = row, bits = 1}
    end
    return ins
end

local device_id = api.register({"advanced_logic_2:encoder_16to4"}, {
    inputs  = make_inputs(),
    outputs = {
        addr  = {dir = 2, offset = 0, offset_y = 0, bits = 4},
        valid = {dir = 2, offset = 1, offset_y = 0, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write)
    local addr  = 0
    local valid = 0
    -- Highest priority wins (15 down to 0)
    for i = 15, 0, -1 do
        if (read("in_" .. i) or 0) ~= 0 then
            addr  = i
            valid = 1
            break
        end
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
        display_name = "16-to-4 Priority Encoder",
        type = "gate",
        settings = {
            {name = "addr = индекс самого активного входа"},
            {name = "valid = 1 если есть активный"},
        }
    }
end)
