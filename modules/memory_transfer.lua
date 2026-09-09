-- Здесь обмениваемся словами, а не байтами. Значения не обрезаются сами.
local M={}
function M.parse(text,bits,radix,limit)
 local result={}
 for token in tostring(text or ''):gmatch('[^%s,;]+') do
  local value
  if token:match('^0[xX]%x+$') then value=tonumber(token:sub(3),16)
  elseif token:match('^0b') then
   if token:match('^0b[01]+$') then
    value=0;for digit in token:sub(3):gmatch('.') do value=value*2+tonumber(digit) end
   end
  elseif radix==16 and token:match('^%x+$') then value=tonumber(token,16)
  elseif radix==10 and token:match('^%d+$') then value=tonumber(token) end
  if not value or value~=value or value<0 or value>=2^bits or value~=math.floor(value) then
   return nil,'Слово '..(#result+1)..': неверное значение '..token
  end
  result[#result+1]=value
  if #result>limit then return nil,'Данные не помещаются в выбранный диапазон' end
 end
 if #result==0 then return nil,'Поле обмена пустое' end
 return result
end
function M.format(value,bits,radix)
 return radix==16 and string.format('%0'..math.ceil(bits/4)..'X',value) or string.format("%.0f",value)
end
function M.export(values,bits,radix)
 local lines={}
 for first=1,#values,8 do
  local row={}
  for i=first,math.min(first+7,#values) do row[#row+1]=M.format(values[i],bits,radix) end
  lines[#lines+1]=table.concat(row,' ')
 end
 return table.concat(lines,'\n')
end
return M
