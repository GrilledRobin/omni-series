#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from inspect import signature
from omniPy.AdvOp import get_values

def std_read_RAM(
    infile : str
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
#   |   |pandas, inspect                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #100. Determine the <usecols>
    usecols = kw.get('usecols', None)
    has_usecols = ('usecols' in kw) and (usecols is not None)

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

    #700. Load the data directly
    rstOut = get_values(infile, inplace = False, **kw_final)

    #800. Filter the columns
    if has_usecols:
        rstOut = rstOut.loc[:, lambda x: x.columns.isin(usecols)]

    #900. Import data
    return( funcConv(rstOut) )
#End std_read_RAM
