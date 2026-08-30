-- Редактор/просмотрщик памяти ROM/RAM
-- addr_bits определяется физическим объёмом блока (16→4, 64→6).
-- data_bits: ширина данных (4/8/16). Влияет на диапазон значений.

local api        = require("wire_mod_2:api")
local mem        = require("advanced_logic_2:memory_common")

local LAYOUT_ID  = "advanced_logic_2:memory_editor"
local bx, by, bz
local is_rom
local mem_type    -- "ROM" / "RAM"
local addr_bits   -- 4 / 8 / 16
local data_bits   -- 4 / 8 / 16
local phys_cells  -- 16 / 64 / ... зависит от типа блока

-- ========================
-- Утилиты
-- ========================

local function safe_bits(v)
    return mem.safe_bits(v)
end

local function next_in_cycle(cur)
    return mem.next_in_cycle(cur)
end

local function get_max()   return 2 ^ data_bits - 1 end

local function to_bin(val)
    val = math.floor(val or 0)
    if data_bits > 8 then return "--------" end
    local s = ""
    for i = data_bits - 1, 0, -1 do
        s = s .. (math.floor(val / (2 ^ i)) % 2)
        if i == 4 and data_bits == 8 then s = s .. "_" end
    end
    return s
end

local function hex_fmt(val)
    if data_bits <= 4  then return string.format("0x%X",   val) end
    if data_bits <= 8  then return string.format("0x%02X", val) end
    return string.format("0x%04X", val)
end

local function clamp_val(text)
    local n = math.floor(tonumber(text) or 0)
    local mx = get_max()
    if n < 0  then return 0  end
    if n > mx then return mx end
    return n
end

-- ========================
-- Обновление лейблов (бинарник + хекс, не трогает textbox)
-- ========================

local function update_labels(addr, val)
    local bin = document["bin_" .. addr]
    local hex = document["hex_" .. addr]
    if bin then bin.text = to_bin(val)  end
    if hex then hex.text = hex_fmt(val) end
end

-- ========================
-- Построение сетки
-- ========================

local function build_grid()
    local grid = document["mem_grid"]
    grid:clear()
    local editable = is_rom and "true" or "false"

    -- Сначала создаём структуру БЕЗ атрибута text= на textbox.
    -- text="..." в динамическом XML работает как supplier (каждый кадр),
    -- что сбрасывает введённые пользователем значения.
    for i = 0, phys_cells - 1 do
        grid:add(string.format(
            '<panel size="268,22" orientation="horizontal" interval="3" color="#00000000">'
            .. '<label size="36,20" color="#5588FF" font-size="10">0x%02X</label>'
            .. '<textbox id="cell_%d" size="54,20" editable="%s"'
            .. ' font-size="10" text-color="#FFFFFF" color="#1A1A1AFF"/>'
            .. '<label id="bin_%d" size="96,20" color="#505060" font-size="9"></label>'
            .. '<label id="hex_%d" size="42,20" color="#44DDAA" font-size="10"></label>'
            .. '</panel>',
            i, i, editable, i, i
        ))
    end

    -- Заполняем значения через .text — это разовое присвоение, не supplier.
    for i = 0, phys_cells - 1 do
        local val  = block.get_field(bx, by, bz, "mem", i) or 0
        local cell = document["cell_" .. i]
        if cell then cell.text = tostring(val) end
        update_labels(i, val)
    end
end

-- ========================
-- Обновление заголовка и кнопок режима
-- ========================

local function refresh_header()
    document["mem_title"].text = string.format(
        "%s  addr:%db  data:%db",
        mem_type, addr_bits, data_bits
    )
    local ba = document["btn_addr"]
    local bd = document["btn_data"]
    if ba then ba.text = string.format("Addr: %db", addr_bits) end
    if bd then bd.text = string.format("Data: %db", data_bits) end
end

-- ========================
-- Кнопки
-- ========================

function on_mem_apply()
    if not is_rom then return end
    for i = 0, phys_cells - 1 do
        local cell = document["cell_" .. i]
        if cell then
            local val = clamp_val(cell.text)
            cell.text = tostring(val)
            block.set_field(bx, by, bz, "mem", val, i)
            update_labels(i, val)
        end
    end
    api.mark_device_for_update(bx, by, bz)
end

function on_mem_close()
    hud.close(LAYOUT_ID)
end

function on_mem_clear()
    if not is_rom then return end
    for i = 0, phys_cells - 1 do
        block.set_field(bx, by, bz, "mem", 0, i)
        local cell = document["cell_" .. i]
        if cell then cell.text = "0" end
        update_labels(i, 0)
    end
    api.mark_device_for_update(bx, by, bz)
end

-- ========================
-- Адресная ширина фиксирована физическим объёмом памяти.
-- ========================

function on_addr_cycle()
    refresh_header()
end

-- ========================
-- Цикл data_bits
-- ========================

function on_data_cycle()
    data_bits = next_in_cycle(data_bits)
    block.set_field(bx, by, bz, "data_bits", data_bits, 0)
    -- Применяем новую mask ко всем ячейкам (P2.13).
    mem.normalize_cells_for_bits(bx, by, bz, data_bits, phys_cells)
    refresh_header()
    build_grid()
    -- Битность является частью конфигурации порта: нужно пересобрать связи,
    -- а не только пересчитать значение устройства.
    api.refresh_device(bx, by, bz)
end

-- ========================
-- Авто-обновление ОЗУ
-- ========================

function refresh_all()
    for i = 0, phys_cells - 1 do
        local val  = block.get_field(bx, by, bz, "mem", i) or 0
        local cell = document["cell_" .. i]
        if cell then cell.text = tostring(val) end
        update_labels(i, val)
    end
end

-- ========================
-- События layout
-- ========================

function on_open(...)
    local args = {...}

    if session.entries and session.entries["mem_editor_pos"] then
        local pos = session.entries["mem_editor_pos"]
        bx, by, bz = pos[1], pos[2], pos[3]
    elseif args and #args >= 3 then
        bx, by, bz = args[1], args[2], args[3]
    else
        hud.close(LAYOUT_ID)
        return
    end

    is_rom     = (session.entries and session.entries["mem_editor_is_rom"]) or false
    mem_type   = (session.entries and session.entries["mem_editor_type"]) or (is_rom and "ROM" or "RAM")
    addr_bits  = safe_bits(session.entries and session.entries["mem_editor_addr_bits"])
    data_bits  = safe_bits(session.entries and session.entries["mem_editor_data_bits"])
    phys_cells = (session.entries and session.entries["mem_editor_phys_cells"]) or 16
    if phys_cells == 0 then phys_cells = 16 end

    refresh_header()

    document["mem_apply"].visible = is_rom
    document["mem_clear"].visible = is_rom

    build_grid()
end

function on_close(invid)
end
