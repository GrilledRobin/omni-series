#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
from typing import Any
from collections.abc import Iterable
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from omniPy.AdvOp import vecStack

def vecUnstack(
    df : pd.DataFrame
    ,idRow : str = [
        s.default
        for s in signature(vecStack).parameters.values()
        if s.name == 'idRow'
    ][0]
    ,idCol : str = [
        s.default
        for s in signature(vecStack).parameters.values()
        if s.name == 'idCol'
    ][0]
    ,valName : str = [
        s.default
        for s in signature(vecStack).parameters.values()
        if s.name == 'valName'
    ][0]
    ,modelObj : Any = None
    ,funcConv : callable = lambda x: x
) -> Any:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to unstack (i.e. fold) the provided dataframe to the same type and shape of the model object, following  #
#   | the convention of <vecStack> as a reverse process                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When any function is designed to unanimously handle <pd.Series>, <pd.DataFrame> and scalar value (or iterable of such), use    #
#   |     <vecStack> to unify the input data and hence the internal process, and then this function to create output in the same type   #
#   |     and shape as the input                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |df          :   pd.DataFrame to unstack                                                                                            #
#   |idRow       :   Name of the column indicating the row (axis-0) position of the values to export                                    #
#   |                 [<vecStack>  ] <Default> See documents of the captioned function                                                  #
#   |idCol       :   Name of the column indicating the column (axis-1) position of the values to export                                 #
#   |                 [<vecStack>  ] <Default> See documents of the captioned function                                                  #
#   |valName     :   Name of the column storing the values to unstack                                                                   #
#   |                 [<vecStack>  ] <Default> See documents of the captioned function                                                  #
#   |modelObj    :   Model object to determine the output type and shape                                                                #
#   |                 [None        ] <Default> Function fails if it is not provided                                                     #
#   |funcConv    :   Callable to process the unstacked dataframe, in case of dtype conversion during pandas process or other needs      #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the unstacked data before transformation               #
#   |                 [callable    ]           Callable that takes only one positional argument                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<any>       :   Object in the same type and shape of the <modelObj>                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230610        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas, numpy, typing, collections, inspect                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |vecStack                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Handle the parameter buffer
    if not isinstance(df, pd.DataFrame):
        raise ValueError(f'[{LfuncName}][df] must be pd.DataFrame, got [{type(df)}]!')
    vfy_nans = [idRow, idCol]
    vfy_cols = vfy_nans + [valName]
    col_exist = { col: (col not in df.columns) for col in vfy_cols }
    if any(col_exist.values()):
        col_error = [ k for k,v in col_exist.items() if v ]
        raise ValueError(f'[{LfuncName}]Column names [{"][".join(col_error)}] cannot be found in [df]!')
    if isinstance(modelObj, Iterable):
        if not isinstance(modelObj, (str, list, tuple, pd.DataFrame, pd.Index, pd.Series, np.ndarray)):
            raise TypeError(f'[{LfuncName}]Type [{type(modelObj)}] of [modelObj] is not recognized!')
    col_nans = { col: df[col].hasnans for col in vfy_nans }
    if any(col_nans.values()):
        nan_error = [ k for k,v in col_nans.items() if v ]
        raise ValueError(f'[{LfuncName}]Columns [{"][".join(nan_error)}] should not contain NA values!')

    #015. Function local variables

    #100. Obtain the attributes of the model object
    #130. Shape
    #[ASSUMPTION]
    #[1] We always <unstack> the input <df> by setting MultiIndex for <idRow> and <idCol>
    #[2] The result of <pd.DataFrame.unstack()> is always a <pd.DataFrame> when <df> has a MultiIndex
    #[3] Hence the shape of the unstacked data is always a 2-tuple
    if isinstance(modelObj, pd.Index):
        mdl_shape = (modelObj.size, modelObj.nlevels)
    elif isinstance(modelObj, (pd.DataFrame, pd.Series, np.ndarray)):
        mdl_shape = modelObj.shape
        if len(mdl_shape) == 1:
            mdl_shape += (1,)
    elif isinstance(modelObj, Iterable) and (not isinstance(modelObj, str)):
        #We do not verify the dimensions of such object, which may lead to unexpected result
        mdl_shape = (len(modelObj),1)
    elif modelObj is None:
        #<NoneType> has the size of 1, whic means its dimension is as below:
        mdl_shape = (0,1)
    else:
        mdl_shape = (1,1)

    mdl_empty = (mdl_shape[0] == 0) | (mdl_shape[-1] == 0)

    #150. Names if any
    if isinstance(modelObj, pd.DataFrame):
        mdl_names = modelObj.columns
    elif isinstance(modelObj, pd.Index):
        mdl_names = modelObj.names
    elif isinstance(modelObj, pd.Series):
        mdl_names = [modelObj.name]
    else:
        mdl_names = []

    #170. Index if any
    if isinstance(modelObj, (pd.DataFrame, pd.Series)):
        mdl_index = modelObj.index
    else:
        mdl_index = []

    #400. Unstack the data
    #410. Obtain the dimensions of the output result
    if len(df) == 0:
        #Empty data will be handled during output
        rst_shape = mdl_shape

        if not mdl_empty:
            raise ValueError(f'[{LfuncName}]Shape of [modelObj] [{str(mdl_shape)}] is not recognized!')
    else:
        rst_shape = (df[idRow].nunique(), df[idCol].nunique())

    #419. Abort if the output shape is different from the model object
    if rst_shape != mdl_shape:
        raise ValueError(f'[{LfuncName}]Unstack result has shape [{str(rst_shape)}] different as [modelObj] [{mdl_shape}]!')

    #430. Handle empty structures in certain classes
    if mdl_empty:
        if isinstance(modelObj, (pd.DataFrame, pd.Index, pd.Series, np.ndarray)):
            return(modelObj)

    #450. Differentiate the process
    if mdl_shape[-1] == 1:
        rstPre = funcConv((
            df
            .loc[:, vfy_cols]
            .set_index([idRow, idCol])
            .sort_index()
        ))
    else:
        rstPre = funcConv((
            df
            .loc[:, vfy_cols]
            .set_index([idRow, idCol])
            .sort_index()
            .unstack(level = -1)
        ))

    #700. Apply attributes to the result
    #[ASSUMPTION]
    #[1] There is no implicit type conversion in Python
    #    Quote: https://stackoverflow.com/questions/67205254/casting-constructor-in-python?r=SearchResults
    if isinstance(modelObj, pd.DataFrame):
        rstOut = (
            rstPre
            .set_axis(mdl_index, axis = 0)
            .set_axis(mdl_names, axis = 1)
        )
    elif isinstance(modelObj, pd.MultiIndex):
        rstOut = (
            pd.MultiIndex.from_frame(rstPre)
            .set_names(mdl_names)
        )
    elif isinstance(modelObj, pd.Index):
        rstOut = (
            pd.Index(rstPre.iloc[:, 0])
            .set_names(mdl_names)
        )
    elif isinstance(modelObj, pd.Series):
        rstOut = (
            rstPre
            .set_axis(mdl_index, axis = 0)
            .set_axis(mdl_names, axis = 1)
            .iloc[:, 0]
        )
    elif isinstance(modelObj, np.matrix):
        rstOut = np.matrix(rstPre.to_numpy())
    elif isinstance(modelObj, np.ndarray):
        rstOut = rstPre.to_numpy()
    elif isinstance(modelObj, list):
        rstOut = rstPre.iloc[:, 0].to_list()
    elif isinstance(modelObj, tuple):
        rstOut = tuple(rstPre.iloc[:, 0].to_list())
    elif modelObj is None:
        rstOut = None
    else:
        rstOut = rstPre.iat[0,0]

    #999. Purge
    return(rstOut)
#End vecUnstack

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import datetime as dt
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import vecStack, vecUnstack

    #100. Prepare sample data
    data_raw = pd.DataFrame({
        'int' : [1,3,5]
        ,'float' : [0.5, 1.7, 3.2]
        ,'char' : ['a','c','f']
    })

    #200. Stack it with the default parameters
    data_trns = vecStack(data_raw)

    #300. Stack a list
    list_raw = [4,'a',7.9]
    list_trns = vecStack(list_raw)

    #400. Unstack
    uns_data = vecUnstack(data_trns, modelObj = data_raw)
    uns_list = vecUnstack(list_trns, modelObj = list_raw)

    #800. Speed test
    data_large = data_raw.sample(1000000, replace = True)
    trns_large = vecStack(data_large)

    time_bgn = dt.datetime.now()
    uns_large = vecUnstack(trns_large, modelObj = data_large)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 1.07s on average

    #590. Purge
    del data_large, trns_large, uns_large
#-Notes- -End-
'''