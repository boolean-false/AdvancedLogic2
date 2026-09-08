local clocks = require('advanced_logic_2:clock_registry')

local block_x, block_y, block_z = 0, 0, 0

local function valid_target()
    local id=block.get(block_x,block_y,block_z)
    if id<=0 then close_gui();return false end
    local name=block.name(id)
    if name~='advanced_logic_2:clock_generator' and name~='advanced_logic_2:clock_generator_mounted'
        and name~='advanced_logic_2:clock_generator_ceiling' then close_gui();return false end
    return true
end
local function refresh_status()
    document.run_status.text=clocks.is_paused(block_x,block_y,block_z) and 'Пауза этого генератора' or 'Этот генератор работает'
end
function start_clock()
    if not valid_target() then return end
    clocks.set_paused(block_x,block_y,block_z,false);refresh_status()
end
function pause_clock()
    if not valid_target() then return end
    clocks.set_paused(block_x,block_y,block_z,true);refresh_status()
end
function cycle_clock()
    if not valid_target() then return end
    if not clocks.request_cycle(block_x,block_y,block_z) then
        gui.alert('Включите паузу и дождитесь завершения предыдущего такта.')
    end
    refresh_status()
end

function on_open(...)
    -- Get block position from args (passed to hud.show_overlay)
    local args = {...}
    
    -- Try session first (set in on_interact)
    if session.entries and session.entries["clock_generator_pos"] then
        local pos = session.entries["clock_generator_pos"]
        block_x = pos[1]
        block_y = pos[2]
        block_z = pos[3]
    elseif args and #args >= 3 then
        -- Use args if available
        block_x = args[1]
        block_y = args[2]
        block_z = args[3]
    else
        -- If no position found, close GUI
        gui.alert("Error: Block position not found")
        close_gui()
        return
    end
    
    if not valid_target() then return end
    refresh_status()
    -- Load current settings from block
    local pulse_time = block.get_field(block_x, block_y, block_z, "pulse_time")
    local delay_time = block.get_field(block_x, block_y, block_z, "delay_time")
    
    -- Set default values if not set
    if not pulse_time or pulse_time == 0 then
        pulse_time = 0.5
    end
    if not delay_time or delay_time == 0 then
        delay_time = 0.5
    end
    
    -- Update textboxes with formatted values (2 decimal places)
    document.pulse_time.text = string.format("%.2f", pulse_time)
    document.delay_time.text = string.format("%.2f", delay_time)
    
end

function apply_settings()
    if not valid_target() then return end
    -- Validate and parse input
    local pulse_text = document.pulse_time.text
    local delay_text = document.delay_time.text
    
    local pulse_time = tonumber(pulse_text)
    local delay_time = tonumber(delay_text)
    
    if not pulse_time or pulse_time < 0.01 or pulse_time > 60 then
        gui.alert("Pulse time must be between 0.01 and 60 seconds")
        return
    end
    
    if not delay_time or delay_time < 0.01 or delay_time > 60 then
        gui.alert("Delay time must be between 0.01 and 60 seconds")
        return
    end
    
    -- Save to block fields
    block.set_field(block_x, block_y, block_z, "pulse_time", pulse_time)
    block.set_field(block_x, block_y, block_z, "delay_time", delay_time)
    
    -- Update next toggle time based on current output state
    local success, uptime = pcall(time.uptime)
    if success and uptime then
        local current_output = block.get_field(block_x, block_y, block_z, "output") or 0
        if current_output == 1 then
            -- HIGH длится pulse_time.
            block.set_field(block_x, block_y, block_z, "next_toggle", uptime + pulse_time)
        else
            -- LOW длится delay_time.
            block.set_field(block_x, block_y, block_z, "next_toggle", uptime + delay_time)
        end
    end
    
    close_gui()
end

function close_gui()
    hud.close("advanced_logic_2:clock_generator")
end
