Scriptname skyrimnet_SlaveAuction_EntryDefeat extends ReferenceAlias
{Sample entry mod for SkyrimNet Slave Auction: beaten by humanoid enemies, the player and the followers
nearby are sold at the auction. It uses only the public events. On the player's alias; aliases 1 to 10
of its quest are optional and essential, and hold the followers while the player is fighting.}

String Property SettingsFile = "../skyrimnet_SlaveAuction_EntryDefeat/settings.json" AutoReadOnly
Float Property HealthLimit = 0.05 AutoReadOnly
Float Property ScanRadius = 4096.0 AutoReadOnly
Float Property CombatPollSeconds = 0.5 AutoReadOnly
Float Property IdlePollSeconds = 2.0 AutoReadOnly
Float Property LineStartSeconds = 10.0 AutoReadOnly      ; no line by then: on without it
Float Property LineMostSeconds = 25.0 AutoReadOnly       ; one that started may finish, within reason
Float Property LineGapSeconds = 1.0 AutoReadOnly
Float Property AnswerSeconds = 5.0 AutoReadOnly          ; without the auction mod nobody answers
Float Property FadeSeconds = 3.0 AutoReadOnly
Float Property RetrySeconds = 30.0 AutoReadOnly
Int Property FollowerAliases = 10 AutoReadOnly
Int Property ActorTypeNPCID = 0x013794 AutoReadOnly
Int Property FalmerRaceID = 0x0131F4 AutoReadOnly        ; humanoid, but the game calls them creatures
Int Property LeftShift = 42 AutoReadOnly
Int Property RightShift = 54 AutoReadOnly

Bool enabled
Int giveUpKey = -1
Bool giveUpShift
Bool protecting
Bool surrendering
Float resumeAt
Actor lastAttacker
Actor[] calmed
Float[] calmedAggression
Actor approaching
Actor lineSpeaker
Bool lineStarted
Bool linePlaying
Int lineCount
Float lineEnd
String captureAnswer

Event OnInit()
	Start()
EndEvent

Event OnPlayerLoadGame()
	Start()
EndEvent

Function Start()
	RegisterForModEvent("skyrimnet_SlaveAuction_CaptureResult", "OnCaptureResult")
	RegisterForModEvent("SkyrimNet_AudioStarted", "OnSkyrimNetAudioStarted")
	RegisterForModEvent("SkyrimNet_AudioEnded", "OnSkyrimNetAudioEnded")
	RegisterForModEvent("skyrimnet_SlaveAuction_EntryDefeat_Approach", "OnApproach")
	resumeAt = 0.0   ; real time starts over with the game
	SettingsChanged()
	RegisterForSingleUpdate(IdlePollSeconds)
EndFunction

; Called by the menu too.
Function SettingsChanged()
	enabled = JsonUtil.GetIntValue(SettingsFile, "enabled", 1) == 1
	giveUpShift = JsonUtil.GetIntValue(SettingsFile, "giveUpShift") == 1
	If giveUpKey >= 0
		UnregisterForKey(giveUpKey)
	EndIf
	giveUpKey = JsonUtil.GetIntValue(SettingsFile, "giveUpKey", -1)
	If giveUpKey >= 0
		RegisterForKey(giveUpKey)
	EndIf
EndFunction

; ---------------------------------------------------------------------------------------------
; When the player is defeated
; ---------------------------------------------------------------------------------------------
Event OnUpdate()
	If surrendering
		RegisterForSingleUpdate(IdlePollSeconds)
		Return
	EndIf
	Actor player = GetReference() as Actor
	If enabled && player.IsInCombat() && Utility.GetCurrentRealTime() >= resumeAt
		Protect(player, True)
		If player.GetActorValuePercentage("Health") < HealthLimit
			TrySurrender()
		EndIf
		RegisterForSingleUpdate(CombatPollSeconds)
	Else
		Protect(player, False)
		RegisterForSingleUpdate(IdlePollSeconds)
	EndIf
EndEvent

Event OnHit(ObjectReference aggressor, Form source, Projectile bolt, Bool power, Bool sneak, Bool bash, Bool blocked)
	If !protecting
		Return
	EndIf
	Actor player = GetReference() as Actor
	If IsHumanoidEnemy(aggressor as Actor, player)
		lastAttacker = aggressor as Actor
	EndIf
	If player.GetActorValuePercentage("Health") < HealthLimit
		TrySurrender()
	EndIf
EndEvent

; Essential only stops the death. With no humanoid enemy about, this was not a defeat: the player dies as usual.
Event OnEnterBleedout()
	If surrendering || !protecting
		Return
	EndIf
	Actor player = GetReference() as Actor
	If FindSpeaker(player)
		TrySurrender()
	Else
		Protect(player, False)
		player.Kill()
	EndIf
EndEvent

Event OnKeyDown(Int keyCode)
	If keyCode != giveUpKey || !enabled || Utility.IsInMenuMode()
		Return
	EndIf
	If giveUpShift && !Input.IsKeyPressed(LeftShift) && !Input.IsKeyPressed(RightShift)
		Return
	EndIf
	TrySurrender()
EndEvent

Function TrySurrender()
	; Set at once: calling anything first lets a second hit or update in, and it would surrender too.
	If surrendering
		Return
	EndIf
	surrendering = True
	If Utility.GetCurrentRealTime() < resumeAt
		surrendering = False
		Return
	EndIf
	Actor player = GetReference() as Actor
	Actor speaker = FindSpeaker(player)
	If speaker
		Protect(player, True)
		Surrender(player, speaker)
	EndIf
	surrendering = False
EndFunction

Bool Function IsHumanoidEnemy(Actor npc, Actor player)
	If !npc || npc == player || npc.IsDead() || !npc.IsInCombat() || !npc.IsHostileToActor(player)
		Return False
	EndIf
	Return npc.HasKeyword(Game.GetFormFromFile(ActorTypeNPCID, "Skyrim.esm") as Keyword) || npc.GetRace() == Game.GetFormFromFile(FalmerRaceID, "Skyrim.esm") as Race
EndFunction

; The one who last struck the player if they are still at it, or else the nearest.
Actor Function FindSpeaker(Actor player)
	If IsHumanoidEnemy(lastAttacker, player) && lastAttacker.GetDistance(player) <= ScanRadius
		Return lastAttacker
	EndIf
	Actor nearest = None
	Float nearestDistance = ScanRadius
	Actor[] nearby = MiscUtil.ScanCellNPCs(player, ScanRadius)
	Int i = 0
	While i < nearby.Length
		If IsHumanoidEnemy(nearby[i], player) && nearby[i].GetDistance(player) <= nearestDistance
			nearest = nearby[i]
			nearestDistance = nearest.GetDistance(player)
		EndIf
		i += 1
	EndWhile
	Return nearest
EndFunction

; ---------------------------------------------------------------------------------------------
; Keeping them alive: only during a fight, so that a fall on a quiet road still kills
; ---------------------------------------------------------------------------------------------
Function Protect(Actor player, Bool on)
	If on == protecting
		Return
	EndIf
	protecting = on
	player.GetActorBase().SetEssential(on)
	Quest owner = GetOwningQuest()
	Int i = 0
	While i < FollowerAliases
		(owner.GetAlias(i + 1) as ReferenceAlias).Clear()
		i += 1
	EndWhile
	If !on
		Return
	EndIf
	Actor[] nearby = MiscUtil.ScanCellNPCs(player, ScanRadius)
	Int filled = 0
	i = 0
	While i < nearby.Length && filled < FollowerAliases
		If nearby[i] != player && nearby[i].IsPlayerTeammate() && !nearby[i].IsDead()
			(owner.GetAlias(filled + 1) as ReferenceAlias).ForceRefTo(nearby[i])
			filled += 1
		EndIf
		i += 1
	EndWhile
EndFunction

; ---------------------------------------------------------------------------------------------
; The enemy says what will happen, then the auction takes over
; ---------------------------------------------------------------------------------------------
Function Surrender(Actor player, Actor speaker)
	Game.DisablePlayerControls(True, True, False, False, True, True, True, True)
	Calm(player)
	speaker.StopCombat()
	If speaker.GetDistance(player) > 256.0
		approaching = speaker
		GetOwningQuest().SendModEvent("skyrimnet_SlaveAuction_EntryDefeat_Approach")
	EndIf
	String playerName = player.GetDisplayName()
	String speakerName = speaker.GetDisplayName()
	SayLine(player, speaker, speakerName + " has beaten " + playerName + " in battle and stands over them. " + speakerName + " tells " + playerName + " that they will not be killed: they will be sold as a slave at the underground auction.")
	; Enabled before the event: the auction disables what it wants once the captive is bound.
	Game.EnablePlayerControls()
	captureAnswer = ""
	GetOwningQuest().SendModEvent("skyrimnet_SlaveAuction_Capture", "defeated in battle by " + speakerName)
	Float startedAt = Utility.GetCurrentRealTime()
	While captureAnswer == "" && Utility.GetCurrentRealTime() - startedAt < AnswerSeconds
		Utility.Wait(0.25)
	EndWhile
	If captureAnswer == "accepted"
		Utility.Wait(FadeSeconds)   ; the auction brings them round in its fade
	ElseIf player.IsBleedingOut()
		player.ResetHealthAndLimbs()
	Else
		player.RestoreActorValue("Health", player.GetBaseActorValue("Health") * 0.25)
	EndIf
	Uncalm()
	Protect(player, False)
	resumeAt = Utility.GetCurrentRealTime() + RetrySeconds
EndFunction

Event OnApproach(String eventName, String strArg, Float numArg, Form sender)
	Actor walker = approaching
	If walker
		approaching = None
		walker.PathToReference(GetReference(), 1.0)
		walker.EvaluatePackage()
	EndIf
EndEvent

Event OnCaptureResult(String result, String reason, Form requester)
	If requester == GetOwningQuest()
		captureAnswer = result
	EndIf
EndEvent

; An actor of aggression 0 starts no fight, so a stopped fight stays stopped.
Function Calm(Actor player)
	calmed = MiscUtil.ScanCellNPCs(player, ScanRadius)
	If calmed.Length > 0
		calmedAggression = Utility.CreateFloatArray(calmed.Length, -1.0)
	EndIf
	Int i = 0
	While i < calmed.Length
		If calmed[i] != player && (calmed[i].IsInCombat() || calmed[i].IsHostileToActor(player))
			calmedAggression[i] = calmed[i].GetActorValue("Aggression")
			calmed[i].SetActorValue("Aggression", 0.0)
			calmed[i].StopCombat()
		EndIf
		i += 1
	EndWhile
	player.StopCombatAlarm()
EndFunction

Function KeepCalm(Actor player)
	Int i = 0
	While i < calmed.Length
		If calmedAggression[i] >= 0.0 && calmed[i].IsInCombat()
			calmed[i].StopCombat()
		EndIf
		i += 1
	EndWhile
	player.StopCombatAlarm()
EndFunction

Function Uncalm()
	Int i = 0
	While i < calmed.Length
		If calmedAggression[i] >= 0.0
			calmed[i].SetActorValue("Aggression", calmedAggression[i])
		EndIf
		i += 1
	EndWhile
EndFunction

; The AI writes the line and only hears the situation. A directed line behind another mod's goes unsaid,
; hence the purge. Gives up when it does not start, so that nobody stands frozen waiting for it.
Function SayLine(Actor player, Actor speaker, String situation)
	SkyrimNetApi.PurgeDialogue(True)
	lineSpeaker = speaker
	lineStarted = False
	linePlaying = False
	lineCount = 0
	lineEnd = 0.0
	SkyrimNetApi.DirectNarration(situation, speaker, player)
	Float startedAt = Utility.GetCurrentRealTime()
	Int ticks = 0
	Bool waiting = True
	While waiting
		Float elapsed = Utility.GetCurrentRealTime() - startedAt
		If elapsed >= LineMostSeconds || (!lineStarted && elapsed >= LineStartSeconds)
			waiting = False
		ElseIf lineCount > 0 && !linePlaying && Utility.GetCurrentRealTime() - lineEnd >= LineGapSeconds && SkyrimNetApi.GetSpeechQueueSize() == 0
			waiting = False
		Else
			ticks += 1
			If ticks % 4 == 0
				KeepCalm(player)
			EndIf
			Utility.Wait(0.25)
		EndIf
	EndWhile
	lineSpeaker = None
EndFunction

Event OnSkyrimNetAudioStarted(String eventName, String strArg, Float numArg, Form sender)
	If lineSpeaker && sender == lineSpeaker
		lineStarted = True
		linePlaying = True
	EndIf
EndEvent

Event OnSkyrimNetAudioEnded(String eventName, String strArg, Float numArg, Form sender)
	If lineSpeaker && sender == lineSpeaker && lineStarted
		lineEnd = Utility.GetCurrentRealTime()
		linePlaying = False
		lineCount += 1
	EndIf
EndEvent
