'001.	System Initiation.
Dim	XLApp,XLsrcBook,XLsrcSheet,XLsrcRng,XLsrcRngHeight,XLsrcRngWidth
Dim	NameLstShape,arrShape
Dim	XLBook,XLSheet,XLPic,XLPicHeight,XLPicWidth,XLChart,XLChartName
Dim	InFdrName,InFlName,InExt,OutFdrName,OutFlName,OutExt
InFdrName	=	"X:\SME_MIS\LuBin\AutoReports\900tools\002RPTtpl\"
InFlName	=	"test_SALES_2012Q2"
InExt		=	"xls"
OutFdrName	=	"X:\SME_MIS\LuBin\AutoReports\900tools\002RPTtpl\"
OutFlName	=	"IDB_SALES_2012Q2"
OutExt		=	"png"	'"bmp","jpg","gif","png"

'100.	Source Retrieval.
'Set	XLApp	=	CreateObject("Excel.Application.12")
Set	XLApp	=	CreateObject("Excel.Application")
XLApp.Visible	=	False
XLApp.DisplayAlerts	=	False
XLApp.ScreenUpdating	=	True
XLApp.AskToUpdateLinks	=	False
XLApp.Workbooks.Open InFdrName & InFlName & "." & InExt
Set	XLsrcBook	=	XLApp.ActiveWorkbook
Set	XLsrcSheet	=	XLsrcBook.Sheets("Report")
Set	XLsrcRng	=	XLsrcSheet.Range("B2:CG217")
NameLstShape	=	""
For Each shp In XLsrcSheet.Shapes
	NameLstShape	=	NameLstShape & "," & shp.Name
Next
NameLstShape	=	Right(NameLstShape, Len(NameLstShape) - 1)
arrShape	=	Split(NameLstShape,",")
XLsrcSheet.Shapes.Range((arrShape)).Group
XLsrcRngHeight	=	XLsrcRng.Height
XLsrcRngWidth	=	XLsrcRng.Width
XLsrcRng.CopyPicture 2,-4147

'200.	Create Output workbook.
Set	XLBook	=	XLApp.Workbooks.Add
Set	XLSheet	=	XLBook.Worksheets(1)
Set	XLDel2	=	XLBook.Worksheets(2)
Set	XLDel3	=	XLBook.Worksheets(3)
'210.	Clogging sheets truncation.
XLDel2.Delete
XLDel3.Delete
'220.	Paste picture to the given sheet.
XLSheet.Paste
Set	XLPic	=	XLSheet.Shapes("Picture 1")
XLPicWidth	=	XLPic.Width
XLPicHeight	=	XLPic.Height
XLPic.Copy
XLBook.Charts.add
XLBook.ActiveChart.Location 2,XLSheet.Name
Set	XLChart	=	XLBook.ActiveChart
'XLChartName	=	XLChart.Name
With XLChart.Parent
'With XLSheet.Shapes(XLChartName)
	.Width	=	XLPicWidth
	.Height	=	XLPicHeight
End With
XLChart.ChartArea.Clear
XLChart.Paste
'290.	Save the Output workbook.
XLChart.Export OutFdrName & OutFlName & "." & OutExt, OutExt
'XLBook.SaveAs	FdrName & FlName & ".htm",44
'300.	Initiate FileSystemObject to get the PNG
'Dim FSO,PNGCopy
'Set FSO	=	CreateObject("Scripting.FileSystemObject")
'Set PNGCopy	=	FSO.GetFile(FdrName & FlName & "_Files\image001.png")
'PNGCopy.Copy(FdrName & FlName & ".png"),True
'800.	System Objects truncation.
XLApp.WorkBooks.Close
XLApp.Quit
'FSO.DeleteFolder(FdrName & FlName & "_Files"),DeleteReadOnly
'FSO.DeleteFile(FdrName & FlName & ".htm"),DeleteReadOnly
'set PNGCopy	=	nothing
'set FSO		=	nothing
set XLSheet	=	nothing
set XLBook	=	nothing
set XLApp	=	nothing
