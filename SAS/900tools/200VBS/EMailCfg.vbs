'100.	We find the respective columns regardless of their positions
for Vi = 1 to nMaxCol step 1
	if	arrTitles(1,Vi)	=	"Item"	then
		nItem		=	Vi
	elseif	arrTitles(1,Vi)	=	"Attachments"	then
		nAtt		=	Vi
	elseif	arrTitles(1,Vi)	=	"Subtitle"	then
		nSubTitle	=	Vi
	elseif	arrTitles(1,Vi)	=	"MailTo"	then
		nMailTo		=	Vi
	elseif	arrTitles(1,Vi)	=	"Salutation"	then
		nSalute		=	Vi
	elseif	arrTitles(1,Vi)	=	"CC_Common"	then
		nCC_Cmn		=	Vi
	elseif	arrTitles(1,Vi)	=	"CC_SP"	then
		nCC_Sp		=	Vi
	elseif	arrTitles(1,Vi)	=	"CC_Oth"	then
		nCC_Oth		=	Vi
	elseif	arrTitles(1,Vi)	=	"BCC_Common"	then
		nBCC_Cmn	=	Vi
	elseif	arrTitles(1,Vi)	=	"BCC_SP"	then
		nBCC_Sp		=	Vi
	elseif	arrTitles(1,Vi)	=	"BCC_Oth"	then
		nBCC_Oth	=	Vi
	elseif	arrTitles(1,Vi)	=	"Mail_Body"	then
		nMailBody	=	Vi
	end if
next

'200.	Please ensure the user has the delegation to send emails on behalf of below Email Address.
'It is OK if the Sender is not provided, while the process will use the default Email host to deliver the Emails.
strSender	=	"UOBCPFSBusinessIntelligence@UOBGroup.com"

'300.	Define the Universal Subject (which will be followed by the user specified modifiers in the Recipient List File.).
strSubj		=	"PFS Business Performance Pack - "

'400.	Set the Mail Body.
strMBody	=	strMBody & vbCrLf & "Please find the latest PFS Business Performance Pack-" & month( date - 30 ) & " for your review."
strMBody	=	strMBody & vbCrLf
strMBody	=	strMBody & vbCrLf & "-----------------------------------------------------------------------------"
strMBody	=	strMBody & vbCrLf & "Best Regards,"
strMBody	=	strMBody & vbCrLf & "Business Intelligence"