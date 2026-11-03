Scriptname skyrimnet_SlaveAuctionDoor extends ReferenceAlias
{The door at the top of the reception room's stairs. It leads outside by itself; this only tells the
quest that the player has left the hall, whichever way they went, and keeps the door in its place.}

Event OnLoad()
	(GetOwningQuest() as skyrimnet_SlaveAuction).HallLoaded()
EndEvent

Event OnCellDetach()
	(GetOwningQuest() as skyrimnet_SlaveAuction).HallLeft()
EndEvent
