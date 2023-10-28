#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
from typing import Any
from collections.abc import Iterable

def vecStack(
    vec : Any
    ,idRow : str = '.idRow.'
    ,idCol : str = '.idCol.'
    ,valName : str = '.val.'
) -> pd.DataFrame:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to stack (i.e. unfold) the provided 1-D or 2-D iterable object into a dataframe by setting all input     #
#   | values into one column, to simplify the future process. Use <vecUnstack> to transform such structure back to its shape and type   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When any function is designed to unanimously handle <pd.Series>, <pd.DataFrame> and scalar value (or iterable of such), use    #
#   |     this function to unify the input data and hence the internal process                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec         :   Vector to stack, can be Iterable or scalar value                                                                   #
#   |                 No plan to support types of <dict>, {3,n}-D <np.array>; please transform them before calling this function        #
#   |idRow       :   Name of the column indicating the row (axis-0) position of the input values, in the output result                  #
#   |                 [.idRow.     ] <Default> This column is exported to the result                                                    #
#   |idCol       :   Name of the column indicating the column (axis-1) position of the input values, in the output result               #
#   |                 [.idCol.     ] <Default> This column is exported to the result                                                    #
#   |valName     :   Name of the column storing the stacked input values, in the output result                                          #
#   |                 [.val.       ] <Default> This column is exported to the result                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<DataFrame> :   pd.DataFrame with below columns:                                                                                   #
#   |                 [<idRow>     ]           Input position at axis-0                                                                 #
#   |                 [<idCol>     ]           Input position at axis-1                                                                 #
#   |                 [<valName>   ]           Input value at above position                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230610        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231016        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <stack> with a more intuitive method to reduce the time consumption by 30%                                      #
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
#   |   |sys, pandas, numpy, typing, collections                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #100. Convert the input value into a dataframe
    if isinstance(vec, pd.DataFrame):
        vec_proc = vec
    elif isinstance(vec, np.ndarray):
        vec_proc = pd.DataFrame(vec)
    elif isinstance(vec, (pd.Series, pd.Index)):
        vec_proc = vec.to_frame()
    elif isinstance(vec, Iterable) and (not isinstance(vec, str)):
        #We do not verify <dict> since it is NOT 2-D, hence an input of <dict> will cause errors
        vec_proc = pd.DataFrame({0 : vec})
    elif vec is None:
        #<NoneType> has the size of 1, whic means its dimension is as below:
        vec_proc = pd.DataFrame(index = [], columns = [0])
    else:
        vec_proc = pd.DataFrame({0 : vec}, index = [0])

    #500. Stack the translated data
    #510. Obtain the attribute of the data
    vec_shape = vec_proc.shape
    vec_names = vec_proc.columns

    #550. Differentiate the process
    if vec_shape[-1] == 1:
        rstOut = (
            vec_proc
            .reset_index(drop = True)
            .assign(**{
                idRow : lambda x: range(len(x))
                ,idCol : 0
            })
            #Actually there is only one column to rename
            .rename(columns = { c : valName for c in vec_names })
        )
    else:
        vec_reset = vec_proc.reset_index(drop = True)
        rstOut = (
            pd.concat(
                [ vec_reset.iloc[:, [i]].set_axis([valName], axis = 1) for i in range(len(vec_names)) ]
                ,axis = 0
                ,keys = range(len(vec_names))
                ,names = [idCol, idRow]
            )
            .reset_index()
        )

    #999. Purge
    return(rstOut)
#End vecStack

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import datetime as dt
    import pandas as pd
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import vecStack

    #100. Prepare sample data
    data_raw = pd.DataFrame({
        'int' : [1,3,5]
        ,'float' : [0.5, 1.7, 3.2]
        ,'char' : ['a','c','f']
    })

    #200. Stack it with the default parameters
    data_trns = vecStack(data_raw)

    #300. Stack a list
    list_trns = vecStack([4,'a',7.9])

    #800. Speed test
    data_large = data_raw.sample(1000000, replace = True)

    time_bgn = dt.datetime.now()
    trns_large = vecStack(data_large)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0.13s on average

    #590. Purge
    del data_large, trns_large
#-Notes- -End-
'''
