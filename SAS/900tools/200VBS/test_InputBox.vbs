Function GetUserInput(myPrompt)
' This function uses Internet Explorer to
' create a dialog and prompt for user input.
'
'
' Argument:   [string] prompt text, e.g. "Please enter your name:"
' Returns:    [string] the user input typed in the dialog screen
'

    Dim objIE

    ' Create an IE object
    Set objIE = CreateObject("InternetExplorer.Application")

    ' Specify some of the IE window's settings
    objIE.Navigate "about:blank"
    objIE.Document.Title = "Input required " & String(100, ".")
    objIE.ToolBar = False
    objIE.Resizable = False
    objIE.StatusBar = False
    objIE.Width = 640
    objIE.Height = 480

    ' Center the dialog window on the screen
    With objIE.Document.ParentWindow.screen
        objIE.Left = (.AvailWidth - objIE.Width) \ 2
        objIE.Top = (.Availheight - objIE.Height) \ 2
    End With

    ' Wait till IE is ready
    Do While objIE.Busy
'        WScript.Sleep 200
    Loop
    ' Insert the HTML code to prompt for user input
    objIE.Document.Body.InnerHTML = "<div align=""center""><p>" & myPrompt _
                                  & "</p>" & vbCrLf _
                                  & "<p><input type=""text"" size=""20"" " _
                                  & "id=""UserInput""></p>" & vbCrLf _
                                  & "<p><input type=""hidden"" id=""OK"" " _
                                  & "name=""OK"" value=""0"">" _
                                  & "<input type=""submit"" value="" OK "" " _
                                  & "OnClick=""VBScript:OK.Value=1""></p></div>" _
                                  & "<form action="""">" _
                                  & "<select name=""NCA"">" _
                                  & "<option value=""N"">Option 1</option>" _
                                  & "<option value=""C"">Option 2</option>" _
                                  & "<option value=""A"">Option 3 and final!</option>" _
                                  & "</select>" _
                                  & "</form>"


    ' Hide the scrollbars
    objIE.Document.Body.Style.overflow = "auto"
    ' Make the window visible
    objIE.Visible = True
    ' Set focus on input field
    objIE.Document.All.UserInput.Focus

    ' Wait till the OK button has been clicked
    On Error Resume Next
    Do While objIE.Document.All.OK.value = 0
 '       WScript.Sleep 200
        
        If Err Then ' user clicked red X (or alt-F4) to close IE window
            IELogin = Array("", "")
            objIE.Quit
            Set objIE = Nothing
            Exit Function
        End If
    Loop
    On Error GoTo 0


    ' Read the user input from the dialog window
    GetUserInput = objIE.Document.All.UserInput.value & "|" & objIE.Document.All.NCA.value
    ' Close and release the object
    objIE.Quit
    Set objIE = Nothing

End Function

strInput = GetUserInput("Please enter loan number:")
strUserInput = Split(strInput, "|")(0)
strUserDropDown = Split(strInput, "|")(1)

WScript.Echo strUserInput & " ; " & strUserDropDown
