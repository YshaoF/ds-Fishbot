(()=>{'use strict';
 const native=!!window.webkit?.messageHandlers?.fishbot;
 const rpc=async data=>{const r=await window.webkit.messageHandlers.fishbot.postMessage(data);if(r?.error)throw new Error(r.error);return r;};
 let dbPromise;
 function db(){if(!dbPromise)dbPromise=new Promise((resolve,reject)=>{const req=indexedDB.open('fishbot-mobile',1);req.onupgradeneeded=()=>req.result.createObjectStore('items');req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(new Error('本机存储不可用，请检查浏览器设置。'));});return dbPromise;}
 async function entry(key,value,write=false){const database=await db();return await new Promise((resolve,reject)=>{const tx=database.transaction('items',write?'readwrite':'readonly'),store=tx.objectStore('items');let result;const req=write?value===null?store.delete(key):store.put(value,key):store.get(key);req.onsuccess=()=>result=req.result;tx.oncomplete=()=>resolve(result??null);tx.onerror=()=>reject(new Error('保存失败，可能已没有可用空间。'));});}
 async function request(url,options={}){
  if(!native)return await fetch(url,{...options,redirect:'error'});
  const id=FishbotCore.uuid(),abort=()=>rpc({action:'cancel',id}).catch(()=>{});options.signal?.throwIfAborted();options.signal?.addEventListener('abort',abort,{once:true});
  try{const response=await rpc({action:'request',id,url,method:options.method||'GET',headers:options.headers||{},body:options.body||''});if(options.signal?.aborted)throw new DOMException('已停止','AbortError');return {ok:response.status>=200&&response.status<300,status:response.status,json:async()=>JSON.parse(response.text),text:async()=>response.text};}finally{options.signal?.removeEventListener('abort',abort);}
 }
 window.FishbotBridge={native,request,load:async()=>{const raw=native?(await rpc({action:'storageRead'})).value:await entry('state');return raw?JSON.parse(raw):null;},save:async state=>{const value=JSON.stringify(FishbotCore.exportData(state));if(native)await rpc({action:'storageWrite',value});else await entry('state',value,true);},getSecret:async slot=>native?(await rpc({action:'secretGet',slot})).value||'':await entry('secret:'+slot)||'',setSecret:async(slot,value)=>{if(native)await rpc({action:'secretSet',slot,value});else await entry('secret:'+slot,value||null,true);},appearance:theme=>{if(native)rpc({action:'appearance',theme}).catch(()=>{});},share:async(text,filename)=>native?await rpc({action:'share',text,filename}):navigator.share?await navigator.share({title:filename,text}):null};
})();
