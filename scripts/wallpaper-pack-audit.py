#!/usr/bin/env python3
"""Check shipped wallpaper counts, integrity, dimensions and provenance."""
import collections, hashlib, json, sys
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image
root = Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]/'assets/wallpapers'
entries = json.loads((root/'catalog.json').read_text())
assert collections.Counter(e['category'] for e in entries)=={'anime':20,'nature':20,'abstract':20}, 'Expected 20 images per category'
seen=set()
for entry in entries:
    p=(root/entry['file']).resolve()
    assert p.is_relative_to(root.resolve()), 'Unsafe catalog path'
    data=p.read_bytes(); sha=hashlib.sha256(data).hexdigest()
    assert sha==entry['sha256'] and sha not in seen, f'Damaged or duplicate image: {p}'
    seen.add(sha)
    assert entry['title'] and entry['authors'] and entry['license'] and entry['source'], f'Missing provenance: {p}'
    if p.suffix=='.svg':
        svg=ET.fromstring(data); w,h=int(svg.attrib['width']),int(svg.attrib['height'])
        assert not any(n.tag.endswith(('script','image','foreignObject')) or any('href' in k for k in n.attrib) for n in svg.iter()), f'External SVG resource: {p}'
    else:
        with Image.open(p) as image:
            w,h=image.size; image.verify()
    assert w>=1920 and h>=1080, f'Image too small: {p}: {w}x{h}'
for name in ['CC-BY-SA-4.0.txt','CC-BY-2.0.txt','KDE-COPYING.LGPL3','GPL-3.0.txt']:
    assert (root/'licenses'/name).stat().st_size>1000, 'License text missing'
print('wallpaper-pack-audit: 60 bundled offline images, 20 per category, full HD or larger, checksums and provenance valid')
