#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
from pyreadstat import read_sas7bdat
from inspect import signature
from omniPy.AdvDB import loadSASdat

def std_read_SAS(
    infile
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
#   | Date |    20240102        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Eliminate the excessive kwargs from those acceptable in <pyreadstat.read_sas7bdat>                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240129        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the unnecessary restrictions on arguments, and leave them to the caller process                                  #
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
#   |   |pandas, pyreadstat, inspect                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |loadSASdat                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #013. Define the local environment.

    #500. Overwrite the keyword arguments
    #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
    sig_pyr = signature(read_sas7bdat).parameters.values()
    sig_ls = signature(loadSASdat).parameters.values()

    #510. Obtain all defaults of keyword arguments of the function
    kw_raw_pyr = {
        s.name : s.default
        for s in sig_pyr
        if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.default is not s.empty
    }
    kw_raw_ls = {
        s.name : s.default
        for s in sig_ls
        if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.default is not s.empty
    }

    #550. In case the raw API takes any variant keywords, we also identify them
    #[ASSUMPTION]
    #[1] Variant kwargs from <loadSASdat> is designed only for <read_sas7bdat>
    #[2] Hence we only validate the kwargs of the latter
    if len([ s.name for s in sig_pyr if s.kind == s.VAR_KEYWORD ]) > 0:
        kw_varkw = { k:v for k,v in kw.items() if not ((k in kw_raw_pyr) or (k in kw_raw_ls) or (k in ['filename_path','inFile'])) }
    else:
        kw_varkw = {}

    #590. Create the final keyword arguments for calling the function
    kw_final = {
        **{ k:v for k,v in kw.items() if ((k in kw_raw_pyr) or (k in kw_raw_ls)) and k not in ['filename_path','inFile'] }
        ,**kw_varkw
    }

    #800. Import the data
    df , meta = loadSASdat( infile, **kw_final )

    #999. Return the result
    return( funcConv(df) )
#End std_read_SAS
