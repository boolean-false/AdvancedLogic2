-- 2-to-4 Decoder (one-hot). Активен только один выход — соответствующий sel.
--
-- Порты:
--   BACK  (0, bits=2): sel
--   FRONT (2, bits=1): out0   (sel=00)
--   LEFT  (3, bits=1): out1   (sel=01)
--   RIGHT (1, bits=1): out2   (sel=10)
--   UP    (4, bits=1): out3   (sel=11)

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:decoder_2to4"}, {
    inputs  = { sel = {dir = 0, offset = 0, bits = 2} },
    outputs = {
        out0 = {dir = 2, offset = 0, bits = 1},
        out1 = {dir = 3, offset = 0, bits = 1},
        out2 = {dir = 1, offset = 0, bits = 1},
        out3 = {dir = 4, offset = 0, bits = 1},
    }
})

api.register_signal_handler(device_id, function(read, write)
    local sel = (read("sel") or 0) % 4
    write("out0", sel == 0 and 1 or 0)
    write("out1", sel == 1 and 1 or 0)
    write("out2", sel == 2 and 1 or 0)
    write("out3", sel == 3 and 1 or 0)
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
        display_name = "2-to-4 Decoder",
        type = "gate",
    }
end)
