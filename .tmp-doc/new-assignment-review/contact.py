from PIL import Image, ImageDraw
from pathlib import Path
fs=sorted(Path('.tmp-doc/new-assignment-review').glob('final-*.png'))
W,H=500,650
for k in range(0,len(fs),4):
    chunk=fs[k:k+4]
    out=Image.new('RGB',(W*2,H*2),(210,210,210))
    for i,p in enumerate(chunk):
        im=Image.open(p).convert('RGB'); im.thumbnail((W-20,H-32))
        x=(i%2)*W+(W-im.width)//2; y=(i//2)*H+24
        out.paste(im,(x,y)); ImageDraw.Draw(out).text(((i%2)*W+8,(i//2)*H+5),p.name,fill='black')
    out.save(f'.tmp-doc/new-assignment-review/contact-final-{k//4+1}.png')
