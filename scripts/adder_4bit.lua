-- 4-битный сумматор с переносом
--
-- Порты:
--   A    (BACK,  dir=0, bits=4) — первый операнд
--   B    (LEFT,  dir=3, bits=4) — второй операнд
--   CIN  (RIGHT, dir=1, bits=1) — входной перенос (carry in)
--   SUM  (FRONT, dir=2, bits=4) — сумма (4 бита, биты 3:0)
--
-- COUT (бит 4 результата) отображается в Logic Viewer, но нет отдельного порта.
-- Для вычитания: B = NOT(B) + 1 (дополнение до двух).

local api          = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

local device_id = api.register({"advanced_logic_2:adder_4bit"}, {
    inputs = {
        a   = {dir = 0, offset = 0, bits = 4},
        b   = {dir = 3, offset = 0, bits = 4},
        cin = {dir = 1, offset = 0, bits = 1},
    },
    outputs = {
        sum = {dir = 2, offset = 0, bits = 4}
    }
})

api.register_signal_handler(device_id, function(read, write, inputs, outputs, origin)
    local x, y, z = origin[1], origin[2], origin[3]

    local a   = read("a")   or 0
    local b   = read("b")   or 0
    local cin = read("cin") or 0

    local result = (a % 16) + (b % 16) + (cin ~= 0 and 1 or 0)
    local sum    = result % 16
    local cout   = math.floor(result / 16)

    -- Сохраняем COUT для Logic Viewer
    block.set_field(x, y, z, "cout", cout)

    write("sum", sum)
end)

function on_placed(x, y, z, _)
    block.set_field(x, y, z, "cout", 0)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    local cout = block.get_field(x, y, z, "cout") or 0
    return {
        display_name = "4-bit Adder",
        type = "gate",
        -- inputs/outputs auto-filled (A, B, CIN, SUM с реальными значениями)
        settings = {
            {name = "COUT", value = tostring(cout),
             color = cout ~= 0 and "#FF8800" or "#AAAAAA"},
        }
    }
end)
