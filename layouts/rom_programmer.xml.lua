-- ROM Programmer UI Script

local rom_storage = require("advanced_logic_2:rom_storage")

-- Глобальное состояние UI
local programmer_pos = {x = 0, y = 0, z = 0}
local current_rom_size = 16  -- Текущий размер ROM для валидации


-- Инициализация UI
function on_open(...)
    print("[ROM Programmer UI] on_open called")
    
    -- Получение позиции ROM блока из сессии (установлено в rom_4bit.lua)
    local args = {...}
    print(string.format("[ROM Programmer UI] Args count: %d", #args))
    if #args >= 3 then
        print(string.format("[ROM Programmer UI] Args: (%d, %d, %d)", args[1], args[2], args[3]))
    end
    
    local rom_x, rom_y, rom_z
    if session.entries and session.entries["rom_programmer_pos"] then
        local pos = session.entries["rom_programmer_pos"]
        rom_x, rom_y, rom_z = pos[1], pos[2], pos[3]
        print(string.format("[ROM Programmer UI] Got position from session: (%d, %d, %d)", rom_x, rom_y, rom_z))
    elseif args and #args >= 3 then
        rom_x, rom_y, rom_z = args[1], args[2], args[3]
        print(string.format("[ROM Programmer UI] Got position from args: (%d, %d, %d)", rom_x, rom_y, rom_z))
    else
        -- Если позиция не найдена, закрыть GUI
        print("[ROM Programmer UI] ERROR: ROM block position not found!")
        gui.alert("Error: ROM block position not found")
        close_gui()
        return
    end
    
    -- Сохранение позиции ROM блока
    programmer_pos = {x = rom_x, y = rom_y, z = rom_z}
    
    -- Формирование ROM ID для отображения
    local rom_id = string.format("rom_%d_%d_%d", rom_x, rom_y, rom_z)
    print(string.format("[ROM Programmer UI] ROM ID: %s", rom_id))
    
    -- Получение битности из сессии (установлено в rom_4bit.lua)
    local address_bits = 4  -- По умолчанию
    local cell_bits = 4     -- По умолчанию
    if session.entries then
        if session.entries["rom_address_bits"] then
            address_bits = session.entries["rom_address_bits"]
            print(string.format("[ROM Programmer UI] Got address_bits from session: %d", address_bits))
        end
        if session.entries["rom_cell_bits"] then
            cell_bits = session.entries["rom_cell_bits"]
            print(string.format("[ROM Programmer UI] Got cell_bits from session: %d", cell_bits))
        end
    end
    
    -- Если битность не в сессии, загрузить из метаданных ROM
    if not session.entries or not session.entries["rom_cell_bits"] then
        print("[ROM Programmer UI] Loading bits from ROM metadata...")
        local _, metadata = rom_storage.load_rom(rom_id)
        if metadata then
            address_bits = metadata.address_bits or address_bits
            cell_bits = metadata.cell_bits or cell_bits
            print(string.format("[ROM Programmer UI] Loaded from metadata: address_bits=%d, cell_bits=%d", address_bits, cell_bits))
        else
            print("[ROM Programmer UI] WARNING: Could not load ROM metadata, using defaults")
        end
    end
    
    print(string.format("[ROM Programmer UI] Final bits: address_bits=%d, cell_bits=%d", address_bits, cell_bits))
    
    -- Установка значений полей (как в clock_generator - напрямую по id)
    document.rom_id_label.text = rom_id
    print(string.format("[ROM Programmer UI] ROM ID label set to: %s", rom_id))
    
    -- Обновление ширины окна в зависимости от битности
    -- Используем pcall для безопасного вызова (на случай, если элемент еще не загружен)
    -- local success, err = pcall(function()
    --     update_window_width(cell_bits)
    -- end)
    -- if not success then
    --     print(string.format("[ROM Programmer UI] update_window_width failed: %s", tostring(err)))
    --     print("[ROM Programmer UI] Will continue without width update")
    -- end
    
    -- Загрузка начального HEX контента
    print("[ROM Programmer UI] Loading initial HEX content...")
    load_initial_hex(rom_id)
    
    -- -- Обновление позиции кнопок импорта/экспорта
    -- update_import_export_position()
    
    print("[ROM Programmer UI] UI initialization complete!")
end



-- Генерация HEX редактора с сеткой
function create_hex_grid(rom_size)
    rom_size = rom_size or 16
    local bytes_per_line = 8
    local num_rows = math.ceil(rom_size / bytes_per_line)
    
    -- Очистка существующих элементов
    if document.hex_header then
        document.hex_header:clear()
    end
    if document.hex_rows then
        document.hex_rows:clear()
    end
    
    -- Создание заголовка колонок
    if document.hex_header then
        for col = 0, bytes_per_line - 1 do
            local label = string.format("<label size='46,20' color='#E0E0E0' gravity='center-center'>%02X</label>", col)
            document.hex_header:add(label)
        end
    end
    
    -- Создание строк с адресами и textbox для каждого байта
    if document.hex_rows then
        for row = 0, num_rows - 1 do
            local row_address = row * bytes_per_line
            local row_y = row * 30
            
            -- Создание полного XML для строки
            local row_xml = string.format(
                "<panel pos='0,%d' size='420,25' orientation='horizontal' interval='18' color='0'>",
                row_y
            )
            
            -- Адрес строки (показываем адрес начала строки)
            row_xml = row_xml .. string.format(
                "<label size='30,25' color='#888888' gravity='center-center'>%02X:</label>",
                row_address
            )
            
            -- Textbox для каждого байта в строке
            for col = 0, bytes_per_line - 1 do
                local addr = row_address + col
                if addr < rom_size then
                    row_xml = row_xml .. string.format(
                        "<textbox id='hex_byte_%d' size='30,25' text='00' editable='true' text-color='#FFFFFF' color='#1A1A1AFF' maxlength='2' validator='hex_validator' consumer='function(val) on_hex_byte_change(%d, val) end' />",
                        addr, addr
                    )
                else
                    -- Пустое место для несуществующих байт
                    row_xml = row_xml .. "<panel size='40,25' color='0' />"
                end
            end
            
            row_xml = row_xml .. "</panel>"
            document.hex_rows:add(row_xml)
        end
    end
end

-- Валидатор для HEX значений
function hex_validator(text)
    if text == "" then return true end
    local num = tonumber(text, 16)
    return num ~= nil and num >= 0 and num <= 255
end

-- Обработка изменения байта в HEX редакторе
function on_hex_byte_change(address, value)
    local rom_id = document.rom_id_label.text
    if not rom_id or rom_id == "" then
        return
    end
    
    -- Получение метаданных ROM для ограничения значения
    local _, metadata = rom_storage.load_rom(rom_id)
    local max_value = 255  -- По умолчанию для 8+ бит
    if metadata and metadata.cell_bits then
        max_value = 2 ^ metadata.cell_bits - 1
    end
    
    -- Парсинг HEX значения
    local num_value = tonumber(value, 16) or 0
    if num_value < 0 then num_value = 0 end
    if num_value > max_value then 
        num_value = max_value
        -- Обновить текст в textbox, если значение было обрезано
        local textbox_id = "hex_byte_" .. tostring(address)
        if document[textbox_id] then
            document[textbox_id].text = string.format("%02X", num_value)
        end
    end
    
    -- Запись в ROM
    rom_storage.write_rom(rom_id, address, num_value)
    
    print(string.format("[ROM Programmer] HEX byte %d changed to 0x%02X", address, num_value))
end

-- Загрузка начального HEX контента
function load_initial_hex(rom_id)
    -- Получение размера ROM
    local _, metadata = rom_storage.load_rom(rom_id)
    local rom_size = 16  -- По умолчанию
    if metadata and metadata.size then
        rom_size = metadata.size
    end
    
    -- Сохранение размера ROM для валидации
    current_rom_size = rom_size
    
    -- Создание сетки HEX редактора
    create_hex_grid(rom_size)
    
    -- Загрузка данных в сетку
    local data, _ = rom_storage.load_rom(rom_id)
    if not data then
        -- Если ROM не существует, создать пустые данные
        data = {}
        for i = 0, rom_size - 1 do
            data[i] = 0
        end
    end
    
    -- Заполнение textbox значениями
    for addr = 0, rom_size - 1 do
        local textbox_id = "hex_byte_" .. tostring(addr)
        if document[textbox_id] then
            local value = (data[addr] or 0)
            document[textbox_id].text = string.format("%02X", value)
        end
    end
end


-- Запись данных из HEX сетки в ROM
function on_write_button_click()
    local rom_id = document.rom_id_label.text
    
    if not rom_id or rom_id == "" then
        gui.alert("Error: ROM ID is empty")
        return
    end
    
    -- Проверка формата ROM ID (формат: rom_X_Y_Z)
    local target_x, target_y, target_z = rom_id:match("rom_([%-]?%d+)_([%-]?%d+)_([%-]?%d+)")
    
    if not target_x then
        gui.alert("Error: Invalid ROM ID format (use: rom_X_Y_Z)")
        return
    end
    
    -- Получение размера ROM из метаданных
    local _, metadata = rom_storage.load_rom(rom_id)
    local rom_size = 16  -- По умолчанию
    if metadata and metadata.size then
        rom_size = metadata.size
    end
    
    -- Получение данных из HEX сетки
    local data = get_hex_grid_data(rom_size)
    
    -- Сохранение данных в ROM
    local success = true
    for addr = 0, rom_size - 1 do
        if not rom_storage.write_rom(rom_id, addr, data[addr] or 0) then
            success = false
            break
        end
    end
    
    if success then
        gui.alert("ROM записан")
    else
        gui.alert("Ошибка записи ROM")
    end
end

-- Чтение данных из ROM в HEX сетку
function on_read_button_click()
    local rom_id = document.rom_id_label.text
    
    if not rom_id or rom_id == "" then
        gui.alert("Error: ROM ID is empty")
        return
    end
    
    -- Загрузка данных из ROM
    local data, metadata = rom_storage.load_rom(rom_id)
    
    if data and metadata then
        -- Обновление сетки из данных ROM
        local rom_size = metadata.size or 16
        for addr = 0, rom_size - 1 do
            local textbox_id = "hex_byte_" .. tostring(addr)
            if document[textbox_id] then
                local value = (data[addr] or 0)
                document[textbox_id].text = string.format("%02X", value)
            end
        end
        gui.alert("ROM прочитан")

    else
        -- Если ROM не существует, показать пустой шаблон
        load_initial_hex(rom_id)
        gui.alert("ROM не найден, показан пустой шаблон")
    end
end

-- Очистка ROM (заполнение нулями)
function on_clear_button_click()
    local rom_id = document.rom_id_label.text
    
    if not rom_id or rom_id == "" then
        gui.alert("Error: ROM ID is empty")
        return
    end
    
    -- Получение размера ROM из метаданных
    local _, metadata = rom_storage.load_rom(rom_id)
    local rom_size = 16  -- По умолчанию
    if metadata and metadata.size then
        rom_size = metadata.size
    end
    
    -- Очистка всех ячеек ROM
    for addr = 0, rom_size - 1 do
        rom_storage.write_rom(rom_id, addr, 0)
    end
    
    -- Обновление HEX редактора
    for addr = 0, rom_size - 1 do
        local textbox_id = "hex_byte_" .. tostring(addr)
        if document[textbox_id] then
            document[textbox_id].text = "00"
        end
    end
    
    gui.alert("ROM Очищен")
end

-- Получение данных из HEX сетки
function get_hex_grid_data(rom_size)
    rom_size = rom_size or 16
    local data = {}
    
    for addr = 0, rom_size - 1 do
        local textbox_id = "hex_byte_" .. tostring(addr)
        if document[textbox_id] then
            local hex_text = document[textbox_id].text
            local value = tonumber(hex_text, 16) or 0
            if value < 0 then value = 0 end
            if value > 255 then value = 255 end
            data[addr] = value
        else
            data[addr] = 0
        end
    end
    
    return data
end


-- Закрытие UI
function on_close_button_click()
    close_gui()
end

function close_gui()
    hud.close("advanced_logic_2:rom_programmer")
end

