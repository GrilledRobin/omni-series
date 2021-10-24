'=============================================================================
'- COPY PICTURES FROM A WORKSHEET TO .BMP FILES
'- VERSION 2 : uses code to save file instead of SendKeys/MS Paint
'---------------------------------------------------------------------
'- Thanks to the code attributed to JAAFAR of MrExcel forum (with no messages present now)
'- Ref : http://www.ozgrid.com/forum/showthread.php?t=45682
'---------------------------------------------------------------------
'- Picks up Embedded objects (OLEObjects) and Pictures (Picture objects)
'=============================================================================
'- *** AMEND THESE CONST VALUES AND RUN THE MACRO FROM THE SHEET
Const BitmapFileName As String = "XLpicture" 'file name without "_00x.bmp"
Const MyPictureFolder As String = "F:\TEMP\" ' target folder for files
'-------------------------------------------------------------------------
'- 1. Copies all pictures from sheet.
'- 2. Gets next file name in the series (filenames format like "xxx_001.bmp")
'- 3. Saves file in target folder.
'- Brian Baulsom November 2008
'=============================================================================
'- VERSION 1 : Userform Screen copy July 2008 using SendKeys/MS Paint
'- http://www.mrexcel.com/forum/showthread.php?t=331211
'=============================================================================
'- DECLARATIONS & VARIABLES TO SAVE PICTURE FILE FROM CLIPBOARD
Private Declare Function OpenClipboard Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function GetClipboardData Lib "user32" (ByVal wFormat As Integer) As Long
Private Declare Function CloseClipboard Lib "user32" () As Long
Private Declare Function OleCreatePictureIndirect Lib "olepro32.dll" _
    (PicDesc As uPicDesc, RefIID As GUID, ByVal fPictureOwnsHandle As Long, IPic As IPicture) As Long
'------------------------------------------------------------------------------
'- IPicture OLE Interface
Private Type GUID
Data1 As Long
Data2 As Integer
Data3 As Integer
Data4(0 To 7) As Byte
End Type
'-store the bitmap information
Private Type uPicDesc
Size As Long
Type As Long
    hPic As Long
    hPal As Long
End Type
'-------------------------------------------------------------------------------
Const CF_BITMAP = 2
Const CF_PALETTE = 9
Const IMAGE_BITMAP = 0
Const LR_COPYRETURNORG = &H4
Const PICTYPE_BITMAP = 1
Dim IID_IDispatch As GUID
Dim uPicinfo As uPicDesc
Dim IPic As IPicture
Dim hPtr As Long
'=============================================================================
'- WORKSHEET/PICTURE VARIABLES
Dim MyShapeRange As ShapeRange
Dim MyPicture As Object        ' PICTURES IN SHEET
Dim PictureCount As Integer
'-----------------------------------------------------------------------------
'- BITMAP FILE : FULL PATH & FILE NAME
Dim FullFileName As String '= MyPictureFolder & BitmapFileName & "_00x.bmp"
'-----------------------------------------------------------------------------
'- GET NEXT FILE NAME (Uses FileSystemObject)
Dim FSO As Object
Dim FileNumber As Integer
Dim LastFileNumber As Integer
'-- end of declarations ------------------------------------------------------
 
'*****************************************************************************
'- MAIN ROUTINE - LOOP PICTURES IN ACTIVE SHEET
'- Picks up Embedded objects (OLEObjects) and Pictures (Picture objects)
'*****************************************************************************
Sub PICTURES_TO_FILES()
    Application.Calculation = xlCalculationManual
    ActiveSheet.Range("A1").Select  ' focus from button or picture to sheet
    LastFileNumber = 0              ' counter
    Set FSO = CreateObject("Scripting.FileSystemObject") ' FOR NEXTFILENAME
    '------------------------------------------------------------------------
    '- LOOP ALL PICTURES IN THE WORKSHEET
    Set MyShapeRange = ActiveSheet.Pictures.ShapeRange
    For Each MyPicture In MyShapeRange
        PictureCount = PictureCount + 1
        '- COPY PICTURE
        MyPicture.CopyPicture Appearance:=xlScreen, Format:=xlBitmap       ' MyPicture.Copy
        '--------------------------------------------------------------------
        '- NEXT FILE NAME IN THE SERIES
        GET_NEXT_FILENAME       ' SUBROUTINE
        '--------------------------------------------------------------------
        '- SAVE PICTURE FROM CLIPBOARD
        SAVE_PICTURE            ' SUBROUTINE
    Next
    '------------------------------------------------------------------------
    '- FINISH
    MsgBox ("Saved " & PictureCount & " file(s)." & vbCr _
            & "To Folder : " & MyPictureFolder & vbCr _
            & "Last file name : " & BitmapFileName & Format(LastFileNumber, "000"))
    Application.Calculation = xlCalculationAutomatic
End Sub
'- END OF MAIN ROUTINE =======================================================
'=============================================================================
'- SUBROUTINE : SAVE PICTURE FROM CLIPBOARD AS A BITMAP FILE (JAAFAR'S CODE)
'- Called from main routine
'=============================================================================
Private Sub SAVE_PICTURE()
    '-----------------------------------------------------------------
    OpenClipboard 0
    hPtr = GetClipboardData(CF_BITMAP)
    CloseClipboard
    '-------------------------------------------------------------------------
     'Create the interface GUID for the picture
    With IID_IDispatch
        .Data1 = &H7BF80980
        .Data2 = &HBF32
        .Data3 = &H101A
        .Data4(0) = &H8B
        .Data4(1) = &HBB
        .Data4(2) = &H0
        .Data4(3) = &HAA
        .Data4(4) = &H0
        .Data4(5) = &H30
        .Data4(6) = &HC
        .Data4(7) = &HAB
    End With
    '------------------------------------------------------------------------
     '  Fill uPicInfo with necessary parts.
    With uPicinfo
        .Size = Len(uPicinfo) ' Length of structure.
        .Type = PICTYPE_BITMAP ' Type of Picture
        .hPic = hPtr ' Handle to image.
        .hPal = 0 ' Handle to palette (if bitmap).
    End With
    '------------------------------------------------------------------------
     'Create the Picture Object
    OleCreatePictureIndirect uPicinfo, IID_IDispatch, True, IPic
    '------------------------------------------------------------------------
     'Save Picture
    stdole.SavePicture IPic, FullFileName
    '------------------------------------------------------------------------
     'fix the clipboard (it seems to go messed up)
    Selection.CopyPicture Appearance:=xlScreen, Format:=xlBitmap
    '------------------------------------------------------------------------
End Sub
'======== EOP ===============================================================
'=============================================================================
'- SUBROUTINE : GET NEXT FILE NAME -> BitMapFileName + "_00x"
'- Called from Sub SAVE_PICTURE()
'=============================================================================
Private Sub GET_NEXT_FILENAME()
    Dim f, f1, fc
    Dim Fname As String
    Dim F3 As String    ' number
    Dim Flen As Integer ' length
    '-------------------------------------------------------------------------
    ' Set FSO = CreateObject("Scripting.FileSystemObject")' MOVED TO BEGINNING
    Set f = FSO.GetFolder(MyPictureFolder)
    Set fc = f.Files
    '- length of file name = name + number + suffix
    Flen = Len(BitmapFileName) + 4 + 4
    '-------------------------------------------------------------------------
    '- LOOP FILES IN FOLDER
    For Each f1 In fc
        Fname = f1.Name
        '---------------------------------------------------------------------
        '- check valid file and number
        F3 = Mid(Fname, Len(Fname) - 6, 3) ' number string
        If InStr(1, Fname, BitmapFileName, vbTextCompare) <> 0 _
            And IsNumeric(F3) And Len(Fname) = Flen Then
            FileNumber = CInt(F3)
            If FileNumber > LastFileNumber Then
                LastFileNumber = FileNumber
            End If
        End If
        '---------------------------------------------------------------------
    Next
    LastFileNumber = LastFileNumber + 1
    '-------------------------------------------------------------------------
    '- Next file name in series
    FullFileName = MyPictureFolder _
        & BitmapFileName & "_" & Format(LastFileNumber, "000") & ".bmp"
End Sub
'======== EOP ================================================================