#!/usr/bin/env python3
"""Original Raohane vector collection. No external images, fonts or resources."""
import math, random, json, hashlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
entries = json.loads((ROOT / 'catalog.json').read_text())
entries = [e for e in entries if e.get('source') != 'Raohane original vector artwork']

def save(category, index, title, content):
    folder = ROOT/category; folder.mkdir(exist_ok=True)
    file = folder/f'{index:02d}-{title.lower().replace(" ", "-")}.svg'
    file.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 1920 1080"><title>'+title+'</title>'+content+'</svg>')
    entries.append(dict(category=category, file=str(file.relative_to(ROOT)), title=title,
        authors=['Raohane contributors'], license='GPL-3.0-or-later', source='Raohane original vector artwork',
        sha256=hashlib.sha256(file.read_bytes()).hexdigest(), modified=False))

palettes=[('#101d38','#e7a7ae','#273960','#0d1830'),('#123340','#c3e1da','#416b78','#102a38'),
          ('#25213f','#e9b4ed','#5c4773','#201c38'),('#2c2944','#f6c499','#89708b','#26263e'),
          ('#111f2a','#a3d4c4','#305958','#0b1d26')]
titles=['Lantern girl','The last train','Skyline observer','Sea breeze','Starlight traveler',
        'Rain on the balcony','Cloud messenger','The little astronomer','After school','Northern wanderer',
        'Lantern valley','Summer crossing','Cloud archipelago','The quiet station','Petal river',
        'Rooftop constellation','Floating observatory','Night harbour','Wisteria passage','Dawn above the clouds']
for n,title in enumerate(titles):
    rng=random.Random(700+n); sky,light,mid,ink=palettes[n%5]
    s=f'<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="{sky}"/><stop offset="1" stop-color="{mid}"/></linearGradient><radialGradient id="halo"><stop stop-color="{light}" stop-opacity=".35"/><stop offset="1" stop-color="{light}" stop-opacity="0"/></radialGradient></defs><path fill="url(#sky)" d="M0 0h1920v1080H0z"/><ellipse cx="1280" cy="340" rx="700" ry="600" fill="url(#halo)"/>'
    for j in range(65):
        x=rng.randint(80,1850); y=rng.randint(30,560); rad=rng.choice([1,1,2])
        s+=f'<circle cx="{x}" cy="{y}" r="{rad}" fill="{light}" opacity="{rng.uniform(.15,.7):.2f}"/>'
    s+=f'<circle cx="{1350-n*15}" cy="{220+n%4*40}" r="{60+n%3*18}" fill="{light}" opacity=".8"/>'
    # Long stylized cloud banks, drawn as irregular closed silhouettes.
    for j in range(5):
        x=rng.randint(-300,1600);y=240+j*105;w=rng.randint(350,650)
        s+=f'<path d="M{x} {y}q{w*.12} -44 {w*.28} -20q{w*.12} -62 {w*.3} -25q{w*.13} -24 {w*.25} 12l{w*.17} 33Z" fill="{light}" opacity=".08"/>'
    scene=n%5
    if scene in (0,2):
        for layer in range(2):
            for j in range(23):
                x=j*95+rng.randint(-20,20); y=650+rng.randint(-100,130)+layer*100; w=rng.randint(60,110)
                s+=f'<path d="M{x} 1080V{y}h{w}v{1080-y}Z" fill="{mid if layer==0 else ink}"/>'
                for yy in range(y+20,960,35):
                    if rng.random()>.4:
                        s+=f'<path d="M{x+15} {yy}h9v14h-9zm23 0h9v14h-9z" fill="{light}" opacity=".28"/>'
    elif scene==1:
        s+=f'<path d="M0 790Q450 570 910 790T1920 680V1080H0Z" fill="{mid}"/><path d="M0 900Q650 740 1080 920T1920 820V1080H0Z" fill="{ink}"/>'
        for x in range(0,2000,230):
            s+=f'<path d="M{x} 830V430m-60 40h120" fill="none" stroke="{ink}" stroke-width="8"/>'
        s+=f'<path d="M0 470Q960 680 1920 470" fill="none" stroke="{ink}" stroke-width="3"/>'
    elif scene==3:
        s+=f'<path d="M0 690h1920v390H0z" fill="{ink}" opacity=".7"/>'
        for j in range(75):
            x=rng.randrange(0,1900);y=rng.randrange(710,1060);w=rng.randrange(20,150)
            s+=f'<path d="M{x} {y}h{w}" stroke="{light}" stroke-width="2" opacity=".12"/>'
    else:
        for j in range(4):
            y=650+j*110;s+=f'<path d="M-100 1080V{y}Q320 {y-240} 650 {y}T1250 {y-80}T2000 {y+70}V1080Z" fill="{mid if j<2 else ink}" opacity="{.45+j*.18}"/>'
    if n<10:
        # Original anime-inspired character, different pose/hair/outfit per scene.
        x=1180+(n%3)*100; y=630; face='#f0cebd'; hair=['#1b1c32','#e1d5dc','#564761','#172d3b','#b28e9c'][n%5]
        s+=f'<g transform="translate({x} {y}) rotate({[-5,3,-2,5,0][n%5]})">'
        s+=f'<path d="M-84 0Q-110-145 0-155Q100-150 85 5L110 170L-95 165Z" fill="{hair}"/>'
        s+=f'<path d="M-58-72Q0-122 57-72L50-5Q30 45 0 52Q-38 38-51-8Z" fill="{face}"/>'
        s+=f'<path d="M-82-35Q-90-175 10-158Q108-145 80-30L48-102L25-52L5-104L-23-55L-40-105Z" fill="{hair}"/>'
        for ex in (-28,29):
            s+=f'<path d="M{ex-14} -12q14-12 28 0q-12 16-28 0" fill="{ink}"/><ellipse cx="{ex+2}" cy="-9" rx="6" ry="8" fill="{light}"/><circle cx="{ex+3}" cy="-13" r="2" fill="white"/>'
        s+=f'<path d="M-8 27q9 5 17-1" fill="none" stroke="#a36d75" stroke-width="2"/>'
        s+=f'<path d="M-18 44v25l-70 25-49 202 63 10 29-120-10 260h150L44 183l37 120 56-20-58-188-62-26V44" fill="{mid}" stroke="{ink}" stroke-width="5"/>'
        s+=f'<path d="M-45 84L0 130l42-46M0 130V420" fill="none" stroke="{light}" stroke-width="6" opacity=".6"/>'
        if n%2==0:s+=f'<path d="M-70 73Q0 100 90 67L70 113Q0 139-77 107Z" fill="{light}" opacity=".85"/>'
        if n%3==0:s+=f'<path d="M-140 300h60v80h-60z" fill="{light}" opacity=".8"/><path d="M-136 300q26-45 50 0" fill="none" stroke="{light}" stroke-width="3"/>'
        s+='</g>'
    else:
        # Architecture/foliage changes the silhouette, not merely the palette.
        if n%3==0:
            s+=f'<path d="M960 760V420h210v340m-290-360h370l-55-50H935Z" fill="{ink}"/><circle cx="1060" cy="490" r="42" fill="{light}" opacity=".65"/>'
        elif n%3==1:
            s+=f'<path d="M760 1080L1190 620h150l460 460" fill="none" stroke="{light}" stroke-width="7" opacity=".28"/>'
        else:
            for j in range(18):
                x=750+j*65;y=530+int(math.sin(j*.35)*100)
                s+=f'<path d="M{x} {y}v330" stroke="{ink}" stroke-width="6"/><ellipse cx="{x}" cy="{y+85}" rx="19" ry="32" fill="{light}" opacity=".7"/>'
    s+=f'<path d="M0 1035Q900 1000 1920 1045V1080H0Z" fill="{ink}"/>'
    save('anime',n+1,title,s)

for n in range(8):
    sky,light,mid,ink=palettes[n%5];rng=random.Random(120+n)
    s=f'<defs><radialGradient id="b"><stop stop-color="{mid}"/><stop offset="1" stop-color="{ink}"/></radialGradient><linearGradient id="a"><stop stop-color="{light}"/><stop offset="1" stop-color="{sky}"/></linearGradient></defs><path fill="url(#b)" d="M0 0h1920v1080H0z"/>'
    if n%4==0:
        for j in range(26):
            x=300+j*46;s+=f'<path d="M{x} -120C{x+700} 280 {x-650} 800 {x+200} 1200" stroke="url(#a)" stroke-width="22" fill="none" opacity="{.25+j*.025}"/>'
    elif n%4==1:
        for j in range(18):
            x=rng.randrange(-200,1700);y=rng.randrange(-150,900);r=rng.randrange(90,330)
            s+=f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#a)" opacity=".18"/><circle cx="{x}" cy="{y}" r="{r-7}" fill="none" stroke="{light}" opacity=".35"/>'
    elif n%4==2:
        for j in range(20):
            x=j*110;s+=f'<path d="M{x} 850L{x+190} 200l80 30-190 650Z" fill="url(#a)" opacity="{.3+(j%5)*.1}"/>'
    else:
        for j in range(35):
            r=20+j*21;s+=f'<ellipse cx="1100" cy="540" rx="{r}" ry="{r*.7}" fill="none" stroke="{light}" opacity="{.12+(j%7)*.045}" stroke-width="3" transform="rotate({j*3} 1100 540)"/>'
    save('abstract',13+n,['Silk current','Orbital glass','Prismatic corridor','Resonance','Violet tide','Glass planets','Golden prisms','Quiet orbit'][n],s)
(ROOT/'catalog.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
