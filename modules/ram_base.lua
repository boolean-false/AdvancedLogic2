-- -- Базовый модуль для реализации ОЗУ (RAM)
-- -- Предоставляет общую логику для всех типов ОЗУ с поддержкой записи через входы

-- local bus_system = require("advanced_logic_2:bus_system")
-- local core = require("wire_mod:core")
-- local rom_storage = require("advanced_logic_2:rom_storage")

-- ---Создание обработчика ОЗУ с заданной конфигурацией
-- ---@param config table Конфигурация ОЗУ:
-- ---   - block_name: string - имя блока (например, "advanced_logic_2:ram_4bit")
-- ---   - display_name: string - отображаемое имя (например, "ОЗУ 4-бит")
-- ---   - ram_size: integer - размер RAM в ячейках
-- ---   - ram_cell_bits: integer - количество бит на ячейку
-- ---   - ram_address_bits: integer - количество бит адреса
-- ---   - ram_output_bus_width: integer - ширина выходной шины
-- ---   - default_input_bus_width: integer - ширина входной шины адреса по умолчанию
-- ---@return table Модуль с функциями для использования в блоке
-- local function create_ram_handler(config)
--     local block_name = config.block_name
--     local display_name = config.display_name
--     local RAM_SIZE = config.ram_size
--     local RAM_CELL_BITS = config.ram_cell_bits
--     local RAM_ADDRESS_BITS = config.ram_address_bits
--     local RAM_OUTPUT_BUS_WIDTH = config.ram_output_bus_width
--     local DEFAULT_INPUT_BUS_WIDTH = config.default_input_bus_width or RAM_ADDRESS_BITS
    
--     local ram_base = {}
    
--     ---Получение адреса из входной шины с учетом смещения битов
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@return integer address
--     function ram_base.get_address_from_bus(ox, oy, oz)
--         local api_module = require("wire_mod:api")
--         local rotation = block.get_rotation(ox, oy, oz)
        
--         -- Получение конфигурации устройства для named входов
--         local config = api_module.complex_devices[block_name]
--         local input_entries = config and config.input_entries and config.input_entries[rotation]
        
--         local bus_value = 0
--         local bus_width = DEFAULT_INPUT_BUS_WIDTH
        
--         if input_entries and input_entries["address_bus"] then
--             -- Использование named входа через API
--             local entry = input_entries["address_bus"]
--             local input_dir = entry.dir
--             local offset = entry.offset or 0
            
--             -- Вычисление позиции сегмента для этого входа
--             local block_id = block.get(ox, oy, oz)
--             local size_x, size_y, size_z = 1, 1, 1
--             if block_id ~= 0 then
--                 local success_size, sx, sy, sz = pcall(block.get_size, block_id)
--                 if success_size then
--                     size_x, size_y, size_z = sx, sy, sz
--                 end
--             end
            
--             local bx, by, bz = api_module.calculate_segment_position(
--                 ox, oy, oz, rotation, input_dir, offset,
--                 size_x, size_y, size_z
--             )
            
--             -- Получение значения с шины
--             if bus_system.is_bus(bx, by, bz) then
--                 bus_value = bus_system.get_bus_value(bx, by, bz)
--                 bus_width = bus_system.get_bus_width(bx, by, bz)
--             end
--         else
--             -- Fallback: старый способ (dir = 0, offset = 0)
--             local input_dir = 0
--             local world_input_dir = (input_dir + rotation) % 4
--             local dx, dy, dz = core.DIRECTIONS[world_input_dir][1], core.DIRECTIONS[world_input_dir][2], core.DIRECTIONS[world_input_dir][3]
--             local bx, by, bz = ox + dx, oy + dy, oz + dz
            
--             if bus_system.is_bus(bx, by, bz) then
--                 bus_value = bus_system.get_bus_value(bx, by, bz)
--                 bus_width = bus_system.get_bus_width(bx, by, bz)
--             end
--         end
        
--         -- Применение смещения адресных битов
--         local address_bit_offset = block.get_field(ox, oy, oz, "address_bit_offset") or 0
        
--         -- Извлечение нужных битов из шины
--         local address = math.floor(bus_value / (2 ^ address_bit_offset)) % (2 ^ RAM_ADDRESS_BITS)
        
--         return address
--     end
    
--     ---Получение данных для записи из входной шины
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@return integer data_value, integer bus_width
--     function ram_base.get_write_data_from_bus(ox, oy, oz)
--         local api_module = require("wire_mod:api")
--         local rotation = block.get_rotation(ox, oy, oz)
        
--         -- Получение конфигурации устройства для named входов
--         local config = api_module.complex_devices[block_name]
--         local input_entries = config and config.input_entries and config.input_entries[rotation]
        
--         local bus_value = 0
--         local bus_width = RAM_OUTPUT_BUS_WIDTH
        
--         if input_entries and input_entries["data_in"] then
--             -- Использование named входа через API
--             local entry = input_entries["data_in"]
--             local input_dir = entry.dir
--             local offset = entry.offset or 0
            
--             -- Вычисление позиции сегмента для этого входа
--             local block_id = block.get(ox, oy, oz)
--             local size_x, size_y, size_z = 1, 1, 1
--             if block_id ~= 0 then
--                 local success_size, sx, sy, sz = pcall(block.get_size, block_id)
--                 if success_size then
--                     size_x, size_y, size_z = sx, sy, sz
--                 end
--             end
            
--             local bx, by, bz = api_module.calculate_segment_position(
--                 ox, oy, oz, rotation, input_dir, offset,
--                 size_x, size_y, size_z
--             )
            
--             -- Получение значения с шины
--             if bus_system.is_bus(bx, by, bz) then
--                 bus_value = bus_system.get_bus_value(bx, by, bz)
--                 bus_width = bus_system.get_bus_width(bx, by, bz)
--             end
--         else
--             -- Fallback: старый способ (dir = 1, offset = 0)
--             local input_dir = 1
--             local world_input_dir = (input_dir + rotation) % 4
--             local dx, dy, dz = core.DIRECTIONS[world_input_dir][1], core.DIRECTIONS[world_input_dir][2], core.DIRECTIONS[world_input_dir][3]
--             local bx, by, bz = ox + dx, oy + dy, oz + dz
            
--             if bus_system.is_bus(bx, by, bz) then
--                 bus_value = bus_system.get_bus_value(bx, by, bz)
--                 bus_width = bus_system.get_bus_width(bx, by, bz)
--             end
--         end
        
--         return bus_value, bus_width
--     end
    
--     ---Получение сигнала записи (write enable) с провода
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@return boolean write_enable
--     function ram_base.get_write_enable(ox, oy, oz)
--         local rotation = block.get_rotation(ox, oy, oz)
        
--         -- Вход write_enable находится справа (dir = 3)
--         local input_dir = 3
--         local world_input_dir = (input_dir + rotation) % 4
        
--         local dx, dy, dz = core.DIRECTIONS[world_input_dir][1], core.DIRECTIONS[world_input_dir][2], core.DIRECTIONS[world_input_dir][3]
--         local bx, by, bz = ox + dx, oy + dy, oz + dz
        
--         -- Проверка, есть ли там провод
--         if core.is_wire(bx, by, bz) then
--             -- Получение сигнала с провода
--             return core.wire_has_signal(bx, by, bz)
--         end
        
--         return false
--     end
    
--     ---Получение тактового сигнала (clock) с провода
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@return boolean clock_signal
--     function ram_base.get_clock_signal(ox, oy, oz)
--         local api_module = require("wire_mod:api")
--         local rotation = block.get_rotation(ox, oy, oz)
        
--         -- Получение конфигурации устройства для named входов
--         local config = api_module.complex_devices[block_name]
--         local input_entries = config and config.input_entries and config.input_entries[rotation]
        
--         if input_entries and input_entries["clock"] then
--             -- Использование named входа через API
--             local entry = input_entries["clock"]
--             local input_dir = entry.dir
--             local offset = entry.offset or 0
            
--             -- Вычисление позиции сегмента для этого входа
--             local block_id = block.get(ox, oy, oz)
--             local size_x, size_y, size_z = 1, 1, 1
--             if block_id ~= 0 then
--                 local success_size, sx, sy, sz = pcall(block.get_size, block_id)
--                 if success_size then
--                     size_x, size_y, size_z = sx, sy, sz
--                 end
--             end
            
--             local bx, by, bz = api_module.calculate_segment_position(
--                 ox, oy, oz, rotation, input_dir, offset,
--                 size_x, size_y, size_z
--             )
            
--             -- Проверка, есть ли там провод
--             if core.is_wire(bx, by, bz) then
--                 return core.wire_has_signal(bx, by, bz)
--             end
--         else
--             -- Fallback: старый способ (dir = 0, offset = 1)
--             local input_dir = 0
--             local world_input_dir = (input_dir + rotation) % 4
--             local dx, dy, dz = core.DIRECTIONS[world_input_dir][1], core.DIRECTIONS[world_input_dir][2], core.DIRECTIONS[world_input_dir][3]
--             local bx, by, bz = ox + dx, oy + dy, oz + dz
            
--             if core.is_wire(bx, by, bz) then
--                 return core.wire_has_signal(bx, by, bz)
--             end
--         end
        
--         return false
--     end
    
--     ---Чтение данных из RAM и распространение на выходную шину
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@param address integer
--     function ram_base.read_and_propagate(ox, oy, oz, address)
--         -- Генерация RAM ID из координат блока
--         local ram_id = string.format("ram_%d_%d_%d", ox, oy, oz)
        
--         -- Чтение значения из RAM
--         local value = rom_storage.read_rom(ram_id, address)
        
--         if not value then
--             -- RAM не существует или ошибка чтения - использовать 0
--             value = 0
--         end
        
--         -- Ограничение значения диапазоном cell_bits
--         local max_value = (2 ^ RAM_CELL_BITS) - 1
--         value = math.min(math.max(0, value), max_value)
        
--         -- Сохранение последнего адреса и значения
--         local last_address = block.get_field(ox, oy, oz, "last_address") or -1
--         local last_value = block.get_field(ox, oy, oz, "output_value") or -1
        
--         if address ~= last_address or value ~= last_value then
--             block.set_field(ox, oy, oz, "last_address", address)
--             block.set_field(ox, oy, oz, "output_value", value)
            
--             -- Найти выходную шину и установить значение
--             local rotation = block.get_rotation(ox, oy, oz)
--             local output_dir = 2  -- dir 2 = front
--             local world_output_dir = (output_dir + rotation) % 4
            
--             local dx, dy, dz = core.DIRECTIONS[world_output_dir][1], core.DIRECTIONS[world_output_dir][2], core.DIRECTIONS[world_output_dir][3]
--             local bx, by, bz = ox + dx, oy + dy, oz + dz
            
--             -- Проверить, что там шина нужной ширины
--             if bus_system.is_bus(bx, by, bz) then
--                 local bus_width = bus_system.get_bus_width(bx, by, bz)
--                 -- Если шина не нужной ширины, попробуем установить ширину
--                 if bus_width ~= RAM_OUTPUT_BUS_WIDTH then
--                     -- Установить ширину шины, если возможно
--                     pcall(block.set_field, bx, by, bz, "bus_width", RAM_OUTPUT_BUS_WIDTH)
--                 end
--                 bus_system.propagate_bus_value(bx, by, bz, value)
--             end
--         end
--     end
    
--     ---Запись данных в RAM
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@param address integer
--     ---@param value integer
--     function ram_base.write_to_ram(ox, oy, oz, address, value)
--         -- Генерация RAM ID из координат блока
--         local ram_id = string.format("ram_%d_%d_%d", ox, oy, oz)
        
--         -- Ограничение значения диапазоном cell_bits
--         local max_value = (2 ^ RAM_CELL_BITS) - 1
--         value = math.min(math.max(0, value), max_value)
        
--         -- Запись в RAM
--         rom_storage.write_rom(ram_id, address, value)
--     end
    
--     ---Обработка обновления RAM (чтение/запись)
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     function ram_base.update_ram(ox, oy, oz)
--         -- Получение адреса
--         local address = ram_base.get_address_from_bus(ox, oy, oz)
        
--         -- Получение тактового сигнала
--         local clock_signal = ram_base.get_clock_signal(ox, oy, oz)
--         local last_clock = block.get_field(ox, oy, oz, "last_clock") or 0
        
--         -- Проверка сигнала записи
--         local write_enable = ram_base.get_write_enable(ox, oy, oz)
        
--         -- Определение фронта тактового сигнала (переход 0->1)
--         local clock_rising_edge = clock_signal and (last_clock == 0)
        
--         -- Сохранение текущего состояния clock (0 или 1)
--         block.set_field(ox, oy, oz, "last_clock", clock_signal and 1 or 0)
        
--         if write_enable and clock_rising_edge then
--             -- Режим записи: записать данные из входной шины только на фронте тактового сигнала
--             local write_data, _ = ram_base.get_write_data_from_bus(ox, oy, oz)
--             ram_base.write_to_ram(ox, oy, oz, address, write_data)
            
--             -- После записи сразу прочитать и вывести новое значение
--             ram_base.read_and_propagate(ox, oy, oz, address)
--         else
--             -- Режим чтения: просто прочитать и вывести (чтение происходит всегда)
--             ram_base.read_and_propagate(ox, oy, oz, address)
--         end
--     end
    
--     ---Обработчик события от шины
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param signal table
--     function ram_base.on_device_signal(x, y, z, signal)
--         -- Обрабатываем события от шин и проводов
--         if signal.device_type ~= "bus" and signal.device_type ~= "wire" then return end
        
--         local ox, oy, oz = block.seek_origin(x, y, z)
        
--         local id = block.get(ox, oy, oz)
--         if id == 0 then return end
        
--         local name = block.name(id)
--         if name ~= block_name then return end
        
--         -- Обновление RAM (чтение/запись)
--         ram_base.update_ram(ox, oy, oz)
--     end
    
--     ---Обработчик размещения блока
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param playerid integer
--     function ram_base.on_placed(x, y, z, playerid)
--         local ox, oy, oz = block.seek_origin(x, y, z)
        
--         -- Проверка существования RAM, если нет - создать
--         local ram_id = string.format("ram_%d_%d_%d", ox, oy, oz)
--         local data, metadata = rom_storage.load_rom(ram_id)
        
--         if not metadata then
--             -- Создание пустого массива данных
--             local new_data = {}
--             for i = 0, RAM_SIZE - 1 do
--                 new_data[i] = 0
--             end
            
--             -- Метаданные RAM
--             local new_metadata = {
--                 rom_id = ram_id,
--                 position = {x = ox, y = oy, z = oz},
--                 size = RAM_SIZE,
--                 cell_bits = RAM_CELL_BITS,
--                 address_bits = RAM_ADDRESS_BITS,
--                 created_at = os.time(),
--                 modified_at = os.time(),
--                 version = 1
--             }
            
--             -- Сохранение RAM
--             rom_storage.save_rom(ram_id, new_data, new_metadata)
--             print(string.format("[RAM %s] Created new RAM: %s", display_name, ram_id))
--         else
--             print(string.format("[RAM %s] Using existing RAM: %s", display_name, ram_id))
--         end
        
--         -- Инициализация полей
--         block.set_field(ox, oy, oz, "address_bit_offset", 0)
--         block.set_field(ox, oy, oz, "last_address", -1)
--         block.set_field(ox, oy, oz, "output_value", 0)
--         block.set_field(ox, oy, oz, "last_clock", 0)
        
--         -- Начальное чтение
--         ram_base.update_ram(ox, oy, oz)
--     end
    
--     ---Обработчик разрушения блока
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param playerid integer
--     function ram_base.on_broken(x, y, z, playerid)
--         -- Примечание: не удаляем RAM данные при разрушении блока
--         -- Данные остаются в файлах и могут быть использованы повторно
--     end
    
--     ---Показ информации о RAM
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@param playerid integer
--     function ram_base.show_ram_info(ox, oy, oz, playerid)
--         -- Получение RAM ID
--         local ram_id = string.format("ram_%d_%d_%d", ox, oy, oz)
        
--         -- Загрузка метаданных и данных RAM
--         local ram_data, metadata = rom_storage.load_rom(ram_id)
        
--         if not metadata then
--             gui.alert("RAM не инициализирован")
--             return
--         end
--     end
    
--     ---Обработчик взаимодействия с блоком
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param playerid integer
--     ---@return boolean
--     function ram_base.on_interact(x, y, z, playerid)
--         local ox, oy, oz = block.seek_origin(x, y, z)
        
--         -- Показать информацию о RAM
--         ram_base.show_ram_info(ox, oy, oz, playerid)
--         return true
--     end
    
--     ---Создание view для logic_viewer
--     ---@param logic_viewer_module table Модуль logic_viewer
--     function ram_base.setup_logic_viewer(logic_viewer_module)
--         logic_viewer_module.set_view(block_name, function(x, y, z)
--             local block_id = block.get(x, y, z)
--             if block_id == 0 then
--                 return nil
--             end
            
--             local ram_id = string.format("ram_%d_%d_%d", x, y, z)
--             local address_bit_offset = block.get_field(x, y, z, "address_bit_offset") or 0
--             local last_address = block.get_field(x, y, z, "last_address") or 0
            
--             -- Получение информации о шине адреса через API
--             local api_module = require("wire_mod:api")
--             local rotation = block.get_rotation(x, y, z)
--             local config = api_module.complex_devices[block_name]
--             local input_entries = config and config.input_entries and config.input_entries[rotation]
            
--             local address_value = 0
--             local address_width = DEFAULT_INPUT_BUS_WIDTH
            
--             if input_entries and input_entries["address_bus"] then
--                 local entry = input_entries["address_bus"]
--                 local input_dir = entry.dir
--                 local offset = entry.offset or 0
                
--                 local block_id = block.get(x, y, z)
--                 local size_x, size_y, size_z = 1, 1, 1
--                 if block_id ~= 0 then
--                     local success_size, sx, sy, sz = pcall(block.get_size, block_id)
--                     if success_size then
--                         size_x, size_y, size_z = sx, sy, sz
--                     end
--                 end
                
--                 local bx, by, bz = api_module.calculate_segment_position(
--                     x, y, z, rotation, input_dir, offset,
--                     size_x, size_y, size_z
--                 )
                
--                 if bus_system.is_bus(bx, by, bz) then
--                     address_value = bus_system.get_bus_value(bx, by, bz)
--                     address_width = bus_system.get_bus_width(bx, by, bz)
--                 end
--             else
--                 -- Fallback
--                 local address_dir = 0
--                 local world_address_dir = (address_dir + rotation) % 4
--                 local dx, dy, dz = core.DIRECTIONS[world_address_dir][1], core.DIRECTIONS[world_address_dir][2], core.DIRECTIONS[world_address_dir][3]
--                 local bx, by, bz = x + dx, y + dy, z + dz
--                 if bus_system.is_bus(bx, by, bz) then
--                     address_value = bus_system.get_bus_value(bx, by, bz)
--                     address_width = bus_system.get_bus_width(bx, by, bz)
--                 end
--             end
            
--             -- Применение смещения адресных битов для вычисления реального адреса
--             local real_address = math.floor(address_value / (2 ^ address_bit_offset)) % (2 ^ RAM_ADDRESS_BITS)
            
--             -- Получение информации о шине данных для записи через API
--             local write_data_value = 0
--             local write_data_width = RAM_OUTPUT_BUS_WIDTH
            
--             if input_entries and input_entries["data_in"] then
--                 local entry = input_entries["data_in"]
--                 local input_dir = entry.dir
--                 local offset = entry.offset or 0
                
--                 local block_id = block.get(x, y, z)
--                 local size_x, size_y, size_z = 1, 1, 1
--                 if block_id ~= 0 then
--                     local success_size, sx, sy, sz = pcall(block.get_size, block_id)
--                     if success_size then
--                         size_x, size_y, size_z = sx, sy, sz
--                     end
--                 end
                
--                 local bx, by, bz = api_module.calculate_segment_position(
--                     x, y, z, rotation, input_dir, offset,
--                     size_x, size_y, size_z
--                 )
                
--                 if bus_system.is_bus(bx, by, bz) then
--                     write_data_value = bus_system.get_bus_value(bx, by, bz)
--                     write_data_width = bus_system.get_bus_width(bx, by, bz)
--                 end
--             else
--                 -- Fallback
--                 local data_dir = 1
--                 local world_data_dir = (data_dir + rotation) % 4
--                 local dx, dy, dz = core.DIRECTIONS[world_data_dir][1], core.DIRECTIONS[world_data_dir][2], core.DIRECTIONS[world_data_dir][3]
--                 local bx, by, bz = x + dx, y + dy, z + dz
--                 if bus_system.is_bus(bx, by, bz) then
--                     write_data_value = bus_system.get_bus_value(bx, by, bz)
--                     write_data_width = bus_system.get_bus_width(bx, by, bz)
--                 end
--             end
            
--             -- Ограничение данных для записи
--             local max_write_value = (2 ^ RAM_CELL_BITS) - 1
--             write_data_value = math.min(math.max(0, write_data_value), max_write_value)
            
--             -- Получение сигнала записи
--             local write_enable_dir = 3
--             local world_write_enable_dir = (write_enable_dir + rotation) % 4
--             local dx, dy, dz = core.DIRECTIONS[world_write_enable_dir][1], core.DIRECTIONS[world_write_enable_dir][2], core.DIRECTIONS[world_write_enable_dir][3]
--             local bx, by, bz = x + dx, y + dy, z + dz
            
--             local write_enable = false
--             if core.is_wire(bx, by, bz) then
--                 write_enable = core.wire_has_signal(bx, by, bz)
--             end
            
--             -- Получение тактового сигнала через API
--             local clock_signal = false
--             if input_entries and input_entries["clock"] then
--                 local entry = input_entries["clock"]
--                 local input_dir = entry.dir
--                 local offset = entry.offset or 0
                
--                 local block_id = block.get(x, y, z)
--                 local size_x, size_y, size_z = 1, 1, 1
--                 if block_id ~= 0 then
--                     local success_size, sx, sy, sz = pcall(block.get_size, block_id)
--                     if success_size then
--                         size_x, size_y, size_z = sx, sy, sz
--                     end
--                 end
                
--                 local bx, by, bz = api_module.calculate_segment_position(
--                     x, y, z, rotation, input_dir, offset,
--                     size_x, size_y, size_z
--                 )
                
--                 if core.is_wire(bx, by, bz) then
--                     clock_signal = core.wire_has_signal(bx, by, bz)
--                 end
--             else
--                 -- Fallback
--                 local clock_dir = 0
--                 local world_clock_dir = (clock_dir + rotation) % 4
--                 local dx, dy, dz = core.DIRECTIONS[world_clock_dir][1], core.DIRECTIONS[world_clock_dir][2], core.DIRECTIONS[world_clock_dir][3]
--                 local bx, by, bz = x + dx, y + dy, z + dz
--                 if core.is_wire(bx, by, bz) then
--                     clock_signal = core.wire_has_signal(bx, by, bz)
--                 end
--             end
            
--             local last_clock = block.get_field(x, y, z, "last_clock") or 0
--             local clock_rising_edge = clock_signal and (last_clock == 0)
            
--             -- Загрузка данных RAM для отображения окрестности
--             local ram_data, metadata = rom_storage.load_rom(ram_id)
--             if not ram_data or not metadata then
--                 ram_data = {}
--                 for i = 0, RAM_SIZE - 1 do
--                     ram_data[i] = 0
--                 end
--             end
            
--             -- Чтение текущего значения из RAM
--             local ram_value = ram_data[real_address] or 0
            
--             -- Получение выходного значения
--             local output_value = block.get_field(x, y, z, "output_value") or 0
            
--             -- Подсчет статистики
--             local filled_cells = 0
--             local total_cells = RAM_SIZE
--             for i = 0, total_cells - 1 do
--                 if (ram_data[i] or 0) ~= 0 then
--                     filled_cells = filled_cells + 1
--                 end
--             end
--             local fill_percentage = math.floor((filled_cells / total_cells) * 100)
            
--             -- Формирование матрицы данных
--             -- Определяем размеры матрицы в зависимости от размера RAM
--             local cols = 16  -- Количество столбцов
--             if RAM_SIZE <= 16 then
--                 cols = 4  -- Для маленьких RAM используем 4 столбца
--             elseif RAM_SIZE <= 64 then
--                 cols = 8
--             end
--             local rows = math.ceil(RAM_SIZE / cols)
            
--             -- Формирование заголовка матрицы
--             local matrix_header = " "
--             for col = 0, cols - 1 do
--                 matrix_header = matrix_header .. string.format("    %X", col)
--             end
            
--             -- Формирование строк матрицы (каждая строка будет отдельной записью в settings)
--             local matrix_rows = {
--                 {name = "<spacer>"},
--                 {name = "МАТРИЦА ДАННЫХ", value = nil},
--                 {name = matrix_header, value = nil},
--             }
            
--             for row = 0, rows - 1 do
--                 local row_start = row * cols
--                 local row_label = string.format("%02X: ", row_start)
--                 local row_data = row_label
                
--                 for col = 0, cols - 1 do
--                     local addr = row_start + col
--                     if addr < RAM_SIZE then
--                         local value = ram_data[addr] or 0
--                         local marker = (addr == real_address) and "[" or " "
--                         local end_marker = (addr == real_address) and "]" or " "
--                         local hex_str = string.format("%02X", value)
--                         row_data = row_data .. string.format("%s%s%s ", marker, hex_str, end_marker)
--                     else
--                         row_data = row_data .. "    "  -- Пустое место для несуществующих ячеек
--                     end
--                 end
                
--                 table.insert(matrix_rows, {name = row_data, value = nil})
--             end
            
--             table.insert(matrix_rows, {name = "<spacer>"})
            
--             -- Форматирование значения в двоичном виде  
--             local binary_str = ""
--             local temp_value = ram_value
--             for i = RAM_CELL_BITS - 1, 0, -1 do
--                 local bit = math.floor(temp_value / (2 ^ i)) % 2
--                 binary_str = binary_str .. tostring(bit)
--             end
            
--             -- Форматирование данных для записи в двоичном виде
--             local write_binary_str = ""
--             local temp_write_value = write_data_value
--             for i = RAM_CELL_BITS - 1, 0, -1 do
--                 local bit = math.floor(temp_write_value / (2 ^ i)) % 2
--                 write_binary_str = write_binary_str .. tostring(bit)
--             end
            
--             return {
--                 display_name = display_name,
--                 inputs = {
--                     {name = "ADDRESS_BUS", value = address_value, bits = address_width},
--                     {name = "DATA_IN", value = write_data_value, bits = write_data_width},
--                     {name = "WRITE_EN", value = write_enable and 1 or 0, bits = 1},
--                     {name = "CLOCK", value = clock_signal and 1 or 0, bits = 1}
--                 },
--                 outputs = {
--                     {name = "DATA_OUT", value = output_value, bits = RAM_OUTPUT_BUS_WIDTH}
--                 },
--                 settings = (function()
--                     local settings_list = {
--                         {name = "<spacer>"},
--                         {name = "СТАТИСТИКА", value = string.format("%d/%d ячеек (%d%%)", filled_cells, total_cells, fill_percentage)},
--                         {name = "<spacer>"},
--                         {name = "Текущий адрес", value = string.format("0x%02X (%d)", real_address, real_address)},
--                         {name = "Значение [HEX]", value = string.format("0x%02X", ram_value)},
--                         {name = "Значение [DEC]", value = tostring(ram_value)},
--                         {name = "Значение [BIN]", value = binary_str},
--                         {name = "<spacer>"},
--                         {name = "Режим", value = write_enable and "ЗАПИСЬ" or "ЧТЕНИЕ"},
--                         {name = "CLOCK", value = clock_signal and "1" or "0"},
--                         {name = "CLOCK фронт", value = clock_rising_edge and "ДА" or "НЕТ"},
--                         {name = "Данные для записи", value = string.format("0x%02X (%d)", write_data_value, write_data_value)},
--                         {name = "Данные [BIN]", value = write_binary_str},
--                         {name = "<spacer>"},
--                         {name = "Смещение адреса", value = address_bit_offset .. " бит"}
--                     }
                    
--                     -- Добавляем строки матрицы
--                     for _, row in ipairs(matrix_rows) do
--                         table.insert(settings_list, row)
--                     end
                    
--                     return settings_list
--                 end)()
--             }
--         end)
--     end
    
--     return ram_base
-- end

-- return {
--     create_ram_handler = create_ram_handler
-- }

