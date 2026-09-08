-- Настраиваемый вычитатель 4/8/16 бит с заёмом.
--
-- Порты:
--   a    (BACK,  dir=0, bits=4) — уменьшаемое
--   b    (LEFT,  dir=3, bits=4) — вычитаемое
--   bin  (RIGHT, dir=1, bits=1) — входной заём (borrow in)
--   diff (FRONT, dir=2, bits=4) — разность (4 бита)
--
--   bout (DOWN, dir=5, bits=1) — выходной заём
-- Алгоритм: diff = a - b - bin. Если результат < 0: diff += 16, bout = 1.

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bus          = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:subtractor_4bit"}, {
    inputs = {
        a   = {dir = 0, offset = 0, bits = 4, bits_field = "data_bits"},
        b   = {dir = 3, offset = 0, bits = 4, bits_field = "data_bits"},
        bin = {dir = 1, offset = 0, bits = 1},
    },
    outputs = {
        diff = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"},
        bout = {dir = 5, offset = 0, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = bus.get_width(x, y, z)
    local modulus = bus.mask(width) + 1

    local a   = (read("a")   or 0) % modulus
    local b   = (read("b")   or 0) % modulus
    local bin = (read("bin") or 0) ~= 0 and 1 or 0

    local result = a - b - bin
    local bout   = 0

    if result < 0 then
        result = result + modulus
        bout   = 1
    end

    block.set_field(x, y, z, "bout", bout)
    write("diff", result)
    write("bout", bout)
end)

function on_placed(x, y, z, _)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,_)
    bus.init_width(x, y, z)
    block.set_field(x, y, z, "bout", 0)
    api.on_placed(x, y, z, device_id)
end

function on_block_present(x, y, z)
    api.on_placed(x, y, z, device_id)
end

function on_interact(x, y, z, playerid)
    return bus.try_cycle_width(x, y, z, playerid)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local bout = block.get_field(x, y, z, "bout") or 0
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("Subtractor (%d-bit)", width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = "BOUT", value = tostring(bout),
             color = bout ~= 0 and "#FF4444" or "#AAAAAA"},
        }
    }
end)
