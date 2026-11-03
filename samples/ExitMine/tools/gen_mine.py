"""Generate the records of the mine sample: its cell, the door and marker in Tamriel, and its quest.

The room is built from the Imperial SmallRoom kit, as the auction hall is, and its floor is one flat
navmesh of two triangles. The way in is the auction cave's pair of rock and door, at a point measured in
the game beside the mountain (MountainTrimSlab), and looked at offline from its meshes and the terrain.
The rock stands untilted, as in the vanilla pair: the ground there is flat.

    +----------door----------+    north is up
    |      overseer          |
    |  chest      followers  |
    |      player arrives    |
    |   rock   rock   rock   |
    +------------------------+
"""
import json
import os

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUCTION = os.path.join(os.path.dirname(PROJECT), "skyrimnet_SlaveAuction")   # in the public repository: ../..
if not os.path.isdir(AUCTION):
    AUCTION = os.path.dirname(os.path.dirname(PROJECT))
P = "skyrimnet_SlaveAuction_ExitMine.esp"
PREFIX = "skyrimnet_SlaveAuction_ExitMine"
PLUGIN = os.path.join(PROJECT, "plugin")
CELL_ID, QUEST_ID, GLOBAL_ID, ROCK_ID, OUTFIT_ID = 0x800, 0x801, 0x802, 0x803, 0x804
BRANCH_ID, TOPIC_ID, INFO_ID = 0x805, 0x806, 0x807
ARRIVAL, OVERSEER, HOLD, PLAYER_CHEST, FOLLOWER_CHEST = 0x810, 0x811, 0x812, 0x814, 0x815
INNER_DOOR, WORLD_DOOR, WORLD_ROCK, WORLD_MARKER = 0x829, 0x826, 0x827, 0x828
NAVMESH_ID = 0xF00

T = 256
W, D = 5, 4
FLOOR = 15.6       # the kit's floor, from the auction hall's navmesh
WALL_IN = {"N": 105, "W": 107, "S": 117, "E": 109}
CORNER = {"NW": "029994:Skyrim.esm", "SW": "029997:Skyrim.esm", "SE": "029995:Skyrim.esm", "NE": "029996:Skyrim.esm"}
WALL = {"N": "029987:Skyrim.esm", "W": "02998E:Skyrim.esm", "S": "02998F:Skyrim.esm", "E": "02998C:Skyrim.esm"}
DOORWAY_N = "0299B0:Skyrim.esm"
MID = "02998D:Skyrim.esm"
DOOR_TILE = 2      # along the north side
LOAD_DOOR = "04203A:Skyrim.esm"   # ImpDoorSingleLoad01
CAVE_DOOR = "10C62A:Skyrim.esm"   # the door and rock of the auction's cave
CAVE_ROCK = "0E0BA5:Skyrim.esm"
CHEST = "0F8476:Skyrim.esm"       # LargeChestNoRespawn
MARKER = "000034:Skyrim.esm"      # XMarkerHeading
MAP_MARKER = "000010:Skyrim.esm"
NORTH = "000003:Skyrim.esm"       # NorthMarker
LIGHT = "06FF42:Skyrim.esm"       # SolitudeInnLight02Sm
BRAZIER = "05F227:Skyrim.esm"     # ImpBrazier01
DO_NOTHING = "0654E2:Skyrim.esm"

# In Tamriel: the door on the ground where the user stood, facing the mountain that overhangs there.
DOOR_POS = (178066.11, -83536.43, 8693.7)
DOOR_RZ = 2.1786945
ROCK_POS = (178231.44, -83749.99, 8714.89)
ROCK_ROT = (0.0, 0.0, 3.6774945)
OUT_POS = (177860.9, -83393.64, 8720.0)       # 250 out from the door, looking away from it
MAP_POS = (177803.44, -83353.66, 8720.0)
OUT_RZ = 5.3202872


def fk(i):
    return f"{i:06X}:{P}"


def write(rel, text):
    path = os.path.join(PLUGIN, *rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


cell_dir = ["Cells", "8", "4", f"skyrimnetSlaveAuctionMine - {CELL_ID:06X}_{P}"]


def ref(i, base, x, y, z=0.0, rz=0.0, persistent=True, editor=None, extra=""):
    head = "MutagenObjectType: PlacedObject\nFormKey: " + fk(i) + "\n"
    if persistent:
        head += "MajorRecordFlagsRaw: 1024\nSkyrimMajorRecordFlags:\n- 0x400\n"
    if editor:
        head += f"EditorID: {editor}\n"
    body = f"{head}Base: {base}\n{extra}Placement:\n  Position: {x}, {y}, {z}\n  Rotation: 0, 0, {rz}\n"
    name = f"{editor} - {i:06X}_{P}.yaml" if editor else f"{i:06X}_{P}.yaml"
    write(cell_dir + ["Persistent" if persistent else "Temporary", name], body)


# --- The cell -----------------------------------------------------------------------------------
hall = open(os.path.join(AUCTION, "plugin", "Cells", "8", "4", "skyrimnetSlaveAuctionHall - 000800_skyrimnet_SlaveAuction.esp", "RecordData.yaml"), encoding="utf-8").read()
hall = hall.replace("FormKey: 000800:skyrimnet_SlaveAuction.esp", "FormKey: " + fk(CELL_ID))
hall = hall.replace("EditorID: skyrimnetSlaveAuctionHall", "EditorID: skyrimnetSlaveAuctionMine")
hall = hall.replace('Value: "Underground Auction Hall"', 'Value: "Abandoned Mine"')
write(cell_dir + ["RecordData.yaml"], hall)
write(["Cells", "GroupRecordData.yaml"], "{}\n")
write(["Cells", "8", "GroupRecordData.yaml"], "BlockNumber: 8\nGroupType: InteriorCellBlock\n")
write(["Cells", "8", "4", "GroupRecordData.yaml"], "BlockNumber: 4\nGroupType: InteriorCellSubBlock\n")

next_id = 0x830


def temp(base, x, y, z=0.0, rz=0.0):
    global next_id
    ref(next_id, base, x, y, z, rz, persistent=False)
    next_id += 1


for ix in range(W):
    for iy in range(D):
        x, y = ix * T, iy * T
        west, east, south, north = ix == 0, ix == W - 1, iy == 0, iy == D - 1
        if (south or north) and (west or east):
            temp(CORNER[("N" if north else "S") + ("W" if west else "E")], x, y)
        elif north and ix == DOOR_TILE:
            temp(DOORWAY_N, x, y)
        elif west or east or south or north:
            temp(WALL["W" if west else "E" if east else "S" if south else "N"], x, y)
        else:
            temp(MID, x, y)
temp(NORTH, 0, 0, 64.0)
west_in, east_in = -WALL_IN["W"], (W - 1) * T + WALL_IN["E"]
south_in, north_in = -WALL_IN["S"], (D - 1) * T + WALL_IN["N"]
door_x = DOOR_TILE * T
cx = (west_in + east_in) / 2

ref(INNER_DOOR, LOAD_DOOR, door_x, north_in + 23, 0.0, 0.0, editor=PREFIX + "InnerDoor",
    extra=f"""TeleportDestination:
  Door: {fk(WORLD_DOOR)}
  Position: {OUT_POS[0]}, {OUT_POS[1]}, {OUT_POS[2]}
  Rotation: 0, 0, {OUT_RZ}
VirtualMachineAdapter:
  Scripts:
  - Name: {PREFIX}Door
""")
ref(ARRIVAL, MARKER, cx, 256.0, FLOOR, 0.0, editor=PREFIX + "Arrival")
ref(OVERSEER, MARKER, door_x, 480.0, FLOOR, 3.1415927, editor=PREFIX + "OverseerMarker")
ref(HOLD, MARKER, east_in - 200, 300.0, FLOOR, 4.712389, editor=PREFIX + "Holding")
ref(PLAYER_CHEST, CHEST, west_in + 60, 300.0, FLOOR, 1.5707963, editor=PREFIX + "PlayerChest")
for i in range(10):
    ref(FOLLOWER_CHEST + i, CHEST, cx + i * 80, 300.0, -600.0, 0.0, editor=f"{PREFIX}FollowerChest{i}")
for i in range(10):
    ref(0x850 + i, CHEST, cx + i * 80, 400.0, -600.0, 0.0, editor=f"{PREFIX}FollowerChest{10 + i}")
for i, x in enumerate((west_in + 200, cx, east_in - 200)):
    temp(fk(ROCK_ID), x, south_in + 110, FLOOR)
temp(BRAZIER, west_in + 70, north_in - 70, FLOOR)
temp(BRAZIER, east_in - 70, north_in - 70, FLOOR)
for x in (cx - 260, cx + 260):
    for y in (90.0, 480.0):
        temp(LIGHT, x, y, 170.0)

# One flat floor. Counter-clockwise from above; the two triangles share the edge from 0 to 2.
x0, x1, y0, y1 = west_in + 20, east_in - 20, south_in + 20, north_in - 20
grid = bytes.fromhex("020000000000" + "0100").hex().upper()
write(cell_dir + ["NavigationMeshes", f"{NAVMESH_ID:06X}_{P}.yaml"], f"""FormKey: {fk(NAVMESH_ID)}
Data:
  Parent:
    MutagenObjectType: CellNavmeshParent
    Parent: {fk(CELL_ID)}
  Vertices:
  - {x0}, {y0}, {FLOOR}
  - {x1}, {y0}, {FLOOR}
  - {x1}, {y1}, {FLOOR}
  - {x0}, {y1}, {FLOOR}
  Triangles:
  - Vertices: 0, 1, 2
    EdgeLink_0_1: -1
    EdgeLink_1_2: -1
    EdgeLink_2_0: 1
    Flags:
    - Found
  - Vertices: 0, 2, 3
    EdgeLink_0_1: 0
    EdgeLink_1_2: -1
    EdgeLink_2_0: -1
    Flags:
    - Found
  NavmeshGridDivisor: 1
  MaxDistanceX: {x1 - x0}
  MaxDistanceY: {y1 - y0}
  Min: {x0}, {y0}, {FLOOR}
  Max: {x1}, {y1}, {FLOOR}
  NavmeshGrid: 0x{grid}
""")

# The info map holds only this navmesh: the game adds each plugin's entries to the others'.
write(["NavigationMeshInfoMaps", "012FB4_Skyrim.esm.yaml"], f"""FormKey: 012FB4:Skyrim.esm
VersionControl: 3696904
FormVersion: 40
Version2: 14
NavMeshVersion: 12
MapInfos:
- NavigationMesh: {fk(NAVMESH_ID)}
  Point: {cx}, 300.0, {FLOOR}
  Unknown2: -1511415748
  Parent:
    MutagenObjectType: NavigationMapInfoCellParent
    ParentCell: {fk(CELL_ID)}
""")

# --- In Tamriel ---------------------------------------------------------------------------------
tamriel = ["Worldspaces", "Tamriel - 00003C_Skyrim.esm", "TopCell", "Persistent"]
write(tamriel + [f"{PREFIX}WorldDoor - {WORLD_DOOR:06X}_{P}.yaml"], f"""MutagenObjectType: PlacedObject
FormKey: {fk(WORLD_DOOR)}
MajorRecordFlagsRaw: 1024
SkyrimMajorRecordFlags:
- 0x400
EditorID: {PREFIX}WorldDoor
Base: {CAVE_DOOR}
TeleportDestination:
  Door: {fk(INNER_DOOR)}
  Position: {door_x}, {north_in - 120}, {FLOOR}
  Rotation: 0, 0, 3.1415927
Placement:
  Position: {DOOR_POS[0]}, {DOOR_POS[1]}, {DOOR_POS[2]}
  Rotation: 0, 0, {DOOR_RZ}
""")
write(tamriel + [f"{PREFIX}WorldRock - {WORLD_ROCK:06X}_{P}.yaml"], f"""MutagenObjectType: PlacedObject
FormKey: {fk(WORLD_ROCK)}
MajorRecordFlagsRaw: 1024
SkyrimMajorRecordFlags:
- 0x400
EditorID: {PREFIX}WorldRock
Base: {CAVE_ROCK}
Placement:
  Position: {ROCK_POS[0]}, {ROCK_POS[1]}, {ROCK_POS[2]}
  Rotation: {ROCK_ROT[0]}, {ROCK_ROT[1]}, {ROCK_ROT[2]}
""")
write(tamriel + [f"{PREFIX}WorldMarker - {WORLD_MARKER:06X}_{P}.yaml"], f"""MutagenObjectType: PlacedObject
FormKey: {fk(WORLD_MARKER)}
MajorRecordFlagsRaw: 1024
SkyrimMajorRecordFlags:
- 0x400
EditorID: {PREFIX}WorldMarker
Base: {MAP_MARKER}
MapMarker:
  Flags:
  - Visible
  - CanTravelTo
  Name:
    TargetLanguage: English
    Value: Abandoned Mine
  Type: Mine
Placement:
  Position: {MAP_POS[0]}, {MAP_POS[1]}, {MAP_POS[2]}
  Rotation: 0, 0, {DOOR_RZ}
""")

# --- Records --------------------------------------------------------------------------------------
write(["Quests", f"{PREFIX}Quest - {QUEST_ID:06X}_{P}.yaml"], f"""FormKey: {fk(QUEST_ID)}
EditorID: {PREFIX}Quest
VirtualMachineAdapter:
  Scripts:
  - Name: {PREFIX}
  FileName: ''
  Aliases:
  - Property:
      Name: ''
      Object: {fk(QUEST_ID)}
      Alias: 1
    Scripts:
    - Name: {PREFIX}Boss
Priority: 60
Flags:
- StartGameEnabled
NextAliasID: 2
Aliases:
- Name: Player
  Flags: []
  ForcedReference: 000014:Skyrim.esm
  VoiceTypes: Null
- ID: 1
  Name: Overseer
  Flags:
  - Optional
  - AllowReuseInQuest
  - AllowDisabled
  - AllowDead
  VoiceTypes: Null
""")
write(["Globals", f"{PREFIX}HeldCount - {GLOBAL_ID:06X}_{P}.yaml"], f"""MutagenObjectType: GlobalInt
FormKey: {fk(GLOBAL_ID)}
EditorID: {PREFIX}HeldCount
Data: 0
""")
write(["Outfits", f"{PREFIX}Bare - {OUTFIT_ID:06X}_{P}.yaml"], f"""FormKey: {fk(OUTFIT_ID)}
EditorID: {PREFIX}Bare
Items: []
""")
write(["Activators", f"{PREFIX}RockFace - {ROCK_ID:06X}_{P}.yaml"], f"""FormKey: {fk(ROCK_ID)}
EditorID: {PREFIX}RockFace
VirtualMachineAdapter:
  Scripts:
  - Name: {PREFIX}Rock
ObjectBounds:
  First: -271, -269, -50
  Second: 231, 245, 67
Name:
  TargetLanguage: English
  Value: Rock Face
Model:
  File: Dungeons\\Mines\\Ore\\MineOreCorundum01.nif
MarkerColor: '#00CC4C33'
ActivateTextOverride:
  TargetLanguage: English
  Value: Dig
Flags: []
""")
write(["DialogBranches", f"{PREFIX}BuybackBranch - {BRANCH_ID:06X}_{P}.yaml"], f"""FormKey: {fk(BRANCH_ID)}
EditorID: {PREFIX}BuybackBranch
Quest: {fk(QUEST_ID)}
Category: Player
Flags:
- TopLevel
StartingTopic: {fk(TOPIC_ID)}
""")
topic = ["DialogTopics", f"{PREFIX}BuybackTopic - {TOPIC_ID:06X}_{P}"]
write(topic + ["RecordData.yaml"], f"""FormKey: {fk(TOPIC_ID)}
EditorID: {PREFIX}BuybackTopic
Name:
  TargetLanguage: English
  Value: "(Buy back someone who was sold to you)"
Priority: 50
Quest: {fk(QUEST_ID)}
SubtypeName: CUST
Branch: {fk(BRANCH_ID)}
""")
write(topic + ["Responses", f"{INFO_ID:06X}_{P}.yaml"], f"""FormKey: {fk(INFO_ID)}
PreviousDialog: Null
VirtualMachineAdapter:
  Scripts:
  - Name: {PREFIX}TIF
  ScriptFragments:
    MutagenObjectType: ScriptFragments
    FileName: {PREFIX}TIF
    OnEnd:
      ExtraBindDataVersion: 1
      ScriptName: {PREFIX}TIF
      FragmentName: Fragment_0
Flags:
  Flags:
  - Goodbye
FavorLevel: None
Responses:
- EmotionValue: 50
  ResponseNumber: 1
  Unknown2: 0x000000
  Unknown3: 0x000000
  Text:
    TargetLanguage: English
    Value: '...'
  ScriptNotes: ''
  Edits: ''
Conditions:
- MutagenObjectType: ConditionFloat
  Unknown1: 0x000000
  Data:
    MutagenObjectType: GetIsAliasRefConditionData
    ReferenceAliasIndex: 1
  ComparisonValue: 1
- MutagenObjectType: ConditionFloat
  CompareOperator: GreaterThan
  Unknown1: 0x000000
  Data:
    MutagenObjectType: GetGlobalValueConditionData
    Global: {fk(GLOBAL_ID)}
  ComparisonValue: 0
""")

# --- Assets --------------------------------------------------------------------------------------
ROLE = "A hard, plain-spoken mine overseer buying cheap labour for a worked-out mine, with money to spare and no patience."


def write_asset(root, rel, data):
    path = os.path.join(root, *rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(data)


def definition(file_id, name, buyer, kind, marker, event):
    return json.dumps({
        "string": {
            "id": file_id, "name": name, "plugin": P, "marker": hex(marker).upper().replace("0X", "0x"),
            "event": event, "for": kind, "buyer_name": buyer, "buyer_role": ROLE,
        },
        "int": {"api_version": 1, "buyer_female": 0},
    }, ensure_ascii=False, indent=2)


TEXTS = (
    ("assets", "Forced Labor in the Mine", "Resold to the Mine", "Mine Overseer",
     {"free": "You are free to go. Your belongings are in the chest.",
      "resold": "Your followers have been sold on to the Abandoned Mine.",
      "notYet": "Not yet", "tooMuch": "You do not have that much gold."}),
    (os.path.join(AUCTION, "japanese", "samples") if os.path.isdir(os.path.join(AUCTION, "japanese")) else os.path.join(os.path.dirname(PROJECT), "skyrimnet_SlaveAuction_Japanese", "samples"), "鉱山の強制労働", "鉱山へ転売", "鉱山の監督",
     {"free": "解放されました。持ち物は宝箱の中です。",
      "resold": "フォロワーは廃鉱へ転売されました。",
      "notYet": "まだしない", "tooMuch": "ゴールドが足りません。"}),
)
for root, labor, resold, buyer, strings in TEXTS:
    root = root if os.path.isabs(root) else os.path.join(PROJECT, root)
    exits = ["SKSE", "Plugins", "skyrimnet_SlaveAuction", "exits"]
    write_asset(root, exits + ["skyrimnet_SlaveAuction_mine_labor.json"],
                definition("skyrimnet_SlaveAuction_mine_labor", labor, buyer, "player_sold", ARRIVAL, PREFIX.replace("ExitMine", "ExitMine_PlayerSold")))
    write_asset(root, exits + ["skyrimnet_SlaveAuction_mine_resold.json"],
                definition("skyrimnet_SlaveAuction_mine_resold", resold, buyer, "followers_sold", HOLD, PREFIX.replace("ExitMine", "ExitMine_FollowersSold")))
    write_asset(root, ["SKSE", "Plugins", "skyrimnet_SlaveAuction_ExitMine", "strings.json"],
                json.dumps({"string": strings}, ensure_ascii=False, indent=2))

action = ["assets", "SKSE", "Plugins", "SkyrimNet", "external", "local.skyrimnet-slaveauction-exitmine"]
# manifest.json sits beside it, written by hand.
write_asset(PROJECT, action + ["dialogue_actions", "slave_auction_mine_player_only.yaml"], """kind: lists
name: Slave Auction mine player choices
description: Keeps the LLM from firing the buyback line; paying the overseer is the player's own choice.
blacklist:
  - skyrimnet_SlaveAuction_ExitMineQuest
  - skyrimnet_SlaveAuction_ExitMineTIF
""")
print("records written; last temporary", hex(next_id))
