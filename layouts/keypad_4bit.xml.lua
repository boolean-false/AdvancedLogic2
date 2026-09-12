--- Интерфейс клавиатуры: 4x4 hex кнопок. На клик - пишет value+strobe в полях блока,
--- mark_device_for_update запускает пересчёт симуляции.

local api          = require("wire_mod:api")
local simulation   = require("wire_mod:simulation")

local LAYOUT_ID       = "advanced_logic:keypad_4bit"
local STROBE_DURATION = 0.15

local bx, by, bz

local function uptime_safe()
    local ok, t = pcall(time.uptime)
    if ok and t then return t end
    return 0
end

function on_open(...)
    local args = {...}
    if session.entries and session.entries["keypad_pos"] then
        local pos = session.entries["keypad_pos"]
        bx, by, bz = pos[1], pos[2], pos[3]
    elseif args and #args >= 3 then
        bx, by, bz = args[1], args[2], args[3]
    else
        hud.close(LAYOUT_ID)
        return
    end
    document.last_pressed.text=string.format("Выход: %d / 0x%X",block.get_field(bx,by,bz,"value") or 0,block.get_field(bx,by,bz,"value") or 0)
end

function on_close(invid)
end

function press_key(value)
    if not require('wire_mod:ui').valid(bx,by,bz,'advanced_logic:keypad_4bit') then close_keypad();return end
    block.set_field(bx, by, bz, "value",        value % 16)
    block.set_field(bx, by, bz, "strobe_until", uptime_safe() + STROBE_DURATION)

    local lbl = document["last_pressed"]
    if lbl then lbl.text = string.format("Выход: 0x%X / %d", value % 16, value % 16) end

    -- Триггерим evaluate -> выходы обновятся
    simulation.mark_device_for_update(bx, by, bz)
end

function close_keypad()
    hud.close(LAYOUT_ID)
end
