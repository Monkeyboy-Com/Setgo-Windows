#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Windows-icon.ico
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=setgo
#AutoIt3Wrapper_Res_Description=Quick Directory Change Helper
#AutoIt3Wrapper_Res_Fileversion=1.3.1.0
#AutoIt3Wrapper_Res_LegalCopyright=Uncopyrighted & Unwarranted
#AutoIt3Wrapper_Res_Field=ProductName|setgo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region
#EndRegion

#cs -------------------------------------------------------------------------

	Windows-based setgo utility

	Compile as a console application.

	AutoIt Version: 3.3.14.2

#ce -------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Setup & Directives
AutoItSetOption("MustDeclareVars", 1)

;----------------------------------------------------------------------------
; Includes
#include <Array.au3>
#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <WinAPI.au3>

#include "Console.au3"

;----------------------------------------------------------------------------
; Globals
Global $_answer = 0
Global $_mode = 0
Global $_prog = "Setgo for Windows v1.3.1.0"
Global $_progTitle = $_prog & " - Quick Directory Change Helper  "
Global $_returnMsg = ""
Global $_returnValue = 0
Global $_setgo = ""
Global $_target = ""
Global $_writePath = ""

; error information
Dim $_panErrorValue = 0
Dim $_panErrorMsg = ""

Dim $msg

;============================================================================
; Main

ConsoleWrite(@CRLF & $_progTitle & @CRLF & @CRLF)

$_setgo = EnvGet("SETGO")
If StringLen($_setgo) < 1 Then
	$msg =  @CRLF & "SETGO environment symbol not found, cannot continue" & @CRLF
	$msg =  "Please set the SETGO environment symbol to the desired directory for setgo batch files" & @CRLF
	ConsoleWrite($msg)
	CloseProgram()
EndIf

ParseOptions()
If $_panErrorValue <> 0 Then
	$_returnValue = $_panErrorValue
	$_returnMsg = $_panErrorMsg
	CloseProgram()
EndIf

If $_mode == 3 Then
	Help()
	CloseProgram()
EndIf

If StringLen($_target) = 0 Then
	If $_mode == 3 Then
		$_target = "."
	Else
		Help()
		CloseProgram()
	EndIf
EndIf

If $_target == "." Then
	Local $a
	$_target = @WorkingDir
	$a = StringSplit($_target, "\")
	$_target = $a[$a[0]]
EndIf

If StringLen($_target) < 1 Then
	$msg =  @CRLF & "No name specified, nothing to do" & @CRLF
	ConsoleWrite($msg)
	CloseProgram()
EndIf

$msg =  "setgo: keyword.....: " & $_target & @CRLF
$msg &= "       directory...: " & @WorkingDir & @CRLF
ConsoleWrite($msg)

$_writePath = $_setgo & "\-" & $_target & ".bat"

If $_mode = 0 Then
	CreateSetgo()
EndIf
If $_mode = 1 Then
	DeleteSetgo()
EndIf
If $_mode = 2 Then
	EditSetgo()
EndIf
If $_mode = 3 Then
	FindSetgo()
EndIf

ConsoleWrite(" " & @CRLF)
Exit $_returnValue

; Main
;============================================================================

;----------------------------------------------------------------------------
Func CloseProgram()
	Exit $_returnValue
EndFunc   ;==>CloseProgram

;----------------------------------------------------------------------------
Func CreateSetgo()
	Local $msg
	If FileExists($_writePath) Then
		$msg =  @CRLF & $_target & ".bat already exists as:" & @CRLF
		$msg &= "  " & $_writePath & @CRLF & @CRLF
		Local $hwnd = _Console_GetWindow()
		$_answer = MsgBox($MB_YESNO + $MB_ICONQUESTION, $_progTitle, "The Go command '" & $_target & "' already exists, overwrite it?", 0, $hwnd)
		If $_answer == $IDYES Then
			DeleteSetgo()
			DoAdd()
		Else
			$_returnMsg = "cancelled"
			$_returnValue = 1
			ConsoleWrite(@CRLF & $_returnMsg)
		EndIf
	Else
		$msg = "       " & $_target & " is new" & @CRLF
		ConsoleWrite($msg)
		DoAdd()
	EndIf
EndFunc   ;==>CreateSetgo

;----------------------------------------------------------------------------
Func DeleteSetgo()
	Local $msg
	If FileExists($_writePath) Then
		FileDelete($_writePath)
		$msg = "       removed " & $_target
	Else
		$msg = $_target & " (" & $_writePath & ") not found"
	EndIf
	ConsoleWrite($msg & @CRLF)
EndFunc   ;==>DeleteSetgo

;----------------------------------------------------------------------------
Func DoAdd()
	Local $quote = ('"')
	Local $stamp = @MON & "/" & @MDAY & "/" & @YEAR & " " & @HOUR & ":" & @MIN
	Local $go = "@echo off" & @CRLF
	$go &= "REM Created by " & $_prog & " at " & $stamp & @CRLF
	$go &= "cd /D " & $quote & @WorkingDir & $quote & @CRLF
	FileWriteLine($_writePath, $go)
	ConsoleWrite(@CRLF & "New Go command '" & $_target & "' is ready" & @CRLF)
EndFunc

;----------------------------------------------------------------------------
Func EditSetgo()
	Local $msg
	Local $_editor = EnvGet("SETGOEDITOR")
	If StringLen($_editor) < 1 Then
		$msg =  @CRLF & "SETGOEDITOR environment symbol not found, cannot continue" & @CRLF
		$msg =  "Please set the SETGOEDITOR environment symbol to the desired editor executable" & @CRLF
		ConsoleWrite($msg)
		CloseProgram()
	EndIf
	ShellExecute($_editor, $_writePath, $_setgo)
EndFunc   ;==>EditSetgo

;----------------------------------------------------------------------------
Func FindSetgo()
	Local $msg = ""
	ConsoleWrite(" " & @CRLF)
	Local $quote = ('"')
	Local $cmd = @WindowsDir & "\system32\findstr.exe" & " /L /I /M " & $quote & $_target & $quote & " " & $quote & $_setgo& "\-*.bat" & $quote
	;ConsoleWrite("Executing: " & $cmd & @CRLF)
	Local $pid = Run($cmd, "", Default, $STDOUT_CHILD)
	ProcessWaitClose($pid)
	Local $out = StdoutRead($pid)
	Local $aArray = StringSplit(StringTrimRight(StringStripCR($out), StringLen(@CRLF)), @CRLF)
	;_ArrayDisplay($aArray)
	If StringLen($out) > 0 Then
		ConsoleWrite(@CRLF & "Found: " & @CRLF)
		For $i = 1 To $aArray[0]
			$msg = $aArray[$i]
			If $i == $aArray[0] Then $msg &= "t" 			; replace the last trimmed-off 't' from .bat
			ConsoleWrite("       " & $msg & @CRLF)
		Next
	Else
		ConsoleWrite(@CRLF & "No Go command containing '" & $_target & "' was found" & @CRLF)
	Endif
EndFunc   ;==>FindSetgo

;----------------------------------------------------------------------------
Func Help()
	Local $msg
	$msg =  @CRLF & "USAGE: setgo [-d][-e][-f] name" & @CRLF
	$msg &= " " & @CRLF
	$msg &= "A simple utility to maintain a set of batch files of 'Go' command...aliases used to" & @CRLF
	$msg &= "quickly change directories with a simple name.  For example, if you are currently in" & @CRLF
	$msg &= "C:\Windows\System32 and run the command:" & @CRLF
	$msg &= " " & @CRLF
	$msg &= "    setgo sys32" & @CRLF
	$msg &= " " & @CRLF
	$msg &= "a batch file is added to the SETGO directory named -sys32.bat that will contain:" & @CRLF
	$msg &= " " & @CRLF
	$msg &= "    cd /d 'C:\Windows\system32'" & @CRLF
	$msg &= " " & @CRLF
	$msg &= "which says to change the current drive and directory to that path." & @CRLF
	$msg &= " " & @CRLF
	$msg &= "The environment symbol SETGO is required to specify the directory where the Go batch" & @CRLF
	$msg &= "will be maintained.  Optionally the symbol SETGOEDITOR may be specified as the full" & @CRLF
	$msg &= "path and filename to the desired editor for the -e option." & @CRLF
	$msg &= " " & @CRLF
	$msg &= "To make the Go batch files available in a Command Window added the same SETGO path" & @CRLF
	$msg &= "to the system PATH in Control Panel, System, Advanced Settings. The go to the Advanced" & @CRLF
	$msg &= "tab and click the Environment Variables... button. Add the SETGO symbol, and add it to" & @CRLF
	$msg &= "the system PATH in the System variables section like this:  %SETGO%; " & @CRLF
	$msg &= " " & @CRLF
	$msg &= "  Options: " & @CRLF
	$msg &= "    -d      delete name from setgo directory" & @CRLF
	$msg &= "    -e      edit the name, if SETGOEDITOR environment symbol is set." & @CRLF
	$msg &= "    -f      find all go entries containing name. If name is not specified" & @CRLF
	$msg &= "            then use the current directory name." & @CRLF
	$msg &= "    name    logical go name for the current directory. If '.' (dot) is" & @CRLF
	$msg &= "            specified then the name of the current directory is used." & @CRLF
	$msg &= " " & @CRLF
	$msg &= "  If neither -d or -f are used the a new go name is added." & @CRLF
	$msg &= " " & @CRLF
	$msg &= "  To use a go command type:  -name" & @CRLF
	$msg &= " " & @CRLF
	$msg &= "  Examples:" & @CRLF
	$msg &= "    setgo work           creates new go name: -work" & @CRLF
	$msg &= "    setgo -f             finds all entries containing the current directory" & @CRLF
	$msg &= "    setgo -f work        finds all entries containing: work" & @CRLF
	$msg &= "    setgo -d work        deletes go entry: -work" & @CRLF
	$msg &= "  " & @CRLF
	ConsoleWrite($msg)
EndFunc   ;==>Help

;----------------------------------------------------------------------------
Func ParseOptions()
	Dim $l, $opt
	$l = $CmdLine[0]
	For $j = 1 To $l
		$opt = $CmdLine[$j]
		If $opt == "-d" Then		; delete
			$_mode = 1
			ContinueLoop
		EndIf
		If $opt == "-e" Then		; edit
			$_mode = 2
			ContinueLoop
		EndIf
		If $opt == "-f" Then		; find
			$_mode = 3
			ContinueLoop
		EndIf
		If StringInStr("-?/?-h/h--help/help", $opt) Then ; help
			$_mode = 4
			ContinueLoop
		EndIf
		$_target = $CmdLine[$j]
	Next
	;;;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : @AppDataCommonDir = ' & @AppDataCommonDir & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
EndFunc   ;==>ParseOptions


; end

