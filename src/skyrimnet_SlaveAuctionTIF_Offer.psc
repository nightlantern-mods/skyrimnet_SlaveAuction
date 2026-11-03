Scriptname skyrimnet_SlaveAuctionTIF_Offer extends TopicInfo Hidden
{Fragment of the receptionist's topic (skyrimnet_SlaveAuction_OfferTopic): the player keeps away from the drink and has their followers drink it.}

Function Fragment_0(ObjectReference akSpeakerRef)
	(GetOwningQuest() as skyrimnet_SlaveAuction).Request("offer")
EndFunction
