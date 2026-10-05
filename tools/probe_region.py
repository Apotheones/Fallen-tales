#!/usr/bin/env python3
"""Probe de alcançabilidade para regiões autorais do ARROWFALLEN.

Replica Region.build + Region.reachable (src/region.lua) sobre o arquivo da
região e reporta cobertura do spawn: hotspots (por célula no range), NPCs,
encontros e frentes de portais. Uso:

    python tools/probe_region.py reservatorio [sx sy]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def num(body, key, default=None):
    m = re.search(rf"{key}\s*=\s*(-?\d+)", body)
    return int(m.group(1)) if m else default


def parse_region(path):
    text = path.read_text(encoding="utf-8")
    # Células geradas por loops (reservatorio usa loops pros canais): cada
    # `for y = A, B do for x = C, D` com um filtro `seco` opcional.
    holes = []
    for m in re.finditer(
        r"for y = (\d+), (\d+) do\s+for x = (\d+), (\d+) do\s*(.*?)holes\[#holes \+ 1\] = \{x = x, y = y\}",
        text, re.S,
    ):
        y0, y1, x0, x1, body = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4)), m.group(5)
        seco = re.search(r"local seco = (.*)", body)
        expr = seco.group(1).strip() if seco else None
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if expr:
                    e = expr
                    e = re.sub(r"x >= (\d+) and x <= (\d+)", lambda mm: str(int(mm.group(1)) <= x <= int(mm.group(2))), e)
                    e = e.replace("x ==", "x ==").replace("y ==", "y ==")
                    e = re.sub(r"x == (\d+)", lambda mm: str(x == int(mm.group(1))), e)
                    e = re.sub(r"y == (\d+)", lambda mm: str(y == int(mm.group(1))), e)
                    e = e.replace(" and ", " and ").replace(" or ", " or ")
                    e = e.replace("true", "True").replace("false", "False")
                    if eval(e):
                        continue
                holes.append((x, y))
    data = {"holes": holes}

    # Seções são tabelas Lua aninhadas — regex de um nível quebrava em
    # entries com sub-tabelas próprias (ex.: npc.posts = {{...},{...}})
    # ou formatação fora do padrão. Extrai o bloco casando chaves e
    # splita só as entradas de nível mais externo.
    def extract_table(key):
        m = re.search(rf"{key}\s*=\s*\{{", text)
        if not m:
            return None
        depth = 0
        for j in range(m.end() - 1, len(text)):
            if text[j] == '{':
                depth += 1
            elif text[j] == '}':
                depth -= 1
                if depth == 0:
                    return text[m.end():j]
        return None

    def split_entries(body):
        out, depth, start = [], 0, -1
        for i, ch in enumerate(body):
            if ch == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0 and start >= 0:
                    out.append(body[start + 1:i])
        return out

    for section in ("carve", "walls", "pillars", "props", "npcs", "hotspots", "exits", "encounters"):
        entries = []
        body = extract_table(section)
        if body:
            for b in split_entries(body):
                if "x" not in b and "id" not in b:
                    continue
                entries.append(b)
        data[section] = entries
    m = re.search(r"spawn = \{x = (\d+), y = (\d+)\}", text)
    data["spawn"] = (int(m.group(1)), int(m.group(2)))
    return data


def main():
    rid = sys.argv[1] if len(sys.argv) > 1 else "reservatorio"
    path = ROOT / "src" / "regions" / f"{rid}.lua"
    d = parse_region(path)
    tiles = {}

    def put(x, y, piece=None, ground=None):
        c = tiles.setdefault((x, y), {})
        if ground:
            c["ground"] = ground
        if piece:
            c["piece"] = piece
        return c

    for b in d["carve"]:
        x, y, w, h = num(b, "x"), num(b, "y"), num(b, "w"), num(b, "h")
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                tiles.setdefault((xx, yy), {})["ground"] = "floor"
    for x, y in d["holes"]:
        c = put(x, y, ground="hole")
        c.pop("piece", None)
    for b in d["pillars"]:
        put(num(b, "x"), num(b, "y"), "pillar", "floor")
    for b in d["walls"]:
        put(num(b, "x"), num(b, "y"), "wall", "floor")

    exits = []
    for b in d["exits"]:
        x, y = num(b, "x"), num(b, "y")
        closed = "open = false" in b
        put(x, y, "portal", "floor")
        mto = re.search(r"to = '(\w+)'", b)
        exits.append({"x": x, "y": y, "closed": closed,
                      "to": mto.group(1) if mto else "?"})

    solid = {}
    for b in d["props"]:
        x, y = num(b, "x"), num(b, "y")
        w, h = num(b, "w", 1), num(b, "h", 1)
        mid = re.search(r"id = '(\w+)'", b)
        if "solid = true" in b and mid:
            for yy in range(y, y + h):
                for xx in range(x, x + w):
                    solid[(xx, yy)] = mid.group(1)
    # --taken=propId simula o estado pós-interação (setProp 'taken'): as
    # células sólidas do prop param de bloquear, como na campanha.
    for arg in sys.argv:
        if arg.startswith("--taken="):
            pid = arg.split("=", 1)[1]
            for cell in [c for c, p in solid.items() if p == pid]:
                del solid[cell]
            print(f"(simulando prop '{pid}' como taken)")

    def open_(x, y):
        c = tiles.get((x, y))
        if not c or c.get("ground") != "floor":
            return False
        if c.get("piece") == "portal":
            return not any(e["x"] == x and e["y"] == y and e["closed"] for e in exits)
        if c.get("piece"):
            return False
        return (x, y) not in solid

    sx, sy = d["spawn"]
    if len(sys.argv) > 3:
        sx, sy = int(sys.argv[2]), int(sys.argv[3])
    seen, queue = set(), [(sx, sy)]
    if open_(sx, sy):
        seen.add((sx, sy))
    for node in queue:
        x, y = node
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n not in seen and open_(*n):
                seen.add(n)
                queue.append(n)

    def covered(x, y, rng=1.45):
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                if dx * dx + dy * dy <= rng * rng and (x + dx, y + dy) in seen:
                    return True
        return False

    print(f"== {rid} == spawn ({sx},{sy}) -> {len(seen)} células alcançáveis")
    fails = 0
    for b in d["hotspots"]:
        mh = re.search(r"id = '(\w+)'", b)
        hid = mh.group(1) if mh else "?"
        x, y = num(b, "x"), num(b, "y")
        rng = num(b, "range", 1.45) or 1.45
        ok = covered(x, y, rng)
        fails += not ok
        print(f"  hotspot {hid:18s} ({x:2},{y:2}) range {rng}: {'OK' if ok else 'FALHOU'}")
    for b in d["npcs"]:
        mn = re.search(r"id = '([\w-]+)'", b)
        nid = mn.group(1) if mn else "?"
        x, y = num(b, "x"), num(b, "y")
        tr = num(b, "talkRange", 1.7) or 1.7
        foot = (x, y) in seen
        voice = covered(x, y, tr)
        tag = "a pé" if foot else ("por voz" if voice else "FALHOU")
        if not (foot or voice):
            fails += 1
        print(f"  npc     {nid:18s} ({x:2},{y:2}) alcançável {tag}")
    encs = []
    for b in d["encounters"]:
        me = re.search(r"id = '([\w-]+)'", b)
        if me:
            encs.append((me.group(1), num(b, "x"), num(b, "y")))
    for eid, x, y in encs:
        ok = (x, y) in seen
        fails += not ok
        print(f"  enc     {eid:18s} ({x:2},{y:2}): {'OK' if ok else 'FALHOU'}")
    for e in exits:
        front = any((e["x"] + dx, e["y"] + dy) in seen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        state = "fechado" if e["closed"] else "aberto"
        fails += not front
        print(f"  exit -> {e['to']:12s} ({e['x']:2},{e['y']:2}) {state}: frente {'OK' if front else 'FALHOU'}")
    print("RESULTADO:", "TUDO COBERTO" if fails == 0 else f"{fails} FALHA(S)")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
