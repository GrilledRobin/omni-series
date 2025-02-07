#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import pandas as pd
from omniPy.AdvOp import ExpandSignature
from omniPy.AdvDB import loadSASdat

eSig = ExpandSignature(loadSASdat)

@eSig
def std_read_SAS(
    infile : str | os.PathLike
    ,funcConv : callable = lambda x: x
    ,filename_path : str | os.PathLike = None
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
#   |infile        :   The name (as character string) of the file or data frame to read into RAM, superseding <filename_path>           #
#   |funcConv      :   Callable to mutate the loaded dataframe                                                                          #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [callable    ]           Callable that takes only one positional argument with data.frame type                  #
#   |filename_path :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <infile> so it no  #
#   |                   longer takes effect                                                                                             #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                   [<see def.>  ] <Default> Use the same input as <infile>                                                         #
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
#   | Date |    20240102        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Eliminate the excessive kwargs from those acceptable in <pyreadstat.read_sas7bdat>                                      #
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
#   |   |os, pandas                                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |loadSASdat                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #013. Define the local environment.

    #100. Identify the shared arguments between this function and its ancestor functions
    args_share = {
        'filename_path' : infile
    }
    eSig.vfyConflict(args_share)

    #700. Insert the patched values into the input parameters
    pos_out, kw_out = eSig.insParams(args_share, pos, kw)

    #800. Import the data
    df , meta = eSig.src( *pos_out, **kw_out )

    #999. Return the result
    return( funcConv(df) )
#End std_read_SAS

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create environment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import withDefaults
    from omniPy.AdvDB import std_read_SAS

    #100. Load the SAS dataset with Chinese Characters
    tt = std_read_SAS( dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat' , encoding = 'GB2312' )
    tt.head()
    tt.dtypes

    #200. Standardize the call with keyword input pattern
    #[ASSUMPTION]
    #[1] <withDefaults> only enables keyword provision of parameters, while any positional or keyword-only arguments without
    #     default values should still be provided as input in accordance with the signature
    std_param = {
        'infile' : dir_omniPy + r'omniPy\AdvDB\test_emptysasdat.sas7bdat'
        ,'encoding' : 'GB2312'
    }

    #210. Wrap the function to enable provision of keyword parameters
    readsas = withDefaults(std_read_SAS)
    help(readsas)

    #250. Load data
    tt2 = readsas(**std_param)

#-Notes- -End-
'''
