-- 4-bit bus merger: собирает 4 однобитных провода в 4-битную шину.
--
-- Порты:
--   BACK  (dir=0, bits=1): bit0    — младший бит (LSB)
--   LEFT  (dir=3, bits=1): bit1
--   RIGHT (dir=1, bits=1): bit2
--   UP    (dir=4, bits=1): bit3    — старший бит
--   FRONT (dir=2, bits=4): bus     — выходная шина

local api = require('wire_mod_2:api')
local bit = require('wire_mod_2:bit')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:bus_merger_4bit"}, {
    inputs = {
        bit0 = {dir = 0, offset = 0, bits = 1},
        bit1 = {dir = 3, offset = 0, bits = 1},
        bit2 = {dir = 1, offset = 0, bits = 1},
        bit3 = {dir = 4, offset = 0, bits = 1},
    },
    outputs = { bus = {dir = 2, offset = 0, bits = 4} }
})

api.register_signal_handler(device_id, function(read, write)
    local b0 = (read("bit0") or 0) ~= 0 and 1 or 0
    local b1 = (read("bit1") or 0) ~= 0 and 1 or 0
    local b2 = (read("bit2") or 0) ~= 0 and 1 or 0
    local b3 = (read("bit3") or 0) ~= 0 and 1 or 0
    local v = bit.bor(b0, bit.bor(bit.lshift(b1, 1), bit.bor(bit.lshift(b2, 2), bit.lshift(b3, 3))))
    write("bus", v)
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
        display_name = "Bus Merger (4-bit)",
        type = "gate",
    }
end)
