#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os, re, winreg
import collections as clt
from collections.abc import Callable
from omniPy.AdvOp import thisFunction

def winReg_getInfByStrPattern(
    inKEY : str
    ,inRegExp : str = r'^HK_Def$'
    ,exRegExp : str = r'^$'
    ,chkType : int = 1
    ,recursive : bool = False
    ,loggerInf : Callable = print
) -> 'Get the information of the Windows Registry Item':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to query the information of the Windows Registry Item.                                                   #
#   |It is useful to search for the installation path of any specific software on current Windows OS                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKEY       :   The Key within which to search for the item in Windows Registry, e.g. <HKEY_LOCAL_MACHINE\SOFTWARE>                #
#   |inRegExp    :   Name pattern of the item, i.e. <sub-key>s or the name of <value>s for a key                                        #
#   |                NOTE: If one needs to query the unnamed <Default> value of a key, just input '^HK_Def$' for this argument          #
#   |                 [^HK_Def$    ] <Default> Query the unnamed <Default> value of <inKEY>                                             #
#   |exRegExp    :   Name pattern of the item to be excluded from the searching result                                                  #
#   |                 [^$          ] <Default> Do not exclude any valid pattern                                                         #
#   |chkType     :   Type of the item to be searched                                                                                    #
#   |                 [1           ] <Default> Query the content of <value> of any Windows Registry Item                                #
#   |                 [2           ]           Query the names of <sub-key> of any Windows Registry Key (like a sub-directory)          #
#   |                 [0           ]           Query the names of <sub-key> and the content of <value> within the key                   #
#   |recursive   :   Whether to search for all sub-keys, if any, within the requested <inKEY> recursively                               #
#   |                 [False       ] <Default> Only query the direct subordinates of the requested <inKEY>                              #
#   |                 [True        ]           Query the names within all <sub-keys> in recursion                                       #
#   |loggerInf   :   Callable to print <NOTE> into the logging system for debugging purpose                                             #
#   |                 [print       ] <Default> Print the <NOTE> messages into current console                                           #
#   |                 [Callable    ]           Any Callable to conduct the log printing                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |list        :   List of dicts with below items:                                                                                    #
#   |                 [path        ] Full path in the Windows Registry of current item                                                  #
#   |                 [name        ] Name of the item, or 'HK_Default' when it is the unnamed default value of any key                  #
#   |                                NOTE: If the default value of any key is not set, there will not be a result for this key          #
#   |                 [value       ] Value of the item, when [chkType==0], it is the same as <name>                                     #
#   |                 [type        ] Type of the item, when [chkType==0], it is <None>                                                  #
#   |                 [regtype     ] Registry Type of the item, <subkey> or <value>                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20221015        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <thisFunction> to actually find the current callable being called instead of its name                         #
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
#   |   |sys, os, re, winreg, collections                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#   |   |   |thisFunction                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    recall = thisFunction()

    #012. Handle the parameter buffer.
    if len(inKEY.strip()) == 0:
        return([])
    if len(inRegExp.strip()) == 0:
        loggerInf( f'[{LfuncName}]No pattern is specified, program only searches default value for current key.' )
        inRegExp = r'^HK_Def$'
    if len(exRegExp.strip()) == 0:
        exRegExp = r'^$'
    if chkType not in [ 0 , 1 , 2 ]:
        loggerInf( f'[{LfuncName}]No type is specified. Program will search for <value> instead of <sub-key>.' )
        chkType = 1
    if not isinstance( recursive , bool ):
        raise TypeError( f'[{LfuncName}]Parameter [recursive] should be of the type [bool]!' )

    #015. Function local variables
    #Since the list is to be extended within the Generator, we use [deque] to improve the performance of [append()].
    rstOut = clt.deque([])
    reIN = re.compile( inRegExp.strip() , re.I | re.M | re.S | re.X )
    reEX = re.compile( exRegExp.strip() , re.I | re.M | re.S | re.X )
    rootKey, keyPath = inKEY.split(os.sep, 1)

    #100. Setup the connection to Windows Registry
    regConn = winreg.ConnectRegistry(None, winreg.__getattribute__(rootKey))

    #300. Try to obtain the value for the requested key
    #[ASSUMPTION]:
    #[1] The provided [inKEY] may be invalid
    #[2] There may not be a [sub-key] of the provided [inKEY]
    try:
        with winreg.OpenKeyEx(regConn, keyPath) as actkey:
            #100. Get the stats of the active key
            stats_key = winreg.QueryInfoKey(actkey)

            #400. Retrieve all <sub-key>s
            subKeys = [
                winreg.EnumKey(actkey, i)
                for i in range(stats_key[0])
            ]

            #500. Identify the requested <sub-key>
            if chkType != 1:
                for k in subKeys:
                    #500. Skip if it is requested to be excluded
                    if reEX.search(k): continue

                    #700. Skip if it does not match the requested pattern
                    if not reIN.search(k): continue

                    #900. Append the result
                    rstOut.append(
                        {
                            'path' : inKEY
                            ,'name' : k
                            ,'value' : k
                            ,'type' : None
                            ,'regtype' : 'subkey'
                        }
                    )
                #End For
            #End If

            #700. Retrieve the <value>
            if chkType != 2:
                for i in range(stats_key[1]):
                    #100. Extract current item
                    curr_item = winreg.EnumValue(actkey, i)

                    #300. Patch the result
                    curr_name = curr_item[0] or 'HK_Def'

                    #500. Skip if it is requested to be excluded
                    if reEX.search(curr_name): continue

                    #700. Skip if it does not match the requested pattern
                    if not reIN.search(curr_name): continue

                    #900. Append the result
                    rstOut.append(
                        {
                            'path' : inKEY
                            ,'name' : curr_name
                            ,'value' : curr_item[1]
                            ,'type' : curr_item[2]
                            ,'regtype' : 'value'
                        }
                    )
                #End For
            #End If
        #End With
    except:
        subKeys = []

    #500. Close the connection
    winreg.CloseKey(regConn)

    #700. Continue the recursion when required
    if recursive:
        for k in subKeys:
            rstOut.extend(
                recall(
                    os.path.join(inKEY, k)
                    ,inRegExp = inRegExp
                    ,exRegExp = exRegExp
                    ,chkType = chkType
                    ,recursive = recursive
                    ,loggerInf = loggerInf
                )
            )
        #End For
    #End If

    #999. Return the values
    return(list(rstOut))
#End winReg_getInfByStrPattern

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import winReg_getInfByStrPattern
    print(winReg_getInfByStrPattern.__doc__)

    import os
    from packaging import version

    #100. Retrieve the installation path for the latest version of [SAS] installed
    #Quote: https://thewebdev.info/2022/04/12/how-to-compare-version-numbers-in-python-2/
    sasKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\SAS Institute Inc.\The SAS System'
    #The names of the direct sub-keys are the version numbers of all installed [SAS] software
    sasVers = winReg_getInfByStrPattern(sasKey, inRegExp = r'^.*$', chkType = 2)
    if len(sasVers):
        sasVers_comp = [ version.parse(v.get('name', None)) for v in sasVers ]
        sasVer = sasVers[sasVers_comp.index(max(sasVers_comp))].get('name', None)
        print(winReg_getInfByStrPattern(os.path.join(sasKey, sasVer), 'DefaultRoot')[0]['value'])

    #200. Retrieve the installation path for the latest version of [Python] installed
    pyKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\Python\PythonCore'
    #The names of the direct sub-keys are the version numbers of all installed [Python] software
    pyVers = winReg_getInfByStrPattern(pyKey, inRegExp = r'^.*$', chkType = 2)
    if len(pyVers):
        pyVers_comp = [ version.parse(v.get('name', None)) for v in pyVers ]
        pyVer = pyVers[pyVers_comp.index(max(pyVers_comp))].get('name', None)
        #We search for the <Default> value of below path
        print(winReg_getInfByStrPattern(os.path.join(pyKey, pyVer, 'InstallPath'))[0]['value'])

    #300. Retrieve [R] installation path
    rKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\R-core\R64'
    rVal = r'InstallPath'
    r_install = winReg_getInfByStrPattern(rKey, rVal)
    if len(r_install):
        print(r_install[0]['value'])
#-Notes- -End-
'''
