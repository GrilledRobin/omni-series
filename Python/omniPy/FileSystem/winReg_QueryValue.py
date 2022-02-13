#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os, re, winreg

def winReg_QueryValue( key, val_name = None ) -> 'Get the value of [val_name] within the [key] of Windows Registry':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to query the value of [val_name] within the [key] of Windows Registry.                                   #
#   |It is useful to search for the installation path of any specific software on current Windows OS                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |key         :   Full valid path for Windows Registry within which to query the value                                               #
#   |val_name    :   Name of the sub-key within current [key], for which to query the value                                             #
#   |                 [None        ] <Default> Retrieve the [Default Value] of current [key], as indicated [(Default)] in Registry      #
#   |                 [<str>       ]           Provide a sub-key for query                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<various>   :   The search result in various types with respect of the Windows Registry. [None] is returned if not found           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220117        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, os, re, winreg                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if len(key) == 0: return(None)

    #050. Local parameters
    fullPath, rootName = os.path.split(key)
    while len(fullPath):
        fullPath, rootKey = os.path.split(fullPath)

    keyPath = re.sub(r'^[\\/]+', '', key[len(rootKey):])

    #100. Setup the connection to Windows Registry
    regConn = winreg.ConnectRegistry(None, winreg.__getattribute__(rootKey))

    #500. Try to obtain the value for the requested key
    #[ASSUMPTION]:
    #[1] The provided [key] may be invalid
    #[2] There may not be a [sub-key] of the provided [key]
    try:
        accKey = winreg.OpenKey(regConn, keyPath)
        rstOut = winreg.QueryValueEx(accKey, val_name)[0]
    except:
        rstOut = None

    #700. Close the connection
    winreg.CloseKey(regConn)

    #999. Return the values
    return(rstOut)
#End winReg_QueryValue

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import winReg_QueryValue
    print(winReg_QueryValue.__doc__)

    #100. Retrieve [SAS] installation path
    sasVer = '9.4'
    sasKey = os.path.join(r'HKEY_LOCAL_MACHINE\SOFTWARE\SAS Institute Inc.\The SAS System', sasVer)
    sasVal = r'DefaultRoot'
    print(winReg_QueryValue(sasKey, sasVal))

    #200. Retrieve [Python] installation path
    pyVer = '3.7'
    pyKey = os.path.join(r'HKEY_LOCAL_MACHINE\SOFTWARE\Python\PythonCore', pyVer, 'InstallPath')
    pyVal = None
    print(winReg_QueryValue(pyKey, pyVal))

    #300. Retrieve [R] installation path
    rKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\R-core\R64'
    rVal = r'InstallPath'
    print(winReg_QueryValue(rKey, rVal))
#-Notes- -End-
'''
