Scriptname skyrimnet_SlaveAuction_ExitMineBoss extends ReferenceAlias
{On the overseer's alias: killing the overseer is the other way out of both exits.}

Event OnDeath(Actor killer)
	(GetOwningQuest() as skyrimnet_SlaveAuction_ExitMine).OverseerDied()
EndEvent
