#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
from typing import Optional

def highWaterMark(
    mark : pd.Series
    ,vortex : Optional[pd.Series] = None
    ,benchmark : Optional[pd.Series] = None
) -> pd.Series:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the high water mark (HWM) in a convolutional way, by interpolating the vortex and the       #
#   | historically accumulated HWM result if any, to save the system calculation effort                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Customer campaigns sometimes entitle the customers with game points in the method of HWM, i.e. only entitle them with the      #
#   |     additional points on top of their historically gained ones. Meanwhile, there could be manual payment that differs the         #
#   |     should-be results to encourage the customers to participate in a more proactive way (often higher than the entitlement at a   #
#   |     certain payment cycle), but they need to invest more in the future to gain more points that can cover these extra ones        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |mark        :   Water mark at each each certain period of observation. It will be used for calculation of cumulative maximum       #
#   |vortex      :   Vortex that affects each <mark> along the period. Non-NULL values among it will directly replace <mark> if         #
#   |                 <benchmark> is NOT provided. When <benchmark> is provided, its values before the last non-NULL one will overwrite #
#   |                 the calculation result, including <vortex>, even if any among them is NULL. See details in the example            #
#   |                [None            ] <Default> No vortex is in effect                                                                #
#   |                [pd.Series       ]           A pd.Series with the same index as <mark>                                             #
#   |benchmark   :   Benchmark representing the final water mark in the history, ignoring <vortex> as it is designed to consume its     #
#   |                 effect. Only the values TILL the last non-NULL one will be honored. E.g. the first 3 values of the data in        #
#   |                 pd.Series([0,nan,1,nan]) will be honored, i.e. including those NULL values within the valid period; while these 3 #
#   |                 values are retained in the calculation result, regardless of <vortex>                                             #
#   |                [None            ] <Default> No benchmark is in effect                                                             #
#   |                [pd.Series       ]           A pd.Series with the same index as <mark>                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |pd.Series   :   The residue of water mark on top of historical HWM at each observation period                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240302        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas, numpy, typing                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #011. Prepare log text
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer
    f_vortex = isinstance(vortex, pd.Series)
    f_bench = isinstance(benchmark, pd.Series)
    if f_vortex:
        if not mark.index.equals(vortex.index):
            raise ValueError(f'[{LfuncName}][mark] should have the same index as [vortex]!')
    if f_bench:
        if not mark.index.equals(benchmark.index):
            raise ValueError(f'[{LfuncName}][mark] should have the same index as [benchmark]!')

    #100. Prepare the high water mark (HWM)
    mark_high = mark.cummax(skipna = True).ffill()

    #300. Direct calculation without convolution if no other parameters are provided
    #310. Check if all values in <vortex> is NaN
    if f_vortex:
        p_vortex = vortex.notnull().any()
    else:
        p_vortex = False

    #330. Check if all values in <benchmark> is NaN
    if f_bench:
        p_bench = benchmark.notnull().any()
    else:
        p_bench = False

    #390. Simple version
    if (not p_vortex) and (not p_bench):
        return(mark_high.sub(mark_high.shift(1, fill_value = 0)).where(lambda x: x.ge(0), 0).astype(float))

    #400. Prepare the vortex
    if not f_vortex:
        vortex = pd.Series(np.full_like(mark, np.nan, dtype = float), index = mark.index, dtype = float)

    #500. Prepare the benchmark
    #[ASSUMPTION]
    #[1] <benchmark> should start from the first period with a consecutive trend along the same axis as <mark>
    #[2] It is presumed that the <index> of all inputs are sorted in the same and correct way
    #[2] Should the <benchmark> not fit above rule, we calculate starting from scratch with a warning
    if not p_bench:
        #100. Initialize the marks in history
        mark_hist = pd.Series(np.zeros_like(mark), index = mark.index, dtype = float)

        #[ASSUMPTION]
        #[1] <p_vortex> is True till this step, i.e. at least one value is non-NULL
        #300. Retrieve all non-NULL values in the <vortex>
        vortex_vld = pd.Series(range(len(vortex)), index = vortex.index)

        #500. Identify the first position
        vortex_first = int(vortex_vld.loc[vortex.notnull()].min())

        #900. Create the mask of valid index
        #[ASSUMPTION]
        #[1] We would commence the loop from the first non-NULL value of <vortex>
        #[2] This value is included in the loop
        idx_proc = vortex_vld.ge(vortex_first)
        benchmark = mark_high.sub(mark_high.shift(1, fill_value = 0)).where(lambda x: x.ge(0), 0).astype(float)
    else:
        #100. Retrieve all non-NULL values in the <benchmark>
        bench_vld = pd.Series(range(len(benchmark)), index = benchmark.index)

        #300. Identify the last position
        bench_last = int(bench_vld.loc[benchmark.notnull()].max())

        #900. Create the mask of valid index
        #[ASSUMPTION]
        #[1] We would commence the loop right after the last non-NULL value of <benchmark>
        #[2] This value is excluded in the loop
        idx_proc = bench_vld.gt(bench_last)
        mark_hist = benchmark.astype(float)

    #700. Calculate the cumulative result
    #[ASSUMPTION]
    #[1] <cumsum> is affected by <vortex>, then by <benchmark>, every time along the period
    #[2] Such a situation forms a convolution
    #[3] That is why we have to repeat the calculation starting from the <benchmark> by every single <period>
    #[4] <benchmark> is at higher priority than <vortex>, as it should be, even if it has NaN values
    for i in range(idx_proc.sum()):
        mark_hist = (
            mark_high
            .sub(
                mark_hist
                .cumsum(skipna = True)
                .ffill()
                .shift(1, fill_value = 0)
            )
            .where(lambda x: x.ge(0), 0)
            .where(vortex.isnull(), vortex)
            .where(idx_proc, benchmark)
        )

    #999. Output
    return(mark_hist)
#End highWaterMark

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
    from omniPy.Stats import highWaterMark

    #100. Prepare testing data
    testdf = pd.DataFrame({
        'cust' : list('a' * 7) + list('b' * 5)
        ,'prd' : list(range(7)) + list(range(5))
        ,'marks' : [0,100,500,300,0,0,1000,1500,2000,0,0,3000]
    })
    testvortex = pd.DataFrame({
        'cust' : ['a','a','b','b']
        ,'prd' : [1,4,0,3]
        ,'actual' : [50,200,1800,100]
    })

    #200. Test the result
    testHWM = (
        testdf
        .assign(**{
            'actual' : lambda x: (
                testvortex
                .set_index(['cust','prd'])
                .reindex(x.set_index(['cust','prd']).index)
                .set_index(x.index)
                ['actual']
            )
        })
        .sort_values(['cust','prd'])
        .assign(**{
            'sys' : lambda x: (
                x.groupby('cust')
                .apply(lambda y: highWaterMark(y['marks']))
                .set_axis(x.index)
            )
            ,'paid' : lambda x: (
                x.groupby('cust')
                .apply(lambda y: highWaterMark(y['marks'],y['actual']))
                .set_axis(x.index)
            )
        })
    )

    print(testHWM[['marks','actual','sys','paid']])
    #     marks  actual     sys    paid
    # 0       0     NaN     0.0     0.0
    # 1     100    50.0   100.0    50.0
    # 2     500     NaN   400.0   450.0
    # 3     300     NaN     0.0     0.0
    # 4       0   200.0     0.0   200.0
    # 5       0     NaN     0.0     0.0
    # 6    1000     NaN   500.0   300.0
    # 7    1500  1800.0  1500.0  1800.0
    # 8    2000     NaN   500.0   200.0
    # 9       0     NaN     0.0     0.0
    # 10      0   100.0     0.0   100.0
    # 11   3000     NaN  1000.0   900.0

    #300. Test without grouping
    #[ASSUMPTION]
    #[1] This function works well in both grouping and non-grouping environment
    paid = highWaterMark(testHWM['marks'],testHWM['actual'])

    print(pd.concat([testHWM['marks'],testHWM['actual'],paid], axis = 1))
    #     marks  actual       0
    # 0       0     NaN     0.0
    # 1     100    50.0    50.0
    # 2     500     NaN   450.0
    # 3     300     NaN     0.0
    # 4       0   200.0   200.0
    # 5       0     NaN     0.0
    # 6    1000     NaN   300.0
    # 7    1500  1800.0  1800.0
    # 8    2000     NaN     0.0
    # 9       0     NaN     0.0
    # 10      0   100.0   100.0
    # 11   3000     NaN   100.0

    #400. Provide a <previously accumulated result>
    testbench = pd.DataFrame({
        'cust' : ['a','a','b','b']
        ,'prd' : [0,2,0,1]
        ,'prev' : [50,100,1800,100]
    })

    testHWM2 = (
        testHWM
        .drop(columns = ['paid'])
        .assign(**{
            'prev' : lambda x: (
                testbench
                .set_index(['cust','prd'])
                .reindex(x.set_index(['cust','prd']).index)
                .set_index(x.index)
                ['prev']
            )
        })
        .sort_values(['cust','prd'])
        .assign(**{
            'paid' : lambda x: (
                x.groupby('cust')
                .apply(lambda y: highWaterMark(y['marks'],y['actual'], benchmark = y['prev']))
                .set_axis(x.index)
            )
        })
    )

    print(testHWM2[['marks','actual','prev','paid']])
    #     marks  actual    prev    paid
    # 0       0     NaN    50.0    50.0
    # 1     100    50.0     NaN     NaN
    # 2     500     NaN   100.0   100.0
    # 3     300     NaN     NaN   350.0
    # 4       0   200.0     NaN   200.0
    # 5       0     NaN     NaN     0.0
    # 6    1000     NaN     NaN   300.0
    # 7    1500  1800.0  1800.0  1800.0
    # 8    2000     NaN   100.0   100.0
    # 9       0     NaN     NaN   100.0
    # 10      0   100.0     NaN   100.0
    # 11   3000     NaN     NaN   900.0

    #700. Test speed
    smpl = (
        testHWM
        .drop(columns = ['paid'])
        .sample(10000, replace = True)
        .sort_values(['cust','prd'])
    )

    time_bgn = dt.datetime.now()
    smplHWM = (
        smpl
        .assign(**{
            'paid' : lambda x: (
                x.groupby('cust')
                .apply(lambda y: highWaterMark(y['marks'],y['actual']))
                .set_axis(x.index)
            )
        })
    )
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:05.420444

    #700. Test speed when <benchmark> is provided
    #[ASSUMPTION]
    #[1] The more historical <benchmark> is provided, the less time the process will consume
    #[2] One can store the historical result on harddisk for periodical calculation
    smpl2 = (
        testHWM2
        .drop(columns = ['paid'])
        .sample(10000, replace = True)
        .sort_values(['cust','prd'])
    )

    time_bgn = dt.datetime.now()
    smplHWM2 = (
        smpl2
        .assign(**{
            'paid' : lambda x: (
                x.groupby('cust')
                .apply(lambda y: highWaterMark(y['marks'],y['actual'], benchmark = y['prev']))
                .set_axis(x.index)
            )
        })
    )
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:03.828390
#-Notes- -End-
'''
