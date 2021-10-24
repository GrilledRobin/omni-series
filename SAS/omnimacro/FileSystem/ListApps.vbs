'listapps.vbs
'Generates a text file listing all 32bit & 64bit apps installed on the local machine
'===================================================================================

'Declare constants, variables and arrays
'---------------------------------------

'Registry keys and values
Const HKLM = &H80000002 'HKEY_LOCAL_MACHINE 

Dim arrKeys(1)
arrKeys(0) = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
arrKeys(1) = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"

strComputer = "." 
strEntry1a = "DisplayName" 
strEntry1b = "QuietDisplayName" 
strEntry2 = "Publisher"
strEntry3 = "InstallDate"
strEntry4 = "EstimatedSize"
strEntry5 = "DisplayVersion"

'Create the output file
Dim objShell, objShellEnv, strComputerName, objFso
Set objShell = WScript.CreateObject("WScript.Shell")
Set objShellEnv = objShell.Environment("Process")
strComputerName = objShellEnv("ComputerName")
Set objFso = WScript.CreateObject("Scripting.FileSystemObject")
Set outputFile = objFso.CreateTextFile(strComputerName & ".txt", True)
'===================================================================================

Set objReg = GetObject("winmgmts://" & strComputer & "/root/default:StdRegProv") 

'Print header (comment out the line below if you do not want headers in your output file)
'outputFile.WriteLine"Name" & vbTab & "Publisher" & vbTab & "Installed On" & vbTab & "Size" & vbTab & "Version" & VbCrLf 

For i = 0 to 1

  'Check to ensure registry key exists
  intCheckKey = objReg.EnumKey(HKLM, arrKeys(i), arrSubkeys)

  If intCheckKey = 0 Then
    For Each strSubkey In arrSubkeys 
      intReturn = objReg.GetStringValue(HKLM, arrKeys(i) & strSubkey, strEntry1a, strValue1) 

      If intReturn <> 0 Then 
        objReg.GetStringValue HKLM, arrKeys(i) & strSubkey, strEntry1b, strValue1 
      End If 

      objReg.GetStringValue HKLM, arrKeys(i) & strSubkey, strEntry2, strValue2
      objReg.GetStringValue HKLM, arrKeys(i) & strSubkey, strEntry3, strValue3
      objReg.GetDWORDValue HKLM, arrKeys(i) & strSubkey, strEntry4, strValue4
      objReg.GetStringValue HKLM, arrKeys(i) & strSubkey, strEntry5, strValue5

    If strValue1 <> "" Then
      outputFile.WriteLine strValue1 & vbTab & strValue2 & vbTab & strValue3 & vbTab & strValue4 & vbTab & strValue5
    End If

    Next 

  End If

Next 

'Close the output file
outputFile.Close

'Launch output file for review
objShell.run "notepad.exe " & strComputerName & ".txt"

'Clean up and exit
Set objShell = Nothing
Set objFso = Nothing