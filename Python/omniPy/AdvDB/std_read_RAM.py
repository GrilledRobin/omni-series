#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
from inspect import signature
from omniPy.AdvOp import get_values, ls_frame

def std_read_RAM(
    infile : str
    ,funcConv : callable = lambda x: x
    ,frame = None
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
#   |funcConv    :   Callable to mutate the loaded dataframe                                                                            #
#   |                [<see def.>  ] <Default> Do not apply further process upon the data                                                #
#   |                [callable    ]           Callable that takes only one positional argument with data.frame type                     #
#   |frame       :   <frame> object in which to search for objects                                                                      #
#   |                [None        ] <Default> Search in all frames along the call stack                                                 #
#   |                [frame       ]           Dedicated <frame> in which to search the objects                                          #
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
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240129        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |   |ls_frame                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #100. Determine the <usecols>
    usecols = kw.get('usecols', None)
    has_usecols = ('usecols' in kw) and (usecols is not None)

    #500. Load the data
    if frame is None:
        #100. Retrieve the keyword arguments
        #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
        sig_raw = signature(get_values).parameters.values()

        #300. Obtain all defaults of keyword arguments of the function
        #[ASSUMPTION]
        #[1] We do not retrieve the VAR_KEYWORD args of the function, as it is designed for other purpose
        kw_raw = {
            s.name : s.default
            for s in sig_raw
            if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
            and s.default is not s.empty
            and s.name != 'inplace'
        }

        #500. Create the final keyword arguments for calling the function
        kw_final = { k:v for k,v in kw.items() if k in kw_raw }

        #900. Retrieval
        rstOut = get_values(infile, inplace = False, **kw_final)
    else:
        #100. Retrieve the keyword arguments
        sig_raw = signature(ls_frame).parameters.values()

        #300. Obtain all defaults of keyword arguments of the function
        kw_raw = {
            s.name : s.default
            for s in sig_raw
            if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
            and s.default is not s.empty
            and s.name not in ['pattern','verbose']
        }

        #400. In case the raw API takes any variant keywords, we also identify them
        if len([ s.name for s in sig_raw if s.kind == s.VAR_KEYWORD ]) > 0:
            kw_varkw = { k:v for k,v in kw.items() if not ((k in kw_raw) or (k in ['pattern','verbose'])) }
        else:
            kw_varkw = {}

        #500. Create the final keyword arguments for calling the function
        kw_final = {
            **{ k:v for k,v in kw.items() if k in kw_raw }
            ,**kw_varkw
        }

        #900. Retrieval
        rstPre = (
            ls_frame(
                frame = frame
                ,pattern = f'^{infile}$'
                ,verbose = True
                ,**kw_final
            )
        )

        #950. Raise exception if multiple objects are found
        if len(rstPre) > 1:
            raise ValueError(
                f'[{LfuncName}]Multiple objects found for pattern [infile] as <{str(list(rstPre.keys()))}>!'
                +' It is designed to load only one!'
            )
        elif len(rstPre) == 0:
            rstOut = None
        else:
            rstOut = list(rstPre.values())[0]

    #800. Filter the columns
    if has_usecols:
        rstOut = rstOut.loc[:, lambda x: x.columns.isin(usecols)]

    #900. Import data
    return( funcConv(rstOut) )
#End std_read_RAM
