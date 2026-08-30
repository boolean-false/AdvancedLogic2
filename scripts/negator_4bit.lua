-- 4-битный negator (two's complement). Result = (-A) mod 16.
--
-- Порты:
--   BACK  (0, bits=4): a
--   FRONT (2, bits=4): result

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:negator_4bit"}, {
    inputs  = { a      = {dir = 0, offset = 0, bits = 4} },
    outputs = { result = {dir = 2, offset = 0, bits = 4} }
})

api.register_signal_handler(device_id, function(read, write)
    local a = (read("a") or 0) % 16
    -- Two's complement в 4 битах: -A mod 16
    write("result", (16 - a) % 16)
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
        display_name = "4-bit Negator (-A)",
        type = "gate",
    }
end)
