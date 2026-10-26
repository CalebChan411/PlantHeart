"""Create original, silent demo footage. Development-only: Pillow and ffmpeg.

The app plays the bundled result; it does not need Python/ffmpeg installed.
This fictional marigold story illustrates a future photo-timelapse workflow.
"""
from pathlib import Path
import math
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'demo_growth'
OUT.mkdir(parents=True, exist_ok=True)
W, H, SCALE, FPS, SECONDS = 960, 540, 2, 24, 18
STAGES = [('DAY 00', 'A seed and a beginning'), ('DAY 04', 'Hello, little sprout'),
          ('DAY 10', 'Our first leaves'), ('DAY 18', 'Growing stronger'),
          ('DAY 28', 'A promise of a flower'), ('DAY 42', 'Our first bloom')]

def ease(x):
    x = max(0., min(1., x))
    return x*x*(3-2*x)

def frame(t):
    image = Image.new('RGB', (W*SCALE, H*SCALE), '#fffaf0')
    d = ImageDraw.Draw(image)
    def poly(points, fill): d.polygon([(round(x*SCALE), round(y*SCALE)) for x,y in points], fill=fill)
    def ellipse(box, fill): d.ellipse(tuple(round(v*SCALE) for v in box), fill=fill)
    def line(points, fill, width): d.line([(round(x*SCALE), round(y*SCALE)) for x,y in points], fill=fill, width=max(1, round(width*SCALE)))
    def text(x,y,value,size,color='#243c32'):
        font=ImageFont.truetype('DejaVuSans.ttf', size*SCALE)
        d.text((x*SCALE,y*SCALE),value,font=font,fill=color)
    stage = min(5, int(t/3))
    progress = t/SECONDS
    # Airy illustrated room, morning light and a wooden shelf.
    ellipse((670,35,1050,420),'#eef2df')
    ellipse((-150,150,190,510),'#f0f2e5')
    d.rounded_rectangle((738*SCALE,65*SCALE,895*SCALE,285*SCALE), radius=22*SCALE, fill='#e2eff0')
    line([(816,70),(816,280)],'#fffdf5',8);line([(742,172),(892,172)],'#fffdf5',8)
    ellipse((848,87,877,116),'#ffe5a4')
    d.rectangle((0,465*SCALE,W*SCALE,H*SCALE), fill='#ecddc7')
    line([(0,470),(960,470)],'#dbc6a7',3)
    text(44,34,'PLANT HEART  /  A GROWTH MEMOIR',16,'#377e43')
    text(44,68,'A little seed. A little sunshine.',29)
    text(44,121,'ILLUSTRATED DEMO',12,'#6f7e71')
    # Soil cutaway with seed; growth gently rises above the pot.
    ellipse((350,450,612,480),'#d2c5ac')
    poly([(365,366),(595,366),(572,466),(388,466)],'#ce9674')
    poly([(384,385),(576,385),(558,450),(402,450)],'#654d3d')
    for x,y in [(418,414),(554,404),(435,440),(524,426)]: ellipse((x,y,x+5,y+3),'#967459')
    seed_scale=1-ease((t-1)/3)*.55
    ellipse((480-8*seed_scale,404-4*seed_scale,480+8*seed_scale,404+4*seed_scale),'#cfb180')
    stem=ease((t-1.7)/10)
    top=365-185*stem
    sway=math.sin(t*1.5)*2*stem
    if stem>0:
        line([(480,406),(480,365),(480+sway,top)],'#427b46',5)
        for idx,(side,level) in enumerate([(-1,.25),(1,.30),(-1,.53),(1,.59),(-1,.75),(1,.79)]):
            growth=ease((t-(3+idx*1.2))/2)
            if growth<=0: continue
            cy=365-(365-top)*level
            length=(43+idx*2)*growth
            pts=[]
            for k in range(31):
                u=k/30
                pts.append((480+side*length*u,cy-length*.48*u-math.sin(u*math.pi)*length*.3))
            for k in range(30,-1,-1):
                u=k/30
                pts.append((480+side*length*u,cy-length*.48*u+math.sin(u*math.pi)*length*.24))
            poly(pts,'#568b4b' if side<0 else '#80a65b')
            line([(480,cy),(480+side*length*.93,cy-length*.48)],'#a3c47c',1)
    bud=ease((t-11)/2)
    bloom=ease((t-13)/3.5)
    if bud>0:
        ellipse((480+sway-10*bud,top-18*bud,480+sway+10*bud,top+6*bud),'#8ba457')
    if bloom>0:
        for ring in [1,.65]:
            for i in range(16):
                a=i*math.tau/16+(0 if ring==1 else .18)
                radius=29*bloom*ring
                cx=480+sway+math.cos(a)*radius
                cy=top-7+math.sin(a)*radius
                ellipse((cx-13*bloom,cy-16*bloom,cx+13*bloom,cy+16*bloom),'#eab343' if ring==1 else '#f8d46b')
        ellipse((480+sway-14*bloom,top-7-14*bloom,480+sway+14*bloom,top-7+14*bloom),'#ad7036')
        ellipse((480+sway-9*bloom,top-7-9*bloom,480+sway+9*bloom,top-7+9*bloom),'#cf9442')
    d.rounded_rectangle((352*SCALE,352*SCALE,608*SCALE,380*SCALE), radius=8*SCALE, fill='#e0ae89')
    # A small friendly pot and the stage caption.
    ellipse((447,391,453,397),'#5a4938');ellipse((506,391,512,397),'#5a4938')
    d.arc((465*SCALE,394*SCALE,495*SCALE,416*SCALE),0,180,fill='#5a4938',width=3*SCALE)
    text(44,381,STAGES[stage][0],16,'#377e43')
    text(44,410,STAGES[stage][1],18)
    text(44,493,'A fictional marigold story  |  six moments, forty-two days',15,'#665b4c')
    d.rectangle((44*SCALE,525*SCALE,916*SCALE,528*SCALE), fill='#d1bd9f')
    d.rectangle((44*SCALE,525*SCALE,(44+872*progress)*SCALE,528*SCALE), fill='#377e43')
    return image.resize((W,H),Image.Resampling.LANCZOS)

if __name__ == '__main__':
    process=subprocess.Popen(['ffmpeg','-y','-loglevel','error','-f','rawvideo','-vcodec','rawvideo',
        '-s',f'{W}x{H}','-pix_fmt','rgb24','-r',str(FPS),'-i','-','-an','-c:v','libx264',
        '-profile:v','baseline','-level','3.1','-preset','medium','-crf','23','-pix_fmt','yuv420p',
        '-movflags','+faststart',str(OUT/'seed_to_bloom.mp4')],stdin=subprocess.PIPE)
    try:
        for i in range(FPS*SECONDS): process.stdin.write(frame(i/FPS).tobytes())
    finally:
        process.stdin.close()
    if process.wait()!=0: raise SystemExit('ffmpeg encoding failed')
    for i in range(6): frame(min(17.8,i*3+2.7)).save(OUT/f'stage_{i}.png',optimize=True)
    print('Created 18-second H.264 demo and six checkpoint illustrations.')
