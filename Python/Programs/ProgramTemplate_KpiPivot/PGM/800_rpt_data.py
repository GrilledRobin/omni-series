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
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Create report data')
import os
import pandas as pd
import numpy as np
from omniPy.AdvOp import get_values, pandasPivot

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
    ,fill_value = 0
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

print('500. Direct pivoting')
#510. Prepare mapper
#[ASSUMPTION]
#[1] Ensure <$ Val> is ahead of <# Cust> in the display result
map_pvt = {
    'A_KPI_VAL' : {
        'rename' : '$ Val'
        ,'agg' : np.nansum
    }
    ,'nc_cifno' : {
        'rename' : '# Cust'
        ,'agg' : h_distCnt
    }
}

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
rpt_rst = h_pivot(
    pvt_src
    ,index = ['C_KPI_CAT1','C_KPI_CAT2']
    ,columns = ['RPT_MON']
    ,aggmapper = map_pvt
    ,dropstats = False
    ,name_vals = '.pivot.values.'
    ,keyPatcher = {
        'C_KPI_CAT1' : { v:i for i,v in enumerate(seq_cat1) }
        ,'.pivot.values.' : { v:i for i,v in enumerate([v.get('rename') for v in map_pvt.values()]) }
    }
    ,**args_pvt
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
