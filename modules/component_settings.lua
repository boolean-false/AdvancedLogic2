-- Минимальная панель настроек; оформление можно менять независимо.
local M={}
local api=require('wire_mod_2:api')
local function base_name(name)return name:gsub('_mounted$',''):gsub('_ceiling$','') end
local function options(field,title,values,labels)
 local out={field=field,title=title,values=values,labels=labels or {}}
 return out
end
function M.specs(name)
 name=base_name(name)
 if name=='advanced_logic_2:pulse_generator' then
  return {options('pulse_duration','Длительность, секунды',{0.05,0.1,0.25,0.5,1})}
 end
 if name=='advanced_logic_2:bus_splitter_4bit' then
  return {options('group','Диапазон битов',{0,1,2,3},{'0..3','4..7','8..11','12..15'})}
 end
 if name=='advanced_logic_2:bus_slice' or name=='advanced_logic_2:bus_join' then
  return {options('part_bits','Ширина каждой части',{4,8},{'4 + 4','8 + 8'})}
 end
 local width=options('data_bits','Ширина данных',{1,4,8,16})
 if name=='advanced_logic_2:bus_bit_reader_4bit' or name=='advanced_logic_2:bus_bit_writer_4bit' then
  local bits={};for i=0,15 do bits[#bits+1]=i end
  local index=options('selected_bit','Номер бита (0 - младший)',bits)
  if name=='advanced_logic_2:bus_bit_reader_4bit' then return {index} end
  return {width,index}
 end
 if name=='advanced_logic_2:bus_logic' then
  return {width,options('operation','Операция',{0,1,2,3},{'AND','OR','XOR','NOT'})}
 end
 return {width}
end
function M.open(x,y,z,playerid)
 if not require('advanced_logic_2:configurator_check').can_open_ui(playerid) then return false end
 x,y,z=block.seek_origin(x,y,z)
 session.entries=session.entries or {}
 session.entries.component_settings={x,y,z,base_name(block.name(block.get(x,y,z)))}
 hud.show_overlay('advanced_logic_2:component_settings',false)
 return true
end
function M.apply(target,field,value)
 local x,y,z=target[1],target[2],target[3]
 local id=block.get(x,y,z)
 if id<=0 or base_name(block.name(id))~=target[4] then return false end
 local valid=false
 for _,spec in ipairs(M.specs(target[4])) do
  if spec.field==field then for _,candidate in ipairs(spec.values) do if value==candidate then valid=true end end end
 end
 if not valid then return false end
 block.set_field(x,y,z,field,value)
 if field=='part_bits' then block.set_field(x,y,z,'data_bits',value*2) end
 api.refresh_device(x,y,z)
 return true
end
return M
