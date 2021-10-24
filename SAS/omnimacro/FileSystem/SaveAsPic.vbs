'001.	System Initiation.
Dim XLApp,XLBook,XLSheet,XLRng,XLChart
Set	XLApp	=	CreateObject("Excel.Application")
XLApp.Visible	=	False
XLApp.DisplayAlerts	=	False

InFdrName	=	"C:\Documents and Settings\1298609\Desktop\Robin Lucas\workflow\201307\20130725\"
InFlName	=	"pic_pre"
InExt		=	"xls"
InShName	=	"Report"
InShRng		=	"B2:CG226"
OutFdrName	=	"C:\Documents and Settings\1298609\Desktop\Robin Lucas\workflow\201307\20130725\"
OutFlName	=	"a"
OutShName	=	"Report"
OutExt		=	"png"	'"bmp","jpg","gif","png"
FHighRes	=	0

'100.	Source Retrieval.
XLApp.Workbooks.Open InFdrName & InFlName & "." & InExt
XLApp.ActiveWorkbook.Sheets(InShName).Activate
Set	XLRng	=	XLApp.ActiveSheet.Range(InShRng)
XLRng.CopyPicture 1,-4147

'200.	Create Output workbook.
Set	XLBook	=	XLApp.Workbooks.Add
Set	XLSheet	=	XLBook.Worksheets(1)
Set	XLDel2	=	XLBook.Worksheets(2)
Set	XLDel3	=	XLBook.Worksheets(3)
Set XLChart	=	XLSheet.ChartObjects.Add(0, 0, XLRng.Width, XLRng.Height)

'300.	Output.
if	FHighRes	=	1	then
	OutExt	=	"xls"

	'Clogging sheets truncation.
	XLDel2.Delete
	XLDel3.Delete

	'Paste picture to the given sheet.
	XLSheet.Activate
	XLSheet.Name	=	OutShName
	XLSheet.Paste

	'Save the Output workbook.
	XLBook.SaveAs	OutFdrName & OutFlName & "." & OutExt ,-4143
else
	'Set Print Quality for Printer, this should be capped at 1200
	XLChart.Chart.PageSetup.PrintQuality	=	1200

	'Paste picture to the given chart.
	XLChart.Chart.Paste

	'Save the Output file.
	XLChart.Chart.Export OutFdrName & OutFlName & "." & OutExt ,OutExt
end if

'800.	System Objects truncation.
XLApp.WorkBooks.Close
XLApp.Quit
set XLChart	=	nothing
set XLRng	=	nothing
set XLSheet	=	nothing
set XLBook	=	nothing
set XLApp	=	nothing
