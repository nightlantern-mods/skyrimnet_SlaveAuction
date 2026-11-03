"""Build the Japanese override of skyrimnet_SlaveAuction from the English project's built plugin.

The output is an MO2 mod placed above the English one: the same plugin name with its text in
Japanese (written as UTF-8; Mutagen would write it as "?"), and strings.json. Everything else stays
in the English mod. Run it after every build of ../skyrimnet_SlaveAuction whose text or records
changed.

usage: build_jp.py [mod_folder]
"""
import json
import os
import shutil
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# In the public repository this folder sits inside the main one, and the samples beside it.
PUBLIC = os.path.isdir(os.path.join(HERE, "..", "samples"))
MAIN_PROJECT = os.path.join(HERE, "..") if PUBLIC else os.path.join(HERE, "..", "skyrimnet_SlaveAuction")
SAMPLES = os.path.join(HERE, "..", "samples") if PUBLIC else os.path.join(HERE, "..")
SOURCE = os.path.join(MAIN_PROJECT, "build", "skyrimnet_SlaveAuction.esp")
DEFAULT_OUT = os.path.join(HERE, "build")

# Text a player sees: names (FULL) and dialogue lines (NAM1).
TEXT_SUBRECORDS = {b"FULL", b"NAM1", b"RNAM"}


def walk(buf, pos, end, out, mapping, used):
    while pos < end:
        record_type = buf[pos:pos + 4]
        size = struct.unpack_from("<I", buf, pos + 4)[0]
        head = bytearray(buf[pos:pos + 24])
        if record_type == b"GRUP":
            inner = bytearray()
            walk(buf, pos + 24, pos + size, inner, mapping, used)
            struct.pack_into("<I", head, 4, 24 + len(inner))
            out += head + inner
            pos += size
            continue
        if struct.unpack_from("<I", head, 8)[0] & 0x00040000:
            # Navmeshes and the patched Tamriel records hold no text; anything else compressed could.
            if record_type not in (b"NAVM", b"NAVI", b"CELL", b"WRLD"):
                raise SystemExit("compressed record: " + record_type.decode())
            out += buf[pos:pos + 24 + size]
            pos += 24 + size
            continue
        data = buf[pos + 24:pos + 24 + size]
        new = patch_subrecords(record_type, data, mapping, used)
        struct.pack_into("<I", head, 4, len(new))
        out += head + new
        pos += 24 + size


def patch_subrecords(record_type, data, mapping, used):
    new = bytearray()
    p = 0
    while p < len(data):
        sub = data[p:p + 4]
        sub_size = struct.unpack_from("<H", data, p + 4)[0]
        if sub == b"XXXX":
            # The next subrecord's real size, for one too long for its 16-bit field: kept as it is.
            real_size = struct.unpack_from("<I", data, p + 6)[0]
            whole = 6 + 4 + 6 + real_size
            new += data[p:p + whole]
            p += whole
            continue
        body = data[p + 6:p + 6 + sub_size]
        if sub in TEXT_SUBRECORDS and record_type != b"TES4":
            text = body.rstrip(b"\0").decode("utf-8", "replace")
            if text in mapping:
                body = mapping[text].encode("utf-8") + b"\0"
                used.add(text)
        new += sub + struct.pack("<H", len(body)) + body
        p += 6 + sub_size
    return new


def translated_plugin(path, map_file):
    """A built plugin's bytes with its text in Japanese. Also used by the release build."""
    mapping = json.load(open(os.path.join(HERE, map_file), encoding="utf-8"))
    buf = open(path, "rb").read()
    out = bytearray()
    used = set()
    walk(buf, 0, len(buf), out, mapping, used)
    missing = set(mapping) - used
    if missing:
        raise SystemExit(path + ": not found in the plugin: " + ", ".join(sorted(missing)))
    return bytes(out)


def translate_sample(out_dir, name, map_file):
    with open(os.path.join(out_dir, name + ".esp"), "wb") as f:
        f.write(translated_plugin(os.path.join(SAMPLES, name.replace("skyrimnet_SlaveAuction_", "") if PUBLIC else name, "build", name + ".esp"), map_file))


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUT
    mapping = json.load(open(os.path.join(HERE, "ja_map.json"), encoding="utf-8"))
    buf = open(SOURCE, "rb").read()
    out = bytearray()
    used = set()
    walk(buf, 0, len(buf), out, mapping, used)
    missing = set(mapping) - used
    if missing:
        raise SystemExit("not found in the plugin: " + ", ".join(sorted(missing)))
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "skyrimnet_SlaveAuction.esp"), "wb") as f:
        f.write(out)
    strings_dir = os.path.join(out_dir, "SKSE", "Plugins", "skyrimnet_SlaveAuction")
    os.makedirs(strings_dir, exist_ok=True)
    shutil.copyfile(os.path.join(HERE, "strings.json"), os.path.join(strings_dir, "strings.json"))
    shutil.copyfile(os.path.join(HERE, "README_skyrimnet_SlaveAuction_日本語.md"), os.path.join(out_dir, "README_skyrimnet_SlaveAuction_日本語.md"))
    # The MCM's text, under both names, so it shows whichever language the game runs in.
    translations_dir = os.path.join(out_dir, "Interface", "Translations")
    os.makedirs(translations_dir, exist_ok=True)
    # One file per plugin: the main one, and the samples' for whoever installs them.
    for name in os.listdir(os.path.join(HERE, "translations")):
        stem = name[:-len("_JAPANESE.txt")]
        for language in ("JAPANESE", "ENGLISH"):
            shutil.copyfile(os.path.join(HERE, "translations", name),
                            os.path.join(translations_dir, f"{stem}_{language}.txt"))
    translate_sample(out_dir, "skyrimnet_SlaveAuction_ExitMine", "ja_map_mine.json")
    # The samples' other text, for whoever installs them.
    shutil.copytree(os.path.join(HERE, "samples"), out_dir, dirs_exist_ok=True)
    print(f"{len(used)} texts in Japanese, {len(out)} bytes, written to {out_dir}")


if __name__ == "__main__":
    main()
