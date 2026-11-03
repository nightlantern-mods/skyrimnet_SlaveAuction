Scriptname skyrimnet_SlaveAuctionTIF_Choose extends TopicInfo Hidden
{Fragment of the cage guard's topic (skyrimnet_SlaveAuction_ChooseTopic): the player names who
goes on the stage next.}

Function Fragment_0(ObjectReference akSpeakerRef)
	(GetOwningQuest() as skyrimnet_SlaveAuction).Request("choose")
EndFunction
