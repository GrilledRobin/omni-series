#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import pandas as pd
from omniPy.AdvOp import ExpandSignature

#[ASSUMPTION]
#[1] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module

@(eSig := ExpandSignature(pd.read_pickle))
def std_read_PICKLE(
    infile : str | os.PathLike | pd._typing.ReadPickleBuffer = None
    ,funcConv : callable = lambda x: x
    ,filepath_or_buffer = None
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
#   |[4] Since it is wrapped by <ExpandSignature>, all arguments can be passed with positional or keyword fashion, regardless of its    #
#   |     wrapped signature, although it is strongly recommended to pass the parameters in their suggested <kind>                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |infile        :   The name (as character string) of the file or data frame to read into RAM, superseding <filename_path>           #
#   |                   [<see def.>  ] <Default> None input will lead to exception                                                      #
#   |funcConv      :   Callable to mutate the loaded dataframe                                                                          #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [callable    ]           Callable that takes only one positional argument with data.frame type                  #
#   |filepath_or_buffer        :   The same argument in the ancestor function, which is a placeholder in this one, superseded by        #
#   |                   <infile> so it no longer takes effect                                                                           #
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
#   | Date |    20250413        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |os, pandas                                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #013. Define the local environment.

    #100. Identify the shared arguments between this function and its ancestor functions
    args_share = {
        'filepath_or_buffer' : (infile or filepath_or_buffer)
    }
    eSig.vfyConflict(args_share)

    #700. Insert the patched values into the input parameters
    pos_out, kw_out = eSig.insParams(args_share, pos, kw)

    #800. Import the data
    df = eSig.src( *pos_out, **kw_out )

    #999. Return the result
    return( funcConv(df) )
#End std_read_PICKLE

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create environment.
    import sys
    import os
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import std_read_PICKLE
    from omniPy.Dates import asDates, asDatetimes, asTimes

    #200. Create data frame with various dtypes
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

    #300. Convert the data to pickle file
    outf = os.path.join(os.getcwd(), 'vfypickle.pkl')
    rc = pd.to_pickle(aaa, outf)

    #400. Load the file
    aa1 = std_read_PICKLE(outf)

    #450. Verify whether the pickled data can be converted back
    print(aaa.eq(aa1).all(axis = None))
    # True

    #900. Purge
    if os.path.isfile(outf): os.remove(outf)

#-Notes- -End-
'''
