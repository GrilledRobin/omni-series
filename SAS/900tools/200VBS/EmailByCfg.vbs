' VBScript sample using Windows Script Host
'Set WshShell = WScript.CreateObject("WScript.Shell")
'WshShell.Popup "Hello World!"
'*000.	Info.;
'*-------------------------------------------------------------------------------------------------------------------------------------*'
'100.	Introduction.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|This script is intended to send emails in terms of the Configuration files as below:												'
'	|[1] VB Script File that defines the Sender (On-Behalf-Of name), the Mail Subject and the Universal Mail Body content. The file		'
'	|     should be stored in the same directory as this one.																			'
'	|[2] EXCEL file (with only ONE sheet, in which there is ONE table at left top) that contains the Recipients and Attachment Names.	'
'	|    This file is to be selected via a Dialog.																						'
'---------------------------------------------------------------------------------------------------------------------------------------'
'200.	Glossary.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|Path_Att	:	The directory that stores the Attachments (Only one directory can be selected)										'
'	|File_Cfg	:	The EXCEL Configuration File that stores the Email Attributes Information (See example: [DistributionList.xlsx])	'
'	|fEmailCfg	:	The constant name of a sub-routine script. It should be stored in the same directory as this script.				'
'---------------------------------------------------------------------------------------------------------------------------------------'
'300.	Update log.																														'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	| Date |	20170825		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |Version 1.																													'
'	|______|____________________________________________________________________________________________________________________________'
'	|___________________________________________________________________________________________________________________________________'
'	| Date |	20170909		| Version |	2.00		| Updater/Creator |	Robin Lu Bin												'
'	|______|____________________|_________|_____________|_________________|_____________________________________________________________'
'	| Log  |Split the process of loading EXCEL information into another script for automation purpose.									'
'	|______|____________________________________________________________________________________________________________________________'
'---------------------------------------------------------------------------------------------------------------------------------------'
'400.	User Manual.																													'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|[1] Prepare the Text Configuration File [fEmailCfg] (See Part[010] in this script) to set the texts as below:						'
'	|    [strSender]	:	(Optional) The Sender Email Address to be sent on behalf of.												'
'	|    [strSubj]		:	The universal Email Subject content																			'
'	|    [strMBody]		:	The last part of the Email Body for all Emails, with signatures, etc.										'
'	|[2] Double Click this script in the Explorer																						'
'	|[3] Select the folder that stores all the attachments in the first popup window													'
'	|[4] Locate the Distribution List file in the second popup window and ensure the mapping table is in the First Sheet.				'
'	|[5] Select the Sheet Name from the list in the third popup window and click "OK"													'
'	|[6] Click "OK" when the window of "Successful" popups.																				'
'---------------------------------------------------------------------------------------------------------------------------------------'
'500.	Dependent Scripts.																												'
'---------------------------------------------------------------------------------------------------------------------------------------'
'	|Below scripts are from "900Tools\200VBS"																							'
'	|-----------------------------------------------------------------------------------------------------------------------------------'
'	|	|EMailCfg.vbs																													'
'	|	|LoadXlsAsArray.vbs																												'
'*-------------------------------------------------------------------------------------------------------------------------------------*'

'001.	Declare the input variables.
dim Path_Att,File_Cfg,MsgSelCfg,MsgSelAtt
'Set the initial directory for selection dialog as "My Computer"
const MY_COMPUTER	=	&H11&
'Set the handler as 0 in all VB Scripts
const WINDOW_HANDLE	=	0
'Set the option as below to force an input box to show up in the Folder Selection Dialog
const OPTIONS		=	&H10&
'Set the default settings when we decide to embed the pictures as showing in the Mail Body instead of as a plain attachment file.
Const PR_ATTACH_MIME_TAG	=	"http://schemas.microsoft.com/mapi/proptag/0x370E001E"
Const PR_ATTACH_CONTENT_ID	=	"http://schemas.microsoft.com/mapi/proptag/0x3712001E"
Const PR_ATTACHMENT_HIDDEN	=	"http://schemas.microsoft.com/mapi/proptag/0x7FFE000B"

'005.	Declare the internal variables.
dim oShell,oFolder,oFIterm,strInitPath
dim arrEmails,Vi,Ri
dim strSender,strSubj,strMBody
dim nItem,nAtt,nSubTitle,nMailTo,nSalute,nCC_Cmn,nCC_Sp,nCC_Oth,nBCC_Cmn,nBCC_Sp,nBCC_Oth,nMailBody
dim oFilFSO,nFilCnt,sFilNam
dim oEmails,oEmItem,oEmAtt,oAttPA,sFilExt,sImgTag,Ai
dim fEmailCfg
dim iAtt
strSender	=	""
strSubj		=	""
strMBody	=	""
nItem		=	0
nAtt		=	0
nSubTitle	=	0
nMailTo		=	0
nSalute		=	0
nCC_Cmn		=	0
nCC_Sp		=	0
nCC_Oth		=	0
nBCC_Cmn	=	0
nBCC_Sp		=	0
nBCC_Oth	=	0
nMailBody	=	0
nFilCnt		=	0
Ai			=	0

'010.	Set local parameters.
MsgSelCfg	=	"Please select the Configuration File for Recipient Information (e.g. [DistributionList.xlsx])"
MsgSelAtt	=	"Please select the Directory that stores the Attachments"
'Please ensure the file [fEmailCfg] is in the very same directory as this script.
strInitPath	=	WScript.CreateObject("Scripting.FileSystemObject").GetFile(WScript.ScriptFullName).ParentFolder.Path
fEmailCfg	=	strInitPath & "\EMailCfg.vbs"

'020.	Prepare functions for further process
Sub Include(sInstFile)
	Dim oFSO, f, s
	Set oFSO = WScript.CreateObject("Scripting.FileSystemObject")
	Set f = oFSO.OpenTextFile(sInstFile)
	s = f.ReadAll
	f.Close
	ExecuteGlobal s
End Sub

'100.	Select the directory to locate the attachments.
'150.	Retrieve the Attachments folder name via the Dialog.
MsgBox ( MsgSelAtt )
set	oShell	=	WScript.CreateObject("Shell.Application")
set oFolder	=	oShell.BrowseForFolder( WINDOW_HANDLE , MsgSelAtt , OPTIONS , MY_COMPUTER )
if	oFolder is Nothing	then
	MsgBox ( "Failed to Retrieve the Pathname!" ) , vbOKOnly
	WScript.Quit
end if
set oFIterm	=	oFolder.Self
Path_Att	=	oFIterm.Path

'190.	Demise the objects
set oFIterm	=	nothing
set oFolder	=	nothing
set oShell	=	nothing

'200.	Read the configuration file into arrays.
'[arrTitles] and [arrTblCnt] are returned from the process called below.
MsgBox ( MsgSelCfg )
Include strInitPath & "\LoadXlsAsArray.vbs"

'220.	Read the Titles and the Used Range.
arrEmails	=	arrTblCnt

'500.	Retrieve the Configuration Texts for the Email content.
Include	fEmailCfg

'700.	Quit the script if there is no valid content.
'710.	Mail Subject is compulsary.
if	strSubj	=	""	and	nSubTitle	=	0	then
	MsgBox ( "There is no Subject for the emails! Quit the process!" ) , vbOKOnly
	WScript.Quit
end if

'720.	At least on recipient is required.
if	nMailTo + nCC_Cmn + nCC_Sp + nCC_Oth + nBCC_Cmn + nBCC_Sp + nBCC_Oth	=	0	then
	MsgBox ( "There is no Recipient for the emails! Quit the process!" ) , vbOKOnly
	WScript.Quit
end if

'760.	Attachments should exist on the hard disk.
set	oFilFSO	=	WScript.CreateObject("Scripting.FileSystemObject")
if	nAtt	<>	0	then
	for Ri = 1 to nEmailRow step 1
		for each iAtt in split( arrEmails( Ri , nAtt ) , ";" )
			if	iAtt	<>	""	then
				if	oFilFSO.FileExists( Path_Att & "\" & iAtt )	=	False	then
					nFilCnt	=	nFilCnt	+	1
					sFilNam	=	sFilNam & "[" & iAtt & "];"
				end if
			end if
		next
	next
end if
if	nFilCnt	<>	0	then
	MsgBox ( "Below attachment files do not exist!" & vbCrLf & "Folder:[" & Path_Att & "]" & vbCrLf & sFilNam ) , vbOKOnly
	set	oFilFSO	=	nothing
	WScript.Quit
end if

'800.	Emailing
'810.	Prepare the Emailing environment.
set	oEmails	=	WScript.CreateObject("Outlook.Application")

'820.	Prepare the FSO environment for handling the pictures if any.
set	oFilFSO	=	WScript.CreateObject("Scripting.FileSystemObject")

'850.	Send emails in terms of the records in the configuration file.
for Ri = 1 to nEmailRow step 1
	'010.	Initialize a new Email.
	set	oEmItem	=	oEmails.CreateItem( olMailItem )
	if	strSender	<>	""	then
		oEmItem.SentOnBehalfOfName	=	strSender
	end if

	'100.	Setup the Email Subject.
	if	strSubj		<>	""	then
		oEmItem.Subject	=	oEmItem.Subject & strSubj
	end if
	if	nSubTitle	<>	0	then
		if	arrEmails( Ri , nSubTitle )	<>	""	then
			oEmItem.Subject	=	oEmItem.Subject & " [" & arrEmails( Ri , nSubTitle ) & "]"
		end if
	end if

	'200.	Setup the direct recipients.
	if	nMailTo		<>	0	then
		if	arrEmails( Ri , nMailTo )	<>	""	then
			oEmItem.To		=	arrEmails( Ri , nMailTo )
		end if
	end if

	'300.	Setup the Carbon-Copy recipients.
	if	nCC_Cmn		<>	0	then
		if	arrEmails( Ri , nCC_Cmn )	<>	""	then
			oEmItem.CC		=	oEmItem.CC & ";" & arrEmails( Ri , nCC_Cmn )
		end if
	end if
	if	nCC_Sp		<>	0	then
		if	arrEmails( Ri , nCC_Sp )	<>	""	then
			oEmItem.CC		=	oEmItem.CC & ";" & arrEmails( Ri , nCC_Sp )
		end if
	end if
	if	nCC_Oth		<>	0	then
		if	arrEmails( Ri , nCC_Oth )	<>	""	then
			oEmItem.CC		=	oEmItem.CC & ";" & arrEmails( Ri , nCC_Oth )
		end if
	end if

	'400.	Setup the Blind Carbon-Copy recipients.
	if	nBCC_Cmn	<>	0	then
		if	arrEmails( Ri , nBCC_Cmn )	<>	""	then
			oEmItem.BCC		=	oEmItem.BCC & ";" & arrEmails( Ri , nBCC_Cmn )
		end if
	end if
	if	nBCC_Sp		<>	0	then
		if	arrEmails( Ri , nBCC_Sp )	<>	""	then
			oEmItem.BCC		=	oEmItem.BCC & ";" & arrEmails( Ri , nBCC_Sp )
		end if
	end if
	if	nBCC_Oth	<>	0	then
		if	arrEmails( Ri , nBCC_Oth )	<>	""	then
			oEmItem.BCC		=	oEmItem.BCC & ";" & arrEmails( Ri , nBCC_Oth )
		end if
	end if

	'500.	Setup the Mail Body.
	if	nSalute		<>	0	then
		if	arrEmails( Ri , nSalute )	<>	""	then
			oEmItem.Body	=	oEmItem.Body & "Dear " & arrEmails( Ri , nSalute ) & ":"
		else
			oEmItem.Body	=	oEmItem.Body & "Dear Sir/Madam:"
		end if
	end if
	if	nMailBody	<>	0	then
		if	arrEmails( Ri , nMailBody )	<>	""	then
			oEmItem.Body	=	oEmItem.Body & vbCrLf & vbCrLf & arrEmails( Ri , nMailBody )
		end if
	end if
	if	strMBody	<>	""	then
		oEmItem.Body	=	oEmItem.Body & vbCrLf & vbCrLf & strMBody
	end if

	'600.	Define the attachments.
	if	nAtt		<>	0	then
		for each iAtt in split( arrEmails( Ri , nAtt ) , ";" )
			if	iAtt	<>	""	then
				oEmItem.Attachments.add( Path_Att & "\" & iAtt )
			end if
		next
	end if

	'700.	Embed the pictures in the attachments into the HTML Body.
	if	oEmItem.Attachments.Count	<>	0	then
		for each oEmAtt in oEmItem.Attachments
			'100.	Identify the File Extension of current attachment.
			sFilExt	=	uCase( oFilFSO.GetExtensionName( oEmAtt ) )

			'500.	Only process the pictures.
			if	inStr( ";BMP;GIF;JPG;JPEG;PNG;" , sFilExt )	<>	0	then
				'100.	Identify the Image Tag for pictures.
				sImgTag	=	"image/" & sFilExt

				'200.	Increment the Indent ID.
				Ai		=	Ai	+	1

				'300.	Setup the Property Accessor.
				set oAttPA	=	oEmAtt.PropertyAccessor

				'400.	Set the Image Tag.
				oAttPA.SetProperty PR_ATTACH_MIME_TAG , sImgTag

				'500.	Set the Indent ID.
				oAttPA.SetProperty PR_ATTACH_CONTENT_ID , "MyIdImg" & Ai

				'600.	Embed the current picture in HTML Body.
				'[HTMLBody] property will overwrite the original [Body] property.
				oEmItem.HTMLBody	=	oEmItem.HTMLBody & "<br />" & "<br />" & "<IMG align=baseline border=0 hspace=0 src=cid:MyIdImg" & Ai & ">"
			end if
		next
	end if

	'900.	Send current email.
	oEmItem.Send
next

'890.	Demise the Email environment
set oAttPA	=	nothing
set oEmAtt	=	nothing
set oFilFSO	=	nothing
set	oEmItem	=	nothing
set	oEmails	=	nothing

MsgBox ("Emails have been successfully submitted!") , vbOKOnly