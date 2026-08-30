--- Общая логика для блоков памяти (RAM/ROM).
--- Все функции принимают phys_cells явно — это позволяет иметь блоки разного размера
--- (ram=16 ячеек, ram_large=64 ячеек, и т.д.) без дублирования логики.

---@class ALMemoryCommon
local M = {}

--- Дефолт для совместимости со старыми скриптами.
M.DEFAULT_PHYS_CELLS = 16

--- Допустимые битности данных (cycle через UI).
M.BIT_CYCLE = {4, 8, 16}

local INT16_MODULUS = 65536
local INT16_SIGN_BIT = 32768

---Безопасное получение битности (если field не задан или 0 — возвращает 4 как дефолт).
---@param v number|nil
---@return integer
function M.safe_bits(v)
    if not v or v == 0 then return 4 end
    return v
end

---@param x integer
---@param y integer
---@param z integer
---@return integer
function M.get_addr_bits(x, y, z)
    return M.safe_bits(block.get_field(x, y, z, "addr_bits", 0))
end

---@param x integer
---@param y integer
---@param z integer
---@return integer
function M.get_data_bits(x, y, z)
    return M.safe_bits(block.get_field(x, y, z, "data_bits", 0))
end

---Следующая битность в цикле {4, 8, 16}. После 16 → 4.
---@param cur integer
---@return integer
function M.next_in_cycle(cur)
    for i, v in ipairs(M.BIT_CYCLE) do
        if v == cur then return M.BIT_CYCLE[(i % #M.BIT_CYCLE) + 1] end
    end
    return 4
end

---@param bits integer
---@return integer
function M.value_mask(bits)
    return 2 ^ bits - 1
end

---@param value integer
---@param bits integer
---@return integer
function M.clamp_value(value, bits)
    local mask = M.value_mask(bits)
    return math.floor(value or 0) % (mask + 1)
end

---Читает int16-поле памяти как беззнаковое значение 0..65535.
---@param x integer
---@param y integer
---@param z integer
---@param index integer
---@return integer
function M.read_cell(x, y, z, index)
    local value = block.get_field(x, y, z, "mem", index) or 0
    if value < 0 then
        return value + INT16_MODULUS
    end
    return value
end

---Записывает беззнаковое 16-битное значение в знаковое int16-поле.
---@param x integer
---@param y integer
---@param z integer
---@param value number
---@param index integer
function M.write_cell(x, y, z, value, index)
    value = math.floor(value or 0) % INT16_MODULUS
    if value >= INT16_SIGN_BIT then
        value = value - INT16_MODULUS
    end
    block.set_field(x, y, z, "mem", value, index)
end

---При смене data_bits применить новую mask ко всем сохранённым ячейкам.
---@param x integer
---@param y integer
---@param z integer
---@param new_bits integer
---@param phys_cells integer Размер памяти (число ячеек)
function M.normalize_cells_for_bits(x, y, z, new_bits, phys_cells)
    phys_cells = phys_cells or M.DEFAULT_PHYS_CELLS
    local mask = M.value_mask(new_bits)
    for i = 0, phys_cells - 1 do
        local v = M.read_cell(x, y, z, i)
        if v > mask then
            M.write_cell(x, y, z, math.floor(v) % (mask + 1), i)
        end
    end
end

---Дамп памяти для logic_viewer.
---Кол-во строк автоматически: phys_cells / 8 (rounding up).
---Для phys_cells=16: 2 строки по 8. Для phys_cells=64: 8 строк по 8.
---@param x integer
---@param y integer
---@param z integer
---@param data_bits integer
---@param phys_cells integer
---@return table Массив строк {{name = "..."}, ...}
function M.build_memory_dump(x, y, z, data_bits, phys_cells)
    phys_cells = phys_cells or M.DEFAULT_PHYS_CELLS
    local fmt = data_bits <= 8 and "%02X " or "%04X "
    local cols = 8
    local rows = math.ceil(phys_cells / cols)
    local out = {}
    -- Лимит вывода в viewer: первые 4 строки. Иначе слишком много текста.
    local max_view_rows = 4
    for row = 0, math.min(rows, max_view_rows) - 1 do
        local line = string.format("%02X: ", row * cols)
        for col = 0, cols - 1 do
            local idx = row * cols + col
            if idx < phys_cells then
                local val = M.read_cell(x, y, z, idx)
                line = line .. string.format(fmt, val)
            end
        end
        table.insert(out, {name = line})
    end
    if rows > max_view_rows then
        table.insert(out, {name = string.format("... (%d ячеек, открой редактор для всех)", phys_cells), color = "#888888"})
    end
    return out
end

---Инициализация полей памяти.
---@param x integer
---@param y integer
---@param z integer
---@param phys_cells integer
function M.init_fields(x, y, z, phys_cells)
    phys_cells = phys_cells or M.DEFAULT_PHYS_CELLS
    local addr_bits = 0
    local capacity = 1
    while capacity < phys_cells do
        capacity = capacity * 2
        addr_bits = addr_bits + 1
    end
    block.set_field(x, y, z, "addr_bits", addr_bits, 0)
    if not block.get_field(x, y, z, "data_bits", 0) then
        block.set_field(x, y, z, "data_bits", 4, 0)
    end
    for i = 0, phys_cells - 1 do
        if block.get_field(x, y, z, "mem", i) == nil then
            M.write_cell(x, y, z, 0, i)
        end
    end
end

return M
