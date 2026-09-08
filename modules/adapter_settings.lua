local M={}
function M.valid_width(width)
    return width==1 or width==4 or width==8 or width==16
end
function M.width(x,y,z)
    local width=block.get_field(x,y,z,'data_bits')
    return M.valid_width(width) and width or 4
end
function M.set_width(x,y,z,width)
    if not M.valid_width(width) then return false end
    local id=block.get(x,y,z)
    if id<=0 then return false end
    local name=block.name(id)
    if name~='advanced_logic_2:bus_adapter' and name~='advanced_logic_2:bus_adapter_mounted'
        and name~='advanced_logic_2:bus_adapter_ceiling' then return false end
    block.set_field(x,y,z,'data_bits',width)
    require('wire_mod_2:api').refresh_device(x,y,z)
    return true
end
return M
