'This sample shows an alternative when MS Office is not installed while the sheet names should
' be retrieved, in terms of ActiveX Data Objects Database (ADODB).
'However, ADODB still requires "Microsoft Office Data Connectivity Component" to be installed.

option explicit
Dim objConn 'As ADODB.Connection
Dim objCat 'As ADOX.Catalog
Dim tbl 'As ADOX.Table
Dim iRow 'As Long
Dim sWorkbook 'As String
Dim sFileType 'As String
Dim sConnString 'As String
Dim sTableName 'As String
Dim cLength 'As Integer
Dim iTestPos 'As Integer
Dim iStartpos 'As Integer


sWorkbook = "C:\Documents and Settings\1298609\Desktop\Robin Lucas\workflow\201409\20140915\book1.xls"
sWorkbook = "X:\SME_Raw\dtp\daily\(083) Customer Profile (CIU)20140912.xls"
sFileType = Mid( sWorkbook, InStrRev(sWorkbook, ".") + 1, Len(sWorkbook) - InStrRev(sWorkbook, ".") )
'Object Linking and Embedding Database
If UCase(sFileType) = "XLS" Then
sConnString = "Provider=Microsoft.Jet.OLEDB.4.0;" _
              & "Data Source=" & sWorkbook & ";" _
              & "Extended Properties=Excel 8.0;"
ElseIf UCase(sFileType) = "XLSX" Then
sConnString = "Provider=Microsoft.ACE.OLEDB.12.0;" _
              & "Data Source=" & sWorkbook & ";" _
              & "Extended Properties=Excel 12.0;"
Else
'Should there be any other file types please setup proper engine here.
End If

Set objConn = CreateObject("ADODB.Connection")
'Set objConn = New oADO
objConn.Open sConnString
Set objCat = CreateObject("ADOX.Catalog")
'Set objCat = New ADOX.Catalog
Set objCat.ActiveConnection = objConn

iRow = 1
For Each tbl In objCat.Tables
    sTableName = tbl.Name
    cLength = Len(sTableName)
    iTestPos = 0
    iStartpos = 1
        'Worksheet name with embedded spaces are enclosed by single quotes
    If Left(sTableName, 1) = "'" And Right(sTableName, 1) = "'" Then
        iTestPos = 1
        iStartpos = 2
    End If
        'Worksheet names always end in the "$" character
    If Mid(sTableName, cLength - iTestPos, 1) = "$" Then
        wscript.echo    Mid(sTableName, iStartpos, cLength - (iStartpos + iTestPos))
        iRow = iRow + 1
    End If
Next
objConn.Close
Set objCat = Nothing
Set objConn = Nothing