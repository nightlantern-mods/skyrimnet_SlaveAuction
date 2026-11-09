Scriptname skyrimnet_SlaveAuction_EntrySackDesk extends ReferenceAlias
{On the receptionist: when the hall loads, start looking for people to hand over.}

Event OnLoad()
	(GetOwningQuest() as skyrimnet_SlaveAuction_EntrySack).Watch()
EndEvent

Event OnCellAttach()
	(GetOwningQuest() as skyrimnet_SlaveAuction_EntrySack).Watch()
EndEvent
