-- Universal Counter с явной шириной 4/8/16 бит.
--
-- Порты:
--   data  (BACK,  dir=0, flexible): значение для load
--   clk   (LEFT,  dir=3, bits=1)
--   en    (RIGHT, dir=1, bits=1):   счёт (en=1+load=1 → декремент, en=1+load=0 → инкремент)
--   load  (UP,    dir=4, bits=1)
--   clr   (DOWN,  dir=5, bits=1):   async clear
--   q     (FRONT, dir=2, flexible)
--   carry (FRONT offset=1, dir=2, bits=1)

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge         = require('advanced_logic_2:edge')
local bus          = require('advanced_logic_2:bus_common')

local device_id = api.register({"advanced_logic_2:counter"}, {
    inputs = {
        clk  = {dir = 3, offset = 0, bits = 1},
        en   = {dir = 1, offset = 0, bits = 1},
        data = {dir = 0, offset = 0, bits = 4, bits_field = "data_bits"},
        load = {dir = 4, offset = 0, bits = 1},
        clr  = {dir = 5, offset = 0, bits = 1},
    },
    outputs = {
        q     = {dir = 2, offset = 0, bits = 4, bits_field = "data_bits"},
        carry = {dir = 2, offset = 1, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = bus.get_width(x, y, z)
    local modulus = 2 ^ width

    local clk  = read("clk")  or 0
    local clr  = read("clr")  or 0
    local load = read("load") or 0
    local en   = read("en")   or 0
    local data = (read("data") or 0) % modulus

    local count = (block.get_field(x, y, z, "count") or 0) % modulus
    local carry = block.get_field(x, y, z, "carry") or 0

    if clr ~= 0 then
        count = 0
        carry = 0
        edge.update(x, y, z, clk, "prev_clk")
    elseif edge.rising(x, y, z, clk, "prev_clk") then
        carry = 0
        if en ~= 0 and load ~= 0 then
            -- декремент
            if count == 0 then count = modulus - 1; carry = 1
            else count = count - 1 end
        elseif en ~= 0 then
            -- инкремент
            if count == modulus - 1 then count = 0; carry = 1
            else count = count + 1 end
        elseif load ~= 0 then
            count = data
        end
    end

    block.set_field(x, y, z, "count", count)
    block.set_field(x, y, z, "carry", carry)

    write("q",     count)
    write("carry", carry)
end)

function on_placed(x, y, z, _)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,_)
    bus.init_width(x, y, z)
    block.set_field(x, y, z, "count",    0)
    block.set_field(x, y, z, "carry",    0)
    block.set_field(x, y, z, "prev_clk", 0)
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
    local count = block.get_field(x, y, z, "count") or 0
    local carry = block.get_field(x, y, z, "carry") or 0
    local width = bus.get_width(x, y, z)
    return {
        display_name = string.format("Counter (%d-bit)", width),
        type = "gate",
        settings = {
            bus.viewer_width(width),
            {name = "Q",     value = logic_viewer.format_bits(count, width)},
            {name = "DEC",   value = tostring(count)},
            {name = "CARRY", value = tostring(carry)},
        }
    }
end)
