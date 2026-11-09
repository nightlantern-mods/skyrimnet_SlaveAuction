Scriptname skyrimnet_SlaveAuction_ExitDebtLoad extends ReferenceAlias
{On the player: mod events are registered again on every load.}

Event OnPlayerLoadGame()
	(GetOwningQuest() as skyrimnet_SlaveAuction_ExitDebt).Setup()
EndEvent
