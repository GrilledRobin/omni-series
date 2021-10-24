%macro VBS_CrFn_StrConv(
	VBSFile	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|VBSFile	:	The VBS file defining public functions.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140913		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This function ALMOST resembles the same one as in VB or VBA																		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%local
	L_mcrLABEL
;
%let	L_mcrLABEL	=	&sysMacroName.;

%*100.	Generate VB Script.;
data _NULL_;
	file "&VBSFile.";

	put	"Public Const vbUpperCase    = 1";
	put	"Public Const vbLowerCase    = 2";
	put	"Public Const vbProperCase   = 3";
	put	"Public Const vbWide         = 4";
	put	"Public Const vbNarrow       = 8";
	put	"Public Const vbUnicode      = 64";
	put	"Public Const vbFromUnicode  = 128";
	put;
	put	"Public Function StrConv(ByVal varIn, ByVal iConv)";
	put	"    Dim i, c";
	put	"    Dim ret";
	put	"    Select Case iConv";
	put	"    Case vbUpperCase";
	put	"        ret = UCase(varIn)";
	put	"    Case vbLowerCase";
	put	"        ret = LCase(varIn)";
	put	"    Case vbProperCase";
	put	"        Dim tmp";
	put	"        tmp = Split(varIn, "" "")";
	put	"        For i = 0 To UBound(tmp)";
	put	"            ret = ret & UCase(Mid(tmp(i), 1, 1)) & Mid(tmp(i), 2)";
	put	"        Next";
	put	"    Case vbWide";
	put	"        For i = 1 To Len(varIn)";
	put	"            c = AscW(Mid(varIn, i, 1))";
	put	"            If c < 0 Then c = c + 65536";
	put	"            If c = 32 Then";
	put	"                ret = ret & ChrW(12288)";
	put	"            ElseIf c < 128 Then";
	put	"                ret = ret & ChrW(c + 65248)";
	put	"            Else";
	put	"                ret = ret & ChrW(c)";
	put	"            End If";
	put	"        Next";
	put	"    Case vbNarrow";
	put	"        For i = 1 To Len(varIn)";
	put	"            c = AscW(Mid(varIn, i, 1))";
	put	"            If c < 0 Then c = c + 65536";
	put	"            If c = 12288 Then";
	put	"                ret = ret & ChrW(32)";
	put	"            ElseIf c > 65280 And c < 65375 Then";
	put	"                ret = ret & ChrW(c- 65248)";
	put	"            Else";
	put	"                ret = ret & ChrW(c)";
	put	"            End If";
	put	"        Next";
	put	"    Case vbUnicode";
	put	"        For i = 1 To LenB(varIn)";
	put	"            c = AscB(MidB(varIn, i, 1))";
	put	"            If c < 0 Then c = c + 65536";
	put	"            If c = 0 Then";
	put	"                'Pass";
	put	"            ElseIf c < 128 Then";
	put	"                ret = ret & Chr(c)";
	put	"            Else";
	put	"                c = LShift(c, 8) Or AscB(MidB(varIn, i + 1, 1))";
	put	"                ret = ret & Chr(c)";
	put	"                i = i + 1";
	put	"            End If";
	put	"        Next";
	put	"    Case vbFromUnicode";
	put	"        For i = 1 To Len(varIn)";
	put	"            c = Asc(Mid(varIn, i, 1))";
	put	"            If c < 0 Then c = c + 65536";
	put	"            If c < 128 Then";
	put	"                ret = ret & ChrB(c)";
	put	"                ret = ret & ChrB(0)";
	put	"            Else";
	put	"                ret = ret & ChrB(RShift(c, 8))";
	put	'                ret = ret & ChrB(c And &HFF)';
	put	"            End If";
	put	"        Next";
	put	"    End Select";
	put	"    StrConv = ret";
	put	"End Function";
	put;
	put	"Public Function RShift(ByVal lValue, ByVal iShiftBits)";
	put	"    RShift = lValue \ (2 ^ iShiftBits)";
	put	"End Function";
	put;
	put	"Public Function LShift(ByVal lValue, ByVal iShiftBits)";
	put	"    LShift = lValue * (2 ^ iShiftBits)";
	put	"End Function";
run;

%EndOfProc:
%mend VBS_CrFn_StrConv;