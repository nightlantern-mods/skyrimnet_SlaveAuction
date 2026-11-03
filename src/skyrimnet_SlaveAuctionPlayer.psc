Scriptname skyrimnet_SlaveAuctionPlayer extends ReferenceAlias
{Re-registers the auction's mod event after each save load, and watches that the captives stay
bound. The watch runs here because the quest's own updates run the long auction steps.}

Event OnPlayerLoadGame()
	(GetOwningQuest() as skyrimnet_SlaveAuction).Setup()
EndEvent

Function Watch()
	RegisterForSingleUpdate(WatchSeconds)
EndFunction

Event OnUpdate()
	If (GetOwningQuest() as skyrimnet_SlaveAuction).KeepCaptivesBound()
		RegisterForSingleUpdate(WatchSeconds)
	EndIf
EndEvent

Float Property WatchSeconds = 1.0 AutoReadOnly
