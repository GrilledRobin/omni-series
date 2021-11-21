on error resume next '忽略错误

'设置对象
set objExcel=CreateObject ("excel.application")
'set objWorks=objExcel.WorkBooks.Open(path&"\"&wscript.arguments(0))	'arguments(0)表示参数1
set objWorks=objExcel.WorkBooks.Open(wscript.arguments(0) & "\" & wscript.arguments(1))
objWorks.Worksheets(1).Activate

objExcel.DisplayAlerts = False
objWorks.SaveAs wscript.arguments(0) & "\" & wscript.arguments(1),-4143
objExcel.DisplayAlerts = True
objWorks.Close

'清空对象，释放内存
set objWorks=Nothing
set objExcel=Nothing