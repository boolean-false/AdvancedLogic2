-- 4-to-16 Decoder. One-hot: активен только один из 16 выходов (выбранный addr).
--
-- Размер блока: 4×4×1 (panel-style, ставится на стену).
--
-- Пины:
--   BACK  (dir=0, offset=0, offset_y=0, bits=4): addr
--   FRONT (dir=2): out_0..out_15
--
-- Layout выходов на FRONT (LSB снизу-слева, MSB сверху-справа):
--   row 3:  out_12 out_13 out_14 out_15
--   row 2:  out_8  out_9  out_10 out_11
--   row 1:  out_4  out_5  out_6  out_7
--   row 0:  out_0  out_1  out_2  out_3

local api = require('wire_mod_2:api')
local logic_viewer = require('wire_mod_2:logic_viewer')

-- Сгенерируем outputs программно для краткости.
local function make_outputs()
    local outs = {}
    for i = 0, 15 do
        local col = i % 4
        local row = math.floor(i / 4)
        outs["out_" .. i] = {dir = 2, offset = col, offset_y = row, bits = 1}
    end
    return outs
end

local device_id = api.register({"advanced_logic_2:decoder_4to16"}, {
    inputs  = { addr = {dir = 0, offset = 0, offset_y = 0, bits = 4} },
    outputs = make_outputs()
})

api.register_signal_handler(device_id, function(read, write)
    local sel = (read("addr") or 0) % 16
    for i = 0, 15 do
        write("out_" .. i, sel == i and 1 or 0)
    end
end)

function on_placed(x, y, z, _)
    api.on_placed(x, y, z, device_id)
end

function on_broken(x, y, z, _)
    api.on_broken(x, y, z, device_id)
end

logic_viewer.set_view(device_id, function(x, y, z)
    if block.get(x, y, z) == 0 then return nil end
    return {
        display_name = "4-to-16 Decoder",
        type = "gate",
        settings = {
            {name = "Один из 16 выходов = 1, остальные = 0"},
            {name = "Layout: row 0 = out_0..3 (LSB)"},
            {name = "        row 3 = out_12..15 (MSB)"},
        }
    }
end)
