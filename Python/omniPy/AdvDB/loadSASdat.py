#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import datetime as dt
import pandas as pd
import pyreadstat as pyr
from collections import OrderedDict
from collections.abc import Iterable
from functools import partial
from omniPy.AdvOp import apply_MapVal, ExpandSignature
from omniPy.Dates import asDates, asDatetimes, asTimes

eSig = ExpandSignature(pyr.read_sas7bdat)

@eSig
def loadSASdat(
    *pos
    ,dt_map : dict = {
        #[LHS] The original format in SAS loaded from [pyreadstat.read_sas7bdat] and stored in meta.original_variable_types
        #[RHS] The [function] to translate the corresponding values in the format of [LHS]
        #[IMPORTANT] The mapping is conducted by the sequence as provided below, check document for [apply_MapVal]
        #See official document of [SAS Date, Time, and Datetime Values]
        r'(datetime|dateampm)+' : 'dt'
        ,r'(hhmm|mmss)+' : 't'
        ,r'(time|tod|hour)+' : 't'
        ,r'(ampm)+' : 't'
        ,r'(yy|mmdd|ddmm)+' : 'd'
        ,r'(dat|day|mon|qtr|year)+' : 'd'
        ,r'(jul)+' : 'd'
    }
    ,**kw
) -> tuple[pd.DataFrame, pyr.metadata_container]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to load the SAS dataset by [pyreadstat.read_sas7bdat], while converting all date-like columns into       #
#   | corresponding [datetime] values in Python, i.e. [dt.date], [dt.datetime] or [dt.time], and change the column type into [object]   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |This function is able to:                                                                                                          #
#   |[1] Read SAS dataset in different encoding                                                                                         #
#   |[2] Eliminate the error reading of variable names when they have LABELS in SAS dataset, esp. when the LABEL contains MBCS/DBCS     #
#   |[3] Convert the date-like values into [pandas], esp. for those beyond the limits of [pd.Timestamp]                                 #
#   |[4] Ignore case during the column name filtration (as what SAS does)                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |*pos          :   Various positional arguments to expand from its ancestor; see its official document                              #
#   |dt_map        :   Mapping table to convert the SAS datetime values into [datetime]                                                 #
#   |                  [ <dict>     ]  <Default> Check the function definition for details                                              #
#   |**kw          :   Various keyword arguments to expand from its ancestor; see its official document                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[<tuple>]     :   A tuple of two elements in the same sequence as below (see official document for [pyreadstat.read_sas7bdat]):    #
#   |                  [pd.DataFrame] The data frame corresponding to the input SAS dataset                                             #
#   |                  [meta        ] pyr.metadata_container                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20190409        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210307        | Version | 1.01        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the core function of [pd.read_sas] with a more convenient one [pyreadstat.read_sas7bdat]                        #
#   |      |[2] Add function to handle the SAS datetime values as the default parameters of [pyreadstat.read_sas7bdat] leave them       #
#   |      |     unevaluated during import due to no appropriate mapping                                                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210316        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add correction of column dtypes when the input data has no row                                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240112        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Enable user to provide kwarg <usecols=> with column names regardless of character case                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250201        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |      |[2] Remove argument <inFile> as it is usually provided in positional pattern, and more importantly, it takes the same effect#
#   |      |     as <filename_path> in its ancestor function                                                                            #
#   |      |[3] Set the arguments with default values of this function as <KEYWORD_ONLY>, so that the keyword arguments of the ancestor #
#   |      |     functions prepend them in the signature                                                                                #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, pyreadstat, collections, functools, pandas                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asDatetimes                                                                                                                #
#   |   |   |asTimes                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer
    if not isinstance(dt_map, dict):
        dt_map : dict = {
            r'(datetime|dateampm)+' : 'dt'
            ,r'(hhmm|mmss)+' : 't'
            ,r'(time|tod|hour)+' : 't'
            ,r'(ampm)+' : 't'
            ,r'(yy|mmdd|ddmm)+' : 'd'
            ,r'(dat|day|mon|qtr|year)+' : 'd'
            ,r'(jul)+' : 'd'
        }

    #013. Define the local environment
    args_share = {}
    err_funcs = [ v for v in set(dt_map.values()) if v not in ['dt','t','d'] ]
    if err_funcs:
        raise ValueError(
            f'[{LfuncName}]Values of [dt_map] should be among [dt, t, d]! Check these: {str(err_funcs)}'
        )

    #060. Reshape the input parameters
    #[ASSUMPTION]
    #[1] Below function ensures the input parameters to be reshaped in keyword pattern as many as possible
    #[2] It also obtain the default values, when there is no input, of related arguments to mimic the input
    #[3] Hence it is safe to locate any inputs using their positions prior to their names and default values in line
    #[4] After the insertion, the arguments have been validated, so all updates to below result only need to be applied
    #     by <eSig.updParams()>
    pos_in, kw_in = eSig.insParams(args_share, pos, kw)

    #200. Helper functions

    #300. Determine the <usecols>
    #[ASSUMPTION]
    #[1] SAS does not validate the character case of the column names
    #[2] There may be different character cases for the same column name in different SAS datasets
    #[3] When we use the unified API to load these datasets, we should be able to unify the column selection
    #[4] This would provide flexibility
    #310. Split the kwargs
    usecols = eSig.getParam('usecols', pos_in, kw_in)

    #350. Modify the <usecols> argument
    if usecols is not None:
        #010. Standardize the input
        if not isinstance(usecols, Iterable):
            raise TypeError(f'[{LfuncName}]<usecols> must be Iterable, given <{type(usecols).__name__}>')

        #100. Fabricate the parameters to only retrieve the meta structure of the input file
        args_meta = args_share | {'usecols' : None, 'metadataonly' : True}
        pos_meta, kw_meta = eSig.updParams(args_meta, pos_in, kw_in)

        #300. Retrieve the meta structure
        _, meta_col = eSig.src(*pos_meta, **kw_meta)

        #500. Search for the possible matching of the provided column names
        newcol = [ v for v in meta_col.column_names if v.upper() in [ u.upper() for u in usecols ] ]

        #900. Update the kwargs for the actual data retrieval
        args_setcol = args_share | {'usecols' : newcol}
        pos_in, kw_in = eSig.updParams(args_setcol, pos_in, kw_in)

    #400. Read the SAS dataset
    df, meta = eSig.src(*pos_in, **kw_in)

    #500. Correct the character column dtype if the input data is empty
    #This is because [pyreadstat] will convert them to [float64] imperatively.
    if not len(df):
        #100. Correction of the case when the column type is clearly specified
        cols_char = [ k for k,v in meta.original_variable_types.items() if v == '$' ]
        if cols_char:
            df[cols_char] = df[cols_char].astype('object')

        #300. Compile a Regular Expression for the usage inside the loop
        rx_sasvar = re.compile(r'^[fn]?c_\w+', re.I)

        #500. Correction of the case when the column type is not specified
        #In such case we can only expect the creator of the data makes use of column naming convention as below.
        cols_null = [
            k for k,v in meta.original_variable_types.items()
            if (v == 'NULL') & ( rx_sasvar.search(k) is not None )
        ]
        if cols_null:
            df[cols_null] = df[cols_null].astype('object')

        #900. Purge the memory usage
        re.purge()

    #700. Translate the date-like columns where necessary
    #710. Identify the original [format] of all variables in the SAS dataset
    vardef = OrderedDict(sorted(meta.original_variable_types.items()))

    #720. Identify the [unit] to be used for translating the date-like variables
    f_conv = apply_MapVal(
        list(vardef.values())
        , dt_map
        , preserve = False
        , full_match = False
        , ignore_case = True
        , PRX = True
    )

    #750. Extract the date-like variables by above mapping result
    k_conv = list(vardef.keys())
    varconv = { k_conv[i]:f_conv[i] for i in range(len(f_conv)) if f_conv[i] is not None }

    #770. Collect the functions for date-like value convertion
    dt_func = {
        'dt' : partial( asDatetimes , origin = dt.datetime(1960,1,1) , unit = 'seconds' )
        ,'t' : partial( asTimes , unit = 'seconds' )
        ,'d' : partial( asDates , origin = dt.date(1960,1,1) , unit = 'days' )
    }

    #790. Convert these variables
    if varconv:
        #100. Invert the dict by merging the column names in the same convertion [unit] into lists
        #Quote: (#3) https://stackoverflow.com/questions/483666/reverse-invert-a-dictionary-mapping/41861007#41861007
        inv_map = {v:[k for k in varconv if varconv[k] == v] for v in varconv.values()}

        #900. Convert the columns
        #Quote: https://pandas.pydata.org/pandas-docs/stable/user_guide/basics.html#basics-dtypes
        for k,v in inv_map.items():
            #df[v] = df[v].apply(dt_func.get(k)).astype('object')
            df[v] = dt_func.get(k)(df[v])

    #999. Return the result
    return( df, meta )
#End loadSASdat

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create environment.
    import sys
    from inspect import signature
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import loadSASdat

    #100. Load the SAS dataset with Chinese Characters and missing values
    tt , meta_tt = loadSASdat( dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat' , encoding = 'GB2312' )
    tt.head()
    tt.dtypes
    meta_tt.original_variable_types

    #200. Load the empty SAS dataset
    tt2 , meta_tt2 = loadSASdat( dir_omniPy + r'omniPy\AdvDB\test_emptysasdat.sas7bdat' , encoding = 'GB2312' )
    tt2.head()
    tt2.dtypes
    meta_tt2.original_variable_types

    #300. Load the SAS dataset with specific columns, regardless of the character case
    tt3 , meta_tt3 = loadSASdat(
        dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat'
        ,usecols = ['dt_test']
        ,encoding = 'GB2312'
    )
    tt3.head()
    tt3.dtypes
    meta_tt3.original_variable_types

    #400. Check the signature of the wrapped function
    sig_fn = signature(loadSASdat).parameters.values()
    args = { s.name : s.default for s in sig_fn }
    print(str(args))

    help(loadSASdat)
#-Notes- -End-
'''
