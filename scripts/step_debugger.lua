--- Step Debugger item.
---
--- Управление:
---   ПКМ в воздух / по блоку       — toggle глобальной паузы clocks
---   Shift+ПКМ                      — ручной шаг (один tick всех clocks)
---                                    Работает только когда на паузе.

local clock_registry = require('advanced_logic_2:clock_registry')

local function shift_pressed()
    local ok1, p1 = pcall(input.is_pressed, "key:left-shift")
    local ok2, p2 = pcall(input.is_pressed, "key:right-shift")
    return (ok1 and p1) or (ok2 and p2)
end

local function announce(msg)
    print("[StepDbg] " .. msg)
end

local function handle_action()
    if shift_pressed() then
        if not clock_registry.is_paused() then
            announce("Сначала включи паузу (ПКМ без Shift)")
            return
        end
        clock_registry.request_step()
        announce("Step: 1 tick")
        return
    end

    local now_paused = clock_registry.toggle_paused()
    if now_paused then
        announce(string.format("PAUSED. Clocks: %d. Shift+ПКМ — шаг.", clock_registry.clock_count()))
    else
        announce(string.format("RUNNING. Clocks: %d.", clock_registry.clock_count()))
    end
end

function on_use(playerid)
    handle_action()
end

function on_use_on_block(x, y, z, playerid, normal)
    handle_action()
    return true  -- блокируем placing-block (его нет, но safe)
end
