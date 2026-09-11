'use strict';
const fs=require('node:fs'), os=require('node:os'), path=require('node:path');
const cp=require('node:child_process'), assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const build=cp.spawnSync('moon',['build','--target','js','cmd/inspect'],{cwd:root,encoding:'utf8'});
assert.equal(build.status,0,build.stderr);
const cli=path.join(root,'_build/js/debug/build/cmd/inspect/inspect.js');
const run=file=>{
 const r=cp.spawnSync(process.execPath,[cli,file],{cwd:root,encoding:'utf8',maxBuffer:8*1024*1024});
 const events=r.stdout.trim()?r.stdout.trim().split(/\r?\n/).map(JSON.parse):[];
 return {...r,events};
};
const source=path.join(root,'fixtures/synthetic.ts');
const actual=run(source); assert.equal(actual.status,0,actual.stdout+actual.stderr);
const probe=cp.spawnSync('ffprobe',['-v','error','-show_programs','-show_packets','-of','json',source],{encoding:'utf8',maxBuffer:8*1024*1024});
assert.equal(probe.status,0,probe.stderr || 'ffprobe must be installed; this is not a skipped verification');
const reference=JSON.parse(probe.stdout);
const summary=actual.events.find(x=>x.type==='summary');
for(const p of reference.programs){
 const map=summary.maps.find(m=>m.program===p.program_num); assert.ok(map);
 assert.equal(map.pcr_pid,p.pcr_pid);
 assert.equal(summary.programs.find(x=>x.program===p.program_num).pmt_pid,p.pmt_pid);
 assert.deepEqual(map.streams.map(s=>s.pid).sort(),p.streams.map(s=>parseInt(s.id,16)).sort());
 for(const s of p.streams){
   const first=reference.packets.find(x=>x.stream_index===s.index && x.pts!==undefined);
   const timestamp=actual.events.find(x=>x.type==='pes' && x.pid===parseInt(s.id,16));
   assert.equal(timestamp.pts,String(first.pts));
   assert.equal(timestamp.dts===null?timestamp.pts:timestamp.dts,String(first.dts));
 }
}
const bytes=fs.readFileSync(source), packets=[];
for(let i=0;i<bytes.length;i+=188)packets.push(bytes.subarray(i,i+188));
const pid=p=>((p[1]&31)<<8)|p[2];
const victim=packets.findIndex((p,i)=>i>10&&pid(p)===256&&(p[3]&16)!==0);
assert.ok(victim>0);
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'moontsinspect-check-'));
try {
 const check=(name,data,code,status=1)=>{
  const file=path.join(tmp,name+'.ts');fs.writeFileSync(file,data);const r=run(file);
  assert.equal(r.status,status,r.stdout+r.stderr);
  if(code)assert.ok(r.events.some(e=>e.type==='issue'&&e.code===code),r.stdout);
  return r;
 };
 const dropped=check('dropped',Buffer.concat(packets.filter((_,i)=>i!==victim)),'continuity_gap');
 const next=packets.findIndex((p,i)=>i>victim&&pid(p)===256);
 assert.ok(dropped.events.some(e=>e.code==='continuity_gap'&&e.offset===String((next-1)*188)&&e.pid===256), JSON.stringify({victim,next,issues:dropped.events.filter(e=>e.type==='issue')}));
 check('duplicate',Buffer.concat([...packets.slice(0,victim+1),packets[victim],...packets.slice(victim+1)]),null,0);
 check('triple',Buffer.concat([...packets.slice(0,victim+1),packets[victim],packets[victim],...packets.slice(victim+1)]),'continuity_gap');
 check('truncated',bytes.subarray(0,bytes.length-1),'trailing_bytes');
 const pat=packets.findIndex(p=>pid(p)===0);const corrupt=Buffer.from(bytes);corrupt[pat*188+13]^=1;
 check('crc',corrupt,'section_crc');
 const sync=Buffer.from(bytes);sync[188*10]=0;check('sync',sync,'sync_byte');
 console.log('Independent crosscheck: program/PID inventory and first PTS/DTS match ffprobe; drop/duplicate/triple/truncation/CRC/sync mutations passed');
} finally {
 // Only remove this test's known files; no recursive deletion or shared directories.
 for(const name of ['dropped','duplicate','triple','truncated','crc','sync']) {
  const file=path.join(tmp,name+'.ts');if(fs.existsSync(file))fs.unlinkSync(file);
 }
 fs.rmdirSync(tmp);
}
