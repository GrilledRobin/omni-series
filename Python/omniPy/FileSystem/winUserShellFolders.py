#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#We have to import [pywintypes] to activate the DLL required by [win32com]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes

import sys
import numpy as np
from win32com.client import Dispatch
from collections import OrderedDict

def winUserShellFolders( *arg , inplace = True , **kw ) -> 'Get the [User Shell Folders] for all users or current user on Windows OS':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the special folders called [User Shell Folders] on Windows OS                                #
#   |[Supported values] (when providing below values as [str])                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |AllUsersDesktop, AllUsersStartMenu, AllUsersPrograms, AllUsersStartup, Desktop, Favorites, Fonts, MyDocuments, NetHood, PrintHood, #
#   | Recent, SendTo, StartMenu, Startup & Templates                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Way to find them]: https://stackoverflow.com/questions/2063508/find-system-folder-locations-in-python                             #
#   |[Names to find   ]: https://ss64.com/vb/special.html                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |arg         :   Any positional arguments that represent [special folder names] for search in Windows COM                           #
#   |inplace     :   Whether to keep the output the same as the input values if any cannot be found as [special folder names]           #
#   |                 [True        ] <Default> Keep the input values as output if they cannot be found                                  #
#   |                 [False       ]           Output [None] for those which cannot be found                                            #
#   |kw          :   Various named parameters, whose [names] are used as names in output, while their [values] will be used to search   #
#   |                 as [special folder names]                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>   :   This function output different values in below convention:                                                         #
#   |                [1] If [kw] is provided with at least one element, return a [dict], with:                                          #
#   |                    [names ] [str('.arg' + pos. num)] for [positional arguments] and [keys] for [kw]                               #
#   |                    [values] absolute paths to the [names], or [None] if not available                                             #
#   |                [2] If there is only one positional argument provided, return the value assigned to it if any                      #
#   |                [3] In other cases (i.e. many positional arguments), return a [tuple] with values in the same order as provided    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210731        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, numpy, pywintypes, win32com, collections                                                                                  #
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
    if inplace is None: inplace = True
    if not isinstance( inplace , bool ): inplace = True
    if (not arg) and (not kw): return()

    #050. Local parameters
    dict_found , dict_rest = {} , {}
    if arg:
        arg_arglen = len(str(len(arg)))
        dict_rest.update({ '.arg'+str(i).zfill(arg_arglen) : arg[i] for i in range(len(arg)) })
    if kw: dict_rest.update(kw)

    #100. Setup the shell command for retrieval
    objShell = Dispatch('WScript.Shell')

    #500. Retrieve the absolute paths of the provided special names
    for k,v in dict_rest.items():
        #100. Retrieve the valid folders, or set [None] as output
        #[SpecialFolders] returns a blank string when provided an invalid string, but raises an error when provided an invalid number.
        try:
            getshell = objShell.SpecialFolders(v)
        except:
            getshell = None

        #500. Set the result in terms of [inplace]
        if not getshell:
            getshell = v if inplace else None

        #900. Update the output result
        dict_found.update({k : getshell})

    #999. Return the values
    if kw:
        return(dict_found)
    elif len(arg)==1:
        return(list(dict_found.values())[0])
    else:
        return(tuple(OrderedDict(sorted(dict_found.items())).values()))
#End winUserShellFolders

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import winUserShellFolders
    print(winUserShellFolders.__doc__)

    #100. Retrieve [My Documents] for current logged user
    MyDocs = winUserShellFolders('MyDocuments')

    #300. Retrieve several special folders at the same time
    curr_desktop, curr_startmenu = winUserShellFolders('Desktop', 'StartMenu')

    #400. Provide an integer for retrieval
    startMenu = winUserShellFolders(1)

    #500. Provide named arguments
    spfolders = winUserShellFolders('Favorites', chkfonts = 'Fonts')

    #800. Test when the folder names are stored in a [collections.abc.Iterable]
    v_df = pd.DataFrame({ 'folders':['MyDocuments' , 'Favorites'] })
    testseries = winUserShellFolders(*v_df['folders'])
    testseries2 = v_df['folders'].apply(winUserShellFolders)

    #900. Test invalid folders
    test_invld = winUserShellFolders(100, 5)
    test_invld2 = winUserShellFolders(100, chk = 5, inplace = False)
#-Notes- -End-
'''
