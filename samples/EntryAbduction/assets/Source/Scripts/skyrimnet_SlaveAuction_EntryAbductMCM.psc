Scriptname skyrimnet_SlaveAuction_EntryAbductMCM extends SKI_ConfigBase
{The settings of the abduction entry: on or off, and the chance. They are kept in one file shared by all saves.}

Int oEnabled
Int oChance

Int Function GetVersion()
	Return 1
EndFunction

Event OnConfigInit()
	ModName = "$SAEA_ModName"
EndEvent

; After several loads in one session this script can reach SkyUI without having started: no name and
; none of the arrays SkyUI's dialogs write to. So it starts here if it has not.
Function MakeSureStarted()
	If ModName == ""
		OnGameReload()
	EndIf
	If ModName == ""
		OnConfigInit()
	EndIf
EndFunction

Event OnConfigManagerReady(String eventName, String strArg, Float numArg, Form sender)
	MakeSureStarted()
	parent.OnConfigManagerReady(eventName, strArg, numArg, sender)
EndEvent

Function OpenConfig()
	MakeSureStarted()
	parent.OpenConfig()
EndFunction

skyrimnet_SlaveAuction_EntryAbduction Function Entry()
	Return GetAlias(0) as skyrimnet_SlaveAuction_EntryAbduction
EndFunction

Event OnPageReset(String page)
	skyrimnet_SlaveAuction_EntryAbduction abduction = Entry()
	SetCursorFillMode(TOP_TO_BOTTOM)
	oEnabled = AddToggleOption("$SAEA_Enabled", JsonUtil.GetIntValue(abduction.SettingsFile, "enabled", 1) == 1)
	oChance = AddSliderOption("$SAEA_Chance", JsonUtil.GetIntValue(abduction.SettingsFile, "chance", abduction.DefaultChance), "{0}%")
EndEvent

Event OnOptionSelect(Int option)
	If option == oEnabled
		Bool enabledNow = JsonUtil.GetIntValue(Entry().SettingsFile, "enabled", 1) != 1
		Save("enabled", enabledNow as Int)
		SetToggleOptionValue(option, enabledNow)
	EndIf
EndEvent

Event OnOptionSliderOpen(Int option)
	If option == oChance
		skyrimnet_SlaveAuction_EntryAbduction abduction = Entry()
		SetSliderDialogStartValue(JsonUtil.GetIntValue(abduction.SettingsFile, "chance", abduction.DefaultChance))
		SetSliderDialogDefaultValue(abduction.DefaultChance)
		SetSliderDialogRange(1, 100)
		SetSliderDialogInterval(1)
	EndIf
EndEvent

Event OnOptionSliderAccept(Int option, Float value)
	If option == oChance
		Save("chance", value as Int)
		SetSliderOptionValue(option, value, "{0}%")
	EndIf
EndEvent

Function Save(String settingKey, Int value)
	String file = Entry().SettingsFile
	JsonUtil.SetIntValue(file, settingKey, value)
	JsonUtil.Save(file)
EndFunction

Event OnOptionHighlight(Int option)
	If option == oEnabled
		SetInfoText("$SAEA_InfoEnabled")
	ElseIf option == oChance
		SetInfoText("$SAEA_InfoChance")
	EndIf
EndEvent
