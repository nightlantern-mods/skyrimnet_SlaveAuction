# Making an entry or exit mod for SkyrimNet Slave Auction

Your mod needs no master on this one, and this one does not need to know about yours. An entry mod sends one event. An exit mod is one JSON file, plus a marker in your own plugin.

The four samples in the installer are working examples, and they ship with their source.

| You want | Read |
|---|---|
| An entry with the player | `skyrimnet_SlaveAuction_EntryDefeat.psc` |
| An entry with followers only | `skyrimnet_SlaveAuction_EntryAbduction.psc` |
| The smallest exit: no script at all | `skyrimnet_SlaveAuction_carriage.json` |
| An exit with its own place and events | `skyrimnet_SlaveAuction_ExitMine.psc` |

## Entry mods

Send one event from any form:

```papyrus
SendModEvent("skyrimnet_SlaveAuction_Capture", "defeated by bandits on the road")
SendModEvent("skyrimnet_SlaveAuction_Capture", "taken in the night", 1.0)   ; followers only
```

The text says how they came, and is handed to the AI for the lines. Keep it short: past 500 characters it is cut. The number 1.0 leaves the player free and takes only the followers.

The answer comes back in an event:

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_CaptureResult", "OnCaptureResult")

Event OnCaptureResult(String result, String reason, Form requester)
	; requester is who sent the event: check that it was you
EndEvent
```

| Result | Meaning |
|---|---|
| `accepted` | The capture has started. |
| `busy` | An auction is under way. Nothing has happened. |
| `no_captives` | Followers only were asked for, and none are nearby. |

- If the auction mod is not installed, nobody answers. Do not wait forever.
- The auction stops every captive's combat and brings round whoever is bleeding out. It does not bring back the dead, and it never takes children.
- Check for yourself that the moment is a good one, for example that no other mod's scene is running.
- To keep followers alive until then, put them in optional aliases with the Essential flag. It applies only while they are in the alias.

## Exit mods

Write one JSON file:

`SKSE/Plugins/skyrimnet_SlaveAuction/exits/<author>_<name>.json`

The auction reads the folder, so there is nothing to register. Start the file name with your name: another mod's file of the same name would replace yours. A translation can replace your file under the same name to change its text.

```json
{
  "string": {
    "id": "author_noble_house",
    "name": "Sold to a Noble House",
    "plugin": "MyExitMod.esp",
    "marker": "0x804",
    "event": "MyExitMod_Start",
    "for": "player_sold",
    "buyer_name": "Agent of House Valerius",
    "buyer_role": "A cold, polite agent buying servants for a noble house."
  },
  "int": {
    "api_version": 1,
    "weight": 10,
    "buyer_female": 0
  }
}
```

| Field | Required | Meaning |
|---|---|---|
| `api_version` | yes | 1 |
| `id` | yes | Unique among all exits. |
| `name` | yes | Shown in the MCM. |
| `plugin` | yes | Your plugin. If it is not loaded, the exit is left out. |
| `marker` | yes | FormID, as hex text, of a **persistent** marker in your plugin. A cell cannot be named directly. |
| `for` | | `player_sold` (default), `followers_sold` or `followers_bought`. |
| `event` | | Sent after arrival. Leave it out for an exit that only moves people. |
| `weight` | | The odds among exits of its kind. Default 10. 0 or less leaves it out. |
| `buyer_name` | | Makes a named buyer take a seat and win everyone they can. |
| `buyer_role` | | That buyer's role, for the AI. |
| `buyer_female` | | 0 male, 1 female. |

Definitions that cannot be read are listed in the MCM, with the reason.

### The three kinds

| Kind | Who moves | When there is none |
|---|---|---|
| `player_sold` | The player and all followers. The screen stays black until you answer. | The liberators' ending. |
| `followers_sold` | Only the followers another buyer won. The player sees nothing. **Give the player a way to get them back.** | They wait in the hall, to be bought back from the receptionist. |
| `followers_bought` | The player and the followers they won. The screen stays black until you answer. | They follow the player again where they stand. |

The `followers_sold` exit and its buyer are chosen at the capture, the `followers_bought` exit at the close. The other two are not used in the same auction as `player_sold`.

### What has been done on arrival

Everyone has been moved to your marker and released: bindings, blocked combat, blocked fast travel and blocked AI actions are all gone, and belongings are back. The player has their items in the inventory, unworn. If you want them kept stripped, take the things again, before you answer.

Followers sold to another buyer have left the party, with `WaitingForPlayer` at 1 so that follower frameworks do not warp them back. To return one to the player:

```papyrus
follower.SetActorValue("WaitingForPlayer", 0.0)
follower.AddToFaction(Game.GetForm(0x05C84E) as Faction)   ; CurrentFollowerFaction
follower.SetPlayerTeammate(True)
```

### The signal

```papyrus
RegisterForModEvent("MyExitMod_Start", "OnExitStart")

Event OnExitStart(Form buyer, Int price, String reason)
	; Take things away again, bring the buyer along, whatever must be ready.
	SendModEvent("skyrimnet_SlaveAuction_ExitAck")   ; the screen may lift now
EndEvent
```

- `player_sold` and `followers_bought` wait for the answer, for 15 seconds at most. Then the screen lifts anyway and a notification says the exit did not answer. No other exit is tried.
- `followers_sold` needs no answer.
- `buyer` is an NPC of the auction. You can move it to your place, and it goes back to its seat at the next capture. Be ready for it to be gone by then.

### Lists and events you can read

Each is kept until the next capture.

```papyrus
Int count = StorageUtil.FormListCount(None, "skyrimnet_SlaveAuction_Captives")
Actor captive = StorageUtil.FormListGet(None, "skyrimnet_SlaveAuction_Captives", 0) as Actor
```

| List | Holds |
|---|---|
| `skyrimnet_SlaveAuction_Captives` | Everyone caught, the player included. |
| `skyrimnet_SlaveAuction_SoldCaptives` | Followers another buyer won. |
| `skyrimnet_SlaveAuction_BoughtCaptives` | Followers the player won. |

Each sale also sends an event, to anyone listening:

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_Sold", "OnSold")

Event OnSold(Form lot, Form buyer, Int price)
EndEvent
```

## Pitfalls

- **Cell editor IDs must have no underscores.** The location goes into the save's file name, and the load menu then does not list the save.
- **Long strings in script variables can make a save fail to load.** Do not read big files into a string.
- **A start-enabled quest with dialogue needs a `SEQ/<plugin>.seq`.** Without it the topics never appear, while the quest's scripts seem fine.
- **A dialogue line needs some text.** An empty one may not show up. `...` is enough.
- **Keep the AI from firing the player's choices.** List the quest and the fragment scripts under `blacklist` in a `dialogue_actions` file of your SkyrimNet bundle. The mine sample has one.
- **Load doors and references in aliases keep their position in old saves.** Moving one in the plugin later does nothing for those saves.
- **Do not put another mod's values in your plugin.** To override a vanilla record, copy it from `Skyrim.esm` itself and not from your load order.
- **After loading several saves in one session, your MCM script can reach SkyUI unstarted,** and a Papyrus error there can crash the game while it is logged. See `MakeSureStarted` in the samples' MCM scripts.

## Compatibility

The event names, fields and arguments here will not change for `api_version` 1. If they must change, the number goes up, and the MCM shows older definitions as unsupported.
