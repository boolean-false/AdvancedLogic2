-- local bus_system = require("advanced_logic_2:bus_system")
-- local core = require("wire_mod:core")
-- local rom_storage = require("advanced_logic_2:rom_storage")

-- ---Создание обработчика ПЗУ с заданной конфигурацией
-- ---@param config table Конфигурация ПЗУ:
-- ---   - block_name: string - имя блока (например, "advanced_logic_2:rom_4bit")
-- ---   - display_name: string - отображаемое имя (например, "ПЗУ 4-бит")
-- ---   - rom_size: integer - размер ROM в ячейках
-- ---   - rom_cell_bits: integer - количество бит на ячейку
-- ---   - rom_address_bits: integer - количество бит адреса
-- ---   - rom_output_bus_width: integer - ширина выходной шины
-- ---   - default_input_bus_width: integer - ширина входной шины по умолчанию
-- ---@return table Модуль с функциями для использования в блоке
-- local function create_rom_handler(config)
--     local block_name = config.block_name
--     local display_name = config.display_name
--     local ROM_SIZE = config.rom_size
--     local ROM_CELL_BITS = config.rom_cell_bits
--     local ROM_ADDRESS_BITS = config.rom_address_bits
--     local ROM_OUTPUT_BUS_WIDTH = config.rom_output_bus_width
--     local DEFAULT_INPUT_BUS_WIDTH = config.default_input_bus_width or ROM_ADDRESS_BITS
    
--     local rom_base = {}
    
--     ---Получение адреса из входной шины с учетом смещения битов
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@return integer address
--     function rom_base.get_address_from_bus(ox, oy, oz)
--         local rotation = block.get_rotation(ox, oy, oz)
        
--         -- Вход address_bus находится сзади (dir = 0)
--         local input_dir = 0
--         local world_input_dir = (input_dir + rotation) % 4
        
--         local dx, dy, dz = core.DIRECTIONS[world_input_dir][1], core.DIRECTIONS[world_input_dir][2], core.DIRECTIONS[world_input_dir][3]
--         local bx, by, bz = ox + dx, oy + dy, oz + dz
        
--         -- Получение значения с шины
--         local bus_value = 0
--         local bus_width = DEFAULT_INPUT_BUS_WIDTH
        
--         if bus_system.is_bus(bx, by, bz) then
--             bus_value = bus_system.get_bus_value(bx, by, bz)
--             bus_width = bus_system.get_bus_width(bx, by, bz)
--         end
        
--         -- Применение смещения адресных битов
--         local address_bit_offset = block.get_field(ox, oy, oz, "address_bit_offset") or 0
        
--         -- Извлечение нужных битов из шины
--         local address = math.floor(bus_value / (2 ^ address_bit_offset)) % (2 ^ ROM_ADDRESS_BITS)
        
--         return address
--     end
    
--     ---Чтение данных из ROM и распространение на выходную шину
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@param address integer
--     function rom_base.read_and_propagate(ox, oy, oz, address)
--         -- Генерация ROM ID из координат блока
--         local rom_id = string.format("rom_%d_%d_%d", ox, oy, oz)
        
--         -- Чтение значения из ROM
--         local value = rom_storage.read_rom(rom_id, address)
        
--         if not value then
--             -- ROM не существует или ошибка чтения - использовать 0
--             value = 0
--         end
        
--         -- Ограничение значения диапазоном cell_bits
--         local max_value = (2 ^ ROM_CELL_BITS) - 1
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
--                 if bus_width ~= ROM_OUTPUT_BUS_WIDTH then
--                     -- Установить ширину шины, если возможно
--                     pcall(block.set_field, bx, by, bz, "bus_width", ROM_OUTPUT_BUS_WIDTH)
--                 end
--                 bus_system.propagate_bus_value(bx, by, bz, value)
--             end
--         end
--     end
    
--     ---Обработчик события от шины
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param signal table
--     function rom_base.on_device_signal(x, y, z, signal)
--         -- Обрабатываем только события от шин
--         if signal.device_type ~= "bus" then return end
        
--         local ox, oy, oz = block.seek_origin(x, y, z)
        
--         local id = block.get(ox, oy, oz)
--         if id == 0 then return end
        
--         local name = block.name(id)
--         if name ~= block_name then return end
        
--         -- Получение адреса из шины
--         local address = rom_base.get_address_from_bus(ox, oy, oz)
        
--         -- Чтение и распространение данных
--         rom_base.read_and_propagate(ox, oy, oz, address)
--     end
    
--     ---Обработчик размещения блока
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param playerid integer
--     function rom_base.on_placed(x, y, z, playerid)
--         local ox, oy, oz = block.seek_origin(x, y, z)
        
--         -- Проверка существования ROM, если нет - создать
--         local rom_id = rom_storage.get_rom_id_by_position(ox, oy, oz)
        
--         if not rom_id then
--             rom_id = rom_storage.create_rom(ox, oy, oz, ROM_SIZE, ROM_CELL_BITS)
--             print(string.format("[ROM %s] Created new ROM: %s", display_name, rom_id))
--         else
--             print(string.format("[ROM %s] Using existing ROM: %s", display_name, rom_id))
--         end
        
--         -- Инициализация полей
--         block.set_field(ox, oy, oz, "address_bit_offset", 0)
--         block.set_field(ox, oy, oz, "last_address", -1)
--         block.set_field(ox, oy, oz, "output_value", 0)
        
--         -- Начальное чтение
--         local address = rom_base.get_address_from_bus(ox, oy, oz)
--         rom_base.read_and_propagate(ox, oy, oz, address)
--     end
    
--     ---Обработчик разрушения блока
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param playerid integer
--     function rom_base.on_broken(x, y, z, playerid)
--         -- Примечание: не удаляем ROM данные при разрушении блока
--         -- Данные остаются в файлах и могут быть использованы повторно
--         -- Для удаления ROM данных используйте специальный инструмент
--     end
    
--     ---Показ информации о ROM
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     ---@param playerid integer
--     function rom_base.show_rom_info(ox, oy, oz, playerid)
--         -- Получение ROM ID
--         local rom_id = rom_storage.get_rom_id_by_position(ox, oy, oz)
        
--         if not rom_id then
--             gui.alert("ROM не найден")
--             return
--         end
        
--         -- Загрузка метаданных и данных ROM
--         local rom_data, metadata = rom_storage.load_rom(rom_id)
        
--         if not metadata then
--             gui.alert("ROM не инициализирован")
--             return
--         end
--     end
    
--     ---Открытие UI программатора для ROM
--     ---@param ox integer
--     ---@param oy integer
--     ---@param oz integer
--     function rom_base.open_rom_programmer(ox, oy, oz)
--         -- Получение ROM ID
--         local rom_id = rom_storage.get_rom_id_by_position(ox, oy, oz)
        
--         -- Загрузка метаданных ROM для определения битности
--         local _, metadata = rom_storage.load_rom(rom_id)
        
--         if not metadata then
--             -- Если ROM не существует, создать новый
--             rom_id = rom_storage.create_rom(ox, oy, oz, ROM_SIZE, ROM_CELL_BITS)
--             _, metadata = rom_storage.load_rom(rom_id)
--         end
        
--         -- Определение битности адреса и выхода
--         local address_bits = metadata.address_bits or ROM_ADDRESS_BITS
--         local cell_bits = metadata.cell_bits or ROM_CELL_BITS

--         -- Сохранение позиции ROM блока в сессии для GUI
--         if not session.entries then
--             session.entries = {}
--         end
--         session.entries["rom_programmer_pos"] = {ox, oy, oz}
--         session.entries["rom_address_bits"] = address_bits
--         session.entries["rom_cell_bits"] = cell_bits
        
--         -- Открыть GUI программатора
--         hud.show_overlay("advanced_logic_2:rom_programmer", false, {ox, oy, oz})
--     end
    
--     ---Обработчик взаимодействия с блоком
--     ---@param x integer
--     ---@param y integer
--     ---@param z integer
--     ---@param playerid integer
--     ---@return boolean
--     function rom_base.on_interact(x, y, z, playerid)
--         local ox, oy, oz = block.seek_origin(x, y, z)
        
--         -- Проверить, есть ли у игрока logic_configurator в руках
--         local invid, slot = player.get_inventory(playerid)
--         if invid and invid ~= 0 then
--             local itemid, count = inventory.get(invid, slot)
--             if itemid ~= 0 then
--                 local item_name = item.name(itemid)
--                 if item_name == "wire_mod:logic_configurator" then
--                     -- Открыть UI программатора
--                     rom_base.open_rom_programmer(ox, oy, oz)
--                     return true
--                 end
--             end
--         end
        
--         -- Если нет configurator, показать информацию о ROM
--         rom_base.show_rom_info(ox, oy, oz, playerid)
--         return true
--     end
    
--     ---Создание view для logic_viewer
--     ---@param logic_viewer_module table Модуль logic_viewer
--     function rom_base.setup_logic_viewer(logic_viewer_module)
--         logic_viewer_module.set_view(block_name, function(x, y, z)
--             local block_id = block.get(x, y, z)
--             if block_id == 0 then
--                 return nil
--             end
            
--             local rom_id = string.format("rom_%d_%d_%d", x, y, z)
--             local address_bit_offset = block.get_field(x, y, z, "address_bit_offset") or 0
--             local last_address = block.get_field(x, y, z, "last_address") or 0
            
--             -- Получение информации о шине
--             local rotation = block.get_rotation(x, y, z)
--             local input_dir = 0
--             local world_input_dir = (input_dir + rotation) % 4
--             local dx, dy, dz = core.DIRECTIONS[world_input_dir][1], core.DIRECTIONS[world_input_dir][2], core.DIRECTIONS[world_input_dir][3]
--             local bx, by, bz = x + dx, y + dy, z + dz
            
--             local bus_value = 0
--             local bus_width = DEFAULT_INPUT_BUS_WIDTH
--             if bus_system.is_bus(bx, by, bz) then
--                 bus_value = bus_system.get_bus_value(bx, by, bz)
--                 bus_width = bus_system.get_bus_width(bx, by, bz)
--             end
            
--             -- Чтение текущего значения из ROM
--             local rom_value = rom_storage.read_rom(rom_id, last_address) or 0
            
--             -- Получение выходного значения
--             local output_value = block.get_field(x, y, z, "output_value") or 0
            
--             return {
--                 display_name = display_name,
--                 inputs = {
--                     {name = "ADDRESS_BUS", value = bus_value, bits = bus_width}
--                 },
--                 outputs = {
--                     {name = "DATA_BUS", value = output_value, bits = ROM_OUTPUT_BUS_WIDTH}
--                 },
--                 settings = {
--                     {name = "ROM ID", value = string.sub(rom_id, 1, 20)},
--                     {name = "Смещение адреса", value = address_bit_offset .. " бит"},
--                     {name = "Текущий адрес", value = string.format("0x%X (%d)", last_address, last_address)},
--                     {name = "Значение", value = string.format("0x%X (%d)", rom_value, rom_value)}
--                 }
--             }
--         end)
--     end
    
--     return rom_base
-- end

-- return {
--     create_rom_handler = create_rom_handler
-- }

