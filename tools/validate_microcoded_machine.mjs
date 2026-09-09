import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const game=path.resolve(root,'../..'),wire=path.resolve(root,'../wire_mod2');
const project=fs.mkdtempSync(path.join(os.tmpdir(),'al2-machine-'));
try{
 fs.mkdirSync(path.join(project,'content'));
 for(const [name,source]of Object.entries({base:path.join(game,'res/content/base'),wire_mod_2:wire,advanced_logic_2:root}))fs.symlinkSync(source,path.join(project,'content',name));
 fs.copyFileSync(path.join(game,'res/project.toml'),path.join(project,'project.toml'));
 for(const rot of [0,1,2,3])for(const create of [true,false]){
  if(create)fs.rmSync(path.join(project,'worlds'),{recursive:true,force:true});
  const script=path.join(project,'check.lua');
  fs.writeFileSync(script,`local CREATE=${create}\nlocal ROT=${rot}\n`+fs.readFileSync(path.join(root,'tools/validate_microcoded_machine.lua'),'utf8'));
  const r=spawnSync(path.join(game,'VoxelCore'),['--res',path.join(game,'res'),'--project',project,'--dir',project,'--script',script,'--log',path.join(project,'engine.log')],{cwd:project,encoding:'utf8',timeout:120000});
  const output=r.stdout+r.stderr;
  const lines=output.split('\n').filter(l=>l.includes('MACHINE')||l.includes('[E]')&&!l.includes('window'));
  console.log(lines.join('\n'));
  if(r.status!==0||!output.includes('MACHINE validation passed')||lines.some(l=>l.includes('[E]')))throw Error(`Engine failed (${create?'create':'reload'}): ${r.error||r.status}`);
 }
}finally{fs.rmSync(project,{recursive:true,force:true});}
