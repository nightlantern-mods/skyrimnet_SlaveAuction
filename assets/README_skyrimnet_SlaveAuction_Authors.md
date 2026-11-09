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
| `no_captives` | Followers only were asked for and none are nearby, or none of the NPCs you named can be sold or they are already in the auction. |
| `full` | You asked to add to a cage that already holds 10. |

- If the auction mod is not installed, nobody answers. Do not wait forever.
- The auction stops every captive's combat and brings round whoever is bleeding out. It does not bring back the dead, and it never takes children.
- Check for yourself that the moment is a good one, for example that no other mod's scene is running.
- To keep followers alive until then, put them in optional aliases with the Essential flag. It applies only while they are in the alias.

### Naming who goes on sale

Your mod can put any NPC on sale, not only followers. List them on the form that sends the event, and send the number 2.0. The player stays free and comes to bid.

```papyrus
Form me = GetOwningQuest()
StorageUtil.FormListAdd(me, "skyrimnet_SlaveAuction_RequestedLots", someNpc)
StorageUtil.SetStringValue(me, "skyrimnet_SlaveAuction_RequestedExit", "author_second_stage")   ; optional
StorageUtil.SetIntValue(me, "skyrimnet_SlaveAuction_KeepLostLots", 1)                           ; optional
me.SendModEvent("skyrimnet_SlaveAuction_Capture", "bought to order for House Valerius", 2.0)
```

| Key | Meaning |
|---|---|
| `skyrimnet_SlaveAuction_RequestedLots` | Who is caught, wherever they are. At most 10; any more are ignored. |
| `skyrimnet_SlaveAuction_RequestedExit` | The `id` of a `lots_bought` exit, for the lots the player buys. |
| `skyrimnet_SlaveAuction_KeepLostLots` | 1 keeps the lots another buyer wins at the hall, to be bought back from the receptionist, instead of sending them to a `followers_sold` exit. |

- **Older versions do not know the number 2.0, and would catch the player.** Check first: `StorageUtil.GetIntValue(None, "skyrimnet_SlaveAuction_ApiLevel") >= 2`.
- All three are emptied by every answer, so fill them in again for each request.
- The dead, the disabled, children, the player and the auction's own NPCs are left out. With nobody left, the result is `no_captives`.
- Other followers around the player are not caught.
- Someone still waiting to be bought back can be named. They leave that list.

When an auction without the player ends, an event goes out to anyone listening. It is the only word you get when nobody was won.

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_Closed", "OnAuctionClosed")

Event OnAuctionClosed(Form requester, String result, Int bought, Int lost)
	; requester is who asked, None for the receptionist's. result is "closed", or "aborted" after a fight in the hall.
EndEvent
```

Three in-game days after the capture, if the player has not come, the lots are sold without them, and this event says so.

### Adding to the cage, one at a time

The number 3.0 is the same request with no fade and no notification, so that your mod shows what it wants. With an auction waiting, it adds to that auction's cage, and the bidding still waits until the player talks to the guard:

```papyrus
Form me = GetOwningQuest()
StorageUtil.FormListAdd(me, "skyrimnet_SlaveAuction_RequestedLots", someNpc)
me.SendModEvent("skyrimnet_SlaveAuction_Capture", "seized on the road", 3.0)
```

- With no auction going on, the first request starts one. Its text, its exit and `KeepLostLots` hold for the whole auction; those of later requests are ignored.
- It works between lots too, while nobody is on the stage. During a lot, or at an auction with the player in it, the answer is `busy`.
- The three days count again from the last one added.
- **While anyone is in the cage, every other capture is answered `busy`:** the receptionist's drink and other entry mods too, since there is one auction at a time. A defeat mod that sends the player here should have a way out for that answer.
- A first request is answered before the list of captives has been filled; the last auction's captives are already gone from it. Wait for your NPC to appear in it if you want to count them.

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
| `for` | | `player_sold` (default), `followers_sold`, `followers_bought` or `lots_bought`. |
| `each_lot` | | 1 on a `followers_sold` exit: each lot comes as soon as they are sold, with one signal each. |
| `event` | | Sent after arrival. Leave it out for an exit that only moves people. |
| `requires` | | Other plugins the exit needs, separated by commas. If one is not loaded, the exit is left out, and the MCM says which. |
| `weight` | | The odds among exits of its kind. Default 10. 0 or less leaves it out. |
| `buyer_name` | | Makes a named buyer take a seat and win everyone they can. |
| `buyer_role` | | That buyer's role, for the AI. |
| `buyer_female` | | 0 male, 1 female. |

Definitions that cannot be read are listed in the MCM, with the reason.

### The kinds

| Kind | Who moves | When there is none |
|---|---|---|
| `player_sold` | The player and all followers. The screen stays black until you answer. | The liberators' ending. |
| `followers_sold` | Only the followers another buyer won. The player sees nothing. **Give the player a way to get them back.** | They wait in the hall, to be bought back from the receptionist. |
| `followers_bought` | The player and the followers they won. The screen stays black until you answer. | They follow the player again where they stand. |
| `lots_bought` | Only the lots the player won, at an auction that named this exit, as soon as they are sold. The player sees nothing. See below. | See below. |

The `followers_sold` exit and its buyer are chosen when the first lot goes on stage, or when the lots are sold off screen, so the player can change the MCM until then. Your buyer takes the twelfth seat at that moment. The `followers_bought` exit is chosen when the first follower is won. The other two are not used in the same auction as `player_sold`.

### Staged exits: `lots_bought`

For a quest that sends the player to buy someone: "go to the auction, buy these two, and they will be brought to me." This kind is never chosen at random and has no setting of its own in the MCM, only its switch. Only a request that names it can use it.

The player does not move and the screen does not fade. Each lot the player wins goes to your marker, released and with their belongings, and one event arrives for each:

```papyrus
RegisterForModEvent("MyExitMod_LotArrived", "OnLotArrived")

Event OnLotArrived(Form lot, Int price, Bool boughtBack)
	; Hold them here: they are free, and their own AI would take them home.
EndEvent
```

No answer is needed. `boughtBack` is True when the player paid the receptionist later, at 1.5 times the price. That can happen long after your auction, even after later auctions, so be ready for it when your quest has moved on.

The player can only buy someone back if they stayed at the hall: name your exit together with `KeepLostLots`, unless you offer another way.

Who goes where, once the player has paid:

| | Won at the auction | Bought back from the receptionist |
|---|---|---|
| The named exit can be used | Your marker | Your marker |
| None named, or it has gone or been switched off, and they were a follower | Follows the player again, through `followers_bought` if there is one | Follows the player again, next to them |
| None named, or it has gone or been switched off, and they were not a follower | Free, next to the player | Free, next to the player |

Someone freed next to the player is moved back to where they belong when the player leaves the hall, since nobody can walk out of it.

If your stage has someone who must stay, such as the person who gave the order, make them an NPC of your own: the `buyer` you are given goes back to its seat at the next capture.

### When each lot goes

At an auction without the player, a lot normally goes on as soon as they are sold, with their clothes and belongings back. Only the two kinds marked "at the close" wait, in a room out of sight.

| Sold | Goes to | When |
|---|---|---|
| To another buyer, with no `followers_sold` exit | The receptionist's list, to be bought back | **At once**, between lots too |
| To another buyer, with a `followers_sold` exit that has `each_lot` | Your marker | **At once** |
| To another buyer, with a `followers_sold` exit without `each_lot` | Your marker | At the close |
| To the player, with a `lots_bought` exit named | Your marker | **At once** |
| To the player, a follower, with no exit | Follows the player again | **At once** |
| To the player, not a follower, with no exit | Free, next to the player | **At once** |
| To the player, a follower, with a `followers_bought` exit | Your marker, with the player | At the close |

The player would have to leave the hall in mid-auction for `followers_bought`. A `followers_sold` exit without `each_lot` was told it gets everyone at once, in one signal, so it stays that way.

The close comes when everyone is sold, or after three in-game days when the rest are sold off screen. Adding someone to the cage between lots puts it off, and those waiting wait longer.

With `each_lot`, the signal comes once per lot, and has the lot in it:

```papyrus
RegisterForModEvent("MyExitMod_LotSold", "OnLotSold")

Event OnLotSold(Form lot, Form buyer, Int price)
	; Hold them here: they are free, and their own AI would take them home.
EndEvent
```

- No answer is needed, and the list of those sold is not ready yet: use `lot`.
- The auction is still going on. Do not move `buyer` until `skyrimnet_SlaveAuction_Closed` arrives: they may be bidding.
- A fight in the hall stops the auction. Those already sent on stay sold.

### What has been done on arrival

Everyone has been moved to your marker and released: bindings, blocked combat and blocked fast travel are all gone, and belongings are back. The player has their items in the inventory, unworn. If you want them kept stripped, take the things again, before you answer.

Followers your exit receives from an auction without the player (those sold to another buyer, and on a `lots_bought` exit those the player won or bought back) have been dismissed, the way vanilla or Nether's Follower Framework dismisses: they are out of the follower slot, and the player can hire them again in dialogue. Followers who come with the player when the player is sold are still the player's followers, waiting (`WaitingForPlayer` at 1).

To give one back to the player, whichever kind, send this event. The auction hires them again through the follower quest, which works with vanilla and with NFF:

```papyrus
Int handle = ModEvent.Create("skyrimnet_SlaveAuction_ReturnFollower")
ModEvent.PushForm(handle, follower)
ModEvent.Send(handle)
```

Do not set the follower faction yourself: on someone dismissed it makes a follower who never follows. With vanilla, which keeps one follower, someone the player hired meanwhile keeps the place, and the one you return stays dismissed until the player hires them.

Check `StorageUtil.GetIntValue(follower, "skyrimnet_SlaveAuction_NotFollower")` first: 1 means a mod named them and they never followed the player, so let them go instead. If your exit is a cell of your own whose navmesh does not reach the world, they cannot walk home from it: call `MoveToPackageLocation()` on them, as the mine does.

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

Each is kept until the next capture, and emptied as soon as that capture is accepted.

```papyrus
Int count = StorageUtil.FormListCount(None, "skyrimnet_SlaveAuction_Captives")
Actor captive = StorageUtil.FormListGet(None, "skyrimnet_SlaveAuction_Captives", 0) as Actor
```

| List | Holds |
|---|---|
| `skyrimnet_SlaveAuction_Captives` | Everyone caught, the player included. |
| `skyrimnet_SlaveAuction_SoldCaptives` | Those another buyer won. |
| `skyrimnet_SlaveAuction_BoughtCaptives` | Those the player won. |

The last two are filled at the close.

Each sale also sends an event, to anyone listening:

```papyrus
RegisterForModEvent("skyrimnet_SlaveAuction_Sold", "OnSold")

Event OnSold(Form lot, Form buyer, Int price)
EndEvent
```

## The IOU Ledger add-on

An add-on of its own, chosen in the installer, that any mod can use to put an NPC in debt. Nothing has to name its plugin: you send events.

```papyrus
; Add to someone's debt. The creditor is a name, kept for the AI and for other mods.
Int handle = ModEvent.Create("IOULedger_AddDebt")
ModEvent.PushForm(handle, npc)
ModEvent.PushInt(handle, 10000)
ModEvent.PushString(handle, "Mine Overseer")
ModEvent.Send(handle)

; Pay some of it off. 0 or less clears it all.
handle = ModEvent.Create("IOULedger_PayDebt")
ModEvent.PushForm(handle, npc)
ModEvent.PushInt(handle, 2500)
ModEvent.Send(handle)
```

| To know | Read |
|---|---|
| Is the ledger running? | `StorageUtil.GetIntValue(None, "IOULedger_Running") == 1` |
| Does this NPC owe? | They carry the bond: an item with the keyword `IOULedger_Bond`, named `[IOU] Debt Bond` |
| How much? | `StorageUtil.GetIntValue(npc, "IOULedger_Debt")` |
| To whom, last? | `StorageUtil.GetStringValue(npc, "IOULedger_Creditor")` |
| Everyone in debt | `StorageUtil.FormListToArray(None, "IOULedger_Debtors")` |

- **The bond is the debt.** Take it from the NPC and the ledger clears the debt within an in-game hour. A dead debtor's debt is cleared too.
- Each change sends `IOULedger_DebtChanged` with `(Form debtor, Int total)`; the total is 0 once the debt is gone.
- The player cannot be put in debt.
- One journal objective under Miscellaneous puts a map marker on each of up to ten debtors, with no names, as follower frameworks do. Anyone past ten is still in debt, and is marked once a place is free. - The AI is told of each new debt, and what the bond is.

To use an exit only when another plugin is there, list that plugin under `requires` in the exit's definition. The exit sample Set Free in Debt does this with the ledger.

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

The event names, fields and arguments here will not change for `api_version` 1. If they must change, the number goes up, and the MCM shows older definitions as unsupported. An older version of the auction lists a `lots_bought` exit among the definitions it cannot read.
