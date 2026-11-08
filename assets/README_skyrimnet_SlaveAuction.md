# SkyrimNet Slave Auction

A secret slave auction in a stone basement near Riften. Its staff, its twelve buyers and the captives all speak through SkyrimNet's AI, so no two nights go alike.

This mod is for adult players. It shows captivity and nudity.

## If you have used 0.1.0: run the repair once

**Version 0.1.0 changed SkyrimNet's settings for other mods.** On every auction it rewrote the cooldowns of 39 AI actions that other mods add to SkyrimNet (restraints, kidnapping, fights and brawls, dressing), and SkyrimNet saved them in its `Actions.yaml`. Those mods then behave differently, also outside the auction, and removing this mod does not undo it.

- **You have run at least one auction with 0.1.0:** update to 0.1.1, then run the separate download **SkyrimNet Actions Repair** once, with the game closed. Its README says how.
- **You start with 0.1.1 or later, or never ran an auction with 0.1.0:** you do not need the repair. 0.1.1 never touches SkyrimNet's settings.

## Requirements

- SKSE64
- SkyrimNet, with an AI model set up
- SkyUI
- PapyrusUtil
- UIExtensions

ZaZ Animation Pack is optional. Without it, whoever is for sale stands on the stage instead of being bound to the cross. With it, powerofthree's Papyrus Extender is needed too.

## Installing

Install the archive with Mod Organizer 2 or Vortex and choose your language. The samples are optional, and none is selected by default. Works on an existing save.

## How it works

The map shows **Underground Auction Hall**, near Riften. The receptionist is in the first room.

### Being sold yourself

1. Drink what the receptionist offers. You wake up naked in a cage, with the followers who were near you.
2. Talk to the cage guard to choose who goes on the stage next.
3. When everyone is sold, the ending depends on what you have installed: an exit mod takes you to its own place, and with none the liberators break in.

### Selling or buying back your followers

1. Tell the receptionist you will keep away from the drink and have your followers take it. Choose one or all of them.
2. Go into the hall and talk to the guard to put them up for sale.
3. While someone is on the stage, the bid key raises the price by 100 gold. Your character says the bid. Before the hammer falls there is a last chance to bid.

| Sold to | What happens |
|---|---|
| You | You pay the price and they follow you again. |
| Another buyer | You get half the price, if you offered them yourself. They can be bought back from the receptionist at 1.5 times the price. |

If followers are taken while you are elsewhere, they wait in the cage for three in-game days, and then are sold without you. Starting a fight in the hall stops the auction: your followers are set free and the buyers run.

## Settings (MCM)

- **How each kind of exit is chosen:** at random by weight, or one fixed exit.
- **Exits:** switch each one on or off, and set its weight.
- **Bid key:** K by default. It can include Shift. Another mod using the same key also reacts, unless it checks that Shift is not held.
- **Days until sold without you**, and **the buyers' top price.**
- **Unreadable:** exit definitions that could not be loaded, and why.

## Samples

| Sample | What it does |
|---|---|
| Entry: Defeated in Battle | Beaten by humanoid enemies, you are sold instead of dying. Do not use it with another defeat mod. |
| Entry: Abducted in Sleep | When you sleep outdoors, in an inn or in a dungeon, your followers may be carried off (25% by default). |
| Exit: The Mine | Sold, you work a mine to get out. Followers sold to another buyer can be bought back there, at 1.5 times the price. |
| Exit: Carriage to Town | After the auction, you and the followers you bought arrive at the Riften stables. |

With an exit for a sold player installed, the liberators' ending does not happen. To see it again, switch those exits off in the MCM.

## Notes

- **Tested with Nether's Follower Framework (NFF) only.** Other setups, including vanilla followers with no follower framework, have not been tested.
- **Vanilla followers can be dismissed while held.** Followers caught without the player are set to wait (`WaitingForPlayer` = 1), so that follower frameworks do not warp them back to the player. In the vanilla game, a waiting follower is dismissed after three in-game days away from the player. If you buy back such a follower later, you may have to ask them to follow you again.
- **Sold followers stay listed in NFF.** A follower sold to another buyer leaves the party but is not removed from NFF's own list.
- **Only followers near the player are caught,** within about 60 meters, and at most 10 of them. Anyone else stays free.
- **A menu pauses the auction.** While a menu is open, SkyrimNet's lines and the scripts wait.
- **When the AI does not answer,** the auction goes on without the line. Each missing line takes up to 20 seconds, so it can look stopped. If it does, look at SkyrimNet's log for a model that has run out or timed out.
- **The AI can get an amount wrong.** The spoken figure now and then differs from the real bid. The notification shows the right one.

## Making your own entry or exit

See `README_skyrimnet_SlaveAuction_Authors.md`.

## License

The mod's own scripts, text and records are MIT licensed, see `LICENSE_skyrimnet_SlaveAuction.txt`. This is an unofficial mod, not made or endorsed by Bethesda. It ships no meshes, textures, sounds or animations, and no files of other mods. Its plugins carry a few records of `Skyrim.esm` as overrides, which remain Bethesda's.
