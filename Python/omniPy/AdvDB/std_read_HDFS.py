#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys
import pandas as pd
from typing import Union, Optional
from omniPy.AdvDB import parseHDFStoreInfo

def std_read_HDFS(
    infile : Union[str, os.PathLike, pd.HDFStore]
    ,key : Optional[object] = None
    ,funcConv : callable = lambda x: x
    ,**kw
) -> pd.DataFrame:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function acts as a [helper] one to standardize the reading of files or data frames with different processing arguments        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] We could pass various parameters into one single expression [kw] that have no negative impact to current function call         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |infile      :   The name (as character string) of the file or data frame to read into RAM                                          #
#   |key         :   The name of the data frame stored in the HDF file to read into RAM                                                 #
#   |funcConv    :   Callable to mutate the loaded dataframe                                                                            #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the data                                               #
#   |                 [callable    ]           Callable that takes only one positional argument with data.frame type                    #
#   |kw          :   Various named parameters for the encapsulated function call if applicable                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[df]        :   The data frame to be read into RAM from the source                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210503        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231209        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <funcConv> to enable mutation of the loaded data and thus save RAM consumption                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240116        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Enable user to provide kwarg <usecols=> to filter columns BEFORE <funcConv> is applied                                  #
#   |      |[2] <usecols> and <columns> (see pd.read_hdf()) cannot be specified at the same time, but take the same effect              #
#   |      |[3] The provided column list is matched to all columns in the source data in the first place, so that anyone that is NOT in #
#   |      |     the source can be ignored, rather than triggering exception                                                            #
#   |      |[4] If the format of the storage is <fixed>, the performance suffers as the filtration is applied AFTER loading the whole   #
#   |      |     object                                                                                                                 #
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
#   |   |os, sys, pandas                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |parseHDFStoreInfo                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #100. Determine the <usecols>
    #110. Split the kwargs
    usecols = kw.get('usecols', None)
    columns = kw.get('columns', None)
    has_usecols = ('usecols' in kw) and (usecols is not None)
    has_columns = ('columns' in kw) and (columns is not None)
    cols_req = []
    kw_col = {}
    fmt_src = 'table'
    kw_raw = { k:v for k,v in kw.items() if k not in ['usecols','columns','path_or_buf'] }

    #119. Raise exception
    if has_usecols and has_columns:
        raise KeyError(f'[{LfuncName}]Cannot specify <usecols> and <columns> at the same time!')

    #130. Combine the requests
    #[ASSUMPTION]
    #[1] We do not use <isinstance>, but leave the exception to be raised
    if has_usecols:
        cols_req = [ v for v in usecols ]
    if has_columns:
        cols_req = [ v for v in columns ]

    #150. Modify the <columns> argument
    if len(cols_req) > 0:
        #100. Pre-load the data structure
        kw_struct = { k:v for k,v in kw_raw.items() if k not in ['start','stop'] }
        kw_norow = { 'start' : 0, 'stop' : 0 }
        struct = pd.read_hdf( infile, key, **kw_struct, **kw_norow )

        #500. Identify the columns that are in the source
        kw_col = { 'columns' : { v for v in struct.columns if v in cols_req } }

        #900. Identify the format of the source
        fmt_src = (
            parseHDFStoreInfo(infile)
            .loc[lambda x: x['key'].eq(key), 'format']
            .iat[0]
        )

    #300. Helper function to slice the data frame at axis-1
    def h_flt(df : pd.DataFrame):
        if len(kw_col) == 0:
            return(slice(len(df.columns)))
        else:
            return(df.columns.isin(kw_col.get('columns')))

    #700. Load the data with the column filter
    if fmt_src == 'table':
        rstOut = pd.read_hdf( infile, key, **kw_raw, **kw_col )
    elif fmt_src == 'fixed':
        rstOut = (
            pd.read_hdf( infile, key, **kw_raw )
            .loc[:, h_flt]
        )
    else:
        raise TypeError(f'[{LfuncName}]Format <{fmt_src}> of the key <{key}> is not recognized!')

    #900. Import data
    return( funcConv(rstOut) )
#End std_read_HDFS

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import std_read_HDFS

    file_tmp = r'D:\Temp\aaa.hdf'
    aaa = pd.DataFrame({'a' : [2,4,6], 'b' : [1,5,9]})
    bbb = pd.DataFrame({'d' : [5,9]})

    #100. Ensure the data format is <table>
    #[ASSUMPTION]
    #[1] <format='table'> cannot store empty data frame into the HDF file, it results in a <dict> instead
    #[2] <format='fixed'> can store empty data frame correctly, without compatibility of <columns=> argument
    #[3] Choose wisely
    with pd.HDFStore(file_tmp, mode = 'w') as store:
        store.put('aaa', aaa, format = 'table')
        store.put('bbb', bbb, format = 'fixed')

    #200. Load the data with specified columns, ignoring those not in the table
    vfy_aaa = std_read_HDFS(file_tmp, 'aaa', columns = ['a','c'])

    #300. Load empty data with none of the required columns existing in the source
    #[ASSUMPTION]
    #[1] <format='fixed'> still causes large effort as the filtration is applied AFTER loading the whole object
    vfy_bbb = std_read_HDFS(file_tmp, 'bbb', usecols = ['a','c'])

    #900. Purge
    if os.path.isfile(file_tmp): os.remove(file_tmp)
#-Notes- -End-
'''
