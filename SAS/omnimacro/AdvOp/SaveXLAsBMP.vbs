'=====================================================================
'- COPY IMAGES FROM A WORKSHEET TO .BMP FILES
'- Picks up Embedded objects (OLEObjects) and Pictures (Picture objects)
'- *** AMEND CONST VALUES BELOW AND RUN THE MACRO FROM THE SHEET
'======================================================================
'- 1. Copies picture from sheet.
'- 2. Gets next file name in the series (filenames format like "xxx_001.bmp")
'- 3. Opens MSPaint application. Paste. Size image. Save image. Close.
'- Brian Baulsom September 2008.
'- Userform Screen copy version July 2008
'- http://www.mrexcel.com/forum/showthread.php?t=331211
'=====================================================================
'- *** AMEND THESE VALUES TO SUIT ************************************
Const BitmapFileName As String = "XLpicture" 'name without "_00x.bmp"
Const MyPictureFolder As String = "F:\TEMP\" ' target folder for files
Const MSPaint As String = "C:\WINDOWS\system32\mspaint.exe"
'====================================================================
Dim MyPicture As Object        ' PICTURES IN SHEET
Dim PointsToPixels As Double   ' convert Excel points size to pixels
Dim Pheight As Integer         ' original picture height
Dim Pwidth As Integer          ' original picture width
Dim V As String                ' height/width value in pixels
'---------------------------------------------------------------------
'- BITMAP FILE
Dim FullFileName As String '= MyPictureFolder & BitmapFileName & "_00x.bmp"
'---------------------------------------------------------------------
'- MS PAINT
Const Alt As String = "%"   ' for SendKeys Alt key
Dim RetVal                  ' Shell error return. Not used here.
'---------------------------------------------------------------------
'- GET NEXT FILE NAME (Uses FileSystemObject)
Dim FSO As Object
Dim FileNumber As Integer
Dim LastFileNumber As Integer
'-- end of declarations ----------------------------------------------
 
'=====================================================================
'- MAIN ROUTINE - LOOP PICTURES IN ACTIVE SHEET
'=====================================================================
Sub PICTURES_TO_FILES()
    Application.Calculation = xlCalculationManual
    ActiveSheet.Range("A1").Select  ' move focus to sheet
    '- INITIALISE VARIABLES
    LastFileNumber = 0              ' counter
    PointsToPixels = 1.333
    '-----------------------------------------------------------------
    '- LOOP
    For Each MyPicture In ActiveSheet.Pictures
        MyPicture.Copy
        Pheight = Int(MyPicture.Height * PointsToPixels) ' points to pixels
        Pwidth = Int(MyPicture.Width * PointsToPixels)
        SAVE_PICTURE    ' SUBROUTINE
    Next
    '-----------------------------------------------------------------
    '- FINISH
    MsgBox ("Saved " & LastFileNumber & " files." & vbCr _
            & "to folder " & MyPictureFolder)
    Application.Calculation = xlCalculationAutomatic
End Sub
'- END OF MAIN ROUTINE ===============================================
'=====================================================================
'- MSPAINT : PASTE PICTURE - SAVE AS BITMAP FILE
'=====================================================================
'- NB. MANUALLY SET MSPAINT IMAGE/ATTRIBUTES TO *PIXELS* & CLOSE.
'- NB. Sendkeys requires 'Wait' statements to delay code while things
'- happen on screen.
'- These can be changed as required depending on computer speed
'- Not been able to get this to work with Paint Hidden or Minimized
'=====================================================================
Private Sub SAVE_PICTURE()
    '-----------------------------------------------------------------
    '- NEXT FILE NAME IN THE SERIES
    GET_NEXT_FILENAME   ' SUBROUTINE
    '-----------------------------------------------------------------
    '- OPEN MS PAINT
    RetVal = Shell(MSPaint, vbNormalFocus)  ' normal screen
    Application.StatusBar = " Open MS Paint"
    Application.Wait Now + TimeValue("00:00:02")    ' 2 seconds to open
    '- paste ---------------------------------------------------------
    Application.StatusBar = " Paste picture"
    SendKeys Alt & "E", True    ' edit menu
    SendKeys "P", True          ' paste
    DoEvents
    Application.Wait Now + TimeValue("00:00:01")    ' wait 1 second
    '-----------------------------------------------------------------
    '- Image Menu
    SendKeys Alt & "I", True    ' image menu
    Application.Wait Now + TimeValue("00:00:01")    ' wait 1 second
    SendKeys "A", True    ' attributes
    DoEvents
    Application.Wait Now + TimeValue("00:00:01")    ' wait 1 second
    '-----------------------------------------------------------------
    '- Set Width
    V = Format(Pwidth, "000")
    SendKeys Alt & "W", True    ' width
    SendKeys V, True
    DoEvents
    Application.Wait Now + TimeValue("00:00:01")    ' wait 1 second
    '-----------------------------------------------------------------
    '- Set Height
    V = Format(Pheight, "000")
    SendKeys Alt & "H", True    ' height
    SendKeys V, True
    DoEvents
    Application.Wait Now + TimeValue("00:00:01")    ' wait 1 second
    '-----------------------------------------------------------------
    '- ENTER
    SendKeys "{ENTER}", True
    DoEvents
    '-----------------------------------------------------------------
    '- save file
    Application.StatusBar = " Saving " & FullFileName
    SendKeys Alt & "F"              ' File menu
    DoEvents
    Application.Wait Now + TimeValue("00:00:01")    ' wait 1 second
    SendKeys "A", True              ' Save As dialog
    DoEvents
    Application.Wait Now + TimeValue("00:00:01")
    SendKeys FullFileName, True     ' type file name
    DoEvents
    Application.Wait Now + TimeValue("00:00:02")    ' wait 2 seconds
    SendKeys Alt & "S", True        ' Save
    DoEvents
    Application.Wait Now + TimeValue("00:00:03") ' 3 seconds to save
    '- close ---------------------------------------------------------
    Application.StatusBar = " Closing Paint"
    SendKeys Alt & "{F4}", True
    DoEvents
    Application.StatusBar = False
End Sub
'-- eop --------------------------------------------------------------
'=====================================================================
'- SUBROUTINE : GET NEXT FILE NAME -> BitMapFileName + "_00x"
'- Called from Sub SAVE_PICTURE()
'=====================================================================
Private Sub GET_NEXT_FILENAME()
    Dim f, f1, fc
    Dim Fname As String
    Dim F3 As String    ' number
    Dim Flen As Integer ' length
    '-----------------------------------------------------------------
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Set f = FSO.GetFolder(MyPictureFolder)
    Set fc = f.Files
    '- length of file name = name + number + suffix
    Flen = Len(BitmapFileName) + 4 + 4
    '-----------------------------------------------------------------
    '- LOOP FILES IN FOLDER
    For Each f1 In fc
        Fname = f1.Name
        '-------------------------------------------------------------
        '- check valid file and number
        F3 = Mid(Fname, Len(Fname) - 6, 3) ' number string
        If InStr(1, Fname, BitmapFileName, vbTextCompare) <> 0 _
            And IsNumeric(F3) And Len(Fname) = Flen Then
            FileNumber = CInt(F3)
            If FileNumber > LastFileNumber Then
                LastFileNumber = FileNumber
            End If
        End If
        '-------------------------------------------------------------
    Next
    LastFileNumber = LastFileNumber + 1
    '------------------------------------------------------------------
    '- Next file name in series
    FullFileName = MyPictureFolder & _
                BitmapFileName & "_" & Format(LastFileNumber, "000")
End Sub
'-- eop ---------------------------------------------------------------