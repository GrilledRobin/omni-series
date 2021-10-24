'I found this online for displaying all users and there login dates from all domain controllers.
'i tried to input text to a file vise having it echo in a command window.. and i don't know exactly what i did wrong.. here is the text..

Option Explicit

dim filesys, filetxt
Cons ForReading = 1, ForWriting = 2, ForAppending = 8
Set filesys = Create Object("Scripting.FilesystemObject")
Set filetxt = filesys.OpenTextFile("lastlogon.txt", ForAppending, True)

Dim objRootDSE, strConfig, adoConnection, adoCommand, strQuery
Dim adoRecordset, objDC
Dim strDNSDomain, objShell, lngBiasKey, lngBias, k, arrstrDCs()
Dim strDN, dtmDate, objDate, objList, strUser
Dim strBase, strFilter, strAttributes, lngHigh, lngLow

' Use a dictionary object to track latest lastLogon for each user.
Set objList = CreateObject("Scripting.Dictionary")
objList.CompareMode = vbTextCompare

' Obtain local Time Zone bias from machine registry.
' This bias changes with Daylight Savings Time.
Set objShell = CreateObject("Wscript.Shell")
lngBiasKey = objShell.RegRead("HKLM\System\CurrentControlSet\Control\" _
    & "TimeZoneInformation\ActiveTimeBias")
If (UCase(TypeName(lngBiasKey)) = "LONG") Then
    lngBias = lngBiasKey
ElseIf (UCase(TypeName(lngBiasKey)) = "VARIANT()") Then
    lngBias = 0
    For k = 0 To UBound(lngBiasKey)
        lngBias = lngBias + (lngBiasKey(k) * 256^k)
    Next
End If

' Determine configuration context and DNS domain from RootDSE object.
Set objRootDSE = GetObject("LDAP://RootDSE")
strConfig = objRootDSE.Get("configurationNamingContext")
strDNSDomain = objRootDSE.Get("defaultNamingContext")

' Use ADO to search Active Directory for ObjectClass nTDSDSA.
' This will identify all Domain Controllers.
Set adoCommand = CreateObject("ADODB.Command")
Set adoConnection = CreateObject("ADODB.Connection")
adoConnection.Provider = "ADsDSOObject"
adoConnection.Open "Active Directory Provider"
adoCommand.ActiveConnection = adoConnection

strBase = "<LDAP://" & strConfig & ">"
strFilter = "(objectClass=nTDSDSA)"
strAttributes = "AdsPath"
strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"

adoCommand.CommandText = strQuery
adoCommand.Properties("Page Size") = 100
adoCommand.Properties("Timeout") = 60
adoCommand.Properties("Cache Results") = False

Set adoRecordset = adoCommand.Execute

' Enumerate parent objects of class nTDSDSA. Save Domain Controller
' AdsPaths in dynamic array arrstrDCs.
k = 0
Do Until adoRecordset.EOF
    Set objDC = _
        GetObject(GetObject(adoRecordset.Fields("AdsPath").Value).Parent)
    ReDim Preserve arrstrDCs(k)
    arrstrDCs(k) = objDC.DNSHostName
    k = k + 1
    adoRecordset.MoveNext
Loop
adoRecordset.Close

' Retrieve lastLogon attribute for each user on each Domain Controller.
For k = 0 To Ubound(arrstrDCs)
    strBase = "<LDAP://" & arrstrDCs(k) & "/" & strDNSDomain & ">"
    strFilter = "(&(objectCategory=person)(objectClass=user))"
    strAttributes = "distinguishedName,lastLogon"
    strQuery = strBase & ";" & strFilter & ";" & strAttributes _
        & ";subtree"
    adoCommand.CommandText = strQuery
    On Error Resume Next
    Set adoRecordset = adoCommand.Execute
    If (Err.Number <> 0) Then
        On Error GoTo 0
        Wscript.Echo "Domain Controller not available: " & arrstrDCs(k)
    Else
        On Error GoTo 0
        Do Until adoRecordset.EOF
            strDN = adoRecordset.Fields("distinguishedName").Value
            On Error Resume Next
            Set objDate = adoRecordset.Fields("lastLogon").Value
            If (Err.Number <> 0) Then
                On Error GoTo 0
                dtmDate = #1/1/1601#
            Else
                On Error GoTo 0
                lngHigh = objDate.HighPart
                lngLow = objDate.LowPart
                If (lngLow < 0) Then
                    lngHigh = lngHigh + 1
                End If
                If (lngHigh = 0) And (lngLow = 0) Then
                    dtmDate = #1/1/1601#
                Else
                    dtmDate = #1/1/1601# + (((lngHigh * (2 ^ 32)) _
                        + lngLow)/600000000 - lngBias)/1440
                End If
            End If
            If (objList.Exists(strDN) = True) Then
                If (dtmDate > objList(strDN)) Then
                    objList.Item(strDN) = dtmDate
                End If
            Else
                objList.Add strDN, dtmDate
            End If
            adoRecordset.MoveNext
        Loop
        adoRecordset.Close
    End If
Next

' Output latest lastLogon date for each user.
For Each strUser In objList.Keys
    If (objList.Item(strUser) = #1/1/1601#) Then
        Wscript.Echo strUser & ";Never"
    Else
        Wscript.Echo strUser & ";" & objList.Item(strUser)
    End If
Next

' Clean up.
adoConnection.Close