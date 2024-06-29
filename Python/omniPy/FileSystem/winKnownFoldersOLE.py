#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import ctypes
import pandas as pd
from ctypes import wintypes
from . import getMSDNKnownFolderIDDoc

#Load necessary DLL
_ole32 = ctypes.OleDLL('ole32')
_shell32 = ctypes.OleDLL('shell32')

#Define helper class
class GUID(ctypes.Structure):
    _fields_ = (
        ('Data1', ctypes.c_ulong)
        ,('Data2', ctypes.c_ushort)
        ,('Data3', ctypes.c_ushort)
        ,('Data4', ctypes.c_char * 8)
    )
    def __init__(self, guid_string):
        _ole32.IIDFromString(guid_string, ctypes.byref(self))

#Define the reference to Known Folder ID
REFKNOWNFOLDERID = LPIID = ctypes.POINTER(GUID)

#Set properties of the loaded DLLs
_ole32.IIDFromString.argtypes = (
    #[lpsz]
    wintypes.LPCWSTR
    #[lpiid]
    ,LPIID
)

_ole32.CoTaskMemFree.restype = None
_ole32.CoTaskMemFree.argtypes = (wintypes.LPVOID,)

_shell32.SHGetKnownFolderPath.argtypes = (
    #[RFID]
    REFKNOWNFOLDERID
    #[dwFlags]
    ,wintypes.DWORD
    #[hToken]
    ,wintypes.HANDLE
    #[ppszPath]
    ,ctypes.POINTER(wintypes.LPWSTR)
)

#Define primary function
def winKnownFoldersOLE(
    *arg
    ,inplace = True
    ,hToken = None
    ,**kw
) -> 'Get the [Known Folders] for all users or current user on Windows OS':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the special folders called [Known Folders] on Windows OS, derived from [KnownFolderID]       #
#   |Similar to the equivalent <winKnownFolders>, this function uses OLE modules for retrieval with the <FOLDERID> hardcoded            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Original Article     ]: https://stackoverflow.com/questions/33179365/python-finding-user-id-and-moving-directories-windows        #
#   |[MSDN Reference       ]: https://msdn.microsoft.com/en-us/library/dd378457                                                         #
#   |[SHGetKnownFolderPath ]: https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |arg         :   Any positional arguments that represent [special folder names] for search in Windows Registry                      #
#   |inplace     :   Whether to keep the output the same as the input values if any cannot be found as [special folder names]           #
#   |                 [True        ] <Default> Keep the input values as output if they cannot be found                                  #
#   |                 [False       ]           Output [None] for those which cannot be found                                            #
#   |hToken      :   Access Token (as a HANDLE) that represents a particular user, [None] means current user                            #
#   |                 [None        ] <Default> Requests Known Folders for current user                                                  #
#   |                 [WIN HANDLE  ]           Access token for any requested user                                                      #
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
#   | Date |    20211106        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, ctypes, pandas                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |getMSDNKnownFolderIDDoc                                                                                                    #
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
    dict_rest = {}
    if arg:
        arg_arglen = len(str(len(arg)))
        dict_rest.update({ '.arg'+str(i).zfill(arg_arglen) : arg[i] for i in range(len(arg)) })
    if kw: dict_rest.update(kw)

    #100. Prepare a data frame for the input arguments
    df_args = pd.DataFrame({ 'args' : dict_rest.keys(), 'vals' : dict_rest.values() })

    #200. Load all available entries of [Known Folder ID] to Windows Registry (See MSDN link)
    df_FOLDERID = getMSDNKnownFolderIDDoc()

    #300. Prepare the items that are available for retrieval
    df_args['GUID'] = (
        df_FOLDERID
        .set_index('FOLDERID')
        .reindex(df_args['vals'])
        .set_axis(df_args.index, axis = 0)
        ['GUID']
    )

    #400. Define helper function
    def h_getfolder(fid):
        c_GUID = GUID(fid)
        pszPath = wintypes.LPWSTR()
        _shell32.SHGetKnownFolderPath(
            ctypes.byref(c_GUID)
            ,0
            ,hToken
            ,ctypes.byref(pszPath)
        )
        getname = pszPath.value
        _ole32.CoTaskMemFree(pszPath)
        return(getname)

    #500. Retrieve the absolute paths of the provided special names
    df_args['path'] = df_args['GUID'].loc[lambda x: x.notnull()].apply(h_getfolder)
    if inplace:
        df_args.loc[df_args['GUID'].isnull(), 'path'] = df_args.loc[df_args['GUID'].isnull(), 'vals']

    #999. Return the values
    if kw:
        #100. Split the data into dict for output
        kwSplit = df_args[['args', 'path']].to_dict('split')['data']

        #500. Translate above dict
        kwRst = { v[0] : (None if pd.isnull(v[-1]) else v[-1]) for v in kwSplit }

        #999. Output
        return(kwRst)
    elif len(arg)==1:
        #100. Only retrieve the first item as is
        valRst = df_args.at[0, 'path']

        #500. Avoid [NaN] value
        if pd.isnull(valRst): valRst = None

        #999. Output
        return(valRst)
    else:
        #100. Convert the result into list
        lstRst = df_args['path'].to_list()

        #500. Convert to tuple and avoid [Nan] value
        tupRst = tuple([ None if pd.isnull(v) else v for v in lstRst ])

        #999. Output
        return(tupRst)
#End winKnownFoldersOLE

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import winKnownFoldersOLE, getMSDNKnownFolderIDDoc
    print(winKnownFoldersOLE.__doc__)

    #100. Retrieve [My Documents] for current logged user
    MyDocs = winKnownFoldersOLE('Documents')

    #300. Retrieve several special folders at the same time
    curr_desktop, curr_startmenu = winKnownFoldersOLE('Desktop', 'StartMenu')

    #500. Provide named arguments
    spfolders = winKnownFoldersOLE('Favorites', chkfonts = 'Fonts')

    #800. Test when the folder names are stored in a [collections.abc.Iterable]
    v_df = pd.DataFrame({ 'folders':['Documents' , 'Favorites'] })
    testseries = winKnownFoldersOLE(*v_df['folders'])
    testseries2 = v_df['folders'].apply(winKnownFoldersOLE)

    #900. Test invalid folders
    test_invld = winKnownFoldersOLE('Downloads', 'Robin')
    test_invld2 = winKnownFoldersOLE('Downloads', chk = 'Robin', inplace = False)

    #990. Get the available [FOLDERID]s for retrieval
    dodLocale = getMSDNKnownFolderIDDoc()
    print(dodLocale[['FOLDERID', 'GUID']])
#-Notes- -End-
'''
