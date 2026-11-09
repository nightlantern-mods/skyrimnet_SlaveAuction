Scriptname skyrimnet_SlaveAuction_ExitMine extends Quest
{Sample exit mod for SkyrimNet Slave Auction, with two exits into one cell. A sold player works the rock
face to get out; followers sold without the player wait here to be bought back. It uses only the public
events and lists. Lines are written by the AI: the scripts only tell it what is going on.}

String Property PluginName = "skyrimnet_SlaveAuction_ExitMine.esp" AutoReadOnly
String Property StringsFile = "../skyrimnet_SlaveAuction_ExitMine/strings.json" AutoReadOnly
String Property HeldList = "skyrimnet_SlaveAuction_ExitMine_Held" AutoReadOnly
String Property PriceKey = "skyrimnet_SlaveAuction_ExitMine_Price" AutoReadOnly
String Property OutfitKey = "skyrimnet_SlaveAuction_ExitMine_Outfit" AutoReadOnly
String Property ChestKey = "skyrimnet_SlaveAuction_ExitMine_Chest" AutoReadOnly
Int Property RocksToDig = 10 AutoReadOnly
Int Property BuybackPercent = 150 AutoReadOnly
Int Property MostFollowers = 10 AutoReadOnly
Int Property HeldCountID = 0x802 AutoReadOnly
Int Property BareOutfitID = 0x804 AutoReadOnly
Int Property OverseerMarkerID = 0x811 AutoReadOnly
Int Property InnerDoorID = 0x829 AutoReadOnly
Int Property PlayerChestID = 0x814 AutoReadOnly
Int Property FollowerChestID = 0x815 AutoReadOnly        ; ten in a row, under the floor
Int Property MoreChestsID = 0x850 AutoReadOnly           ; and ten more: both exits may hold people at once
Int Property OverseerAlias = 1 AutoReadOnly
Int Property GoldID = 0x00000F AutoReadOnly
Int Property DoNothingID = 0x0654E2 AutoReadOnly
Int Property CurrentFollowerFactionID = 0x05C84E AutoReadOnly

Bool playerHeld
Int dug
Actor[] working
Bool[] chestInUse

Event OnInit()
	RegisterForModEvent("skyrimnet_SlaveAuction_ExitMine_PlayerSold", "OnPlayerSold")
	RegisterForModEvent("skyrimnet_SlaveAuction_ExitMine_FollowersSold", "OnFollowersSold")
	RegisterForModEvent("skyrimnet_SlaveAuction_Sold", "OnAnyoneSold")
	working = new Actor[10]
EndEvent

ObjectReference Function Ref(Int id)
	Return Game.GetFormFromFile(id, PluginName) as ObjectReference
EndFunction

String Function Phrase(String phraseKey, String fallback)
	Return JsonUtil.GetStringValue(StringsFile, phraseKey, fallback)
EndFunction

; ---------------------------------------------------------------------------------------------
; The buyer comes along: the auction hands over its NPC, and takes it back at the next capture
; ---------------------------------------------------------------------------------------------
Actor Function Overseer()
	Return (GetAlias(OverseerAlias) as ReferenceAlias).GetActorReference()
EndFunction

Function BringOverseer(Form buyer)
	Actor overseer = buyer as Actor
	If overseer
		(GetAlias(OverseerAlias) as ReferenceAlias).ForceRefTo(overseer)
		overseer.MoveTo(Ref(OverseerMarkerID))
		overseer.EvaluatePackage()
	EndIf
EndFunction

; ---------------------------------------------------------------------------------------------
; Exit 1, player_sold: the auction has moved everyone here, given everything back and is holding the fade
; ---------------------------------------------------------------------------------------------
Event OnPlayerSold(Form buyer, Int price, String reason)
	Actor player = Game.GetPlayer()
	playerHeld = True
	dug = 0
	BringOverseer(buyer)
	; Stripped again, while the player cannot see it.
	ObjectReference chest = Ref(PlayerChestID)
	player.UnequipAll()
	player.RemoveAllItems(chest, False, False)
	chest.Lock(True)
	chest.SetLockLevel(255)
	ObjectReference gate = Ref(InnerDoorID)
	gate.Lock(True)
	gate.SetLockLevel(255)
	Int count = StorageUtil.FormListCount(None, "skyrimnet_SlaveAuction_Captives")
	Int i = 0
	Int filled = 0
	While i < count && filled < MostFollowers
		Actor follower = StorageUtil.FormListGet(None, "skyrimnet_SlaveAuction_Captives", i) as Actor
		If follower && follower != player && !follower.IsDead()
			working[filled] = follower
			Hold(follower)
			filled += 1
		EndIf
		i += 1
	EndWhile
	While filled < MostFollowers
		working[filled] = None
		filled += 1
	EndWhile
	; Only now may the fade lift.
	SendModEvent("skyrimnet_SlaveAuction_ExitAck")
	Utility.Wait(2.0)
	Actor overseer = Overseer()
	If overseer
		SkyrimNetApi.DirectNarration(overseer.GetDisplayName() + " has just bought " + player.GetDisplayName() + " for this mine and tells them how it works: they strip the ore from the rock face until the quota is met, and then, and only then, they may go.", overseer, player)
	EndIf
EndEvent

; Called by the rock face.
Function Dig()
	If !playerHeld
		Return
	EndIf
	dug += 1
	If dug < RocksToDig
		Debug.Notification(dug + " / " + RocksToDig)
		Return
	EndIf
	Actor overseer = Overseer()
	If overseer && !overseer.IsDead()
		Actor player = Game.GetPlayer()
		SkyrimNetApi.DirectNarration(player.GetDisplayName() + " has met the quota. " + overseer.GetDisplayName() + " grudgingly sets them free and tells them to take their things and get out.", overseer, player)
	EndIf
	FreeThePlayer()
EndFunction

Function FreeThePlayer()
	If !playerHeld
		Return
	EndIf
	playerHeld = False
	Ref(PlayerChestID).Lock(False)
	Ref(InnerDoorID).Lock(False)
	Debug.Notification(Phrase("free", "You are free to go. Your belongings are in the chest."))
	Int i = 0
	While i < MostFollowers
		Actor follower = working[i]
		If follower
			Release(follower)
			working[i] = None
		EndIf
		i += 1
	EndWhile
EndFunction

; ---------------------------------------------------------------------------------------------
; Exit 2, followers_sold: the player sees nothing and stays where they are, so no answer is needed
; ---------------------------------------------------------------------------------------------
Event OnAnyoneSold(Form lot, Form buyer, Int price)
	StorageUtil.SetIntValue(lot, PriceKey, price)
EndEvent

Event OnFollowersSold(Form buyer, Int price, String reason)
	BringOverseer(buyer)
	Int count = StorageUtil.FormListCount(None, "skyrimnet_SlaveAuction_SoldCaptives")
	Int i = 0
	While i < count
		Actor follower = StorageUtil.FormListGet(None, "skyrimnet_SlaveAuction_SoldCaptives", i) as Actor
		If follower
			Hold(follower)
			StorageUtil.FormListAdd(None, HeldList, follower)
		EndIf
		i += 1
	EndWhile
	UpdateHeldCount()
	Debug.Notification(Phrase("resold", "Your followers have been sold on to the Abandoned Mine."))
EndEvent

Function UpdateHeldCount()
	(Game.GetFormFromFile(HeldCountID, PluginName) as GlobalVariable).SetValue(StorageUtil.FormListCount(None, HeldList))
EndFunction

; Called by the overseer's dialogue.
Function BuyBack()
	Int count = StorageUtil.FormListCount(None, HeldList)
	If count == 0 || count > 126
		Return
	EndIf
	UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
	If !menu
		Return
	EndIf
	Int i = 0
	While i < count
		Actor follower = StorageUtil.FormListGet(None, HeldList, i) as Actor
		menu.AddEntryItem(follower.GetDisplayName() + " (" + BuybackPrice(follower) + ")")
		i += 1
	EndWhile
	menu.AddEntryItem(Phrase("notYet", "Not yet"))
	menu.OpenMenu()
	Int pick = menu.GetResultInt()
	If pick < 0 || pick >= count
		Return
	EndIf
	Actor chosen = StorageUtil.FormListGet(None, HeldList, pick) as Actor
	Actor player = Game.GetPlayer()
	Form gold = Game.GetForm(GoldID)
	Int price = BuybackPrice(chosen)
	If player.GetItemCount(gold) < price
		Debug.Notification(Phrase("tooMuch", "You do not have that much gold."))
		Return
	EndIf
	player.RemoveItem(gold, price, True)
	StorageUtil.FormListRemoveAt(None, HeldList, pick)
	UpdateHeldCount()
	Release(chosen)
EndFunction

Int Function BuybackPrice(Actor follower)
	Return (StorageUtil.GetIntValue(follower, PriceKey) * BuybackPercent) / 100
EndFunction

Function ReleaseAllHeld()
	Int count = StorageUtil.FormListCount(None, HeldList)
	Int i = 0
	While i < count
		Release(StorageUtil.FormListGet(None, HeldList, i) as Actor)
		i += 1
	EndWhile
	StorageUtil.FormListClear(None, HeldList)
	UpdateHeldCount()
EndFunction

; Called by the door when the player comes in. The auction took its NPC back for a later capture,
; or something killed it unseen: with nobody to pay, nobody is kept.
Function PlayerArrived()
	If playerHeld
		Return
	EndIf
	Actor overseer = Overseer()
	If !overseer || overseer.IsDead() || overseer.IsDisabled() || overseer.GetParentCell() != Ref(OverseerMarkerID).GetParentCell()
		ReleaseAllHeld()
	EndIf
EndFunction

; Called when the overseer dies: both exits' way out.
Function OverseerDied()
	FreeThePlayer()
	ReleaseAllHeld()
EndFunction

; ---------------------------------------------------------------------------------------------
; Followers: the auction gave them everything back on arrival, so it is taken again here
; ---------------------------------------------------------------------------------------------
ObjectReference Function ChestAt(Int slot)
	If slot < MostFollowers
		Return Ref(FollowerChestID + slot)
	EndIf
	Return Ref(MoreChestsID + slot - MostFollowers)
EndFunction

Function Strip(Actor follower)
	If chestInUse.Length == 0
		chestInUse = new Bool[20]
	EndIf
	Int slot = chestInUse.Find(False)
	If slot < 0
		Return
	EndIf
	chestInUse[slot] = True
	StorageUtil.SetIntValue(follower, ChestKey, slot + 1)
	StorageUtil.SetFormValue(follower, OutfitKey, follower.GetActorBase().GetOutfit())
	follower.SetOutfit(Game.GetFormFromFile(BareOutfitID, PluginName) as Outfit)
	follower.UnequipAll()
	; RemoveAllItems right after an outfit change once hung the game: see the auction's TakeBelongings.
	Utility.Wait(0.25)
	MoveItems(follower, ChestAt(slot))
EndFunction

Function MoveItems(ObjectReference from, ObjectReference to)
	Int i = from.GetNumItems()
	While i > 0
		i -= 1
		Form item = from.GetNthForm(i)
		If item && item.IsPlayable()
			Int count = from.GetItemCount(item)
			If count > 0
				from.RemoveItem(item, count, True, to)
			EndIf
		EndIf
	EndWhile
EndFunction

Function GiveBack(Actor follower)
	Int slot = StorageUtil.GetIntValue(follower, ChestKey) - 1
	If slot < 0
		Return
	EndIf
	MoveItems(ChestAt(slot), follower)
	Outfit worn = StorageUtil.GetFormValue(follower, OutfitKey) as Outfit
	If worn
		follower.SetOutfit(worn)
	EndIf
	StorageUtil.UnsetIntValue(follower, ChestKey)
	StorageUtil.UnsetFormValue(follower, OutfitKey)
	chestInUse[slot] = False
EndFunction

Function Hold(Actor follower)
	Strip(follower)
	ActorUtil.AddPackageOverride(follower, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package, 100)
	follower.EvaluatePackage()
EndFunction

; A follower sold here was let go by the auction; one sold with the player is still in their slot.
; Either way the auction's ReturnFollower gives them back.
Function Release(Actor follower)
	If follower
		GiveBack(follower)
		ActorUtil.RemovePackageOverride(follower, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package)
		; Someone an entry mod named, who never followed the player, goes back to their own life. The
		; mine's navmesh does not reach the outside, so they cannot walk there.
		If StorageUtil.GetIntValue(follower, "skyrimnet_SlaveAuction_NotFollower") == 1
			Cell mine = Ref(OverseerMarkerID).GetParentCell()
			follower.EvaluatePackage()
			follower.MoveToPackageLocation()
			If !mine || follower.GetParentCell() == mine
				follower.MoveToMyEditorLocation()
			EndIf
		Else
			; The auction hires them again the way their follower framework does, vanilla's or NFF's.
			Int handle = ModEvent.Create("skyrimnet_SlaveAuction_ReturnFollower")
			If handle
				ModEvent.PushForm(handle, follower)
				ModEvent.Send(handle)
			EndIf
		EndIf
		follower.EvaluatePackage()
	EndIf
EndFunction
