Scriptname skyrimnet_SlaveAuction_EntryAbduction extends ReferenceAlias
{Sample entry mod for SkyrimNet Slave Auction: the player sleeps and, now and then, wakes without the
followers who were nearby. The player stays free and can go after them. It uses only the public events.}

String Property SettingsFile = "../skyrimnet_SlaveAuction_EntryAbduction/settings.json" AutoReadOnly
String Property StringsFile = "../skyrimnet_SlaveAuction_EntryAbduction/strings.json" AutoReadOnly
Int Property DefaultChance = 25 AutoReadOnly
Int Property PlayerHouseID = 0x0FC1A3 AutoReadOnly       ; LocTypePlayerHouse
Int Property InnID = 0x01CB87 AutoReadOnly               ; LocTypeInn
Int Property DungeonID = 0x0130DB AutoReadOnly           ; LocTypeDungeon
Float Property ThoughtDelaySeconds = 12.0 AutoReadOnly   ; the auction's fade comes first, and clears the speech queue

Event OnInit()
	Start()
EndEvent

Event OnPlayerLoadGame()
	Start()
EndEvent

Function Start()
	RegisterForSleep()
	RegisterForModEvent("skyrimnet_SlaveAuction_CaptureResult", "OnCaptureResult")
EndFunction

Event OnSleepStop(Bool interrupted)
	If interrupted || JsonUtil.GetIntValue(SettingsFile, "enabled", 1) != 1
		Return
	EndIf
	If Utility.RandomInt(1, 100) > JsonUtil.GetIntValue(SettingsFile, "chance", DefaultChance)
		Return
	EndIf
	Actor player = GetReference() as Actor
	If !CanBeTakenHere(player)
		Return
	EndIf
	; The number 1.0 asks for the followers alone. With none nearby the answer is no_captives.
	GetOwningQuest().SendModEvent("skyrimnet_SlaveAuction_Capture", "carried off in the night while " + player.GetDisplayName() + " slept", 1.0)
EndEvent

; A home cannot be recognised for sure: one from another mod may have no location at all. So indoors
; only the places known to be unsafe count, inns and dungeons, and any other room is left in peace.
Bool Function CanBeTakenHere(Actor player)
	Location here = player.GetCurrentLocation()
	If here && here.HasKeyword(Game.GetFormFromFile(PlayerHouseID, "Skyrim.esm") as Keyword)
		Return False
	EndIf
	If !player.IsInInterior()
		Return True
	EndIf
	Return here && (here.HasKeyword(Game.GetFormFromFile(InnID, "Skyrim.esm") as Keyword) || here.HasKeyword(Game.GetFormFromFile(DungeonID, "Skyrim.esm") as Keyword))
EndFunction

Event OnCaptureResult(String result, String reason, Form requester)
	If requester != GetOwningQuest() || result != "accepted"
		Return
	EndIf
	Debug.Notification(JsonUtil.GetStringValue(StringsFile, "taken", "While you slept, your followers were taken to the Underground Auction Hall."))
	Utility.Wait(ThoughtDelaySeconds)
	; The AI writes the thought. The event tells it what has happened, and sets off no reactions by itself.
	Actor player = GetReference() as Actor
	SkyrimNetApi.RegisterPersistentEvent(player.GetDisplayName() + " wakes to find that their companions are gone, carried off in the night to the underground auction.", player, player)
	SkyrimNetApi.TriggerPlayerThought()
EndEvent
