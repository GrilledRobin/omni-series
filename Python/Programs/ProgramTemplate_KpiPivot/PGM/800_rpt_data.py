#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create the report data, by pivoting at most times                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250329        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250706        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Further generalize the function of pivoting                                                                             #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Create report data')
import os
import pandas as pd
import numpy as np
from functools import partial
from collections.abc import Iterable
from omniPy.AdvOp import get_values, pandasPivot
from omniPy.AdvDB import wrapAsGroupedFunc

#010. Local environment
L_srcflnm1 = os.path.join(dir_data_db, f'kpi_data{L_curdate}.hdf')
L_stpflnm1 = os.path.join(dir_data_db, f'rpt_rst{L_curdate}.hdf')
dataIO.add('HDFS')
args_pvt = {
    'fRowTot' : True
    ,'fRowSubt' : True
    ,'rowTot' : 'Total'
    ,'rowSubt' : 'Subtotal'
    ,'posRowTot' : 'after'
    ,'posRowSubt' : 'before'
    ,'fColTot' : True
    ,'fColSubt' : True
    ,'colTot' : 'Total'
    ,'colSubt' : 'Subtotal'
    ,'posColTot' : 'after'
    ,'posColSubt' : 'after'
}
args_pvt_df = pd.DataFrame(args_pvt.items(), columns = ['key','value'], dtype = 'O')

#040. Load the data in current session
if not isinstance(get_values('kpi_data', inplace = False), pd.DataFrame):
    kpi_data = dataIO['HDFS'].pull(L_srcflnm1, 'kpi_data')

print('100. Define helper functions')
#110. Function to pivot the data
def h_pivot(
    df : pd.DataFrame
    ,values = None
    ,aggfunc = None
    ,fill_value = 0.0
    ,*pos
    ,aggmapper : dict
    ,dropstats : bool = True
    ,**kw
):
    rstOut = pandasPivot(
        df.rename(columns = { k : v.get('rename') for k,v in aggmapper.items() })
        ,values = list(v.get('rename') for v in aggmapper.values())
        ,aggfunc = { v.get('rename') : v.get('agg') for v in aggmapper.values() }
        ,*pos
        ,**kw
    )
    if dropstats:
        rstOut.columns = rstOut.columns.droplevel(-1)
    return(rstOut)

#130. Function to count distinct values of a pd.Series
def h_distCnt(srs : pd.Series):
    return(srs.drop_duplicates().count())

#150. Function to calculate 同比/环比
#[ASSUMPTION]
#[1] This is a demo for calculating the YoY/MoM changes for a dataframe as a whole
#[2] With the wrapper <wrapAsGroupedFunc>, this function can be adopted by <pd.pivot_table> to calculate stratified aggregation
#[3] See document of the wrapper for the wrapping strategy
def h_pctRollPeriod(df : pd.DataFrame, col_val : str = 'A_KPI_VAL', col_prd : str = 'rpt_prd'):
    val_prev = round(df.loc[lambda x: x[col_prd].eq('prev')][col_val].sum(), 2)
    val_curr = round(df.loc[lambda x: x[col_prd].eq('curr')][col_val].sum(), 2)
    rstOut = np.sign(val_curr) if val_prev == 0.0 else ((val_curr - val_prev) / abs(val_prev))
    return(rstOut)

#191. Function to act as unified aggregator
def h_unifyAgg(srs : pd.Series, df : pd.DataFrame):
    #100. Identify the level of the index, for which the level value is used to differ the process
    #[ASSUMPTION]
    #[1] Below level names should be among the <index=> or <columns=> options for <h_pivot>
    #[2] For each pivot table, below level in the index/column should haave already been unique
    #[3] The identified level value should be a single scalar, regardless of dtype
    #[4] If there are other strategies to identify the level value to differ the aggregation methods, please define them here
    idx = df.reindex(srs.index)['C_KPI_CAT1'].iat[0]

    #500. Mapper for different aggregation methods
    #[ASSUMPTION]
    #[1] If no differentiation is required, set below dict as empty, the process will set <np.nansum> as default aggregation
    map_agg = {
        '同比（%）' : wrapAsGroupedFunc(h_pctRollPeriod, df = df)
        ,'环比（%）' : wrapAsGroupedFunc(h_pctRollPeriod, df = df)
    }

    #900. Unify the process
    return(map_agg.get(idx, np.nansum)(srs))

#195. Core pivot method for looping
#[ASSUMPTION]
#[1] As a standard pivoting strategy, there may be many pivot tables for the same <index=> or <columns=>
#[2] We generalize these pivot tables by unifying most of the parameters
def h_pivotByCol(df : pd.DataFrame, col : Iterable):
    #005. Local environment
    if isinstance(col, str):
        col = [col]
    else:
        col = col[:]

    #100. Prepare mapper
    #[ASSUMPTION]
    #[1] Ensure <$ Val> is ahead of <# Cust> in the display result
    map_pvt = {
        'A_KPI_VAL' : {
            'rename' : '$ Val'
            ,'agg' : partial(h_unifyAgg, df = df)
        }
        ,'nc_cifno' : {
            'rename' : '# Cust'
            ,'agg' : h_distCnt
        }
    }

    #500. Pivoting
    rstOut = h_pivot(
        df
        ,index = col
        ,columns = ['RPT_MON']
        ,aggmapper = map_pvt
        # ,fill_value = 0.0
        ,dropstats = False
        ,name_vals = '.pivot.values.'
        ,keyPatcher = {
            '.pivot.values.' : { v:i for i,v in enumerate([v.get('rename') for v in map_pvt.values()]) }
            ,'C_KPI_CAT1' : { v:i for i,v in enumerate(seq_cat1) }
        }
        ,**args_pvt
    )

    return(rstOut)

print('500. Direct pivoting')
#520. Require to arrange the categories
#[ASSUMPTION]
#[1] Ensure <cat1_2> is ahead of <cat1_1> in the display result
seq_cat1 = ['cat1_2','cat1_1']

#540. Fabricate the input data
pvt_src = (
    kpi_data
    .assign(**{
        'RPT_MON' : lambda x: x['D_RecDate'].apply(lambda row: row.strftime('%Y%m'))
    })
)

#570. Pivoting
rpt_rst = (
    h_pivotByCol(pvt_src, ['C_KPI_CAT1','C_KPI_CAT2'])
)

print('999. Save the result to harddrive')
if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    {
        'args_pvt_df' : args_pvt_df
        ,'rpt_rst' : rpt_rst
    }
    ,L_stpflnm1
)
