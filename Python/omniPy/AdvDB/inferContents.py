#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
from functools import reduce

def inferContents(
    inDat : pd.DataFrame
) -> pd.DataFrame:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to translate the attributes of all columns in the provided data frame into the syntax that can be        #
#   | used to convert the data across platforms, e.g. <data frame> -> <CSV> -> <SAS>                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDat      :   Data frame to be inspected                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<DF>       :   Data frame describing the column-level meta information of the input data that contains below columns               #
#   |               [VARNUM      ] <int   >  Position of variables in the SAS dataset, as well as in the interim CSV file               #
#   |               [NAME        ] <str   >  Column name in SAS syntax                                                                  #
#   |               [FORMAT      ] <str   >  Format name in SAS syntax                                                                  #
#   |               [TYPE        ] <int   >  Variable type, 1 for numeric, 2 for character                                              #
#   |               [LENGTH      ] <int   >  Variable length of the actual storage in SAS dataset                                       #
#   |               [FORMATL     ] <int   >  Format length in SAS syntax, i.e. <w> in the definition <FORMATw.d>                        #
#   |                                        [IMPORTANT] This value is only the display length in the converted data, the storage       #
#   |                                                     precision is always kept maximum during conversion                            #
#   |               [FORMATD     ] <int   >  Format decimal in SAS syntax, i.e. <d> in the definition <FORMATw.d>                       #
#   |                                        [IMPORTANT] This value is only the display length in the converted data, the storage       #
#   |                                                     precision is always kept maximum during conversion                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20231231        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240130        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when <string> column only contains empty strings                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, pandas, numpy, functools                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.
    #from imp import find_module

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

    #013. Define the local environment.
    inDtype = inDat.dtypes
    col_dtypes = {}
    #[ASSUMPTION]
    #[1] Add a common suffix for later removal
    #[2] To create the similar function in R, we also compromise its syntax, since R does not allow underscore as column prefix
    #     but it allows underscore as suffix
    map_fmt = {
        'string_' : '$'
        ,'complex_' : '$'
        ,'category_' : '$'
        ,'bool_' : '$'
        ,'timestamp_' : 'DATETIME'
        ,'datetime_' : 'DATETIME'
        ,'date_' : 'YYMMDDD'
        ,'time_' : 'TIME'
        ,'integer_' : 'COMMA'
        ,'float_' : 'COMMA'
    }
    map_len = {
        'DATETIME' : {
            'length' : 23
            ,'decimal' : 3
        }
        ,'YYMMDDD' : {
            'length' : 10
            ,'decimal' : 0
        }
        ,'TIME' : {
            'length' : 12
            ,'decimal' : 3
        }
        ,'COMMA' : {
            'length' : 32
            ,'decimal' : 3
        }
    }

    #100. Identify column dtypes
    #101. Base dtypes
    col_obj = inDtype.apply(lambda x: pd.api.types.is_object_dtype(x) or pd.api.types.is_string_dtype(x))
    col_real = inDtype.apply(pd.api.types.is_any_real_numeric_dtype)
    col_dtypes['integer_'] = inDtype.apply(pd.api.types.is_integer_dtype)
    col_dtypes['float_'] = col_real & (~col_dtypes['integer_'])
    col_dtypes['complex_'] = inDtype.apply(pd.api.types.is_complex_dtype)
    col_dtypes['bool_'] = inDtype.apply(pd.api.types.is_bool_dtype)
    col_dtypes['timestamp_'] = inDtype.apply(pd.api.types.is_datetime64_any_dtype)
    col_dtypes['category_'] = inDtype.apply(lambda x: isinstance(x, pd.CategoricalDtype))

    #110. Extract the object-dtype columns
    dfsub_obj = inDat.loc[:, col_obj]
    cell_types = dfsub_obj.map(lambda x: type(x).__name__)

    #120. Identify the character columns
    col_dtypes['string_'] = (
        cell_types.apply(lambda x: x.isin(['str','NoneType','NAType']), axis = 1).all(axis = 0)
        .reindex(inDtype.index)
        .fillna(False)
    )

    #140. Identify the date columns
    col_dtypes['date_'] = (
        cell_types.apply(lambda x: x.isin(['date','NaTType']), axis = 1).all(axis = 0)
        .reindex(inDtype.index)
        .fillna(False)
    )

    #150. Identify the datetime columns
    col_dtypes['datetime_'] = (
        cell_types.apply(lambda x: x.isin(['datetime','NaTType']), axis = 1).all(axis = 0)
        .reindex(inDtype.index)
        .fillna(False)
    )

    #160. Identify the time columns
    col_dtypes['time_'] = (
        cell_types.apply(lambda x: x.isin(['time','NaTType']), axis = 1).all(axis = 0)
        .reindex(inDtype.index)
        .fillna(False)
    )

    #199. Raise if otherwise
    col_covered = reduce(lambda x,y: x | y, col_dtypes.values())
    if not col_covered.all():
        col_err = col_covered.loc[col_covered.eq(False)].index.to_list()
        raise TypeError(f'[{LfuncName}]Dtype of the columns: {str(col_err)} cannot be intuitively converted!')

    #400. Infer column lengths
    #401. Helper function to get the string length in bytes
    def h_getByteLen(vec):
        return(len(vec.encode('UTF-8')))
    #410. Data lengths
    #[ASSUMPTION]
    #[1] We set the length of numeric columns in SAS as 8 by default, with maximum compatibility
    #[2] Set the length of character columns as the minimum <k>th power raised from 2 that is larger than the maximum string length
    #     within the same column
    #Quote: https://www.listendata.com/2016/12/sas-length-of-numeric-variables.html
    #Quote: https://www.geeksforgeeks.org/log-and-natural-logarithmic-value-of-a-column-in-pandas-python/
    col_str = reduce(
        lambda x,y: x | y
        ,[ v for k,v in col_dtypes.items() if k in [ k for k,v in map_fmt.items() if v == '$' ] ]
    )
    dfsub_str = inDat.loc[:,col_str].astype(str).where(inDat.loc[:,col_str].notnull(), '')
    col_len = (
        pd.Series(
            np.left_shift(
                np.ones_like(col_str.loc[col_str])
                ,np.ceil(np.log2(
                    dfsub_str
                    .map(h_getByteLen)
                    .max(axis = 0)
                )).replace([-np.inf, np.inf], 0).astype(int)
            )
            ,index = col_str.index
        )
        .fillna(8)
        .astype(int)
    )

    #430. Helper function to retrieve format lengths
    def h_getColAttr(vec : str, attrs : str):
        attr_set = map_len.get(vec, None)
        if attr_set is None:
            return(np.nan)
        else:
            return(attr_set.get(attrs, np.nan))

    #700. Create the data frame to store meta information
    rstOut = (
        pd.concat(
            [ v.rename(k).to_frame() for k,v in col_dtypes.items() ]
            ,ignore_index = False
            ,axis = 1
        )
        .assign(**{
            'FORMAT' : lambda x: x.apply(lambda row: map_fmt.get(row.loc[row].index.to_series().iat[0], ''), axis = 1)
        })
        .assign(**{
            'TYPE' : lambda x: x['FORMAT'].where(x['FORMAT'].eq('$'), '').map({'' : 1, '$' : 2}).astype(int)
            ,'LENGTH' : col_len
        })
        .assign(**{
            'FORMATL' : lambda x: (
                x['FORMAT']
                .apply(h_getColAttr, attrs = 'length')
                .fillna(x['LENGTH'])
                .astype(int)
            )
            ,'FORMATD' : lambda x: (
                x['FORMAT']
                .apply(h_getColAttr, attrs = 'decimal')
                .fillna(0)
                .where(~col_dtypes['integer_'], 0)
                .astype(int)
            )
        })
        .reset_index(drop = False)
        .rename(columns = {'index' : 'NAME'})
        .reset_index(drop = False)
        .rename(columns = {'index' : 'VARNUM'})
        .loc[:, lambda x: ~x.columns.str.endswith('_')]
    )

    #999. Output
    return(rstOut)
#End inferContents

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    import pandas as pd
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import inferContents
    from omniPy.Dates import asDates, asDatetimes, asTimes

    #200. Create data frame with columns of all dtypes that are recognized by this function
    testdf = (
        pd.DataFrame(
            {
                'var_str' : ['abcde',None]
                ,'var_pyarrow' : [np.nan,'k9omd']
                ,'var_int' : [5,7]
                ,'var_float' : [14.678,83.32]
                ,'var_date' : ['2023-12-25','2023-12-32']
                ,'var_dt' : ['2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812']
                ,'var_time' : ['12:34:56.789012','789']
                ,'var_ts' : asDatetimes(['2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812'], fmt = '%Y-%m-%d %H:%M:%S.%f')
                ,'var_bool' : [True,False]
                ,'var_cat' : ['abc','def']
                ,'var_complex' : [1 + 3j, 12.4 + 4.6j]
            }
            ,index = [0,1]
        )
        #Prevent pandas from inferring dtypes of these fields
        .assign(**{
            'var_pyarrow' : lambda x: x['var_pyarrow'].astype(pd.StringDtype('pyarrow'))
            ,'var_cat' : lambda x: x['var_cat'].astype('category')
            ,'var_date' : lambda x: asDates(x['var_date'])
            #<%f> is only valid at input (strptime) rather than output (strftime)
            ,'var_dt' : lambda x: asDatetimes(x['var_dt'], fmt = '%Y-%m-%d %H:%M:%S.%f')
            ,'var_time' : lambda x: asTimes(x['var_time'], fmt = '%H:%M:%S.%f')
        })
    )

    #300. Infer the meta information for data conversion
    infer_testdf = inferContents(testdf)
#-Notes- -End-
'''
