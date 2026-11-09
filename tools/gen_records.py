"""Generate the records of skyrimnet_SlaveAuction other than the hall cell (see gen_hall.py):
factions, the state global, the looks lists, the NPCs, the quest and its two dialogue topics.

FormIDs are fixed here, because the scripts look most of these records up by FormID.
Run once for the first draft; afterwards edit the YAML.
"""
import json
import os


PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN = "skyrimnet_SlaveAuction.esp"
OUT = os.path.join(PROJECT, "plugin")
PREFIX = "skyrimnet_SlaveAuction_"


def fk(local_id):
    return f"{local_id:06X}:{PLUGIN}"


def quoted(text):
    return json.dumps(text)


def write(group, editorid, local_id, body, sub=None, file_name=None, object_type=None):
    folder = os.path.join(OUT, group, *(sub or []))
    os.makedirs(folder, exist_ok=True)
    if not file_name:
        file_name = f"{editorid} - {local_id:06X}_{PLUGIN}.yaml" if editorid else f"{local_id:06X}_{PLUGIN}.yaml"
    with open(os.path.join(folder, file_name), "w", encoding="utf-8") as f:
        f.write((f"MutagenObjectType: {object_type}\n" if object_type else "") + f"FormKey: {fk(local_id)}\n"
                + (f"EditorID: {editorid}\n" if editorid else "") + body)


# --- FormIDs ---------------------------------------------------------------
QUEST = 0x801
STAFF_FACTION, BUYER_FACTION, LIBERATOR_FACTION, CAPTIVE_FACTION = 0x802, 0x815, 0x816, 0x817
LOOKS_MALE, LOOKS_FEMALE = 0x803, 0x804
RECEPTIONIST, GUARD, AUCTIONEER = 0x805, 0x806, 0x807
BUYERS = list(range(0x808, 0x814))
LIBERATOR = 0x814
STATE_GLOBAL = 0x818
HOLD_PACKAGE = 0x819
DRINK_BRANCH, DRINK_TOPIC, DRINK_INFO = 0x820, 0x821, 0x822
CHOOSE_BRANCH, CHOOSE_TOPIC, CHOOSE_INFO = 0x823, 0x824, 0x825
HELLO_TOPIC, HELLO_INFO, GUARD_HELLO_INFO = 0x826, 0x827, 0x828
BARE_OUTFIT = 0x829
BUYBACK_GLOBAL = 0x832
OFFER_BRANCH, OFFER_TOPIC, OFFER_INFO = 0x833, 0x834, 0x835
BUYBACK_BRANCH, BUYBACK_TOPIC, BUYBACK_INFO = 0x836, 0x837, 0x838
ROOM_LIGHT, STAGE_LIGHT = 0x82A, 0x82B
# Placed references (gen_hall.py)
OUTSIDE_DOOR_REF = 0x907

# --- Skyrim.esm ------------------------------------------------------------
CITIZEN = "01326B:Skyrim.esm"                  # Citizen
WARRIOR = "013176:Skyrim.esm"                  # CombatWarrior1H
NORD = "013746:Skyrim.esm"                     # NordRace (overridden by the looks template)
MALE_NORD, FEMALE_NORD = "013AE6:Skyrim.esm", "013AE7:Skyrim.esm"
FINE_CLOTHES = "09D5E0:Skyrim.esm"             # FineClothesOutfit01
IRON_ARMOR = "01697C:Skyrim.esm"               # ArmorIronAllOutfit
LEATHER_ARMOR = "057A2A:Skyrim.esm"            # ArmorLeatherAllOutfit
SLEEP_OUTFIT = "01697D:Skyrim.esm"             # DefaultSleepOutfit
IRON_SWORD = "012EB7:Skyrim.esm"
HOLD_LINKED_256 = "0B4598:Skyrim.esm"          # DefaultHoldPositionLinkedRef256
SIT_LINKED = "0ECEEB:Skyrim.esm"               # defaultSitLinkedRefNoConv
# Vanilla generic NPCs with FaceGen, used as Traits templates (as skyrimnet_Brothel does).
MALE_LOOKS = ["073FBD", "073FBF", "073FC0", "073FC1", "01BCD8", "039CF6", "039CF9", "039CFA",
              "0C3CA0", "03DE8A", "03DE88", "03DE8D", "03DE8B"]
FEMALE_LOOKS = ["0BFB45", "0BFB48", "0BFB47", "0BFB46", "039CF7", "039CF5", "039CF8", "03DE87",
                "03DE89", "03DE8C"]

# --- Factions: SkyrimNet's prompts tell the roles apart by faction and rank. Ranks start at 1:
# get_faction_rank gives no rank above 0 to a non-member. -------------------------------------
FACTIONS = [
    (STAFF_FACTION, "StaffFaction", "Slave Auction Staff"),      # rank 1 receptionist, 2 guard, 3 auctioneer
    (BUYER_FACTION, "BuyerFaction", "Slave Auction Buyer"),      # rank = buyer number + 1
    (LIBERATOR_FACTION, "LiberatorFaction", "Slave Auction Liberator"),
    (CAPTIVE_FACTION, "CaptiveFaction", "Slave Auction Captive"),  # rank 1 in the cage, 2 sold
]
for local_id, name, display in FACTIONS:
    write("Factions", PREFIX + name, local_id, f"Name:\n  TargetLanguage: English\n  Value: {display}\nFlags:\n- HiddenFromPC\n")

# 0 idle, 1 captives in the cage, 2 a lot on the stage, 3 freed (the exit is open)
write("Globals", PREFIX + "State", STATE_GLOBAL, "Data: 0\n", object_type="GlobalShort")
write("Globals", PREFIX + "BuybackCount", BUYBACK_GLOBAL, "Data: 0\n", object_type="GlobalShort")

# --- Looks ------------------------------------------------------------------
for local_id, name, refs in ((LOOKS_MALE, "LooksMale", MALE_LOOKS), (LOOKS_FEMALE, "LooksFemale", FEMALE_LOOKS)):
    entries = "".join(f"- Data:\n    Level: 1\n    Reference: {r}:Skyrim.esm\n    Count: 1\n" for r in refs)
    write("LeveledNpcs", PREFIX + name, local_id,
          "Flags:\n- CalculateFromAllLevelsLessThanOrEqualPlayer\n- CalculateForEachItemInCount\nEntries:\n" + entries)

# --- Outfits ------------------------------------------------------------------
# Captive followers wear this: an NPC puts its outfit back on whenever its inventory changes.
write("Outfits", PREFIX + "BareOutfit", BARE_OUTFIT, "Items: []\n")

# --- Lights -------------------------------------------------------------------
# Players who keep interiors dark must still see the room, and above all the lot and the auctioneer.
# No shadows, and few enough to stay within the four lights a mesh can take without flickering.
LIGHT_YAML = """ObjectBounds:
  First: -38, -40, -74
  Second: 38, 40, 48
Time: -1
Radius: {radius}
Color: '{color}'
Flags:
- Dynamic
- PortalStrict
FalloffExponent: 1
FOV: 90
NearClip: 1
FlickerPeriod: 1
FadeValue: {fade}
"""
write("Lights", PREFIX + "RoomLight", ROOM_LIGHT, LIGHT_YAML.format(radius=560, color="#00E2D994", fade=1.2))
write("Lights", PREFIX + "StageLight", STAGE_LIGHT, LIGHT_YAML.format(radius=400, color="#00FFEFD0", fade=2.4))

# --- Packages -----------------------------------------------------------------
# DefaultHoldPositionLinkedRef128 without its WeaponDrawn flag: the staff stand at ease.
HOLD_LINKED = fk(HOLD_PACKAGE)
write("Packages", PREFIX + "HoldLinkedRefAtEase", HOLD_PACKAGE, """FormVersion: 35
Version2: 1
Type: Package
InterruptOverride: Combat
PreferredSpeed: Walk
Unknown: 130
ScheduleMonth: -1
ScheduleDayOfWeek: Any
ScheduleHour: -1
ScheduleMinute: -1
Unknown3: 0x000000
PackageTemplate: 0503D0:Skyrim.esm  # HoldPosition
DataInputVersion: 5
Data:
- Key: 0
  Value:
    MutagenObjectType: PackageDataLocation
    Location:
      Target:
        MutagenObjectType: LocationKeyword
      Radius: 32
XnamMarker: 0x06
OnBegin:
  Topics:
  - MutagenObjectType: TopicReference
OnEnd:
  Topics:
  - MutagenObjectType: TopicReference
OnChange:
  Topics:
  - MutagenObjectType: TopicReference
""")

# --- NPCs -------------------------------------------------------------------
NPC_YAML = """Configuration:
  Flags:
{flags}  Level: {{MutagenObjectType: PcLevelMult, LevelMult: 1}}
  CalcMinLevel: 5
  CalcMaxLevel: 30
  SpeedMultiplier: 100
  TemplateFlags:
  - Traits
Factions:
- Faction: {faction}
  Rank: {rank}
Template: {template}
Voice: {voice}
Race: {race}
{items}Class: {cls}
Name:
  TargetLanguage: English
  Value: {name}
AIData:
  Aggression: Unaggressive
  Confidence: {confidence}
  EnergyLevel: 50
  Responsibility: NoCrime
Packages:
- {package}
DefaultOutfit: {outfit}
SleepingOutfit: {sleep}
"""


def npc(local_id, editorid, name, *, female, template, faction, rank, cls=CITIZEN, outfit=FINE_CLOTHES,
        package=HOLD_LINKED, flags=(), confidence="Average", weapon=False):
    all_flags = (["Female"] if female else []) + list(flags) + ["AutoCalcStats"]
    items = f"Items:\n- Item:\n    Item: {IRON_SWORD}\n    Count: 1\n" if weapon else ""
    write("Npcs", PREFIX + editorid, local_id, NPC_YAML.format(
        flags="".join(f"  - {f}\n" for f in all_flags), faction=fk(faction), rank=rank, template=template,
        voice=FEMALE_NORD if female else MALE_NORD, race=NORD, items=items, cls=cls, name=quoted(name),
        confidence=confidence, package=package, outfit=outfit, sleep=SLEEP_OUTFIT))


npc(RECEPTIONIST, "Receptionist", "Mira the Receptionist", female=True, template="039CF7:Skyrim.esm",
    faction=STAFF_FACTION, rank=1, flags=["Essential"])
npc(GUARD, "Guard", "Grom the Cage Keeper", female=False, template="01BCD8:Skyrim.esm",
    faction=STAFF_FACTION, rank=2, cls=WARRIOR, outfit=IRON_ARMOR, flags=["Essential"], confidence="Brave", weapon=True)
npc(AUCTIONEER, "Auctioneer", "Marcus the Auctioneer", female=False, template="039CF6:Skyrim.esm",
    faction=STAFF_FACTION, rank=3, flags=["Essential"])

# Buyer number i sits on chair i (gen_hall.py). Female buyers take the female looks.
BUYER_NAMES = [
    ("Halvard the Fur Trader", False), ("Orgnar the Mine Owner", False), ("Old Lord Sextius", False),
    ("Velara the Brothel Madam", True), ("Brolf the Mercenary Captain", False), ("East Empire Company Broker", False),
    ("Ingrid the Widow", True), ("Garnius the Smuggler Captain", False), ("Falmir the Alchemist", False),
    ("Saphira the Merchant", True), ("Vighard the Landowner", False), ("Lady Livia", True),
]
for i, (local_id, (name, female)) in enumerate(zip(BUYERS, BUYER_NAMES)):
    npc(local_id, f"Buyer{i:02d}", name, female=female, template=fk(LOOKS_FEMALE if female else LOOKS_MALE),
        faction=BUYER_FACTION, rank=i + 1, package=SIT_LINKED, confidence="Cowardly")

# The twelfth seat when an exit mod names its buyer: placed disabled, renamed by the script, and
# told apart in the bio by rank 13 and up, where the exit's own buyer_role is used.
for local_id, editorid, female, rank in ((0x830, "DesignatedBuyerMale", False, 13), (0x831, "DesignatedBuyerFemale", True, 14)):
    npc(local_id, editorid, "Private Buyer", female=female, template=fk(LOOKS_FEMALE if female else LOOKS_MALE),
        faction=BUYER_FACTION, rank=rank, package=SIT_LINKED, confidence="Cowardly")

npc(LIBERATOR, "Liberator", "Liberator", female=False, template=fk(LOOKS_MALE),
    faction=LIBERATOR_FACTION, rank=1, cls=WARRIOR, outfit=LEATHER_ARMOR, package=HOLD_LINKED_256,
    flags=["Protected"], confidence="Brave", weapon=True)

# --- Quest --------------------------------------------------------------------
write("Quests", PREFIX + "Quest", QUEST, f"""VirtualMachineAdapter:
  Scripts:
  - Name: skyrimnet_SlaveAuction
  FileName: ''
  Aliases:
  - Property:
      Name: ''
      Object: {fk(QUEST)}
      Alias: 0
    Scripts:
    - Name: skyrimnet_SlaveAuctionPlayer
  - Property:
      Name: ''
      Object: {fk(QUEST)}
      Alias: 1
    Scripts:
    - Name: skyrimnet_SlaveAuctionDoor
Priority: 60
Flags:
- StartGameEnabled
NextAliasID: 3
Aliases:
- Name: Player
  Flags: []
  ForcedReference: 000014:Skyrim.esm
  VoiceTypes: Null
- ID: 1
  Name: OutsideDoor
  Flags: []
  ForcedReference: {fk(OUTSIDE_DOOR_REF)}
  VoiceTypes: Null
""")

# --- Dialogue: the receptionist's drink and the guard's "who goes next" --------------
CONDITION = """- MutagenObjectType: ConditionFloat
  Unknown1: 0x000000
  Data:
    MutagenObjectType: {data}
    {field}: {value}
  ComparisonValue: {cmp}
"""


# The receptionist serves anyone who is not held; the others speak in one state only.
STATE_NOT_HELD = "not held"
# Buying back works between lots too: the player may be a guest, and a sold lot is there at once.
STATE_NOT_ON_STAGE = "not on stage"
HELD_STATES = (1, 2)


def speaker_conditions(speaker, state):
    conditions = CONDITION.format(data="GetIsIDConditionData", field="Object", value=fk(speaker), cmp=1)
    if state == STATE_NOT_HELD:
        for held in HELD_STATES:
            conditions += "- MutagenObjectType: ConditionFloat\n  CompareOperator: NotEqualTo\n" \
                + CONDITION.format(data="GetGlobalValueConditionData", field="Global", value=fk(STATE_GLOBAL), cmp=held) \
                .split("\n", 1)[1]
        return conditions
    if state == STATE_NOT_ON_STAGE:
        return conditions + "- MutagenObjectType: ConditionFloat\n  CompareOperator: NotEqualTo\n" \
            + CONDITION.format(data="GetGlobalValueConditionData", field="Global", value=fk(STATE_GLOBAL), cmp=2).split("\n", 1)[1]
    return conditions + CONDITION.format(data="GetGlobalValueConditionData", field="Global", value=fk(STATE_GLOBAL), cmp=state)


def topic(branch_id, topic_id, info_id, name, prompt, line, speaker, state, fragment_script, extra_conditions=""):
    write("DialogBranches", PREFIX + name + "Branch", branch_id,
          f"Quest: {fk(QUEST)}\nCategory: Player\nFlags:\n- TopLevel\nStartingTopic: {fk(topic_id)}\n")
    topic_folder = f"{PREFIX}{name}Topic - {topic_id:06X}_{PLUGIN}"
    write("DialogTopics", PREFIX + name + "Topic", topic_id,
          f"Name:\n  TargetLanguage: English\n  Value: {quoted(prompt)}\nPriority: 50\nQuest: {fk(QUEST)}\n"
          f"SubtypeName: CUST\nBranch: {fk(branch_id)}\n", sub=[topic_folder], file_name="RecordData.yaml")
    conditions = speaker_conditions(speaker, state) + extra_conditions
    write("DialogTopics", None, info_id, f"""PreviousDialog: Null
VirtualMachineAdapter:
  Scripts:
  - Name: {fragment_script}
  ScriptFragments:
    MutagenObjectType: ScriptFragments
    FileName: {fragment_script}
    OnEnd:
      ExtraBindDataVersion: 1
      ScriptName: {fragment_script}
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
    Value: {quoted(line)}
  ScriptNotes: ''
  Edits: ''
Conditions:
{conditions}""", sub=[topic_folder, "Responses"])


topic(DRINK_BRANCH, DRINK_TOPIC, DRINK_INFO, "Drink", "(Drink the rare liquor she offers)",
      "Heh. There you are. Down it in one, now.", RECEPTIONIST, STATE_NOT_HELD, "skyrimnet_SlaveAuctionTIF_Drink")
topic(OFFER_BRANCH, OFFER_TOPIC, OFFER_INFO, "Offer", "(Keep away from the drink yourself, and have your followers drink it)",
      "How generous of you. They will be well looked after.", RECEPTIONIST, STATE_NOT_HELD, "skyrimnet_SlaveAuctionTIF_Offer")
topic(BUYBACK_BRANCH, BUYBACK_TOPIC, BUYBACK_INFO, "Buyback", "(Buy back someone who was sold)",
      "Certainly. For the right price, a new owner can always be persuaded.", RECEPTIONIST, STATE_NOT_ON_STAGE,
      "skyrimnet_SlaveAuctionTIF_Buyback",
      "- MutagenObjectType: ConditionFloat\n  CompareOperator: NotEqualTo\n"
      + CONDITION.format(data="GetGlobalValueConditionData", field="Global", value=fk(BUYBACK_GLOBAL), cmp=0).split("\n", 1)[1])
topic(CHOOSE_BRANCH, CHOOSE_TOPIC, CHOOSE_INFO, "Choose", "(Name who goes up for sale next)",
      "Well? Give me a name.", GUARD, 1, "skyrimnet_SlaveAuctionTIF_Choose")

# Greetings: the speaker raises the matter, so the player's topics above answer something they said.
hello_folder = f"{PREFIX}HelloTopic - {HELLO_TOPIC:06X}_{PLUGIN}"
write("DialogTopics", PREFIX + "HelloTopic", HELLO_TOPIC,
      f"Name:\n  TargetLanguage: English\n  Value: {PREFIX}HelloTopic\nPriority: 50\nQuest: {fk(QUEST)}\n"
      f"Category: Misc\nSubtype: Hello\nSubtypeName: HELO\n", sub=[hello_folder], file_name="RecordData.yaml")


def hello(info_id, speaker, state, line):
    conditions = speaker_conditions(speaker, state)
    write("DialogTopics", None, info_id, f"""PreviousDialog: Null
FavorLevel: None
Responses:
- EmotionValue: 50
  ResponseNumber: 1
  Unknown2: 0x000000
  Unknown3: 0x000000
  Text:
    TargetLanguage: English
    Value: {quoted(line)}
  ScriptNotes: ''
  Edits: ''
Conditions:
{conditions}""", sub=[hello_folder, "Responses"])


hello(HELLO_INFO, RECEPTIONIST, STATE_NOT_HELD, "Welcome. While you wait for the bidding to begin, may I offer you a rare drink? You won't find this one anywhere else in Skyrim.")
hello(GUARD_HELLO_INFO, GUARD, 1, "Who goes up for sale next? You decide.")

print("records written to", OUT)
