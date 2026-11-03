"""One-off: join the navmesh's pieces at the reception room's stairs, so that followers can climb them.

The Creation Kit left the stairs without a navmesh: the room (0xF06), the foot of the stairs (0xF08) and
the top (0xF09) were separate meshes. This merges the two into 0xF06 with a ramp of new triangles, removes
them from the navmesh info map, and writes the grid again. It stops if 0xF08 is already gone.
"""
import glob
import os
import struct

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN = "skyrimnet_SlaveAuction.esp"
CELL = os.path.join(PROJECT, "plugin", "Cells", "8", "4", f"skyrimnetSlaveAuctionHall - 000800_{PLUGIN}")
MESHES = os.path.join(CELL, "NavigationMeshes")
INFO_MAP = glob.glob(os.path.join(PROJECT, "plugin", "NavigationMeshInfoMaps", "*.yaml"))[0]

# The ramp: rails inside the stairs' walls, and the rise between the two pieces' edges.
LEFT, RIGHT = -816.126, -720.126
RAMP_Y = (1000.0138, 1100.0138, 1200.0138, 1300.0138)
FOOT_EDGE = (948.0138, 35.58)
TOP_EDGE = (1352.0138, 255.58)


def ramp_z(y):
    return FOOT_EDGE[1] + (y - FOOT_EDGE[0]) * (TOP_EDGE[1] - FOOT_EDGE[1]) / (TOP_EDGE[0] - FOOT_EDGE[0])


def read(form):
    path = glob.glob(os.path.join(MESHES, f"{form}_*.yaml"))[0]
    lines = open(path, encoding="utf-8", newline="").read().replace("\r\n", "\n").split("\n")
    i = lines.index("  Vertices:")
    j = i + 1
    verts = []
    while lines[j].startswith("  - "):
        verts.append(lines[j][4:])
        j += 1
    assert lines[j] == "  Triangles:"
    k = j + 1
    tris = []
    while lines[k].startswith("  - Vertices") or lines[k].startswith("    "):
        if lines[k].startswith("  - Vertices"):
            tris.append({"v": [int(x) for x in lines[k].split(":")[1].split(",")], "links": {}, "rest": []})
        elif lines[k].startswith("    EdgeLink"):
            name, value = lines[k].strip().split(":")
            tris[-1]["links"][name] = int(value)
        else:
            tris[-1]["rest"].append(lines[k])
        k += 1
    return path, lines, i, k, verts, tris


def xyz(text):
    return tuple(float(x) for x in text.split(","))


main_path, main_lines, main_start, main_end, verts, tris = read("000F06")
foot_path, _, _, _, foot_verts, foot_tris = read("000F08")
top_path, _, _, _, top_verts, top_tris = read("000F09")
original_main = len(tris)

# The foot's corner at the room's edge is a vertex the room already has.
ROOM_CORNER, FOOT_CORNER = 187, 10
assert xyz(verts[ROOM_CORNER]) == xyz(foot_verts[FOOT_CORNER])
foot_map = {}
for n, text in enumerate(foot_verts):
    if n == FOOT_CORNER:
        foot_map[n] = ROOM_CORNER
    else:
        foot_map[n] = len(verts)
        verts.append(text)
for t in foot_tris:
    tris.append({"v": [foot_map[v] for v in t["v"]], "links": {}, "rest": t["rest"]})
top_map = {}
for n, text in enumerate(top_verts):
    top_map[n] = len(verts)
    verts.append(text)
for t in top_tris:
    tris.append({"v": [top_map[v] for v in t["v"]], "links": {}, "rest": t["rest"]})

rails = []
for y in RAMP_Y:
    z = ramp_z(y)
    rails.append((len(verts), len(verts) + 1))
    verts.append(f"{LEFT}, {y}, {z:.4f}")
    verts.append(f"{RIGHT}, {y}, {z:.4f}")

foot = lambda n: foot_map[n]
top = lambda n: top_map[n]
new = [
    (185, ROOM_CORNER, foot(11)),                      # the room's edge to the foot
    (foot(9), foot(4), rails[0][0]),                   # the foot to the ramp
    (foot(4), foot(5), rails[0][0]),
    (foot(5), rails[0][1], rails[0][0]),
    (foot(5), foot(6), rails[0][1]),
    (rails[-1][0], rails[-1][1], top(0)),              # the ramp to the top
    (rails[-1][0], top(0), top(2)),
    (rails[-1][1], top(1), top(0)),
    (rails[-1][0], top(2), top(3)),
    (rails[-1][1], top(4), top(1)),
]
for a, b in zip(rails, rails[1:]):
    new.append((a[0], a[1], b[1]))
    new.append((a[0], b[1], b[0]))

positions = [xyz(v) for v in verts]
for a, b, c in new:
    area = (positions[b][0] - positions[a][0]) * (positions[c][1] - positions[a][1]) - (positions[b][1] - positions[a][1]) * (positions[c][0] - positions[a][0])
    # The Creation Kit's triangles all turn counter-clockwise.
    tris.append({"v": [a, b, c] if area > 0 else [a, c, b], "links": {}, "rest": ["    Flags:", "    - Found"]})

# Neighbours, from the vertices the triangles share.
users = {}
for n, t in enumerate(tris):
    a, b, c = t["v"]
    for name, e in (("EdgeLink_0_1", (a, b)), ("EdgeLink_1_2", (b, c)), ("EdgeLink_2_0", (c, a))):
        users.setdefault((min(e), max(e)), []).append((n, name))
for edge, sides in users.items():
    assert len(sides) <= 2, ("an edge with three triangles", edge, sides)
    for n, name in sides:
        other = [s[0] for s in sides if s[0] != n]
        tris[n]["new"] = tris[n].get("new", {})
        tris[n]["new"][name] = other[0] if other else -1

# The room's own triangles must come out as they were, except on the one edge joined.
original = read("000F06")[5]
changed = 0
for n in range(original_main):
    for name in ("EdgeLink_0_1", "EdgeLink_1_2", "EdgeLink_2_0"):
        was = original[n]["links"].get(name, 0)
        if was != tris[n]["new"][name]:
            changed += 1
            assert was == -1, (n, name, was, tris[n]["new"][name])
print("edges of the room's triangles newly joined:", changed)

mn = [min(p[i] for p in positions) for i in range(3)]
mx = [max(p[i] for p in positions) for i in range(3)]
DIV = 7
dx, dy = (mx[0] - mn[0]) / DIV, (mx[1] - mn[1]) / DIV
cells = [[] for _ in range(DIV * DIV)]
for n, t in enumerate(tris):
    xs = [positions[v][0] for v in t["v"]]
    ys = [positions[v][1] for v in t["v"]]
    for cy in range(max(0, int((min(ys) - mn[1]) / dy)), min(DIV - 1, int((max(ys) - mn[1]) / dy)) + 1):
        for cx in range(max(0, int((min(xs) - mn[0]) / dx)), min(DIV - 1, int((max(xs) - mn[0]) / dx)) + 1):
            cells[cy * DIV + cx].append(n)
grid = bytearray()
for cell in cells:
    grid += struct.pack("<I", len(cell)) + struct.pack(f"<{len(cell)}H", *cell)

out = main_lines[:main_start + 1]
out += [f"  - {v}" for v in verts]
out.append("  Triangles:")
for t in tris:
    out.append("  - Vertices: " + ", ".join(str(v) for v in t["v"]))
    for name in ("EdgeLink_0_1", "EdgeLink_1_2", "EdgeLink_2_0"):
        if t["new"][name] != 0:
            out.append(f"    {name}: {t['new'][name]}")
    out += t["rest"]
replacements = {
    "  NavmeshGridDivisor:": f"  NavmeshGridDivisor: {DIV}",
    "  MaxDistanceX:": f"  MaxDistanceX: {dx:.5f}",
    "  MaxDistanceY:": f"  MaxDistanceY: {dy:.5f}",
    "  Min:": f"  Min: {mn[0]}, {mn[1]}, {mn[2]}",
    "  Max:": f"  Max: {mx[0]}, {mx[1]}, {mx[2]}",
    "  NavmeshGrid:": "  NavmeshGrid: 0x" + grid.hex().upper(),
}
for line in main_lines[main_end:]:
    for start, value in replacements.items():
        if line.startswith(start + " ") or line == start:
            line = value
            break
    out.append(line)
with open(main_path, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out))

os.remove(foot_path)
os.remove(top_path)

raw = open(INFO_MAP, encoding="utf-8", newline="").read()
newline = "\r\n" if "\r\n" in raw else "\n"
lines = raw.replace("\r\n", "\n").split("\n")
kept = []
skip = False
for line in lines:
    if line.startswith("- NavigationMesh:") or (line and not line.startswith(" ") and not line.startswith("-")):
        skip = line.startswith(f"- NavigationMesh: 000F08:{PLUGIN}") or line.startswith(f"- NavigationMesh: 000F09:{PLUGIN}")
    if not skip:
        kept.append(line)
with open(INFO_MAP, "w", encoding="utf-8", newline="") as f:
    f.write(newline.join(kept))
print("vertices", len(verts), "triangles", len(tris), "min", mn, "max", mx)
