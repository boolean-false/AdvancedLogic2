-- Клиентская панель для каждого загруженного индикатора. Слоты текстур повторно используются после удаления.
local M={}
local api=require('wire_mod_2:api')
local font=require('advanced_logic_2:indicator_font')
local records,slots={},{}
local uploads=0
local unpack=table.unpack or unpack
local C={bg={16,24,30},text={232,244,238},accent={134,207,221},muted={121,139,151},line={44,60,70}}
local function key(x,y,z) return x..':'..y..':'..z end
local function rect(canvas,x,y,w,h,color)
    -- Координата V у Entity UV направлена противоположно порядку строк Canvas.
    canvas:rect(x,192-y-h,w,h,unpack(color))
end
local function text(canvas,value,y,scale,color,scale_y)
    scale_y=scale_y or scale
    local x=math.floor((128-(#value*4-1)*scale)/2)
    for i=1,#value do
        local glyph=font[value:sub(i,i)] or font[' ']
        local row=0
        for line in glyph:gmatch('[^/]+') do
            for col=1,#line do
                if line:sub(col,col)=='1' then
                    rect(canvas,x+((i-1)*4+col-1)*scale,y+row*scale_y,scale,scale_y,color)
                end
            end
            row=row+1
        end
    end
end
function M.draw(canvas,state)
    canvas:clear(unpack(C.bg))
    if state.mode==1 then
        local value=state.connected and string.format('%d',math.floor(state.value) % (2^state.bits)) or '-'
        local sx=math.min(32,math.floor(108/(#value*4-1)))
        local sy=math.min(32,sx*2)
        text(canvas,value,math.floor((192-5*sy)/2),sx,state.connected and C.text or C.muted,sy)
        canvas:update()
        uploads=uploads+1
        return
    end
    text(canvas,'SIGNAL',10,2,C.muted)
    rect(canvas,10,29,108,1,C.line)
    if state.connected then
        local bits=state.bits
        local value=math.floor(state.value) % (2^bits)
        text(canvas,tostring(bits)..' BIT',37,2,C.accent)
        text(canvas,string.format('%d',value),65,5,C.text)
        rect(canvas,10,103,108,1,C.line)
        text(canvas,'HEX',115,2,C.muted)
        text(canvas,string.format('%0'..math.ceil(bits/4)..'X',value),135,4,C.accent)
        -- Ячейки битов показывают физическую разрядность, поэтому мелкий двоичный текст не нужен.
        local pitch=math.floor(108/bits)
        local left=math.floor((128-bits*pitch)/2)
        for bit=0,bits-1 do
            local on=math.floor(value/2^(bits-1-bit))%2==1
            rect(canvas,left+bit*pitch,174,pitch-2,7,on and C.accent or C.line)
        end
    else
        text(canvas,'-',65,6,C.muted)
        text(canvas,'NO INPUT',119,2,C.muted)
        text(canvas,'1 4 8 16',165,2,C.line)
    end
    canvas:update()
    uploads=uploads+1
end
local function acquire()
    for _,slot in ipairs(slots) do
        if not slot.used then slot.used=true;return slot end
    end
    local name='al2_indicator_slot_'..(#slots+1)
    assets.load_texture(file.read_bytes('advanced_logic_2:assets/indicator_canvas.png'),name,'png')
    local slot={name=name,canvas=assert(assets.to_canvas(name)),used=true}
    slots[#slots+1]=slot
    return slot
end
function M.ensure(x,y,z)
    if not vc.is_client() then return end
    if block.get(x,y,z)<=0 then return end
    local ox,oy,oz=block.seek_origin(x,y,z)
    if ox~=x or oy~=y or oz~=z then return end
    local k=key(x,y,z)
    if not records[k] then records[k]={x=x,y=y,z=z} end
end
function M.remove(x,y,z)
    local k=key(x,y,z);local r=records[k]
    if not r then return end
    if r.uid and entities.exists(r.uid) then
        local panel=entities.get(r.uid)
        if panel then panel:despawn() end
    end
    if r.slot then r.slot.used=false end
    records[k]=nil
end
local function create(r)
    r.slot=acquire()
    local panel=entities.spawn('advanced_logic_2:indicator_screen',{r.x+.5,r.y+1.155,r.z+.5},{})
    r.uid=panel:get_uid()
    local a,b,c={block.get_X(r.x,r.y,r.z)},{block.get_Y(r.x,r.y,r.z)},{block.get_Z(r.x,r.y,r.z)}
    panel.transform:set_rot({a[1],a[2],a[3],0,b[1],b[2],b[3],0,c[1],c[2],c[3],0,0,0,0,1})
    panel.skeleton:set_texture('$screen',r.slot.name)
    r.rotation=block.get_rotation(r.x,r.y,r.z)
end
function M.tick()
    if not vc.is_client() then return end
    for _,r in pairs(records) do
        local id=block.get(r.x,r.y,r.z)
        if id<=0 or block.name(id)~='advanced_logic_2:indicator_4bit' then
            M.remove(r.x,r.y,r.z)
        else
            if r.uid and (not entities.exists(r.uid) or r.rotation~=block.get_rotation(r.x,r.y,r.z)) then
                M.remove(r.x,r.y,r.z);M.ensure(r.x,r.y,r.z)
            else
                if not r.uid then create(r) end
                local state=api.get_port_state('input',r.x,r.y,r.z)
                state.mode=block.get_field(r.x,r.y,r.z,'display_mode') or 0
                local signature=tostring(state.connected)..':'..tostring(state.bits)..':'..state.value..':'..state.mode
                if r.signature~=signature then
                    M.draw(r.slot.canvas,state);r.signature=signature
                end
            end
        end
    end
end
function M.stats()
    local active=0
    for _ in pairs(records) do active=active+1 end
    return {active=active,texture_slots=#slots,uploads=uploads}
end
function M.clear()
    for _,r in pairs(records) do M.remove(r.x,r.y,r.z) end
    for _,slot in ipairs(slots) do slot.canvas:unbind_texture() end
    slots={}
end
return M
