Scriptname skyrimnet_SlaveAuction_EntrySackLoad extends ReferenceAlias
{On the player: mod events are registered again on every load.}

Event OnPlayerLoadGame()
	(GetOwningQuest() as skyrimnet_SlaveAuction_EntrySack).Setup()
EndEvent
