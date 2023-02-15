#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
from collections.abc import Iterable
from typing import List

def pandasParseIndexer(
    idx : pd.Index
    ,indexer
    ,idxall : str = '.all.'
    ,logname : str = 'getIndexer'
    ,coerce : bool = True
) -> List[int]:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the actual list of (integer) indexers for the provided pd.Index, by parsing the various inputs    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Enable the program to parse various inputs, such as: name list, slices or boolean list, to subset the provided pd.Index        #
#   |[2] Now only supports positional parse for integer index, i.e. When providing [2] for [pd.Index([1,2,3])] one will get [2] which   #
#   |     is the position of [3] in the index                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |idx         :   pd.Index, or pd.MultiIndex for identifying the indexers for later subset in other processes                        #
#   |indexer     :   Various inputs to be parsed, currently supports below types:                                                       #
#   |                [True        ] <Default> Export [df.index] to the left of the data range                                           #
#   |                [False       ]           Do not export [df.index]                                                                  #
#   |idxall      :   When matching the provision of [indexer], generate a full indexer for the provided pd.Index                        #
#   |                [.all.       ] <Default> When [indexer=='.all.'], generate a full indexer                                          #
#   |                [<str>       ]           Provide a unique value that is non-existing in [idx]                                      #
#   |logname     :   String indicating the environment in which the error message is raised, when the [indexer] is not accepted         #
#   |                [getIndexer  ] <Default> Write it to the error message when the parsing fails                                      #
#   |                [<str>       ]           Other identifier to be printed in the debug mode                                          #
#   |coerce      :   Whether to ignore the indexers that are beyond [range(len[idx])]                                                   #
#   |                [True        ] <Default> Drop the indexers that are beyond [range(len[idx])] without issuing error messages        #
#   |                [False       ]           Issue an error message when any among the indexers are beyond [range(len[idx])]           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>      :   List of integers as positional indexer to the provided pd.Index (i.e. one can use iloc/iat for it)                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20221105        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230216        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when the type of input data is [np.integer] instead of [int]                                                #
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
#   |   |sys, pandas, numpy, collections, typing                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if isinstance(indexer, str):
        if indexer == idxall:
            rst = list(range(len(idx)))
        else:
            rst = idx.get_indexer([indexer])
    elif isinstance(indexer, (int, np.integer)):
        rst = [indexer]
    elif isinstance(indexer, slice):
        bgn, stop, step = indexer.indices(len(idx))
        rst = list(range(bgn, stop, step))
    elif isinstance(indexer, Iterable):
        if isinstance(indexer, tuple):
            if len(indexer) != idx.nlevels:
                raise ValueError(f'[{LfuncName}][{logname}]:Ambiguous [indexer] as tuple has different length to [idx.nlevels]!' )
            else:
                rst = idx.get_indexer([indexer])
        elif len(indexer) == 0:
            rst = []
        elif np.all(list(map(lambda x: isinstance(x, (bool, np.bool_)), indexer))):
            if len(idx) != len(indexer):
                raise ValueError(f'[{LfuncName}][{logname}]:Boolean [indexer] has different length to [idx]!' )
            rst = [ i for i in range(len(idx)) if indexer[i] ]
        elif np.all(list(map(lambda x: isinstance(x, (int, np.integer)), indexer))):
            rst = indexer
        else:
            rst = idx.get_indexer(indexer)
    else:
        raise TypeError(f'[{LfuncName}][{logname}]:[{str(indexer)}] cannot be used to slice [{type(idx)}]!' )

    rst = [ (i + len(idx)) if i < 0 else i for i in rst ]
    rstOut = [ i for i in rst if i in range(len(idx)) ]

    if not coerce:
        rstErr = [ i for i in rst if i not in range(len(idx)) ]
        if len(rstErr) > 0:
            raise ValueError(f'[{LfuncName}][{logname}]:Indexers {str(rstErr)} are out of the range of [idx]!' )

    return(rstOut)
#End pandasParseIndexer

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import numpy as np
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import pandasParseIndexer

    #100. Prepare indexes
    idx_num = pd.Index([1, 2, 3, 5, 7])
    idx_chr = pd.Index(list('abcefg'))
    arrays = [[1, 1, 2, 2], ['red', 'blue', 'red', 'blue']]
    idx_multi = pd.MultiIndex.from_arrays(arrays, names=('number', 'color'))

    #200. Parse the indexers in different ways
    s1 = pandasParseIndexer(idx_num, 2)
    #[2]

    s2 = pandasParseIndexer(idx_num, [False,True,False,True,False])
    #[1, 3]

    s3 = pandasParseIndexer(idx_chr, 'f')
    #[4]

    s4 = pandasParseIndexer(idx_multi, (2,'blue'))
    #[3]

    s5 = pandasParseIndexer(idx_multi, [(1,'red'),(2,'blue')])
    #[0, 3]

    s6 = pandasParseIndexer(idx_multi, '.all.')
    #[0, 1, 2, 3]

    s7 = pandasParseIndexer(idx_chr, 'all', idxall = 'all')
    #[0, 1, 2, 3, 4, 5]

    s8 = pandasParseIndexer(idx_multi, slice(1,9,2))
    #[1, 3]

    #900. Special practices
    e1 = pandasParseIndexer(idx_num, 7, coerce = False)
    #ValueError: [pandasParseIndexer][getIndexer]:Indexers [7] are out of the range of [idx]!
#-Notes- -End-
'''
