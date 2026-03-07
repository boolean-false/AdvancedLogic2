-- Скрипт блока генератора тактов

local api = require("wire_mod_2:api")
local logic_viewer = require("wire_mod_2:logic_viewer")
local simulation = require("wire_mod_2:simulation")

local device_id = api.register({"advanced_logic_2:clock_generator"}, {
    outputs = {
        output = { dir = 2, offset = 0, bits = 1}
    }
})

-- Периоды по умолчанию (используются, если пользовательские значения не установлены)
local DEFAULT_PULSE_TIME = 0.5
local DEFAULT_DELAY_TIME = 0.5

function on_block_tick(x, y, z, tps)
    local id = block.get(x, y, z)
    if id == 0 then return end
    
    local next_toggle = block.get_field(x, y, z, "next_toggle")
    if not next_toggle then 
        -- Инициализируем, если не установлено
        local success, uptime = pcall(time.uptime)
        if success and uptime then
            local pulse_time = block.get_field(x, y, z, "pulse_time") or DEFAULT_PULSE_TIME
            block.set_field(x, y, z, "next_toggle", uptime + pulse_time)
        end
        return 
    end
    
    -- Проверка, пришло ли время переключения
    local success, uptime = pcall(time.uptime)
    if not success or not uptime then return end
    
    if uptime >= next_toggle then
        -- Получаем текущее состояние выхода
        local current_output = block.get_field(x, y, z, "output") or 0
        local new_output = (current_output == 0) and 1 or 0
        
        -- Записываем новое значение выхода
        block.set_field(x, y, z, "output", new_output)
        
        -- Используем api.send_signal, который правильно обрабатывает commit и обновление проводов
        -- Он записывает значение на все выходы устройства и обновляет визуальное состояние проводов
        api.send_signal(x, y, z, new_output)
        
        -- Планирование следующего переключения на основе нового состояния
        local pulse_time = block.get_field(x, y, z, "pulse_time") or DEFAULT_PULSE_TIME
        local delay_time = block.get_field(x, y, z, "delay_time") or DEFAULT_DELAY_TIME
        
        -- Если выход теперь ON, следующее переключение после delay_time (как долго оставаться ON)
        -- Если выход теперь OFF, следующее переключение после pulse_time (как долго оставаться OFF)
        local next_period = (new_output == 1) and delay_time or pulse_time
        block.set_field(x, y, z, "next_toggle", uptime + next_period)
    end
end

function on_placed(x, y, z, playerid)
    block.set_field(x, y, z, "pulse_time", DEFAULT_PULSE_TIME)
    block.set_field(x, y, z, "delay_time", DEFAULT_DELAY_TIME)
    block.set_field(x, y, z, "next_toggle", time.uptime() + DEFAULT_PULSE_TIME)
    block.set_field(x, y, z, "output", 0)

    api.on_placed(x, y, z, device_id)
end

function on_interact(x, y, z, playerId)
    -- Проверить, есть ли у игрока logic_configurator в руках
    local invid, slot = player.get_inventory(playerId)
    if not invid or invid == 0 then
        return false
    end
    
    local itemid, count = inventory.get(invid, slot)
    if itemid == 0 then
        return false
    end
    
    local item_name = item.name(itemid)
    if item_name ~= "wire_mod_2:logic_configurator" then
        return false
    end
    
    -- Сохранение позиции блока в сессии для GUI
    if not session.entries then
        session.entries = {}
    end
    session.entries["clock_generator_pos"] = {x, y, z}
    
    -- Открыть GUI для настроек
    hud.show_overlay("advanced_logic_2:clock_generator", false, {x, y, z})
    return true
end

function on_broken(x, y, z, playerId)
    api.on_broken(x, y, z, device_id)
end

-- Кастомный view для logic_viewer
logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end

    local pulse_time     = block.get_field(x, y, z, "pulse_time")   or DEFAULT_PULSE_TIME
    local delay_time     = block.get_field(x, y, z, "delay_time")   or DEFAULT_DELAY_TIME
    local next_toggle    = block.get_field(x, y, z, "next_toggle")  or 0
    local current_output = block.get_field(x, y, z, "output")       or 0

    local time_until = 0
    local success, uptime = pcall(time.uptime)
    if success and uptime and next_toggle > 0 then
        time_until = math.max(0, next_toggle - uptime)
    end

    -- Period bar: |####....| proportional to time_until vs current period
    local current_period = (current_output == 1) and delay_time or pulse_time
    local bar_len = 10
    local filled = current_period > 0 and math.floor((time_until / current_period) * bar_len + 0.5) or 0
    filled = math.max(0, math.min(bar_len, filled))
    local bar = logic_viewer.color('|', '#555555')
               .. logic_viewer.color(string.rep('#', filled),          '#00FF88')
               .. logic_viewer.color(string.rep('.', bar_len - filled), '#333333')
               .. logic_viewer.color('|', '#555555')

    -- outputs = nil → auto-fill from device_system
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
        }
    }
end)

