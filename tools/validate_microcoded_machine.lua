-- Full-engine behavioural test; driven by validate_microcoded_machine.mjs.
local enable={}
for _,id in ipairs({'wire_mod_2','advanced_logic_2'}) do
 if not table.has(pack.get_installed(),id) then enable[#enable+1]=id end
end
if #enable>0 then app.reconfig_packs(enable,{}) end
app.load_content()
local opened=false
time.post_runnable(function()
 if CREATE then app.new_world('machine','20260909','base:flat_grass') else app.open_world('machine') end
 opened=true
end)
while not opened do coroutine.yield() end
local function frame()hud.resume();coroutine.yield()end
local function wait(n)for _=1,n do frame()end end
local function await_value(predicate,message)
 local deadline=time.uptime()+3
 while not predicate() and time.uptime()<deadline do frame()end
 assert(predicate(),message)
end
wait(40)
local pid=hud.get_player()
local schematic=require('wire_mod_2:schematic')
local api=require('wire_mod_2:api')
local sim=require('wire_mod_2:simulation')
local cm=require('wire_mod_2:chain_manager')
local clocks=require('advanced_logic_2:clock_registry')
local mem=require('advanced_logic_2:memory_common')
local value
for _,entry in ipairs(schematic.library())do
 if entry.path=='advanced_logic_2:schematics/advanced-microcoded-machine.wms' then value=entry.schematic end
end
assert(value,'machine missing from configurator library')
-- Anchor is the origin block. Saved positions are independent of the player.
local anchor
if CREATE then
 local x,y,z=player.get_pos(pid);anchor={x=math.floor(x),y=math.floor(y)+4,z=math.floor(z)}
 file.write(pack.data_file('advanced_logic_2','machine_anchor.json'),json.tostring(anchor))
else anchor=json.parse(file.read(pack.data_file('advanced_logic_2','machine_anchor.json'))) end
player.set_flight(pid,true)
local cx,cz=18,-16;for _=1,ROT do cx,cz=-cz,cx end
player.set_pos(pid,anchor.x+cx,anchor.y+32,anchor.z+cz)
wait(30)
local ox,oz=value.origin[1],value.origin[3]
local function p(x,z)
 x,z=x-ox,z-oz;for _=1,ROT do x,z=-z,x end
 return anchor.x+x,anchor.y,anchor.z+z
end
if CREATE then
 local stone=block.index('base:stone')
 for x=-1,43 do for z=-1,39 do local wx,wy,wz=p(x,z);block.set(wx,wy-1,wz,stone)end end
 assert(schematic.begin_place(pid,value));for _=1,ROT do schematic.rotate(pid) end
 local ok,err=schematic.preview(pid,anchor);assert(ok,err)
 local n,message=schematic.place(pid,anchor,pid);assert(n==#value.blocks,message)
end
wait(60)
local kx,ky,kz=p(3,34)
assert(block.get_field(kx,ky,kz,'paused')==1,'machine must start or reload paused')
assert(clocks.set_paused(kx,ky,kz,true),'missing clock')
local function get(x,z,name)local a,b,c=p(x,z);return block.get_field(a,b,c,name)end
local function read(x,z,name)local a,b,c=p(x,z);return sim.read(a,b,c,name)end
local function set(x,z,name,v)local a,b,c=p(x,z);block.set_field(a,b,c,name,v);api.mark_device_for_update(a,b,c)end
local function chain(x,z,name)local a,b,c=p(x,z);return cm.get_chain_for_port(name,a,b,c)end
local function cell(i)local a,b,c=p(32,5);return mem.read_cell(a,b,c,i)end
local function lever(x,z,on)
 local a,b,c=p(x,z);local name=block.name(block.get(a,b,c))
 assert(name=='wire_mod_2:lever_'..(on and 'off' or 'on'),'unexpected lever state')
 events.emit(name..'.interact',a,b,c,pid)
 assert(block.name(block.get(a,b,c))=='wire_mod_2:lever_'..(on and 'on' or 'off'),'lever interaction failed')
end
assert(get(3,34,'paused')==1,'machine must start paused')
local cc=chain(3,34,'output')
assert(cc and cc==chain(16,34,'clk') and cc==chain(10,5,'clk') and cc==chain(32,5,'clk'),'clock network disconnected')
for _,position in ipairs({{18,10},{28,10},{18,5}})do for _,port in ipairs({'a','b','sel'})do assert(chain(position[1],position[2],port),'MUX missing '..port)end end
assert(chain(18,18,'a')~=chain(18,18,'b'),'SUB inputs shorted')
assert(chain(18,10,'a')~=chain(18,10,'b'),'MUX inputs shorted')
print('MACHINE initial PC='..tostring(get(16,34,'count'))..' ACC='..tostring(get(10,5,'q'))..' EN='..tostring(read(16,34,'en')))
local operands={10,5,3,255,20,40,170,200,100,50,15,1,0,1,255,42}
local operations={0,1,2,3,1,2,3,0,1,2,3,1,0,2,3,1}
local expected={10,15,12,243,7,223,117,200,44,250,245,246,0,255,0,42}
if not CREATE then
 local saved=json.parse(file.read(pack.data_file('advanced_logic_2','machine_state.json')))
 assert(get(16,34,'count')==saved.pc and get(10,5,'q')==saved.acc,'register state changed during reload')
 for i=0,15 do assert(cell(i)==saved.cells[i+1],'RAM changed on reload at '..i)end
end
-- Stop midway so reopening must continue with a nonzero PC and accumulator.
local cycles=CREATE and 6 or 26
for step=1,cycles do
 local pc=get(16,34,'count');local want=expected[pc+1]
 assert(read(4,20,'input')==operands[pc+1],'operand display mismatch')
 assert(read(37,20,'input')==operations[pc+1],'opcode display mismatch')
 assert(read(16,30,'input')==pc,'PC display mismatch')
 assert(read(22,1,'input')==want,'next-result display mismatch')
 assert(read(10,5,'d')==want,'ALU result before clock: expected '..want..', got '..tostring(read(10,5,'d')))
 assert(clocks.request_cycle(kx,ky,kz))
 local deadline=time.uptime()+4
 repeat frame() until (get(16,34,'count')==(pc+1)%16 and get(10,5,'q')==want and get(3,34,'output')==0 and get(10,5,'prev_clk')==0) or time.uptime()>deadline
 assert(get(16,34,'count')==(pc+1)%16,'PC failed to advance')
 assert(get(10,5,'q')==want,'accumulator failed to latch')
 assert(cell(pc)==want,'trace RAM wrote wrong address/value: '..pc..' got '..tostring(cell(pc)))
 assert(read(10,1,'input')==want,'accumulator display disconnected')
 await_value(function()return read(10,5,'d')==expected[get(16,34,'count')+1] and read(22,1,'input')==read(10,5,'d') end,'next instruction did not settle')
end
-- Inspect the trace via actual keypad and address MUX with the clock paused.
lever(37,12,true)
await_value(function()return read(32,12,'sel')==1 end,'INSPECT did not enable')
for i=0,(CREATE and 5 or 15)do
 set(30,15,'value',i)
 await_value(function()return read(32,5,'addr')==i and read(32,1,'input')==expected[i+1] end,'RAM address/readback failed at '..i)
end
lever(37,12,false)
await_value(function()return read(32,12,'sel')==0 and read(32,5,'addr')==get(16,34,'count') end,'INSPECT did not disable')
-- ENABLE holds PC, ACC and the entire RAM while clock pulses continue.
lever(42,37,false)
await_value(function()return read(16,34,'en')==0 and read(10,5,'load')==0 and read(32,5,'we')==0 end,'ENABLE did not disable')
local oldpc,oldacc=get(16,34,'count'),get(10,5,'q')
local before={};for i=0,15 do before[i+1]=cell(i)end
for _=1,2 do
 assert(clocks.request_cycle(kx,ky,kz),'disabled cycle unavailable')
 local deadline=time.uptime()+2
 repeat frame() until get(16,34,'prev_clk')==1 or time.uptime()>deadline
 assert(get(16,34,'prev_clk')==1,'disabled clock did not rise')
 repeat frame() until get(16,34,'prev_clk')==0 or time.uptime()>deadline
 assert(get(16,34,'prev_clk')==0,'disabled clock did not fall')
end
assert(get(16,34,'count')==oldpc and get(10,5,'q')==oldacc,'ENABLE did not hold state')
for i=0,15 do assert(cell(i)==before[i+1],'ENABLE did not protect RAM')end
lever(42,37,true)
await_value(function()return read(16,34,'en')==1 and read(10,5,'load')==1 and read(32,5,'we')==1 end,'ENABLE did not re-enable')
if not CREATE then
 -- The reset lever clears PC; instruction zero initializes ACC on the next edge.
 lever(22,34,true)
 await_value(function()return get(16,34,'count')==0 and read(16,34,'clr')==1 end,'PC reset failed')
 lever(22,34,false)
 await_value(function()return read(16,34,'clr')==0 and read(10,5,'d')==10 end,'PC reset did not release')
 assert(clocks.set_paused(kx,ky,kz,false))
 local deadline=time.uptime()+10
 repeat frame() until (get(16,34,'count')==5 and get(3,34,'output')==0) or time.uptime()>deadline
 assert(clocks.set_paused(kx,ky,kz,true));wait(8)
 assert(get(16,34,'count')==5 and get(10,5,'q')==7,'autonomous execution failed')
 for i=0,4 do assert(cell(i)==expected[i+1],'autonomous RAM trace mismatch')end
end
-- Drain deferred conductor variant/presence jobs before closing the world.
local settle=time.uptime()+0.3;while time.uptime()<settle do frame()end
local cells={};for i=0,15 do cells[i+1]=cell(i)end
file.write(pack.data_file('advanced_logic_2','machine_state.json'),json.tostring({pc=get(16,34,'count'),acc=get(10,5,'q'),cells=cells}))
app.close_world(true)
print('MACHINE validation passed: rotation '..ROT..', '..(CREATE and 'create / 6 instructions' or 'reload / 26 instructions / autonomous clock')..', RAM, ENABLE, displays')
app.quit()
