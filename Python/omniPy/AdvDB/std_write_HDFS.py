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
    ,kw_put : dict = {}
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
#   |                 [<see def.>  ] <Default> Open the data file in the dedicated mode                                                 #
#   |kw_put      :   Named parameters for <pd.HDFStore.put>, excluding <key>, <value> as they are already provided                      #
#   |                 [IMPORTANT   ] To ensure the same behavior, when any API that is designed to push the data in {key:value} fashion #
#   |                                 , please set the same argument to differ the process                                              #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240211        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Differ the args for the keys during applying <store.put> method                                                         #
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
    if not isinstance(kw_put, dict):
        raise TypeError(f'[{LfuncName}]<kw_put> must be a dict, while <{type(kw_put).__name__}> is given!')
    kw_open_fnl = { k:v for k,v in kw_open.items() if k not in ['path'] }
    rc = 0

    #100. Mutate <kw_put>
    #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
    sig_put_raw = signature(pd.HDFStore.put).parameters.values()
    kw_put_fnl = {
        k : {
            arg:val
            for arg,val in v.items()
            if (arg in [ s.name for s in sig_put_raw ])
            and (arg not in ['key','value'])
        }
        for k,v in kw_put.items()
        if (k in indat)
    }

    #500. Overwrite the keyword arguments
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
            rc_this = store.put(key, dat, **kw_put_fnl.get(key, {}))
            if rc_this: rc = rc_this

    #999. Return the result
    return(rc)
#End std_write_HDFS

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    import os
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import std_write_HDFS
    from omniPy.Dates import asDates, asDatetimes, asTimes

    #200. Create data frame in terms of the indication in above meta config table
    aaa = (
        pd.DataFrame(
            {
                'var_str' : 'abcde'
                ,'var_int' : 5
                ,'var_float' : 14.678
                ,'var_date' : '2023-12-25'
                ,'var_dt' : '2023-12-25 12:34:56.789012'
                ,'var_time' : '12:34:56.789012'
                ,'var_ts' : asDatetimes('2023-12-25 12:34:56.789012', fmt = '%Y-%m-%d %H:%M:%S.%f')
            }
            ,index = [0]
        )
        #Prevent pandas from inferring dtypes of these fields
        .assign(**{
            'var_date' : lambda x: asDates(x['var_date'])
            #<%f> is only valid at input (strptime) rather than output (strftime)
            ,'var_dt' : lambda x: asDatetimes(x['var_dt'], fmt = '%Y-%m-%d %H:%M:%S.%f')
            ,'var_time' : lambda x: asTimes(x['var_time'], fmt = '%H:%M:%S.%f')
        })
    )

    #300. Convert the data to HDFStore file
    outf = os.path.join(os.getcwd(), 'vfyhdf.hdf')
    rc = std_write_HDFS(
        { 'aaa' : aaa }
        ,outf
        ,kw_put = {
            'aaa' : {
                'format' : 'fixed'
            }
        }
    )
    if os.path.isfile(outf): os.remove(outf)
#-Notes- -End-
'''
