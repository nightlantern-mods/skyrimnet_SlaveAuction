Scriptname IOULedger_Load extends ReferenceAlias
{On the player: mod events are registered again on every load, and the ledger is checked.}

Event OnPlayerLoadGame()
	(GetOwningQuest() as IOULedger).Setup()
EndEvent
