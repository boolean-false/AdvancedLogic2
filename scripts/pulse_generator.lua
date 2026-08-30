-- Pulse Generator: на фронте входа (0→1) выдаёт фиксированный импульс на выход.
-- Длительность импульса PULSE_DURATION секунд.
--
-- Порты:
--   BACK  (dir=0, bits=1): in    — триггер
--   FRONT (dir=2, bits=1): out   — импульс

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local PULSE_DURATION = 0.1  -- секунды

local device_id = api.register({"advanced_logic_2:pulse_generator"}, {
    inputs  = { ["in"] = {dir = 0, offset = 0, bits = 1} },
    outputs = { out    = {dir = 2, offset = 0, bits = 1} }
})

local function uptime_safe()
    local ok, t = pcall(time.uptime)
    if ok and t then return t end
    return 0
end

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]

    local now = uptime_safe()
    local input_v = (read("in") or 0) ~= 0 and 1 or 0
    local prev    = block.get_field(x, y, z, "prev_in") or 0
    local active  = (block.get_field(x, y, z, "pulse_active") or 0) ~= 0
    local until_t = block.get_field(x, y, z, "pulse_until") or 0

    block.set_field(x, y, z, "prev_in", input_v)

    -- Rising edge → старт импульса
    if input_v == 1 and prev == 0 then
        active = true
        until_t = now + PULSE_DURATION
        block.set_field(x, y, z, "pulse_active", 1)
        block.set_field(x, y, z, "pulse_until",  until_t)
        write("out", 1)
        return
    end

    -- Импульс активен
    if active then
        if now >= until_t then
            block.set_field(x, y, z, "pulse_active", 0)
            block.set_field(x, y, z, "pulse_until",  0)
            write("out", 0)
        else
            write("out", 1)
        end
    else
        write("out", 0)
    end
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "prev_in",      0)
    block.set_field(x, y, z, "pulse_active", 0)
    block.set_field(x, y, z, "pulse_until",  0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

-- Tick для авто-сброса импульса (если evaluate не вызывается извне за время импульса).
function on_block_tick(x, y, z, tps)
    local active = (block.get_field(x, y, z, "pulse_active") or 0) ~= 0
    if not active then return end
    local until_t = block.get_field(x, y, z, "pulse_until") or 0
    if uptime_safe() >= until_t then
        api.mark_device_for_update(x, y, z)
    end
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local active = (block.get_field(x, y, z, "pulse_active") or 0) ~= 0
    return {
        display_name = "Pulse Generator",
        type = "gate",
        settings = {
            {name = "Длит. импульса", value = string.format("%.2fs", PULSE_DURATION)},
            {name = "Состояние", value = active and "PULSING" or "idle",
             color = active and "#00FF88" or "#888888"},
        }
    }
end)
