"""Check that a release holds nothing from another mod: its plugins' masters, and every override against Skyrim.esm,
subrecord by subrecord. Read only.

usage: check_foreign.py <archive.zip>
"""
import struct
import sys
import zipfile
import zlib

MASTER = r"C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data\Skyrim.esm"
MAIN_OK = {b"FULL"}   # a world's name is plain text in an override and a string ID in the localized master


def subrecords(data):
    out = []
    p = 0
    over = None
    while p < len(data):
        t = data[p:p + 4]
        s = struct.unpack_from("<H", data, p + 4)[0]
        if t == b"XXXX":
            over = struct.unpack_from("<I", data, p + 6)[0]
            p += 10
            continue
        if over is not None:
            s, over = over, None
        out.append((t, data[p + 6:p + 6 + s]))
        p += 6 + s
    return out


def records(buf, wanted=None):
    """Every record outside the header: (signature, form id) -> (flags, body)."""
    found = {}

    def walk(pos, end):
        while pos < end:
            kind = buf[pos:pos + 4]
            size = struct.unpack_from("<I", buf, pos + 4)[0]
            if kind == b"GRUP":
                walk(pos + 24, pos + size)
                pos += size
                continue
            flags, form = struct.unpack_from("<II", buf, pos + 8)
            if wanted is None or form in wanted:
                body = buf[pos + 24:pos + 24 + size]
                if flags & 0x40000:
                    body = zlib.decompress(body[4:])
                found[form] = (kind, flags, body)
            pos += 24 + size

    head = 24 + struct.unpack_from("<I", buf, 4)[0]
    walk(head, len(buf))
    return found


def masters(buf):
    size = struct.unpack_from("<I", buf, 4)[0]
    return [b.rstrip(b"\0").decode() for t, b in subrecords(buf[24:24 + size]) if t == b"MAST"]


archive = zipfile.ZipFile(sys.argv[1])
plugins = sorted(n for n in archive.namelist() if n.endswith(".esp"))
overrides = {}
loaded = {}
problems = []
for name in plugins:
    buf = archive.read(name)
    loaded[name] = buf
    found = masters(buf)
    if found != ["Skyrim.esm"]:
        problems.append((name, "masters", found))
    for form, record in records(buf).items():
        if form >> 24 == 0:
            overrides.setdefault(form, []).append((name, record))
print(len(plugins), "plugins; vanilla records overridden:", sorted(f"{f:06X}" for f in overrides))
vanilla = records(open(MASTER, "rb").read(), set(overrides))
for form, versions in sorted(overrides.items()):
    kind, _, base = vanilla[form]
    base_subs = dict()
    for t, b in subrecords(base):
        base_subs.setdefault(t, []).append(b)
    for name, (k, _, body) in versions:
        mine = {}
        for t, b in subrecords(body):
            mine.setdefault(t, []).append(b)
        for t in sorted(set(mine) | set(base_subs)):
            if mine.get(t) == base_subs.get(t):
                continue
            label = f"{form:06X} {kind.decode()} {t.decode()}"
            if t in MAIN_OK:
                print(f"  {name.split('/')[-1]}: {label} differs (a name, expected): {mine.get(t, [b''])[0][:30]}")
            elif kind == b"NAVI" and t in (b"NVMI", b"NVPP", b"NVSI"):
                continue    # an override of this one lists only the plugin's own navmeshes
            elif kind == b"WRLD" and t in (b"OFST", b"RNAM", b"CLSZ"):
                continue    # big tables a world override leaves out, as every other mod's does
            else:
                problems.append((name, label, "mine" if t in mine else "absent", len(b"".join(mine.get(t, []))), len(b"".join(base_subs.get(t, [])))))
print("problems:", problems if problems else "none")
sys.exit(1 if problems else 0)
