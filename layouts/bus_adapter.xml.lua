local unpack = table.unpack or unpack
local settings=require('advanced_logic_2:adapter_settings')
local pos
function close()
    hud.close('advanced_logic_2:bus_adapter')
end
function on_open()
    pos=session.entries and session.entries.adapter_pos
    if not pos then close();return end
    document.current.text='Ширина выхода: '..settings.width(unpack(pos))..' бит'
end
function choose(width)
    if not pos then return end
    settings.set_width(pos[1],pos[2],pos[3],width)
    close()
end
