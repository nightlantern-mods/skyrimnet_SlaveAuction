Scriptname skyrimnet_SlaveAuctionTIF_Buyback extends TopicInfo Hidden
{Fragment of the receptionist's topic (skyrimnet_SlaveAuction_BuybackTopic): the player buys back a follower who was sold.}

Function Fragment_0(ObjectReference akSpeakerRef)
	(GetOwningQuest() as skyrimnet_SlaveAuction).Request("buyback")
EndFunction
