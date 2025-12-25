local api = require('wire_mod_2:api')

local block_x, block_y, block_z = 0, 0, 0

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
    -- Validate and parse input
    local pulse_text = document.pulse_time.text
    local delay_text = document.delay_time.text
    
    local pulse_time = tonumber(pulse_text)
    local delay_time = tonumber(delay_text)
    
    if not pulse_time or pulse_time <= 0 or pulse_time > 60 then
        gui.alert("Pulse time must be between 0.01 and 60 seconds")
        return
    end
    
    if not delay_time or delay_time <= 0 or delay_time > 60 then
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
            -- Currently on, next toggle after delay_time
            block.set_field(block_x, block_y, block_z, "next_toggle", uptime + delay_time)
        else
            -- Currently off, next toggle after pulse_time
            block.set_field(block_x, block_y, block_z, "next_toggle", uptime + pulse_time)
        end
    end
    
    close_gui()
end

function close_gui()
    hud.close("advanced_logic_2:clock_generator")
end

