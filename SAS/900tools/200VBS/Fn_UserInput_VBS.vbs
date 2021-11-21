' VBScript sample using Windows Script Host
'Set WshShell = WScript.CreateObject("WScript.Shell")
'WshShell.Popup "Hello World!"
'*000.	Info.;
'*-------------------------------------------------------------------------------------------------------------------------------------*'
'100.	Introduction.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|This script is to define a function for user input, adapting both [CSCRIPT.EXE] call and direct script execution.					'
'	|___________________________________________________________________________________________________________________________________'
'	|This function prompts the user for some input.																						'
'	|When the script runs in CSCRIPT.EXE, StdIn is used, otherwise the VBScript InputBox( ) function is used.							'
'	|The function returns the input typed either on StdIn or in InputBox( ).															'
'	|http://www.robvanderwoude.com																										'
'	|___________________________________________________________________________________________________________________________________'
'	|Windows version	:	All																											'
'	|Network			:	N/A																											'
'	|Client software	:	Windows Script 5.6 for Windows 98, ME, and NT 4																'
'	|Script Engine		:	WSH																											'
'	|Summarized			:	Works in any Windows version, provided Windows Script 5.6 for Windows 98, ME, and NT 4 is installed for		'
'	|						 Windows 98, ME, and NT 4																					'
'---------------------------------------------------------------------------------------------------------------------------------------'
'200.	Glossary.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|myPrompt	:	The prompt message to show up once the input box is popping up														'
'	|Returns	:	The value retrieved from user input																					'
'---------------------------------------------------------------------------------------------------------------------------------------'
'300.	Update log.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	| Date |	20170909		| Version |	1.00		| Updater/Creator |	Rob van der Woude											'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |Version 1.																													'
'	|______|____________________________________________________________________________________________________________________________'
'---------------------------------------------------------------------------------------------------------------------------------------'
'400.	User Manual.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|[1] Call this script to define the public fuction																					'
'	|[2] Provide the Prompt Message while calling this function during your own script													'
'	|[3] Execute your script and wait until the input box pops up																		'
'	|[4] Enter proper text based on the predefined Prompt Message																		'
'---------------------------------------------------------------------------------------------------------------------------------------'
'500.	Dependent Scripts.																												'
'---------------------------------------------------------------------------------------------------------------------------------------'
'*-------------------------------------------------------------------------------------------------------------------------------------*'

Public Function UserInput( myPrompt )
    ' Check if the script runs in CSCRIPT.EXE
    If UCase( Right( WScript.FullName, 12 ) ) = "\CSCRIPT.EXE" Then
        ' If so, use StdIn and StdOut
        WScript.StdOut.Write myPrompt & " "
        UserInput = WScript.StdIn.ReadLine
    Else
        ' If not, use InputBox( )
        UserInput = InputBox( myPrompt )
    End If
End Function

'* Examples Begin ---------------------------------------------------------------------------------------------------------------------*'
'100.	Direct call of the function.																									'
'	strInput = UserInput( "Enter some input:" )																							'
'	WScript.Echo "You entered: " & strInput																								'
'* Examples End   ---------------------------------------------------------------------------------------------------------------------*'