-- 4-bit bus splitter: разбивает 4-битную шину на 4 отдельных 1-битных провода.
--
-- Порты:
--   BACK  (dir=0, bits=4): bus     — входная шина
--   FRONT (dir=2, bits=1): bit0    — младший бит (LSB)
--   LEFT  (dir=3, bits=1): bit1
--   RIGHT (dir=1, bits=1): bit2
--   UP    (dir=4, bits=1): bit3    — старший бит

local api = require('wire_mod_2:api')
local bit = require('wire_mod_2:bit')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:bus_splitter_4bit"}, {
    inputs  = { bus  = {dir = 0, offset = 0, bits = 4} },
    outputs = {
        bit0 = {dir = 2, offset = 0, bits = 1},
        bit1 = {dir = 3, offset = 0, bits = 1},
        bit2 = {dir = 1, offset = 0, bits = 1},
        bit3 = {dir = 4, offset = 0, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write)
    local v = read("bus") or 0
    write("bit0", bit.band(v,                1))
    write("bit1", bit.band(bit.rshift(v, 1), 1))
    write("bit2", bit.band(bit.rshift(v, 2), 1))
    write("bit3", bit.band(bit.rshift(v, 3), 1))
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
        display_name = "Bus Splitter (4-bit)",
        type = "gate",
    }
end)
