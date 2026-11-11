#!/usr/bin/env python3
"""Download a user-requested external collection; preserve its original rights."""
import argparse, concurrent.futures, hashlib, json, os, tempfile, urllib.request
from pathlib import Path
from PIL import Image

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--register-config',type=Path,help='Existing native.json to register the collection in')
    args=parser.parse_args()
    source=Path(__file__).resolve().parents[1]/'assets/wallpapers/online-anime.json'
    entries=json.loads(source.read_text())
    assert len(entries)==20
    output=args.output.resolve();output.mkdir(parents=True,exist_ok=True)
    def download(entry):
        name=entry['file'];assert Path(name).name==name
        target=output/name
        if target.exists():
            if hashlib.sha256(target.read_bytes()).hexdigest()!=entry['sha256']:
                raise ValueError(f'Refusing to replace an existing different file: {target}')
            return
        with urllib.request.urlopen(entry['source'],timeout=60) as response:
            data=response.read(30*1024*1024+1)
        if len(data)>30*1024*1024 or hashlib.sha256(data).hexdigest()!=entry['sha256']:
            raise ValueError(f'Integrity check failed: {name}')
        descriptor,temporary=tempfile.mkstemp(prefix='.download-',dir=output)
        try:
            with os.fdopen(descriptor,'wb') as file:file.write(data)
            with Image.open(temporary) as image:
                if image.width < 1920 or image.height < 1080: raise ValueError(f"Image too small: {name}")
                image.verify()
            os.replace(temporary,target)
        finally:
            Path(temporary).unlink(missing_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:list(pool.map(download,entries))
    (output/'SOURCES.json').write_text(json.dumps(entries,indent=2)+'\n')
    if args.register_config:
        config=args.register_config.resolve();raw=config.read_bytes();data=json.loads(raw)
        wallpaper=data.setdefault('wallpaper',{})
        collections=wallpaper.setdefault('collections',[])
        collections[:]=[c for c in collections if c.get('name')!='Raohane Anime' and c.get('path')!=str(output)]
        collections.append(dict(name='Raohane Anime',path=str(output)))
        if len(collections)>24:raise ValueError('Wallpaper collection limit reached; config was not changed')
        descriptor,temporary=tempfile.mkstemp(prefix='.anime-config-',dir=config.parent)
        try:
            with os.fdopen(descriptor,'w') as file:json.dump(data,file,ensure_ascii=False,indent=2);file.write('\n')
            if config.read_bytes()!=raw:raise ValueError('Config changed during import; registration was not saved')
            os.replace(temporary,config)
        finally:Path(temporary).unlink(missing_ok=True)
    print(f'20 verified online wallpapers: {output}')
if __name__=='__main__':main()
