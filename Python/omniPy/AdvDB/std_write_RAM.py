#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
from inspect import signature
from omniPy.AdvOp import get_values

def std_write_RAM(
    indat : dict[str : [str | pd.DataFrame]]
    ,outfile : str
    ,funcConv : callable = lambda x: x
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
#   |indat       :   1-item <dict> with its value as the data frame or its literal name (as character string) to be exported, while the #
#   |                 key of it is not validated, since SAS dataset only contains one data frame per file.                              #
#   |                 [IMPORTANT   ] This argument is for standardization purpose to construct a unified API                            #
#   |outfile     :   Name as character string indicating the converted object                                                           #
#   |funcConv    :   Callable to mutate the input data frame before exporting it                                                        #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the data                                               #
#   |                 [callable    ]           Callable that takes only one positional argument with data.frame type                    #
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
#   |   |sys, pandas, inspect                                                                                                           #
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
        raise TypeError(f'[{LfuncName}]<indat> must be a 1-item dict, while <{type(indat).__name__}> is given!')
    if len(indat) != 1:
        raise ValueError(f'[{LfuncName}]<indat> must be a 1-item dict, while <{len(indat)}> items are given!')
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

    #600. Identify the data frame to be exported
    val = list(indat.values())[0]
    if isinstance(val, str): val = get_values(val, inplace = False, **kw_final)

    #700. Identify the frame to export the data
    #[ASSUMPTION]
    #[1] Tt cannot be detected how deep this function is called along the stack
    #[2] It can neither be detected which along the call stack should we export the data for other processes
    #[3] Hence we put the data at the farthest stack, probably <global> to ensure maximum compability
    frame = sys._getframe()
    while frame.f_back:
        frame = frame.f_back

    #800. Write the data
    rc_this = frame.f_locals.update({outfile : funcConv(val)})
    if rc_this: rc = rc_this

    #999. Return the result
    return(rc)
#End std_write_RAM
