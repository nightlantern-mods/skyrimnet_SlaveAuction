"""Check the release archive without installing it: read its FOMOD as an installer would, try the choices, and
look at what each one puts in the game's Data folder.

usage: check_fomod.py <archive.zip>
"""
import itertools
import json
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile

archive = zipfile.ZipFile(sys.argv[1])
names = set(archive.namelist())
config = ET.fromstring(archive.read("fomod/ModuleConfig.xml"))
ET.fromstring(archive.read("fomod/info.xml"))
# Vortex strips the encoding from the declaration only when it is in double quotes; otherwise it fails at
# line 1, position 39 (it re-encodes the text as UTF-16 first).
for xml_name in ("fomod/ModuleConfig.xml", "fomod/info.xml"):
    head = archive.read(xml_name).split(b"?>", 1)[0]
    assert b"encoding='" not in head, xml_name + ": Vortex needs the declaration's encoding in double quotes"
patterns = []
for p in config.find("conditionalFileInstalls/patterns"):
    needed = [d.get("flag") for d in p.find("dependencies")]
    source = p.find("files/folder").get("source").replace("\\", "/")
    assert any(n.startswith(source + "/") for n in names), source
    patterns.append((needed, source))


def install(flags):
    out = {}
    for needed, source in patterns:
        if all(f in flags for f in needed):
            for name in names:
                if name.startswith(source + "/"):
                    out[name[len(source) + 1:]] = name
    return out


MAIN = "skyrimnet_SlaveAuction"
SAMPLES = {"EntryDefeat": MAIN + "_EntryDefeat.esp", "EntryAbduction": MAIN + "_EntryAbduction.esp", "ExitMine": MAIN + "_ExitMine.esp", "ExitCarriage": MAIN + "_ExitCarriage.esp"}
problems = []
count = 0
for language in ("LangEN", "LangJA"):
    for size in range(5):
        for chosen in itertools.combinations(SAMPLES, size):
            count += 1
            data = install({language, *chosen})
            plugins = {n for n in data if n.endswith(".esp")}
            expected = {MAIN + ".esp", *(SAMPLES[c] for c in chosen)}
            if plugins != expected:
                problems.append((language, chosen, "plugins", sorted(plugins ^ expected)))
            for name, source in data.items():
                if name.endswith(".json"):
                    json.loads(archive.read(source).decode("utf-8"))
                low = name.lower()
                if "test" in low.replace("latest", "") or low.startswith(("tools/", "docs/", "src/")):
                    problems.append((language, chosen, "does not belong", name))
            text = {n: archive.read(s) for n, s in data.items() if n.startswith("Interface/Translations/")}
            for n, t in text.items():
                if t[:2] != b"\xff\xfe":
                    problems.append((language, chosen, "not UTF-16", n))
                body = t.decode("utf-16")
                has_japanese = any(ord(c) > 0x3000 for c in body)
                if has_japanese != (language == "LangJA"):
                    problems.append((language, chosen, "wrong language", n))
            for n, s in data.items():
                if not n.endswith(".esp"):
                    continue
                head = archive.read(s)[:4]
                if head != b"TES4":
                    problems.append((language, chosen, "not a plugin", n))
                flags = struct.unpack_from("<I", archive.read(s), 8)[0]
                if not flags & 0x200:
                    problems.append((language, chosen, "not light", n))

print(count, "combinations of choices,", len(names), "files in the archive")
print("nothing chosen, English:", sorted(n for n in install({"LangEN"}) if n.endswith(".esp")))
print("nothing chosen, Japanese:", sorted(n for n in install({"LangJA"}) if n.endswith(".esp")))
print("mine, Japanese:", sorted(n for n in install({"LangJA", "ExitMine"}) if n.endswith(".esp")))
for label, source in (("en", "samples/en/ExitMine"), ("ja", "samples/ja/ExitMine")):
    b = archive.read(source + "/" + MAIN + "_ExitMine.esp")
    print(label, "mine plugin has Japanese names:", "廃鉱".encode("utf-8") in b)
    print(label, "exit name:", json.loads(archive.read(source + "/SKSE/Plugins/skyrimnet_SlaveAuction/exits/skyrimnet_SlaveAuction_mine_labor.json").decode("utf-8"))["string"]["name"])
print("problems:", problems[:20] if problems else "none")
sys.exit(1 if problems else 0)
