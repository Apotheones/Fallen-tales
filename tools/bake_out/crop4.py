#!/usr/bin/env python3
"""Recorta uma região de um PNG (8/4-bit, RGB/RGBA/indexed) e grava
ampliada (nearest). Uso: python tools/bake_out/crop4.py <img> <x> <y> <w> <h> <zoom> <out>"""
import struct, sys, zlib


def decode(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    pos, idat, w, h, depth, ctype, plte, trns = 8, b'', 0, 0, 8, 6, None, None
    while pos < len(data):
        ln, typ = struct.unpack('>I4s', data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + ln]
        if typ == b'IHDR':
            w, h, depth, ctype = struct.unpack('>IIBB', chunk[:10])[:4]
        elif typ == b'PLTE':
            plte = chunk
        elif typ == b'tRNS':
            trns = chunk
        elif typ == b'IDAT':
            idat += chunk
        pos += 12 + ln
    raw = zlib.decompress(idat)
    if ctype == 3:
        ch = 1
    else:
        ch = {0: 1, 2: 3, 4: 2, 6: 4}[ctype]
    assert depth in (1, 2, 4, 8), 'only 1/2/4/8-bit'
    pixels = []  # rgba rows
    if depth < 8:
        stride = (w * depth + 7) // 8
    else:
        stride = w * ch
    p = 0
    prev = bytearray(stride)
    out = []
    for y in range(h):
        f = raw[p]; p += 1
        line = bytearray(raw[p:p + stride]); p += stride
        bpp = 1  # bytes per pixel for filtering (depth4/ctype3 = 1 byte)
        bpp = ch if depth == 8 else 1
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        prev = line
        # unpack row to rgba
        row = []
        if ctype == 3:
            for x in range(w):
                if depth < 8:
                    byte = line[(x * depth) // 8]
                    sh = 8 - depth - (x * depth) % 8
                    idx = (byte >> sh) & ((1 << depth) - 1)
                else:
                    idx = line[x]
                r, g, b = plte[idx * 3:idx * 3 + 3]
                a = trns[idx] if trns and idx < len(trns) else 255
                row.append((r, g, b, a))
        elif ctype == 6:
            for x in range(w):
                i = x * 4
                row.append(tuple(line[i:i + 4]))
        else:
            for x in range(w):
                i = x * ch
                v = line[i:i + ch]
                row.append((v[0], v[0], v[0], v[1] if ch > 1 else 255))
        out.append(row)
    return w, h, out


def encode(w, h, rows, path):
    raw = b''
    for row in rows:
        raw += b'\x00' + b''.join(bytes(px) for px in row)
    comp = zlib.compress(raw, 9)

    def chunk(typ, payload):
        c = struct.pack('>I', len(payload)) + typ + payload
        return c + struct.pack('>I', zlib.crc32(typ + payload) & 0xFFFFFFFF)

    ihdr = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
    png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr)
           + chunk(b'IDAT', comp) + chunk(b'IEND', b''))
    open(path, 'wb').write(png)


def main():
    img, x, y, w, h, zoom, out = (sys.argv[1], int(sys.argv[2]),
        int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]),
        int(sys.argv[6]), sys.argv[7])
    iw, ih, rows = decode(img)
    x2, y2 = min(x + w, iw), min(y + h, ih)
    crop = [r[x:x2] for r in rows[y:y2]]
    big = []
    for row in crop:
        zrow = [px for px in row for _ in range(zoom)]
        for _ in range(zoom):
            big.append(list(zrow))
    encode(len(big[0]), len(big), big, out)
    print(out)


main()
