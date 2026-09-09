--- Движок тактового генератора: обработка одного clock_generator блока.
--- Раньше находилось в scripts/clock_generator.lua:on_block_tick, теперь вызывается
--- глобально из world.lua через clock_registry.

local api = require('wire_mod_2:api')

---@class ALClockEngine
local M = {}

local DEFAULT_PULSE_TIME = 0.5
local DEFAULT_DELAY_TIME = 0.5

---Обработка одного блока clock. Вызывается раз за такт из world.lua.
---@param x integer
---@param y integer
---@param z integer
---@param force_toggle boolean|nil Принудительный фронт для ручного Step
function M.process_one(x, y, z, force_toggle)
    local next_toggle = block.get_field(x, y, z, "next_toggle")
    if not next_toggle then
        local ok, uptime = pcall(time.uptime)
        if ok and uptime then
            local delay_time = block.get_field(x, y, z, "delay_time") or DEFAULT_DELAY_TIME
            block.set_field(x, y, z, "next_toggle", uptime + delay_time)
        end
        return
    end

    local ok, uptime = pcall(time.uptime)
    if not ok or not uptime then return end
    if not force_toggle and uptime < next_toggle then return end

    local current_output = block.get_field(x, y, z, "output") or 0
    local new_output = (current_output == 0) and 1 or 0

    block.set_field(x, y, z, "output", new_output)
    api.send_signal(x, y, z, new_output)

    local pulse_time = block.get_field(x, y, z, "pulse_time") or DEFAULT_PULSE_TIME
    local delay_time = block.get_field(x, y, z, "delay_time") or DEFAULT_DELAY_TIME
    -- pulse_time = длительность HIGH, delay_time = длительность LOW.
    local next_period = (new_output == 1) and pulse_time or delay_time
    block.set_field(x, y, z, "next_toggle", uptime + next_period)
end

return M
