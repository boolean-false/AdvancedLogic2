local unpack = table.unpack or unpack
local settings=require('advanced_logic_2:adapter_settings')
local pos
function close()
    hud.close('advanced_logic_2:bus_adapter')
end
function on_open()
    pos=session.entries and session.entries.adapter_pos
    if not pos then close();return end
    local width=settings.width(unpack(pos))
    document.current.text='Ширина выхода: '..width..' бит'
    for _,n in ipairs({1,4,8,16}) do document['width_'..n].text=(n==width and '[x] ' or '')..n..' бит' end
end
function choose(width)
    if not pos then return end
    settings.set_width(pos[1],pos[2],pos[3],width)
    on_open()
end
