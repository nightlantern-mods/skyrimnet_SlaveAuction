Scriptname skyrimnet_SlaveAuction_ExitMineRock extends ObjectReference
{On the rock faces: each click is one piece of the quota.}

Int Property QuestID = 0x801 AutoReadOnly

Event OnActivate(ObjectReference actionRef)
	If actionRef == Game.GetPlayer()
		(Game.GetFormFromFile(QuestID, "skyrimnet_SlaveAuction_ExitMine.esp") as skyrimnet_SlaveAuction_ExitMine).Dig()
	EndIf
EndEvent
