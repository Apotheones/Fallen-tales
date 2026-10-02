"""Render the original Arrowfallen score using only Python's standard library."""
from array import array
from functools import lru_cache
from pathlib import Path
import math
import random
import sys
import wave

RATE = 22050
TAU = 2 * math.pi


@lru_cache(maxsize=256)
def voice(note, seconds, instrument):
    frequency = 440 * 2 ** ((note - 69) / 12)
    noise = random.Random(113 + note)
    samples = array('f')
    for i in range(round(seconds * RATE)):
        t = i / RATE
        attack = min(1, t / (.18 if instrument == 'pad' else .008))
        release = min(1, (seconds - t) / (.35 if instrument == 'pad' else .08))
        phase = TAU * frequency * t
        if instrument == 'pad':
            sound = (math.sin(phase) + .3 * math.sin(phase * 1.002)
                     + .12 * math.sin(phase * 2)) * .5
        elif instrument == 'harp':
            sound = (math.sin(phase) + .32 * math.sin(phase * 2)
                     + .13 * math.sin(phase * 3)) * math.exp(-t * 3.5)
        elif instrument == 'lead':
            sound = (math.sin(phase + .025 * math.sin(TAU * 5 * t))
                     + .14 * math.sin(phase * 2)) * math.exp(-t * .9)
        elif instrument == 'bass':
            sound = (math.sin(phase) + .18 * math.sin(phase * 2)) * math.exp(-t * 2)
        elif instrument == 'brass':
            sound = (math.sin(phase) + .4 * math.sin(phase * 2)
                     + .2 * math.sin(phase * 3)) * math.exp(-t * 1.8)
        elif instrument == 'bell':
            sound = (math.sin(phase) + .3 * math.sin(phase * 2.76)
                     * math.exp(-t * 4)) * math.exp(-t * 2.5)
        elif instrument == 'kick':
            sound = math.sin(TAU * (46 * t + 7 * (1 - math.exp(-t * 25)))) * math.exp(-t * 12)
        elif instrument == 'snare':
            sound = (noise.uniform(-1, 1) * .7 + math.sin(TAU * 170 * t) * .3) * math.exp(-t * 22)
        else:  # Quiet shaker between the drum beats.
            sound = noise.uniform(-1, 1) * math.exp(-t * 65)
        samples.append(sound * attack * release)
    return samples


def compose(theme, bpm, bars):
    beat = 60 / bpm
    frames = round(bars * 4 * beat * RATE)
    left, right = array('f', [0]) * frames, array('f', [0]) * frames

    def add(position_beat, note, length, instrument, gain, pan=0, echo=False):
        samples = voice(note, length * beat, instrument)
        for delay, level, position in ((0, 1, pan), (.75, .23, -pan), (1.5, .09, pan)) if echo else ((0, 1, pan),):
            start = round((position_beat + delay) * beat * RATE)
            lg, rg = gain * level * math.sqrt((1 - position) / 2), gain * level * math.sqrt((1 + position) / 2)
            for i, sample in enumerate(samples):
                index = (start + i) % frames  # Tails wrap into the start of the loop.
                left[index] += sample * lg
                right[index] += sample * rg

    # D minor / Bb / F / C, then D minor / G minor / Bb / A major.
    harmony = [(50, 57, 62, 65), (46, 53, 58, 62), (41, 53, 57, 60), (48, 55, 60, 64),
               (50, 57, 62, 65), (43, 55, 58, 62), (46, 53, 58, 62), (45, 57, 61, 64)]
    motifs = [((0, 74, 1), (1.5, 77, .5), (2, 76, 1), (3, 69, .75)),
              ((.5, 70, 1), (2, 74, 1.5)),
              ((0, 72, 1.5), (2, 69, .75), (3, 65, .75)),
              ((0, 67, 1), (1.5, 72, .5), (2.5, 76, 1)),
              ((0, 77, 1), (1, 81, .75), (2, 79, 1), (3, 77, .75)),
              ((.5, 79, 1), (2, 77, .75), (3, 74, .75)),
              ((0, 77, 1.5), (2, 74, 1), (3, 70, .75)),
              ((0, 73, 1), (1.5, 76, .5), (2, 73, 1), (3, 69, .75))]
    if theme == 'warden':
        harmony = [(38, 50, 53, 57), (39, 51, 55, 58), (46, 53, 58, 62), (45, 52, 57, 61)] * 2
        motifs = [((0, 62, .5), (.75, 62, .5), (1.5, 69, .75), (2.5, 65, .5), (3.25, 64, .5)),
                  ((0, 63, 1), (1.5, 70, .5), (2.5, 67, 1)),
                  ((0, 70, .5), (1, 74, .5), (2, 77, .75), (3, 74, .75)),
                  ((0, 73, .75), (1, 69, .5), (2, 64, .75), (3, 61, .75))] * 2
    elif theme == 'breaker':
        harmony = [(50, 57, 62, 65), (50, 57, 60, 64), (46, 53, 58, 62), (45, 52, 57, 61)] * 2
        motifs = [((0, 62, .4), (.75, 65, .4), (1.5, 69, .4), (2.5, 65, .8)),
                  ((0, 64, .4), (.75, 67, .4), (1.5, 69, .4), (3, 64, .6)),
                  ((.5, 65, .5), (1.5, 70, .5), (2.5, 74, .9)),
                  ((0, 73, .5), (1, 69, .5), (2, 64, .5), (3, 61, .5))] * 2
    elif theme == 'demolisher':
        harmony = [(38, 50, 53, 57), (38, 50, 54, 57), (34, 46, 50, 53), (33, 45, 49, 52)] * 2
        motifs = [((0, 50, 1.2), (2, 57, .6), (3, 53, .6)),
                  ((0, 54, .6), (1.5, 57, .6), (3, 50, .7)),
                  ((0, 58, 1), (1.5, 53, .5), (2.5, 50, 1)),
                  ((0, 57, .6), (1, 52, .6), (2, 49, 1.5))] * 2
    elif theme == 'regent':
        harmony = [(50, 57, 62, 65), (49, 56, 61, 65), (46, 53, 58, 62), (45, 57, 61, 64),
                   (43, 55, 58, 62), (46, 53, 58, 65), (49, 56, 61, 65), (45, 57, 61, 64)]
        motifs = [((0, 81, 1.2), (1.5, 77, .6), (3, 74, .8)),
                  ((.5, 80, 1), (2, 77, .7), (3, 73, .7)),
                  ((0, 82, .7), (1, 77, .7), (2.5, 74, 1.2)),
                  ((0, 81, .5), (1, 76, .5), (2, 73, 1.6)),
                  ((.5, 79, .8), (2, 77, .5), (3, 74, .7)),
                  ((0, 77, .6), (1.5, 82, .6), (2.5, 86, 1)),
                  ((0, 85, 1), (1.5, 80, .6), (3, 77, .6)),
                  ((0, 81, .7), (1.5, 76, .5), (2.5, 73, 1.2))]
    elif theme == 'veteran':
        harmony = [(50, 57, 62, 65), (48, 55, 60, 64), (46, 53, 58, 62), (45, 52, 57, 61)] * 2
        # Paired notes answer each other, followed by an opening to approach.
        motifs = [((0, 74, .4), (.5, 77, .4), (2, 69, .4), (2.5, 74, .4)),
                  ((0, 72, .4), (.5, 76, .4), (2, 67, .4), (2.5, 72, .4)),
                  ((0, 70, .4), (.5, 74, .4), (2, 65, .4), (2.5, 70, .4)),
                  ((0, 73, .4), (.5, 76, .4), (2, 69, .4), (2.5, 73, .4))] * 2
    elif theme in ('challenge_targets', 'challenge_combat'):
        harmony = [(50, 57, 62, 65), (48, 55, 60, 64), (43, 55, 58, 62), (45, 57, 61, 64)] * 2
        motifs = [((0, 74, .5), (1, 77, .5), (2, 81, .5), (3, 77, .5)),
                  ((.5, 79, .5), (1.5, 76, .5), (2.5, 72, 1)),
                  ((0, 74, .5), (.75, 79, .5), (1.5, 77, .5), (2.5, 74, 1)),
                  ((0, 73, .5), (1, 76, .5), (2, 81, .5), (3, 73, .5))] * 2
        if theme == 'challenge_combat':
            harmony = [(50, 57, 62, 65), (46, 53, 58, 62), (43, 55, 58, 62), (45, 52, 57, 61)] * 2
            motifs = [((0, 62, .5), (.75, 69, .5), (1.5, 65, .5), (3, 74, .6)),
                      ((0, 65, .5), (1, 70, .5), (2.5, 74, .6)),
                      ((0, 67, .5), (.75, 74, .5), (2, 70, .5), (3, 67, .5)),
                      ((.5, 69, .5), (1.5, 73, .5), (2.5, 76, .8))] * 2
    # Opening, main theme, rising tension, return; encounters enter immediately.
    special = theme != 'chamber_of_echoes'
    for bar in range(bars):
        start, chord = bar * 4, harmony[bar % 8]
        energy = (.8 if bar % 16 < 8 else 1) if special else (.65 if bar < 8 or bar >= 28 else 1)
        for note in chord[1:]:
            add(start, note, 4.4, 'pad', .075, (note % 3 - 1) * .4)
        add(start, chord[0] - 12, 2, 'bass', .19 * energy)
        add(start + 2.5, chord[0], 1.4, 'bass', .12 * energy)
        pattern = (0, 0, 2, 0, 1, 0, 2, 1) if theme in ('warden', 'demolisher', 'breaker') else (0, 1, 2, 1, 0, 2, 1, 2)
        for step, degree in enumerate(pattern):
            add(start + step * .5, chord[degree + 1] + (0 if theme in ('warden', 'demolisher', 'breaker') else 12), 1.4,
                'bell' if theme in ('challenge_targets', 'regent', 'veteran') else 'harp',
                (.075 if step % 2 else .10) * energy, -.35 if step % 2 else .35, True)
        if special or bar >= 4:
            for offset, note, length in motifs[bar % 8]:
                # First statement low, middle section high, final phrase resolves low.
                note -= 12 if not special and (bar < 8 or bar >= 24) else 0
                instrument = 'brass' if theme in ('warden', 'demolisher', 'breaker') else 'lead'
                add(start + offset, note, length + .2, instrument,
                    .15 * energy, .12, True)
        if theme == 'regent' and bar % 4 == 3:
            # High echo answers the lead like a summoned voice.
            add(start + 3, chord[2] + 24, 2.2, 'bell', .08, -.5, True)
        if special or 8 <= bar < 28:
            kicks = (0, 1.5, 2, 3.5) if theme == 'warden' else (0, 2)
            if theme == 'demolisher':
                kicks = (0, .5, 2.5) if bar % 2 else (0, 2)
            for offset in kicks:
                add(start + offset, 36, .6, 'kick', .18)
            add(start + 2, 38, .4, 'snare', .065, -.15)
            for step in range(8):
                add(start + step * .5, 42, .15, 'shaker', .027, .4)
            if theme in ('breaker', 'challenge_combat') or (not special and 16 <= bar < 24):
                add(start + 3.5, 36, .4, 'kick', .10)
            if theme == 'challenge_targets':
                add(start + 1.5, 38, .3, 'snare', .045, .2)
            if theme == 'veteran':
                add(start + 2.5, 38, .25, 'snare', .065, .2)

    peak = max(max(map(abs, left)), max(map(abs, right)))
    assert 0 < peak < 2, 'Unexpected mix level'
    scale = .78 / peak
    pcm = array('h')
    for i, (l, r) in enumerate(zip(left, right)):
        # A tiny fade removes boundary clicks without a noticeable musical gap.
        fade = min(1, i / (RATE * .012), (frames - 1 - i) / (RATE * .012))
        pcm.extend((round(l * scale * fade * 32767), round(r * scale * fade * 32767)))
    assert len(pcm) == frames * 2 and max(map(abs, pcm)) <= 32767
    assert pcm[0] == pcm[1] == pcm[-1] == pcm[-2] == 0
    if sys.byteorder != 'little':
        pcm.byteswap()
    path = Path(__file__).resolve().parents[1] / f'assets/audio/{theme}.wav'
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as output:
        output.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())
    with wave.open(str(path)) as check:
        assert check.getnframes() == frames and check.getnchannels() == 2
    print(f'{path}\n{frames / RATE:.1f}s, {bpm} BPM, stereo; audio checks passed.', flush=True)


if __name__ == '__main__':
    for theme, bpm, bars in [('chamber_of_echoes', 80, 32), ('warden', 120, 32),
                             ('demolisher', 104, 32), ('regent', 96, 32),
                             ('breaker', 108, 24), ('veteran', 116, 24),
                             ('challenge_combat', 112, 24), ('challenge_targets', 104, 24)]:
        compose(theme, bpm, bars)
