dim a(2) 
 dim b() 
 redim b(3) 
 a(0)=b 
 redim b(5) 
 b(2) = "test"
 
 MsgBox ubound(a(0))
 
 a(0)=b 
 MsgBox ubound(a(0))
 
 MsgBox a(0)(2)