#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd

def debug_comp_datcols( *arg , **kw ) -> 'Compare the [dtypes] of the columns in the provided data frames':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to compare the columns of the input list of data frames, and output a checklist (data frame) for those   #
#   | columns that have different [dtype] among the input data frames while issuing a message in terms of the requested message level.  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |arg          :   Various positional parameters that indicates a list of data frames for comparison                                 #
#   |kw           :   Various named parameters that indicates a list of data frames for comparison                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[data frame] :   The combined data frame that stores the columns in the same names but with different [dtype] in the input list of #
#   |                  data frames                                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210306        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210503        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the usage of [\] as new-row-expansion with the officially recommended way [(multi-line-expr.)], see PEP-8       #
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
#   |   |sys, pandas                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Parameter buffer
    if (not arg) and (not kw): return()

    #050. Local parameters
    dict_dfs = {}
    if arg:
        arg_arglen = len(str(len(arg)))
        dict_dfs.update({ '.arg'+str('0'*arg_arglen+str(i))[-arg_arglen:] : arg[i] for i in range(len(arg)) })
    if kw: dict_dfs.update(kw)

    #100. Verify whether all of the input parameters are [pd.DataFrame]
    non_dfs = { k:v for k,v in dict_dfs.items() if not isinstance(v, pd.DataFrame) }
    if non_dfs:
        print('['+LfuncName+']'+'Below inputs are NOT [pd.DataFrame]!')
        print(non_dfs)
        raise TypeError('['+LfuncName+']'+'Above inputs are NOT [pd.DataFrame]!')

    #300. Create a data frame that stores the [dtypes] of all columns in all input data frames
    dat_dtypes = pd.concat(
        [ pd.DataFrame({ 'dat_name':k, 'col_name':v.columns.values, 'col_dtype':v.dtypes }) for k,v in dict_dfs.items() ]
        , ignore_index = True
    ).reset_index().drop(columns=['index'])

    #500. Check the [dtypes] among the columns
    #510. Calculate the frequency at level: [ col_name * col_dtype ]
    #Quote: https://stackoverflow.com/questions/15411158/pandas-countdistinct-equivalent
    sum_by_dtype = dat_dtypes.groupby(['col_name', 'col_dtype']).agg(
        freq = pd.NamedAgg(column = 'dat_name', aggfunc = 'nunique')
    ).reset_index()

    #520. Calculate the frequency at level: [ col_name ]
    sum_by_dats = dat_dtypes.groupby(['col_name']).agg(
        ndat = pd.NamedAgg(column = 'dat_name', aggfunc = 'nunique')
    ).reset_index()

    #550. Identify the columns with different dtypes among the data frames
    #When any combination of [ col_name * col_dtype ] is in different [dat_name] numbers to that of [ col_name ],
    # the column MUST have different dtypes within at least 2 data frames
    #Unlike the [data.frame] in [R], columns in [pd.DataFrame] cannot have multiple [dtypes]
    #These two tables have the same column: [ col_name ], hence any join method is acceptable
    err_match_dtype = sum_by_dtype.merge(sum_by_dats)
    err_match_dtype = err_match_dtype.loc[ err_match_dtype['freq'] != err_match_dtype['ndat'] ].copy(deep=True)

    #700. Retrieve all necessary information for above columns as identified
    dat_out = (
        dat_dtypes.merge(err_match_dtype['col_name'].drop_duplicates().reset_index().drop(columns=['index']))
        .sort_values(['col_name', 'col_dtype'])
    )

    #910. Print a warning message if there are any columns identified
    if len(err_match_dtype):
        print('['+LfuncName+']'+'Columns are found with different dtypes in different data frames!')
        print(err_match_dtype)

    #999. Return the data frame
    return(dat_out)
#End debug_comp_datcols

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import debug_comp_datcols

    #100. Execute a script with a simple process
    x1 = pd.DataFrame({ 'x':[1,2,3] })
    x2 = pd.DataFrame({ 'x':[1.5,2.7], 'y':'a' })
    cls_1 = debug_comp_datcols( a1 = x1, a2 = x2 )
#-Notes- -End-
'''