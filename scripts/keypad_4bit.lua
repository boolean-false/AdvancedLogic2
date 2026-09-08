-- 4-bit Keypad: UI 4×4 кнопок с hex-значениями (0-F).
-- При нажатии в UI:
--   - value (FRONT, 4-bit) ← код клавиши
--   - strobe (RIGHT, 1-bit) ← 1 в течение STROBE_DURATION секунд
-- ПКМ+конфигуратор → открыть UI.

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')
local cfg_check    = require('advanced_logic_2:configurator_check')
local timer_registry = require('wire_mod_2:timer_registry')

local LAYOUT_ID       = "advanced_logic_2:keypad_4bit"
local STROBE_DURATION = 0.15  -- секунды
local process_timer

local device_id = api.register({"advanced_logic_2:keypad_4bit"}, {
    outputs = {
        value  = {dir = 2, offset = 0, bits = 4},
        strobe = {dir = 1, offset = 0, bits = 1},
    }
})

local function uptime_safe()
    local ok, t = pcall(time.uptime)
    if ok and t then return t end
    return 0
end

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]
    local v = (block.get_field(x, y, z, "value") or 0) % 16
    local strobe_until = block.get_field(x, y, z, "strobe_until") or 0
    local active = strobe_until > 0 and uptime_safe() < strobe_until

    write("value",  v)
    write("strobe", active and 1 or 0)
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "value",        0)
    block.set_field(x, y, z, "strobe_until", 0)
    api.on_placed(x, y, z, device_id)
    timer_registry.register(x, y, z, process_timer, device_id)
end

function on_broken(x, y, z, _)
    timer_registry.unregister(x, y, z)
    api.on_broken(x, y, z, device_id)
end

function on_block_present(x, y, z)
    -- Значение клавиши сохраняется, а короткий strobe после перезапуска гасится.
    block.set_field(x, y, z, "strobe_until", 0)
    api.on_placed(x, y, z, device_id)
    api.mark_device_for_update(x, y, z)
    timer_registry.register(x, y, z, process_timer, device_id)
end

function on_interact(x, y, z, playerid)
    if not cfg_check.can_open_ui(playerid) then return false end
    if hud.is_open(LAYOUT_ID) then return true end

    if not session.entries then session.entries = {} end
    local pkey = tostring(playerid)
    session.entries["keypad_pos_" .. pkey] = {x, y, z}
    session.entries["keypad_pos"] = {x, y, z}

    hud.show_overlay(LAYOUT_ID, false, {x, y, z})
    return true
end

-- Централизованная проверка для авто-сброса strobe.
process_timer = function(x, y, z)
    local strobe_until = block.get_field(x, y, z, "strobe_until") or 0
    if strobe_until <= 0 then return end
    if uptime_safe() >= strobe_until then
        block.set_field(x, y, z, "strobe_until", 0)
        api.mark_device_for_update(x, y, z)
    end
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local v = block.get_field(x, y, z, "value") or 0
    local strobe_until = block.get_field(x, y, z, "strobe_until") or 0
    local active = strobe_until > 0 and uptime_safe() < strobe_until
    return {
        display_name = "4-bit Keypad",
        type = "source",
        settings = {
            {name = "Value",  value = string.format("0x%X (%d)", v, v),
             color = "#FFFF88"},
            {name = "Strobe", value = active and "ACTIVE" or "idle",
             color = active and "#00FF88" or "#888888"},
            {name = "<spacer>"},
            {name = "ПКМ+конф = открыть клавиатуру", color = "#888888"},
        }
    }
end)
