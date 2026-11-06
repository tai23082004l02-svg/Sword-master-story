#!/usr/bin/env python3
"""Extract existing sprite pixels into isolated, anchored frames; no generated repaint.
Dev-only dependencies: Pillow, numpy, scipy. Runtime uses only the exported PNG/tres.
"""
from pathlib import Path
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import label, find_objects, distance_transform_edt
ROOT = Path(__file__).resolve().parents[1]
SOURCES = {'aether':'assets/hero/aether_sheet.png', **{n:f'assets/party/{n}_sheet.png' for n in ('brann','lyra','nyx','sol')}, 'hollows':'assets/enemies/hollows_sheet.png','eclipse':'assets/boss/eclipse_knight.png'}

def extract(name, relative):
    src = np.array(Image.open(ROOT / relative).convert('RGBA'))
    folder = ROOT / 'assets/frames' / name
    folder.mkdir(parents=True, exist_ok=True)
    records=[]
    offsets=[]
    montage=Image.new('RGB',(1152,768),'#172c39')
    alpha=src[:,:,3]
    labels,_=label(alpha>=100)
    sizes=np.bincount(labels.ravel())
    owners=np.zeros_like(labels)
    grid_y,grid_x=np.indices(labels.shape)
    for k,box in enumerate(find_objects(labels),1):
        if sizes[k]<5000:
            continue
        ys,xs=box
        row=int(np.clip(round(((ys.start+ys.stop)/2-128)/256),0,3))
        spans=[(xs.start,xs.stop)]
        if xs.stop-xs.start>380:
            # Two boss spell poses share a glow; use the reviewed least-
            # occupied seam, retaining both bodies and recording the limit.
            midpoint=(xs.start+xs.stop)//2
            seam=min(range(midpoint-35,midpoint+36),key=lambda x:int(np.sum(alpha[ys,x]>=160)))
            if name == "eclipse": seam = 740
            spans=[(xs.start,seam),(seam,xs.stop)]
        for lo,hi in spans:
            col=int(np.clip(round(((lo+hi)/2-128)/256),0,5))
            owners[(labels==k)&(grid_x>=lo)&(grid_x<hi)]=row*6+col+1
    assert set(np.unique(owners))==set(range(25)), (name,'missing body seed')
    body_owners=owners.copy()
    # Keep detached objects whole and in the same source row as their center.
    # This stops a bow tip just below a row boundary attaching to the feet above.
    row_maps=[]
    for r in range(4):
        selected=(owners>r*6)&(owners<=(r+1)*6)
        _,nearest=distance_transform_edt(~selected,return_indices=True)
        row_maps.append(owners[tuple(nearest)])
    for k,box in enumerate(find_objects(labels),1):
        if sizes[k]<20 or sizes[k]>=5000:
            continue
        ys,xs=box
        row=int(np.clip(((ys.start+ys.stop)/2)//256,0,3))
        component=labels==k
        votes=row_maps[row][component]
        owner=int(np.bincount(votes,minlength=25).argmax())
        owners[component]=owner
    distances,indices=distance_transform_edt(owners==0,return_indices=True)
    assigned=owners[tuple(indices)]
    if name=='lyra':
        assigned[512:672,1208:1288]=17  # normal arrow follows firing pose16
        assigned[768:928,640:778]=21    # skill arrow follows pose20, not hurt21
    if name=='nyx':
        assigned[768:900,730:781]=21  # recovery spell motes belong to skill20
    islands,_=label(alpha>20)
    island_sizes=np.bincount(islands.ravel())
    clean=(island_sizes[islands]>=20)|(distances<12)
    for n in range(24):
        row,col=divmod(n,6)
        mask=(assigned==n+1)&(alpha>20)&((alpha>=80)|(distances<28))&clean
        core=body_owners==n+1
        yy,xx=np.where(core)
        lower=xx[yy>=max(row*256+170,int(yy.max())-32)]
        anchor_x=int(np.median(lower if len(lower) else xx))
        isolated=np.zeros((384,512,4),dtype=np.uint8)
        sy,sx=np.where(mask)
        dx=sx-anchor_x+256
        dy=sy-row*256+48
        assert np.all((dx>=8)&(dx<504)&(dy>=8)&(dy<376)), (name,n,'needs larger canvas',int(dx.min()),int(dx.max()),int(dy.min()),int(dy.max()))
        pixels=src[sy,sx].copy()
        if name=='eclipse' and n in (14,15):
            # The two spell glows were painted together in the source. Fade
            # only violet light at the reviewed seam, never armor/cape pixels.
            rgb=pixels[:,:3].astype(float)
            glow=(rgb[:,2]>110)&(rgb[:,2]>rgb[:,1]*1.25)&(rgb[:,2]>rgb[:,0]*0.9)
            taper=np.clip((740-sx)/12 if n==14 else (sx-740)/12,0,1)
            pixels[glow,3]=(pixels[glow,3]*taper[glow]).astype(np.uint8)
        isolated[dy,dx]=pixels
        left,top,right,bottom=int(dx.min()),int(dy.min()),int(dx.max()+1),int(dy.max()+1)
        cropped=isolated[top-8:bottom+8,left-8:right+8]
        path=folder/f'{n:02d}.png'
        Image.fromarray(cropped).save(path)
        offsets.append([left-8-256,top-8-272])
        records.append({'index':n,'file':path.name,'source_row':row,'source_anchor':[anchor_x,row*256+224], 'visible_pixels':int(np.count_nonzero(cropped[:,:,3])),'draw_offset':offsets[-1],'size':[cropped.shape[1],cropped.shape[0]]})
        tile=Image.fromarray(isolated).resize((192,120))
        montage.paste(tile,(col*192,row*192),tile)
        ImageDraw.Draw(montage).text((col*192+8,row*192+162),f'{n:02d}',fill='white')
    frames='[gd_resource type="SpriteFrames" load_steps=25 format=3]\n\n'
    for i in range(24):
        frames+=f'[ext_resource type="Texture2D" path="res://assets/frames/{name}/{i:02d}.png" id="{i+1}"]\n'
    entries=',\n'.join(f'{{"duration": 1.0, "texture": ExtResource("{i+1}")}}' for i in range(24))
    frames+='\n[resource]\nanimations = [{"frames": ['+entries+'], "loop": false, "name": &"frames", "speed": 10.0}]\n'
    frames+='metadata/draw_offsets = PackedVector2Array('+', '.join(str(v) for point in offsets for v in point)+')\n'
    (folder/'frames.tres').write_text(frames)
    manifest={'source':relative,'source_sha256':hashlib.sha256((ROOT/relative).read_bytes()).hexdigest(),'logical_canvas':[512,384],'logical_anchor':[256,272],'padding':8,'reviewed_projectile_ownership':name=='lyra','method':'alpha silhouette ownership; whole 2D components retained across nominal column AND row borders, nearest silhouette for disconnected particles; documented vertical seam for merged boss spell glow','frames':records}
    if name=='eclipse':
        manifest['overlap_note']='Reviewed seam x=740 between poses14/15; violet-light alpha tapers12px at seam, armor pixels unchanged.'
    if name=='nyx':
        manifest['overlap_note']='Recovery motes at source rect730,768,51,132 assigned to skill20.'
    (folder/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    audit=ROOT/'work/frame_audit'
    audit.mkdir(parents=True,exist_ok=True)
    montage.save(audit/f'{name}.png')

if __name__=='__main__':
    for name,relative in SOURCES.items():
        extract(name,relative)
        print('Extracted',name)
