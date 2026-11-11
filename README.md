# SkyrimNet Slave Auction 0.2.1

A secret slave auction in a stone basement near Riften. Get sold on its stage, or sit among the
buyers and bid on whoever is in the cage: your own followers, or anyone another mod brings in.
SkyrimNet gives everyone a voice: the staff, the twelve buyers and the captives react to what is
happening in their own words, so no two nights go alike.

Anyone can add a way in or a way out, with no master on this mod: an entry mod sends one event, and
an exit mod is one JSON file and a marker in your own plugin.

**This mod is for adult players.** It shows captivity and nudity. Children are never caught.

## If you have used 0.1.0: run the repair once

**Version 0.1.0 changed SkyrimNet's settings for other mods.** On every auction it rewrote the cooldowns of some actions that other mods add to SkyrimNet (restraints, kidnapping, fights, dressing and more: up to 39 actions, only those of mods you have installed), and SkyrimNet saved them in its `Actions.yaml`. Those mods then behave differently, even outside the auction.

- **You ran an auction with 0.1.0:** update to this version, then run the separate download **SkyrimNet Actions Repair** once, with the game closed. Its README says how. If you already ran it after updating to 0.1.1, you do not need it again.
- **You started with 0.1.1 or later, or never ran an auction with 0.1.0:** you do not need the repair. Since 0.1.1 the mod never touches SkyrimNet's settings.

## Requirements

| Mod | Notes |
|---|---|
| Skyrim Special Edition / Anniversary Edition | Built and tested on 1.6.1170. |
| [SKSE64](https://skse.silverlock.org/) | |
| [SkyrimNet](https://github.com/MinLL/SkyrimNet-GamePlugin) | Tested on beta 29.1, with an AI model set up. Without a working model the auction runs in silence. |
| [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604) | The settings menu. |
| [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048) | |
| [UIExtensions](https://www.nexusmods.com/skyrimspecialedition/mods/17561) | The lists for choosing who goes up for sale. |
| ZaZ Animation Pack | Optional. Without it, whoever is for sale stands on the stage instead of being bound to the cross. |
| [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) | Needed with ZaZ Animation Pack only, to put people on the cross. |

## Installation

Download the archive from [Releases](../../releases) and install it with your mod manager. The
installer asks for your language (English or Japanese) and which samples you want; none is selected
by default. Every plugin is ESL-flagged and needs no load-order slot. It can be added to an existing
save.

## How to play

The map shows **Underground Auction Hall**, near Riften. The receptionist is in the first room.

### Being sold yourself

1. Drink what the receptionist offers. You wake up naked in a cage, with the followers who were near
   you.
2. Talk to the cage guard to choose who goes on the stage next.
3. When everyone is sold, the ending depends on what you have installed: an exit mod takes you to its
   own place, and with none the liberators break in.

### Selling or bidding for your followers

1. Tell the receptionist you will keep away from the drink and have your followers take it. Choose
   one or all of them.
2. Go into the hall and talk to the guard to put them up for sale.
3. While someone is on the stage, the bid key (**K** by default) raises the price by 100 gold. Your
   character says the bid in their own voice, and the buyers answer. Before the hammer falls there
   is a last chance to bid.

| Sold to | What happens |
|---|---|
| You | You pay the price and they follow you again, right after the sale. |
| Another buyer | You get half the price, if you offered them yourself. They can be bought back from the receptionist at 1.5 times the price, as soon as they are sold. |

If followers are taken while you are elsewhere, they wait in the cage for three in-game days, and
then are sold without you. Starting a fight in the hall stops the auction: your followers go free and
the buyers run.

## Settings

In the MCM: how each kind of exit is chosen (at random by weight, or one fixed), each exit's switch
and weight, the bid key, the days until followers are sold without you, and the buyers' top price.
Exit definitions that could not be loaded are listed there too, with the reason.

## Samples

Small working examples, offered by the installer, and one add-on. They come with their source.

| Sample | What it does |
|---|---|
| Entry: Defeated in Battle | Beaten by humanoid enemies, you are sold instead of dying. It has an optional give-up key. Do not use it with another defeat mod. |
| Entry: Abducted in Sleep | When you sleep outdoors, in an inn or in a dungeon, your followers may be carried off (25% by default). |
| Exit: The Mine | Sold, you work a mine to get out. Followers sold to another buyer can be bought back there. |
| Entry: Sacked Captives | Needs Diary of Mine. Carry someone to the receptionist's room in a sack, take them out tied up, and hand them over to be sold. You get half of what another buyer pays. |
| Exit: Carriage to Town | After the auction, you and the followers you bought arrive at the Riften stables. |
| Exit: Set Free in Debt | A moneylender takes a seat and wins every lot you do not buy, then sets each free at once, owing three times the price. Followers come back to you; others go home. Needs the IOU Ledger. |
| Add-on: IOU Ledger | Debts any mod can give an NPC. The debtor carries a bond, and the journal tracks up to ten debtors. A mod of its own, not tied to the auction. Installed with the exit above. |

With an exit for a sold player installed, the liberators' ending does not happen. Switch that exit
off in the MCM to see it again.

## Making your own entry or exit

See the [guide for authors](assets/README_skyrimnet_SlaveAuction_Authors.md). In short:

```papyrus
SendModEvent("skyrimnet_SlaveAuction_Capture", "defeated by bandits on the road")
```

```json
{
  "string": {
    "id": "author_noble_house",
    "name": "Sold to a Noble House",
    "plugin": "MyExitMod.esp",
    "marker": "0x804",
    "buyer_name": "Agent of House Valerius"
  },
  "int": { "api_version": 1 }
}
```

## Known limits

- **Tested with Nether's Follower Framework (NFF) only.** Other setups, including vanilla followers
  with no follower framework, have not been tested.
- **Only followers near you are caught:** within about 60 meters, and at most 10 of them, unless
  another mod names someone for an auction.
- **A menu pauses the auction,** since SkyrimNet's lines and the scripts wait while one is open.
- **If the AI does not answer,** the auction goes on without the line. Each missing line takes up to
  20 seconds, so it can look stopped. Look at SkyrimNet's log for a model that has run out or timed
  out.
- **The AI can get an amount wrong.** The spoken figure now and then differs from the real bid. The
  notification shows the right one.

## License

The scripts, text and records written for this mod are MIT licensed, see [LICENSE](LICENSE). That does
not extend to anything of Bethesda's or of the mods named below.

**Skyrim.** This is an unofficial mod, not made or endorsed by Bethesda. *The Elder Scrolls* and *Skyrim*
are their trademarks. It ships no meshes, textures, sounds or animations: it refers to those of the base
game, which you need to own. To place things in the world, its plugins carry a few records of
`Skyrim.esm` as overrides (the Tamriel worldspace and its persistent cell, one cell near Riften, and the
navmesh info map). Those records remain Bethesda's.

**Other mods.** None of their files are included, here or in the archive. All are installed separately,
under their own terms:

- SKSE64, SkyUI, PapyrusUtil, UIExtensions and powerofthree's Papyrus Extender: the scripts call their
  functions. SkyUI's own scripts are also attached to the settings quests.
- SkyrimNet: the scripts call its plugin API, which is MIT licensed by Fateless.Ai, and the SkyrimNet
  add-on files follow its formats.
- ZaZ Animation Pack: when installed, its cross and pose are used by name at run time.
- Nether's Follower Framework: when installed, the scripts call its functions to let a follower go and to
  take them back, the way it does itself.
- Diary of Mine: the sample Entry: Sacked Captives calls its functions to untie and tie up again, and
  reads its factions, at run time.

To compile the scripts, you need the script sources of those mods.
