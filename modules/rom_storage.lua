-- -- Модуль для хранения данных ROM в файлах
-- -- Избегаем сохранения больших массивов данных в полях блоков

-- local rom_storage = {}

-- local PACK_ID = "advanced_logic_2"

-- -- Кэш загруженных ROM данных
-- -- Структура: [rom_id] = {data = {}, metadata = {}}
-- local rom_cache = {}

-- ---Генерация уникального ID для ROM блока на основе позиции
-- ---@param x integer
-- ---@param y integer
-- ---@param z integer
-- ---@return string
-- local function generate_rom_id(x, y, z)
--     return string.format("rom_%d_%d_%d", x, y, z)
-- end

-- ---Получение пути к файлу данных ROM
-- ---@param rom_id string
-- ---@return string
-- local function get_rom_data_path(rom_id)
--     return pack.data_file(PACK_ID, "rom_data/" .. rom_id .. ".bin")
-- end

-- ---Получение пути к файлу метаданных ROM
-- ---@param rom_id string
-- ---@return string
-- local function get_rom_metadata_path(rom_id)
--     return pack.data_file(PACK_ID, "rom_data/" .. rom_id .. ".json")
-- end

-- ---Создание нового ROM с заданными параметрами
-- ---@param x integer
-- ---@param y integer
-- ---@param z integer
-- ---@param size integer Размер ROM в ячейках (16, 256, 4096 и т.д.)
-- ---@param cell_bits integer Количество бит на ячейку (4, 8, 16)
-- ---@return string rom_id
-- function rom_storage.create_rom(x, y, z, size, cell_bits)
--     local rom_id = generate_rom_id(x, y, z)
    
--     -- Создание пустого массива данных
--     local data = {}
--     for i = 0, size - 1 do
--         data[i] = 0
--     end
    
--     -- Метаданные ROM
--     local metadata = {
--         rom_id = rom_id,
--         position = {x = x, y = y, z = z},
--         size = size,
--         cell_bits = cell_bits,
--         address_bits = math.ceil(math.log(size) / math.log(2)),
--         created_at = os.time(),
--         modified_at = os.time(),
--         version = 1
--     }
    
--     -- Сохранение в файлы
--     rom_storage.save_rom(rom_id, data, metadata)
    
--     return rom_id
-- end

-- ---Сохранение данных ROM в файлы
-- ---@param rom_id string
-- ---@param data table Массив данных ROM
-- ---@param metadata table Метаданные ROM
-- function rom_storage.save_rom(rom_id, data, metadata)
--     -- Обновление времени модификации
--     metadata.modified_at = os.time()
    
--     -- Сохранение данных в бинарный файл
--     local data_path = get_rom_data_path(rom_id)
    
--     -- Создание директории rom_data, если её нет
--     -- pack.data_file создает директории автоматически для текстовых файлов,
--     -- но file.write_bytes может не создавать их, поэтому используем file.mkdirs()
--     local dir_path = file.parent(data_path)
--     file.mkdirs(dir_path)
--     local bytes = {}
    
--     -- Упаковка данных в байты
--     if metadata.cell_bits == 4 then
--         -- По 2 ячейки на байт для 4-битных данных
--         for i = 0, metadata.size - 1, 2 do
--             local low = data[i] or 0
--             local high = data[i + 1] or 0
--             table.insert(bytes, (high * 16) + low)
--         end
--     elseif metadata.cell_bits == 6 then
--         -- Храним 6-битные значения как 8-битные байты (значения ограничены 0-63)
--         for i = 0, metadata.size - 1 do
--             table.insert(bytes, data[i] or 0)
--         end
--     elseif metadata.cell_bits == 8 then
--         for i = 0, metadata.size - 1 do
--             table.insert(bytes, data[i] or 0)
--         end
--     elseif metadata.cell_bits == 16 then
--         for i = 0, metadata.size - 1 do
--             local value = data[i] or 0
--             table.insert(bytes, math.floor(value / 256))  -- Старший байт
--             table.insert(bytes, value % 256)                -- Младший байт
--         end
--     end
    
--     file.write_bytes(data_path, bytes)
    
--     -- Сохранение метаданных в JSON
--     local metadata_path = get_rom_metadata_path(rom_id)
--     local metadata_json = "{\n"
--     metadata_json = metadata_json .. '  "rom_id": "' .. metadata.rom_id .. '",\n'
--     metadata_json = metadata_json .. '  "position": {"x": ' .. metadata.position.x .. ', "y": ' .. metadata.position.y .. ', "z": ' .. metadata.position.z .. '},\n'
--     metadata_json = metadata_json .. '  "size": ' .. metadata.size .. ',\n'
--     metadata_json = metadata_json .. '  "cell_bits": ' .. metadata.cell_bits .. ',\n'
--     metadata_json = metadata_json .. '  "address_bits": ' .. metadata.address_bits .. ',\n'
--     metadata_json = metadata_json .. '  "created_at": ' .. metadata.created_at .. ',\n'
--     metadata_json = metadata_json .. '  "modified_at": ' .. metadata.modified_at .. ',\n'
--     metadata_json = metadata_json .. '  "version": ' .. metadata.version .. '\n'
--     metadata_json = metadata_json .. '}'
--     file.write(metadata_path, metadata_json)
    
--     -- Обновление кэша
--     rom_cache[rom_id] = {
--         data = data,
--         metadata = metadata
--     }
    
--     print("[ROM Storage] Saved ROM: " .. rom_id .. " (" .. metadata.size .. " cells x " .. metadata.cell_bits .. " bits)")
-- end

-- ---Загрузка данных ROM из файлов
-- ---@param rom_id string
-- ---@return table|nil, table|nil Данные и метаданные ROM или nil, если не найдено
-- function rom_storage.load_rom(rom_id)
--     -- Проверка кэша
--     if rom_cache[rom_id] then
--         return rom_cache[rom_id].data, rom_cache[rom_id].metadata
--     end
    
--     local metadata_path = get_rom_metadata_path(rom_id)
--     local data_path = get_rom_data_path(rom_id)
    
--     -- Проверка существования файлов
--     if not file.exists(metadata_path) or not file.exists(data_path) then
--         return nil, nil
--     end
    
--     -- Загрузка метаданных (простой парсинг JSON)
--     local metadata_str = file.read(metadata_path)
--     local metadata = {}
    
--     -- Простой парсер для метаданных ROM
--     metadata.rom_id = metadata_str:match('"rom_id"%s*:%s*"([^"]+)"')
--     metadata.size = tonumber(metadata_str:match('"size"%s*:%s*(%d+)'))
--     metadata.cell_bits = tonumber(metadata_str:match('"cell_bits"%s*:%s*(%d+)'))
--     metadata.address_bits = tonumber(metadata_str:match('"address_bits"%s*:%s*(%d+)'))
--     metadata.created_at = tonumber(metadata_str:match('"created_at"%s*:%s*(%-?%d+)'))
--     metadata.modified_at = tonumber(metadata_str:match('"modified_at"%s*:%s*(%-?%d+)'))
--     metadata.version = tonumber(metadata_str:match('"version"%s*:%s*(%d+)'))
    
--     -- Парсинг координат (могут быть отрицательными)
--     local x = tonumber(metadata_str:match('"x"%s*:%s*(%-?%d+)'))
--     local y = tonumber(metadata_str:match('"y"%s*:%s*(%-?%d+)'))
--     local z = tonumber(metadata_str:match('"z"%s*:%s*(%-?%d+)'))
--     metadata.position = {x = x, y = y, z = z}
    
--     -- Загрузка данных
--     local bytes = file.read_bytes(data_path, true)
--     local data = {}
    
--     -- Распаковка данных из байтов
--     if metadata.cell_bits == 4 then
--         for i, byte in ipairs(bytes) do
--             local idx = (i - 1) * 2
--             data[idx] = byte % 16        -- Младшие 4 бита
--             data[idx + 1] = math.floor(byte / 16)  -- Старшие 4 бита
--         end
--     elseif metadata.cell_bits == 6 then
--         -- 6-битные значения хранятся как 8-битные байты, ограничиваем до 63
--         for i, byte in ipairs(bytes) do
--             data[i - 1] = math.min(byte, 63)  -- Ограничение до 6 бит (0-63)
--         end
--     elseif metadata.cell_bits == 8 then
--         for i, byte in ipairs(bytes) do
--             data[i - 1] = byte
--         end
--     elseif metadata.cell_bits == 16 then
--         for i = 1, #bytes, 2 do
--             local idx = math.floor((i - 1) / 2)
--             data[idx] = bytes[i] * 256 + bytes[i + 1]
--         end
--     end
    
--     -- Кэширование
--     rom_cache[rom_id] = {
--         data = data,
--         metadata = metadata
--     }
    
--     print("[ROM Storage] Loaded ROM: " .. rom_id .. " (" .. metadata.size .. " cells x " .. metadata.cell_bits .. " bits)")
    
--     return data, metadata
-- end

-- ---Чтение значения из ROM по адресу
-- ---@param rom_id string
-- ---@param address integer
-- ---@return integer|nil Значение или nil, если ROM не найдена
-- function rom_storage.read_rom(rom_id, address)
--     local data, metadata = rom_storage.load_rom(rom_id)
    
--     if not data or not metadata then
--         return nil
--     end
    
--     -- Проверка диапазона адреса
--     if address < 0 or address >= metadata.size then
--         return 0
--     end
    
--     return data[address] or 0
-- end

-- ---Запись значения в ROM (для программирования)
-- ---@param rom_id string
-- ---@param address integer
-- ---@param value integer
-- ---@return boolean Успешность операции
-- function rom_storage.write_rom(rom_id, address, value)
--     local data, metadata = rom_storage.load_rom(rom_id)
    
--     if not data or not metadata then
--         return false
--     end
    
--     -- Проверка диапазона адреса
--     if address < 0 or address >= metadata.size then
--         return false
--     end
    
--     -- Ограничение значения максимальным для данной битности
--     local max_value = 2 ^ metadata.cell_bits - 1
--     value = math.min(math.max(0, value), max_value)
    
--     -- Запись значения
--     data[address] = value
    
--     -- Сохранение изменений
--     rom_storage.save_rom(rom_id, data, metadata)
    
--     return true
-- end

-- ---Удаление ROM и её файлов
-- ---@param rom_id string
-- ---@return boolean Успешность операции
-- function rom_storage.delete_rom(rom_id)
--     local data_path = get_rom_data_path(rom_id)
--     local metadata_path = get_rom_metadata_path(rom_id)
    
--     -- Удаление файлов
--     local success = true
--     if file.exists(data_path) then
--         success = success and file.remove(data_path)
--     end
--     if file.exists(metadata_path) then
--         success = success and file.remove(metadata_path)
--     end
    
--     -- Удаление из кэша
--     rom_cache[rom_id] = nil
    
--     print("[ROM Storage] Deleted ROM: " .. rom_id)
    
--     return success
-- end

-- ---Получение ROM ID по позиции блока
-- ---@param x integer
-- ---@param y integer
-- ---@param z integer
-- ---@return string|nil rom_id или nil, если ROM не найдена
-- function rom_storage.get_rom_id_by_position(x, y, z)
--     local rom_id = generate_rom_id(x, y, z)
    
--     -- Проверка существования ROM
--     if file.exists(get_rom_metadata_path(rom_id)) then
--         return rom_id
--     end
    
--     return nil
-- end

-- ---Экспорт данных ROM в HEX формат
-- ---@param rom_id string
-- ---@return string|nil HEX строка или nil
-- function rom_storage.export_rom_hex(rom_id)
--     local data, metadata = rom_storage.load_rom(rom_id)
    
--     if not data or not metadata then
--         return nil
--     end
    
--     local hex_lines = {}
--     local bytes_per_line = 16
    
--     for i = 0, metadata.size - 1, bytes_per_line do
--         local line = string.format("%04X: ", i)
--         local ascii = ""
        
--         for j = 0, bytes_per_line - 1 do
--             local idx = i + j
--             if idx < metadata.size then
--                 local value = data[idx] or 0
--                 line = line .. string.format("%02X ", value)
                
--                 -- ASCII представление (если применимо)
--                 if value >= 32 and value < 127 then
--                     ascii = ascii .. string.char(value)
--                 else
--                     ascii = ascii .. "."
--                 end
--             end
--         end
        
--         table.insert(hex_lines, line .. " | " .. ascii)
--     end
    
--     return table.concat(hex_lines, "\n")
-- end

-- ---Импорт данных ROM из HEX формата
-- ---@param rom_id string
-- ---@param hex_str string
-- ---@return boolean Успешность операции
-- function rom_storage.import_rom_hex(rom_id, hex_str)
--     local data, metadata = rom_storage.load_rom(rom_id)
    
--     if not data or not metadata then
--         return false
--     end
    
--     local address = 0
    
--     -- Парсинг HEX строк
--     for line in hex_str:gmatch("[^\r\n]+") do
--         -- Пропуск комментариев и пустых строк
--         if not line:match("^%s*$") and not line:match("^%s*#") then
--             -- Извлечение HEX значений
--             for hex_value in line:gmatch("%x%x") do
--                 if address < metadata.size then
--                     data[address] = tonumber(hex_value, 16)
--                     address = address + 1
--                 end
--             end
--         end
--     end
    
--     -- Сохранение изменений
--     rom_storage.save_rom(rom_id, data, metadata)
    
--     return true
-- end

-- ---Очистка кэша ROM (вызывать при выгрузке мира)
-- function rom_storage.clear_cache()
--     rom_cache = {}
--     print("[ROM Storage] Cache cleared")
-- end

-- return rom_storage

