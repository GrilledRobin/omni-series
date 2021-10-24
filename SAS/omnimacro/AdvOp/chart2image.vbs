'This VBScript creates an instance of Excel.Application object and opens XLS file.
'XLS file contains a chart as a separate sheet (not as object on the sheet): chart wizard in Excel allows to set this option.
'The ShotGraph object converts the chart to Gif image file using ShotGraph OLE capabilities.
'This chart can be vector resized to any size during conversion.
'All error checkings are omitted to make script more simple.
'After some little modifications you can use this script in your Excel VBA macros. All variables should be of Variant type.

Set excel=CreateObject("Excel.Application")
Set g=CreateObject("shotgraph.image")

' Opening XLS file containing the chart
excel.WorkBooks.Open "c:\xls\test.xls"
' Making the chart active
excel.WorkBooks(1).Charts(1).Select
' Checking object
g.CheckObject excel.WorkBooks(1),x,y
if x>0 and y>0 then
' Creating image
' Here you can change x,y to reduce the image
 g.CreateImage x,y,16
 g.SetColor 0,255,255,255
 g.SetBgColor 0
 g.FillRect 0,0,x-1,y-1
 g.DrawObject excel.WorkBooks(1),"CONTENT",0,0,x,y
 g.BuildPalette 0
' To convert image to Jpeg, remove previous BuildPalette calling
' and use JpegImage instead of GifImage
 g.GifImage -1,0,"c:\test.gif"
else
    Wscript.echo "Could not draw chart!"
end if
excel.WorkBooks(1).Close 0
excel.Quit