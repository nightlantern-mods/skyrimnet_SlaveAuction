"""Generate the auction's entrance in Tamriel: a cave mouth near Riften, its load door and the map marker.

STAND is a point touching the mountain (MountainTrimSlab 0x05B42D, its face 29 units ahead), facing it
along HEADING. The door stands just in front of that face, on the ground, and the rock is placed around
it as the vanilla Nightingale Hall entrance places them (0x047D24 and 0x047D26), so that the rock's mouth
opens out of the mountain. The ground falls away from the door, so the rock is tilted about the door and
lowered until its outer edge meets the terrain. One arrives ARRIVAL_DISTANCE out of the door, on the rock's
floor.

Run after addPatch has copied the cell and the world's top cell into the project. Only these three
files are written. To move the entrance, change STAND and HEADING and run it again.
"""
import math
import os

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN = "skyrimnet_SlaveAuction.esp"
TAMRIEL = os.path.join(PROJECT, "plugin", "Worldspaces", "Tamriel - 00003C_Skyrim.esm")
CELL_DIR = os.path.join(TAMRIEL, "1, -1", "5, -3", "00BC6E_Skyrim.esm", "Temporary")
PERSISTENT_DIR = os.path.join(TAMRIEL, "TopCell", "Persistent")

STAND = (171018.83, -85120.14, 10139.44)
HEADING = math.radians(231.88)
DOOR_DISTANCE = 15.0
DOOR_RISE = 7.34                      # the terrain under the door, against STAND
ARRIVAL_DISTANCE = 250.0
ARRIVAL_RISE = -48.0                  # the rock's floor there, against the door
ROCK_TILT = (-0.12, -0.18)            # about the world's X and Y
ROCK_EXTRA_TURN = 0.1
ROCK_DROP = 40.0

ROCK = "0E0BA5:Skyrim.esm"            # RockCaveEntrance01FallForestDirt01
DOOR = "10C62A:Skyrim.esm"            # ImpWoodDoorCaveLoad01
MAP_MARKER = "000010:Skyrim.esm"

WORLD_DOOR = f"00082C:{PLUGIN}"
WORLD_MARKER = f"00082D:{PLUGIN}"
WORLD_ROCK = f"00082E:{PLUGIN}"
HALL_DOOR = f"000907:{PLUGIN}"
HALL_ARRIVAL = "-768, 1536, 256"      # the top of the stairs (gen_hall.py), facing down them
HALL_ARRIVAL_ANGLE = round(math.pi, 7)

# The door in the vanilla rock's own axes, and its turn against the rock.
DOOR_IN_ROCK = (251.2, -99.2, -21.19)
DOOR_TURN = -1.4988

door = (STAND[0] + DOOR_DISTANCE * math.sin(HEADING), STAND[1] + DOOR_DISTANCE * math.cos(HEADING), STAND[2] + DOOR_RISE)
arrival = (door[0] - ARRIVAL_DISTANCE * math.sin(HEADING), door[1] - ARRIVAL_DISTANCE * math.cos(HEADING), door[2] + ARRIVAL_RISE)
rock_angle = HEADING - DOOR_TURN + ROCK_EXTRA_TURN


def rock_axes(v):
    """The rock's own axes in the world: its rotation applies Z, then Y, then X, each clockwise."""
    s, c = math.sin(rock_angle), math.cos(rock_angle)
    x, y, z = v[0] * c + v[1] * s, -v[0] * s + v[1] * c, v[2]
    s, c = math.sin(ROCK_TILT[1]), math.cos(ROCK_TILT[1])
    x, z = x * c - z * s, x * s + z * c
    s, c = math.sin(ROCK_TILT[0]), math.cos(ROCK_TILT[0])
    return x, y * c + z * s, -y * s + z * c


offset = rock_axes(DOOR_IN_ROCK)
rock = (door[0] - offset[0], door[1] - offset[1], door[2] - offset[2] - ROCK_DROP)
assert math.floor(rock[0] / 4096) == 41 and math.floor(rock[1] / 4096) == -21, "the rock left the patched cell"

PERSISTENT = "MajorRecordFlagsRaw: 1024\n"
PERSISTENT_FLAGS = "SkyrimMajorRecordFlags:\n- 0x400\n"


def xyz(p):
    return f"{p[0]:.2f}, {p[1]:.2f}, {p[2]:.2f}"


def write(folder, name, text):
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, name), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


write(CELL_DIR, f"00082E_{PLUGIN}.yaml", f"""MutagenObjectType: PlacedObject
FormKey: {WORLD_ROCK}
Base: {ROCK}
Placement:
  Position: {xyz(rock)}
  Rotation: {ROCK_TILT[0]}, {ROCK_TILT[1]}, {rock_angle:.7f}
""")

write(PERSISTENT_DIR, f"skyrimnet_SlaveAuction_WorldDoor - 00082C_{PLUGIN}.yaml", f"""MutagenObjectType: PlacedObject
FormKey: {WORLD_DOOR}
{PERSISTENT}EditorID: skyrimnet_SlaveAuction_WorldDoor
{PERSISTENT_FLAGS}Base: {DOOR}
TeleportDestination:
  Door: {HALL_DOOR}
  Position: {HALL_ARRIVAL}
  Rotation: 0, 0, {HALL_ARRIVAL_ANGLE}
Placement:
  Position: {xyz(door)}
  Rotation: 0, 0, {HEADING:.7f}
""")

write(PERSISTENT_DIR, f"skyrimnet_SlaveAuction_WorldMarker - 00082D_{PLUGIN}.yaml", f"""MutagenObjectType: PlacedObject
FormKey: {WORLD_MARKER}
{PERSISTENT}EditorID: skyrimnet_SlaveAuction_WorldMarker
{PERSISTENT_FLAGS}Base: {MAP_MARKER}
MapMarker:
  Flags:
  - Visible
  - CanTravelTo
  Name:
    TargetLanguage: English
    Value: Underground Auction Hall
  Type: Cave
Placement:
  Position: {xyz(arrival)}
  Rotation: 0, 0, {HEADING - math.pi:.7f}
""")
print("door", xyz(door), "rock", xyz(rock), "arrival", xyz(arrival))
