--- Clock Registry: централизованное управление clock_generator блоками.
--- Заменяет per-block on_block_tick на один глобальный tick (см. P2.10).
---
--- Преимущества:
---   1. Один callback вместо N (масштабируется до сотен clocks).
---   2. Глобальная пауза/step через step debugger.
---   3. Легче дебажить.

---@class ALClockRegistry
local M = {}

--- Зарегистрированные clocks.
--- key = "x:y:z", value = {x, y, z}
local clocks = {}

--- Глобальная пауза. Когда true — clocks НЕ обрабатываются автоматически.
local paused = false

--- Счётчик ручных шагов (для step debugger).
local pending_steps = 0

local function pos_key(x, y, z)
    return x .. ":" .. y .. ":" .. z
end

---Регистрация clock_generator.
---@param x integer
---@param y integer
---@param z integer
function M.register(x, y, z)
    clocks[pos_key(x, y, z)] = {x, y, z}
end

---@param x integer
---@param y integer
---@param z integer
function M.unregister(x, y, z)
    clocks[pos_key(x, y, z)] = nil
end

---@return boolean
function M.is_paused()
    return paused
end

---Установить состояние паузы.
---@param p boolean
function M.set_paused(p)
    paused = p == true
end

---Тогглить паузу. Возвращает новое состояние.
---@return boolean
function M.toggle_paused()
    paused = not paused
    return paused
end

---Запросить ручной шаг (для step debugger). Если на паузе — следующий tick
---обработает clocks один раз и снова замрёт.
function M.request_step()
    pending_steps = pending_steps + 1
end

---@return integer
function M.clock_count()
    local n = 0
    for _ in pairs(clocks) do n = n + 1 end
    return n
end

---Tick callback (вызывается из world.lua on_world_tick).
---Обрабатывает все зарегистрированные clocks.
---@param process_clock fun(x: integer, y: integer, z: integer)
function M.tick(process_clock)
    -- Если на паузе и нет pending steps — пропускаем.
    if paused and pending_steps == 0 then
        return
    end

    if pending_steps > 0 then
        pending_steps = pending_steps - 1
    end

    -- Делаем копию ключей чтобы безопасно итерировать (clock мог удалиться).
    local keys = {}
    for k, _ in pairs(clocks) do table.insert(keys, k) end

    for _, k in ipairs(keys) do
        local pos = clocks[k]
        if pos then
            local block_id = block.get(pos[1], pos[2], pos[3])
            if block_id == 0 then
                -- Блок удалён — снимаем регистрацию.
                clocks[k] = nil
            else
                local ok, err = pcall(process_clock, pos[1], pos[2], pos[3])
                if not ok then
                    print("[clock_registry] tick error at " .. k .. ": " .. tostring(err))
                end
            end
        end
    end
end

return M
