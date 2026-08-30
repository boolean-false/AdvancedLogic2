-- Universal CPU ALU (flex-width). 4/8/16 бит автоматически.
--
-- Размер: 2×1×1.
-- Op-коды (3-bit op): 000=ADD 001=SUB 010=AND 011=OR 100=XOR 101=NOT 110=SHL 111=SHR
-- Flags: zero, carry, neg (sign bit), overflow (signed ADD/SUB)

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local bit = require('wire_mod_2:bit')

local device_id = api.register({"advanced_logic_2:cpu_alu"}, {
    inputs = {
        a  = {dir = 0, offset = 0, bits = 16, flexible = true},
        b  = {dir = 0, offset = 1, bits = 16, flexible = true},
        op = {dir = 3, offset = 0, bits = 3},
    },
    outputs = {
        result   = {dir = 2, offset = 0, bits = 16, flexible = true},
        zero     = {dir = 2, offset = 1, bits = 1},
        carry    = {dir = 1, offset = 0, bits = 1},
        neg      = {dir = 4, offset = 0, bits = 1},
        overflow = {dir = 4, offset = 1, bits = 1},
    }
})

local function port_width(x, y, z)
    local a_bits = api.get_port_chain_bits("a", x, y, z) or 0
    local b_bits = api.get_port_chain_bits("b", x, y, z) or 0
    local r_bits = api.get_port_chain_bits("result", x, y, z) or 0
    local w = math.max(a_bits, b_bits, r_bits)
    if w == 0 then return 4 end
    return w
end

---@param v integer
---@param width integer
---@return integer signed value
local function signed(v, width)
    local modulus = 2 ^ width
    local half = modulus / 2
    v = v % modulus
    if v >= half then return v - modulus end
    return v
end

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local width = port_width(x, y, z)
    local modulus = 2 ^ width
    local mask = modulus - 1

    local a  = (read("a")  or 0) % modulus
    local b  = (read("b")  or 0) % modulus
    local op = (read("op") or 0) % 8

    local result = 0
    local carry  = 0
    local overflow = 0

    if op == 0 then
        local raw = a + b
        result = raw % modulus
        carry  = raw >= modulus and 1 or 0
        local sa, sb, sr = signed(a, width), signed(b, width), signed(result, width)
        if (sa >= 0 and sb >= 0 and sr < 0) or (sa < 0 and sb < 0 and sr >= 0) then
            overflow = 1
        end
    elseif op == 1 then
        local raw = a - b
        result = (raw + modulus) % modulus
        carry  = raw < 0 and 1 or 0
        local sa, sb, sr = signed(a, width), signed(b, width), signed(result, width)
        if (sa >= 0 and sb < 0 and sr < 0) or (sa < 0 and sb >= 0 and sr >= 0) then
            overflow = 1
        end
    elseif op == 2 then
        result = bit.band(a, b)
    elseif op == 3 then
        result = bit.bor(a, b)
    elseif op == 4 then
        result = bit.bxor(a, b)
    elseif op == 5 then
        result = bit.band(bit.bnot(a), mask)
    elseif op == 6 then
        carry  = bit.band(bit.rshift(a, width - 1), 1)
        result = bit.band(bit.lshift(a, 1), mask)
    elseif op == 7 then
        carry  = bit.band(a, 1)
        result = bit.band(bit.rshift(a, 1), mask)
    end

    write("result",   result)
    write("zero",     result == 0 and 1 or 0)
    write("carry",    carry)
    write("neg",      bit.band(bit.rshift(result, width - 1), 1))
    write("overflow", overflow)
end)

function on_placed(x, y, z, _)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local width = port_width(x, y, z)
    return {
        display_name = string.format("CPU ALU (%d-bit)", width),
        type = "gate",
        settings = {
            {name = "OP-коды:"},
            {name = "  0=ADD 1=SUB 2=AND 3=OR"},
            {name = "  4=XOR 5=NOT 6=SHL 7=SHR"},
        }
    }
end)
