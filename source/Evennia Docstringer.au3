#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=Evennia Docstringer.exe
#AutoIt3Wrapper_Compression=0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs	··············································································
	··············································································
	···························· EVENNIA DOSCSTRINGER ····························
	··············································································
	··············································································

	AutoIt Version: 3.3.12.0
	Author:         Tristano Ajmone
	App Version:	Alpha 1									Date: 29th March 2015

	Script Function: Evennia Docstringer is a tool for creating Python docstrings
	to be used with Evennia's auto-help system, or for the creation of custom MUD
	texts. It allows to write text within a working file without having to worry
	about text-wrapping. It will autowrap at 80 columns, all calculations are done
	on ANSI-stripped text so valid tags don't add to the wrapping calculations.
	It will output a 80-columns wrapped text that can be copied and pasted were
	needed (Cmds docstring, custom Help entries, ingame texts, ecc.)
	It can handle Evennia's ANSI escape codes (text tags) and offers a color pre-
	view of final docstring as it will look in the MUD -- it replicates Evennia's
	behavior almost 100% (some complex tag nesting might produce slightly different
	output).
#ce ----------------------------------------------------------------------------

#cs

	******************************************************************************
	*                                                                            *
	*                             DEVELOPMENT STATUS                             *
	*                                                                            *
	******************************************************************************
	This app is still in active development and there are still some unimplement
	functions and limitations:

	- {/	The linebreak tag is not implemented and will be ignored. It is not
	;		something you'd normally use in docstrings, though.

	- {-	Tab tags are converted into a single whitespace. It is not possibile
	;		to predict how each client will visualize tabs. So don't rely on the
	;		previewer for their real in-game output.

	··············································································
	···························· Extra Functionality ·····························
	··············································································
	1) Evennia Docstringer keeps track of trailing spaces in source text, and when
	it wraps it will perserve the exact number of spaces at the beginning of the
	line.
	··············································································
	····························· Future Development ·····························
	··············································································
	In future editions I'm planning to add some functionalities:
	1) Custom formatting tags: to be used in source text for auto-formatting the
	final docstring.
	2) Docstrings Auto-injection: each docstring might be associated with a function
	in a python module and the output docstring injected into the file to replace
	the docstring.
	3) Custom Help-Entries: each docstring might be associated with an extarnal file
	to be injected with a python script that adds the docstring to a custom Help
	entry for the MUD.
#ce

#cs ---------------------------~{ MISC WORKING NOTES }~---------------------------

	******************************************************************************
	*                                                                            *
	*                    CARRIAGE RETURN, NEWLINE, LINE FEED                     *
	*                                                                            *
	******************************************************************************

	@CR = \r = Chr(13) = 0x0D
	@LF = \n = Chr(10  = 0x0A
	@CRLF = \r\n = Chr(13)+(10) = 0x0D0A

	NOTE: Edit control will not wrap with @CR or @LF only. Must use @CRLF. For this
	I've added a  SanitizeEOLs_CRLF() func.

	These characters are based on printer commands: The line feed indicated that
	one line of paper should feed out of the printer thus instructed the printer
	to advance the paper one line, and a carriage return indicated that the printer
	carriage should return to the beginning of the current line.

	Linux: @LF
	Windows: @CRLF

	In AutoIt:
	@CR		= Carriage return, Chr(13); occasionally used for line breaks.
	@LF		= Line feed, Chr(10); occasionally used for line breaks.
	@CRLF	= @CR & @LF; typically used for line breaks.

	******************************************************************************
	*                                                                            *
	*                      FILE LINE-WRITE END OF LINE CHAR                      *
	*                                                                            *
	******************************************************************************

	FileWriteLine ( "filehandle/filename", "line" )

	line:	The line of text to write to the text file. If the line does NOT
	end in @CR or @LF then a DOS linefeed (@CRLF) will be automatically added.

	Therefore appropriate Pythonic EOL char must be added to the line when writing
	to file.

	******************************************************************************
	*                                                                            *
	*                            EVENNIA ANSI ESCAPES                            *
	*                                                                            *
	******************************************************************************
	{# text color {[# = bgcolor
	where # = color: r g y b m c w x R G Y B M C W X
	red green yellow blue magenta cyan white x=black
	lower-case = bright colors
	upper-case = darker (normal) colors
	{!# normal text color (only capital letters are valid)
	{n = Normal/reset
	{/ = linebreak
	{- = TAB --will convert to single space!
	{_ = space (non-strippable)
	{* = invert current text/bg colours
	{^ = blink (ignored, stripped)
	{{ = escaped ANSI codes--first brace stripped

	******************************************************************************
	*                                                                            *
	*                        AUTOIT CONSOLE COLOR CODES                          *
	*                                                                            *
	******************************************************************************
	These codes can be used to color the output of ConsoleWrite():
	! = red text color
	> = blue text color
	- = orange text color
	+ = green text color
#ce ----------------------------------------------------------------------------

; ******************************************************************************
; *                                  INCLUDES                                  *
; ******************************************************************************

#include <AutoItConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <IE.au3>
#include <String.au3>
#include <Array.au3>


; ******************************************************************************
; *                                DECLARATIONS                                *
; ******************************************************************************

Global $Docstringer_Version = "Alpha 1"
Global $Button_Refresh, $Button_Copy_Input, $Button_Copy_Output, $Button_Clear, $Button_Test
Global $DocString_Edit, $DocString_Preview, $oIE

Main()

; ----------------------~{ END OF INITIALIZE/SETUP CODE }~----------------------


; ******************************************************************************
; *                                    MAIN                                    *
; ******************************************************************************

Func Main()
	Create_GUI()

	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $Button_Refresh
				; ------------------------------------------------------------------------------
				;                                    REFRESH
				; ------------------------------------------------------------------------------
				Refresh_View(GUICtrlRead($DocString_Edit))
			Case $Button_Copy_Input
				; ------------------------------------------------------------------------------
				;                                   COPY INPUT
				; ------------------------------------------------------------------------------
				$docstring = GUICtrlRead($DocString_Edit)
				Refresh_View($docstring)
				ClipPut($docstring)
				Beep(500, 100)
			Case $Button_Copy_Output
				; ------------------------------------------------------------------------------
				;                                  COPY OUTPUT
				; ------------------------------------------------------------------------------
				$docstring = GUICtrlRead($DocString_Edit)
				Refresh_View($docstring)
				$docstring = RawText_2_Docstring($docstring)
				ClipPut($docstring)
				Beep(500, 100)
			Case $Button_Clear
				; ------------------------------------------------------------------------------
				;                                     CLEAR
				; ------------------------------------------------------------------------------
				Refresh_View("")
			Case $Button_Test
				; ------------------------------------------------------------------------------
				;                                      TEST
				; ------------------------------------------------------------------------------
				Refresh_View(Sample_Text())

		EndSwitch
	WEnd

EndFunc   ;==>Main

Func Create_GUI()
	; ******************************************************************************
	; *                                 CREATE GUI                                 *
	; ******************************************************************************
	$WinMain_W = 1000
	$WinMain_H = 800
	$PosX = 10
	$PosY = 10

	Global $oIE = _IECreateEmbedded()
	Global $WinMain = GUICreate("Evennia Dosctringer (" & $Docstringer_Version & ")", $WinMain_W, $WinMain_H, -1, -1, $WS_OVERLAPPEDWINDOW + $WS_CLIPSIBLINGS + $WS_CLIPCHILDREN)
	; $GUI_SS_DEFAULT_GUI + $WS_CLIPCHILDREN )
	; ==============================================================================
	;                                  BUTTONS ROW
	; ==============================================================================
	$butt_width = 150
	$butt_height = 30
	Local Enum Step +160 $ButtPosX1 = $PosX, $ButtPosX2, $ButtPosX3, $ButtPosX4, $ButtPosX5
	;;; ConsoleWrite ("$ButtPosX = " & $ButtPosX1 & " - " & $ButtPosX2 & " - " & $ButtPosX3 & @CRLF)
	; ------------------------------------------------------------------------------
	;                                    Refresh
	; ------------------------------------------------------------------------------
	$Button_Refresh = GUICtrlCreateButton("Refresh", $ButtPosX1, $PosY, $butt_width, $butt_height)
	GUICtrlSetTip(-1, "Refresh the working panes: User input pane, Docstring output preview pane, " & _
			"and ANSI Color Preview pane.", "Refresh View Panes", 1, 1)
	; ------------------------------------------------------------------------------
	;                                   COPY INPUT
	; ------------------------------------------------------------------------------
	$Button_Copy_Input = GUICtrlCreateButton("Copy Input", $ButtPosX2, $PosY, $butt_width, $butt_height)
	GUICtrlSetTip(-1, "Copy to clipboard the raw input of the User Input Pane.", "Copy Input to Clipboard", 1, 1)
	; ------------------------------------------------------------------------------
	;                                  COPY OUTPUT
	; ------------------------------------------------------------------------------
	$Button_Copy_Output = GUICtrlCreateButton("Copy Output", $ButtPosX3, $PosY, $butt_width, $butt_height)
	GUICtrlSetTip(-1, "Copy to clipboard the wrapped Docstring from the Docstring Output Preview Pane.", "Copy Docstring to Clipboard", 1, 1)
	; ------------------------------------------------------------------------------
	;                                     Clear
	; ------------------------------------------------------------------------------
	$Button_Clear = GUICtrlCreateButton("Clear", $ButtPosX4, $PosY, $butt_width, $butt_height)
	GUICtrlSetTip(-1, "Click to erase all text in user input pane." & @CRLF & "WARNING: You'll lose all your " & _
			"unsaved custom text! This operation can't be undone!", "Clear Input Pane", 2, 1)
	; ------------------------------------------------------------------------------
	;                                      Test
	; ------------------------------------------------------------------------------
	$Button_Test = GUICtrlCreateButton("Test", $ButtPosX5, $PosY, $butt_width, $butt_height)
	GUICtrlSetTip(-1, "Click this button to replace user input with Sample Text" & @CRLF & _
			"WARNING: You'll lose all your unsaved custom text! This operation can't be undone!", "Test Button", 2, 1)
	; ------------------------------- Refresh Coords -------------------------------
	$PosX = 10
	$PosY += $butt_height + 10
	; ==============================================================================
	;                            USER INPUT EDIT CONTROL
	; ==============================================================================
	$this_height = (($WinMain_H - $PosY) / 3) - 10
	Global $DocString_Edit = GUICtrlCreateEdit("Your text here..." & @LF, $PosX, $PosY, $WinMain_W - 20, $this_height, _
			$ES_MULTILINE + $ES_WANTRETURN + $WS_HSCROLL + $WS_VSCROLL)
	GUICtrlSetTip(-1, "Type here your raw Docstring (unwrapped).", "User Input Pane", 1, 1)
	GUICtrlSetFont($DocString_Edit, 9, 400, 0, "FixedSys")
	; ------------------------------- Refresh Coords -------------------------------
	$PosX = 10
	$PosY += $this_height + 10
	; ==============================================================================
	;                           DOCSTRING PREVIEW CONTROL
	; ==============================================================================
	Global $DocString_Preview = GUICtrlCreateEdit("Docstring preview..." & @LF, $PosX, $PosY, $WinMain_W - 20, $this_height, _
			$ES_MULTILINE + $ES_READONLY + $WS_HSCROLL + $WS_VSCROLL)
	GUICtrlSetTip(-1, "Here you'll see a preview of your wrapped docstring text. Click ""Refresh"" to update pane.", "Docstring Output Preview Pane", 1, 1)
	GUICtrlSetFont($DocString_Preview, 9, 400, 0, "FixedSys")
	GUICtrlSetColor($DocString_Preview, $COLOR_MEDGRAY) ; $COLOR_MEDGRAY $COLOR_GRAY
	; ------------------------------- Refresh Coords -------------------------------
	$PosX = 10
	$PosY += $this_height + 10
	; ==============================================================================
	;                                 HTML PREVIEWER
	; ==============================================================================
	GUICtrlCreateObj($oIE, $PosX, $PosY, $WinMain_W - 20, $this_height)
	GUICtrlSetTip(-1, "Here you'll see a preview of your docstring MUD-output, with " & _
			"ANSI escape sequences put into effect. Click ""Refresh"" to update pane.", _
			"ANSI Color Preview Pane", 1, 1) ; Doesn't show up!!!!
	GUISetState(@SW_SHOW, $WinMain)
	_IENavigate($oIE, "about:blank")
	_IEAction($oIE, "stop")
	HTML_Preview_Initialize()
	;HTML_Preview_Refresh()

EndFunc   ;==>Create_GUI

; ··············································································
; ··············································································
; ····························· GUI RELATED FUNCS ······························
; ··············································································
; ··············································································
Func Refresh_View($docstring)
	DocString_Edit_Refresh($docstring)
	$docstring = RawText_2_Docstring($docstring)
	DocString_Preview_Refresh($docstring)
	$docstring = Docstring_2_HTML($docstring)
	HTML_Preview_Refresh($docstring)
EndFunc   ;==>Refresh_View
; ··············································································
; ··············································································
; ····························· USER INPUT EDITOR ······························
; ··············································································
; ··············································································
Func DocString_Edit_Refresh($rawtext)
	; ******************************************************************************
	; *                             USER INPUT REFRESH                             *
	; ******************************************************************************
	$sanitezed = SanitizeEOLs_CRLF($rawtext)
	GUICtrlSetData($DocString_Edit, $sanitezed)
EndFunc   ;==>DocString_Edit_Refresh

; ··············································································
; ··············································································
; ···························· DOCSTRING PREVIEWER ·····························
; ··············································································
; ··············································································
Func DocString_Preview_Refresh($docstring)
	; ******************************************************************************
	; *                        DOCSTRING PREVIEWER REFRESH                         *
	; ******************************************************************************
	$sanitezed = SanitizeEOLs_CRLF($docstring)
	GUICtrlSetData($DocString_Preview, $sanitezed)
EndFunc   ;==>DocString_Preview_Refresh

; ··············································································
; ··············································································
; ······························· HTML PREVIEWER ·······························
; ··············································································
; ··············································································
Func HTML_Preview_Initialize()
	; ******************************************************************************
	; *                          HTML PREVIEW INITIALIZE                           *
	; ******************************************************************************

	$HTML_Boiler = HTML_Boilerplate()
	$Sample = Sample_Text()
	_IEDocWriteHTML($oIE, $HTML_Boiler)
	_IEBodyWriteHTML($oIE, $Sample)
	_IEAction($oIE, "refresh")

EndFunc   ;==>HTML_Preview_Initialize

Func HTML_Preview_Refresh($docstring)
	; ******************************************************************************
	; *                            HTML PREVIEW REFRESH                            *
	; ******************************************************************************
	_IEBodyWriteHTML($oIE, $docstring)
	;_IEAction($oIE, "refresh")
EndFunc   ;==>HTML_Preview_Refresh
; ******************************************************************************
; *                                REFRESH VIEW                                *
; ******************************************************************************

; ··············································································
; ··············································································
; ·························· TEXT MANIPULATION FUNCS ···························
; ··············································································
; ··············································································
Func Sample_Text()
	; ******************************************************************************
	; *                              SAMPLE RAW TEXT                               *
	; ******************************************************************************
	; "This line, stripped of ANSI escape sequences, is exactly eighty characters long."
	$sample_s = "This is some sample text. This line is plain and less than 80 chars." & @CR
	$sample_s &= "This {mline{n,{_{gstripped{n{_of {w{[yANSI{_escape{n {csequences{n, is exactly{* eighty {ncharacters long." & @CR
	$sample_s &= "{rred {ggreen {yyellow {bblue {mmagenta {ccyan {wwhite {xblack" & @CR
	$sample_s &= "{RRED {GGREEN {YYELLOW {BBLUE {MMAGENTA {CCYAN {WWHITE {XBLACK{n" & @CR
	$sample_s &= "{X{[rRED BG {[gGREEN BG {[yYELLOW BG {[bBLUE BG {[mMAGENTA BG {[cCYAN BG {[wWHITE BG {w{[xBLACK BG{n" & @CR
	$sample_s &= "Also, this line is longer than 80 chars and will wrapped to 80 when outputted to docstring." & @CR
	$sample_s &= "    This line has 4 leading spaces, and is longer than 80 chars. When wrapped to 80, the leftover string will have same leading spaces. "
	$sample_s &= "And the same for the next newline, and the next one... as long as it needs. It helps preserving indentation." & @CR
	$sample_s &= "Here are escaped codes (ignored): {{Y{{[bAAAAA{{n." & @CR;$sample_s &= "" & @LF
	;$sample_s &= "" & @LF
	;$sample_s &= "" & @LF
	;$sample_s &= "" & @LF

	; ==============================================================================
	;                          Ruler Line (80 Chars Rules)
	; ==============================================================================
	; line markings: 10, 20, ..., 80
	$ruler = "{R"
	For $i = 1 To 8
		$ruler &= "{x||||{W|{x|||{r" & $i & "0"
	Next
	$ruler &= "{n" & @CR
	; Ruler Marks
	$ruler &= _StringRepeat("{x||||{W|{x||||{w|", 8) & "{n" & @CR

	#cs ; Previous version (numbers instead of lines)
		; line markings: 10, 20, ..., 80
		$ruler = "{R"
		For $i = 1 To 8
		$ruler &= _StringRepeat(" ", 8) & $i & "0"
		Next
		$ruler &= "{n" & @CR
		; line with 1-9 + bright 0 numbers, up to 80
		$ruler &= _StringRepeat("{r123456789{g0", 8) & "{n" & @CR
	#ce
	; ==============================================================================

	$sample_s = $ruler & $sample_s & $ruler
	;;; ConsoleWrite($sample_s)
	Return $sample_s

EndFunc   ;==>Sample_Text


Func RawText_2_Docstring($rawtext)
	; ******************************************************************************
	; *                     CONVERT RAW-USER-TEXT TO DOCSTRING                     *
	; ******************************************************************************
	SanitizeEOLs_CRLF($rawtext)
	$multiline_rawtext = _StringExplode($rawtext, @CRLF)
	$wrapped_text = ""
	; _ArrayDisplay($multiline_rawtext, "RawText in Array")

	$i = -1
	;For $i = 0 To UBound($multiline_rawtext) - 1
	While $i + 1 < UBound($multiline_rawtext)
		$i += 1 ; counter increase goes here because ExitLoop skips back to While
		;;; ConsoleWrite(@CRLF & "Line " & $i + 1 & "= " & $multiline_rawtext[$i])
		;;; ConsoleWrite(@CRLF & "Line " & $i + 1 & ": ")
		$LineLength = StringLen($multiline_rawtext[$i])
		If $LineLength > 80 Then
			;;; ConsoleWrite("rawline > 80 | ")
			; ==============================================================================
			;              Lets check if after ANSI stripping is still > 80...
			; ==============================================================================
			If LineLength_ANSI_Stripped($multiline_rawtext[$i]) <= 80 Then
				; ------------------------------------------------------------------------------
				;                       YES, after ANSI stripping is <= 80
				; ------------------------------------------------------------------------------
				;;; ConsoleWrite("stripped <= 80.")
				; Clean Trailing WitheSpaces (ANSI Stripper doesn't count them! Might break up)
				$multiline_rawtext[$i] = StringStripWS($multiline_rawtext[$i], $STR_STRIPTRAILING)
				$wrapped_text &= $multiline_rawtext[$i] & @CRLF
			Else
				; ------------------------------------------------------------------------------
				;                     NO, after ANSI stripping is still > 80
				; ------------------------------------------------------------------------------
				;;; ConsoleWrite("stripped > 80." & @CRLF)
				; Start removing one word at the time, starting from end (should be faster usually)...
				$occur = -1 ; Which occurence in string to find
				While True
					$pos_result = StringInStr($multiline_rawtext[$i], " ", 0, $occur)
					If @error == 1 Or $pos_result == 0 Then
						MsgBox(0, "Error!", "Something went wrong...")
						ExitLoop
					EndIf
					$temp_line = StringLeft($multiline_rawtext[$i], $pos_result - 1)
					;$temp_line = StringStripWS($temp_line, $STR_STRIPTRAILING) ; strip trailing whitespaces
					$temp_line_length = LineLength_ANSI_Stripped($temp_line)
					;;; ConsoleWrite(">>> Pos result = " & $pos_result & " | Stripped Length = " & $temp_line_length & " | OrigLength = " & $LineLength & @CRLF)
					;;; ConsoleWrite($temp_line & @CRLF)
					If $temp_line_length <= 80 Then
						;;; ConsoleWrite(">>> OK = " & $temp_line & @CRLF)
						;MsgBox(0, "Trimmed to 80!", "Original line:" & @CRLF & $multiline_rawtext[$i] & @CRLF & "Now string is trimmed within 80:" & @CRLF & $temp_line)
						; add result to docstring
						$wrapped_text &= $temp_line & @CRLF
						; Get leftover of string so we will insert it in next Array slot...
						$leftover_text = StringTrimLeft($multiline_rawtext[$i], $pos_result)
						$leftover_text = StringStripWS($leftover_text, $STR_STRIPLEADING) ; strip leading whitespaces
						; ------------------------------------------------------------------------------
						;                  Preserve original indentantion on next line
						; ------------------------------------------------------------------------------
						; if original string had leading whitespaces, add them also to split string...
						If Num_of_LeadingWS($multiline_rawtext[$i]) > 0 Then
							$leftover_text = _StringRepeat(" ", Num_of_LeadingWS($multiline_rawtext[$i])) & $leftover_text
						EndIf
						;$multiline_rawtext[$i] = $leftover_text
						;$i = $i - 1
						; Insert leftover of string in next Array slot...
						If (UBound($multiline_rawtext) > ($i + 1)) Then ; Check to prevent out-of-bounds error
							; Insert on top of next to current item in Array (ie: it will become next)
							;$insertion_raw =  $multiline_rawtext[$i + 1]
							;MsgBox(0, "INSERT ROW", $insertion_raw)
							;_ArrayInsert($multiline_rawtext, $insertion_raw, $leftover_text)
							_ArrayInsert($multiline_rawtext, $i + 1, $leftover_text)
							If @error Then MsgBox(0, "ERROR", "_ArrayInstert() Err: " & @error)
							;;; ConsoleWrite(">>> Array Insterted at " & $i + 1 & @CRLF)
						Else
							; Put it at end because there is no next item
							_ArrayAdd($multiline_rawtext, $leftover_text)
							;;; ConsoleWrite(">>> Array Added at end, with $i = " & $i + 1 & @CRLF)
						EndIf
						;$i -= 1
						ExitLoop
					EndIf
					$occur -= 1
				WEnd
			EndIf
		Else ; The line was already <= 80
			;;; ConsoleWrite("rawline <= 80.")
			; Text is ok as is...
			$wrapped_text &= $multiline_rawtext[$i] & @CRLF
		EndIf
	WEnd
	;;; ConsoleWrite($wrapped_text)
	Return $wrapped_text
EndFunc   ;==>RawText_2_Docstring

Func LineLength_ANSI_Stripped($rawinput)
	; ******************************************************************************
	; *                 RET LENGTH OF LINE STRIPPED OF ANSI CODES                  *
	; ******************************************************************************
	$stripped_chars = 0
	; Cleanup text line of trailing @CR and spaces...
	$rawinput = StringStripCR($rawinput)
	$rawinput = StringStripWS($rawinput, $STR_STRIPTRAILING)

	; RegExPattern + Division Factor (because One-Space ANSI return 1 char, divide by 2)
	Local $RegExPattern = [ _
			"(?<!\{)(?:(?:\{(?:\[)?)[0-5]{3}|\{\[[BCGMRWXYbcgmrwxy]|\{[*BCGHMRWXYbcghmnrwxy^]|\{![BCGMRWXY])", 1, _ ; Zero-Space ANSI & Xterm Codes
			"(?<!\{)\{[_-]|\{\{", 2] ; One-Space ANSI Codes (divides by 2 total lenght, ie: `{_` = 1 char in output)
	#cs	------------------------- RegEx Patterns Explanation: --------------------------
		; ==============================================================================
		;                              Zero-Space ANSI Tags
		; ==============================================================================
		----Extract all ANSI escape seqs that don't add to output text length----

		Valid ANSI Seqs are:
		1) `{` followed by any of:
		rgybmcwx	— bright FG colors
		RGYBMCWX	— normal FG colors
		n			— normal
		*			— invert BG/FG
		!			— normal color (only followed by capital letter)
		h			— highlight on
		H			— highlight of
		^			— blink

		2) `{[` followed by any of:
		rgybmcwxn	— bright BG colors
		RGYBMCWX	— normal FG colors

		3) `{` or `{[` followed by three digits of value 0-5 (Xterm)

		Valid ANSI Seqs that will be IGNORED here are:
		1) `{_` forced white space (because it will produce 1 char!)

		2) `{-` Tab (it will produce some chars!)

		Any escaped (eg: `{{r`) or invalid ANSI Seq (eg: `{[R`) will be ignored from
		results since it will pass-through and show in Evennia output.
		; ==============================================================================
		;                              One-Space ANSI Tags
		; ==============================================================================
		----Extract all ANSI escape seqs that do add to the output text length----

		Valid ANSI Seqs are:
		1) `{_`	— forced white space : 1 char

		2) `{-`	— Tab, will produce some chars : here 1 char (can't guess real output)

		3) `{{`	— escaped ANSI codes (will output without the first `}`)

		Escaped ANSI seqs will be handled differently here.
	#ce

	For $i = 0 To UBound($RegExPattern) - 1 Step 2 ; Cycle $rawinput through RegEx patterns
		$RegExResult = StringRegExp($rawinput, $RegExPattern[$i], $STR_REGEXPARRAYGLOBALMATCH)
		If @error == 2 Then ; @error 2 = RegEx Pattern Invalid
			MsgBox(0, "RegEx Error", "Zero-Space Error: RegEx Pattern Invalid")
		ElseIf @error == 1 Then ; @error = 1 = NO ANSI SEQs FOUND! Just don't do anything
			; ------------------------------------------------------------------------------
			;                         NO relevant ANSI-Seqs captured
			; ------------------------------------------------------------------------------
			;MsgBox(0, "LineLength_ANSI_Stripped", "RegExt found NO matches")
		Else
			; ------------------------------------------------------------------------------
			;                       If ANY relevant ANSI-Seqs captured
			; ------------------------------------------------------------------------------
			$ANSI_Escapes_String = _ArrayToString($RegExResult, "")
			$stripped_chars += (StringLen($ANSI_Escapes_String)) / ($RegExPattern[$i] + 1)
			;_ArrayDisplay($RegExResult, "Results")
		EndIf
	Next
	Return StringLen($rawinput) - $stripped_chars
EndFunc   ;==>LineLength_ANSI_Stripped

Func Num_of_LeadingWS($rawline)
	; ******************************************************************************
	; *                  CALCULATE NUMBER OF LEADING WHITE SPACES                  *
	; ******************************************************************************
	Local $i
	For $i = 1 To StringLen($rawline)
		$stemp = StringLeft($rawline, $i)
		If Not StringIsSpace($stemp) Then
			Return $i - 1
		EndIf
	Next
EndFunc   ;==>Num_of_LeadingWS


Func Docstring_2_HTML($docstring)
	; ******************************************************************************
	; *                         CONVERT DOCSTRING TO HTML                          *
	; ******************************************************************************
	;;; ConsoleWrite(@CRLF & "HTML Code Before:" & @CRLF & $docstring & @CRLF) ;### Debug Console
	; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	;                            CAPTURE SPACES : {- & {_
	; //////////////////////////////////////////////////////////////////////////////
	$RegExPattern = "(?<!\{)\{[_-]"
	$docstring = StringRegExpReplace($docstring, $RegExPattern, " ")


	$docstring = SanitizeEOLs_CRLF($docstring)
	; Replace whitespaces with &nbsp;
	$docstring = StringReplace($docstring, " ", "&nbsp;", 0, $STR_NOCASESENSEBASIC)
	; Replace CRLFs with <br>....
	$linebreak_tag = "<br />" & @CRLF ; This string will be used more than once here!
	$docstring = StringReplace($docstring, @CRLF, $linebreak_tag, 0, $STR_NOCASESENSEBASIC)



	; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	;                           1st PASS - TAGS INSERTION
	; //////////////////////////////////////////////////////////////////////////////
	#cs -------------------------- First Pass Substitions ---------------------------

		First pass captures valid ANSI codes and replaces them with temporary Tags for
		the benefit of next parser (FSM).
	#ce
	$RegExPattern = "(?<!\{)(?:(?:\{(?:\[)?)[0-5]{3}|\{\[[BCGMRWXYbcgmrwxy]|\{[*BCGHMRWXYbcghmnrwxy^]|\{![BCGMRWXY])" ; Zero-Space ANSI & Xterm Codes

	$docstring = StringRegExpReplace($docstring, $RegExPattern, "<!~\0~!>")
	If @error <> 0 Then ; @error non-0 = Failure...
		MsgBox(0, "REGEX", "HTML RegEx Error: " & @error & " | Offset: " & @extended)
	Else
		;MsgBox(0, "REGEX", "HTML RegEx Replaced = " & @extended)
	EndIf

	; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	;                             2nd PASS - FSM MACHINE
	; //////////////////////////////////////////////////////////////////////////////

	; ==============================================================================
	;                                 FSM Variables
	; ==============================================================================
	; What class will be implemented is determined by a FSM which carries on
	; previous ANSI states through some variables:
	$SPAN_Open = False; Boolean: if there is an open </span> going on...
	$Hilight = False ; Boolean: corresponds to {H / {h
	$XtermedFG = False ; Boolean: True if FB is an ANSI converted to Xterm col because a BG-Bright was inverted.
	$XtermedBG = False ; Boolean: True if BG is an ANSI converted to Xterm col because is Bright.
	$Xterm_FG_Color = "" ; Current Xterm Color value of FG (if any)
	$Xterm_BG_Color = "" ; Current Xterm Color value of BG (if any)
	$FG_Color = "Wn" ; Current ANSI FG color, any of the following:
	#cs ------ CSS ANSI colors classes ------
		Yn : Black_Dark		bB: Black_Bright
		Rn : Red_Dark		rB: Red_Bright
		Gn : Green_Dark		gB: Green_Bright
		Yn : Yellow_Dark	yB: Yellow_Bright
		Bn : Blue_Dark		bB: Blue_Bright
		Mn : Magenta_Dark	mB: Magenta_Bright
		Cn : Cyan_Dark		cB: Cyan_Bright
		Wn : White_Dark		wB: White_Bright
	#ce
	$BG_Color = "BGXn" ; Current ANSI BG color, any of the above preceeded by "BG".
	$Inverted = False ; Boolean: corresponds to {* and can be used only once (if self = false)


	; ==============================================================================
	;                                  Extract Tags
	; ==============================================================================
	$matches = 0 ; holds number of RegEx matches
	$RegExPattern = "<!~[\d!*A-Z[a-z{]+~!>"
	$RegExResults = StringRegExp($docstring, $RegExPattern, $STR_REGEXPARRAYGLOBALMATCH)
	If @error <> 0 Then ; @error non-0 = Either no Matches or Failure...
		If @error == 2 Then ; @error = 2 = Bad Pattern
			MsgBox(0, "REGEX", "HTML RegEx Error:  Bad pattern " & @error & " | Offset: " & @extended)
		ElseIf @error == 1 Then ; @error = 1 = No matches
			;MsgBox(0, "REGEX", "HTML  Extract Tags RegEx No matches found")
			$matches = 0
			; POSSO METTERE QUI UN RETURN SE NON DEVE FARE ALTRO!
		EndIf
	Else ; Everything fine, some matches found.
		$matches = UBound($RegExResults)
		; MsgBox(0, "REGEX", "HTML RegEx matches found = " & $matches)
	EndIf

	; ******************************************************************************
	; *                          Cycle Through Temp-Tags                           *
	; ******************************************************************************
	$HTML_tag = "" ; Holder of final substitution tag
	$HTML_SPAN_CLOSE = ""
	$HTML_SPAN_OPEN = ""
	$Prev_Tag_Open = False ; if there was a preeceding <SPAN>
	$Curr_Tag_Open = False ; if current tag produces a <SPAN>
	For $i = 0 To $matches - 1
		$skip_HTML_tag_build = False ; put here because {n will set it to false!
		$tag = StringTrimLeft($RegExResults[$i], 4) ; Remove tag-open and {
		$tag = StringTrimRight($tag, 3) ; Remove tag-close
		;If $i < 4 Then MsgBox(0, "", "Tag = " & $tag)
		If StringLen($tag) >= 3 Then ; it's an Xterm {### or {[###
			; ==============================================================================
			;                                   Xterm Tag
			; ==============================================================================
			; Extract the 3 values and calculate Hex color
			$Xterm_Hex_Color = "#" ; reset color holder
			For $j = 2 To 0 Step -1
				$XtermValue = StringMid($tag, StringLen($tag) - $j, 1)
				Switch $XtermValue
					Case 0
						$Xterm_Hex_Color &= "00"
					Case 1
						$Xterm_Hex_Color &= "5F"
					Case 2
						$Xterm_Hex_Color &= "87"
					Case 3
						$Xterm_Hex_Color &= "AF"
					Case 4
						$Xterm_Hex_Color &= "D7"
					Case 5
						$Xterm_Hex_Color &= "FF"
				EndSwitch
			Next

			If StringLen($tag) == 4 Then ; It's an Xterm BG
				$Xterm_BG_Color = $Xterm_Hex_Color
				$BG_Color = ""
			Else ; It's an Xterm FG
				$Xterm_FG_Color = $Xterm_Hex_Color
				$FG_Color = ""
			EndIf
			; Xterm forces reset of all ANSI...
			; $Hilight = False;

		ElseIf StringLen($tag) == 2 Then ; it's either `{[` or `{!`
			If StringLeft($tag, 1) == "[" Then
				; ==============================================================================
				;                                     {[ Tag
				; ==============================================================================
				$tag_code = StringRight($tag, 1)
				If StringIsUpper($tag_code) Then
					; --------- Normal Color ---------
					$Temp_Color = $tag_code & "n"
					$Xterm_BG_Color = ""
					If $Inverted And $XtermedBG == False Then
						; ------------------------------------------------------------------------------
						;                         Inverted ANSI Swaps References
						; ------------------------------------------------------------------------------
						$FG_Color = $Temp_Color
					Else
						; ------------------------------------------------------------------------------
						;                  Otherwise Normal Behavior: Color goes to BG
						; ------------------------------------------------------------------------------
						$BG_Color = "BG" & $Temp_Color
						$XtermedBG = False
					EndIf
				Else ; --------- Bright Color ---------
					$BG_Color = "BG" & $tag_code & "B"
					$XtermedBG = True
					$Xterm_BG_Color = ""
				EndIf
			Else
				; ==============================================================================
				;                                     Tag {!
				; ==============================================================================
				If $Hilight Then
					$FG_Color = StringLower(StringRight($tag, 1)) & "B"
				Else
					$FG_Color = StringRight($tag, 1) & "n"
				EndIf
			EndIf
		Else ; it's a 1 char tag...
			$tag_code = StringLeft($tag, 1)
			If $tag_code == "n" Then
				; ==============================================================================
				;                             {n Normalize ANSI Tag
				; ==============================================================================
				; Correct tagThere will be no opening span after...
				;If $SPAN_Open Then $HTML_tag = "</span>"
				$HTML_tag = ""
				$Curr_Tag_Open = False
				$skip_HTML_tag_build = True
				; Reset all ANSI variables
				$BG_Color = "BGXn"
				$FG_Color = "Wn"
				$Xterm_BG_Color = ""
				$Xterm_FG_Color = ""
				$XtermedBG = False
				$XtermedFG = False
				$Hilight = False
				$Inverted = False
			ElseIf $tag_code == "h" Then
				; ==============================================================================
				;                               {h - Hightlight On
				; ==============================================================================
				$Hilight = True
				$FG_Color = StringLower(StringLeft($FG_Color, 1)) & "B"
			ElseIf $tag_code == "H" Then
				; ==============================================================================
				;                              {h - Hightlight Off
				; ==============================================================================
				$Hilight = False
				$FG_Color = StringUpper(StringLeft($FG_Color, 1)) & "n"

			ElseIf $tag_code = "*" Then
				; ==============================================================================
				;                                   {* Inverse
				; ==============================================================================
				If $Inverted Then ; doesn't work twice in a row: leave things unchanged
					$HTML_tag = "" ; Replace temp-tag with nothing
					$skip_HTML_tag_build = True
				Else
					$BG_Color_Old = $BG_Color
					$FG_Color_Old = $FG_Color
					$XtermedBG_Old = $XtermedBG
					$XtermedFG_Old = $XtermedFG
					$Xterm_BG_Color_Old = $Xterm_BG_Color
					$Xterm_FG_Color_Old = $Xterm_FG_Color
					If $Xterm_FG_Color_Old == "" Then
						; ------------------------------------------------------------------------------
						;                                 ANSI FG --> BG
						; ------------------------------------------------------------------------------
						If Not $XtermedBG Then
							; If not Xtermed: Convert new ANSI BG color always to normal/dark
							$BG_Color = "BG" & StringUpper(StringLeft($FG_Color_Old, 1)) & "n"
						Else
							; if Xtermed, BG accepts Bright colors too
							$BG_Color = "BG" & $FG_Color_Old
						EndIf
						$Xterm_BG_Color = ""
					Else
						; ------------------------------------------------------------------------------
						;                                Xterm FG --> BG
						; ------------------------------------------------------------------------------
						$Xterm_BG_Color = $Xterm_FG_Color_Old
						$XtermedBG = True
					EndIf
					If $Xterm_BG_Color_Old == "" Then
						; ------------------------------------------------------------------------------
						;                                 ANSI BG --> FG
						; ------------------------------------------------------------------------------
						If $Hilight Then
							$FG_Color = StringLower(StringMid($BG_Color_Old, 3, 1)) & "B"
						Else
							$FG_Color = StringUpper(StringMid($BG_Color_Old, 3, 1)) & "n"
						EndIf
						If $XtermedBG_Old == True Then
							$XtermedFG = True
						Else
							$XtermedFG = False
						EndIf
						$Xterm_FG_Color = ""
					Else
						; ------------------------------------------------------------------------------
						;                                Xterm BG --> FG
						; ------------------------------------------------------------------------------
						$Xterm_FG_Color = $Xterm_BG_Color_Old
						$XtermeFG = True

					EndIf
					$Inverted = True
				EndIf
			Else ; only possibility left...
				; ==============================================================================
				;                              { FG ANSI Color Tag
				; ==============================================================================

				If StringIsUpper($tag_code) Then
					; ------------------------------------------------------------------------------
					;                                  Normal Color
					; ------------------------------------------------------------------------------
					$FG_Color = $tag_code & "n"
					$Hilight = False
				Else
					; ------------------------------------------------------------------------------
					;                                  Bright Color
					; ------------------------------------------------------------------------------
					$FG_Color = $tag_code & "B"
					$Hilight = True
				EndIf
				$XtermedFG = False
			EndIf
		EndIf
		If $tag <> "{n" And $tag <> "{*" Then
			; Unless tag is {n or {* we are dealing with an active <SPAN>
			; In case of {* it will be left as it was
			$Curr_Tag_Open = True
		EndIf
		; ==============================================================================
		;                              BUILD THE HTML TAGS
		; ==============================================================================
		If Not $skip_HTML_tag_build Then ; Will skip if tag was {n or second {* in a row
			$HTML_tag = "<span " ; Common part of all HTML tags
			$SPAN_Open = True ; because it will not exceute if was {n

			; ------------------------------------------------------------------------------
			;                        If Any Xterm color, use "style"
			; ------------------------------------------------------------------------------
			If $Xterm_BG_Color <> "" Or $Xterm_FG_Color <> "" Then
				$HTML_tag &= 'style="'
				If $Xterm_BG_Color <> "" Then
					$HTML_tag &= "background:" & $Xterm_BG_Color & ";"
				EndIf
				If $Xterm_FG_Color <> "" Then
					$HTML_tag &= "color:" & $Xterm_FG_Color
				EndIf
				$HTML_tag &= '"'
			EndIf
			If $Xterm_BG_Color <> "" And $Xterm_FG_Color <> "" Then ; both BG & FG Xterm = No ANSI
				$skip_HTML_tag_build = True
			EndIf
			If Not $skip_HTML_tag_build Then
				$HTML_tag &= ' class="'
				If $BG_Color <> "" Then
					$HTML_tag &= $BG_Color & " "
				EndIf
				If $FG_Color <> "" Then
					$HTML_tag &= $FG_Color
				EndIf
				$HTML_tag &= '"'
			EndIf
			$HTML_tag &= ">" ; (common) close tag
		EndIf
		; ------------------------------------------------------------------------------
		;                         Replace Temp-Tag with HTML tag
		; ------------------------------------------------------------------------------
		$Final_HTML_tag = $HTML_tag
		If $Prev_Tag_Open Then
			$Final_HTML_tag = "</span>" & $HTML_tag
		EndIf
		$current_tag_start_pos = StringInStr($docstring, $RegExResults[$i])
		$docstring = StringReplace($docstring, $RegExResults[$i], $Final_HTML_tag, 1)
		;MsgBox(0, "", "HTML Tag = " & $HTML_tag)
		; ==============================================================================
		;                             Check for Line-Breaks
		; ==============================================================================
		; any </ br> will require <SPAN> closure and reopening IF THERE IS AN OPEN TAG!
		If $Curr_Tag_Open Then
			$current_tag_end_pos = $current_tag_start_pos + StringLen($Final_HTML_tag)

			If $i < $matches - 1 Then ;If this was not last element in cycle!
				$next_tag_start_pos = StringInStr($docstring, $RegExResults[$i + 1])
				$temp_docstring2 = StringMid($docstring, $current_tag_end_pos, $next_tag_start_pos - $current_tag_end_pos)
				$temp_docstring3 = StringMid($docstring, $next_tag_start_pos, StringLen($docstring) - $next_tag_start_pos + 1)
			Else ;If this WAS last element in cycle!
				$next_tag_start_pos = StringLen($docstring)
				$temp_docstring2 = StringTrimLeft($docstring, StringLen($docstring) - $current_tag_end_pos - 1)
				$temp_docstring3 = ""
			EndIf
			; Split all $docstring into thre parts...
			$temp_docstring1 = StringLeft($docstring, $current_tag_end_pos - 1)

			$matched_linebreak = StringInStr($docstring, $linebreak_tag, Default, 1, $current_tag_end_pos, $next_tag_start_pos - $current_tag_end_pos)
			If $matched_linebreak <> 0 Then
				; ------------------------------------------------------------------------------
				;                               Line-Breaks Found!
				; ------------------------------------------------------------------------------
				; Split all $docstring into thre parts...
				;MsgBox(0, "", "$temp_docstring1 = " & @CRLF & $temp_docstring1 & @CRLF & "$temp_docstring2 = " & $temp_docstring2 & @CRLF & "$temp_docstring3 = " & @CRLF & $temp_docstring3 )
				; ------------------------------------------------------------------------------
				;                        Change all </ br> in Temp String
				; ------------------------------------------------------------------------------
				$Substitute_HTML_LineBreak = ""
				If $Prev_Tag_Open Then
					$Substitute_HTML_LineBreak = "</span>"
				EndIf
				$Substitute_HTML_LineBreak &= $linebreak_tag & $HTML_tag
				$temp_docstring2 = StringReplace($temp_docstring2, $linebreak_tag, $Substitute_HTML_LineBreak, 0, 2)
				If @error == 1 Then MsgBox(0, "ERROR", "Temp docstring 2 problems")
				$docstring = $temp_docstring1 & $temp_docstring2 & $temp_docstring3

			EndIf
		EndIf
		If $Curr_Tag_Open Then $Prev_Tag_Open = True
	Next
	; \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	;                         CAPTURE & CLEAN ESCAPE SEQS {{
	; //////////////////////////////////////////////////////////////////////////////

	$RegExPattern = "\{\{"
	$docstring = StringRegExpReplace($docstring, $RegExPattern, "{")

	;;; ConsoleWrite(@CRLF & "HTML Code After:" & @CRLF & $docstring & @CRLF) ;### Debug Console
	Return $docstring
EndFunc   ;==>Docstring_2_HTML

Func SanitizeEOLs_CRLF($rawtext)
	; ******************************************************************************
	; *                             SANITIZE TEXT EOFs                             *
	; ******************************************************************************
	; NOTE: Edit control will not wrap with @CR or @LF only. Must use @CRLF.

	; RegEx will capture all @CRLF, @CR, @LF (with @CRLF being atomically unbreakable)
	; \R matches "(?>\r\n|\n|\r)" where "(?>...)" is an atomic group, making the
	; sequence "\r\n" (@CRLF) unbreakable.

	$sanitazedstring = StringRegExpReplace($rawtext, "(\R)", @CRLF)
	If @error Then
		MsgBox(0, "REGEX", "RegEx Failed!")
	Else
		;MsgBox(0, "REGEX", "RegEx changed:" & @extended)
		;;; ConsoleWrite(@CRLF & "--> Sanitized " & @extended & " EOLs to @CRLF")
	EndIf
	; ------------------------------------------------------------------------------
	;                            Remove Duplicate @CRLFs
	; ------------------------------------------------------------------------------
	While True
		$sanitazedstring = StringReplace($sanitazedstring, @CRLF & @CRLF, @CRLF)
		If @extended == 0 Then ExitLoop
	WEnd
	Return $sanitazedstring
EndFunc   ;==>SanitizeEOLs_CRLF



Func HTML_Boilerplate()
	; ******************************************************************************
	; *                              HTML Boilerplate                              *
	; ******************************************************************************
	; ==============================================================================
	;                              ANSI Colors Palette
	; ==============================================================================
	Local $Black_Dark = "#000000", $Black_Bright = "#808080" ; * | Darkgray
	Local $Red_Dark = "#800000", $Red_Bright = "#FF0000"
	Local $Green_Dark = "#008000", $Green_Bright = "#00FF00"
	Local $Yellow_Dark = "#808000", $Yellow_Bright = "#FFFF00" ; Brown | *
	Local $Blue_Dark = "#000080", $Blue_Bright = "#0000FF"
	Local $Magenta_Dark = "#800080", $Magenta_Bright = "#FF00FF"
	Local $Cyan_Dark = "#008080", $Cyan_Bright = "#00FFFF"
	Local $White_Dark = "#C0C0C0", $White_Bright = "#FFFFFF" ; Gray | *
	;----------------------------------------------
	$HTML_Code = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' & @CRLF
	$HTML_Code &= '<html xmlns="http://www.w3.org/1999/xhtml">' & @CRLF
	$HTML_Code &= '<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" />' & @CRLF
	$HTML_Code &= '<style type="text/css">' & @CRLF
	$HTML_Code &= '<!--' & @CRLF
	$HTML_Code &= 'body { font-family: FixedSys; font-size:14px; font-weight: bold; }' & @CRLF
	; ------------------------------------------------------------------------------
	;               Red Green Yellow Blue Magenta Cyan White X =black
	; ------------------------------------------------------------------------------
	$HTML_Code &= '.Xn { color: #000000; }' & @CRLF
	$HTML_Code &= '.Rn { color: #BB0000; }' & @CRLF
	$HTML_Code &= '.Gn { color: #00BB00; }' & @CRLF
	$HTML_Code &= '.Yn { color: #BBBB00; }' & @CRLF
	$HTML_Code &= '.Bn { color: #0000BB; }' & @CRLF
	$HTML_Code &= '.Mn { color: #BB00BB; }' & @CRLF
	$HTML_Code &= '.Cn { color: #00BBBB; }' & @CRLF
	$HTML_Code &= '.Wn, body {	color: #BBBBBB; }' & @CRLF
	;----------------------------------------------
	$HTML_Code &= '.xB { color: #555555; }' & @CRLF
	$HTML_Code &= '.rB { color: #FF5555; }' & @CRLF
	$HTML_Code &= '.gB { color: #55FF55; }' & @CRLF
	$HTML_Code &= '.yB { color: #FFFF55; }' & @CRLF
	$HTML_Code &= '.bB { color: #5555FF; }' & @CRLF
	$HTML_Code &= '.mB { color: #FF55FF; }' & @CRLF
	$HTML_Code &= '.cB { color: #55FFFF; }' & @CRLF
	$HTML_Code &= '.wB { color: #FFFFFF; }' & @CRLF
	;----------------------------------------------
	$HTML_Code &= '.BGXn, body { background: #000000; }' & @CRLF
	$HTML_Code &= '.BGRn { background: #BB0000; }' & @CRLF
	$HTML_Code &= '.BGGn { background: #00BB00; }' & @CRLF
	$HTML_Code &= '.BGYn { background: #BBBB00; }' & @CRLF
	$HTML_Code &= '.BGBn { background: #0000BB; }' & @CRLF
	$HTML_Code &= '.BGMn { background: #BB00BB; }' & @CRLF
	$HTML_Code &= '.BGCn { background: #00BBBB; }' & @CRLF
	$HTML_Code &= '.BGWn {	background: #BBBBBB; }' & @CRLF
	;----------------------------------------------
	$HTML_Code &= '.BGxB { background: #555555; }' & @CRLF
	$HTML_Code &= '.BGrB { background: #FF5555; }' & @CRLF
	$HTML_Code &= '.BGgB { background: #55FF55; }' & @CRLF
	$HTML_Code &= '.BGyB { background: #FFFF55; }' & @CRLF
	$HTML_Code &= '.BGbB { background: #5555FF; }' & @CRLF
	$HTML_Code &= '.BGmB { background: #FF55FF; }' & @CRLF
	$HTML_Code &= '.BGcB { background: #55FFFF; }' & @CRLF
	$HTML_Code &= '.BGwB { background: #FFFFFF; }' & @CRLF
	;----------------------------------------------
	$HTML_Code &= '-->' & @CRLF
	$HTML_Code &= '</style></head><body>' & @CRLF
	$HTML_Code &= '</body></html>' & @CRLF
	Return $HTML_Code
EndFunc   ;==>HTML_Boilerplate










