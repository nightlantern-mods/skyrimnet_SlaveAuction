Scriptname IOULedger extends Quest
{IOU Ledger: debts any mod can give an NPC. A mod puts an NPC in debt, or pays it off, by sending an
event; nothing has to name this plugin. A debtor carries a bond, the amount is kept on the NPC, and one
journal objective puts a map marker on each of up to ten debtors. It comes with SkyrimNet Slave Auction, and
needs nothing of it.

    Int handle = ModEvent.Create("IOULedger_AddDebt")   ; (Form debtor, Int amount, String creditor)
    Int handle = ModEvent.Create("IOULedger_PayDebt")   ; (Form debtor, Int amount): 0 or less clears it

A bond in the debtor's inventory is the debt: take it away and the debt is gone.}

String Property AddDebtEvent = "IOULedger_AddDebt" AutoReadOnly
String Property PayDebtEvent = "IOULedger_PayDebt" AutoReadOnly
String Property ChangedEvent = "IOULedger_DebtChanged" AutoReadOnly   ; sent: (Form debtor, Int total)
String Property DebtKey = "IOULedger_Debt" AutoReadOnly   ; Int on the debtor
String Property CreditorKey = "IOULedger_Creditor" AutoReadOnly   ; String on the debtor, the last creditor named
String Property DebtorsKey = "IOULedger_Debtors" AutoReadOnly   ; form list on None
String Property LedgerKey = "IOULedger_Running" AutoReadOnly   ; Int on None: 1 while the ledger runs
String Property OwnPlugin = "IOULedger.esp" AutoReadOnly
Int Property BondID = 0x802 AutoReadOnly
Int Property Slots = 10 AutoReadOnly
Float Property CheckHours = 1.0 AutoReadOnly

Bool changing   ; one change of the ledger at a time: events and the hourly check can come together

Event OnInit()
	Setup()
EndEvent

; Also on every load, from the player's alias.
Function Setup()
	RegisterForModEvent(AddDebtEvent, "OnAddDebt")
	RegisterForModEvent(PayDebtEvent, "OnPayDebt")
	StorageUtil.SetIntValue(None, LedgerKey, 1)
	Lock()
	TidySlots()
	Reconcile()
	changing = False
	RegisterForSingleUpdateGameTime(CheckHours)
EndFunction

Event OnUpdateGameTime()
	Lock()
	Reconcile()
	changing = False
	RegisterForSingleUpdateGameTime(CheckHours)
EndEvent

; Nothing latent between the check and the set, so no other thread can come in between.
Function Lock()
	While changing
		Utility.Wait(0.1)
	EndWhile
	changing = True
EndFunction

Event OnAddDebt(Form debtor, Int amount, String creditor)
	Actor npc = debtor as Actor
	If !npc || npc == Game.GetPlayer() || npc.IsDead() || amount <= 0
		Return
	EndIf
	Lock()
	Int total = 0
	If npc.GetItemCount(Bond()) > 0
		total = StorageUtil.GetIntValue(npc, DebtKey)
	Else
		npc.AddItem(Bond(), 1, True)
	EndIf
	total += amount
	StorageUtil.SetIntValue(npc, DebtKey, total)
	If creditor != ""
		StorageUtil.SetStringValue(npc, CreditorKey, creditor)
	EndIf
	StorageUtil.FormListAdd(None, DebtorsKey, npc, False)
	Debug.Trace("IOULedger: " + npc.GetDisplayName() + " owes " + total + ", creditor " + creditor)
	String owedTo = ""
	If creditor != ""
		owedTo = " to " + creditor
	EndIf
	; The AI knows of it from now on, without anyone reacting at once.
	SkyrimNetApi.RegisterPersistentEvent(npc.GetDisplayName() + " now owes " + total + " gold" + owedTo + ", and carries a signed bond for it until it is paid.", npc, None)
	Track(npc, total)
	changing = False
	SendChanged(npc, total)
EndEvent

Event OnPayDebt(Form debtor, Int amount)
	Actor npc = debtor as Actor
	If !npc || npc.GetItemCount(Bond()) == 0
		Return
	EndIf
	Lock()
	Int total = StorageUtil.GetIntValue(npc, DebtKey) - amount
	If amount <= 0 || total <= 0
		ClearDebt(npc)
		changing = False
		Return
	EndIf
	StorageUtil.SetIntValue(npc, DebtKey, total)
	Debug.Trace("IOULedger: " + npc.GetDisplayName() + " paid " + amount + ", owes " + total)
	Track(npc, total)
	changing = False
	SendChanged(npc, total)
EndEvent

Function ClearDebt(Actor npc)
	Int bonds = npc.GetItemCount(Bond())
	If bonds > 0
		npc.RemoveItem(Bond(), bonds, True)
	EndIf
	ForgetDebt(npc)
EndFunction

; Off the ledger: the bond is already gone, or the debtor is.
Function ForgetDebt(Actor npc)
	Debug.Trace("IOULedger: " + npc.GetDisplayName() + " owes nothing now")
	StorageUtil.UnsetIntValue(npc, DebtKey)
	StorageUtil.UnsetStringValue(npc, CreditorKey)
	StorageUtil.FormListRemove(None, DebtorsKey, npc, True)
	Untrack(npc)
	SendChanged(npc, 0)
EndFunction

; Everyone on the ledger who has lost their bond, or died, owes nothing any more.
Function Reconcile()
	Form bond = Bond()
	Int i = StorageUtil.FormListCount(None, DebtorsKey) - 1
	While i >= 0
		Actor npc = StorageUtil.FormListGet(None, DebtorsKey, i) as Actor
		If !npc
			StorageUtil.FormListRemoveAt(None, DebtorsKey, i)
		ElseIf npc.IsDead() || npc.GetItemCount(bond) == 0
			ForgetDebt(npc)
		EndIf
		i -= 1
	EndWhile
	FillFreeSlots()
EndFunction

; Anyone in two slots keeps the first.
Function TidySlots()
	Int i = 0
	While i < Slots
		Actor npc = Debtor(i).GetActorReference()
		If npc && SlotOf(npc) < i
			Debug.Trace("IOULedger: " + npc.GetDisplayName() + " was in two slots, clearing slot " + i)
			Debtor(i).Clear()
		EndIf
		i += 1
	EndWhile
	ShowObjective()
EndFunction

; The journal: one objective, with a map marker on the debtor of each filled slot. No names, as NFF does.
Function Track(Actor npc, Int total)
	If SlotOf(npc) >= 0
		Return
	EndIf
	Int slot = FreeSlot()
	If slot < 0
		Return   ; on the ledger, and marked once a slot is free
	EndIf
	Debtor(slot).ForceRefTo(npc)
	ShowObjective()
EndFunction

; Shown while anyone is marked, and hidden when nobody is.
Function ShowObjective()
	Bool anyone = False
	Int i = 0
	While i < Slots && !anyone
		anyone = Debtor(i).GetActorReference() != None
		i += 1
	EndWhile
	If anyone && !IsObjectiveDisplayed(0)
		SetObjectiveDisplayed(0, True)
	ElseIf !anyone && IsObjectiveDisplayed(0)
		SetObjectiveDisplayed(0, False)
	EndIf
EndFunction

Function Untrack(Actor npc)
	Int slot = SlotOf(npc)
	If slot < 0
		Return
	EndIf
	Debtor(slot).Clear()
	FillFreeSlots()
	ShowObjective()
EndFunction

Function FillFreeSlots()
	Int i = 0
	Int count = StorageUtil.FormListCount(None, DebtorsKey)
	While i < count && FreeSlot() >= 0
		Actor npc = StorageUtil.FormListGet(None, DebtorsKey, i) as Actor
		If npc && SlotOf(npc) < 0
			Track(npc, StorageUtil.GetIntValue(npc, DebtKey))
		EndIf
		i += 1
	EndWhile
EndFunction

Int Function SlotOf(Actor npc)
	Int i = 0
	While i < Slots
		If Debtor(i).GetActorReference() == npc
			Return i
		EndIf
		i += 1
	EndWhile
	Return -1
EndFunction

Int Function FreeSlot()
	Int i = 0
	While i < Slots
		If !Debtor(i).GetActorReference()
			Return i
		EndIf
		i += 1
	EndWhile
	Return -1
EndFunction

Function SendChanged(Actor npc, Int total)
	Int handle = ModEvent.Create(ChangedEvent)
	If handle
		ModEvent.PushForm(handle, npc)
		ModEvent.PushInt(handle, total)
		ModEvent.Send(handle)
	EndIf
EndFunction

ReferenceAlias Function Debtor(Int slot)
	Return GetAlias(slot + 1) as ReferenceAlias
EndFunction

Form Function Bond()
	Return Game.GetFormFromFile(BondID, OwnPlugin)
EndFunction
