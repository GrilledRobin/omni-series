#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os
import pandas as pd
from omniPy.AdvOp import get_values, ExpandSignature
from omniPy.AdvDB import writeSASdat

#[ASSUMPTION]
#[1] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module

@(eSig := ExpandSignature(writeSASdat))
def std_write_SAS(
    indat : dict[str, [str | pd.DataFrame]]
    ,outfile : str | os.PathLike
    ,funcConv : callable = lambda x: x
    ,inDat : pd.DataFrame = None
    ,outFile : str | os.PathLike = None
    ,*pos
    ,**kw
) -> int:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function acts as a [helper] one to standardize the writing of files or data frames with different processing arguments        #
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
#   |indat         :   1-item <dict> with its value as the data frame or its literal name (as character string) to be exported, while   #
#   |                   the key of it is not validated, since SAS dataset only contains one data frame per file.                        #
#   |                   [IMPORTANT   ] This argument is for standardization purpose to construct a unified API                          #
#   |outfile       :   PathLike object indicating the full path of the exported data file                                               #
#   |funcConv      :   Callable to mutate the input data frame before exporting it                                                      #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [callable    ]           Callable that takes only one positional argument with data.frame type                  #
#   |inDat         :   The same argument in the ancestor function, which is a placeholder in this one, omitted and overwritten as       #
#   |                   <indat> is of different input type so it no longer takes effect                                                 #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                   [<see def.>  ] <Default> Use the same input as indicated in <indat>                                             #
#   |outFile       :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <outfile> so it no #
#   |                   longer takes effect                                                                                             #
#   |                   [<see def.>  ] <Default> Use the same input as <outfile>                                                        #
#   |*pos          :   Various positional arguments to expand from its ancestor; see its official document                              #
#   |**kw          :   Various keyword arguments to expand from its ancestor; see its official document                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>         :   Return code from the encapsulated function call                                                                  #
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
#   |   |sys, os, pandas                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |writeSASdat                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |get_values                                                                                                                 #
#   |   |   |ExpandSignature                                                                                                            #
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

    #013. Define the local environment.

    #100. Identify the shared arguments between this function and its ancestor functions
    val_in = list(indat.values())[0]
    if isinstance(val_in, str): val_in = get_values(val_in, inplace = False, instance = pd.DataFrame)
    val_out = funcConv(val_in)
    args_share = {
        'inDat' : val_out
        ,'outFile' : outfile
    }
    eSig.vfyConflict(args_share)

    #700. Insert the patched values into the input parameters
    pos_out, kw_out = eSig.insParams(args_share, pos, kw)

    #999. Return the result
    return( eSig.src(*pos_out, **kw_out) )
#End std_write_SAS

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create environment.
    import sys
    import os
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import withDefaults
    from omniPy.AdvDB import std_write_SAS
    from omniPy.Dates import asDates, asDatetimes, asTimes

    #100. Load the meta config table for data conversion
    conv_meta = pd.read_excel(os.path.join(dir_omniPy, 'omniPy', 'AdvDB', 'meta_writeSASdat.xlsx'))

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

    #300. Convert the data to SAS dataset
    outf = os.path.join(os.getcwd(), 'vfysas.sas7bdat')
    rc = std_write_SAS(
        {'key' : aaa}
        ,outf
        ,metaVar = conv_meta
    )
    if os.path.isfile(outf): os.remove(outf)

    #500. Standardize the call with keyword input pattern
    #[ASSUMPTION]
    #[1] <withDefaults> only enables keyword provision of parameters, while any positional or keyword-only arguments without
    #     default values should still be provided as input in accordance with the signature
    std_param = {
        'indat' : {'key' : aaa}
        ,'encoding' : 'GB2312'
        ,'outfile' : outf
    }

    #510. Wrap the function to enable provision of keyword parameters
    writesas = withDefaults(std_write_SAS)
    help(writesas)

    #550. Write data
    rc2 = writesas(**std_param)
    if os.path.isfile(outf): os.remove(outf)

#-Notes- -End-
'''
