// Плата спроектирована вручную: позиции компонентов и ломаные проводов заданы явно.
// Поиск позиций и автоматическая трассировка не выполняются. Запуск возможен из любого каталога через Node.
import fs from 'node:fs';
import {encode} from '../../wire_mod2/tools/wms_codec.mjs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const axes=[[1,0,0],[0,1,0],[0,0,1]], blocks=[], occupied=new Map(), grid=new Map();
const key=(x,z)=>`${x},${z}`;
const devices={},sizes={};
function device(label,name,x,z,fields={},data){
 const full=name.includes(':')?name:`advanced_logic_2:${name}`;
 const b={name:full,pos:[x,0,z],axes,fields};if(data)b.data=data;
 blocks.push(b);devices[label]=b;
 const pack=full.startsWith('wire_mod_2:')?path.resolve(root,'../wire_mod2'):root;
 const def=JSON.parse(fs.readFileSync(path.join(pack,'blocks',full.split(':')[1]+'.json')));
 const [sx,,sz]=def.size||[1,1,1];sizes[label]=[sx,sz];
 for(let dx=0;dx<sx;dx++)for(let dz=0;dz<sz;dz++){
  const k=key(x+dx,z+dz);if(occupied.has(k))throw Error(`Device overlap ${label}`);occupied.set(k,label);
 }
}
const operands=[10,5,3,255,20,40,170,200,100,50,15,1,0,1,255,42];
const operations=[0,1,2,3,1,2,3,0,1,2,3,1,0,2,3,1];
const memory=cells=>({cells:[...cells,...Array(64-cells.length).fill(0)]});
device('pc','counter',16,34,{data_bits:4});
device('operand','rom',4,27,{data_bits:8,addr_bits:4},memory(operands));
device('opcode','rom',25,27,{data_bits:4,addr_bits:4},memory(operations));
device('add','adder_4bit',8,18,{data_bits:8});
device('sub','adder_4bit',18,18,{data_bits:8});
device('invert','bus_logic',23,19,{data_bits:8,operation:3});
device('carry','wire_mod_2:lever_on',20,20);
device('xor','bus_logic',28,18,{data_bits:8,operation:2});
device('alu_low','mux_4bit',18,10,{data_bits:8});
device('alu_high','mux_4bit',28,10,{data_bits:8});
device('alu','mux_4bit',18,5,{data_bits:8});
device('decode','bus_splitter_4bit',35,18,{group:0});
device('acc','register',10,5,{data_bits:8});
device('trace','ram',32,5,{data_bits:8,addr_bits:4},memory([]));
device('address','mux_4bit',32,12,{data_bits:4});
device('keypad','keypad_4bit',30,15,{value:0});
device('inspect','wire_mod_2:lever_off',37,12);
device('enable','wire_mod_2:lever_on',42,37);
device('reset','wire_mod_2:lever_off',22,34);
device('clock','clock_generator',3,34,{pulse_time:0.5,delay_time:0.5,paused:1});
for(const [label,x,z] of [['pc_display',16,30],['operand_display',4,20],['opcode_display',37,20],['acc_display',10,1],['alu_display',22,1],['ram_display',32,1]])device(label,'indicator_4bit',x,z);
const nets=new Map();
function wire(net,type,...points){
 let cells=nets.get(net);if(!cells){cells=new Map();nets.set(net,cells);}
 const add=(x,z)=>{
  const k=key(x,z);if(occupied.has(k))throw Error(`${net} hits ${occupied.get(k)} at ${k}`);
  if(!grid.has(k))grid.set(k,new Map());
  if(!cells.has(k)){const c={x,z,type,dirs:new Set()};cells.set(k,c);grid.get(k).set(net,c);}return cells.get(k);
 };
 let [x,z]=points[0];add(x,z);
 for(const [tx,tz] of points.slice(1)){
  if(x!==tx&&z!==tz)throw Error(`Diagonal ${net}`);
  while(x!==tx||z!==tz){const dx=Math.sign(tx-x),dz=Math.sign(tz-z);add(x,z).dirs.add(`${dx},${dz}`);add(x+dx,z+dz).dirs.add(`${-dx},${-dz}`);x+=dx;z+=dz;}
 }
}
const B='advanced_logic_2:bus_purple_8',A='advanced_logic_2:bus_orange_4';
const blue='wire_mod_2:wire_blue',green='wire_mod_2:wire_green',red='wire_mod_2:wire_red';
// Тракт данных: обратная связь аккумулятора, непосредственный операнд и три результата ALU.
wire('acc',B,[11,5],[12,5],[12,21],[8,21],[8,19]);
wire('acc',B,[12,21],[28,21],[28,19]);wire('acc',B,[18,21],[18,19]);
wire('acc',B,[12,5],[12,2],[10,2]);
wire('operand',B,[4,26],[4,23],[32,23],[32,18],[29,18]);
wire('operand',B,[10,23],[10,18]);wire('operand',B,[23,23],[23,20]);
wire('operand',B,[16,23],[16,11],[18,11]);wire('operand',B,[4,23],[4,21]);
wire('add',B,[8,17],[8,14],[15,14],[15,10],[17,10]);
wire('sub',B,[18,17],[18,15],[26,15],[26,11],[28,11]);
wire('inverted',B,[23,18],[20,18]);
wire('xor',B,[28,17],[28,16],[31,16],[31,13],[24,13],[24,10],[27,10]);
wire('low',B,[18,9],[18,6]);wire('high',B,[28,9],[28,8],[16,8],[16,5],[17,5]);
wire('result',B,[18,4],[18,2],[14,2],[14,7],[9,7],[9,5]);
wire('result',B,[18,2],[18,0],[36,0],[36,6],[34,6]);wire('result',B,[18,2],[22,2]);
// Адрес программы и код операции. MUX использует два младших бита кода операции.
wire('pc',A,[16,33],[16,31],[4,31],[4,28]);
wire('pc',A,[16,31],[40,31],[40,13],[32,13]);wire('pc',A,[25,31],[25,28]);
wire('opcode',A,[25,26],[25,24],[35,24],[35,19]);
wire('bit0',red,[35,17],[35,10],[29,10]);wire('bit0',red,[35,10],[35,7],[20,7],[20,10],[19,10]);
wire('bit1',green,[36,17],[39,17],[39,14],[34,14],[34,8],[29,8],[29,4],[19,4],[19,5]);wire('opcode',A,[35,24],[37,24],[37,21]);
// Выбор адреса RAM и чтение данных независимо от входа записи.
wire('address',A,[32,11],[32,6]);wire('keypad',A,[30,14],[30,12],[31,12]);
wire('inspect',red,[36,12],[33,12]);wire('ram',B,[32,4],[32,2]);
// Одна физическая тактовая сеть для всех последовательных компонентов.
wire('clock',blue,[3,33],[2,33],[2,3],[37,3],[37,5],[35,5]);
wire('clock',blue,[10,3],[10,4]);wire('clock',blue,[2,33],[2,38],[20,38],[20,34],[18,34]);
wire('enable',green,[41,37],[6,37],[6,6],[10,6]);wire('enable',green,[14,37],[14,35],[15,35]);
wire('enable',green,[41,37],[41,9],[30,9],[30,5],[31,5]);
wire('carry',green,[19,20],[17,20],[17,18]);
wire('reset',red,[22,35],[18,35]);
// Направления контактов заданы явно. У каждого контакта устройства должен быть настоящий провод
// : пассивные мосты нельзя подключать непосредственно к портам компонентов.
const terminals={
 acc:[[11,5,-1,0],[8,19,0,-1],[18,19,0,-1],[28,19,0,-1],[10,2,0,-1]],
 operand:[[4,26,0,1],[10,18,-1,0],[23,20,0,-1],[29,18,-1,0],[18,11,0,-1],[4,21,0,-1]],
 add:[[8,17,0,1],[17,10,1,0]],sub:[[18,17,0,1],[28,11,0,-1]],xor:[[28,17,0,1],[27,10,1,0]],
 inverted:[[23,18,0,1],[20,18,-1,0]],low:[[18,9,0,1],[18,6,0,-1]],high:[[28,9,0,1],[17,5,1,0]],
 bit0:[[35,17,0,1],[29,10,-1,0],[19,10,-1,0]],bit1:[[36,17,0,1],[19,5,-1,0]],
 result:[[18,4,0,1],[9,5,1,0],[34,6,0,-1],[22,2,0,-1]],
 pc:[[16,33,0,1],[4,28,0,-1],[25,28,0,-1],[16,31,0,-1],[32,13,0,-1]],
 opcode:[[25,26,0,1],[35,19,0,-1],[37,21,0,-1]],address:[[32,11,0,1],[32,6,0,-1]],
 keypad:[[30,14,0,1],[31,12,1,0]],inspect:[[36,12,1,0],[33,12,-1,0]],ram:[[32,4,0,1],[32,2,0,-1]],
 clock:[[3,33,0,1],[35,5,-1,0],[10,4,0,1],[18,34,-1,0]],
 carry:[[19,20,1,0],[17,18,1,0]],enable:[[41,37,1,0],[10,6,0,-1],[15,35,1,0],[31,5,1,0]],reset:[[22,35,0,-1],[18,35,-1,0]]};
for(const [net,ends] of Object.entries(terminals))for(const [x,z,dx,dz]of ends)nets.get(net).get(key(x,z)).dirs.add(`${dx},${dz}`);
const straight=c=>c.dirs.size===2&&([...c.dirs].every(d=>d.endsWith(',0'))||[...c.dirs].every(d=>d.startsWith('0,')));
const bridges=new Set();
for(const [k,owners]of grid){if(owners.size>1){
 const all=[...owners.values()];if(all.length!==2||!all.every(straight)||[...all[0].dirs][0].endsWith(',0')===[...all[1].dirs][0].endsWith(',0'))throw Error(`Non-crossing overlap ${k}: ${[...owners.keys()]}`);
 bridges.add(k);
}}
// На параллельных соседних дорожках прямой мост изолирует боковые контакты. Поворот
// нельзя превращать в мост: это разорвёт нужную сеть.
for(const [k,owners]of grid)for(const [net,c]of owners){for(const [dx,dz]of [[1,0],[-1,0],[0,1],[0,-1]]){
 const nk=key(c.x+dx,c.z+dz),other=grid.get(nk);if(!other)continue;
 for(const [on,oc]of other){if(net===on||c.type!==oc.type)continue;
 const blocksSide=(cell,cellKey,dir)=>bridges.has(cellKey)&&!cell.dirs.has(dir);
 if(blocksSide(c,k,`${dx},${dz}`)||blocksSide(oc,nk,`${-dx},${-dz}`))continue;
 if(straight(c)&&!c.dirs.has(`${dx},${dz}`))bridges.add(k);
 else if(straight(oc)&&!oc.dirs.has(`${-dx},${-dz}`))bridges.add(nk);
 else throw Error(`Adjacent unrelated turns ${net}/${on} at ${k}/${nk}`);
 }
}}
for(const [net,ends]of Object.entries(terminals))for(const [x,z]of ends)if(bridges.has(key(x,z)))throw Error(`Bridge touches port ${net}: ${x},${z}`);
for(const [k,owners]of grid){const c=[...owners.values()][0];blocks.push({name:bridges.has(k)?'wire_mod_2:wire_bridge':c.type,pos:[c.x,0,c.z],axes});}
const result={format:1,name:'advanced-microcoded-machine',description:'8-битная программируемая машина: LOAD / ADD / SUB / XOR, аккумулятор и журнал RAM',author:'DaggerLab',dependencies:['wire_mod_2','advanced_logic_2'],size:[43,2,39],origin:[3,0,34],blocks};
fs.writeFileSync(path.join(root,'schematics/advanced-microcoded-machine.wms'),encode(result)+'\n');
console.log(`${blocks.length} blocks, ${Object.keys(devices).length} devices, ${bridges.size} bridges`);
// Подписанный план для инструкции с теми же фиксированными координатами платы.
const labels={carry:'SUB +1',pc:'PC',operand:'OPERAND',opcode:'OPCODE',add:'ADD',sub:'SUB ADD',invert:'NOT',xor:'XOR',alu_low:'LOAD/ADD',alu_high:'SUB/XOR',alu:'RESULT',decode:'DECODE',acc:'ACC',trace:'RAM',address:'ADDR MUX',keypad:'KEYPAD',inspect:'INSPECT',enable:'ENABLE',reset:'RESET PC',clock:'CLOCK',pc_display:'PC OUT',operand_display:'IMM OUT',opcode_display:'OP OUT',acc_display:'ACC OUT',alu_display:'NEXT OUT',ram_display:'RAM OUT'};
let svg='<svg xmlns="http://www.w3.org/2000/svg" viewBox="-2 -3 48 44" width="960" height="880"><rect x="-2" y="-3" width="48" height="44" fill="#151b24"/><g stroke-linecap="round" fill="none">';
for(const cells of nets.values())for(const c of cells.values())for(const dir of c.dirs){const [dx,dz]=dir.split(',').map(Number);const color=c.type===B?'#ad94da':c.type===A?'#e6b15c':c.type===blue?'#78bcec':c.type===green?'#8fd0ad':'#e98991';svg+=`<path d="M${c.x+.5} ${c.z+.5}l${dx/2} ${dz/2}" stroke="${color}" stroke-width=".13"/>`;}
svg+='</g>';
for(const k of bridges){const [x,z]=k.split(',').map(Number);svg+=`<circle cx="${x+.5}" cy="${z+.5}" r=".16" fill="#151b24" stroke="#a3b1c3" stroke-width=".065"/>`;}
for(const [label,b]of Object.entries(devices)){const [x,,z]=b.pos;const [sx,sz]=sizes[label];svg+=`<rect x="${x}" y="${z}" width="${sx}" height="${sz}" rx=".1" fill="#e4eaf1" stroke="#111" stroke-width=".1"/><text x="${x+sx/2}" y="${z-.28}" text-anchor="middle" font-family="sans-serif" font-size=".62" font-weight="bold" fill="#fff" stroke="#151b24" stroke-width=".12" paint-order="stroke">${labels[label]}</text>`;}
svg+='<text x="0" y="-1.8" font-family="sans-serif" font-size=".85" fill="#fff">8-битная машина · вид сверху · CLOCK = начало размещения</text></svg>\n';
fs.writeFileSync(path.join(root,'docs/microcoded-machine.svg'),svg);
