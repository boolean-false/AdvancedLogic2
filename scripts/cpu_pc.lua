-- Universal CPU Program Counter (flex-width). 4/8/16 бит автоматически.
--
-- Порты:
--   BACK  (dir=0, flexible): data
--   LEFT  (dir=3, bits=1):   clk
--   RIGHT (dir=1, bits=1):   inc
--   UP    (dir=4, bits=1):   load
--   DOWN  (dir=5, bits=1):   reset
--   FRONT (dir=2, flexible): pc
--
-- Приоритет: reset > load > inc > hold

local api  = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local edge = require('advanced_logic_2:edge')

local device_id = api.register({"advanced_logic_2:cpu_pc"}, {
    inputs = {
        data  = {dir = 0, offset = 0, bits = 16, flexible = true},
        clk   = {dir = 3, offset = 0, bits = 1},
        inc   = {dir = 1, offset = 0, bits = 1},
        load  = {dir = 4, offset = 0, bits = 1},
        reset = {dir = 5, offset = 0, bits = 1},
    },
    outputs = { pc = {dir = 2, offset = 0, bits = 16, flexible = true} }
})

local function port_width(x, y, z)
    local d_bits = api.get_port_chain_bits("data", x, y, z) or 0
    local p_bits = api.get_port_chain_bits("pc", x, y, z) or 0
    local w = math.max(d_bits, p_bits)
    if w == 0 then return 4 end
    return w
end

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = port_width(x, y, z)
    local modulus = 2 ^ width

    local clk   = read("clk") or 0
    local inc   = (read("inc")  or 0) ~= 0
    local load  = (read("load") or 0) ~= 0
    local reset = (read("reset") or 0) ~= 0
    local data  = (read("data") or 0) % modulus

    local pc = (block.get_field(x, y, z, "pc") or 0) % modulus

    if reset then
        pc = 0
        edge.update(x, y, z, clk, "prev_clk")
    elseif edge.rising(x, y, z, clk, "prev_clk") then
        if load then
            pc = data
        elseif inc then
            pc = (pc + 1) % modulus
        end
    end

    block.set_field(x, y, z, "pc", pc)
    write("pc", pc)
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "pc", 0)
    block.set_field(x, y, z, "prev_clk", 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local pc = block.get_field(x, y, z, "pc") or 0
    local width = port_width(x, y, z)
    return {
        display_name = string.format("CPU Program Counter (%d-bit)", width),
        type = "gate",
        settings = {
            {name = "PC", value = string.format("0x%X (%d)", pc, pc),
             color = "#FFFF88"},
        }
    }
end)
