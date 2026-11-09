Scriptname skyrimnet_SlaveAuction_ExitDebt extends Quest
{Sample exit mod for SkyrimNet Slave Auction, a followers_sold exit with each_lot and a named buyer, a
moneylender who wins every lot: whoever they win is set free at once, owing them three times the price,
so that the moneylender makes a profit. The debt is the IOU Ledger's: this exit only
asks for it, by the ledger's public event, so it never names the ledger's plugin. Its definition lists
the ledger under "requires", and the auction leaves the exit out when the ledger is not loaded.}

String Property SoldEvent = "skyrimnet_SlaveAuction_ExitDebt_LotSold" AutoReadOnly   ; the "event" of its definition
String Property AddDebtEvent = "IOULedger_AddDebt" AutoReadOnly
String Property ReturnFollowerEvent = "skyrimnet_SlaveAuction_ReturnFollower" AutoReadOnly
String Property NotFollowerKey = "skyrimnet_SlaveAuction_NotFollower" AutoReadOnly
String Property StringsFile = "../skyrimnet_SlaveAuction_ExitDebt/strings.json" AutoReadOnly
Int Property DebtTimesPrice = 3 AutoReadOnly

Event OnInit()
	Setup()
EndEvent

; Also on every load, from the player's alias.
Function Setup()
	RegisterForModEvent(SoldEvent, "OnLotSold")
EndFunction

; The lot is free at the marker outside the hall, with their clothes and belongings.
Event OnLotSold(Form lot, Form buyer, Int price)
	Actor npc = lot as Actor
	If !npc || npc.IsDead()
		Return
	EndIf
	String creditor = "a buyer at the underground auction"
	Actor buyerActor = buyer as Actor
	If buyerActor
		creditor = buyerActor.GetDisplayName()
	EndIf
	Int debt = price * DebtTimesPrice
	Debug.Trace("skyrimnet_SlaveAuction_ExitDebt: " + npc.GetDisplayName() + " sold to " + creditor + " for " + price + ", set free owing " + debt)
	If debt > 0
		Int handle = ModEvent.Create(AddDebtEvent)
		If handle
			ModEvent.PushForm(handle, npc)
			ModEvent.PushInt(handle, debt)
			ModEvent.PushString(handle, creditor)
			ModEvent.Send(handle)
		EndIf
		Debug.Notification(npc.GetDisplayName() + JsonUtil.GetStringValue(StringsFile, "freedBefore", " was sold, and set free owing ") + debt + JsonUtil.GetStringValue(StringsFile, "freedAfter", " gold."))
	EndIf
	Release(npc)
EndEvent

; A follower comes back to the player; anyone else goes home.
Function Release(Actor npc)
	If StorageUtil.GetIntValue(npc, NotFollowerKey) != 1
		Int handle = ModEvent.Create(ReturnFollowerEvent)
		If handle
			ModEvent.PushForm(handle, npc)
			ModEvent.Send(handle)
		EndIf
		Return
	EndIf
	Cell here = npc.GetParentCell()
	npc.EvaluatePackage()
	npc.MoveToPackageLocation()
	If npc.GetParentCell() == here
		npc.MoveToMyEditorLocation()
	EndIf
EndFunction
