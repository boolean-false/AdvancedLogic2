-- Один планировщик с отдельным сохраняемым состоянием паузы для каждого генератора.
local M={}
local devices=require('wire_mod:device_system')
local api=require('wire_mod:api')
local clocks={}
local function key(x,y,z)return x..':'..y..':'..z end
function M.register(x,y,z,device_id)
    local k=key(x,y,z)
    if not clocks[k] then clocks[k]={x=x,y=y,z=z,device_id=device_id,pending=0} end
end
function M.unregister(x,y,z)clocks[key(x,y,z)]=nil end
function M.is_paused(x,y,z)return (block.get_field(x,y,z,'paused') or 0)~=0 end
function M.set_paused(x,y,z,paused)
    local r=clocks[key(x,y,z)]
    if not r then return false end
    r.pending=0
    block.set_field(x,y,z,'paused',paused and 1 or 0)
    if not paused then
        local period=(block.get_field(x,y,z,'output') or 0)==1 and 'pulse_time' or 'delay_time'
        block.set_field(x,y,z,'next_toggle',time.uptime()+(block.get_field(x,y,z,period) or .5))
    end
    return true
end
-- Полный импульс 0 -> 1 -> 0 за два такта мира. Этот генератор должен оставаться на паузе.
function M.request_cycle(x,y,z)
    local r=clocks[key(x,y,z)]
    if not r or not M.is_paused(x,y,z) or r.pending>0 then return false end
    if (block.get_field(x,y,z,'output') or 0)~=0 then
        block.set_field(x,y,z,'output',0)
        api.send_signal(x,y,z,0)
    end
    r.pending=2
    return true
end
function M.clock_count()
    local n=0;for _ in pairs(clocks) do n=n+1 end;return n
end
function M.tick(process_clock)
    local keys={};for k in pairs(clocks) do keys[#keys+1]=k end
    table.sort(keys)
    for _,k in ipairs(keys) do
        local r=clocks[k]
        if r and block.get(r.x,r.y,r.z)>=0 then
            local config=devices.get_device_config_by_position(r.x,r.y,r.z)
            if not config or (r.device_id and config.device_id~=r.device_id) then clocks[k]=nil
            elseif r.pending>0 or not M.is_paused(r.x,r.y,r.z) then
                local forced=r.pending>0
                if forced then r.pending=r.pending-1 end
                local ok,err=pcall(process_clock,r.x,r.y,r.z,forced)
                if not ok then print('[clock_registry] '..k..': '..tostring(err)) end
            end
        end
    end
end
return M
