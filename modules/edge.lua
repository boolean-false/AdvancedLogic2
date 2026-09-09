--- Вспомогательные функции обнаружения фронтов для синхронной логики.
--- Все последовательные блоки (flip-flop, register, counter, RAM) должны использовать их,
--- чтобы фронты везде обрабатывались одинаково (читаем prev_<name> из field, сравниваем,
--- пишем новое значение обратно).

---@class ALEdge
local M = {}

---Обнаружение переднего фронта (0->1) на сигнале sig. Сохраняет текущее значение в поле блока <name>.
---@param x integer
---@param y integer
---@param z integer
---@param sig integer Текущее значение сигнала (0 или ненулевое)
---@param field_name string Имя поля для хранения предыдущего значения (например "prev_clk")
---@return boolean Значение true, если зафиксирован переход 0->1
function M.rising(x, y, z, sig, field_name)
    local prev = block.get_field(x, y, z, field_name) or 0
    local now = (sig and sig ~= 0) and 1 or 0
    block.set_field(x, y, z, field_name, now)
    return now == 1 and prev == 0
end

---Обнаружение заднего фронта (1->0).
---@param x integer
---@param y integer
---@param z integer
---@param sig integer
---@param field_name string
---@return boolean
function M.falling(x, y, z, sig, field_name)
    local prev = block.get_field(x, y, z, field_name) or 0
    local now = (sig and sig ~= 0) and 1 or 0
    block.set_field(x, y, z, field_name, now)
    return now == 0 and prev == 1
end

---Обнаружение любого фронта (0->1 или 1->0).
---@param x integer
---@param y integer
---@param z integer
---@param sig integer
---@param field_name string
---@return boolean
function M.any(x, y, z, sig, field_name)
    local prev = block.get_field(x, y, z, field_name) or 0
    local now = (sig and sig ~= 0) and 1 or 0
    block.set_field(x, y, z, field_name, now)
    return now ~= prev
end

---Только обновить prev-поле без проверки фронта (для случаев когда edge нужно
---зафиксировать но не обработать - например, при асинхронном RST).
---@param x integer
---@param y integer
---@param z integer
---@param sig integer
---@param field_name string
function M.update(x, y, z, sig, field_name)
    local now = (sig and sig ~= 0) and 1 or 0
    block.set_field(x, y, z, field_name, now)
end

return M
