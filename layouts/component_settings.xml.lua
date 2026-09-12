local settings=require('advanced_logic:component_settings')
local ui=require('wire_mod:ui')
local target
function close()hud.close('advanced_logic:component_settings')end
function choose(field,value)
 if not target or not settings.apply(target,field,value) then close();return end
 on_open();document.feedback.text='Настройка применена'
end
function on_open()
 target=session.entries and session.entries.component_settings
 if not target then close();return end
 local info=require('wire_mod:logic_viewer').inspect(target[1],target[2],target[3])
 document.ui_title.text=info and info.display_name or 'Настройки компонента'
 local panel=document.options;panel:clear()
 for _,spec in ipairs(settings.specs(target[4])) do
  local current=block.get_field(target[1],target[2],target[3],spec.field) or 0
  if spec.field=='pulse_duration' and current==0 then current=0.1 end
  panel:add('<label size="424,24" color="#8AC6D3FF">'..ui.escape(spec.title)..'</label>')
  for first=1,#spec.values,4 do
   local row='<panel size="424,34" orientation="horizontal" interval="8" color="0">'
   for i=first,math.min(first+3,#spec.values) do
    row=row..ui.button((current==spec.values[i] and '[x] ' or '')..(spec.labels[i] or spec.values[i]),string.format("choose('%s',%g)",spec.field,spec.values[i]),98,current==spec.values[i])
   end
   panel:add(row..'</panel>')
  end
 end
end
