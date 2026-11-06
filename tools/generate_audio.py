"""Original synthetic prototype cues; Python standard library only."""
import math, random, struct, wave
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'audio'
root.mkdir(exist_ok=True)
for name, frequency, duration in [('hit', 160, .09), ('skill', 530, .3), ('wave', 330, .15), ('win', 660, .4), ('lose', 130, .4)]:
    rng = random.Random(name)
    with wave.open(str(root / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, 22050, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', int(5000 * (1-i/(duration*22050))**2 * (math.sin(2*math.pi*frequency*i/22050)*.8 + rng.uniform(-.2,.2)))) for i in range(int(duration*22050))))
