Scriptname skyrimnet_SlaveAuction_EntrySack extends Quest
{Sample entry mod for SkyrimNet Slave Auction, for people who are not followers. Put someone in a sack
with Diary of Mine, carry them to the receptionist's room, take them out tied up, and hand them over:
the receptionist puts them up for sale, and the player gets half of what another buyer pays. Only those
tied up in the receptionist's room count. It uses the auction's public events and Diary of Mine's own
functions, and needs Diary of Mine.}

String Property StringsFile = "../skyrimnet_SlaveAuction_EntrySack/strings.json" AutoReadOnly
String Property AuctionPlugin = "skyrimnet_SlaveAuction.esp" AutoReadOnly
String Property OwnPlugin = "skyrimnet_SlaveAuction_EntrySack.esp" AutoReadOnly
String Property DomPlugin = "DiaryOfMine.esm" AutoReadOnly
Int Property ReceptionistID = 0x910 AutoReadOnly
Int Property HallDoorID = 0x906 AutoReadOnly           ; the receptionist's room is the side of this door away from the hall
Int Property AuctionStateID = 0x818 AutoReadOnly       ; the auction's state: 2 while someone is on the stage
Int Property OnStage = 2 AutoReadOnly
Int Property ReadyID = 0x801 AutoReadOnly              ; 1 while someone can be handed over: the topic shows
Int Property DomCoreID = 0x000D61 AutoReadOnly         ; DOM01, which runs DOM_Core
Int Property DomInteractID = 0x0ED87C AutoReadOnly     ; DOM02Topic, which runs DOM_Interactor
Int Property TiedFactionID = 0x58AB49 AutoReadOnly     ; DOMActionTied: tied up by Diary of Mine
Int Property DomActorFactionID = 0x58FC50 AutoReadOnly ; DOMActorFaction: the slaves and slavers Diary of Mine looks after
Int Property GoldID = 0x00000F AutoReadOnly
Int Property MaxLots = 10 AutoReadOnly
Int Property SellerSharePercent = 50 AutoReadOnly      ; as for followers left with the receptionist
Float Property WatchSeconds = 1.0 AutoReadOnly
Float Property AnswerWaitSeconds = 5.0 AutoReadOnly
String Property RequestedLotsKey = "skyrimnet_SlaveAuction_RequestedLots" AutoReadOnly
String Property CaptivesKey = "skyrimnet_SlaveAuction_Captives" AutoReadOnly
String Property HandedKey = "skyrimnet_SlaveAuction_EntrySack_Handed" AutoReadOnly   ; on each person handed over, until sold

Actor[] found        ; filled by CollectTied
Actor[] handing      ; the people of the request waiting for its answer
Int handingCount
Bool waiting

Event OnInit()
	Setup()
EndEvent

; Also on every load, from the player's alias.
Function Setup()
	found = new Actor[10]
	handing = new Actor[10]
	RegisterForModEvent("skyrimnet_SlaveAuction_CaptureResult", "OnCaptureResult")
	RegisterForModEvent("skyrimnet_SlaveAuction_Sold", "OnSold")
	Actor desk = Receptionist()
	If desk
		(GetAlias(1) as ReferenceAlias).ForceRefTo(desk)
	EndIf
	Watch()
EndFunction

; While the player is in the receptionist's room, look every second for someone to hand over, so that the
; topic shows only when there is. Started by the receptionist's alias when the hall loads.
Function Watch()
	RegisterForSingleUpdate(0.1)
EndFunction

Event OnUpdate()
	Actor desk = Receptionist()
	If !desk || !desk.Is3DLoaded() || Game.GetPlayer().GetParentCell() != desk.GetParentCell()
		Ready().SetValue(0)
		Return
	EndIf
	Ready().SetValue((CanHandOver() && CollectTied() > 0) as Int)
	RegisterForSingleUpdate(WatchSeconds)
EndEvent

Bool Function CanHandOver()
	If waiting || Game.GetModByName(DomPlugin) == 255
		Return False
	EndIf
	; Older versions of the auction do not know the number 3.0.
	If StorageUtil.GetIntValue(None, "skyrimnet_SlaveAuction_ApiLevel") < 2
		Return False
	EndIf
	GlobalVariable auctionState = Game.GetFormFromFile(AuctionStateID, AuctionPlugin) as GlobalVariable
	Return !auctionState || auctionState.GetValueInt() != OnStage
EndFunction

; Everyone tied up by Diary of Mine in the receptionist's room, at most ten. Returns how many.
Int Function CollectTied()
	Actor player = Game.GetPlayer()
	Actor desk = Receptionist()
	ObjectReference hallDoor = Game.GetFormFromFile(HallDoorID, AuctionPlugin) as ObjectReference
	Faction tied = Game.GetFormFromFile(TiedFactionID, DomPlugin) as Faction
	Faction domActors = Game.GetFormFromFile(DomActorFactionID, DomPlugin) as Faction
	DOM_Core core = Game.GetFormFromFile(DomCoreID, DomPlugin) as DOM_Core
	If !desk || !hallDoor || !tied
		Return 0
	EndIf
	Float doorX = hallDoor.GetPositionX()
	Actor[] nearby = MiscUtil.ScanCellNPCs(desk, 0.0)
	Int count = 0
	Int i = 0
	While i < nearby.Length && count < MaxLots
		Actor npc = nearby[i]
		If IsHandable(npc, player, desk, tied, domActors, core, doorX)
			found[count] = npc
			count += 1
		EndIf
		i += 1
	EndWhile
	Return count
EndFunction

Bool Function IsHandable(Actor npc, Actor player, Actor desk, Faction tied, Faction domActors, DOM_Core core, Float doorX)
	If !npc || npc == player || npc == desk || npc.IsDead() || npc.IsDisabled() || npc.IsChild() || npc.IsPlayerTeammate()
		Return False
	EndIf
	If !npc.IsInFaction(tied) || (domActors && npc.IsInFaction(domActors))
		Return False
	EndIf
	; The same cell holds the hall: only this side of its door is the receptionist's room.
	If npc.GetPositionX() >= doorX
		Return False
	EndIf
	; Slaves of Diary of Mine and the mods it works with stay with them.
	Return !core || !core.isASlave(npc)
EndFunction

; The receptionist's topic.
Function HandOver()
	If !CanHandOver()
		Return
	EndIf
	Int count = CollectTied()
	If count == 0
		Return
	EndIf
	Actor player = Game.GetPlayer()
	DOM_Interactor interact = Game.GetFormFromFile(DomInteractID, DomPlugin) as DOM_Interactor
	StorageUtil.FormListClear(self, RequestedLotsKey)
	handingCount = 0
	Int i = 0
	While i < count
		Actor npc = found[i]
		; Diary of Mine's ropes come off first, with no call for help: the auction binds them itself.
		If interact
			interact.UnTieActor(npc, player, False)
		EndIf
		StorageUtil.FormListAdd(self, RequestedLotsKey, npc)
		StorageUtil.SetIntValue(npc, HandedKey, 1)
		handing[i] = npc
		handingCount += 1
		i += 1
	EndWhile
	waiting = True
	Ready().SetValue(0)
	; The number 3.0 adds them to the auction waiting for its next lot, or starts one, with no fade.
	SendModEvent("skyrimnet_SlaveAuction_Capture", "carried off in a sack and handed over to the receptionist, tied up", 3.0)
EndFunction

Event OnCaptureResult(String result, String reason, Form requester)
	If requester != self || !waiting
		Return
	EndIf
	Actor player = Game.GetPlayer()
	If result == "accepted"
		; A first request is answered before the cage's list is filled.
		Float startedAt = Utility.GetCurrentRealTime()
		While !AnyInCage() && Utility.GetCurrentRealTime() - startedAt < AnswerWaitSeconds
			Utility.Wait(0.25)
		EndWhile
	EndIf
	; Whoever the auction did not take is tied up again, where they stand.
	DOM_Interactor interact = Game.GetFormFromFile(DomInteractID, DomPlugin) as DOM_Interactor
	Int taken = 0
	String names = ""
	Int i = 0
	While i < handingCount
		Actor npc = handing[i]
		If npc && StorageUtil.FormListFind(None, CaptivesKey, npc) >= 0
			taken += 1
			If names != ""
				names += ", "
			EndIf
			names += npc.GetDisplayName()
		ElseIf npc
			StorageUtil.UnsetIntValue(npc, HandedKey)
			If interact && !npc.IsDead()
				interact.TieupActor(npc, player, "", True, False)
			EndIf
		EndIf
		handing[i] = None
		i += 1
	EndWhile
	Debug.Trace("skyrimnet_SlaveAuction_EntrySack: answer " + result + ", taken " + taken + " of " + handingCount + ": " + names)
	handingCount = 0
	waiting = False
	If taken > 0
		Debug.Notification(Text("handed", "The receptionist has them taken to the cage."))
		Actor desk = Receptionist()
		; The AI says what the receptionist makes of it.
		SkyrimNetApi.DirectNarration(player.GetDisplayName() + " has just handed " + names + " over to " + desk.GetDisplayName() + ", tied up, to be sold at the auction. " + desk.GetDisplayName() + " has them taken to the cage.", desk, player)
	ElseIf result == "full"
		Debug.Notification(Text("full", "The cage is full."))
	Else
		Debug.Notification(Text("busy", "The receptionist cannot take anyone now."))
	EndIf
	Watch()
EndEvent

Bool Function AnyInCage()
	Int i = 0
	While i < handingCount
		If handing[i] && StorageUtil.FormListFind(None, CaptivesKey, handing[i]) >= 0
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

; The player's half of what another buyer pays for someone they handed over.
Event OnSold(Form lot, Form buyer, Int price)
	If StorageUtil.GetIntValue(lot, HandedKey) != 1
		Return
	EndIf
	StorageUtil.UnsetIntValue(lot, HandedKey)
	Actor player = Game.GetPlayer()
	If buyer == player || price <= 0
		Return
	EndIf
	Int share = (price * SellerSharePercent) / 100
	Debug.Trace("skyrimnet_SlaveAuction_EntrySack: " + (lot as Actor).GetDisplayName() + " sold for " + price + ", the player's share " + share)
	player.AddItem(Game.GetFormFromFile(GoldID, "Skyrim.esm"), share, True)
	Debug.Notification(Text("share", "Your share of a sale, in gold:") + " " + share)
EndEvent

Actor Function Receptionist()
	Return Game.GetFormFromFile(ReceptionistID, AuctionPlugin) as Actor
EndFunction

GlobalVariable Function Ready()
	Return Game.GetFormFromFile(ReadyID, OwnPlugin) as GlobalVariable
EndFunction

String Function Text(String entry, String fallback)
	Return JsonUtil.GetStringValue(StringsFile, entry, fallback)
EndFunction
