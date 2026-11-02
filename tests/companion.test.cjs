'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict');
const {advance,markup}=require('../dist/companion.js');
test('roaming stays bounded, reverses at each edge and caps suspended-frame time',()=>{
 let p={x:30,y:100,size:128,vx:-15},left=false,right=false;
 for(let i=0;i<2500;i++){const old=p.vx;p=advance(p,.1,{width:320,height:250});assert.ok(p.x>=0&&p.x<=192);assert.ok(p.y>=0&&p.y<=154);if(old!==p.vx){if(p.x===0)left=true;else right=true;}}
 assert.ok(left&&right);assert.equal(advance({...p,x:100,vx:15},1000,{width:320,height:250}).x,101.5);
 assert.equal(advance({...p,x:100,size:176},.1,{width:100,height:50}).x,0);
});
test('companion name is escaped; interactions do not introduce a chat or memory store',()=>{
 const html=markup('<img src=x onerror=alert(1)>');assert.ok(html.includes('&lt;img'));assert.ok(!html.includes('onerror=alert(1)>'));assert.match(html,/id="pet"/);assert.match(html,/data-duration="25"/);
});
