Scriptname skyrimnet_SlaveAuction_EntrySackTIF extends TopicInfo Hidden
{Fragment of the receptionist's topic: the player hands over the people they have tied up. On the AI's list of lines it may not fire.}

Function Fragment_0(ObjectReference akSpeakerRef)
	(GetOwningQuest() as skyrimnet_SlaveAuction_EntrySack).HandOver()
EndFunction
