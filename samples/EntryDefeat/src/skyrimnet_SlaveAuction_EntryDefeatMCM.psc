Scriptname skyrimnet_SlaveAuction_EntryDefeatMCM extends SKI_ConfigBase
{The settings of the defeat entry: on or off, and the give-up key. They are kept in one file shared by all saves.}

Int oEnabled
Int oGiveUpKey
Int oGiveUpShift

Int Function GetVersion()
	Return 1
EndFunction

Event OnConfigInit()
	ModName = "$SAED_ModName"
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

skyrimnet_SlaveAuction_EntryDefeat Function Entry()
	Return GetAlias(0) as skyrimnet_SlaveAuction_EntryDefeat
EndFunction

Event OnPageReset(String page)
	String file = Entry().SettingsFile
	SetCursorFillMode(TOP_TO_BOTTOM)
	oEnabled = AddToggleOption("$SAED_Enabled", JsonUtil.GetIntValue(file, "enabled", 1) == 1)
	oGiveUpKey = AddKeyMapOption("$SAED_GiveUpKey", JsonUtil.GetIntValue(file, "giveUpKey", -1), OPTION_FLAG_WITH_UNMAP)
	oGiveUpShift = AddToggleOption("$SAED_GiveUpShift", JsonUtil.GetIntValue(file, "giveUpShift") == 1)
EndEvent

Event OnOptionSelect(Int option)
	String file = Entry().SettingsFile
	If option == oEnabled
		Bool enabledNow = JsonUtil.GetIntValue(file, "enabled", 1) != 1
		Save("enabled", enabledNow as Int)
		SetToggleOptionValue(option, enabledNow)
	ElseIf option == oGiveUpShift
		Bool shiftNow = JsonUtil.GetIntValue(file, "giveUpShift") != 1
		Save("giveUpShift", shiftNow as Int)
		SetToggleOptionValue(option, shiftNow)
	EndIf
EndEvent

Event OnOptionKeyMapChange(Int option, Int keyCode, String conflictControl, String conflictName)
	If option == oGiveUpKey
		Save("giveUpKey", keyCode)
		SetKeyMapOptionValue(option, keyCode)
	EndIf
EndEvent

Function Save(String settingKey, Int value)
	String file = Entry().SettingsFile
	JsonUtil.SetIntValue(file, settingKey, value)
	JsonUtil.Save(file)
	Entry().SettingsChanged()
EndFunction

Event OnOptionHighlight(Int option)
	If option == oEnabled
		SetInfoText("$SAED_InfoEnabled")
	ElseIf option == oGiveUpKey
		SetInfoText("$SAED_InfoGiveUpKey")
	ElseIf option == oGiveUpShift
		SetInfoText("$SAED_InfoGiveUpShift")
	EndIf
EndEvent
