#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys
import pandas as pd
from collections.abc import Iterable
from typing import Union, Optional
from omniPy.AdvOp import ExpandSignature
from omniPy.AdvDB import parseHDFStoreInfo

eSig = ExpandSignature(pd.read_hdf)

@eSig
def std_read_HDFS(
    infile : Union[str, os.PathLike, pd.HDFStore]
    ,key : Optional[object] = None
    ,funcConv : callable = lambda x: x
    ,usecols : Iterable[str | tuple[str]] = None
    ,path_or_buf : Union[str, os.PathLike, pd.HDFStore] = None
    ,columns : Iterable[str] = None
    ,*pos
    ,**kw
) -> pd.DataFrame:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function acts as a [helper] one to standardize the reading of files or data frames with different processing arguments        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CONCLUSION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Retain the signatures of all ancestor functions for easy program design                                                        #
#   |[2] Add aliases of necessary arguments to enable standardized call                                                                 #
#   |[3] In most cases when this function is called in a standardized way, the first argument is provided in positional pattern         #
#   |[4] In order to call the function with standardized keywords, one must also wrap it with <AdvOp.withDefaults>, see examples        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |infile        :   The name (as character string) of the file or data frame to read into RAM, superseding <path_or_buf> if provided #
#   |key           :   The name of the data frame stored in the HDF file to read into RAM                                               #
#   |funcConv      :   Callable to mutate the loaded dataframe                                                                          #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [callable    ]           Callable that takes only one positional argument with data.frame type                  #
#   |usecols       :   Iterable of column names to keep from the retrieved data, superseding <columns> if it is not None                #
#   |                   [None        ] <Default> Keep all columns                                                                       #
#   |path_or_buf   :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <infile> so it no  #
#   |                   longer takes effect                                                                                             #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                   [<see def.>  ] <Default> Use the same input as <infile>                                                         #
#   |columns       :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <usecols> so it no #
#   |                   longer takes effect                                                                                             #
#   |                   [<see def.>  ] <Default> Use the same input as <usecols>                                                        #
#   |*pos          :   Various positional arguments to expand from its ancestor; see its official document                              #
#   |**kw          :   Various keyword arguments to expand from its ancestor; see its official document                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[df]          :   The data frame to be read into RAM from the source                                                               #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240129        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the unnecessary restrictions on arguments, and leave them to the caller process                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250201        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |      |[2] Make <usecols> supersede <columns> to standardize the call                                                              #
#   |      |[3] For the same functionality, enable diversified parameter provision in accordance with its expanded signature            #
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
#   |   |os, sys, pandas, typing, collections                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |parseHDFStoreInfo                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if usecols is not None:
        if not isinstance(usecols, Iterable):
            raise TypeError(f'[{LfuncName}]<usecols> must be non-str Iterable, while <{type(usecols).__name__}> is given!')
        if isinstance(usecols, str):
            raise TypeError(f'[{LfuncName}]<usecols> must be non-str Iterable, while <str> is given!')
    if columns is not None:
        if not isinstance(columns, Iterable):
            raise TypeError(f'[{LfuncName}]<columns> must be non-str Iterable, while <{type(columns).__name__}> is given!')
        if isinstance(columns, str):
            raise TypeError(f'[{LfuncName}]<columns> must be non-str Iterable, while <str> is given!')
        if usecols is None:
            raise NotImplementedError(f'[{LfuncName}]Please use <usecols> instead as a standardized call!')

    #013. Define the local environment.
    rst_col = []

    #050. Identify the format of the source
    fmt_src = (
        parseHDFStoreInfo(infile)
        .loc[lambda x: x['key'].eq(key), 'format']
        .iat[0]
    )

    #059. Raise exception if the dedicated object is not recognized
    if fmt_src not in ['table','fixed']:
        raise TypeError(f'[{LfuncName}]Format <{fmt_src}> of the key <{key}> is not recognized!')

    #100. Identify the shared arguments between this function and its ancestor functions
    #[ASSUMPTION]
    #[1] We do not use <or> syntax as the input object may not have definition of <truth value>
    args_share = {
        'path_or_buf' : infile
        ,'key' : key
    }

    #200. Helper functions

    #210. Function to slice the data frame at axis-1
    def h_flt(df : pd.DataFrame):
        if usecols is None:
            return(slice(len(df.columns)))
        else:
            return(df.columns.isin(rst_col))

    #500. Determine the correct <columns> to load the data
    if usecols is not None:
        #100. Tweak the shared arguments to retrieve the data structure
        args_struct = args_share | {'columns' : None, 'start' : 0, 'stop' : 0}

        #200. Prepare the correct inputs for the ancestor function
        pos_struct, kw_struct = eSig.insParams(args_struct, pos, kw)

        #100. Pre-load the data structure
        struct = eSig.src( *pos_struct, **kw_struct )

        #500. Identify the columns that are in the source
        rst_col = [v for v in struct.columns if v in usecols]

    #900. Load the data with the column filter
    #910. Prepare the proper arguments
    args_fnl = args_share | {'columns' : (None if fmt_src == 'fixed' else rst_col)}
    pos_fnl, kw_fnl = eSig.insParams(args_fnl, pos, kw)

    #930. Eliminate excessive parameters
    #[ASSUMPTION]
    #[1] In some standard process, there may be extra arguments passed, e.g. <format=>
    #[2] In <pd.HDFStore>, such arguments are not allowed
    #[3] Since they are extra, they cannot be positional arguments, hence all inputs will be translated into keywords
    #[4] That is why we only need to shrink the keywords
    kw_fnl = { k:v for k,v in kw_fnl.items() if k not in ['format'] }

    #990. Differ the process
    if fmt_src == 'table':
        return(funcConv(eSig.src( *pos_fnl, **kw_fnl )))
    else:
        return(funcConv(
            eSig.src( *pos_fnl, **kw_fnl )
            .iloc[:, h_flt]
        ))
#End std_read_HDFS

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create environment.
    import os
    import sys
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import std_read_HDFS

    file_tmp = os.path.join(os.getcwd(), 'aaa.hdf')
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
    vfy_aaa = std_read_HDFS(file_tmp, 'aaa', usecols = ['a','c'])

    #300. Load empty data with none of the required columns existing in the source
    #[ASSUMPTION]
    #[1] <format='fixed'> still causes large effort as the filtration is applied AFTER loading the whole object
    vfy_bbb = std_read_HDFS(file_tmp, 'bbb', usecols = ['a','c'])

    #900. Purge
    if os.path.isfile(file_tmp): os.remove(file_tmp)
#-Notes- -End-
'''
