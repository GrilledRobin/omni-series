#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os
import pandas as pd
from inspect import signature
from omniPy.AdvOp import get_values

def std_write_HDFS(
    indat : dict[str : [str | pd.DataFrame]]
    ,outfile : str | os.PathLike
    ,funcConv : callable = lambda x: x
    ,kw_open : dict = {'mode' : 'w'}
    ,kw_put : dict = {'format' : 'fixed'}
    ,**kw
) -> int:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function acts as a [helper] one to standardize the writing of files or data frames with different processing arguments        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] We could pass various parameters into one single expression [kw] that have no negative impact to current function call         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indat       :   <dict> with its values as the data frames or their literal names (as character string) to be exported, while the   #
#   |                 keys of it are the keys to store in HDFStore                                                                      #
#   |outfile     :   PathLike object indicating the full path of the exported data file                                                 #
#   |funcConv    :   Callable to mutate the input data frame before exporting it                                                        #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the data                                               #
#   |                 [callable    ]           Callable that takes only one positional argument with data.frame type                    #
#   |kw_open     :   Named parameters for <pd.HDFStore>, excluding <path> as it is already provided                                     #
#   |kw_put      :   Named parameters for <pd.HDFStore.put>, excluding <key>, <value> as they are already provided                      #
#   |kw          :   Various named parameters for the encapsulated function call if applicable                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>       :   Return code from the encapsulated function call                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240101        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240129        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the unnecessary restrictions on data type, and leave them to the caller process                                  #
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
#   |   |sys, os, pandas, inspect                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if not isinstance(indat, dict):
        raise TypeError(f'[{LfuncName}]<indat> must be a dict, while <{type(indat).__name__}> is given!')
    kw_open_fnl = { k:v for k,v in kw_open.items() if k not in ['path'] }
    kw_put_fnl = { k:v for k,v in kw_put.items() if k not in ['key','value'] }
    rc = 0

    #500. Overwrite the keyword arguments
    #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
    sig_raw = signature(get_values).parameters.values()

    #510. Obtain all defaults of keyword arguments of the function
    #[ASSUMPTION]
    #[1] We do not retrieve the VAR_KEYWORD args of the function, as it is designed for other purpose
    kw_raw = {
        s.name : s.default
        for s in sig_raw
        if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.default is not s.empty
        and s.name != 'inplace'
    }

    #590. Create the final keyword arguments for calling the function
    kw_final = { k:v for k,v in kw.items() if k in kw_raw }

    #600. Retrieve the data before writing to the API, to avoid destruction of the destination
    rstOut = {}
    for key,dat in indat.items():
        if isinstance(dat, str):
            dat = get_values(dat, inplace = False, **kw_final)
        rstOut[key] = funcConv(dat)

    #800. Write the data with API
    with pd.HDFStore(outfile, **kw_open_fnl) as store:
        for key,dat in rstOut.items():
            #Quote: https://pandas.pydata.org/docs/reference/api/pandas.HDFStore.put.html
            rc_this = store.put(key, dat, **kw_put_fnl)
            if rc_this: rc = rc_this

    #999. Return the result
    return(rc)
#End std_write_HDFS
