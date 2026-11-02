"""Fetch only missing, integrity-pinned build inputs; never fetch at app runtime."""
from pathlib import Path
import json,hashlib,base64,urllib.request,tarfile,io
root=Path(__file__).resolve().parent.parent
pins=json.loads((root/'VENDOR.json').read_text(encoding='utf-8'))
missing=[name for name,digest in pins['files'].items() if not (root/name).is_file()]
for name,digest in pins['files'].items():
    p=root/name
    if p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()!=digest:raise RuntimeError('Bundled dependency hash mismatch: '+name)
if missing:
    with urllib.request.urlopen(pins['tarball'],timeout=120) as response:raw=response.read(100*1024*1024)
    if 'sha512-'+base64.b64encode(hashlib.sha512(raw).digest()).decode()!=pins['integrity']:raise RuntimeError('PDF.js package integrity mismatch')
    with tarfile.open(fileobj=io.BytesIO(raw),mode='r:gz') as tar:
        for source,target in pins['members'].items():
            if target not in missing:continue
            data=tar.extractfile(source).read()
            if hashlib.sha256(data).hexdigest()!=pins['files'][target]:raise RuntimeError('PDF.js file digest mismatch')
            p=root/target;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    print('Verified missing PDF.js build dependencies.')
