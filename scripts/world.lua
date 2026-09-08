--- World script для advanced_logic_2.
--- Драйвит clock_registry - один tick callback на все clock_generator блоки.

local clock_registry = require('advanced_logic_2:clock_registry')
local clock_engine   = require('advanced_logic_2:clock_engine')

local indicator_display=require('advanced_logic_2:indicator_display')

function on_world_tick()
    indicator_display.tick()
    clock_registry.tick(clock_engine.process_one)
end

function on_world_quit()
    indicator_display.clear()
end
