-- Тактовый генератор. Логика тактов вынесена в modules/clock_engine.lua,
-- вызывается централизованно из scripts/world.lua через clock_registry.
-- Здесь только регистрация в registry + UI + initial fields.

local api            = require("wire_mod_2:api")
local logic_viewer   = require("wire_mod_2:logic_viewer")
local cfg_check      = require("advanced_logic_2:configurator_check")
local clock_registry = require("advanced_logic_2:clock_registry")

local device_id = api.register({"advanced_logic_2:clock_generator"}, {
    outputs = {
        output = { dir = 2, offset = 0, bits = 1}
    }
})

local DEFAULT_PULSE_TIME = 0.5
local DEFAULT_DELAY_TIME = 0.5

function on_placed(x, y, z, playerid)
    require('wire_mod_2:gate_mounts').prepare(x,y,z,playerid)
    block.set_field(x, y, z, "pulse_time", DEFAULT_PULSE_TIME)
    block.set_field(x, y, z, "delay_time", DEFAULT_DELAY_TIME)
    local ok, uptime = pcall(time.uptime)
    block.set_field(x, y, z, "next_toggle", (ok and uptime or 0) + DEFAULT_DELAY_TIME)
    block.set_field(x, y, z, "output", 0)
    block.set_field(x, y, z, "paused", 0)

    api.on_placed(x, y, z, device_id)
    clock_registry.register(x, y, z, device_id)
end

function on_broken(x, y, z, playerId)
    clock_registry.unregister(x, y, z)
    api.on_broken(x, y, z, device_id)
end

local function restore_clock(x,y,z)
    local output=block.get_field(x,y,z,'output') or 0
    local period=output~=0 and (block.get_field(x,y,z,'pulse_time') or DEFAULT_PULSE_TIME)
        or (block.get_field(x,y,z,'delay_time') or DEFAULT_DELAY_TIME)
    block.set_field(x,y,z,'next_toggle',time.uptime()+period)
    clock_registry.register(x,y,z,device_id)
end
api.register_restore_handler(device_id,restore_clock)

function on_block_present(x, y, z)
    restore_clock(x,y,z)
    api.on_placed(x, y, z, device_id)
    api.send_signal(x, y, z, block.get_field(x,y,z,'output') or 0)
end

function on_block_removed(x, y, z)
    clock_registry.unregister(x, y, z)
end

function on_interact(x, y, z, playerId)
    if not cfg_check.can_open_ui(playerId) then
        return false
    end

    if not session.entries then
        session.entries = {}
    end
    session.entries["clock_generator_pos_" .. tostring(playerId)] = {x, y, z}
    session.entries["clock_generator_pos"] = {x, y, z}

    hud.show_overlay("advanced_logic_2:clock_generator", false, {x, y, z})
    return true
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end

    local pulse_time     = block.get_field(x, y, z, "pulse_time")   or DEFAULT_PULSE_TIME
    local delay_time     = block.get_field(x, y, z, "delay_time")   or DEFAULT_DELAY_TIME
    local next_toggle    = block.get_field(x, y, z, "next_toggle")  or 0
    local current_output = block.get_field(x, y, z, "output")       or 0

    local time_until = 0
    local ok, uptime = pcall(time.uptime)
    if ok and uptime and next_toggle > 0 then
        time_until = math.max(0, next_toggle - uptime)
    end

    local current_period = (current_output == 1) and pulse_time or delay_time
    local bar_len = 10
    local filled = current_period > 0 and math.floor((time_until / current_period) * bar_len + 0.5) or 0
    filled = math.max(0, math.min(bar_len, filled))
    local bar = logic_viewer.color('|', '#555555')
               .. logic_viewer.color(string.rep('#', filled),          '#00FF88')
               .. logic_viewer.color(string.rep('.', bar_len - filled), '#333333')
               .. logic_viewer.color('|', '#555555')

    local paused_str = clock_registry.is_paused(x,y,z) and "ДА" or "нет"

    return {
        display_name = "Clock Generator",
        type = "source",
        settings = {
            {name = "Состояние",   value = current_output == 1 and "ON" or "OFF",
             color = current_output == 1 and "#00FF88" or "#555555"},
            {name = "<spacer>"},
            {name = "Pulse",       value = string.format("%.2f", pulse_time)  .. "s"},
            {name = "Delay",       value = string.format("%.2f", delay_time)  .. "s"},
            {name = "До смены",    value = string.format("%.2f", time_until)  .. "s"},
            {name = "Прогресс",    value = bar},
            {name = "<spacer>"},
            {name = "Пауза генератора", value = paused_str,
             color = clock_registry.is_paused(x,y,z) and "#FF8800" or "#888888"},
        }
    }
end)
