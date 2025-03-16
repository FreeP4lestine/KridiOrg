#Requires AutoHotkey v2
#SingleInstance Force

#Include <CreateImageButton>
#Include <Gdip>
#Include <Json>
#Include <Language>
#Include <Eval>

Set := JSON.Load(FileRead('Setting.json'))

pToken := Gdip_Startup()
; RTL ex-style E0x00400000
KO := Gui('Resize MinSize700x400', Set['name'])
KO.MarginX := 10
KO.MarginY := 10
KO.OnEvent('Close', (*) => ExitApp())
KO.OnEvent('ContextMenu', Gui_ContextMenu)
Gui_ContextMenu(GuiObj, GuiCtrlObj, Item, IsRightClick, X, Y) {
    If !IsObject(GuiCtrlObj) {
        Return
    }
    Switch GuiCtrlObj.Hwnd {
        Case EmptyName.Hwnd, NoEmptyName.Hwnd:
            ContextMenu1.Show()
        Case SelectedFolder.Hwnd:
            ContextMenu2.Show()
    }
}
KO.OnEvent('Size', Gui_Size)
Gui_Size(GuiObj, MinMax, Width, Height) {
    ProportionsCalc(Width, Height)
}
KO.BackColor := Set['backColor']
KO.SetFont('s14 Bold', 'Segoe UI')
KO.AddText('cGreen', ISTR.2)
KO.SetFont('s8')
KO.AddText('xm ym+20 cBlue', Set['version'])
Loop 3
    KO.AddText('xm ym+' 34 + A_Index ' 0x10 w824')

KO.SetFont('s9')
Locate := KO.AddButton('xm+538 ym+113 w283 h20', ISTR.3)
Locate.OnEvent('Click', LocateDB)
LocateDB(Ctrl, Info) {
    If !Folder := FileSelect('D')
        Return
    CurrentLocation.Value := Folder
    IniWrite(Folder, A_AppData "\Kridi_Config.ini", 'FolderPath', 'LastSelectedFolder')
    Selections := IniRead(A_AppData "\Kridi_Config.ini", 'FolderPath', 'Selection', '')
    If !Index := IsSelectedFolder(Folder) {
        Selections .= (Selections = '' ? '' : '|') Folder
        IniWrite(Selections, A_AppData "\Kridi_Config.ini", 'FolderPath', 'Selection')
        SelectedFolder.Delete()
        SelectedFolder.Add(StrSplit(Selections, '|'))
    } Else SelectedFolder.Choose(Index)
    WriteHistory('"' Folder '" ' ISTR.58)
}
CreateImageButton(Locate, 0, Set['IB']*)

KO.SetFont('s10')
CurrentLocation := KO.AddEdit('xm+538 ym+248 w283 +Center ReadOnly h20 -E0x200 Background' Set['editBackColor'])

KO.SetFont('s10')
Empty := KO.AddText('xm ym+70 w205 Center Background' Set['editBackColor'], ISTR.4)
NoEmpty := KO.AddText('xm+210 ym+70 w205 Center Background' Set['editBackColor'], ISTR.5)

KO.SetFont('s12')
NoEmptyName := KO.AddListBox('xm ym+90 w205 r8 -E0x200 Border c800000 Background' Set['backColor'])
NoEmptyName.OnEvent('Change', (*) => ShowSelectedKridi())
ShowSelectedKridi(EmptyUnSelect := True) {
    If EmptyUnSelect
        EmptyName.Choose(0)
    If !NoEmptyName.Text || !SelectedFolder.Text {
        Return
    }
    Name := SubStr(NoEmptyName.Text, 4)
    Content := FileRead(SelectedFolder.Text '\' Name '.txt')
    CalculatedKridi.Value := Round(Evaluate(Content) / 1000, 3) ' TND'
}
EmptyName := KO.AddListBox('xm+210 ym+90 w205 r8 -E0x200 cGreen Border Background' Set['backColor'])
EmptyName.OnEvent('Change', (*) => (NoEmptyName.Choose(0), CalculatedKridi.Value := ''))

NewNameT := KO.AddText('xm+210 ym+140 w205 r2 Center Hidden', ISTR.45)
NewNameE := KO.AddEdit('xm+210 ym+140 w205 h27 Center Hidden Background' Set['editBackColor'])
NewNameBtn := KO.AddButton('xm+210 ym+220 w205 h22 Hidden', ISTR.43)
CreateImageButton(NewNameBtn, 0, Set['IB']*)

KO.SetFont('s11')
FullHistoryBtn := KO.AddButton('xm+538 ym+275 w283 h20 Center cBlue', ISTR.18)
FullHistoryBtn.OnEvent('Click', (*) => ShowFullHistory())
CreateImageButton(FullHistoryBtn, 0, Set['IB']*)
SFH := Gui()
SFH.BackColor := 'White'
SFH.MarginX := 10
SFH.MarginY := 10
SFH.SetFont('Bold s10', 'Calibri')
HistoryList := SFH.AddListView('xm ym w834 h416 Background' Set['backColor'], ["#ID", " ", "#" ISTR.83, " ", "#" ISTR.84, " ", "#" ISTR.85])
ShowFullHistory() {
    LoadFullHistory()
    SFH.Show()
}
LoadFullHistory() {
    HObj := FileOpen(A_AppData "\IKAHistory.log", "r")
    HistoryList.Delete()
    While (!HObj.AtEOF) {
        CurrLine := HObj.ReadLine()
        RegExMatch(CurrLine, "(\d+/\d+/\d+)", &Date)
        RegExMatch(CurrLine, "(\d+:\d+:\d+ (A|P)M)", &Time)
        RegExMatch(CurrLine, "_:(.*)$", &Action)
        HistoryList.Add(, "[" A_Index "]", "|", Date[1], "|", Time[1], "|", Action[1])
    }
    HObj.Close()
    Loop HistoryList.GetCount('Col')
        HistoryList.ModifyCol(A_Index, 'AutoHdr')
}

KO.SetFont('s9')
History := KO.AddListView('xm+538 ym+299 w283 r3 VScroll HScroll Grid Background' Set['backColor'], [ISTR.81, ISTR.82])

SelectedFolder := KO.AddListBox('xm+538 ym+136 w283 r6 HScroll Background' Set['backColor'])
SelectedFolder.OnEvent('Change', (*) => LoadDB())
LoadDB() {
    If !SelectedFolder.Text || !DirExist(SelectedFolder.Text)
        Return
    IniWrite(SelectedFolder.Text, A_AppData "\Kridi_Config.ini", "FolderPath", "LastSelectedFolder")
    NoEmptyName.Delete()
    EmptyName.Delete()
    TotalSum := Low := High := 0
    LowName := HighName := ''
    Loop Files, SelectedFolder.Text '\*.txt' {
        If KridiData := FileRead(A_LoopFileFullPath) {
            Try {
                CurrSum := Evaluate(KridiData)
                TotalSum += CurrSum
                If Low = 0 {
                    Low := CurrSum
                    LowName := SubStr(A_LoopFileName, 1, -4)
                }
                If CurrSum && (CurrSum < Low) {
                    Low := CurrSum
                    LowName := SubStr(A_LoopFileName, 1, -4)
                }
                If CurrSum > High {
                    High := CurrSum
                    HighName := SubStr(A_LoopFileName, 1, -4)
                }
                NoEmptyName.Add(['X. ' SubStr(A_LoopFileName, 1, -4)])
            } Catch {
                EmptyName.Add(['✓. ' SubStr(A_LoopFileName, 1, -4)])
            }
        } Else EmptyName.Add(['✓. ' SubStr(A_LoopFileName, 1, -4)])
    }
    TotalKridi.Value := Round(TotalSum / 1000, 3) ' TND'
    Lowest.Value := LowName ': ' Round(Low / 1000, 3) ' TND'
    Highest.Value := HighName ': ' Round(High / 1000, 3) ' TND'
}

KO.SetFont('s12')
CalculatedKridi := KO.AddEdit('xm ym+40 w415 ReadOnly h25 -E0x200 Center cFF0000 Background' Set['backColor'])

Statistic := KO.AddButton('xm+430 ym+70 w93 h40 Disabled', ISTR.86)
CreateImageButton(Statistic, 0, Set['IB']*)
Highest := KO.AddEdit('xm+538 ym+70 w283 ReadOnly h20 Center -E0x200 BackgroundFFFFFF cFF0000')
Lowest := KO.AddEdit('xm+538 ym+90 w283 ReadOnly h20 Center -E0x200 BackgroundFFFFFF cGreen')

RecordKridi := KO.AddButton('xm+430 ym+113 w93 h40', ISTR.79)
CreateImageButton(RecordKridi, 0, Set['IB']*)
RecordKridi.OnEvent('Click', (*) => ShowKridiRecord())
Kridi := Gui(, ISTR.9)
Kridi.MarginX := 10
Kridi.MarginY := 10
Kridi.SetFont('s12 Bold', 'Calibri')
Kridi.BackColor := 'White'
Kridi.AddText(, ISTR.68)
KridiList := Kridi.AddListView('w834 h416 Background' Set['backColor'], ["#" ISTR.69, " ", "#" ISTR.70, " ", "#" ISTR.71, " ", "#" ISTR.72, " ", "#" ISTR.73, " ", "#" ISTR.74, " ", "#" ISTR.75])

ShowKridiRecord() {
    If !(Name := SubStr(NoEmptyName.Text EmptyName.Text, 4)) || !SelectedFolder.Text {
        Return
    }
    KridiList.Delete()
    FileObj := FileOpen(SelectedFolder.Text "\" Name ".Info", "r")
    While !FileObj.AtEOF {
        If !InStr(Line := FileObj.ReadLine(), "Kridi") {
            Continue
        }
        BF := AF := Date := ProdList := "-"
        Try {
            Line := StrSplit(Line, '|')
            Line.RemoveAt(1)
            DayName := Trim(Line.RemoveAt(1), ' []')
            Date := Trim(Line.RemoveAt(1), ' []') ' | '
            Date .= Trim(Line.RemoveAt(1), ' []')
            SelectedName := Trim(Line.RemoveAt(1), ' []')
            BF := Trim(Line.RemoveAt(1), ' []')
            Add := Trim(Line.RemoveAt(1), ' []')
            AF := Trim(Line.RemoveAt(1), ' []')
            AF := StrSplit(AF, ' [ ')
            If AF.Length = 2 {
                ProdList := AF[2]
                Loop Line.Length {
                    ProdList .= ' | ' Trim(Line.RemoveAt(1), ' []')
                }
            }
            AF := AF[1]
        } Catch {
            MsgBox(ISTR.93 ' ' Name '`nIndex: ' A_Index, ISTR.9, 0x30)
            Continue
        }
        KridiList.Add(, Date, , DayName, , SelectedName, , BF, , Add, , AF, , ProdList)
    }
    FileObj.Close()
    Loop KridiList.GetCount('Col')
        KridiList.ModifyCol(A_Index, 'AutoHdr')
    Kridi.Show()
}

RecordPaid := KO.AddButton('xm+430 ym+156 w93 h40', ISTR.80)
CreateImageButton(RecordPaid, 0, Set['IB']*)
RecordPaid.OnEvent('Click', (*) => ShowPaidRecord())
Paid := Gui(, ISTR.12)
Paid.MarginX := 10
Paid.MarginY := 10
Paid.SetFont('s12 Bold', 'Calibri')
Paid.BackColor := 'White'
Paid.AddText(, ISTR.80)
PaidList := Paid.AddListView('w834 h416 Background' Set['backColor'], ["#" ISTR.69, " ", "#" ISTR.70, " ", "#" ISTR.71, " ", "#" ISTR.72, " ", "#" ISTR.73, " ", "#" ISTR.74])
ShowPaidRecord() {
    If !(Name := SubStr(NoEmptyName.Text EmptyName.Text, 4)) || !SelectedFolder.Text {
        Return
    }
    PaidList.Delete()
    FileObj := FileOpen(SelectedFolder.Text "\" Name ".Info", "r")
    While !FileObj.AtEOF {
        If !InStr(Line := FileObj.ReadLine(), "Paid") {
            Continue
        }
        Try {
            Line := StrSplit(Line, '|')
            Line.RemoveAt(1)
            DayName := Trim(Line.RemoveAt(1), ' []')
            Date := Trim(Line.RemoveAt(1), ' []') ' | '
            Date .= Trim(Line.RemoveAt(1), ' []')
            SelectedName := Trim(Line.RemoveAt(1), ' []')
            BF := Trim(Line.RemoveAt(1), ' []')
            Add := Trim(Line.RemoveAt(1), ' []')
            AF := Trim(Line.RemoveAt(1), ' []')
        } Catch {
            MsgBox(ISTR.93 ' ' Name '`nIndex: ' A_Index, ISTR.12, 0x30)
            Continue
        }
        PaidList.Add(, Date, , DayName, , SelectedName, , BF, , Add, , AF)
    }
    FileObj.Close()
    Loop PaidList.GetCount('Col')
        PaidList.ModifyCol(A_Index, 'AutoHdr')
    Paid.Show()
}

x := 430, y := 320
Loop Parse, "0123456789"
{
    w := (A_LoopField = 0) ? 93 : 29
    H := KO.AddButton('xm+' x ' ym+' y ' w' w ' h25', A_LoopField)
    (A_LoopField = 0 || A_LoopField = 3 || A_LoopField = 6 || A_LoopField = 9) ? (x := 430, y -= 28) : x += 32
    CreateImageButton(H, 0, Set['IB']*)
    H.OnEvent('Click', WriteCP)
}
WriteCP(Ctrl, Info) {
    ControlSend('{Text}' Ctrl.Text, ChangePrice)
}

DeleteFromField := KO.AddButton('xm+' x ' ym+' y ' w93 h25', ISTR.19)
CreateImageButton(DeleteFromField, 0, Set['IB']*)
DeleteFromField.OnEvent('Click', (*) => DeleteCP())
DeleteCP() {
    ControlSend('+{Del}', ChangePrice)
}

MainButtonAdd := KO.AddButton('xm ym+325 w205 h25', ISTR.11)
MainButtonAdd.OnEvent('Click', (*) => KridiAdd())
PLC := Gui(, ISTR.90)
PLC.BackColor := 'White'
PLC.SetFont('s12 Bold', 'Calibri')
PLC.MarginX := 10
PLC.MarginY := 10
Search := PLC.AddEdit('w500 -E0x200 Center Background' Set['backColor'])
Search.OnEvent('Change', (*) => UpdateSearchList())
UpdateSearchList() {
    PopulateSearchList(Search.Value)
}
SearchThumb := PLC.AddPicture('xm+436 w64 h64')
SearchList := PLC.AddListView('xm w500 Checked r15', [ISTR.71, ISTR.91])
SearchList.OnEvent('ItemCheck', ItemCheck)
SearchList.OnEvent('Click', LookForThumbnail)
ItemCheck(GuiCtrlObj, Item, Checked) {
    If !Item
        Return
    If Item = 1 {
        ToggleAllSelect()
        Return
    }
}
ToggleAllSelect() {
    Static Tog := 0
    If Tog := !Tog {
        SearchList.Modify(0, "Check")
    } Else SearchList.Modify(0, "-Check")
}
LookForThumbnail(GuiCtrlObj, Row) {
    If !Row {
        Return
    }
    Code := GuiCtrlObj.GetText(Row, 2)
    x86ExDB := EnvGet('ProgramFiles(x86)')
    If Code = '' || !FileExist(x86ExDB '\Cash Helper v2\setting\defs\' Code '.json') {
        Return
    }
    Try {
        Item := JSON.Load(FileRead(x86ExDB '\Cash Helper v2\setting\defs\' Code '.json'))
        SearchThumb.Value := 'HBITMAP:*' Gdip_CreateHBITMAPFromBitmap(Gdip_BitmapFromBase64(Item['Thumbnail']))
    } Catch
        SearchThumb.Value := ''
}
SearchOK := PLC.AddButton('wp', ISTR.43)
CreateImageButton(SearchOK, 0, Set['IB']*)
SearchOK.OnEvent('Click', (*) => PLC.Hide())

KridiAdd() {
    If !ChangePrice.Value || !SelectedFolder.Text || (!NoEmptyName.Text && !EmptyName.Text) {
        Return
    }
    If 'Yes' != MsgBox(ISTR.89, ISTR.11, 0X4 + 0X30) {
        Return
    }
    PLC.Show(), PopulateSearchList()

    Name := SubStr(NoEmptyName.Text, 4) SubStr(EmptyName.Text, 4)
    Content := FileRead(SelectedFolder.Text '\' Name '.txt')

    WinWaitClose(PLC)

    FileObj := FileOpen(SelectedFolder.Text '\' Name '.txt', 'w')
    FileObj.Write(Evaluate(Content '+' ChangePrice.Value))
    FileObj.Close()

    LoadDB(), SearchSelectListBox(NoEmptyName, Name), ShowSelectedKridi()

    WriteInfo(Content, ChangePrice.Value, Content '+' ChangePrice.Value, "Kridi", Name)
    WriteHistory("'" ChangePrice.Value "' " ISTR.52 " " ISTR.53 " '" Name "'__Location:'" CurrentLocation.Value "'")
    ChangePrice.Value := '', ChangePrice.Focus(), CPConverted2DT.Value := ''
}

PopulateSearchList(Needle := '') {
    SearchList.Delete()
    SearchList.Add(, ISTR.42)
    Items := IniRead(A_AppData "\Kridi_Config.ini", 'FolderPath', "Items", "")
    For Item in StrSplit(Items, ';') {
        If Item != 'ERROR' {
            If Needle != '' && !InStr(Item, Needle)
                Continue
            SearchList.Add(, Item)
        }
    }
    x86ExDB := EnvGet('ProgramFiles(x86)')
    Loop Files, x86ExDB '\Cash Helper v2\setting\defs\*.json' {
        Try {
            Item := JSON.Load(FileRead(A_LoopFileFullPath))
            If Needle != '' && !InStr(Item['Name'], Needle) && !InStr(Item['Code'], Needle)
                Continue
            Item := [Item['Name'], Item['Code']]
            SearchList.Add(, Item*)
        }
    }
    SearchList.ModifyCol(1, 'AutoHdr')
    SearchList.ModifyCol(2, 'AutoHdr')
}

CreateImageButton(MainButtonAdd, 0, Set['IB']*)
MainButtonSubstract := KO.AddButton('xm+210 ym+325 w205 h25', ISTR.12)
CreateImageButton(MainButtonSubstract, 0, Set['IB']*)
MainButtonSubstract.OnEvent('Click', (*) => KridiSubstract())
KridiSubstract() {
    If !ChangePrice.Value || !SelectedFolder.Text || (!NoEmptyName.Text && !EmptyName.Text) {
        Return
    }
    If 'Yes' != MsgBox(ISTR.89, ISTR.11, 0X4 + 0X30) {
        Return
    }
    Name := SubStr(NoEmptyName.Text, 4) SubStr(EmptyName.Text, 4)
    Content := FileRead(SelectedFolder.Text '\' Name '.txt')

    FileObj := FileOpen(SelectedFolder.Text '\' Name '.txt', 'w')
    NewValue := Evaluate(Content '-' ChangePrice.Value)
    If NewValue > 0
        FileObj.Write(NewValue)
    FileObj.Close()

    LoadDB(), SearchSelectListBox(NewValue <= 0 ? EmptyName : NoEmptyName, Name), ShowSelectedKridi(0)

    WriteInfo(Content, ChangePrice.Value, Content - ChangePrice.Value, "Paid", Name)
    WriteHistory("'" ChangePrice.Value "' " ISTR.49 " " ISTR.53 " '" Name "'__Location:'" CurrentLocation.Value "'")

    ChangePrice.Value := '', ChangePrice.Focus(), CPConverted2DT.Value := ''
}

ChangePrice := KO.AddEdit('xm ym+295 w205 h25 Right -VScroll Number -E0x200 BackgroundF2BD73')
ChangePrice.OnEvent('Change', (*) => CPConverted2DT.Value := (ChangePrice.Value != '') ? Round(ChangePrice.Value / 1000, 3) ' TND' : '')

MainButtonCustomTotal := KO.AddButton('xm+430 ym+364 w93 h47 Disabled', ISTR.15)
CreateImageButton(MainButtonCustomTotal, 0, Set['IB']*)

KO.SetFont('s10')
English := KO.AddButton('xm+538 ym+391 w140 h20', ISTR.87)
CreateImageButton(English, 0, Set['IB']*)

Eddarja := KO.AddButton('xm+681 ym+391 w140 h20 Disabled', ISTR.88)
CreateImageButton(Eddarja, 0, Set['IB']*)

KO.SetFont('s12')
CPConverted2DT := KO.AddEdit('xm+205 ym+295 w210 h25 Left -VScroll -E0x200 ReadOnly BackgroundF0AD4E')

x := 0, y := 355
KO.AddGroupBox('xm+' x ' ym+' y ' w415 h57 cRed Left', ISTR.16)

x += 10, y += 19
KO.SetFont('s15')
TotalKridi := KO.AddEdit('xm+' x ' ym+' y ' w395 h28 Center ReadOnly -E0x200 cFF0000 Background' Set['backColor'])

ContextMenu1 := Menu()
ContextMenu1.Add(ISTR.20, AddName)
AddName(ItemName, ItemPos, MyMenu) {

}
ContextMenu1.SetIcon(ISTR.20, 'Add.png', , 0)
ContextMenu1.Add(ISTR.19, RemoveName)
RemoveName(ItemName, ItemPos, MyMenu) {

}
ContextMenu1.SetIcon(ISTR.19, 'Remove.png', , 0)
ContextMenu1.SetColor('FFFFFF')

ContextMenu2 := Menu()
ContextMenu2.Add(ISTR.21, (*) => Run(SelectedFolder.Text))
ContextMenu2.SetIcon(ISTR.21, 'Open.png', , 0)
ContextMenu2.Add(ISTR.19, RemoveFolder)
RemoveFolder(ItemName, ItemPos, MyMenu) {
    RemoveLocation()
}
ContextMenu2.SetIcon(ISTR.19, 'Remove.png', , 0)
ContextMenu2.SetColor('FFFFFF')

KO.Show(), AutoLoad(), LoadDB(), LoadHistory()

AutoLoad() {
    Selections := IniRead(A_AppData "\Kridi_Config.ini", "FolderPath", "Selection", "")
    SelectedFolder.Delete()
    SelectedFolder.Add(StrSplit(Selections, '|'))
    LastSelectedFolder := IniRead(A_AppData "\Kridi_Config.ini", "FolderPath", "LastSelectedFolder", "")
    CurrentLocation.Value := LastSelectedFolder
    If Index := IsSelectedFolder(LastSelectedFolder, Selections)
        SelectedFolder.Choose(Index)
}

RemoveLocation() {
    If !Folder := SelectedFolder.Text
        Return
    Selections := IniRead(A_AppData "\Kridi_Config.ini", "FolderPath", "Selection", "")
    NSelections := ''
    For Selection in StrSplit(Selections, '|') {
        If Selection != Folder
            NSelections .= (NSelections = '' ? '' : '|') Selection
    }
    IniWrite(NSelections, A_AppData "\Kridi_Config.ini", "FolderPath", "Selection")
    LastSelectedFolder := IniRead(A_AppData "\Kridi_Config.ini", "FolderPath", "LastSelectedFolder", "")
    If LastSelectedFolder = Folder {
        Try IniDelete(A_AppData "\Kridi_Config.ini", "FolderPath", "LastSelectedFolder")
        WriteHistory('"' SelectedFolder.Text '" ' ISTR.28)
    }
    AutoLoad()
}

IsSelectedFolder(Folder, Selections := '') {
    For EachFolder in StrSplit(Selections ? Selections : IniRead(A_AppData "\Kridi_Config.ini", "FolderPath", "Selection", ""), '|') {
        If EachFolder = Folder
            Return A_Index
    }
    Return 0
}

WriteHistory(HistoryData) {
    TimeString := FormatTime(A_Now, "__'Date:' yyyy/MM/dd ('Time:' hh:mm:ss tt)__")
    FileAppend(TimeString ":" HistoryData "`n", A_AppData "\IKAHistory.log")
    LoadHistory()
}

LoadHistory() {
    Try {
        FileObj := FileOpen(A_AppData "\IKAHistory.log", "r")
        While !FileObj.AtEOF
            LastHistoryLine := FileObj.ReadLine()
        FileObj.Close()
        History.Delete()
        If RegExMatch(LastHistoryLine, "(\d+/\d+/\d+)", &Date)
            History.Add(, "Date: ", Date[1])
        If Pos := RegExMatch(LastHistoryLine, "(\d+:\d+:\d+ (A|P)M)", &Time) {
            History.Add(, "Time: ", Time[1])
            If RegExMatch(LastHistoryLine, "(.*)", &Action, StrLen(Time[1]) + Pos + 4)
                History.Add(, "Action: ", Action[1])
        }
        History.ModifyCol(2, 'AutoHdr')
    }
}

SearchSelectListBox(List, Name) {
    Try If FoundItem := ControlFindItem('X. ' Name, List.Hwnd)
        List.Choose(FoundItem)
    Try If FoundItem := ControlFindItem('✓. ' Name, List.Hwnd)
        List.Choose(FoundItem)
}

WriteInfo(B, CP, A, Type, Name) {
    TimeString := FormatTime(A_Now, '[dddd | yyyy/MM/dd | hh:mm:ss tt]')
    B := Evaluate(B), CP := Evaluate(CP), A := Evaluate(A)
    ImportantInfo := "[" Type "] | " TimeString " | " Name " | " B " Millims (" Round(B / 1000, 3) " TND) | " CP " Millims (" Round(CP / 1000, 3) " TND) | " A " Millims (" Round(A / 1000, 3) " TND)"
    If Type = 'Kridi' {
        Products := ''
        R := 1
        While R := SearchList.GetNext(R, 'C') {
            If R = 1 {
                Continue
            }
            ProductName := SearchList.GetText(R)
            Code := SearchList.GetText(R, 2)
            Products .= (Products = '' ? '' : '|') ProductName (Code != '' ? ';' Code : '')
        }
        ImportantInfo .= Products != '' ? ' [ ' Products ' ]' : ''
    }
    FileAppend(ImportantInfo "`n", SelectedFolder.Text "\" Name ".Info")
}

Evaluate(Expr) {
    Try Return ((E := eval(Expr)) >= 0) ? E : 0
    Catch
        Return 0
}

ProportionsCalc(WWidth := 0, WHeight := 0) {
    Static Proportion := Map()
    If !WWidth
        KO.GetPos(&WX, &WY, &WWidth, &WHeight)
    If !Proportion.Count {
        For Control in KO {
            Control.GetPos(&X, &Y, &Width, &Height)
            Proportion[Control] := [
                X / WWidth,
                Y / WHeight,
                Width / WWidth,
                Height / WHeight
            ]
        }
    }
    For Control, Ratio in Proportion {
        Control.Move(
            WWidth * Ratio[1], 
            WHeight * Ratio[2], 
            WWidth * Ratio[3], 
            WHeight * Ratio[4]
        )
        If Type(Control) = 'Gui.Button'
            CreateImageButton(Control, 0, Set['IB']*)
        Control.Redraw()
    }
}