"""Build the release archive: an MO2 / Vortex FOMOD installer holding the mod and its samples, in two languages.

Run after building every project (buildProject), and after a change to any of their assets. It reads the
built plugins and the assets, never a deployed mod folder, so nothing from the test setup can get in. Every
choice installs one complete folder: the Japanese ones hold the same files with their text in Japanese, under
the same names, and a sample's plugin is installed only when that sample is chosen.

    core/en, core/ja                the mod
    samples/<language>/<sample>     each sample
    fomod/                          the installer

usage: build_fomod.py [version]
"""
import io
import os
import sys
import xml.etree.ElementTree as ET
import zipfile

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# In the public repository the others sit inside this one; in development they are its neighbours.
PUBLIC = os.path.isdir(os.path.join(PROJECT, "samples"))
PROJECTS = os.path.join(PROJECT, "samples") if PUBLIC else os.path.dirname(PROJECT)
JAPANESE = os.path.join(PROJECT, "japanese") if PUBLIC else os.path.join(PROJECTS, "skyrimnet_SlaveAuction_Japanese")
sys.dont_write_bytecode = True
sys.path.insert(0, JAPANESE)
import build_jp  # noqa: E402

VERSION = sys.argv[1] if len(sys.argv) > 1 else "0.1.0"
OUT = os.path.join(PROJECT, "dist", f"SkyrimNet Slave Auction {VERSION}.zip")
MAIN = "skyrimnet_SlaveAuction"
AUTHOR = "nightlantern-mods"

# (flag, project, map of the text in its plugin, English name and text, Japanese name and text)
SAMPLES = (
    ("EntryDefeat", MAIN + "_EntryDefeat", None,
     "Entry: Defeated in Battle",
     "Beaten by humanoid enemies, you and your followers nearby are sold at the auction instead of dying. "
     "Do not use with another defeat mod. It has its own MCM, with an optional give-up key.",
     "入口：戦闘敗北",
     "人型の敵に負けると、死なずに近くのフォロワーと一緒に競売で売られます。"
     "ほかの敗北系 MOD と同時には使えません。専用の MCM があり、ギブアップキーも設定できます。"),
    ("EntryAbduction", MAIN + "_EntryAbduction", None,
     "Entry: Abducted in Sleep",
     "When you sleep outdoors, in an inn or in a dungeon, the followers near you may be carried off to the auction. "
     "It has its own MCM with the chance (25% by default).",
     "入口：就寝中の誘拐",
     "屋外、宿屋、ダンジョンで眠ると、近くのフォロワーが競売へさらわれることがあります。"
     "専用の MCM で確率を変えられます（標準は 25%）。"),
    ("EntrySack", MAIN + "_EntrySack", "ja_map_sack.json",
     "Entry: Sacked Captives",
     "Needs Diary of Mine. Carry someone to the receptionist's room in a sack, take them out tied up, "
     "and hand them over to be sold. When another buyer wins them, you get half the price.",
     "入口：袋詰めの引き渡し",
     "Diary of Mine が必要です。袋詰めにした人を受付の部屋で縛った状態で取り出し、受付に引き渡すと競売にかけられます。"
     "他の買い手が落札すると、落札額の半分を受け取ります。"),
    ("ExitMine", MAIN + "_ExitMine", "ja_map_mine.json",
     "Exit: The Mine",
     "Sold, you work a mine until the quota is met. Followers sold to another buyer wait there to be bought back. "
     "With this installed, the liberators' ending no longer happens, unless you switch the exit off in the MCM.",
     "出口：鉱山",
     "売られると、ノルマを終えるまで鉱山で働きます。他の買い手に売られたフォロワーは、鉱山で買い戻せます。"
     "これを入れると、MCM で出口を無効にしない限り、解放戦線の結末は起きなくなります。"),
    ("ExitDebt", MAIN + "_ExitDebt", None,
     "Exit: Set Free in Debt",
     "A moneylender takes a seat and wins every lot you do not buy, then sets each free at once, owing three times "
     "the price: followers come back to you, others go home. Needs the IOU Ledger add-on, which is installed with it.",
     "出口：借金を背負って解放",
     "金融屋が席に着き、あなたが買わなかった人をすべて落札します。落札された人は、落札額の 3 倍の借金を背負って、すぐに解放されます。"
     "フォロワーはあなたの元へ戻り、それ以外の人は家へ帰ります。追加 MOD の借用書台帳が必要で、一緒に導入されます。"),
    ("ExitCarriage", MAIN + "_ExitCarriage", None,
     "Exit: Carriage to Town",
     "After the auction, you and the followers you bought arrive at the Riften stables.",
     "出口：馬車で町へ",
     "競売のあと、落札したフォロワーと一緒にリフテンの馬屋の前へ着きます。"),
)

# Add-ons: mods of their own that others can use. (flag, project, map, English name and text, Japanese
# name and text, the sample flag that needs it)
ADDONS = (
    ("IOULedger", "IOULedger", "ja_map_ledger.json",
     "Add-on: IOU Ledger",
     "Debts any mod can give an NPC: a bond in their inventory, the amount on record, and the journal tracking "
     "up to ten debtors. A mod of its own, not tied to the auction. Needed by the exit Set Free in Debt.",
     "追加 MOD：借用書台帳",
     "どの MOD からでも NPC に借金を負わせられる仕組みです。借用書を持たせ、金額を記録し、ジャーナルで最大 10 人まで追跡できます。"
     "競売とは独立した MOD です。出口「借金を背負って解放」に必要です。",
     "ExitDebt"),
)

files = {}


def project_folder(project):
    if project == MAIN:
        return PROJECT
    return os.path.join(PROJECTS, project.replace(MAIN + "_", "") if PUBLIC else project)


def add_project(prefix, project):
    """The plugin as built and every asset."""
    root = project_folder(project)
    files[f"{prefix}/{project}.esp"] = open(os.path.join(root, "build", project + ".esp"), "rb").read()
    assets = os.path.join(root, "assets")
    for folder, _, names in os.walk(assets):
        for name in names:
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, assets).replace(os.sep, "/")
            data = open(path, "rb").read()
            files[f"{prefix}/{rel}"] = data
            # SkyUI reads <mod>_<the game's language>.txt: the English text goes under every language's name,
            # so that no game shows the $keys. A translation replaces its own language's file.
            if rel.startswith("Interface/Translations/") and rel.endswith("_ENGLISH.txt"):
                for language in GAME_LANGUAGES:
                    files[f"{prefix}/{rel[:-len('ENGLISH.txt')]}{language}.txt"] = data


GAME_LANGUAGES = ("CHINESE", "CZECH", "ENGLISH", "FRENCH", "GERMAN", "ITALIAN", "JAPANESE", "POLISH", "RUSSIAN", "SPANISH")


def japanese_overlay(prefix, project, map_file):
    """Everything with text, replaced under the same name. The translations go under every language's name,
    so that they show whichever language the game runs in."""
    if map_file:
        files[f"{prefix}/{project}.esp"] = build_jp.translated_plugin(os.path.join(project_folder(project), "build", project + ".esp"), map_file)
    translation = os.path.join(JAPANESE, "translations", project + "_JAPANESE.txt")
    if os.path.exists(translation):
        data = open(translation, "rb").read()
        # The language chosen in the installer, whatever the game's.
        for language in GAME_LANGUAGES:
            files[f"{prefix}/Interface/Translations/{project}_{language}.txt"] = data
    samples = os.path.join(JAPANESE, "samples")
    for folder, _, names in os.walk(samples):
        for name in names:
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, samples).replace(os.sep, "/")
            if f"{prefix}/{rel}" in files:
                files[f"{prefix}/{rel}"] = open(path, "rb").read()


# --- The mod ---------------------------------------------------------------------------------------
add_project("core/en", MAIN)
add_project("core/ja", MAIN)
for language in ("en", "ja"):
    files[f"core/{language}/LICENSE_{MAIN}.txt"] = open(os.path.join(PROJECT, "LICENSE"), "rb").read()
files[f"core/ja/{MAIN}.esp"] = build_jp.translated_plugin(os.path.join(PROJECT, "build", MAIN + ".esp"), "ja_map.json")
files[f"core/ja/SKSE/Plugins/{MAIN}/strings.json"] = open(os.path.join(JAPANESE, "strings.json"), "rb").read()
japanese_overlay("core/ja", MAIN, None)
del files[f"core/ja/README_{MAIN}.md"]
del files[f"core/ja/README_{MAIN}_Authors.md"]
files[f"core/ja/README_{MAIN}_ja.md"] = open(os.path.join(JAPANESE, f"README_{MAIN}_日本語.md"), "rb").read()
files[f"core/ja/README_{MAIN}_Authors_ja.md"] = open(os.path.join(JAPANESE, f"README_{MAIN}_Authors_日本語.md"), "rb").read()

# --- The samples -----------------------------------------------------------------------------------
for flag, project, map_file, *_ in SAMPLES:
    add_project(f"samples/en/{flag}", project)
    add_project(f"samples/ja/{flag}", project)
    japanese_overlay(f"samples/ja/{flag}", project, map_file)
for flag, project, map_file, *_ in ADDONS:
    add_project(f"addons/en/{flag}", project)
    add_project(f"addons/ja/{flag}", project)
    japanese_overlay(f"addons/ja/{flag}", project, map_file)


# --- The installer ---------------------------------------------------------------------------------
def el(parent, tag, text=None, **attrs):
    node = ET.SubElement(parent, tag, {k: str(v) for k, v in attrs.items()})
    if text is not None:
        node.text = text
    return node


def xml_bytes(root):
    # Vortex re-encodes the file as UTF-16 and strips the encoding from the declaration, but only when
    # it is written in double quotes. ElementTree writes single ones, and Vortex then refuses the file
    # at line 1, position 39. So the declaration is written by hand.
    ET.indent(root)
    buffer = io.BytesIO()
    buffer.write(b'<?xml version="1.0" encoding="utf-8"?>\n')
    ET.ElementTree(root).write(buffer, encoding="utf-8", xml_declaration=False)
    return buffer.getvalue()


info = ET.Element("fomod")
el(info, "Name", "SkyrimNet Slave Auction")
el(info, "Author", AUTHOR)
el(info, "Version", VERSION)
el(info, "Description", "A secret slave auction under the stone, voiced by SkyrimNet's AI.")
files["fomod/info.xml"] = xml_bytes(info)

config = ET.Element("config", {
    "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
    "xsi:noNamespaceSchemaLocation": "http://qconsulting.ca/fo3/ModConfig5.0.xsd",
})
el(config, "moduleName", "SkyrimNet Slave Auction")
steps = el(config, "installSteps", order="Explicit")


def plugin(group_plugins, name, description, flags, kind):
    p = el(group_plugins, "plugin", name=name)
    el(p, "description", description)
    conditions = el(p, "conditionFlags")
    for flag in flags:
        el(conditions, "flag", "On", name=flag)
    types = el(p, "typeDescriptor")
    el(types, "type", name=kind)


step = el(steps, "installStep", name="Language / 言語")
groups = el(step, "optionalFileGroups", order="Explicit")
group = el(groups, "group", name="Language / 言語", type="SelectExactlyOne")
plugins = el(group, "plugins", order="Explicit")
plugin(plugins, "English", "Install the mod with its text in English.", ["LangEN"], "Recommended")
plugin(plugins, "日本語", "MOD を日本語の表示で導入します。", ["LangJA"], "Optional")


def samples_step(step_name, group_name, flag, name_at, text_at):
    step = el(steps, "installStep", name=step_name)
    visible = el(step, "visible")
    el(visible, "flagDependency", flag=flag, value="On")
    groups = el(step, "optionalFileGroups", order="Explicit")
    group = el(groups, "group", name=group_name, type="SelectAny")
    plugins = el(group, "plugins", order="Explicit")
    for sample in SAMPLES:
        plugin(plugins, sample[name_at], sample[text_at], [sample[0]], "Optional")


samples_step("Samples", "Samples (none are needed; each is a small mod, source included)", "LangEN", 3, 4)
samples_step("サンプル", "サンプル（どれも必須ではありません。小さな MOD で、ソース付きです）", "LangJA", 5, 6)


def addons_step(step_name, group_name, flag, name_at, text_at):
    """A step after the samples, so that a sample chosen there makes the add-on it needs required."""
    step = el(steps, "installStep", name=step_name)
    visible = el(step, "visible")
    el(visible, "flagDependency", flag=flag, value="On")
    groups = el(step, "optionalFileGroups", order="Explicit")
    group = el(groups, "group", name=group_name, type="SelectAny")
    plugins = el(group, "plugins", order="Explicit")
    for addon in ADDONS:
        p = el(plugins, "plugin", name=addon[name_at])
        el(p, "description", addon[text_at])
        conditions = el(p, "conditionFlags")
        el(conditions, "flag", "On", name=addon[0])
        types = el(p, "typeDescriptor")
        dependency = el(types, "dependencyType")
        el(dependency, "defaultType", name="Optional")
        needed = el(el(dependency, "patterns"), "pattern")
        el(el(needed, "dependencies", operator="And"), "flagDependency", flag=addon[7], value="On")
        el(needed, "type", name="Required")


addons_step("Add-ons", "Add-ons (mods of their own that other mods can use)", "LangEN", 3, 4)
addons_step("追加 MOD", "追加 MOD（ほかの MOD からも使える、独立した MOD です）", "LangJA", 5, 6)

conditional = el(config, "conditionalFileInstalls")
patterns = el(conditional, "patterns")


def pattern(flags, source):
    p = el(patterns, "pattern")
    dependencies = el(p, "dependencies", operator="And")
    for flag in flags:
        el(dependencies, "flagDependency", flag=flag, value="On")
    folder = el(p, "files")
    el(folder, "folder", source=source.replace("/", "\\"), destination="", priority="0")


pattern(["LangEN"], "core/en")
pattern(["LangJA"], "core/ja")
for sample in SAMPLES:
    pattern(["LangEN", sample[0]], f"samples/en/{sample[0]}")
    pattern(["LangJA", sample[0]], f"samples/ja/{sample[0]}")
for addon in ADDONS:
    # Installed when chosen, and always with the sample that needs it, whatever the installer showed.
    for language, code in (("LangEN", "en"), ("LangJA", "ja")):
        pattern([language, addon[0]], f"addons/{code}/{addon[0]}")
        pattern([language, addon[7]], f"addons/{code}/{addon[0]}")
files["fomod/ModuleConfig.xml"] = xml_bytes(config)

# --- Written last: nothing is packed unless all of it was found --------------------------------------
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(files):
        archive.writestr(name, files[name])
print(f"{len(files)} files, {os.path.getsize(OUT)} bytes: {OUT}")
