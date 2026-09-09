local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bus          = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:adder_4bit"}, {
    inputs = {
        a   = {dir = 0, offset = 0, bits = 4, bits_field = "data_bits"},
        b   = {dir = 3, offset = 0, bits = 4, bits_field = "data_bits"},
        cin = {dir = 1, offset = 0, bits = 1},
    },
    outputs = {
        sum  = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"},
        cout = {dir = 2, offset = 1, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = bus.get_width(x, y, z)
    local modulus = bus.mask(width) + 1

    local a   = read("a")   or 0
    local b   = read("b")   or 0
    local cin = read("cin") or 0

    local result = (a % modulus) + (b % modulus) + (cin ~= 0 and 1 or 0)
    local sum    = result % modulus
    local cout   = math.floor(result / modulus)

    block.set_field(x, y, z, "cout", cout)

    write("sum", sum)
    write("cout", cout)
end)

function on_placed(x, y, z, _)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,_)
    bus.init_width(x, y, z)
    block.set_field(x, y, z, "cout", 0)
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
    local cout = block.get_field(x, y, z, "cout") or 0
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("Adder (%d-bit)", width),
        type = "gate",
        -- inputs/outputs auto-filled (A, B, CIN, SUM с реальными значениями)
        settings = {
            bus.viewer_width(width),
            {name = "COUT", value = tostring(cout),
             color = cout ~= 0 and "#FF8800" or "#AAAAAA"},
        }
    }
end)
