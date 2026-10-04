#!/usr/bin/env python3
"""Recorta uma região de um PNG e grava ampliada (nearest).
Uso: python tools/crop.py <img> <x> <y> <w> <h> <zoom> <out>"""
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
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                q = a + b - c
                pa, pb, pc = abs(q - a), abs(q - b), abs(q - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        out[y * stride:(y + 1) * stride] = line
        prev = bytes(line)
    return w, h, ch, plte, bytes(out)


def px(w, ch, plte, raw, x, y):
    i = y * w * ch + x * ch
    if plte is not None:
        idx = raw[i]
        return tuple(plte[idx * 3:idx * 3 + 3]) + (255,)
    if ch == 4:
        return tuple(raw[i:i + 4])
    if ch == 3:
        return tuple(raw[i:i + 3]) + (255,)
    v = raw[i]
    return (v, v, v, 255)


def encode_rgba(w, h, raw):
    rows = b''.join(b'\x00' + raw[y * w * 4:(y + 1) * w * 4] for y in range(h))
    def chunk(t, d):
        c = struct.pack('>I', len(d)) + t + d
        return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


def main():
    img, x, y, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
    zoom, out = int(sys.argv[6]) if len(sys.argv) > 6 else 3, sys.argv[7] if len(sys.argv) > 7 else 'screenshots/crop.png'
    iw, ih, ch, plte, raw = decode(img)
    ow, oh = w * zoom, h * zoom
    buf = bytearray(ow * oh * 4)
    for j in range(h):
        for i in range(w):
            c = px(iw, ch, plte, raw, x + i, y + j)
            for sj in range(zoom):
                base = ((j * zoom + sj) * ow + i * zoom) * 4
                for si in range(zoom):
                    buf[base + si * 4:base + si * 4 + 4] = bytes(c)
    open(out, 'wb').write(encode_rgba(ow, oh, bytes(buf)))
    print(out)


if __name__ == '__main__':
    main()
