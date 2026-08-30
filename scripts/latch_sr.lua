-- SR Latch (level-triggered, асинхронный)
--
-- Порты:
--   RIGHT (dir=1): S — Set
--   LEFT  (dir=3): R — Reset
--   FRONT (dir=2): Q — выход
--
-- Логика:
--   S=1, R=0 → Q=1
--   S=0, R=1 → Q=0
--   S=0, R=0 → hold (Q не меняется)
--   S=1, R=1 → запрещено, Q=0 (race-resolution)

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:latch_sr"}, {
    inputs = {
        s = {dir = 1, offset = 0, bits = 1},
        r = {dir = 3, offset = 0, bits = 1},
    },
    outputs = { q = {dir = 2, offset = 0, bits = 1} }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local s = (read("s") or 0) ~= 0
    local r = (read("r") or 0) ~= 0
    local q = block.get_field(x, y, z, "q") or 0

    if s and r then
        q = 0  -- forbidden state
    elseif s then
        q = 1
    elseif r then
        q = 0
    end

    block.set_field(x, y, z, "q", q)
    write("q", q)
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "q", 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local q = block.get_field(x, y, z, "q") or 0
    return {
        display_name = "SR Latch",
        type = "gate",
        settings = {
            {name = "Q", value = tostring(q),
             color = q ~= 0 and "#00FF88" or "#AAAAAA"},
        }
    }
end)
