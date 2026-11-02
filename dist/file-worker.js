importScripts('vendor/fflate.min.js','file-parser.js');
self.onmessage=e=>{try{self.postMessage({ok:true,result:FishbotFiles.parse(e.data.buffer,e.data.name,fflate)});}catch(error){self.postMessage({ok:false,error:error.message});}};
