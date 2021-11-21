' VBScript sample using Windows Script Host
'Set WshShell = WScript.CreateObject("WScript.Shell")
'WshShell.Popup "Hello World!"
'*000.	Info.;
'*-------------------------------------------------------------------------------------------------------------------------------------*'
'100.	Introduction.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|This script is to define a class for user to instantiate Internet Explorer to display one or more forms, and then collect the		'
'	| values based on the input that the operator writes or the options that the user selects.											'
'	|___________________________________________________________________________________________________________________________________'
'	|This class uses Internet Explorer to create a dialog and prompt for user input or selections.										'
'	|Error handling code written by Denis St-Pierre																						'
'	|http://www.robvanderwoude.com																										'
'	|___________________________________________________________________________________________________________________________________'
'	|Windows version	:	ANY																											'
'	|Network			:	ANY																											'
'	|Client software	:	Internet Explorer 4 or later																				'
'	|Script Engine		:	WSH (CSCRIPT and WSCRIPT)																					'
'	|						 (to use in HTAs, remove both WScript.Sleep lines)															'
'	|Summarized			:	Works in all Windows versions with Internet Explorer 4 or later, remove both WScript.Sleep lines to use in	'
'	|						 HTAs.																										'
'---------------------------------------------------------------------------------------------------------------------------------------'
'200.	Glossary.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|210.	Properties.																													'
'   |-----------------------------------------------------------------------------------------------------------------------------------'
'	|              Name              | R/W |   Type   |                                  Description                                    '
'   |--------------------------------|-----|----------|---------------------------------------------------------------------------------'
'	|IEWinRSize                      | R/W |  Boolean |Set or Retrieve the attribute of whether the IE Window is re-sizable             '
'	|                                |     |          |Parameters (when used as LET property):                                          '
'	|                                |     |          |[myInput]: The BOOLEAN value to imply whether the window is re-sizable.          '
'	|IEWinTBar                       | R/W |  Boolean |Set or Retrieve the attribute of whether to show Tool Bar in the IE Window       '
'	|                                |     |          |Parameters (when used as LET property):                                          '
'	|                                |     |          |[myInput]: The BOOLEAN value to imply whether to show Tool Bar.                  '
'	|IEWinTitle                      | R/W |  String  |Set or Retrieve the Title of the IE Window                                       '
'	|                                |     |          |Parameters (when used as LET property):                                          '
'	|                                |     |          |[myInput]: The character string to show in the Title Bar.                        '
'	|IEWinHeight                     | R/W |   Long   |Set or Retrieve the height of the IE Window, it will initialize the height as    '
'	|                                |     |          | what is input once it is used as LET property hence please be cautious.         '
'	|                                |     |          |Parameters (when used as LET property):                                          '
'	|                                |     |          |[myInput]: The number of pixels                                                  '
'	|IEWinWidth                      | R/W |   Long   |Set or Retrieve the width of the IE Window, it will initialize the width as      '
'	|                                |     |          | what is input once it is used as LET property hence please be cautious.         '
'	|                                |     |          |Parameters (when used as LET property):                                          '
'	|                                |     |          |[myInput]: The number of pixels                                                  '
'	|ValByFormName                   |  R  | (Various)|Retrieve the value of the provided Form Name (also the internal Form ID)         '
'	|                                |     |          |Parameters:                                                                      '
'	|                                |     |          |[myForm]: The name of the form of which to retrieve the value                    '
'   |-----------------------------------------------------------------------------------------------------------------------------------'
'	|220.	Methods.																													'
'   |-----------------------------------------------------------------------------------------------------------------------------------'
'	|              Name              |                                          Description                                             '
'   |--------------------------------|--------------------------------------------------------------------------------------------------'
'	|crDropDown                      |Create a form of Dropdown Box Selection in the <div>, with a Prompt Message to be defined.        '
'	|                                |Parameters:                                                                                       '
'	|                                |[myName]:   The ID of the form (Please ensure the names unique during input)                      '
'	|                                |[myPrompt]: The prompt message showing just above the current form.                               '
'	|                                |[myWidth]:  The number of pixels as the width of the form.                                        '
'	|                                |[ArraySel]: The array that holds the options to show up in the Dropdown list.                     '
'   |--------------------------------|--------------------------------------------------------------------------------------------------'
'	|crCheckBox                      |Create a form of CheckBox in the <div>, with a Prompt Message to be defined.                      '
'	|                                |Parameters:                                                                                       '
'	|                                |[myName]:      The ID of the form (Please ensure the names unique during input)                   '
'	|                                |[myPrompt]:    The prompt message showing just above the current form.                            '
'	|                                |[ArraySel]:    The array that holds the options to show up in the Check List.                     '
'	|                                |[myDirection]: "H" or "V", indicating whether the options are placed Horizontally or Vertically.  '
'   |--------------------------------|--------------------------------------------------------------------------------------------------'
'	|crInputBox                      |Create a form of Input Box in the <div>, with a Prompt Message to be defined.                     '
'	|                                |Parameters:                                                                                       '
'	|                                |[myName]:   The ID of the form (Please ensure the names unique during input)                      '
'	|                                |[myPrompt]: The prompt message showing just above the current form.                               '
'	|                                |[mySize]:   The size of the form to receive the input message.                                    '
'   |--------------------------------|--------------------------------------------------------------------------------------------------'
'	|crRadioBox                      |Create a form of Radio (single Selection) in the <div>, with a Prompt Message to be defined.      '
'	|                                |Parameters:                                                                                       '
'	|                                |[myName]:      The ID of the form (Please ensure the names unique during input)                   '
'	|                                |[myPrompt]:    The prompt message showing just above the current form.                            '
'	|                                |[ArraySel]:    The array that holds the options to show up in the Single Selection List.          '
'	|                                |[myDirection]: "H" or "V", indicating whether the options are placed Horizontally or Vertically.  '
'   |--------------------------------|--------------------------------------------------------------------------------------------------'
'	|DisplayForms                    |Startup the Internet Explorer and display all the forms that are defined by user                  '
'	|                                |Parameters:                                                                                       '
'	|                                |[myPrompt]: The prompt message showing in the first line above all forms.                         '
'	|                                |Returns: [Array: DisplayForms( 1 , n )]                                                           '
'	|                                |[DisplayForms( 0 , n )]: The Form Name of [n]th definition                                        '
'	|                                |[DisplayForms( 1 , n )]: The Array of Values of [n]th definition as per user interaction          '
'	|                                |-[DisplayForms( 1 , n )( 0 , m )]: The Sequence Number of [m]th element in the [n]th definition   '
'	|                                |-[DisplayForms( 1 , n )( 1 , m )]: The Value of [m]th element in the [n]th definition             '
'	|___________________________________________________________________________________________________________________________________'
'---------------------------------------------------------------------------------------------------------------------------------------'
'300.	Update log.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	| Date |	2017-09-28		| Version |	1.00		| Updater/Creator |	Robin Lu Bin												'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |Version 1.																													'
'	|______|____________________________________________________________________________________________________________________________'
'	|___________________________________________________________________________________________________________________________________'
'	| Date |	20171015		| Version |	2.00		| Updater/Creator |	Robin Lu Bin												'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |(1) Create additional arrays for the forms to store the values when there are more than one, such as Check Boxes.			'
'	|      |    The returned array now contains additional arrays.																		'
'	|      |(2) Add additional forms: [Radio] and [CheckBox]																			'
'	|______|____________________________________________________________________________________________________________________________'
'---------------------------------------------------------------------------------------------------------------------------------------'
'400.	User Manual.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|[1] Call this script to define the class																							'
'	|[2] Set the user-defined messages and properties after creating new object with this class during your own script					'
'	|[3] Execute your script and wait until the IE Box with forms pops up																'
'	|[4] Input messages or make selections based on the predefined forms and click OK													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'500.	Dependent Scripts.																												'
'---------------------------------------------------------------------------------------------------------------------------------------'
'*-------------------------------------------------------------------------------------------------------------------------------------*'

Class IEForms

'001.	Define all local variables
Private arrValues() , fNoFormID , idxLast , strFormID , L_FormCnt , strDiv , strSubmit , HtmBr , Ai , Aj , Ak , Ti
Private objIE , strTitle , BlnToolBar , BlnResize, BlnStsBar , WinWidth , WinHeight

'050.	Initialize the variables when the class is initialized
Private Sub Class_Initialize
	ReDim Preserve arrValues( 1 , 0 )
	fNoFormID	=	True
	idxLast		=	0
	strTitle	=	"VBScript Forms By IE"
	BlnToolBar	=	False
	BlnResize	=	False
	BlnStsBar	=	False
	WinWidth	=	320
	WinHeight	=	80
End Sub

'100.	Define the Readable Properties (Get Property).
'101.	Retrieve the Title of the IE window.
Public Property Get IEWinTitle
	IEWinTitle	=	strTitle
End Property

'102.	Retrieve the attribute of whether to show Tool Bar in the window.
Public Property Get IEWinTBar
	IEWinTBar	=	BlnToolBar
End Property

'103.	Retrieve the attribute of whether the window is re-sizable.
Public Property Get IEWinRSize
	IEWinRSize	=	BlnResize
End Property

'104.	Retrieve the height of the window.
Public Property Get IEWinHeight
	IEWinHeight	=	WinHeight
End Property

'105.	Retrieve the width of the window.
Public Property Get IEWinWidth
	IEWinWidth	=	WinWidth
End Property

'190.	Retrieve the value of the form by the provided name (Form ID).
'IMPORTANT: The returned value is an array [ValByFormName( 1 , N )].
'ValByFormName( 0 , N ): The Sequence Number of [N]th element among all the values.
'ValByFormName( 1 , N ): The Actual Value of [N]th element among all the values.
Public Property Get ValByFormName( myForm )
	for Ai = 0 to UBound( arrValues , 2 )
		if	myForm	=	arrValues( 0 , Ai )	then
			ValByFormName	=	arrValues( 1 , Ai )
		end if
	next
End Property

'200.	Define the Writeable Properties (Let Property).
'201.	Set the Title of the IE window.
Public Property Let IEWinTitle( myInput )
	strTitle	=	myInput
End Property

'202.	Set the attribute of whether to show Tool Bar in the window.
Public Property Let IEWinTBar( myInput )
	BlnToolBar	=	myInput
End Property

'203.	Set the attribute of whether the window is re-sizable.
Public Property Let IEWinRSize( myInput )
	BlnResize	=	myInput
End Property

'204.	Set the height of the window.
Public Property Let IEWinHeight( myInput )
	WinHeight	=	myInput
End Property

'205.	Set the width of the window.
Public Property Let IEWinWidth( myInput )
	WinWidth	=	myInput
End Property

'400.	Define the Object-Writeable Properties (Set Property).

'700.	Define all methods.
'710.	Define an Input Box.
Public Function crInputBox( myName , myPrompt , mySize )
	'010.	Setup environment.
	Dim arrVal()
	ReDim Preserve arrVal( 1 , 0 )

	'100.	Expand the array that contains the Form ID and the value to be collected.
	'110.	Retrieve the last index of the previously DIMed array of values.
	if	fNoFormID	=	False	then
		idxLast	=	UBound( arrValues , 2 ) + 1
	else
		fNoFormID	=	False
	end if

	'150.	ReDim the array.
	ReDim Preserve arrValues( 1 , idxLast )

	'200.	Create a new ID for current form.
	strFormID	=	myName

	'300.	Add the new element to the array.
	arrValues( 0 , idxLast )	=	strFormID
	arrVal( 0 , 0 )				=	1
	arrVal( 1 , 0 )				=	""

	'500.	Initialize the Form.
	L_FormCnt	=	L_FormCnt & vbCrLf & vbCrLf & "<p>" & myPrompt & "</p>" & vbCrLf _
					& "<p>" _
						& "<form action="""">" _
							& "<input type=""text"" size=""" & mySize & """ id=""" & strFormID & "_" & cstr( arrVal( 0 , 0 ) ) & """ name=""" & strFormID & "_" & cstr( arrVal( 0 , 0 ) ) & """>" _
						& "</form>" _
					& "<p>"

	'600.	Initialize the set of values.
	arrValues( 1 , idxLast )	=	arrVal

	'700.	Increase the height of the window.
	WinHeight	=	WinHeight + 120
End Function

'711.	Define a Radio Box.
Public Function crRadioBox( myName , myPrompt , ArraySel , myDirection )
	'010.	Setup environment.
	Dim arrVal()
	ReDim Preserve arrVal( 1 , 0 )
	Ti	=	0

	'050.	Handle the parameter buffer.
	myDirection	=	ucase( left( myDirection , 1 ) )
	if	myDirection	<>	"V"	then	myDirection	=	"H"

	'060.	Setup the HTML carriage return where necessary.
	if	myDirection	=	"V"	then
		HtmBr	=	"<br>"
	else
		HtmBr	=	""
	end if

	'100.	Expand the array that contains the Form ID and the value to be collected.
	'110.	Retrieve the last index of the previously DIMed array of values.
	if	fNoFormID	=	False	then
		idxLast	=	UBound( arrValues , 2 ) + 1
	else
		fNoFormID	=	False
	end if

	'150.	ReDim the array.
	ReDim Preserve arrValues( 1 , idxLast )

	'200.	Create a new ID for current form.
	strFormID	=	myName

	'300.	Add the new element to the array.
	arrValues( 0 , idxLast )	=	strFormID
	arrVal( 0 , 0 )				=	1
	arrVal( 1 , 0 )				=	""

	'500.	Initialize the Form.
	L_FormCnt	=	L_FormCnt & vbCrLf & vbCrLf & "<p>" & myPrompt & "</p>" & vbCrLf _
					& "<p>" _
						& "<form action="""">"
	for each iSel in ArraySel
		'500.	Append the options.
		L_FormCnt	=	L_FormCnt & "<input type=""Radio"" name=""" & strFormID & "_" & cstr( arrVal( 0 , 0 ) ) & """ value=""" & iSel & """>" & iSel & HtmBr

		'700.	Increase the height of the window.
		if	myDirection	=	"V"	then
			WinHeight	=	WinHeight + 20
		end if
	next
	L_FormCnt	=	L_FormCnt _
						& "</form>" _
					& "<p>"

	'600.	Initialize the set of values.
	arrValues( 1 , idxLast )	=	arrVal

	'700.	Increase the height of the window.
	WinHeight	=	WinHeight + 120
End Function

'712.	Define a Check Box.
Public Function crCheckBox( myName , myPrompt , ArraySel , myDirection )
	'010.	Setup environment.
	Dim arrVal()
	Ti	=	0

	'050.	Handle the parameter buffer.
	myDirection	=	ucase( left( myDirection , 1 ) )
	if	myDirection	<>	"V"	then	myDirection	=	"H"

	'060.	Setup the HTML carriage return where necessary.
	if	myDirection	=	"V"	then
		HtmBr	=	"<br>"
	else
		HtmBr	=	""
	end if

	'100.	Expand the array that contains the Form ID and the value to be collected.
	'110.	Retrieve the last index of the previously DIMed array of values.
	if	fNoFormID	=	False	then
		idxLast	=	UBound( arrValues , 2 ) + 1
	else
		fNoFormID	=	False
	end if

	'150.	ReDim the array.
	ReDim Preserve arrValues( 1 , idxLast )

	'200.	Create a new ID for current form.
	strFormID	=	myName

	'300.	Add the new element to the array.
	arrValues( 0 , idxLast )	=	strFormID

	'500.	Initialize the Form.
	L_FormCnt	=	L_FormCnt & vbCrLf & vbCrLf & "<p>" & myPrompt & "</p>" & vbCrLf _
					& "<p>" _
						& "<form action="""">"
	for each iSel in ArraySel
		'100.	Expand the array of values.
		'NOTE: The lower bound always starts from 0.
		ReDim Preserve arrVal( 1 , Ti )

		'300.	Initialize the array elements.
		arrVal( 0 , Ti )	=	Ti	+	1
		arrVal( 1 , Ti )	=	""

		'500.	Append the options.
		L_FormCnt	=	L_FormCnt & "<input type=""CheckBox"" id=""" & strFormID & "_" & cstr( arrVal( 0 , Ti ) ) & """ name=""" & strFormID & "_" & cstr( arrVal( 0 , Ti ) ) & """ value=""" & iSel & """>" & iSel & HtmBr

		'700.	Increase the height of the window.
		if	myDirection	=	"V"	then
			WinHeight	=	WinHeight + 20
		end if

		'900.	Increment the counter.
		Ti	=	Ti	+	1
	next
	L_FormCnt	=	L_FormCnt _
						& "</form>" _
					& "<p>"

	'600.	Initialize the set of values.
	arrValues( 1 , idxLast )	=	arrVal

	'700.	Increase the height of the window.
	WinHeight	=	WinHeight + 120
End Function

'720.	Define a Box of Dropdown List for single selection.
Public Function crDropDown( myName , myPrompt , myWidth , ArraySel )
	'010.	Setup environment.
	Dim arrVal()
	ReDim Preserve arrVal( 1 , 0 )

	'100.	Expand the array that contains the Form ID and the value to be collected.
	'110.	Retrieve the last index of the previously DIMed array of values.
	if	fNoFormID	=	False	then
		idxLast	=	UBound( arrValues , 2 ) + 1
	else
		fNoFormID	=	False
	end if

	'150.	ReDim the array.
	ReDim Preserve arrValues( 1 , idxLast )

	'200.	Create a new ID for current form.
	strFormID	=	myName

	'300.	Add the new element to the array.
	arrValues( 0 , idxLast )	=	strFormID
	arrVal( 0 , 0 )				=	1
	arrVal( 1 , 0 )				=	""

	'500.	Initialize the Form.
	L_FormCnt	=	L_FormCnt & vbCrLf & vbCrLf & "<p>" & myPrompt & "</p>" & vbCrLf _
					& "<p>" _
					& "<select id=""" & strFormID & "_" & cstr( arrVal( 0 , 0 ) ) & """ name=""" & strFormID & "_" & cstr( arrVal( 0 , 0 ) ) & """ style=""width: " & myWidth & "px"">"
	for each iSel in ArraySel
		L_FormCnt	=	L_FormCnt & "<option value=""" & iSel & """>" & iSel & "</option>"
	next
	L_FormCnt	=	L_FormCnt _
					& "</select>" _
					& "<p>"

	'600.	Initialize the set of values.
	arrValues( 1 , idxLast )	=	arrVal

	'700.	Increase the height of the window.
	WinHeight	=	WinHeight + 120
End Function

'799.	Define the method to display the forms as defined by user and collect the necessary values.
Public Function DisplayForms( myPrompt )
	'010.	Setup environment.
	Dim ObjElement

	'100.	Prepare the HTML sections
	'110.	Prepare the section of Submit button
	strSubmit	=	"<div align=""center"">" _
						& "<p>" _
							& "<input type=""hidden"" id=""OK"" name=""OK"" value=""0"">" _
							& "<input type=""submit"" value="" OK "" OnClick=""VBScript:OK.value=1"">" _
						& "</p>" _
					& "</div>"

	'120.	Construct the entire Division
	strDiv		=	"<div align=""center"">" _
						& "<p>" & myPrompt & "</p>" & vbCrLf _
						& L_FormCnt & vbCrLf _
					& "</div>" _
					& strSubmit

	'200.	Setup the IE attributes
	'201.	Create an IE object
	Set objIE	=	CreateObject( "InternetExplorer.Application" )

	'210.	Specify some of the IE window's settings
	objIE.Navigate "about:blank"
	objIE.Document.title	=	strTitle
	objIE.ToolBar			=	BlnToolBar
	objIE.Resizable			=	BlnResize
	objIE.StatusBar			=	BlnStsBar
	objIE.Width				=	WinWidth
	objIE.Height			=	WinHeight

	'220.	Center the dialog window on the screen
	' Please be ware of the case of below characters (upper or lower cases are entirely different!)
	With objIE.Document.ParentWindow.screen
		objIE.Left	=	(.AvailWidth  - objIE.Width ) \ 2
		objIE.Top 	=	(.AvailHeight - objIE.Height) \ 2
	End With

	'300.	Wait till IE is ready
	Do While objIE.Busy
	    WScript.Sleep 200
	Loop

	'400.	Control the display
	'410.	Insert the HTML code to prompt for user actions
	objIE.Document.body.innerHTML = strDiv

	'420.	Hide the scrollbars
	objIE.Document.body.style.overflow = "auto"

	'430.	Make the window visible
	objIE.Visible = True

	'440.	Set focus on input field
'	objIE.Document.all.OK.focus

	'500.	Wait till the OK button has been clicked
	On Error Resume Next
	Do While objIE.Document.all.OK.value = 0 
	    WScript.Sleep 200
	    ' Error handling code by Denis St-Pierre
	    If Err Then ' user clicked red X (or alt-F4) to close IE window
	        IELogin = Array( "", "" )
	        objIE.Quit
	        Set objIE = Nothing
	        Exit Function
	    End if
	Loop
	On Error Goto 0

	'800.	Read the user input from the dialog window
	for Ai = 0 to UBound( arrValues , 2 )
		for Aj = 0 to UBound( arrValues( 1 , Ai ) , 2 )
			'100.	Obtain the current Element in the IE Window
			'We will NOT use the function [getElementByID] as it cannot differentiate the values for "Radio".
			'There should be only one object found below, except "Radio"!
			set	ObjElement	=	objIE.Document.getElementsByName( arrValues( 0 , Ai ) & "_" & cstr( arrValues( 1 , Ai )( 0 , Aj ) ) )

			'500.	Differentiate the retrieval of values.
			for each eSel in ObjElement
				if	ucase(eSel.type)	=	"CHECKBOX"	or	ucase(eSel.type)	=	"RADIO"	then
					if	eSel.checked	=	true	then
						arrValues( 1 , Ai )( 1 , Aj )	=	eSel.value
					end if
				else
					arrValues( 1 , Ai )( 1 , Aj )	=	eSel.value
				end if
			next
		next
	next
	DisplayForms	=	arrValues

	'900.	Close and release the object
	objIE.Quit
	Set objIE	=	Nothing

End Function

End Class

'* Examples Begin ---------------------------------------------------------------------------------------------------------------------*'
'100.	Create a window with an input box and a dropdown list.																			'
'	dim myIEForms , myInputVal																											'
'	dim myArr(1)																														'
'	myArr(0)	=	"Hike"																												'
'	myArr(1)	=	"Yoga"																												'
'	set myIEForms	=	new IEForms																										'
'	myIEForms.crDropDown "DD1" , "Please select your Task:" , 80 , myArr																'
'	myIEForms.crInputBox "IB1" , "Pleass Input Your Name:" , 32																			'
'	myIEForms.crInputBox "IB2" , "Pleass Input Your Target:" , 32																		'
'	myInputVal	=	myIEForms.DisplayForms( "Single Task Selection" )																	'
'	WScript.Echo "Total Number of Forms: " & ubound( myInputVal , 2 ) + 1																'
'	WScript.Echo "Your task is: " & myIEForms.ValByFormName( "DD1" )( 1 , 0 )															'
'	WScript.Echo "Your name is: " & myIEForms.ValByFormName( "IB1" )( 1 , 0 )															'
'	WScript.Echo "Your target is: " & myIEForms.ValByFormName( "IB2" )( 1 , 0 )															'
'	set myIEForms	=	nothing																											'
'																																		'
'200.	Create a window with a CheckBox.																								'
'	dim myMulti , mySelect																												'
'	dim myArr2(2) , myArr3(2)																											'
'	myArr2(0)	=	"Hike"																												'
'	myArr2(1)	=	"Yoga"																												'
'	myArr2(2)	=	"Bask"																												'
'	set myMulti	=	new IEForms																											'
'	myMulti.crCheckBox "CB1" , "Please select your Favourite:" , myArr2 , "H"															'
'	mySelect	=	myMulti.DisplayForms( "Multiple Task Selection" )																	'
'	WScript.Echo "Total Number of Forms: " & ubound( mySelect , 2 ) + 1																	'
'	myArr3(0)	=	myMulti.ValByFormName( "CB1" )( 1 , 0 )																				'
'	myArr3(1)	=	myMulti.ValByFormName( "CB1" )( 1 , 1 )																				'
'	myArr3(2)	=	myMulti.ValByFormName( "CB1" )( 1 , 2 )																				'
'	WScript.Echo "Your favourite are: " & join( myArr3 , "," )																			'
'	set myMulti	=	nothing																												'
'																																		'
'300.	Create a window with a Radio Box of single selection.																			'
'	dim myRadioBox , myRadioChk																											'
'	dim myArr3(2)																														'
'	myArr3(0)	=	"Walk"																												'
'	myArr3(1)	=	"Ride"																												'
'	myArr3(2)	=	"Drive"																												'
'	set myRadioBox	=	new IEForms																										'
'	myRadioBox.crRadioBox "RB1" , "Please select your method to go outside:" , myArr3 , "V"												'
'	myRadioChk	=	myRadioBox.DisplayForms( "Multiple Task Selection" )																'
'	WScript.Echo "Total Number of Forms: " & ubound( myRadioChk , 2 ) + 1																'
'	WScript.Echo "Your method to go outside is: " & myRadioBox.ValByFormName( "RB1" )( 1 , 0 )											'
'	set myRadioBox	=	nothing																											'
'* Examples End   ---------------------------------------------------------------------------------------------------------------------*'