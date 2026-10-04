#!/usr/bin/env python3
"""Diff de dois PNGs (8-bit, RGB/RGBA, sem interlace): reporta bbox e
contagem de pixels diferentes. Uso: python tools/pngdiff.py a.png b.png"""
import struct, sys, zlib


def decode(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    pos, idat, w, h, depth, ctype, plte = 8, b'', 0, 0, 8, 6, None
    while pos < len(data):
        ln, typ = struct.unpack('>I4s', data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + ln]
        if typ == b'IHDR':
            w, h, depth, ctype = struct.unpack('>IIBB', chunk[:10])
        elif typ == b'PLTE':
            plte = chunk
        elif typ == b'IDAT':
            idat += chunk
        pos += 12 + ln
    ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    assert depth == 8, 'only 8-bit'
    raw = zlib.decompress(idat)
    stride = w * ch
    out = bytearray(h * stride)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        f = raw[p]; p += 1
        line = bytearray(raw[p:p + stride]); p += stride
        for i in range(stride):
            a = line[i - ch] if i >= ch else 0
            b = prev[i]
            c = prev[i - ch] if i >= ch else 0
            if f == 1: line[i] = (line[i] + a) & 255
            elif f == 2: line[i] = (line[i] + b) & 255
            elif f == 3: line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                q = a + b - c
                pa, pb, pc = abs(q - a), abs(q - b), abs(q - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc
                                      else b if pb <= pc else c)) & 255
        out[y * stride:(y + 1) * stride] = line
        prev = line
    if ctype == 3:
        rgb = bytearray(w * h * 3)
        for i, idx in enumerate(out):
            rgb[i * 3:i * 3 + 3] = plte[idx * 3:idx * 3 + 3]
        return w, h, 3, rgb
    return w, h, ch, out


def main():
    wa, ha, ca, a = decode(sys.argv[1])
    wb, hb, cb, b = decode(sys.argv[2])
    assert (wa, ha, ca) == (wb, hb, cb), 'dimensoes/canais diferentes'
    n = 0
    minx, miny, maxx, maxy = wa, ha, -1, -1
    for y in range(ha):
        row = y * wa * ca
        for x in range(wa):
            o = row + x * ca
            if a[o:o + 3] != b[o:o + 3]:
                n += 1
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    if n == 0:
        print('IDENTICOS')
    else:
        print(f'{n} px diferentes · bbox ({minx},{miny})..({maxx},{maxy})')


if __name__ == '__main__':
    main()
