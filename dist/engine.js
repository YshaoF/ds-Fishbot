(()=>{'use strict';
 const C=FishbotCore,B=FishbotBridge;
 class Engine{
  constructor(state,{save,change,fetcher=B.request,getSecret=B.getSecret}={}){Object.assign(this,{state,save,change,fetcher,getSecret});this.busy=false;this.speakers=new Set();}
  stop(){this.controller?.abort();}
  async ask(bot,messages,signal){const c=C.connection(this.state,bot),key=await this.getSecret(c.slot);if(!key)throw new Error('请先在设置中填写 '+(bot.inheritAPI===false?bot.name+' 的':'默认')+' API Key。');if(!c.model?.trim())throw new Error('请先填写模型名称。');
   const timeout=new AbortController(),timer=setTimeout(()=>timeout.abort(),120000),abort=()=>timeout.abort();signal?.addEventListener('abort',abort,{once:true});
   try{const response=await this.fetcher(C.endpoint(c.baseURL),{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+key},body:JSON.stringify(C.body(c,messages)),signal:timeout.signal});if(!response.ok)throw new Error('API 返回 HTTP '+response.status+({401:'，请检查 Key。',429:'，请稍后重试或检查额度。',404:'，请检查 API 地址和模型名称。'}[response.status]||'，请检查接口状态。'));const data=await response.json(),m=data.choices?.[0]?.message;if(!m||typeof m.content!=='string'||!m.content.trim())throw new Error(m?.tool_calls?.length?'当前手机聊天仅支持问答，请使用可直接回复的模型。':'接口没有返回可用文字。');return m.content.trim();}catch(e){if(signal?.aborted)throw new DOMException('已停止','AbortError');if(timeout.signal.aborted)throw new Error('请求超时，请检查网络后重试。');if(e instanceof TypeError)throw new Error('网络或跨域连接失败。iOS App 中请检查网络；网页预览需接口允许跨域。');throw e;}finally{clearTimeout(timer);signal?.removeEventListener('abort',abort);}
  }
  async run(id,text,attachments=[]){if(this.busy)throw new Error('请等待上一条回复，或先停止。');const bot=this.state.bots.find(b=>b.id===id);if(!bot)throw new Error('请选择一个 Bot。');if(bot.type==='group'&&bot.memberIds.length<2)throw new Error('群里只有主管，请再加入一位 Bot。');text=String(text||'').trim()||(attachments.length?'请阅读附件，简要说明主要内容。':'');if(!text||text.length>30000)throw new Error('请输入1～30000字。');const members=bot.type==='group'?bot.memberIds.map(id=>this.state.bots.find(b=>b.id===id)).filter(Boolean):[bot];for(const member of members){if(!await this.getSecret(C.connection(this.state,member).slot))throw new Error('请先配置 '+member.name+' 的 API Key。');}
   this.busy=true;this.controller=new AbortController();this.activeId=id;const signal=this.controller.signal;bot.messages.push({id:C.uuid(),role:'user',content:text,attachments,at:Date.now()});
   try{await this.save();this.change();
    if(/^\s*(?:请)?记住[：:\s]/.test(text)&&!attachments.length){C.remember(this.state,text.replace(/^\s*(?:请)?记住[：:\s]+/,''),{botId:bot.id});bot.messages.push({id:C.uuid(),role:'assistant',content:'记住了，其他 Bot 也能使用这条记忆。',at:Date.now(),botId:bot.id,speaker:bot.name});return;}
    const summary=bot.type==='group'&&C.summaryRequested(text),roster=summary?members.filter(b=>b.id===this.state.supervisorId):members,rounds=bot.type==='group'&&!summary?bot.rounds||1:1;
    for(let round=1;round<=rounds;round++){let index=0;const speak=async()=>{while(index<roster.length){signal.throwIfAborted();const member=roster[index++];this.speakers.add(member.id);this.change();try{
      const prompt=C.system(this.state,member,{discussion:bot.type==='group'}),messages=[{role:'system',content:prompt+(summary?'\n用户明确要求总结，只总结已有发言。':'')},...C.context(bot.messages,{group:bot.type==='group'})];if(round>1)messages.push({role:'user',content:'阅读已有发言，只针对一条观点补充、质疑或追问，没有新内容请输出 [SILENT]。不要总结。'});
      const content=await this.ask(member,messages,signal);signal.throwIfAborted();if(content==='[SILENT]')continue;
      const boundary=bot.messages.map(m=>m.role).lastIndexOf('user'),normal=s=>s.replace(/[\s\p{P}]/gu,'');if(bot.messages.slice(boundary+1).some(m=>m.role==='assistant'&&normal(m.content)===normal(content)))continue;
      bot.messages.push({id:C.uuid(),role:'assistant',content,at:Date.now(),botId:member.id,speaker:member.name,...(summary?{summary:true}:{})});await this.save();this.change();
     }catch(e){if(signal.aborted)throw e;bot.messages.push({id:C.uuid(),role:'assistant',content:e.message,at:Date.now(),error:true,botId:member.id,speaker:member.name});await this.save();this.change();}finally{this.speakers.delete(member.id);this.change();}}};
     const settled=await Promise.allSettled(Array.from({length:bot.type==='group'&&bot.parallel&&!summary?Math.min(3,roster.length):1},speak));const failed=settled.find(r=>r.status==='rejected');if(failed)throw failed.reason;
    }
   }finally{this.busy=false;this.speakers.clear();this.activeId=null;this.controller=null;await this.save();this.change();}
  }
 }
 window.FishbotEngine=Engine;
})();
