#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from win32com.shell import shell, shellcon
from pywintypes import com_error

def winKnownFolders(
    *arg
    ,inplace = True
    ,dwFlags = shellcon.KF_FLAG_DEFAULT
    ,hToken = None
    ,**kw
) -> str | tuple | dict:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the special folders called <Known Folders> on Windows OS, derived from <KnownFolderID>       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Original Article     ]: https://stackoverflow.com/questions/33179365/python-finding-user-id-and-moving-directories-windows        #
#   |[MSDN Reference       ]: https://msdn.microsoft.com/en-us/library/dd378457                                                         #
#   |[SHGetKnownFolderPath ]: https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath        #
#   |[Shell Solution       ]: https://stackoverflow.com/questions/29888071/                                                             #
#   |[KNOWN_FOLDER_FLAG    ]: https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/ne-shlobj_core-known_folder_flag          #
#   |[KNOWNFOLDERID        ]: https://learn.microsoft.com/zh-cn/windows/win32/shell/knownfolderid                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |*arg        :   Any positional arguments that represent <special folder names> for search in Windows Registry                      #
#   |inplace     :   <bool> Whether to keep the output the same as the input values if any cannot be found as <special folder names>    #
#   |                 [True        ] <Default> Keep the input values as output if they cannot be found                                  #
#   |                 [False       ]           Output <None> as placeholder for those which cannot be found                             #
#   |dwFlags     :   <int > DWARD flags that specify special retrieval options                                                          #
#   |                 [<see def.>  ] <Default> No special retrieval options                                                             #
#   |                 [<int>       ]           See constants <shellcon.KF_FLAG_*>                                                       #
#   |hToken      :   <int > Access Token (as a <HANDLE>) that represents a particular user, <None> means current user                   #
#   |                 [None        ] <Default> Requests Known Folders for current user                                                  #
#   |                 [WIN HANDLE  ]           Access token for any requested user                                                      #
#   |**kw        :   Various named parameters, whose <names> are used as names in output, while their <values> will be used to search   #
#   |                 as <special folder names>                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>   :   This function output different values in below convention:                                                         #
#   |                [1] If <**kw> is provided with at least one element, return a <dict>, with:                                        #
#   |                    [names ] <str('.arg' + pos. num)> for <positional arguments> and <keys> for <**kw>                             #
#   |                    [values] absolute paths to the <names>, or <None> if not available                                             #
#   |                [2] If there is only one positional argument provided, return the value assigned to it if any                      #
#   |                [3] In other cases (i.e. many positional arguments), return a <tuple> with values in the same order as provided    #
#   |                [4] If neither <*args> nor <**kw> is provided, return the full result of Known Folders in the same format as <1>   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240617        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |pandas, win32com, pywintypes                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #012. Handle the parameter buffer.
    if inplace is None: inplace = True
    if not isinstance( inplace , bool ): inplace = True

    #050. Local parameters
    get_default = False
    folder_con = [ n.replace('FOLDERID_','',1) for n in dir(shellcon) if n.startswith('FOLDERID_') ]
    dict_rest = {}
    if arg:
        arg_arglen = len(str(len(arg)))
        dict_rest.update({ '.arg'+str(i).zfill(arg_arglen) : arg[i] for i in range(len(arg)) })

    #070. Return the available mapping if no specific name is requested
    if (not arg) and (not kw):
        get_default = True
        kw = { n:n for n in folder_con }

    #080. Append the request
    if kw: dict_rest.update(kw)

    #200. Define helper functions
    #210. Function to obtain the attributes from a module
    def safe_getattr(attr_):
        if hasattr(shellcon, attr_):
            return(getattr(shellcon, attr_))
        else:
            return(None)

    #250. Function to obtain the absolute path of an <rfid>
    def h_getfolder(fid):
        try:
            return(shell.SHGetKnownFolderPath(fid, dwFlags, hToken))
        except com_error:
            return(None)

    #300. Prepare a data frame for the input arguments
    df_args = (
        pd.DataFrame(dict_rest.items(), columns = ['args','vals'], dtype = 'O')
        .assign(**{
            'rfid' : lambda x: x['vals'].radd('FOLDERID_').apply(safe_getattr)
        })
    )

    #500. Retrieve the absolute paths of the provided special names
    df_args['path'] = df_args['rfid'].loc[lambda x: x.notnull()].apply(h_getfolder)
    if get_default:
        df_args = df_args.loc[df_args['path'].notnull()]
    if inplace:
        df_args.loc[df_args['rfid'].isnull(), 'path'] = df_args.loc[df_args['rfid'].isnull(), 'vals']

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
#End winKnownFolders

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys, os
    import pandas as pd
    import xlwings as xw
    from win32com.shell import shellcon
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import winKnownFolders
    from omniPy.AdvOp import xwDfToRange
    print(winKnownFolders.__doc__)

    #100. Retrieve [My Documents] for current logged user
    MyDocs = winKnownFolders('Documents')

    #300. Retrieve several special folders at the same time
    curr_desktop, curr_startmenu = winKnownFolders('Desktop', 'StartMenu')

    #500. Provide named arguments
    spfolders = winKnownFolders('Favorites', chkfonts = 'Fonts')

    #800. Test when the folder names are stored in a [collections.abc.Iterable]
    v_df = pd.DataFrame({ 'folders':['Documents' , 'Favorites'] })
    testseries = winKnownFolders(*v_df['folders'])
    testseries2 = v_df['folders'].apply(winKnownFolders)

    #900. Test invalid folders
    test_invld = winKnownFolders('Downloads', 'Robin')
    test_invld2 = winKnownFolders('Downloads', chk = 'Robin', inplace = False)

    #990. Get the available [FOLDERID]s for retrieval
    dodLocale = winKnownFolders()
    # print(dodLocale)

    #995. Export the full result for cross-platform usage
    foldermap = (
        pd.DataFrame(dodLocale.items(), columns = ['Name','Path'])
        .assign(**{
            'FOLDERID' : lambda x: x['Name'].radd('FOLDERID_').apply(lambda row: shellcon.__getattribute__(row))
        })
    )

    #We do not use <df.to_excel()> as it is NOT a correct format while we have to <SaveAs> it via MS EXCEL
    args_axis = {
        'index' : False
        ,'header' : True
    }
    xlfile = os.path.join(winKnownFolders('Documents'), 'shellcon.xlsx')
    if os.path.isfile(xlfile): os.remove(xlfile)
    with xw.App( visible = False, add_book = True ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Identify the EXCEL workbook
        xlwb = xlapp.books[0]

        #300. Define the sheet
        xlsh = xlwb.sheets[0]

        #400. Define the range
        xlrng = (
            xlsh.range((1,1)).expand()
            .options(pd.DataFrame, **args_axis)
        )

        #500. Export the data
        xwDfToRange(
            xlrng
            ,foldermap
            ,theme = None
            ,fmtCol = [
                #Set below column as string
                {
                    'slicer' : '.all.'
                    ,'attrs' : {
                        'NumberFormat' : {
                            'attr' : 'api.NumberFormat'
                            ,'val' : '@'
                        }
                    }
                }
            ]
            ,**args_axis
        )

        #800. More settings
        xlsh.autofit()

        #999. Purge
        xlwb.save(xlfile)
        xlwb.close()
        xlapp.screen_updating = True

    #Remove the file when it is out of usage
    if os.path.isfile(xlfile): os.remove(xlfile)
#-Notes- -End-
'''
