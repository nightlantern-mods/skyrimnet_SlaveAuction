Scriptname skyrimnet_SlaveAuction_MCM extends SKI_ConfigBase
{The settings menu: how each kind of exit is chosen, each exit's switch and weight, the player's
bidding, and the definitions that could not be read. Everything is kept in one file shared by all
saves, and the list is read from the exits folder each time the menu opens, so only what this
player has installed shows.}

; SkyUI pages hold at most 128 options; a row of the exit list takes two.
Int Property RowsPerPage = 50 AutoReadOnly
Int Property MinWeight = 1 AutoReadOnly
Int Property MaxWeight = 100 AutoReadOnly
Int Property KindCount = 3 AutoReadOnly

skyrimnet_SlaveAuction auction
Bool exitsRead

String[] kinds
String[] kindHeaders
String[] kindInfos

String[] exitFiles
String[] exitIds
String[] exitNames
Int[] exitKinds
Int exitCount
String[] problemFiles
String[] problemTexts
Int problemCount
String[] menuIds
String[] menuNames
Int menuCount

Int[] oMode
Int[] oFixed
Int oLiberators
Int oBidKey
Int oBidShift
Int oGuestDays
Int oPriceScale
Int oPrevPage
Int oNextPage
Int[] oExitOn
Int[] oExitWeight
Int listPage = 0

Int Function GetVersion()
	Return 1
EndFunction

Event OnConfigInit()
	ModName = "$SA_ModName"
	Pages = new String[3]
	Pages[0] = "$SA_PageSettings"
	Pages[1] = "$SA_PageExits"
	Pages[2] = "$SA_PageProblems"
EndEvent

; After several loads in one session this script can reach SkyUI without having started: no name, no
; pages, none of the arrays SkyUI's dialogs write to. Opening a menu then was a Papyrus error, and on
; such a script the game crashes while it logs the error's stack. So it starts here if it has not.
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

Event OnConfigClose()
	JsonUtil.Save(auction.SettingsFile)
	exitsRead = False
EndEvent

; Here and not in OnConfigOpen: SkyUI had reset the first page before that event had run.
Function PrepareOnce()
	If !exitsRead
		exitsRead = True
		auction = Game.GetFormFromFile(0x801, "skyrimnet_SlaveAuction.esp") as skyrimnet_SlaveAuction
		kinds = new String[3]
		kinds[0] = auction.ExitForPlayerSold
		kinds[1] = auction.ExitForFollowersSold
		kinds[2] = auction.ExitForFollowersBought
		kindHeaders = new String[3]
		kindHeaders[0] = "$SA_KindPlayerSold"
		kindHeaders[1] = "$SA_KindFollowersSold"
		kindHeaders[2] = "$SA_KindFollowersBought"
		kindInfos = new String[3]
		kindInfos[0] = "$SA_InfoPlayerSold"
		kindInfos[1] = "$SA_InfoFollowersSold"
		kindInfos[2] = "$SA_InfoFollowersBought"
		oMode = Utility.CreateIntArray(KindCount, -1)
		oFixed = Utility.CreateIntArray(KindCount, -1)
		oExitOn = Utility.CreateIntArray(RowsPerPage, -1)
		oExitWeight = Utility.CreateIntArray(RowsPerPage, -1)
		ReadExits()
	EndIf
EndFunction

Function ReadExits()
	String[] files = auction.ExitFiles()
	Int size = files.Length
	If size > auction.MaxExits
		size = auction.MaxExits
	EndIf
	exitFiles = Utility.CreateStringArray(size)
	exitIds = Utility.CreateStringArray(size)
	exitNames = Utility.CreateStringArray(size)
	exitKinds = Utility.CreateIntArray(size)
	problemFiles = Utility.CreateStringArray(size)
	problemTexts = Utility.CreateStringArray(size)
	exitCount = 0
	problemCount = 0
	Int i = 0
	While i < size
		String file = auction.ExitPath(files[i])
		String problem = auction.ExitProblem(file)
		If problem == ""
			exitFiles[exitCount] = file
			exitIds[exitCount] = JsonUtil.GetStringValue(file, "id")
			exitNames[exitCount] = JsonUtil.GetStringValue(file, "name")
			exitKinds[exitCount] = kinds.Find(auction.ExitKind(file))
			exitCount += 1
		Else
			problemFiles[problemCount] = files[i]
			problemTexts[problemCount] = problem
			problemCount += 1
		EndIf
		JsonUtil.Unload(file, False)
		i += 1
	EndWhile
	If listPage * RowsPerPage >= exitCount
		listPage = 0
	EndIf
EndFunction

Event OnPageReset(String page)
	PrepareOnce()
	If page == "$SA_PageExits"
		ResetExitsPage()
	ElseIf page == "$SA_PageProblems"
		ResetProblemsPage()
	Else
		ResetSettingsPage()
	EndIf
EndEvent

Function ResetSettingsPage()
	SetCursorFillMode(TOP_TO_BOTTOM)
	Int kind = 0
	While kind < KindCount
		AddHeaderOption(kindHeaders[kind])
		If IsFixed(kind)
			oMode[kind] = AddMenuOption("$SA_Mode", "$SA_ModeFixed")
			oFixed[kind] = AddMenuOption("$SA_FixedExit", FixedExitName(kind))
		Else
			oMode[kind] = AddMenuOption("$SA_Mode", "$SA_ModeRandom")
			oFixed[kind] = AddMenuOption("$SA_FixedExit", FixedExitName(kind), OPTION_FLAG_DISABLED)
		EndIf
		AddTextOption("$SA_ExitCount", EnabledExitCount(kind), OPTION_FLAG_DISABLED)
		kind += 1
	EndWhile
	SetCursorPosition(1)
	AddHeaderOption("$SA_HeaderBidding")
	oBidKey = AddKeyMapOption("$SA_BidKey", JsonUtil.GetIntValue(auction.SettingsFile, "bidKey", auction.DefaultBidKey))
	oBidShift = AddToggleOption("$SA_BidShift", JsonUtil.GetIntValue(auction.SettingsFile, "bidShift") == 1)
	oGuestDays = AddSliderOption("$SA_GuestDays", JsonUtil.GetIntValue(auction.SettingsFile, "guestDays", auction.DefaultGuestDays))
	oPriceScale = AddSliderOption("$SA_PriceScale", JsonUtil.GetIntValue(auction.SettingsFile, "priceScale", auction.DefaultPriceScale), "{0}%")
	AddEmptyOption()
	AddHeaderOption("$SA_HeaderStatus")
	If EnabledExitCount(0) > 0
		oLiberators = AddTextOption("$SA_Liberators", "$SA_LiberatorsUnused", OPTION_FLAG_DISABLED)
	Else
		oLiberators = AddTextOption("$SA_Liberators", "$SA_LiberatorsUsed", OPTION_FLAG_DISABLED)
	EndIf
	AddTextOption("$SA_ProblemCount", problemCount, OPTION_FLAG_DISABLED)
EndFunction

Function ResetExitsPage()
	oExitOn = Utility.CreateIntArray(RowsPerPage, -1)
	oExitWeight = Utility.CreateIntArray(RowsPerPage, -1)
	oPrevPage = -1
	oNextPage = -1
	SetCursorFillMode(LEFT_TO_RIGHT)
	If exitCount == 0
		AddTextOption("$SA_NoExits", "", OPTION_FLAG_DISABLED)
		Return
	EndIf
	Int row = 0
	Int i = listPage * RowsPerPage
	While i < exitCount && row < RowsPerPage
		oExitOn[row] = AddToggleOption(exitNames[i], !auction.IsExitOff(exitFiles[i]))
		oExitWeight[row] = AddSliderOption("$SA_Weight", auction.ExitWeight(exitFiles[i]))
		row += 1
		i += 1
	EndWhile
	If listPage > 0
		oPrevPage = AddTextOption("$SA_PrevPage", "")
	Else
		AddEmptyOption()
	EndIf
	If i < exitCount
		oNextPage = AddTextOption("$SA_NextPage", "")
	EndIf
EndFunction

Function ResetProblemsPage()
	SetCursorFillMode(TOP_TO_BOTTOM)
	If problemCount == 0
		AddTextOption("$SA_NoProblems", "", OPTION_FLAG_DISABLED)
		Return
	EndIf
	Int i = 0
	While i < problemCount && i < RowsPerPage * 2
		AddTextOption(problemFiles[i], problemTexts[i], OPTION_FLAG_DISABLED)
		i += 1
	EndWhile
EndFunction

Bool Function IsFixed(Int kind)
	Return JsonUtil.GetIntValue(auction.SettingsFile, "fixed_" + kinds[kind]) == 1
EndFunction

String Function FixedId(Int kind)
	Return JsonUtil.GetStringValue(auction.SettingsFile, "fixedId_" + kinds[kind])
EndFunction

String Function FixedExitName(Int kind)
	String fixedId = FixedId(kind)
	If fixedId == ""
		Return "$SA_NoneChosen"
	EndIf
	Int i = exitIds.Find(fixedId)
	If i >= 0 && i < exitCount && exitKinds[i] == kind && !auction.IsExitOff(exitFiles[i])
		Return exitNames[i]
	EndIf
	Return "$SA_FixedMissing"
EndFunction

Int Function EnabledExitCount(Int kind)
	Int count = 0
	Int i = 0
	While i < exitCount
		If exitKinds[i] == kind && !auction.IsExitOff(exitFiles[i])
			count += 1
		EndIf
		i += 1
	EndWhile
	Return count
EndFunction

Event OnOptionSelect(Int option)
	If option == oBidShift
		Bool shift = JsonUtil.GetIntValue(auction.SettingsFile, "bidShift") != 1
		SaveInt("bidShift", shift as Int)
		SetToggleOptionValue(option, shift)
		Return
	EndIf
	If option == oPrevPage
		listPage -= 1
		ForcePageReset()
		Return
	ElseIf option == oNextPage
		listPage += 1
		ForcePageReset()
		Return
	EndIf
	Int row = oExitOn.Find(option)
	If row >= 0
		String file = exitFiles[listPage * RowsPerPage + row]
		Bool off = !auction.IsExitOff(file)
		auction.SetExitOff(file, off)
		SetToggleOptionValue(option, !off)
	EndIf
EndEvent

Event OnOptionSliderOpen(Int option)
	If option == oGuestDays
		SetSliderDialogStartValue(JsonUtil.GetIntValue(auction.SettingsFile, "guestDays", auction.DefaultGuestDays))
		SetSliderDialogDefaultValue(auction.DefaultGuestDays)
		SetSliderDialogRange(1, 30)
		SetSliderDialogInterval(1)
		Return
	ElseIf option == oPriceScale
		SetSliderDialogStartValue(JsonUtil.GetIntValue(auction.SettingsFile, "priceScale", auction.DefaultPriceScale))
		SetSliderDialogDefaultValue(auction.DefaultPriceScale)
		SetSliderDialogRange(50, 1000)
		SetSliderDialogInterval(10)
		Return
	EndIf
	Int row = oExitWeight.Find(option)
	If row >= 0
		String file = exitFiles[listPage * RowsPerPage + row]
		SetSliderDialogStartValue(auction.ExitWeight(file))
		SetSliderDialogDefaultValue(auction.ExitOwnWeight(file))
		SetSliderDialogRange(MinWeight, MaxWeight)
		SetSliderDialogInterval(1)
	EndIf
EndEvent

Event OnOptionSliderAccept(Int option, Float value)
	If option == oGuestDays
		SaveInt("guestDays", value as Int)
		SetSliderOptionValue(option, value)
		Return
	ElseIf option == oPriceScale
		SaveInt("priceScale", value as Int)
		SetSliderOptionValue(option, value, "{0}%")
		Return
	EndIf
	Int row = oExitWeight.Find(option)
	If row >= 0
		auction.SetExitWeight(exitFiles[listPage * RowsPerPage + row], value as Int)
		SetSliderOptionValue(option, value)
	EndIf
EndEvent

Event OnOptionKeyMapChange(Int option, Int keyCode, String conflictControl, String conflictName)
	If option == oBidKey
		SaveInt("bidKey", keyCode)
		SetKeyMapOptionValue(option, keyCode)
		auction.RefreshBidKey()
	EndIf
EndEvent

Function SaveInt(String settingKey, Int value)
	JsonUtil.SetIntValue(auction.SettingsFile, settingKey, value)
	JsonUtil.Save(auction.SettingsFile)
EndFunction

Event OnOptionMenuOpen(Int option)
	Int kind = oMode.Find(option)
	If kind >= 0
		String[] modes = new String[2]
		modes[0] = "$SA_ModeRandom"
		modes[1] = "$SA_ModeFixed"
		SetMenuDialogOptions(modes)
		SetMenuDialogStartIndex(IsFixed(kind) as Int)
		SetMenuDialogDefaultIndex(0)
		Return
	EndIf
	kind = oFixed.Find(option)
	If kind >= 0
		BuildFixedMenu(kind)
		SetMenuDialogOptions(menuNames)
		SetMenuDialogStartIndex(menuIds.Find(FixedId(kind)))
		SetMenuDialogDefaultIndex(0)
	EndIf
EndEvent

; The exits that can be fixed: those of this kind that are switched on.
Function BuildFixedMenu(Int kind)
	menuCount = EnabledExitCount(kind)
	menuIds = Utility.CreateStringArray(menuCount)
	menuNames = Utility.CreateStringArray(menuCount)
	Int n = 0
	Int i = 0
	While i < exitCount
		If exitKinds[i] == kind && !auction.IsExitOff(exitFiles[i])
			menuIds[n] = exitIds[i]
			menuNames[n] = exitNames[i]
			n += 1
		EndIf
		i += 1
	EndWhile
EndFunction

Event OnOptionMenuAccept(Int option, Int index)
	Int kind = oMode.Find(option)
	If kind >= 0
		SaveInt("fixed_" + kinds[kind], index)
		ForcePageReset()
		Return
	EndIf
	kind = oFixed.Find(option)
	If kind >= 0 && index >= 0 && index < menuCount
		JsonUtil.SetStringValue(auction.SettingsFile, "fixedId_" + kinds[kind], menuIds[index])
		JsonUtil.Save(auction.SettingsFile)
		SetMenuOptionValue(option, menuNames[index])
	EndIf
EndEvent

Event OnOptionHighlight(Int option)
	If oMode.Find(option) >= 0
		SetInfoText("$SA_InfoMode")
	ElseIf oFixed.Find(option) >= 0
		SetInfoText("$SA_InfoFixed")
	ElseIf option == oLiberators
		SetInfoText("$SA_InfoLiberators")
	ElseIf option == oBidKey
		SetInfoText("$SA_InfoBidKey")
	ElseIf option == oBidShift
		SetInfoText("$SA_InfoBidShift")
	ElseIf option == oGuestDays
		SetInfoText("$SA_InfoGuestDays")
	ElseIf option == oPriceScale
		SetInfoText("$SA_InfoPriceScale")
	ElseIf oExitOn.Find(option) >= 0
		SetInfoText(kindInfos[exitKinds[listPage * RowsPerPage + oExitOn.Find(option)]])
	ElseIf oExitWeight.Find(option) >= 0
		SetInfoText("$SA_InfoWeight")
	EndIf
EndEvent
