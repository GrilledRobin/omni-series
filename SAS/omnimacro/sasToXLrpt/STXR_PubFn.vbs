Public Const vbUpperCase    = 1
Public Const vbLowerCase    = 2
Public Const vbProperCase   = 3
Public Const vbWide         = 4
Public Const vbNarrow       = 8
Public Const vbUnicode      = 64
Public Const vbFromUnicode  = 128

Public Function StrConv(ByVal varIn, ByVal iConv)
    Dim i, c
    Dim ret
    Select Case iConv
    Case vbUpperCase
        ret = UCase(varIn)
    Case vbLowerCase
        ret = LCase(varIn)
    Case vbProperCase
        Dim tmp
        tmp = Split(varIn, " ")
        For i = 0 To UBound(tmp)
            ret = ret & UCase(Mid(tmp(i), 1, 1)) & Mid(tmp(i), 2)
        Next
    Case vbWide
        For i = 1 To Len(varIn)
            c = AscW(Mid(varIn, i, 1))
            If c < 0 Then c = c + 65536
            If c = 32 Then
                ret = ret & ChrW(12288)
            ElseIf c < 128 Then
                ret = ret & ChrW(c + 65248)
            Else
                ret = ret & ChrW(c)
            End If
        Next
    Case vbNarrow
        For i = 1 To Len(varIn)
            c = AscW(Mid(varIn, i, 1))
            If c < 0 Then c = c + 65536
            If c = 12288 Then
                ret = ret & ChrW(32)
            ElseIf c > 65280 And c < 65375 Then
                ret = ret & ChrW(c- 65248)
            Else
                ret = ret & ChrW(c)
            End If
        Next
    Case vbUnicode
        For i = 1 To LenB(varIn)
            c = AscB(MidB(varIn, i, 1))
            If c < 0 Then c = c + 65536
            If c = 0 Then
                'Pass
            ElseIf c < 128 Then
                ret = ret & Chr(c)
            Else
                c = LShift(c, 8) Or AscB(MidB(varIn, i + 1, 1))
                ret = ret & Chr(c)
                i = i + 1
            End If
        Next
    Case vbFromUnicode
        For i = 1 To Len(varIn)
            c = Asc(Mid(varIn, i, 1))
            If c < 0 Then c = c + 65536
            If c < 128 Then
                ret = ret & ChrB(c)
                ret = ret & ChrB(0)
            Else
                ret = ret & ChrB(RShift(c, 8))
                ret = ret & ChrB(c And &HFF)
            End If
        Next
    End Select
    StrConv = ret
End Function

Public Function LShift(ByVal lValue, ByVal iShiftBits)
    LShift = lValue * (2 ^ iShiftBits)
End Function

Public Function RShift(ByVal lValue, ByVal iShiftBits)
    RShift = lValue \ (2 ^ iShiftBits)
End Function

function StrLen(str)
    dim cnt
    cnt=0
    StrLen=0
    cnt=len(str)
    for i=1 to cnt
        if asc(mid(str,i,1)) < 0 then
            StrLen=int(StrLen) + 2
        else
            StrLen=int(StrLen) + 1
        end if
     next
end function