Scriptname skyrimnet_SlaveAuctionTIF_Drink extends TopicInfo Hidden
{Fragment of the receptionist's topic (skyrimnet_SlaveAuction_DrinkTopic): the player drinks the
rare drink she offers, and wakes up in the cage.}

Function Fragment_0(ObjectReference akSpeakerRef)
	(GetOwningQuest() as skyrimnet_SlaveAuction).Request("capture")
EndFunction
