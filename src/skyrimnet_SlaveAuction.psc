Scriptname skyrimnet_SlaveAuction extends Quest
{Slave auction in the basement hall (skyrimnetSlaveAuctionHall). The receptionist's rare drink
puts the player and their followers in the cage, stripped of everything; the cage guard asks who
goes on the stage next; the auctioneer sells each lot to the twelve buyers, everyone voiced by
SkyrimNet. Once the player is sold, everyone goes to an exit mod's cell (exits/*.json), or with no
exit mod liberators kill the player's buyer and set them all free. Other mods can send the player
here with the mod event skyrimnet_SlaveAuction_Capture.}

String Property PluginName = "skyrimnet_SlaveAuction.esp" AutoReadOnly
; JsonUtil paths start in Data/SKSE/Plugins/StorageUtilData/, hence the "../".
String Property StringsFile = "../skyrimnet_SlaveAuction/strings.json" AutoReadOnly
; SkyrimNet actions that would restrain, dress or start a fight among the held. The script could not
; undo them. Other mods' action names can be added to this file.
String Property BlockedActionsFile = "../skyrimnet_SlaveAuction/blocked_actions.json" AutoReadOnly
Int Property BlockedActionSeconds = 7200 AutoReadOnly
Int Property CaptureReasonMaxLength = 500 AutoReadOnly   ; a long string in a save can break it

; Values of skyrimnet_SlaveAuction_State, which the dialogue conditions read.
Int Property StateIdle = 0 AutoReadOnly
Int Property StateCaged = 1 AutoReadOnly
Int Property StateOnStage = 2 AutoReadOnly
Int Property StateFreed = 3 AutoReadOnly

; Captive 0 is the player, 1..MaxFollowers the followers caught with them.
Int Property MaxFollowers = 10 AutoReadOnly
Int Property BuyerCount = 12 AutoReadOnly
Float Property FollowerScanRadius = 4096.0 AutoReadOnly
Int Property StartingBid = 100 AutoReadOnly
; Longest wait for SkyrimNet to voice one narration.
Float Property SpeechTimeoutSeconds = 60.0 AutoReadOnly
Float Property SpeechStartTimeoutSeconds = 20.0 AutoReadOnly
Float Property QuietTimeoutSeconds = 15.0 AutoReadOnly
; Exit mods. Each ships one JSON here; FilesInFolder starts in the game folder, JsonUtil as above.
String Property ExitsFolder = "Data/SKSE/Plugins/skyrimnet_SlaveAuction/exits" AutoReadOnly
String Property ExitsJsonPath = "../skyrimnet_SlaveAuction/exits/" AutoReadOnly
Int Property ExitApiVersion = 1 AutoReadOnly
Int Property DefaultExitWeight = 10 AutoReadOnly
; An exit's JSON says which of these it is for, in "for".
String Property ExitForPlayerSold = "player_sold" AutoReadOnly
String Property ExitForFollowersSold = "followers_sold" AutoReadOnly
String Property ExitForFollowersBought = "followers_bought" AutoReadOnly
String Property SoldCaptivesKey = "skyrimnet_SlaveAuction_SoldCaptives" AutoReadOnly
String Property BoughtCaptivesKey = "skyrimnet_SlaveAuction_BoughtCaptives" AutoReadOnly
String Property WaitingValue = "WaitingForPlayer" AutoReadOnly   ; follower frameworks do not warp one who waits
String Property BuybackListKey = "skyrimnet_SlaveAuction_Buyback" AutoReadOnly
String Property BuybackPriceKey = "skyrimnet_SlaveAuction_BuybackPrice" AutoReadOnly
Int Property BuybackGlobalID = 0x832 AutoReadOnly
Int Property BuybackMarkupPercent = 150 AutoReadOnly
Int Property SellerSharePercent = 50 AutoReadOnly
Int Property GoldID = 0x00000F AutoReadOnly
Int Property BidUnit = 50 AutoReadOnly                 ; the buyers raise by one to five of these
Int Property MaxRaise = 250 AutoReadOnly
Int Property BidStep = 100 AutoReadOnly                ; the player's bid over the current price
Float Property LastCallSeconds = 5.0 AutoReadOnly
Int Property DefaultBidKey = 37 AutoReadOnly           ; K
Int Property LeftShiftKey = 42 AutoReadOnly
Int Property RightShiftKey = 54 AutoReadOnly
Int Property DefaultGuestDays = 3 AutoReadOnly
Int Property DefaultPriceScale = 100 AutoReadOnly
Int Property MaxExits = 128 AutoReadOnly               ; the limit of a Papyrus array
String Property SettingsFile = "../skyrimnet_SlaveAuction/settings.json" AutoReadOnly   ; the MCM's, for all saves
Float Property ExitAckTimeoutSeconds = 15.0 AutoReadOnly
Float Property ArrivalSpread = 0.4 AutoReadOnly        ; of the cage's spacing, so a small room holds them
String Property CaptivesListKey = "skyrimnet_SlaveAuction_Captives" AutoReadOnly
Float Property FadeInSeconds = 1.5 AutoReadOnly
Float Property SpeechStallSeconds = 10.0 AutoReadOnly
Float Property SpeechGapSeconds = 1.5 AutoReadOnly     ; a line can be several sentences
String Property RestraintPoseEnterEvent = "ZaZXcrossFFSTILL_Enter" AutoReadOnly
String Property RestraintPoseEvent = "ZaZXcrossFFSTILL_Loop" AutoReadOnly     ; facing front, head down
String Property DefaultIdleEvent = "IdleForceDefaultState" AutoReadOnly
Float Property RescueTimeoutSeconds = 20.0 AutoReadOnly

; Records of this plugin, looked up by FormID so the quest needs no property links.
Int Property StateGlobalID = 0x818 AutoReadOnly
Int Property CaptiveFactionID = 0x817 AutoReadOnly
Int Property CageMarkerID = 0x900 AutoReadOnly
Int Property StageMarkerID = 0x901 AutoReadOnly
Int Property ExitAreaMarkerID = 0x903 AutoReadOnly
Int Property HoldingMarkerID = 0x904 AutoReadOnly
Int Property CageDoorID = 0x905 AutoReadOnly
Int Property HallDoorID = 0x906 AutoReadOnly
Int Property OutsideDoorID = 0x907 AutoReadOnly
Float Property OutsideDoorX = -768.0 AutoReadOnly       ; where the plugin puts it (gen_hall.py)
Float Property OutsideDoorY = 1664.0 AutoReadOnly
Float Property OutsideDoorZ = 256.0 AutoReadOnly
Int Property PlayerChestID = 0x908 AutoReadOnly
Int Property FollowerChestID = 0x909 AutoReadOnly      ; 0x909..0x90D, one per follower slot
Int Property MoreFollowerChestID = 0x925 AutoReadOnly  ; 0x925..0x929, for slots 6 to 10
Int Property LiberatorMarkerID = 0x90E AutoReadOnly
Int Property BuyerExitMarkerID = 0x90F AutoReadOnly
Int Property ReceptionistID = 0x910 AutoReadOnly   ; the staff are consecutive: receptionist, guard, auctioneer
Int Property StaffCount = 3 AutoReadOnly
Float Property StaffPostTolerance = 256.0 AutoReadOnly
Int Property AuctioneerMarkerID = 0x902 AutoReadOnly
Int Property GuardID = 0x911 AutoReadOnly
Int Property AuctioneerID = 0x912 AutoReadOnly
Int Property BuyerID = 0x913 AutoReadOnly              ; 0x913..0x91E
Int Property TwelfthSeatBuyer = 11 AutoReadOnly        ; Lady Livia, whose seat an exit's buyer takes
Int Property DesignatedBuyerID = 0x93C AutoReadOnly    ; the man, then the woman at 0x93D; both start disabled
String Property BuyerRoleKey = "skyrimnet_SlaveAuction_BuyerRole" AutoReadOnly   ; read by the bio prompt
Int Property LiberatorID = 0x91F AutoReadOnly          ; 0x91F..0x921
Int Property LiberatorCount = 3 AutoReadOnly

; Skyrim.esm and ZaZ records.
Int Property FadeToBlackImodID = 0x0F756D AutoReadOnly
Int Property FadeToBlackHoldImodID = 0x0F756E AutoReadOnly
Int Property FadeToBlackBackImodID = 0x0F756F AutoReadOnly
Int Property AudienceBuyer = 10 AutoReadOnly           ; chair 10: middle of the row nearest the stage
Int Property SitPackageID = 0x0ECEEB AutoReadOnly      ; defaultSitLinkedRefNoConv
Int Property SitStateSitting = 3 AutoReadOnly
Float Property SeatTimeoutSeconds = 4.0 AutoReadOnly
Float Property StageEntryOffsetX = -90.0 AutoReadOnly
Int Property DoNothingID = 0x0654E2 AutoReadOnly
Int Property CurrentFollowerFactionID = 0x05C84E AutoReadOnly
Int Property CurrentHirelingFactionID = 0x0BD738 AutoReadOnly
; Bound hands, as for the prisoners at Helgen (WEPrisonerAliasScript, MQ101).
Int Property BareOutfitID = 0x829 AutoReadOnly
Int Property PlayerAliasID = 0 AutoReadOnly
Int Property PrisonerCuffsID = 0x103941 AutoReadOnly
Int Property PrisonerCuffsPlayerID = 0x10E039 AutoReadOnly
Int Property BoundStandingIdleID = 0x0B600A AutoReadOnly         ; OffsetBoundStandingStart
Int Property BoundStandingPlayerIdleID = 0x109837 AutoReadOnly   ; OffsetBoundStandingPlayerInstant
Int Property OffsetStopIdleID = 0x08C0A0 AutoReadOnly
Int Property IronSwordID = 0x012EB7 AutoReadOnly
Int Property RestraintID = 0x0419CC AutoReadOnly       ; zbfXCrossLightFFquiet_DarkWood, facing the buyers

Actor[] captives
Actor[] leftBehind
Bool[] lostBoundPose
Actor[] soldTo
Outfit[] savedOutfits
Int[] soldFor
Bool[] isSold
Int captiveCount
Actor playerBuyer
Actor designatedBuyer
Actor currentLot
ObjectReference restraint
Actor posedLot
Bool busy
Bool audioPlaying
Actor narrationSpeaker
Bool speakerStarted
Bool speakerPlaying
Int speakerLines
Float lastLineEnd
String pendingAction
Int outsideDoorTries
String captureReason
String chosenExit
Bool exitAcked
Bool playerIsGuest                  ; only followers were caught
Int firstCaptive                    ; 1 then: captives[0] is the player and is not held
Bool consigned                      ; the player brought them to the house
Actor[] offered
Bool onlyOffered                    ; of the followers around, only those in offered are caught
Bool biddingOpen
Bool handRaised                     ; the player bids at their next turn, over whatever the price is then
Bool bidRefused                     ; told once why a press did nothing: notifications queue up
Int currentPrice
Actor currentLeader
Bool auctionAborted

Event OnInit()
	Setup()
	ResetHall()
EndEvent

; The door's 3D has come, so the hall is loaded: captives who came while it was not take their pose now.
Function HallLoaded()
	ReturnOutsideDoor()
	If playerIsGuest && AuctionState() == StateCaged
		Request("rebind")
	EndIf
EndFunction

; Called again by the player alias on every save load: mod-event registrations do not survive one.
Function Setup()
	RegisterForModEvent("skyrimnet_SlaveAuction_Capture", "OnCaptureRequested")
	RegisterForModEvent("skyrimnet_SlaveAuction_ExitAck", "OnExitAck")
	RegisterForModEvent("SkyrimNet_AudioStarted", "OnSkyrimNetAudioStarted")
	RegisterForModEvent("SkyrimNet_AudioEnded", "OnSkyrimNetAudioEnded")
	Ref(OutsideDoorID).BlockActivation(False)   ; saves from when the script moved the player out
	Ref(HallDoorID).BlockActivation(False)   ; saves from when this was a scripted exit door
	outsideDoorTries = 0
	ReturnOutsideDoor()
	busy = False
	If biddingOpen   ; key registrations do not survive a load either
		RegisterForKey(JsonUtil.GetIntValue(SettingsFile, "bidKey", DefaultBidKey))
	EndIf
	If AuctionState() == StateIdle
		ReturnStaffToPosts()
	ElseIf AuctionState() == StateCaged
		Request("rebind")
		SetActionsBlocked(True)
	EndIf
	WatchBoundCaptives()
EndFunction

; A save keeps where an alias's reference stood when it first met it, even after the plugin has moved it.
; Called on load and when the door's 3D loads: turning it may only work once it has 3D, and the
; Disable below loads the 3D again, hence the limit.
Function ReturnOutsideDoor()
	ObjectReference outside = Ref(OutsideDoorID)
	Float away = Math.Abs(outside.GetPositionX() - OutsideDoorX) + Math.Abs(outside.GetPositionY() - OutsideDoorY) + Math.Abs(outside.GetPositionZ() - OutsideDoorZ)
	Float turned = outside.GetAngleZ()
	If (away > 1.0 || (turned > 1.0 && turned < 359.0)) && outsideDoorTries < 3
		outsideDoorTries += 1
		outside.SetPosition(OutsideDoorX, OutsideDoorY, OutsideDoorZ)
		outside.SetAngle(0.0, 0.0, 0.0)
		outside.Disable()
		outside.Enable()
	EndIf
EndFunction

; A save keeps where an actor last stood, even after the plugin has moved their post.
Function ReturnStaffToPosts()
	Int i = 0
	While i < StaffCount
		Actor staff = Ref(ReceptionistID + i) as Actor
		ObjectReference post = staff.GetLinkedRef()
		If post && staff.GetDistance(post) > StaffPostTolerance
			staff.MoveTo(post)
		EndIf
		i += 1
	EndWhile
EndFunction

; ---------------------------------------------------------------------------------------------
; Requests: dialogue fragments and mod events only queue the work, which runs once the
; conversation has closed.
; ---------------------------------------------------------------------------------------------

Function Request(String requested)
	pendingAction = requested
	RegisterForSingleUpdate(0.5)
EndFunction

Event OnUpdate()
	String requested = pendingAction
	pendingAction = ""
	If requested == "capture"
		Capture(True, False)
	ElseIf requested == "offer"
		OfferFollowers()
	ElseIf requested == "buyback"
		BuyBack()
	ElseIf requested == "brawl"
		GuestBrawl()
	ElseIf requested == "choose"
		ChooseNextLot()
	ElseIf requested == "lot"
		RunLot(currentLot)
	ElseIf requested == "rebind"
		PlayBoundIdles()
	EndIf
EndEvent

; Another mod sends the player (and the followers around them) straight to the cage, e.g. after a
; defeat: SendModEvent("skyrimnet_SlaveAuction_Capture", "defeated by bandits on the road"). The text
; tells SkyrimNet how they came here. The answer goes out as skyrimnet_SlaveAuction_CaptureResult:
; Event OnCaptureResult(String result, String reason, Form requester), result "accepted", "busy" or
; "no_captives". A number of 1.0 after the text catches only the followers, and the player comes to bid.
Event OnCaptureRequested(String eventName, String strArg, Float numArg, Form sender)
	If busy || IsHoldingCaptives()
		SendCaptureResult("busy", strArg, sender)
		Return
	EndIf
	Bool withoutPlayer = numArg == 1.0
	If withoutPlayer && NearbyFollowerCount() == 0
		SendCaptureResult("no_captives", strArg, sender)
		Return
	EndIf
	SendCaptureResult("accepted", strArg, sender)
	consigned = False
	captureReason = strArg
	If StringUtil.GetLength(captureReason) > CaptureReasonMaxLength
		captureReason = StringUtil.Substring(captureReason, 0, CaptureReasonMaxLength)
	EndIf
	Capture(False, withoutPlayer)
EndEvent

Function SendCaptureResult(String result, String reason, Form requester)
	Debug.Trace("skyrimnet_SlaveAuction: capture " + result + " for " + requester + ": " + reason)
	Int handle = ModEvent.Create("skyrimnet_SlaveAuction_CaptureResult")
	If handle
		ModEvent.PushString(handle, result)
		ModEvent.PushString(handle, reason)
		ModEvent.PushForm(handle, requester)
		ModEvent.Send(handle)
	EndIf
EndFunction

; ---------------------------------------------------------------------------------------------
; Capture: the drink, the stripping, the cage
; ---------------------------------------------------------------------------------------------

Function Capture(Bool drugged, Bool withoutPlayer)
	If busy || IsHoldingCaptives()
		Return
	EndIf
	busy = True
	Actor player = Game.GetPlayer()
	If drugged
		captureReason = ""
		Debug.Notification(Phrase("drinkDizzy", "The drink burns... the room starts to spin."))
		Utility.Wait(2.5)
	EndIf
	FadeOut()
	; The last auction is cleared away here, whatever its ending, and an exit may have borrowed a buyer.
	ResetHall()
	playerIsGuest = withoutPlayer
	firstCaptive = withoutPlayer as Int
	auctionAborted = False
	If withoutPlayer
		ChooseExit(ExitForFollowersSold)
	Else
		consigned = False
		ChooseExit(ExitForPlayerSold)
	EndIf
	SetUpTwelfthSeat()
	GatherCaptives(player)
	Faction captiveFaction = Own(CaptiveFactionID) as Faction
	Package doNothing = Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package
	ObjectReference cage = Ref(CageMarkerID)
	Int i = firstCaptive
	While i < captiveCount
		Actor captive = captives[i]
		If captive != player
			savedOutfits[i] = captive.GetActorBase().GetOutfit()
			captive.SetOutfit(Own(BareOutfitID) as Outfit)
		EndIf
		captive.UnequipAll()
		captive.RemoveAllItems(ChestFor(i), False, False)
		captive.AddToFaction(captiveFaction)
		captive.SetFactionRank(captiveFaction, 1)
		captive.StopCombat()
		captive.StopCombatAlarm()
		If captive.IsBleedingOut()   ; an entry mod's defeat
			captive.ResetHealthAndLimbs()
		EndIf
		If captive != player
			ActorUtil.AddPackageOverride(captive, doNothing, 100)
			captive.EvaluatePackage()
		EndIf
		If withoutPlayer
			; Or a follower framework (NFF's catch-up) brings them straight back to the player.
			captive.SetActorValue(WaitingValue, 1.0)
			LeaveParty(captive)
		EndIf
		captive.MoveTo(cage, CageOffsetX(i), CageOffsetY(i), 0.0)
		i += 1
	EndWhile
	ObjectReference cageDoor = Ref(CageDoorID)
	cageDoor.SetOpen(False)
	cageDoor.Lock(True)
	cageDoor.SetLockLevel(255)
	If !withoutPlayer
		Game.EnableFastTravel(False)
	EndIf
	SetAuctionState(StateCaged)
	PlaceRestraint()
	BindCaptives()
	SetActionsBlocked(True)
	Utility.Wait(1.0)
	FadeIn()
	If withoutPlayer
		Ref(HallDoorID).Lock(False)
		RegisterForSingleUpdateGameTime(24.0 * JsonUtil.GetIntValue(SettingsFile, "guestDays", DefaultGuestDays))
		Debug.Notification(Phrase("followersTaken", "Your followers are in the cage below. The hall door is open to you."))
	Else
		Debug.Notification(Phrase("wakeInCage", "You wake up naked, locked in a cage."))
	EndIf
	; Bound captives set off other mods' narrations, and a directed line waiting behind them expires.
	WaitForQuiet()
	busy = False
	If withoutPlayer && !IsInHall(player)
		Return
	EndIf
	Actor guard = Ref(GuardID) as Actor
	SkyrimNetApi.DirectNarration(guard.GetDisplayName() + " looks over the new captives in the cage: " + CaptiveNames() \
		+ ". " + HowTheyCame(drugged) + " They were stripped of everything they owned, and tonight they will be auctioned off one by one. " \
		+ guard.GetDisplayName() + " mocks them through the bars.", guard, player)
EndFunction

String Function HowTheyCame(Bool drugged)
	If playerIsGuest && consigned
		Return Game.GetPlayer().GetDisplayName() + " gave them the drink and handed them over to the house, and now sits among the buyers."
	EndIf
	If drugged
		Return "They were drugged with the receptionist's rare drink."
	ElseIf captureReason != ""
		Return "How they came here: " + captureReason + "."
	EndIf
	Return "They were brought here in chains."
EndFunction

; Hands bound, as at Helgen. The player can still walk and talk to the guard, but not fight.
Function BindCaptives()
	Int i = firstCaptive
	While i < captiveCount
		Armor cuffs = CuffsFor(captives[i])
		captives[i].AddItem(cuffs, 1, True)
		captives[i].EquipItem(cuffs, True, True)
		If !playerIsGuest   ; the player may be far from the hall, and no 3D comes until they enter it
			WaitFor3D(captives[i])
		EndIf
		i += 1
	EndWhile
	If !playerIsGuest
		Game.DisablePlayerControls(False, True, False, False, False, False, False, False)
	EndIf
	PlayBoundIdles()
	WatchBoundCaptives()
EndFunction

Function SetActionsBlocked(Bool blocked)
	Int seconds = 0
	If blocked
		seconds = BlockedActionSeconds
	EndIf
	Int count = JsonUtil.StringListCount(BlockedActionsFile, "actions")
	Int i = 0
	While i < count
		SkyrimNetApi.SetActionCooldown(JsonUtil.StringListGet(BlockedActionsFile, "actions", i), seconds)
		i += 1
	EndWhile
EndFunction

Function WatchBoundCaptives()
	(GetAlias(PlayerAliasID) as skyrimnet_SlaveAuctionPlayer).Watch()
EndFunction

; Called every second by the player alias while anyone is held; False ends the watch. Drawing a
; weapon ends the bound animation, and other mods can give the fighting controls back: both are
; undone here. A follower draws when the player does.
Bool Function KeepCaptivesBound()
	Int current = AuctionState()
	If current != StateCaged && current != StateOnStage
		Return False
	EndIf
	Actor player = Game.GetPlayer()
	If playerIsGuest && !auctionAborted && player.IsInCombat() && IsInHall(player)
		auctionAborted = True
		Request("brawl")
		Return False
	EndIf
	If current == StateCaged && !playerIsGuest && Game.IsFightingControlsEnabled()
		Game.DisablePlayerControls(False, True, False, False, False, False, False, False)
	EndIf
	Actor guard = Ref(GuardID) as Actor
	If guard.IsInCombat()
		guard.StopCombat()
	EndIf
	Int i = firstCaptive
	While i < captiveCount
		Actor captive = captives[i]
		If playerIsGuest && captive && !(current == StateOnStage && captive == currentLot) && !IsInHall(captive)
			ReturnToHold(i)   ; a framework that does not let go of a follower
		EndIf
		If captive && !isSold[i] && !(current == StateOnStage && captive == currentLot)
			If captive != player && captive.IsInCombat()
				captive.StopCombat()
				lostBoundPose[i] = True
			ElseIf captive.IsWeaponDrawn()
				captive.SheatheWeapon()
				lostBoundPose[i] = True
			ElseIf lostBoundPose[i]
				PlayBoundIdle(captive)
				lostBoundPose[i] = False
			EndIf
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction

Function ReturnToHold(Int i)
	If isSold[i]
		captives[i].MoveTo(Ref(HoldingMarkerID))
	Else
		captives[i].MoveTo(Ref(CageMarkerID), CageOffsetX(i), CageOffsetY(i), 0.0)
	EndIf
EndFunction

; The unsold captives only: a sold one stands on the stage or in the holding room.
Function PlayBoundIdles()
	Int i = firstCaptive
	While i < captiveCount
		If captives[i] && !isSold[i]
			PlayBoundIdle(captives[i])
		EndIf
		i += 1
	EndWhile
EndFunction

Function PlayBoundIdle(Actor captive)
	If captive == Game.GetPlayer()
		captive.PlayIdle(Game.GetForm(BoundStandingPlayerIdleID) as Idle)
	Else
		captive.PlayIdle(Game.GetForm(BoundStandingIdleID) as Idle)
	EndIf
EndFunction

Function UnbindArms(Actor captive)
	captive.PlayIdle(Game.GetForm(OffsetStopIdleID) as Idle)
	Armor cuffs = CuffsFor(captive)
	captive.UnequipItem(cuffs, False, True)
	captive.RemoveItem(cuffs, captive.GetItemCount(cuffs), True)
EndFunction

Armor Function CuffsFor(Actor captive)
	If captive == Game.GetPlayer()
		Return Game.GetForm(PrisonerCuffsPlayerID) as Armor
	EndIf
	Return Game.GetForm(PrisonerCuffsID) as Armor
EndFunction

; The player, then every teammate of theirs nearby, up to MaxFollowers. Any more were not caught:
; they stop following and stay where they are. A follower framework may make them followers again,
; so they are also held there until the captives are free.
Function GatherCaptives(Actor player)
	captives = new Actor[11]
	savedOutfits = new Outfit[11]
	lostBoundPose = new Bool[11]
	soldTo = new Actor[11]
	soldFor = new Int[11]
	isSold = new Bool[11]
	captives[0] = player
	captiveCount = 1
	Actor[] nearby = MiscUtil.ScanCellNPCs(player, FollowerScanRadius)
	Int i = 0
	leftBehind = new Actor[64]
	Int left = 0
	Package doNothing = Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package
	While i < nearby.Length
		Actor npc = nearby[i]
		If IsCatchableFollower(npc, player) && (!onlyOffered || offered.Find(npc) >= 0)
			If captiveCount <= MaxFollowers
				captives[captiveCount] = npc
				captiveCount += 1
			ElseIf !playerIsGuest && left < leftBehind.Length
				leftBehind[left] = npc
				left += 1
				npc.SetPlayerTeammate(False)
				npc.RemoveFromFaction(Game.GetForm(CurrentFollowerFactionID) as Faction)
				npc.RemoveFromFaction(Game.GetForm(CurrentHirelingFactionID) as Faction)
				ActorUtil.AddPackageOverride(npc, doNothing, 100)
				npc.EvaluatePackage()
			EndIf
		EndIf
		i += 1
	EndWhile
	onlyOffered = False
	Debug.Trace("skyrimnet_SlaveAuction: caught " + CaptiveNames())
	StorageUtil.FormListClear(None, CaptivesListKey)
	i = firstCaptive
	While i < captiveCount
		StorageUtil.FormListAdd(None, CaptivesListKey, captives[i])
		i += 1
	EndWhile
EndFunction

Bool Function IsHouseActor(Actor npc)
	Int id = Math.LogicalAnd(npc.GetFormID(), 0x00000FFF)
	Return Game.GetFormFromFile(id, PluginName) == npc
EndFunction

Float Function CageOffsetX(Int i)
	If i == 0
		Return 0.0
	ElseIf i % 2 == 1
		Return -130.0 * ((i + 1) / 2)
	EndIf
	Return 130.0 * (i / 2)
EndFunction

Float Function CageOffsetY(Int i)
	Return 90.0 * (i % 3) - 90.0
EndFunction

ObjectReference Function ChestFor(Int i)
	If i == 0
		Return Ref(PlayerChestID)
	EndIf
	If i <= 5
		Return Ref(FollowerChestID + i - 1)
	EndIf
	Return Ref(MoreFollowerChestID + i - 6)
EndFunction

String Function CaptiveNames()
	String names = ""
	Int i = firstCaptive
	While i < captiveCount
		If i > firstCaptive
			names += ", "
		EndIf
		names += captives[i].GetDisplayName()
		i += 1
	EndWhile
	Return names
EndFunction

; ---------------------------------------------------------------------------------------------
; The guard: who goes on the stage next
; ---------------------------------------------------------------------------------------------

Function ChooseNextLot()
	If busy || AuctionState() != StateCaged
		Return
	EndIf
	; entries: the unsold followers, then the player (always the last lot), then "not yet"
	String[] entries = Utility.CreateStringArray(captiveCount + 1)
	Int[] lotOf = Utility.CreateIntArray(captiveCount + 1, -1)
	Int n = 0
	Int i = 1
	While i < captiveCount
		If !isSold[i]
			entries[n] = captives[i].GetDisplayName()
			lotOf[n] = i
			n += 1
		EndIf
		i += 1
	EndWhile
	If !playerIsGuest
		entries[n] = Phrase("lotPlayer", "Yourself (the last lot)")
		lotOf[n] = 0
		n += 1
	EndIf
	entries[n] = Phrase("lotNotYet", "Not yet")
	n += 1
	Int pick = PickFromList(entries, n)
	If pick < 0 || lotOf[pick] < 0
		Return
	EndIf
	currentLot = captives[lotOf[pick]]
	Request("lot")
EndFunction

Int Function PickFromList(String[] entries, Int count)
	UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
	If !menu
		Debug.Notification(Phrase("menuMissing", "UIExtensions is missing: the list cannot open."))
		Return -1
	EndIf
	Int i = 0
	While i < count
		menu.AddEntryItem(entries[i])
		i += 1
	EndWhile
	menu.OpenMenu()
	Return menu.GetResultInt()
EndFunction

; ---------------------------------------------------------------------------------------------
; One lot on the stage
; ---------------------------------------------------------------------------------------------

Function RunLot(Actor lot)
	If busy || !lot || AuctionState() != StateCaged
		Return
	EndIf
	busy = True
	SetAuctionState(StateOnStage)
	Actor player = Game.GetPlayer()
	Bool isPlayer = lot == player
	Actor auctioneer = Ref(AuctioneerID) as Actor
	String lotName = lot.GetDisplayName()

	; With no listener SkyrimNet has a speaker walk up to the player. The auctioneer stays at his post
	; and addresses the buyers, through the one in the middle of the front row.
	Actor audience = Ref(BuyerID + AudienceBuyer) as Actor

	FadeOut()
	HoldAuctioneerAtPost(auctioneer)
	If isPlayer
		Game.DisablePlayerControls(True, True, False, False, True, True, True, True)
	EndIf
	PutOnStage(lot)
	Utility.Wait(1.0)
	FadeIn()
	If playerIsGuest
		OpenBidding()
	EndIf

	Narrate(auctioneer.GetDisplayName() + " presents the next lot to the buyers: " + lotName + ", " + Describe(lot) \
		+ ", naked and bound spread-eagled to an X-shaped cross on the stage. " + auctioneer.GetDisplayName() \
		+ " tells the buyers who " + lotName + " is and what " + Pronoun(lot) + " has done, praises " + Possessive(lot) \
		+ " selling points, and opens the bidding at " + StartingBid + " gold.", auctioneer, audience)
	If !isPlayer
		Narrate(lotName + " hangs naked on the X-shaped cross before the crowd of buyers, being sold like cattle. " + lotName \
			+ " reacts to it in character, with shame, despair or anger.", lot, audience)
	EndIf

	Int price = StartingBid
	Actor bidder = None
	If playerIsGuest
		RunPlayerBidding(lot, auctioneer)
		bidder = currentLeader
		price = currentPrice
	Else
		Int bids = Utility.RandomInt(4, 5)
		Int round = 1
		While round <= bids
			bidder = NextBidder(bidder, round, bids)
			price += Utility.RandomInt(1, 5) * BidUnit
			Narrate(bidder.GetDisplayName() + " raises a hand from the buyers' seats and bids " + price + " gold for " + lotName + ".", bidder, auctioneer)
			If round == 2 && !isPlayer
				Narrate(lotName + ", still bound to the cross, hears the buyers bid on " + Objective(lot) + " and reacts in character.", lot, bidder)
			EndIf
			round += 1
		EndWhile
	EndIf
	If auctionAborted
		busy = False
		Return
	EndIf
	Narrate("No one bids higher than " + bidder.GetDisplayName() + ". " + auctioneer.GetDisplayName() \
		+ " brings down the gavel and declares " + lotName + " sold to " + bidder.GetDisplayName() + " for " + price + " gold.", auctioneer, bidder)
	If !isPlayer
		Narrate(lotName + " has just been sold to " + bidder.GetDisplayName() + " for " + price + " gold, and is about to be led away. " \
			+ lotName + " cries out at " + Possessive(lot) + " new owner in anger or grief, in character.", lot, bidder)
	EndIf

	If auctionAborted
		busy = False
		Return
	EndIf
	If playerIsGuest
		SettleGuestSale(bidder, price)
	EndIf
	Int index = captives.Find(lot)
	isSold[index] = True
	soldTo[index] = bidder
	soldFor[index] = price
	lot.SetFactionRank(Own(CaptiveFactionID) as Faction, 2)
	SendSoldEvent(lot, bidder, price)

	If isPlayer
		playerBuyer = bidder
		SellTheRest()
		If chosenExit != "" && ExitMarker(chosenExit)
			LeaveForExit()
		Else
			EndAuction()
		EndIf
		Return
	EndIf
	FadeOut()
	TakeOffStage(lot)
	lot.MoveTo(Ref(HoldingMarkerID))
	HoldAuctioneerAtPost(auctioneer)
	Utility.Wait(0.5)
	FadeIn()
	If playerIsGuest && AllSold()
		CloseGuestAuction()
	Else
		SetAuctionState(StateCaged)
	EndIf
	busy = False
EndFunction

; The X cross is ZaZ's and is placed at run time; without ZaZ the lot stands on the stage, held in
; place. Placed at the capture, so its 3D has long been loaded when the first lot is called:
; nobody can be seated in furniture that has none yet.
Function PlaceRestraint()
	If restraint
		Return
	EndIf
	Form restraintBase = Game.GetFormFromFile(RestraintID, "ZaZAnimationPack.esm")
	If restraintBase
		ObjectReference stage = Ref(StageMarkerID)
		restraint = stage.PlaceAtMe(restraintBase)
		restraint.SetAngle(0.0, 0.0, stage.GetAngleZ())
	EndIf
EndFunction

Function WaitFor3D(ObjectReference target)
	Float startedAt = Utility.GetCurrentRealTime()
	While !target.Is3DLoaded() && Utility.GetCurrentRealTime() - startedAt < SeatTimeoutSeconds
		Utility.Wait(0.25)
	EndWhile
EndFunction

; SkyrimNet walks a speaker up to the listener; between lots he is put back, and held there.
Function HoldAuctioneerAtPost(Actor auctioneer)
	auctioneer.MoveTo(Ref(AuctioneerMarkerID))
	auctioneer.SetDontMove(True)
EndFunction

Function PutOnStage(Actor lot)
	PlaceRestraint()
	UnbindArms(lot)
	; On the buyers' side of the cross, in front of its entry point.
	lot.MoveTo(Ref(StageMarkerID), StageEntryOffsetX, 0.0, 0.0)
	Bool isPlayer = lot == Game.GetPlayer()
	If !isPlayer
		ActorUtil.RemovePackageOverride(lot, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package)
		lot.EvaluatePackage()
	EndIf
	If !restraint
		lot.SetDontMove(!isPlayer)
		Return
	EndIf
	WaitFor3D(restraint)
	; A sit package on the linked cross, the way the buyers take their chairs; then ZaZ's own way
	; in; and if the engine still refuses, its pose played in place, so the lot at least looks locked.
	If !isPlayer
		PO3_SKSEFunctions.SetLinkedRef(lot, restraint)
		ActorUtil.AddPackageOverride(lot, Game.GetForm(SitPackageID) as Package, 100)
		lot.EvaluatePackage()
		If WaitUntilSeated(lot)
			Return
		EndIf
		Debug.Trace("[skyrimnet_SlaveAuction] " + lot.GetDisplayName() + " did not take the cross by package, activating it")
	EndIf
	restraint.Activate(lot)
	If WaitUntilSeated(lot)
		Return
	EndIf
	Debug.Trace("[skyrimnet_SlaveAuction] " + lot.GetDisplayName() + " did not take the cross, playing its pose")
	lot.MoveTo(restraint)
	lot.SetVehicle(restraint)
	If !isPlayer
		lot.SetDontMove(True)
	EndIf
	Debug.SendAnimationEvent(lot, RestraintPoseEnterEvent)
	Utility.Wait(0.5)
	Debug.SendAnimationEvent(lot, RestraintPoseEvent)
	posedLot = lot
EndFunction

Bool Function WaitUntilSeated(Actor lot)
	Float startedAt = Utility.GetCurrentRealTime()
	While Utility.GetCurrentRealTime() - startedAt < SeatTimeoutSeconds
		If lot.GetSitState() == SitStateSitting
			Return True
		EndIf
		Utility.Wait(0.25)
	EndWhile
	Return False
EndFunction

Function ReleasePose(Actor lot)
	If lot == posedLot
		lot.SetVehicle(None)
		Debug.SendAnimationEvent(lot, DefaultIdleEvent)
		posedLot = None
	EndIf
EndFunction

Function TakeOffStage(Actor lot)
	ReleasePose(lot)
	If lot != Game.GetPlayer()
		lot.SetDontMove(False)
		ActorUtil.RemovePackageOverride(lot, Game.GetForm(SitPackageID) as Package)
		PO3_SKSEFunctions.SetLinkedRef(lot, None)
		ActorUtil.AddPackageOverride(lot, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package, 100)
		lot.EvaluatePackage()
	EndIf
EndFunction

; A buyer at random, never the one who bid last.
; An exit's own buyer wins every lot: others bid too, but the last bid is theirs and the one before it
; another's, so they do not simply outbid themselves.
Actor Function NextBidder(Actor last, Int round, Int bids)
	If designatedBuyer && round == bids
		Return designatedBuyer
	EndIf
	Actor buyer = PickBidder(last)
	Int tries = 0
	While designatedBuyer && round == bids - 1 && buyer == designatedBuyer && tries < 20
		buyer = PickBidder(last)
		tries += 1
	EndWhile
	Return buyer
EndFunction

Actor Function PickBidder(Actor last)
	Int tries = 0
	While tries < 20
		Int seat = Utility.RandomInt(0, BuyerCount - 1)
		Actor buyer = Ref(BuyerID + seat) as Actor
		If designatedBuyer && seat == TwelfthSeatBuyer
			buyer = designatedBuyer
		EndIf
		If buyer && buyer != last && !buyer.IsDead() && !buyer.IsDisabled()
			Return buyer
		EndIf
		tries += 1
	EndWhile
	Return Ref(BuyerID) as Actor
EndFunction

; "a Nord woman of level 12, best at One-Handed and Archery"
String Function Describe(Actor who)
	String sex = "man"
	If who.GetActorBase().GetSex() == 1
		sex = "woman"
	EndIf
	Return "a " + who.GetRace().GetName() + " " + sex + " of level " + who.GetLevel() + ", best at " + TopSkills(who)
EndFunction

String Function TopSkills(Actor who)
	String[] skills = new String[18]
	skills[0] = "OneHanded"
	skills[1] = "TwoHanded"
	skills[2] = "Marksman"
	skills[3] = "Block"
	skills[4] = "Smithing"
	skills[5] = "HeavyArmor"
	skills[6] = "LightArmor"
	skills[7] = "Pickpocket"
	skills[8] = "Lockpicking"
	skills[9] = "Sneak"
	skills[10] = "Alchemy"
	skills[11] = "Speechcraft"
	skills[12] = "Alteration"
	skills[13] = "Conjuration"
	skills[14] = "Destruction"
	skills[15] = "Illusion"
	skills[16] = "Restoration"
	skills[17] = "Enchanting"
	Int best = 0
	Int second = 1
	Int i = 1
	While i < skills.Length
		Float value = who.GetBaseActorValue(skills[i])
		If value > who.GetBaseActorValue(skills[best])
			second = best
			best = i
		ElseIf i != best && value > who.GetBaseActorValue(skills[second])
			second = i
		EndIf
		i += 1
	EndWhile
	Return SkillName(skills[best]) + " and " + SkillName(skills[second])
EndFunction

String Function SkillName(String actorValue)
	If actorValue == "OneHanded"
		Return "one-handed weapons"
	ElseIf actorValue == "TwoHanded"
		Return "two-handed weapons"
	ElseIf actorValue == "Marksman"
		Return "archery"
	ElseIf actorValue == "HeavyArmor"
		Return "heavy armor"
	ElseIf actorValue == "LightArmor"
		Return "light armor"
	ElseIf actorValue == "Speechcraft"
		Return "speech"
	EndIf
	Return actorValue
EndFunction

String Function Pronoun(Actor who)
	If who.GetActorBase().GetSex() == 1
		Return "she"
	EndIf
	Return "he"
EndFunction

String Function Objective(Actor who)
	If who.GetActorBase().GetSex() == 1
		Return "her"
	EndIf
	Return "him"
EndFunction

String Function Possessive(Actor who)
	If who.GetActorBase().GetSex() == 1
		Return "her"
	EndIf
	Return "his"
EndFunction

; For mods that take the sold captives further: sender is the lot.
Function SendSoldEvent(Actor lot, Actor buyer, Int price)
	Int handle = ModEvent.Create("skyrimnet_SlaveAuction_Sold")
	If handle
		ModEvent.PushForm(handle, lot)
		ModEvent.PushForm(handle, buyer)
		ModEvent.PushInt(handle, price)
		ModEvent.Send(handle)
	EndIf
EndFunction

; The player was the last lot they saw, not the last lot: the others are sold off screen.
Function SellTheRest()
	Faction captiveFaction = Own(CaptiveFactionID) as Faction
	Int i = 1
	While i < captiveCount
		If !isSold[i]
			Int bids = Utility.RandomInt(4, 5)
			Int price = StartingBid
			While bids > 0
				price += Utility.RandomInt(1, 5) * 50
				bids -= 1
			EndWhile
			isSold[i] = True
			soldTo[i] = designatedBuyer
			If !designatedBuyer
				soldTo[i] = PickBidder(None)
			EndIf
			soldFor[i] = price
			If playerIsGuest
				SettleGuestSale(soldTo[i], price)
			EndIf
			captives[i].SetFactionRank(captiveFaction, 2)
			SendSoldEvent(captives[i], soldTo[i], price)
		EndIf
		i += 1
	EndWhile
EndFunction

; ---------------------------------------------------------------------------------------------
; Auctions without the player: only followers are caught, and the player comes to bid
; ---------------------------------------------------------------------------------------------

Bool Function IsCatchableFollower(Actor npc, Actor player)
	Return npc && npc != player && npc.IsPlayerTeammate() && !npc.IsDead() && !npc.IsChild() && !IsHouseActor(npc)
EndFunction

Bool Function IsInHall(Actor who)
	Return who.GetParentCell() == Ref(CageMarkerID).GetParentCell()
EndFunction

Int Function NearbyFollowerCount()
	Actor player = Game.GetPlayer()
	Actor[] nearby = MiscUtil.ScanCellNPCs(player, FollowerScanRadius)
	Int count = 0
	Int i = 0
	While i < nearby.Length
		If IsCatchableFollower(nearby[i], player)
			count += 1
		EndIf
		i += 1
	EndWhile
	Return count
EndFunction

; The receptionist's choice: one of them or all drink, and the player goes on as a guest.
Function OfferFollowers()
	If busy || IsHoldingCaptives()
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Actor[] nearby = MiscUtil.ScanCellNPCs(player, FollowerScanRadius)
	Actor[] followers = new Actor[11]
	String[] entries = new String[13]
	Int n = 0
	Int i = 0
	While i < nearby.Length && n < MaxFollowers
		If IsCatchableFollower(nearby[i], player)
			followers[n] = nearby[i]
			entries[n] = nearby[i].GetDisplayName()
			n += 1
		EndIf
		i += 1
	EndWhile
	If n == 0
		Debug.Notification(Phrase("noFollowers", "No follower of yours is here."))
		Return
	EndIf
	entries[n] = Phrase("lotAll", "All of them")
	entries[n + 1] = Phrase("lotNotYet", "Not yet")
	Int pick = PickFromList(entries, n + 2)
	If pick < 0 || pick == n + 1
		Return
	EndIf
	onlyOffered = pick != n
	offered = new Actor[1]
	offered[0] = followers[pick]
	consigned = True
	captureReason = ""
	Capture(False, True)
EndFunction

Event OnKeyDown(Int keyCode)
	If !biddingOpen || Utility.IsInMenuMode() || handRaised
		Return
	EndIf
	If JsonUtil.GetIntValue(SettingsFile, "bidShift") == 1 && !Input.IsKeyPressed(LeftShiftKey) && !Input.IsKeyPressed(RightShiftKey)
		Return
	EndIf
	Actor player = Game.GetPlayer()
	If currentLeader == player
		RefuseBid(Phrase("bidHolding", "You hold the highest bid."))
		Return
	EndIf
	If currentPrice + BidStep > player.GetItemCount(Game.GetForm(GoldID))
		RefuseBid(Phrase("bidTooMuch", "You do not have that much gold."))
		Return
	EndIf
	; One raised hand until it has been taken: a key held or pressed again must not run the price up.
	handRaised = True
	Debug.Notification(Phrase("bidRaised", "You raise your hand"))
EndEvent

Function RefuseBid(String why)
	If !bidRefused
		bidRefused = True
		Debug.Notification(why)
	EndIf
EndFunction

; The AI says the bid in the player's own character and voice, in turn, as the buyers do. The event
; tells it what they are doing; that kind of event sets off no reactions by itself.
Function SayBid(Actor player, Actor lot, Int bid)
	If auctionAborted
		Return
	EndIf
	WaitForQuiet()
	narrationSpeaker = player
	speakerStarted = False
	speakerPlaying = False
	speakerLines = 0
	lastLineEnd = 0.0
	String who = player.GetDisplayName()
	SkyrimNetApi.RegisterPersistentEvent(who + " raises a hand from among the buyers to bid for " + lot.GetDisplayName() + ". " + who + "'s bid is exactly " + bid + " gold, no more and no less: " + who + " says the number " + bid + " aloud and no other amount of gold.", player, Ref(AuctioneerID) as Actor)
	SkyrimNetApi.TriggerPlayerDialogue()
	WaitForSpeech()
EndFunction

; From the moment the lot is presented, so that a press during the auctioneer's speech counts.
Function OpenBidding()
	currentPrice = StartingBid
	currentLeader = None
	handRaised = False
	biddingOpen = True
	RefreshBidKey()
	Debug.Notification(Phrase("bidHowTo", "Press the bid key to raise your hand."))
	ShowBidStatus()
EndFunction

; Called by the MCM too: the key may change while a lot is on the stage.
Function RefreshBidKey()
	UnregisterForAllKeys()
	If biddingOpen
		RegisterForKey(JsonUtil.GetIntValue(SettingsFile, "bidKey", DefaultBidKey))
	EndIf
EndFunction

Function ShowBidStatus()
	bidRefused = False
	Debug.Notification(Phrase("bidStatus", "Current bid") + ": " + currentPrice + " / " + Phrase("bidGold", "your gold") + ": " + Game.GetPlayer().GetItemCount(Game.GetForm(GoldID)))
EndFunction

; What the buyers will go to for this lot: the same range as the auctions the player cannot bid in.
Int Function BuyersLimit()
	Int bids = Utility.RandomInt(4, 5)
	Int limit = StartingBid
	While bids > 0
		limit += Utility.RandomInt(1, 5) * BidUnit
		bids -= 1
	EndWhile
	Return limit * JsonUtil.GetIntValue(SettingsFile, "priceScale", DefaultPriceScale) / 100
EndFunction

; Runs until the buyers are out and the player does not answer the last call. Leaves the winner and
; the price in currentLeader and currentPrice. No line of its own for the player's bids: the next
; line mentions them.
Function RunPlayerBidding(Actor lot, Actor auctioneer)
	Actor player = Game.GetPlayer()
	String lotName = lot.GetDisplayName()
	Int limit = BuyersLimit()
	Bool open = True
	Int round = 1
	While open && !auctionAborted
		String news = ""
		If handRaised
			handRaised = False
			; A buyer may have bid since the hand went up, past what the player can pay.
			If currentPrice + BidStep > player.GetItemCount(Game.GetForm(GoldID))
				Debug.Notification(Phrase("bidTooMuch", "You do not have that much gold."))
			Else
				currentPrice += BidStep
				currentLeader = player
				news = player.GetDisplayName() + " has raised the bid to " + currentPrice + " gold. "
				ShowBidStatus()
				SayBid(player, lot, currentPrice)
			EndIf
		EndIf
		Int nextBid = currentPrice + Utility.RandomInt(1, 5) * BidUnit
		; An exit's own buyer has the last word among the buyers, however high the player goes before.
		Bool lastWordTaken = designatedBuyer && currentLeader == designatedBuyer && nextBid + MaxRaise > limit
		If nextBid <= limit && !lastWordTaken
			Actor bidder = designatedBuyer
			If !designatedBuyer || currentLeader == designatedBuyer || nextBid + MaxRaise <= limit
				bidder = PickBidder(currentLeader)
			EndIf
			Narrate(news + bidder.GetDisplayName() + " raises a hand from the buyers' seats and bids " + nextBid + " gold for " + lotName + ".", bidder, auctioneer)
			currentLeader = bidder
			currentPrice = nextBid
			ShowBidStatus()
			If round == 2
				Narrate(lotName + ", still bound to the cross, hears the buyers bid on " + Objective(lot) + " and reacts in character.", lot, bidder)
			EndIf
			round += 1
		ElseIf currentLeader == player
			open = False
		Else
			Debug.Notification(Phrase("bidLastCall", "Last call!"))
			Float startedAt = Utility.GetCurrentRealTime()
			While !handRaised && !auctionAborted && Utility.GetCurrentRealTime() - startedAt < LastCallSeconds
				Utility.Wait(0.25)
			EndWhile
			open = handRaised
		EndIf
	EndWhile
	biddingOpen = False
	UnregisterForAllKeys()
	If !currentLeader   ; a low price scale, and the player stayed out
		currentLeader = designatedBuyer
		If !currentLeader
			currentLeader = PickBidder(None)
		EndIf
	EndIf
EndFunction

; The player's half of the sale: they pay for what they won, and get their share if they brought the lot.
Function SettleGuestSale(Actor buyer, Int price)
	Actor player = Game.GetPlayer()
	Form gold = Game.GetForm(GoldID)
	If buyer == player
		player.RemoveItem(gold, price, True)
	ElseIf consigned
		player.AddItem(gold, (price * SellerSharePercent) / 100, True)
	EndIf
EndFunction

Bool Function AllSold()
	Int i = firstCaptive
	While i < captiveCount
		If !isSold[i]
			Return False
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction

; Every lot has gone: those another buyer won leave on their own, those the player won are theirs.
Function CloseGuestAuction()
	UnregisterForUpdateGameTime()
	Actor player = Game.GetPlayer()
	SetAuctionState(StateFreed)
	SetActionsBlocked(False)
	Ref(CageDoorID).Lock(False)
	ObjectReference soldMarker = None
	String soldEvent = ""
	If chosenExit != ""
		soldMarker = ExitMarker(chosenExit)
		soldEvent = JsonUtil.GetStringValue(chosenExit, "event")
		JsonUtil.Unload(chosenExit, False)
	EndIf
	StorageUtil.FormListClear(None, SoldCaptivesKey)
	StorageUtil.FormListClear(None, BoughtCaptivesKey)
	Actor lastBuyer = None
	Int soldTotal = 0
	Int boughtTotal = 0
	Int i = 1
	While i < captiveCount
		Actor follower = captives[i]
		ReleaseFollower(i)
		If soldTo[i] == player
			RejoinParty(follower)
			StorageUtil.FormListAdd(None, BoughtCaptivesKey, follower)
			boughtTotal += soldFor[i]
		Else
			StorageUtil.FormListAdd(None, SoldCaptivesKey, follower)
			soldTotal += soldFor[i]
			lastBuyer = soldTo[i]
			LeaveParty(follower)
			If soldMarker
				follower.MoveTo(soldMarker, CageOffsetX(i) * ArrivalSpread, CageOffsetY(i) * ArrivalSpread, 0.0)
			Else
				HoldForBuyback(follower, soldFor[i])
			EndIf
		EndIf
		i += 1
	EndWhile
	If soldMarker && soldEvent != "" && lastBuyer
		SendExitEvent(soldEvent, lastBuyer, soldTotal)
	EndIf
	Int bought = StorageUtil.FormListCount(None, BoughtCaptivesKey)
	If bought > 0
		ChooseExit(ExitForFollowersBought)
	Else
		chosenExit = ""
	EndIf
	If chosenExit != "" && ExitMarker(chosenExit)
		LeaveWithBought(bought, boughtTotal)
		Return
	EndIf
	i = 0
	While i < bought
		(StorageUtil.FormListGet(None, BoughtCaptivesKey, i) as Actor).MoveTo(player)
		i += 1
	EndWhile
	Debug.Notification(Phrase("guestClosed", "The auction is over."))
	If !IsInHall(player)
		ResetHall()
	EndIf
EndFunction

; As when the player is sold: all in the fade, and an exit may do what it wants before it answers.
Function LeaveWithBought(Int bought, Int total)
	Actor player = Game.GetPlayer()
	ObjectReference marker = ExitMarker(chosenExit)
	String exitEvent = JsonUtil.GetStringValue(chosenExit, "event")
	JsonUtil.Unload(chosenExit, False)
	FadeOut()
	player.MoveTo(marker)
	Int i = 0
	While i < bought
		(StorageUtil.FormListGet(None, BoughtCaptivesKey, i) as Actor).MoveTo(marker, CageOffsetX(i + 1) * ArrivalSpread, CageOffsetY(i + 1) * ArrivalSpread, 0.0)
		i += 1
	EndWhile
	Utility.Wait(1.0)
	ResetHall()
	TellExitAndWait(exitEvent, player, total)
	FadeIn()
EndFunction

Function LeaveParty(Actor follower)
	follower.SetPlayerTeammate(False)
	follower.RemoveFromFaction(Game.GetForm(CurrentFollowerFactionID) as Faction)
	follower.RemoveFromFaction(Game.GetForm(CurrentHirelingFactionID) as Faction)
EndFunction

Function RejoinParty(Actor follower)
	follower.SetActorValue(WaitingValue, 0.0)
	follower.AddToFaction(Game.GetForm(CurrentFollowerFactionID) as Faction)
	follower.SetPlayerTeammate(True)
EndFunction

Function HoldForBuyback(Actor follower, Int price)
	ActorUtil.AddPackageOverride(follower, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package, 100)
	follower.MoveTo(Ref(HoldingMarkerID))
	follower.EvaluatePackage()
	StorageUtil.FormListAdd(None, BuybackListKey, follower)
	StorageUtil.IntListAdd(None, BuybackPriceKey, (price * BuybackMarkupPercent) / 100)
	UpdateBuybackCount()
EndFunction

Function UpdateBuybackCount()
	(Own(BuybackGlobalID) as GlobalVariable).SetValue(StorageUtil.FormListCount(None, BuybackListKey))
EndFunction

Function BuyBack()
	Int count = StorageUtil.FormListCount(None, BuybackListKey)
	If count == 0 || count > 126
		Return
	EndIf
	String[] entries = Utility.CreateStringArray(count + 1)
	Int i = 0
	While i < count
		entries[i] = (StorageUtil.FormListGet(None, BuybackListKey, i) as Actor).GetDisplayName() + " (" + StorageUtil.IntListGet(None, BuybackPriceKey, i) + ")"
		i += 1
	EndWhile
	entries[count] = Phrase("lotNotYet", "Not yet")
	Int pick = PickFromList(entries, count + 1)
	If pick < 0 || pick >= count
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Form gold = Game.GetForm(GoldID)
	Int price = StorageUtil.IntListGet(None, BuybackPriceKey, pick)
	If player.GetItemCount(gold) < price
		Debug.Notification(Phrase("bidTooMuch", "You do not have that much gold."))
		Return
	EndIf
	player.RemoveItem(gold, price, True)
	Actor follower = StorageUtil.FormListGet(None, BuybackListKey, pick) as Actor
	StorageUtil.FormListRemoveAt(None, BuybackListKey, pick)
	StorageUtil.IntListRemoveAt(None, BuybackPriceKey, pick)
	UpdateBuybackCount()
	ActorUtil.RemovePackageOverride(follower, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package)
	RejoinParty(follower)
	follower.MoveTo(player)
	follower.EvaluatePackage()
EndFunction

; The player never came: the followers are sold without them. Not while they are in the hall.
Event OnUpdateGameTime()
	If !playerIsGuest || !IsHoldingCaptives()
		Return
	EndIf
	If busy || IsInHall(Game.GetPlayer())
		RegisterForSingleUpdateGameTime(24.0)
		Return
	EndIf
	busy = True
	SellTheRest()
	Debug.Notification(Phrase("soldOffScreen", "You came too late: your followers have been sold."))
	CloseGuestAuction()
	busy = False
EndEvent

; A guest who draws steel ends the auction: the stage is left, everyone is freed, the buyers run.
Function GuestBrawl()
	auctionAborted = True
	Float startedAt = Utility.GetCurrentRealTime()
	While busy && Utility.GetCurrentRealTime() - startedAt < SpeechTimeoutSeconds
		Utility.Wait(0.25)
	EndWhile
	busy = True
	UnregisterForUpdateGameTime()
	Actor player = Game.GetPlayer()
	SetAuctionState(StateFreed)
	SetActionsBlocked(False)
	Ref(CageDoorID).Lock(False)
	If currentLot
		TakeOffStage(currentLot)
	EndIf
	Int i = 1
	While i < captiveCount
		ReleaseFollower(i)
		RejoinParty(captives[i])
		captives[i].MoveTo(player, 60.0 * i, 0.0, 0.0)
		i += 1
	EndWhile
	i = 0
	While i < BuyerCount
		Actor buyer = Ref(BuyerID + i) as Actor
		If !buyer.IsDead() && !buyer.IsDisabled()
			buyer.StartCombat(player)
		EndIf
		i += 1
	EndWhile
	If designatedBuyer
		designatedBuyer.StartCombat(player)
	EndIf
	Debug.Notification(Phrase("brawl", "The auction breaks up in panic."))
	auctionAborted = False
	busy = False
EndFunction

; ---------------------------------------------------------------------------------------------
; The end: an exit mod
; ---------------------------------------------------------------------------------------------

; One exit of a kind, fixed in the MCM or by weight; none leaves it to the liberators or the holding room.
; Weight is the odds: each usable exit replaces the one held so far with the chance of its share of
; the total. A fixed exit that has gone falls back on the others, by weight.
Function ChooseExit(String kind)
	chosenExit = ""
	String fixedId = ""
	If JsonUtil.GetIntValue(SettingsFile, "fixed_" + kind) == 1
		fixedId = JsonUtil.GetStringValue(SettingsFile, "fixedId_" + kind)
	EndIf
	String[] files = ExitFiles()
	Bool fixedFound = False
	Int total = 0
	Int i = 0
	While i < files.Length && i < MaxExits && !fixedFound
		String file = ExitPath(files[i])
		String problem = ExitProblem(file)
		If problem != ""
			Debug.Trace("skyrimnet_SlaveAuction: exit " + file + " left out: " + problem)
		ElseIf !IsExitOff(file) && ExitKind(file) == kind
			If fixedId != "" && JsonUtil.GetStringValue(file, "id") == fixedId
				chosenExit = file
				fixedFound = True
			Else
				Int weight = ExitWeight(file)
				If weight > 0
					total += weight
					If Utility.RandomInt(1, total) <= weight
						chosenExit = file
					EndIf
				EndIf
			EndIf
		EndIf
		JsonUtil.Unload(file, False)
		i += 1
	EndWhile
	Debug.Trace("skyrimnet_SlaveAuction: " + files.Length + " exit files, chose \"" + chosenExit + "\" for " + kind)
EndFunction

; Lady Livia keeps the seat unless the chosen exit names its buyer. An exit may have taken last time's
; buyer away or even killed them; they only come back here, not when the hall is cleared.
Function SetUpTwelfthSeat()
	designatedBuyer = None
	Actor livia = Ref(BuyerID + TwelfthSeatBuyer) as Actor
	Actor[] designated = new Actor[2]
	designated[0] = Ref(DesignatedBuyerID) as Actor
	designated[1] = Ref(DesignatedBuyerID + 1) as Actor
	Int i = 0
	While i < designated.Length
		designated[i].Disable()
		If designated[i].IsDead()
			designated[i].Resurrect()
		EndIf
		designated[i].MoveTo(designated[i].GetLinkedRef())
		i += 1
	EndWhile
	String buyerName = ""
	If chosenExit != ""
		buyerName = JsonUtil.GetStringValue(chosenExit, "buyer_name")
	EndIf
	If buyerName == ""
		livia.Enable()
		livia.EvaluatePackage()
		Return
	EndIf
	livia.Disable()
	designatedBuyer = designated[(JsonUtil.GetIntValue(chosenExit, "buyer_female") == 1) as Int]
	designatedBuyer.SetDisplayName(buyerName, True)
	StorageUtil.SetStringValue(designatedBuyer, BuyerRoleKey, JsonUtil.GetStringValue(chosenExit, "buyer_role"))
	designatedBuyer.Enable()
	designatedBuyer.EvaluatePackage()
	JsonUtil.Unload(chosenExit, False)
EndFunction

String Function ExitKind(String file)
	Return JsonUtil.GetStringValue(file, "for", ExitForPlayerSold)
EndFunction

String[] Function ExitFiles()
	Return MiscUtil.FilesInFolder(ExitsFolder, ".json")
EndFunction

String Function ExitPath(String fileName)
	Return ExitsJsonPath + fileName
EndFunction

; Why this definition cannot be used, or "" when it can.
String Function ExitProblem(String file)
	If !JsonUtil.Load(file) || !JsonUtil.IsGood(file)
		Return "JSON error: " + JsonUtil.GetErrors(file)
	EndIf
	Int version = JsonUtil.GetIntValue(file, "api_version")
	If version < 1 || version > ExitApiVersion
		Return "unsupported api_version " + version
	EndIf
	String kind = ExitKind(file)
	If kind != ExitForPlayerSold && kind != ExitForFollowersSold && kind != ExitForFollowersBought
		Return "unknown for: " + kind
	EndIf
	If JsonUtil.GetStringValue(file, "id") == ""
		Return "no id"
	EndIf
	If JsonUtil.GetStringValue(file, "name") == ""
		Return "no name"
	EndIf
	If !ExitMarker(file)
		Return "no marker " + JsonUtil.GetStringValue(file, "marker") + " in " + JsonUtil.GetStringValue(file, "plugin")
	EndIf
	Return ""
EndFunction

Bool Function IsExitOff(String file)
	Return JsonUtil.GetIntValue(SettingsFile, "off_" + JsonUtil.GetStringValue(file, "id")) == 1
EndFunction

Function SetExitOff(String file, Bool off)
	JsonUtil.SetIntValue(SettingsFile, "off_" + JsonUtil.GetStringValue(file, "id"), off as Int)
	JsonUtil.Save(SettingsFile)
EndFunction

; The weight its author suggests; the player's from the MCM goes first.
Int Function ExitOwnWeight(String file)
	Return JsonUtil.GetIntValue(file, "weight", DefaultExitWeight)
EndFunction

Int Function ExitWeight(String file)
	Return JsonUtil.GetIntValue(SettingsFile, "weight_" + JsonUtil.GetStringValue(file, "id"), ExitOwnWeight(file))
EndFunction

Function SetExitWeight(String file, Int weight)
	JsonUtil.SetIntValue(SettingsFile, "weight_" + JsonUtil.GetStringValue(file, "id"), weight)
	JsonUtil.Save(SettingsFile)
EndFunction

ObjectReference Function ExitMarker(String file)
	Return Game.GetFormFromFile(HexToInt(JsonUtil.GetStringValue(file, "marker")), JsonUtil.GetStringValue(file, "plugin")) as ObjectReference
EndFunction

; "0x804" or "804". Anything else gives 0, which names no form.
Int Function HexToInt(String hex)
	Int i = 0
	If StringUtil.Substring(hex, 0, 2) == "0x"   ; Papyrus compares without case
		i = 2
	EndIf
	Int value = 0
	While i < StringUtil.GetLength(hex)
		String digit = StringUtil.GetNthChar(hex, i)
		Int found = StringUtil.Find("0123456789ABCDEF", digit)
		If found < 0
			found = StringUtil.Find("0123456789abcdef", digit)
		EndIf
		If found < 0
			Return 0
		EndIf
		value = value * 16 + found
		i += 1
	EndWhile
	Return value
EndFunction

; All in the fade: everyone is moved, unbound and given their things back, then the exit is told.
; An exit that wants them bound or stripped does it again before it answers.
Function LeaveForExit()
	Actor player = Game.GetPlayer()
	Actor buyer = playerBuyer
	Int price = soldFor[0]
	String exitEvent = JsonUtil.GetStringValue(chosenExit, "event")
	ObjectReference marker = ExitMarker(chosenExit)
	JsonUtil.Unload(chosenExit, False)
	FadeOut()
	SetAuctionState(StateFreed)
	ReleasePose(player)
	player.MoveTo(marker)
	Int i = 1
	While i < captiveCount
		TakeOffStage(captives[i])
		captives[i].MoveTo(marker, CageOffsetX(i) * ArrivalSpread, CageOffsetY(i) * ArrivalSpread, 0.0)
		i += 1
	EndWhile
	Utility.Wait(1.0)
	ReleaseCaptives()
	Ref(PlayerChestID).RemoveAllItems(player, False, True)
	ResetHall()   ; before the event: the exit may move the buyer to its own cell
	TellExitAndWait(exitEvent, buyer, price)
	FadeIn()
	busy = False
EndFunction

Function SendExitEvent(String exitEvent, Actor buyer, Int price)
	Int handle = ModEvent.Create(exitEvent)
	If handle
		ModEvent.PushForm(handle, buyer)
		ModEvent.PushInt(handle, price)
		ModEvent.PushString(handle, captureReason)
		ModEvent.Send(handle)
	EndIf
EndFunction

; An exit with an event says when the fade may lift. An exit without one has nothing to prepare.
Function TellExitAndWait(String exitEvent, Actor buyer, Int price)
	If exitEvent == ""
		Return
	EndIf
	exitAcked = False
	SendExitEvent(exitEvent, buyer, price)
	Float startedAt = Utility.GetCurrentRealTime()
	While !exitAcked && Utility.GetCurrentRealTime() - startedAt < ExitAckTimeoutSeconds
		Utility.Wait(0.25)
	EndWhile
	If !exitAcked
		Debug.Trace("skyrimnet_SlaveAuction: no answer to " + exitEvent)
		Debug.Notification(Phrase("exitNoAnswer", "The exit mod did not answer."))
	EndIf
EndFunction

Event OnExitAck(String eventName, String strArg, Float numArg, Form sender)
	exitAcked = True
EndEvent

; ---------------------------------------------------------------------------------------------
; The end: the liberators at the hall door
; ---------------------------------------------------------------------------------------------

; Called once the player has been sold.
Function EndAuction()
	Actor player = Game.GetPlayer()
	ObjectReference exitArea = Ref(ExitAreaMarkerID)
	FadeOut()
	HoldAuctioneerAtPost(Ref(AuctioneerID) as Actor)
	ReleasePose(player)
	Int i = 0
	While i < captiveCount
		If i > 0
			TakeOffStage(captives[i])
		EndIf
		captives[i].MoveTo(exitArea, 0.0, 90.0 * i - 180.0 * (i % 2), 0.0)
		i += 1
	EndWhile
	playerBuyer.MoveTo(Ref(BuyerExitMarkerID))
	playerBuyer.SetDontMove(True)
	Actor[] liberators = Liberators()
	ObjectReference liberatorMarker = Ref(LiberatorMarkerID)
	Form sword = Game.GetFormFromFile(IronSwordID, "Skyrim.esm")
	i = 0
	While i < liberators.Length
		liberators[i].Enable()
		liberators[i].MoveTo(liberatorMarker, 70.0 * i, -40.0 * i, 0.0)
		If liberators[i].GetItemCount(sword) == 0
			liberators[i].AddItem(sword)
		EndIf
		liberators[i].EquipItem(sword)
		i += 1
	EndWhile
	Utility.Wait(1.0)
	FadeIn()
	Utility.Wait(FadeInSeconds)
	; Free to walk once the screen is back; to fight only once FreeCaptives has run.
	Game.EnablePlayerControls(True, False)

	SkyrimNetApi.DirectNarration("Masked liberators burst in through the locked door from the reception room and fall upon " + playerBuyer.GetDisplayName() \
		+ ", the slaver who has just bought " + player.GetDisplayName() + " and was leading " + Possessive(player) + " new property out.", liberators[0], playerBuyer)
	playerBuyer.SetDontMove(False)
	i = 0
	While i < liberators.Length
		liberators[i].StartCombat(playerBuyer)
		i += 1
	EndWhile
	PanicBuyers(liberators)
	Float startedAt = Utility.GetCurrentRealTime()
	While !playerBuyer.IsDead() && Utility.GetCurrentRealTime() - startedAt < RescueTimeoutSeconds
		Utility.Wait(0.5)
	EndWhile
	If !playerBuyer.IsDead()
		playerBuyer.Kill(liberators[0])
	EndIf
	i = 0
	While i < liberators.Length
		liberators[i].StopCombat()
		i += 1
	EndWhile

	FreeCaptives()
	Narrate(playerBuyer.GetDisplayName() + " lies dead. The leader of the liberators turns to " + player.GetDisplayName() \
		+ " and the other captives, tells them they are free, that their belongings are in the chest by the door, and urges them to get out of this place through the reception room and up the stairs before more slavers come.", liberators[0], player)
	busy = False
EndFunction

; The buyers are cowards (their records say so): in combat they run, with the hall door to run to.
Function PanicBuyers(Actor[] liberators)
	Int i = 0
	While i < BuyerCount
		Actor buyer = Ref(BuyerID + i) as Actor
		If buyer != playerBuyer && !buyer.IsDead()
			buyer.StartCombat(liberators[i % liberators.Length])
		EndIf
		i += 1
	EndWhile
EndFunction

Function FreeCaptives()
	ReleaseCaptives()
	ObjectReference chest = Ref(PlayerChestID)
	chest.Lock(False)
	ObjectReference hallDoor = Ref(HallDoorID)
	hallDoor.Lock(False)
	SetAuctionState(StateFreed)
	Debug.Notification(Phrase("freed", "You are free. Your belongings are in the chest by the door."))
EndFunction

; Everything the auction holds them with; the player's things stay in the chest.
Function ReleaseCaptives()
	Faction captiveFaction = Own(CaptiveFactionID) as Faction
	Package doNothing = Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package
	Int i = 0
	While i < captiveCount
		UnbindArms(captives[i])
		i += 1
	EndWhile
	Game.EnablePlayerControls()
	SetActionsBlocked(False)
	i = 0
	While i < leftBehind.Length && leftBehind[i]
		ActorUtil.RemovePackageOverride(leftBehind[i], doNothing)
		leftBehind[i].EvaluatePackage()
		i += 1
	EndWhile
	i = 1
	While i < captiveCount
		ReleaseFollower(i)
		i += 1
	EndWhile
	Game.GetPlayer().RemoveFromFaction(captiveFaction)
	Game.EnableFastTravel(True)
EndFunction

Function ReleaseFollower(Int i)
	Actor follower = captives[i]
	UnbindArms(follower)
	ChestFor(i).RemoveAllItems(follower, False, True)
	If savedOutfits[i]
		follower.SetOutfit(savedOutfits[i])
	EndIf
	ActorUtil.RemovePackageOverride(follower, Game.GetFormFromFile(DoNothingID, "Skyrim.esm") as Package)
	follower.RemoveFromFaction(Own(CaptiveFactionID) as Faction)
	follower.EvaluatePackage()
EndFunction

; The door's cell has been left, by the door or any other way (coc, a teleport).
Function HallLeft()
	If !busy && AuctionState() == StateFreed
		ResetHall()
	EndIf
EndFunction

Bool Function IsHoldingCaptives()
	Int current = AuctionState()
	Return current == StateCaged || current == StateOnStage
EndFunction

; Back to the hall's normal night: the liberators gone, the buyers back on their chairs.
Function ResetHall()
	(Ref(AuctioneerID) as Actor).SetDontMove(False)
	Actor[] liberators = Liberators()
	Int i = 0
	While i < liberators.Length
		liberators[i].Disable()
		i += 1
	EndWhile
	playerBuyer = None
	i = 0
	While i < BuyerCount
		Actor buyer = Ref(BuyerID + i) as Actor
		If buyer.IsDead()
			buyer.Resurrect()
		EndIf
		buyer.StopCombat()
		buyer.SetDontMove(False)
		buyer.MoveTo(buyer.GetLinkedRef())
		buyer.EvaluatePackage()
		i += 1
	EndWhile
	If restraint
		restraint.Disable()
		restraint.Delete()
		restraint = None
	EndIf
	Ref(HallDoorID).SetOpen(False)
	Ref(HallDoorID).Lock(True)
	Ref(HallDoorID).SetLockLevel(255)
	ObjectReference chest = Ref(PlayerChestID)
	; Whatever the player did not come back for is theirs; the chest is about to be locked.
	chest.RemoveAllItems(Game.GetPlayer(), False, True)
	chest.Lock(True)
	chest.SetLockLevel(255)
	captives = new Actor[11]
	captiveCount = 0
	currentLot = None
	SetAuctionState(StateIdle)
EndFunction

Actor[] Function Liberators()
	Actor[] liberators = new Actor[3]
	Int i = 0
	While i < LiberatorCount
		liberators[i] = Ref(LiberatorID + i) as Actor
		i += 1
	EndWhile
	Return liberators
EndFunction

; ---------------------------------------------------------------------------------------------
; Helpers
; ---------------------------------------------------------------------------------------------

; The speaker says something about content in SkyrimNet, and the script waits until it is said.
Function Narrate(String content, Actor speaker, Actor listener)
	If auctionAborted
		Return
	EndIf
	WaitForQuiet()
	narrationSpeaker = speaker
	speakerStarted = False
	speakerPlaying = False
	speakerLines = 0
	lastLineEnd = 0.0
	SkyrimNetApi.DirectNarration(content, speaker, listener)
	WaitForSpeech()
EndFunction

; SkyrimNet's own replies (the auctioneer answering a bid) would otherwise be taken for the line
; asked for, and a directed line that waits behind one expires unsaid. The line playing may finish.
Function WaitForQuiet()
	SkyrimNetApi.PurgeDialogue(True)
	Float startedAt = Utility.GetCurrentRealTime()
	While audioPlaying && Utility.GetCurrentRealTime() - startedAt < QuietTimeoutSeconds
		Utility.Wait(0.25)
	EndWhile
EndFunction

; Follows this speaker's own audio: the line generated for a narration starts seconds after it is
; sent, so silence alone does not mean it was said. Gives up when the speaker never starts, and
; when a line stalls: a sentence that the voice service never delivers keeps the queue full and the
; subtitle up until it times out, and the next narration's purge clears both.
Function WaitForSpeech()
	Float startedAt = Utility.GetCurrentRealTime()
	While Utility.GetCurrentRealTime() - startedAt < SpeechTimeoutSeconds && !auctionAborted
		If !speakerStarted && Utility.GetCurrentRealTime() - startedAt >= SpeechStartTimeoutSeconds
			Debug.Trace("[skyrimnet_SlaveAuction] " + narrationSpeaker.GetDisplayName() + " did not start talking, going on")
			Return
		EndIf
		If speakerLines > 0 && !speakerPlaying
			Float silent = Utility.GetCurrentRealTime() - lastLineEnd
			If silent >= SpeechGapSeconds && SkyrimNetApi.GetSpeechQueueSize() == 0
				Return
			ElseIf silent >= SpeechStallSeconds
				Debug.Trace("[skyrimnet_SlaveAuction] " + narrationSpeaker.GetDisplayName() + "'s line stalled, going on")
				Return
			EndIf
		EndIf
		Utility.Wait(0.25)
	EndWhile
EndFunction

Event OnSkyrimNetAudioStarted(String eventName, String strArg, Float numArg, Form sender)
	audioPlaying = True
	If narrationSpeaker && sender == narrationSpeaker
		speakerStarted = True
		speakerPlaying = True
	EndIf
EndEvent

Event OnSkyrimNetAudioEnded(String eventName, String strArg, Float numArg, Form sender)
	audioPlaying = False
	If narrationSpeaker && sender == narrationSpeaker && speakerStarted
		; The time first: this call lets the waiting thread run, and it must not see a counted line
		; that has no end time yet.
		lastLineEnd = Utility.GetCurrentRealTime()
		speakerPlaying = False
		speakerLines += 1
	EndIf
EndEvent

Function FadeOut()
	(Game.GetFormFromFile(FadeToBlackImodID, "Skyrim.esm") as ImageSpaceModifier).Apply()
	Utility.Wait(1.5)
	(Game.GetFormFromFile(FadeToBlackImodID, "Skyrim.esm") as ImageSpaceModifier).PopTo(Game.GetFormFromFile(FadeToBlackHoldImodID, "Skyrim.esm") as ImageSpaceModifier)
EndFunction

Function FadeIn()
	(Game.GetFormFromFile(FadeToBlackHoldImodID, "Skyrim.esm") as ImageSpaceModifier).PopTo(Game.GetFormFromFile(FadeToBlackBackImodID, "Skyrim.esm") as ImageSpaceModifier)
EndFunction

Int Function AuctionState()
	Return (Own(StateGlobalID) as GlobalVariable).GetValueInt()
EndFunction

Function SetAuctionState(Int value)
	(Own(StateGlobalID) as GlobalVariable).SetValueInt(value)
EndFunction

Form Function Own(Int id)
	Return Game.GetFormFromFile(id, PluginName)
EndFunction

ObjectReference Function Ref(Int id)
	Return Game.GetFormFromFile(id, PluginName) as ObjectReference
EndFunction

String Function Phrase(String phraseKey, String fallback)
	Return JsonUtil.GetStringValue(StringsFile, phraseKey, fallback)
EndFunction
