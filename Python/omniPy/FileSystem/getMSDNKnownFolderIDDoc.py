#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os
import requests
import pandas as pd
from inspect import getsourcefile
from bs4 import BeautifulSoup
from warnings import warn
from omniPy.AdvOp import apply_MapVal, getWinUILanguage

#Get the location of current script
#Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
path_thisfile : str = getsourcefile(lambda:0)

#Define primary function
def getMSDNKnownFolderIDDoc(
    lang = getWinUILanguage()
    ,update = False
    ,save_hdf = os.path.join(os.path.dirname(path_thisfile), 'getMSDNKnownFolderIDDoc.hdf')
    ,key_hdf = 'KnownFolders'
) -> 'Get the document of [Known Folders on Windows OS] from MSDN and export a readable table':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the document of [Known Folders on Windows OS] from MSDN and export a readable table               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[NOTE] Specify [update=True] for the first time and then [update=False] for the rest time to save internet connection              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[MSDN Reference EN    ]: https://msdn.microsoft.com/en-us/library/dd378457                                                         #
#   |[MSDN Reference CN    ]: https://docs.microsoft.com/zh-cn/windows/win32/shell/knownfolderid?redirectedfrom=MSDN                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |lang        :   The language that indicates the URL from which to scrape the contents of dedicated <table>                         #
#   |update      :   Whether to update the document from the latest URL                                                                 #
#   |                 [False       ] <Default> Use the existing [HDF] storage by default, in case there is no internet connection       #
#   |                 [True        ]           Update the existing [HDF] storage by the latest URL at the mean time                     #
#   |save_hdf    :   The HDF storage to store the data scraped from the URL                                                             #
#   |                 [<str>       ] <Default> HDF storage in the same directory as this script, see function definition                #
#   |key_hdf     :   The <key> in the HDF storage to store the data scraped from the URL                                                #
#   |                 [KnownFolders] <Default> The default <key>                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<df>        :   Data Frame with below columns                                                                                      #
#   |                [FOLDERID             ] ID of Known Folders, which can be prefixed by [FOLDERID_] to represent the constant in C   #
#   |                [GUID                 ] The GUID to search in Windows Registry                                                     #
#   |                [Display Name         ] The Display Name of the dedicated folder in the Display Language of current Windows OS     #
#   |                [Folder Type          ] Type of the folder for identification by group                                             #
#   |                [Default Path         ] Default path to the folder on harddisk in terms of MS DOS constants                        #
#   |                [CSIDL Equivalent     ] Equivalent value as CSIDL constants                                                        #
#   |                [Legacy Display Name  ] Legacy Name displayed in the older versions of Windows                                     #
#   |                [Legacy Default Path  ] Legacy path in the older versions of Windows                                               #
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
#   |   |sys, os, requests, pandas, bs4, warnings, inspect                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |getWinUILanguage                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    dict_url = {
        'zh_CN' : 'https://docs.microsoft.com/zh-cn/windows/win32/shell/knownfolderid?redirectedfrom=MSDN'
        ,'en_US' : 'https://msdn.microsoft.com/en-us/library/dd378457'
    }
    if lang not in dict_url:
        warn('[' + LfuncName + ']URL for [lang]:[{0}] is not defined, use [en_US] instead!'.format( lang ))
        lang = 'en_US'
    if not update:
        if os.path.isfile(save_hdf):
            outRst = pd.read_hdf(save_hdf, key_hdf)
            return(outRst)

    #050. Local parameters
    site_url = dict_url[lang]
    bgn_FOLDERID = 'FOLDERID_'

    #055. Mapping dict to unify the column names
    dict_ColMap = {
        u'显示名称' : 'Display Name'
        ,u'文件夹类型' : 'Folder Type'
        ,r'^CSIDL.*' : 'CSIDL Equivalent'
        ,r'^' + u'旧' + r'.*' + u'显示名称' : 'Legacy Display Name'
        ,r'^' + u'旧' + r'.*' + u'默认路径' : 'Legacy Default Path'
    }

    #057. Mapping dict to unify the column values
    dict_FolderType = {
        r'^' + u'常见' : 'COMMON'
        ,r'^' + u'虚拟' : 'VIRTUAL'
        ,r'^' + u'一个' : 'PERUSER'
    }

    #100. Retrieve the <table> from the URL
    #110. Get the contents from the URL
    #Quote: https://www.tutorialspoint.com/how-to-parse-html-pages-to-fetch-html-tables-with-python
    response = requests.get(site_url)

    #119. Abort if the requested URL is not accessible
    if response.status_code != 200:
        raise RuntimeError(
            '[' + LfuncName + ']URL for [lang]:[{0}] is not accessible!'.format( lang )
             + '\n[{0}]'.format( site_url )
        )

    #150. Parse the HTML content
    #Quote: https://stackoverflow.com/questions/39213597/convert-text-data-from-requests-object-to-dataframe-with-pandas
    msdn_page = BeautifulSoup(response.content.decode(response.apparent_encoding), 'html.parser')

    #190. Locate the very first <table>
    #The first table is the outmost one which carries all sub-tables
    msdn_table = msdn_page.find('table')

    #300. Retrieve all the [FOLDERID]s
    #310. Get the list of ISs
    #Quote: https://www.crummy.com/software/BeautifulSoup/bs4/doc.zh/#find
    rows_FOLDERID = msdn_table.find('tbody').find_all('tr', recursive = False)
    list_FOLDERID = [
        row.find('td', recursive = False).find('dl').find('strong').text[len(bgn_FOLDERID):]
        for row in rows_FOLDERID
    ]

    #390. Create a data frame for output
    outRst = pd.DataFrame({'FOLDERID' : list_FOLDERID}, index = pd.Index(range(len(list_FOLDERID))))

    #500. Retrieve respective columns for each [FOLDERID]
    for i,row in enumerate(rows_FOLDERID):
        #100. Locate the <table> in the last <td> of current row
        row_tbl = row.find_all('td', recursive = False)[-1].find('tbody')

        #300. Skip if there is no attribute defined for current [FOLDERID]
        if not row_tbl:
            continue

        #500. Loop all rows within this table to set values to each [FOLDERID]
        rows_subtbl = row_tbl.find_all('tr', recursive = False)
        for row in rows_subtbl:
            #100. Locate all columns in current row
            cells = row.find_all('td', recursive = False)

            #300. The first <td> is regarded as the [colname] of the output data frame
            col = cells[0].text
            col = apply_MapVal(col, dict_ColMap, PRX = True)

            #500. The last <td> is regarded as the value of the corresponding [colname] of the output data frame
            val = cells[-1].text
            if col == 'Folder Type':
                val = apply_MapVal(val, dict_FolderType, PRX = True, full_match = False)

            #900. Update the output data frame in accordance
            outRst.at[i, col] = val

    #700. Remove the rows without available [FOLDERID]
    outRst.drop(outRst.index[outRst['GUID'].isnull()], inplace = True)

    #800. Update the HDF storage when necessary
    if update:
        #100. Remove the existing one as the replacement of any <key> does not purge the container at present
        if os.path.isfile(save_hdf): os.remove(save_hdf)

        #500. Write the data frame into the HDF storage
        outRst.to_hdf(save_hdf, key_hdf)

    #999. Output
    return(outRst)
#End getMSDNKnownFolderIDDoc

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.FileSystem import getMSDNKnownFolderIDDoc
    from omniPy.AdvOp import getWinUILanguage
    print(getMSDNKnownFolderIDDoc.__doc__)

    #100. Retrieve the document by [en_US]
    dodEN = getMSDNKnownFolderIDDoc('en_US')

    #200. Retrieve the document by current language and update the storage on the harddisk
    dodLocale = getMSDNKnownFolderIDDoc(getWinUILanguage(), update = True)
#-Notes- -End-
'''
