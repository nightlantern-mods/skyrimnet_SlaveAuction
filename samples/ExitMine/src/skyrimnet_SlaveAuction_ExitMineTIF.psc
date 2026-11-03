Scriptname skyrimnet_SlaveAuction_ExitMineTIF extends TopicInfo Hidden
{Fragment of the overseer's topic: the player buys a follower back. On the AI's list of lines it may not fire.}

Function Fragment_0(ObjectReference akSpeakerRef)
	(GetOwningQuest() as skyrimnet_SlaveAuction_ExitMine).BuyBack()
EndFunction
