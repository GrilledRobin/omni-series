' VBScript sample using Windows Script Host
'Set WshShell = WScript.CreateObject("WScript.Shell")
'WshShell.Popup "Hello World!"
'*000.	Info.;
'*-------------------------------------------------------------------------------------------------------------------------------------*'
'100.	Introduction.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|This script is intended to load the entire table from EXCEL Spreadsheet into two arrays: Titles and Contents.						'
'	|Note: The table to be loaded in the EXCEL file must start at the first cell, while the Used Range must be fulfilled by this table.	'
'---------------------------------------------------------------------------------------------------------------------------------------'
'200.	Glossary.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|arrTitles	:	The output array that holds the values of all cells in the first row of the table									'
'	|arrTblCnt	:	The output array that holds the content of all cells except the first row of the table (Two-dimensional)			'
'---------------------------------------------------------------------------------------------------------------------------------------'
'300.	Update log.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	| Date |	20170909		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |Version 1.																													'
'	|______|____________________________________________________________________________________________________________________________'
'	|___________________________________________________________________________________________________________________________________'
'	| Date |	20171015		| Version |	2.00		| Updater/Creator |	Robin Lu Bin												'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |Leverage the class [IEForms] to display and collect user selection.															'
'	|______|____________________________________________________________________________________________________________________________'
'---------------------------------------------------------------------------------------------------------------------------------------'
'400.	User Manual.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|[1] Double Click this script in the Explorer																						'
'	|[2] Locate the EXCEL file in the first popup window																				'
'	|[3] Select the Sheet Name from the list in the second popup window																	'
'	|[4] Click "OK"																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'500.	Dependent Scripts.																												'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|Below scripts are from "900Tools\200VBS"																							'
'	|-----------------------------------------------------------------------------------------------------------------------------------'
'	|	|Cls_IEForms.vbs																												'
'*-------------------------------------------------------------------------------------------------------------------------------------*'

'001.	Declare the input variables.
dim File_Cfg,MsgSelCfg

'005.	Declare the internal variables.
dim strInitPath
dim oExcel,oWbook,arrSheetNames,uIEForms,uFormRst,uShName,oSheet,oRanges,nMaxRow,nMaxCol,oRTitles,oRCnts,nCntsRow
dim arrTitles,arrTblCnt

'010.	Set local parameters.
MsgSelCfg	=	"Please select the EXCEL File to load data"
'Please ensure the file [fEmailCfg] is in the very same directory as this script.
strInitPath	=	WScript.CreateObject("Scripting.FileSystemObject").GetFile(WScript.ScriptFullName).ParentFolder.Path

'020.	Prepare functions for further process
Sub Include(sInstFile)
	Dim oFSO, f, s
	Set oFSO = WScript.CreateObject("Scripting.FileSystemObject")
	Set f = oFSO.OpenTextFile(sInstFile)
	s = f.ReadAll
	f.Close
	ExecuteGlobal s
End Sub

'100.	Prepare the functions to use.
Include	strInitPath & "\Cls_IEForms.vbs"

'200.	Open the EXCEL file.
set	oExcel	=	WScript.CreateObject("Excel.Application")
File_Cfg	=	oExcel.GetOpenFileName( "All Excel Files|*.xl* , *.xl*" , 1 , MsgSelCfg )
if	File_Cfg	=	False	then
	MsgBox ( "Failed to Retrieve the EXCEL File!" ) , vbOKOnly
	WScript.Quit
end if
set	oWbook	=	oExcel.Workbooks.open( File_Cfg )

'300.	Load all the sheet names into array.
Set arrSheetNames	=	CreateObject( "System.Collections.ArrayList" )
For Each oSheet in oWbook.Worksheets
	arrSheetNames.add oSheet.Name
Next

'400.	Ask user to select one of the sheets to read.
set uIEForms	=	new IEForms
uIEForms.crDropDown "myDD" , MsgSelCfg , 80 , arrSheetNames
uFormRst	=	uIEForms.DisplayForms( "Sheet Selection" )
uShName		=	uIEForms.ValByFormName( "myDD" )( 1 , 0 )

'490.	Read the basic information.
set	oSheet	=	oWbook.Worksheets( uShName )
set	oRanges	=	oSheet.UsedRange
nMaxRow		=	oRanges.Rows.Count
nMaxCol		=	oRanges.Columns.Count
set	oRTitles	=	oSheet.Range( oSheet.Cells( 1 , 1 ) , oSheet.Cells( 1 , nMaxCol ) )
set	oRCnts	=	oSheet.Range( oSheet.Cells( 2 , 1 ) , oSheet.Cells( nMaxRow , nMaxCol ) )
nCntsRow	=	nMaxRow - 1

'800.	Read the Titles and the Used Range into arrays.
arrTitles	=	oRTitles.value
arrTblCnt	=	oRCnts.value

'900.	Close the configuration file.
oWbook.close
set uIEForms	=	nothing
set arrSheetNames	=	nothing
set	oRTitles	=	nothing
set	oRCnts		=	nothing
set	oSheet		=	nothing
set	oWbook		=	nothing
set	oExcel		=	nothing

'* Examples Begin ---------------------------------------------------------------------------------------------------------------------*'
'100.	Direct execution of the script.																									'
'	WScript.Echo "Current Title is: " & arrTitles(1,4) & "<->" & "Current Row Content is: " & arrTblCnt(2,4)							'
'* Examples End   ---------------------------------------------------------------------------------------------------------------------*'