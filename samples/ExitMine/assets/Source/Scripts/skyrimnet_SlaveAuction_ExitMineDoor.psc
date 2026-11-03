Scriptname skyrimnet_SlaveAuction_ExitMineDoor extends ObjectReference
{On the mine's inner door: tells the quest that the player has come in.}

Int Property QuestID = 0x801 AutoReadOnly

Event OnLoad()
	(Game.GetFormFromFile(QuestID, "skyrimnet_SlaveAuction_ExitMine.esp") as skyrimnet_SlaveAuction_ExitMine).PlayerArrived()
EndEvent
