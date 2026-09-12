local ui=require('wire_mod:ui')
local mem=require('advanced_logic:memory_common')
local transfer=require('advanced_logic:memory_transfer')
local api=require('wire_mod:api')
local LAYOUT_ID='advanced_logic:memory_editor'
local bx,by,bz,is_rom,bits,cells,radix
local clear_until,reload_until=0,0
local clear_range
local function feedback(text)document.feedback.text=text end
local function valid()
 if not ui.valid(bx,by,bz,is_rom and 'advanced_logic:rom' or 'advanced_logic:ram') then
  hud.close(LAYOUT_ID);return false
 end
 return true
end
local function headers()
 document.mem_title.text=string.format('%s / %d слов / %d бит / адреса HEX',is_rom and 'ROM' or 'RAM',cells,bits)
 document.btn_addr.value=tostring(cells);document.btn_data.value=tostring(bits)
 document.radix.value=tostring(radix)
end
local function range()
 local parsed,err=transfer.parse(document.range_start.text,8,16,1)
 local first=parsed and parsed[1]
 if not first or first>=cells then feedback('Начало (HEX): '..(err or string.format('допустимо 00..%02X',cells-1)));return end
 local count,err=ui.number(document.range_count.text,1,cells-first,true)
 if not count then feedback('Длина: '..err);return end
 return first,count
end
function select_row(first)
 document.range_start.text=string.format('0x%02X',first)
 document.range_count.text=tostring(math.min(8,cells-first))
 feedback(string.format('Диапазон %02X..%02X',first,math.min(first+7,cells-1)))
end
local function read_draft()
 local values={}
 for i=0,cells-1 do
  local parsed,err=transfer.parse(document['cell_'..i].text,bits,radix,1)
  if not parsed then feedback(string.format('Адрес %02X: %s',i,err));return end
  values[i+1]=parsed[1]
 end
 return values
end
local function build(values)
 local grid=document.mem_grid;grid:clear()
 for first=0,cells-1,8 do
  local row='<panel size="712,28" orientation="horizontal" interval="4" color="0">'
  row=row..'<button size="64,28" onclick="select_row('..first..')">'..string.format('%02X',first)..'</button>'
  for i=first,math.min(first+7,cells-1) do
   row=row..string.format('<textbox id="cell_%d" size="76,28" editable="%s" color="#12171DFF" text-color="#E8E6DFFF"/>',i,is_rom and 'true' or 'false')
  end
  grid:add(row..'</panel>')
 end
 for i=0,cells-1 do
  local value=values and values[i+1] or mem.clamp_value(mem.read_cell(bx,by,bz,i),bits)
  document['cell_'..i].text=transfer.format(value,bits,radix)
 end
end
function on_mem_apply()
 if not valid() then return false end
 if not is_rom then return true end
 local values=read_draft();if not values then return false end
 for i=0,cells-1 do
  if values[i+1]~=mem.clamp_value(mem.read_cell(bx,by,bz,i),bits) then
   mem.write_cell(bx,by,bz,values[i+1],i)
  end
 end
 api.mark_device_for_update(bx,by,bz);feedback('Записано в ROM');return true
end
function export_range()
 if not valid() then return end
 local first,count=range();if not first then return end
 local selected={}
 for i=first,first+count-1 do
  local values,err=transfer.parse(document['cell_'..i].text,bits,radix,1)
  if not values then feedback(string.format('Адрес %02X: %s',i,err));return end
  selected[#selected+1]=values[1]
 end
 document.exchange.text=transfer.export(selected,bits,radix)
 document.exchange.focused=true
 feedback('В поле обмена: Ctrl+A, Ctrl+C для копирования')
end
function import_range()
 if not is_rom or not valid() then return end
 local first,count=range();if not first then return end
 local values,err=transfer.parse(document.exchange.text,bits,radix,count)
 if not values then feedback(err);return false end
 for i,value in ipairs(values) do document['cell_'..(first+i-1)].text=transfer.format(value,bits,radix) end
 feedback(string.format('Вставлено %d слов с адреса %02X. Нажмите "Записать".',#values,first))
 return true
end
function on_mem_clear()
 if not is_rom or not valid() then return end
 local first,count=range();if not first then return end
 local signature=first..':'..count
 if clear_until==0 or time.uptime()>clear_until or clear_range~=signature then
  clear_range=signature;clear_until=time.uptime()+4;feedback('Повторите очистку за 4 с. Изменяется только черновик диапазона.');return
 end
 clear_until=0
 for i=first,first+count-1 do document['cell_'..i].text=transfer.format(0,bits,radix) end
 feedback('Диапазон обнулен в черновике. Нажмите "Записать".')
end
function refresh_all()
 if not valid() then return end
 -- Явная перезагрузка отменяет черновик ROM только после второго нажатия.
 if is_rom then
  local values=read_draft();local dirty=not values
  if values then for i=0,cells-1 do if values[i+1]~=mem.clamp_value(mem.read_cell(bx,by,bz,i),bits) then dirty=true end end end
  if dirty and (reload_until==0 or time.uptime()>reload_until) then
   reload_until=time.uptime()+4;feedback('Есть правки. Повторите "Перечитать" за 4 с, чтобы отменить их.');return
  end
 end
 clear_until=0;reload_until=0;build();feedback('Перечитано из памяти')
end
function set_radix(value)
 local n=tonumber(value);if (n~=10 and n~=16) or n==radix then return end
 local values=read_draft();if not values then headers();return end
 radix=n;headers();build(values);document.exchange.text=''
 feedback('Изменен только формат отображения')
end
function set_capacity(value)
 local n=tonumber(value);if (n~=16 and n~=64) or n==cells then return end
 if not valid() or not on_mem_apply() then headers();return end
 mem.set_cells(bx,by,bz,n);cells=n;headers();build()
 document.range_start.text='0x00';document.range_count.text=tostring(cells)
 api.refresh_device(bx,by,bz)
end
function set_data_width(value)
 local n=tonumber(value);if (n~=4 and n~=8 and n~=16) or n==bits then return end
 if not valid() or not on_mem_apply() then headers();return end
 bits=n;block.set_field(bx,by,bz,'data_bits',bits);headers();build();api.refresh_device(bx,by,bz)
end
function on_mem_close()hud.close(LAYOUT_ID)end
function on_open()
 local entries=session.entries or {};local pos=entries.mem_editor_pos
 if not pos then on_mem_close();return end
 bx,by,bz=pos[1],pos[2],pos[3];is_rom=entries.mem_editor_is_rom or false
 if not valid() then return end
 cells=mem.get_cells(bx,by,bz);bits=mem.get_data_bits(bx,by,bz);radix=16;clear_until=0;reload_until=0
 headers();build()
 document.range_start.text='0x00';document.range_count.text=tostring(cells)
 document.exchange.text=''
 document.mem_apply.enabled=is_rom;document.mem_clear.enabled=is_rom;document.import_btn.enabled=is_rom
 feedback(is_rom and 'HEX: одно поле = одно слово. Правки записываются кнопкой "Записать".' or 'RAM: снимок для чтения и копирования. Запись выполняет схема.')
end
