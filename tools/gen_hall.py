"""Generate the auction hall: the interior cell of skyrimnet_SlaveAuction and everything in it.

A stone basement from the Imperial dungeon "SmallRoom" kit (256-unit tiles), laid out as in the
design sheet (north is up). The only way outside is the door at the top of the reception room's
stairs; the hall (7 tiles wide, 6 deep) has one door, locked, into the reception room:

                                         +------------------------------------+
    outside door                         |  cage for the player and followers |
         | stairs up (north)             +--door------------------------------+
    +----+-----------+                   | (2) guard                          |
    |                |                   |                          (4) stage |
    | (1) desk       +--- locked door ---+  (3) 4 x 3 chairs facing east      |
    |                |                   |                          (5) host  |
    +----------------+                   +------------------------------------+

The cage is built from the Imperial jail kit. A sealed 2 x 2 room east of the hall holds the
sold captives out of sight and the followers' confiscated belongings.

Re-running rewrites the placed references and keeps the navmesh, but moved walls need a new
navmesh from the Creation Kit.
"""
import json
import math
import os
import shutil


PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN = "skyrimnet_SlaveAuction.esp"
CELL_FORMKEY = f"000800:{PLUGIN}"
CELL_DIR = os.path.join(PROJECT, "plugin", "Cells", "8", "4", f"skyrimnetSlaveAuctionHall - 000800_{PLUGIN}")
# No underscores in the cell's editor ID: it goes into save file names, and the load menu does not
# list a save whose location adds to the name's underscore-separated fields.
CELL_NAME = "Underground Auction Hall"

T = 256            # tile size
W, D = 7, 6        # hall size in tiles (x, y)
Z = 0              # floor height

# --- Base objects (Skyrim.esm) ---------------------------------------------
# Imperial SmallRoom kit, at rotation 0. Each piece's wall side is where its bounds stop short of
# the tile edge; checked against FortHraggstad02 and the Solitude jail.
CORNER = {"NW": "029994:Skyrim.esm", "SW": "029997:Skyrim.esm",   # ImpRoomCorner01 / 02
          "SE": "029995:Skyrim.esm", "NE": "029996:Skyrim.esm"}   # ImpRoomCorner03 / 04
WALL = {"N": "029987:Skyrim.esm", "W": "02998E:Skyrim.esm",       # ImpRoomWall01 / 02
        "S": "02998F:Skyrim.esm", "E": "02998C:Skyrim.esm"}       # ImpRoomWall03 / 04
DOORWAY = {"N": "0299B0:Skyrim.esm", "W": "0299B1:Skyrim.esm",    # ImpRoomDoor01 / 02
           "S": "0299B2:Skyrim.esm", "E": "0299B3:Skyrim.esm"}    # ImpRoomDoor03 / 04
MID = "02998D:Skyrim.esm"            # ImpRoomMid01 (floor and ceiling)
# Inner face of each wall, measured from the centre of its edge tile.
WALL_IN = {"N": 105, "W": 107, "S": 117, "E": 109}

# Imperial SmallHall kit; pieces join 384 units from a stair centre (checked against Harmugstahl01).
STAIRS_NORTH = "038367:Skyrim.esm"   # ImpHallStairs02: at rz 0 the low end is south, the high end north, +256
HALL_STRAIGHT = "035B77:Skyrim.esm"  # ImpHall1Way01: at rz 0 open north and south

JAIL_WALL = "040BAF:Skyrim.esm"      # ImpJailWall01: bars, local x 0..260
JAIL_FRAME = "040BB1:Skyrim.esm"     # ImpJailDoorframe01, local x 0..260
JAIL_POLE = "040BAD:Skyrim.esm"      # ImpJailPole01
JAIL_DOOR = "040BB2:Skyrim.esm"      # ImpJailDoor01, at its frame's position and rotation
JAIL_PIECE = 260

DOOR = "042035:Skyrim.esm"           # ImpDoorSingle01 (no load door: the scripts move people)
OUTSIDE_DOOR = "04203A:Skyrim.esm"   # ImpDoorSingleLoad01, to the cave mouth (gen_entrance.py)
CHAIR = "02EC1C:Skyrim.esm"          # CommonChair01, front at local +y
TABLE = "024CB9:Skyrim.esm"          # CommonTable01
CHEST = "0F8476:Skyrim.esm"          # LargeChestNoRespawn
MARKER = "000034:Skyrim.esm"         # XMarkerHeading
COC = "000032:Skyrim.esm"            # COCMarkerHeading
NORTH = "000003:Skyrim.esm"          # NorthMarker
LIGHT = "06FF42:Skyrim.esm"          # SolitudeInnLight02Sm
ROOM_LIGHT = f"00082A:{PLUGIN}"      # these two: see gen_records.py
STAGE_LIGHT = f"00082B:{PLUGIN}"
BRAZIER = "05F227:Skyrim.esm"        # ImpBrazier01
STAGE_PLATFORM = "03E203:Skyrim.esm" # ImpFloorPiece02: 566 x 564, top at about +55
STAGE_TOP = 55
HAY = "03103A:Skyrim.esm"            # HayMound02
HAY_SCATTER = "019B19:Skyrim.esm"    # HayScatter05

# --- NPCs of this plugin (see plugin/Npcs) ----------------------------------
NPC_RECEPTIONIST = f"000805:{PLUGIN}"
NPC_GUARD = f"000806:{PLUGIN}"
NPC_AUCTIONEER = f"000807:{PLUGIN}"
NPC_BUYERS = [f"{0x808 + i:06X}:{PLUGIN}" for i in range(12)]
NPC_LIBERATOR = f"000814:{PLUGIN}"
NPC_DESIGNATED = {"DesignatedBuyerMale": f"000830:{PLUGIN}", "DesignatedBuyerFemale": f"000831:{PLUGIN}"}

# --- Packages (Skyrim.esm), each acting on the actor's linked reference ------
# The NPC records carry them; listed here only to explain the linked references below.
#   staff:  DefaultHoldPositionLinkedRef128 -> their marker
#   buyers: defaultSitLinkedRefNoConv       -> their chair

# Fixed FormIDs: the scripts look these references up with Game.GetFormFromFile, so they never
# change. 0x900-0x93F are named references; everything else is numbered from 0x940.
REF_IDS = {
    "CageMarker": 0x900, "StageMarker": 0x901, "AuctioneerMarker": 0x902, "ExitAreaMarker": 0x903,
    "HoldingMarker": 0x904, "CageDoor": 0x905, "HallDoor": 0x906, "OutsideDoor": 0x907,
    "PlayerChest": 0x908,
    "FollowerChest0": 0x909, "FollowerChest1": 0x90A, "FollowerChest2": 0x90B,
    "FollowerChest3": 0x90C, "FollowerChest4": 0x90D,
    "LiberatorMarker": 0x90E, "BuyerExitMarker": 0x90F,
    "Receptionist": 0x910, "Guard": 0x911, "Auctioneer": 0x912,
    **{f"Buyer{i:02d}": 0x913 + i for i in range(12)},
    "Liberator0": 0x91F, "Liberator1": 0x920, "Liberator2": 0x921,
    "ReceptionMarker": 0x923, "GuardMarker": 0x924,
    **{f"FollowerChest{i}": 0x925 + i - 5 for i in range(5, 10)},
    **{f"Chair{i:02d}": 0x930 + i for i in range(12)},
    "DesignatedBuyerMale": 0x93C, "DesignatedBuyerFemale": 0x93D, "GuestChair": 0x93E,
}

objects = []   # (name, base, x, y, z, rz_deg, extra) ; name None = unnamed temporary reference
actors = []    # (name, base, x, y, z, rz_deg, linked_name)


def add(name, base, x, y, z=Z, rz=0, persistent=False):
    objects.append((name, base, round(x, 1), round(y, 1), round(z, 1), rz % 360, persistent))


def add_actor(name, base, x, y, rz, linked, z=Z):
    actors.append((name, base, round(x, 1), round(y, 1), z, rz % 360, linked))


def room(x0, y0, w, d, doors=()):
    """A w x d room of the SmallRoom kit with its south-west tile centred on (x0, y0).
    doors: (side, index) pairs; index counts tiles along that side from the west or south."""
    for ix in range(w):
        for iy in range(d):
            x, y = x0 + ix * T, y0 + iy * T
            west, east, south, north = ix == 0, ix == w - 1, iy == 0, iy == d - 1
            if (south or north) and (west or east):
                add(None, CORNER[("N" if north else "S") + ("W" if west else "E")], x, y)
            elif west or east or south or north:
                side = "W" if west else "E" if east else "S" if south else "N"
                along = iy if side in "WE" else ix
                add(None, DOORWAY[side] if (side, along) in doors else WALL[side], x, y)
            else:
                add(None, MID, x, y)


# --- The hall -----------------------------------------------------------------
HALL_DOOR_ROW = 1
room(0, 0, W, D, doors=(("W", HALL_DOOR_ROW),))
west_in = -WALL_IN["W"]
east_in = (W - 1) * T + WALL_IN["E"]
south_in = -WALL_IN["S"]
north_in = (D - 1) * T + WALL_IN["N"]

# The door in the west doorway: half a tile west of the tile centre, as in FortHraggstad02.
add("HallDoor", DOOR, -T / 2, HALL_DOOR_ROW * T, rz=270, persistent=True)
add(None, NORTH, 0, 0, z=Z + 64)

# --- Cage (north band, wall to wall): a front line of bars -------------------------
CAGE_X = west_in - 30      # starts inside the west wall
CAGE_Y = 3.5 * T           # front line
DOOR_PIECE = 1             # the front line's second piece is the door frame
front_pieces = math.ceil((east_in - CAGE_X) / JAIL_PIECE)
for k in range(front_pieces):
    x = CAGE_X + k * JAIL_PIECE
    if k == DOOR_PIECE:
        add(None, JAIL_FRAME, x, CAGE_Y)
        add("CageDoor", JAIL_DOOR, x, CAGE_Y, persistent=True)
    else:
        add(None, JAIL_WALL, x, CAGE_Y)
    add(None, JAIL_POLE, x, CAGE_Y)
cage_cx, cage_cy = (CAGE_X + east_in) / 2, (CAGE_Y + north_in) / 2
add("CageMarker", MARKER, cage_cx, cage_cy, rz=180, persistent=True)
for i, (hx, hy) in enumerate(((CAGE_X + 160, north_in - 70), (cage_cx + 250, north_in - 60), (east_in - 120, CAGE_Y + 120))):
    add(None, HAY, hx, hy, rz=40 * i)
for i, hx in enumerate((CAGE_X + 380, cage_cx - 80, east_in - 300)):
    add(None, HAY_SCATTER, hx, cage_cy - 40 * (i % 2), rz=70 * i)

# --- (2) The cage guard, in front of the cage door ------------------------------
door_x = CAGE_X + DOOR_PIECE * JAIL_PIECE + JAIL_PIECE / 2
add("GuardMarker", MARKER, door_x + 90, CAGE_Y - 70, rz=0, persistent=True)
add_actor("Guard", NPC_GUARD, door_x + 90, CAGE_Y - 70, 0, "GuardMarker")

# --- (3) Twelve buyers on chairs, 4 columns x 3 rows, facing the stage (east) -------
CHAIR_COLUMNS = (330, 520, 710, 900)
CHAIR_ROWS = (120, 330, 540)
n = 0
for cx in CHAIR_COLUMNS:
    for cy in CHAIR_ROWS:
        add(f"Chair{n:02d}", CHAIR, cx, cy, rz=90, persistent=True)
        add_actor(f"Buyer{n:02d}", NPC_BUYERS[n], cx, cy, 90, f"Chair{n:02d}")
        if n == 11:   # the seat an exit mod's buyer takes from Lady Livia
            for designated, base in NPC_DESIGNATED.items():
                add_actor(designated, base, cx, cy, 90, f"Chair{n:02d}")
        n += 1

# The player's own seat when they come to bid, behind the third column.
add("GuestChair", CHAIR, CHAIR_COLUMNS[2], CHAIR_ROWS[2] + 210, rz=90)

# --- (4) The stage and (5) the auctioneer, against the east wall ------------------
# The X cross (ZaZ) is placed on StageMarker at run time, so ZaZ is no master of the plugin.
# A raised stone platform, so the buyers look up at the lot and the auctioneer.
stage_x = east_in - 190
add(None, STAGE_PLATFORM, stage_x - 20, 330)
add("StageMarker", MARKER, stage_x, 330, z=STAGE_TOP, rz=270, persistent=True)
add("AuctioneerMarker", MARKER, stage_x - 20, 110, z=STAGE_TOP, rz=270, persistent=True)
add_actor("Auctioneer", NPC_AUCTIONEER, stage_x - 20, 110, 270, "AuctioneerMarker", z=STAGE_TOP)
add(None, BRAZIER, east_in - 70, 600, z=STAGE_TOP)
add(None, BRAZIER, east_in - 70, 40, z=STAGE_TOP)

# --- The hall door: the player's chest, and where the rescue happens ---------------
exit_y = HALL_DOOR_ROW * T
add("ExitAreaMarker", MARKER, west_in + 160, exit_y, rz=90, persistent=True)
add("BuyerExitMarker", MARKER, west_in + 90, exit_y + 110, rz=180, persistent=True)
add("LiberatorMarker", MARKER, west_in + 260, exit_y - 140, rz=315, persistent=True)
add("PlayerChest", CHEST, west_in + 45, south_in + 70, rz=90, persistent=True)
for i in range(3):
    add_actor(f"Liberator{i}", NPC_LIBERATOR, west_in + 260 + 60 * i, exit_y - 140 - 30 * i, 315, "LiberatorMarker")

# --- Light ---------------------------------------------------------------------
for lx, ly in ((300, 1150), (1200, 1150), (350, 330), (850, 330)):
    add(None, ROOM_LIGHT, lx, ly, z=Z + 250)
# On the buyers' side of the lot and of the auctioneer, so what the buyers see is lit.
add(None, STAGE_LIGHT, stage_x - 165, 330, z=STAGE_TOP + 220)
add(None, STAGE_LIGHT, stage_x - 145, 110, z=STAGE_TOP + 220)

# --- Reception room, west of the hall: its east door is the hall door --------------
RW, RD = 4, 4
RX = -RW * T
STAIR_COLUMN = 1
room(RX, 0, RW, RD, doors=(("E", HALL_DOOR_ROW), ("N", STAIR_COLUMN)))
rec_west = RX - WALL_IN["W"]
rec_north = (RD - 1) * T

# (1) The receptionist, behind a table against the west wall
rec_x, rec_y = rec_west + 70, 380
add("ReceptionMarker", MARKER, rec_x, rec_y, rz=90, persistent=True)
add_actor("Receptionist", NPC_RECEPTIONIST, rec_x, rec_y, 90, "ReceptionMarker")
add(None, TABLE, rec_x + 95, rec_y, rz=90)
add(None, BRAZIER, rec_west + 70, rec_north + 40)
add(None, BRAZIER, -180, rec_north + 40)
add(None, ROOM_LIGHT, RX + 1.5 * T, 1.5 * T, z=Z + 250)

# The stairs up from the north doorway to the only door outside
stair_x = RX + STAIR_COLUMN * T
add("COCMarker", COC, stair_x, rec_north - 120, rz=180)
stair_y = rec_north + 384
add(None, STAIRS_NORTH, stair_x, stair_y)
add(None, HALL_STRAIGHT, stair_x, stair_y + 384, z=Z + 256)
add("OutsideDoor", OUTSIDE_DOOR, stair_x, stair_y + 384 + T / 2, z=Z + 256, rz=0, persistent=True)
add(None, ROOM_LIGHT, stair_x, stair_y + 384, z=Z + 256 + 200)

# --- Holding room: sealed, east of the hall, never reached on foot ---------------
HX = (W + 5) * T
room(HX, 0, 2, 2)
add("HoldingMarker", MARKER, HX + T / 2, T / 2, rz=0, persistent=True)
for i in range(10):
    add(f"FollowerChest{i}", CHEST, HX - 60 + 70 * (i % 5), -60 + 90 * (i // 5), rz=0, persistent=True)
add(None, LIGHT, HX + T / 2, T / 2, z=Z + 250)

# --- Write ---------------------------------------------------------------------
CELL_YAML = """FormKey: {formkey}
EditorID: skyrimnetSlaveAuctionHall
Name:
  TargetLanguage: English
  Value: {name}
Flags:
- IsInteriorCell
Lighting:
  AmbientColor: '#00000000'
  DirectionalColor: '#00000000'
  FogNearColor: '#00000000'
  FogPower: 1
  AmbientColors:
    DirectionalXPlus: '#002C2418'
    DirectionalXMinus: '#00232415'
    DirectionalYPlus: '#00282517'
    DirectionalYMinus: '#00282217'
    DirectionalZPlus: '#0013110A'
    DirectionalZMinus: '#003C3623'
    Specular: '#00000000'
    Scale: 1
  FogFarColor: '#00000000'
  FogMax: 1
  Inherits:
  - AmbientColor
  - DirectionalColor
  - FogColor
  - FogNear
  - FogFar
  - DirectionalRotation
  - DirectionalFade
  - ClipDistance
  - FogPower
  - FogMax
LightingTemplate: 06909B:Skyrim.esm  # ImperialFortCloseTemplate
WaterHeight: -2.1474836E+09
AcousticSpace: 04075D:Skyrim.esm  # IntDungeonFortAcousticSpace
Music: 05615B:Skyrim.esm  # MUSDungeonFort
ImageSpace: 0A2687:Skyrim.esm  # DefaultImageSpaceDungeon
"""

REF_YAML = """MutagenObjectType: PlacedObject
FormKey: {formkey}
{persistent}{editorid}Base: {base}
{extra}Placement:
  Position: {x}, {y}, {z}
  Rotation: 0, 0, {rz}
"""

NPC_YAML = """MutagenObjectType: PlacedNpc
FormKey: {formkey}
MajorRecordFlagsRaw: 1024
EditorID: {editorid}
SkyrimMajorRecordFlags:
- 0x400
Base: {base}
LinkedReferences:
- Reference: {linked}
Placement:
  Position: {x}, {y}, {z}
  Rotation: 0, 0, {rz}
MajorFlags:
- Persistent
"""
PERSISTENT = "MajorRecordFlagsRaw: 1024\nSkyrimMajorRecordFlags:\n- 0x400\n"
# Arrival outside: on the floor of the cave mouth (ARRIVAL in gen_entrance.py), facing away from the door.
REF_EXTRA = {"OutsideDoor": f"""TeleportDestination:
  Door: 00082C:{PLUGIN}
  Position: 171203.71, -84975.07, 10098.78
  Rotation: 0, 0, 0.9055
"""}


def rad(deg):
    return round(math.radians(deg % 360), 7)


def formkey_of(name):
    return f"{REF_IDS[name]:06X}:{PLUGIN}"


def editorid_of(name):
    return f"skyrimnet_SlaveAuction_{name}"


def file_name(formkey, editorid=None):
    name = formkey.replace(":", "_") + ".yaml"
    return f"{editorid} - {name}" if editorid else name


# Regenerate the placed refs only: the navmesh comes from the Creation Kit and must survive a re-run.
for folder in ("Temporary", "Persistent"):
    if os.path.isdir(os.path.join(CELL_DIR, folder)):
        shutil.rmtree(os.path.join(CELL_DIR, folder))
    os.makedirs(os.path.join(CELL_DIR, folder))
with open(os.path.join(os.path.dirname(CELL_DIR), "GroupRecordData.yaml"), "w", encoding="utf-8") as f:
    f.write("BlockNumber: 4\nGroupType: InteriorCellSubBlock\n")
with open(os.path.join(os.path.dirname(os.path.dirname(CELL_DIR)), "GroupRecordData.yaml"), "w", encoding="utf-8") as f:
    f.write("BlockNumber: 8\nGroupType: InteriorCellBlock\n")
with open(os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(CELL_DIR))), "GroupRecordData.yaml"), "w", encoding="utf-8") as f:
    f.write("{}\n")
with open(os.path.join(CELL_DIR, "RecordData.yaml"), "w", encoding="utf-8") as f:
    f.write(CELL_YAML.format(formkey=CELL_FORMKEY, name=json.dumps(CELL_NAME)))

next_id = 0x940
for name, base, x, y, z, rz, persistent in objects:
    if name in REF_IDS:
        formkey, editorid = formkey_of(name), editorid_of(name)
    else:
        formkey, editorid = f"{next_id:06X}:{PLUGIN}", None
        next_id += 1
    text = REF_YAML.format(formkey=formkey, base=base, x=x, y=y, z=z, rz=rad(rz),
                           persistent=PERSISTENT if persistent else "",
                           extra=REF_EXTRA.get(name, ""),
                           editorid=f"EditorID: {editorid}\n" if editorid else "")
    folder = "Persistent" if persistent else "Temporary"
    with open(os.path.join(CELL_DIR, folder, file_name(formkey, editorid)), "w", encoding="utf-8") as f:
        f.write((f"# {name}\n" if name else "") + text)

for name, base, x, y, z, rz, linked in actors:
    # "Ref": the NPC records (gen_records.py) already carry the plain editor IDs.
    formkey, editorid = formkey_of(name), editorid_of(name) + "Ref"
    text = NPC_YAML.format(formkey=formkey, editorid=editorid, base=base, linked=formkey_of(linked),
                           x=x, y=y, z=z, rz=rad(rz))
    if name in NPC_DESIGNATED:   # initially disabled
        text = text.replace("MajorRecordFlagsRaw: 1024", "MajorRecordFlagsRaw: 3072").replace("- 0x400\n", "- 0x400\n- 0x800\n").replace("- Persistent\n", "- Persistent\n- InitiallyDisabled\n")
    with open(os.path.join(CELL_DIR, "Persistent", file_name(formkey, editorid)), "w", encoding="utf-8") as f:
        f.write(f"# {name}\n" + text)

assert next_id <= 0xFFF, "out of light-plugin FormIDs"
print(f"{len(objects)} objects and {len(actors)} actors written to {CELL_DIR} (temporaries up to {next_id - 1:03X})")
