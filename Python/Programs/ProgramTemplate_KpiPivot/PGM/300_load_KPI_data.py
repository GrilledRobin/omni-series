#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to load the KPI data in terms of the configuration                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Usually we set the option <MergeProc=SET> to reserve flexibility during pivoting                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250329        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Load KPI data as indicated by CFG_KPI')
import os
import pandas as pd
import numpy as np
from functools import partial
from omniPy.AdvOp import get_values, modifyDict
from omniPy.AdvDB import DBuse_GetTimeSeriesForKpi
from omniPy.Dates import intnx, UserCalendar

#010. Local environment
L_srcflnm1 = r'D:\R\omniR\SampleKPI\KPI\K1\custinfo.sas7bdat'
L_srcflnm10 = os.path.join(dir_data_db, f'kpi_req.hdf')
L_stpflnm1 = os.path.join(dir_data_db, f'kpi_data{L_curdate}.hdf')
L_stpflnm2 = os.path.join(dir_data_db, f'kpi_data_debug{L_curdate}.hdf')
dataIO.add('HDFS')

#040. Load the data in current session
if not isinstance(get_values('rpt_kpi', inplace = False), pd.DataFrame):
    rpt_kpi = dataIO['HDFS'].pull(L_srcflnm10, 'rpt_kpi')
if not isinstance(get_values('cfg_kpi', inplace = False), pd.DataFrame):
    cfg_kpi = dataIO['HDFS'].pull(L_srcflnm10, 'cfg_kpi')

print('100. Define helper functions')
#110. Function to subset the KPI retrieval in terms of the shrunk customer base
#[ASSUMPTION]
#[1] This function is applied BEFORE the KPI source data is merged to <InfDat>
#[2] Hence it is useful to reduce the system effort if you only need a subset of customer base
def h_subCust(df : pd.DataFrame):
    return(df.loc[lambda x: x['nc_cifno'].isin(['001','0002','0004','005'])])

#130. Function to obtain the fields from another dataframe as a step in the chain of operations upon <pd.DataFrame>
#[ASSUMPTION]
#[1] This is to avoid <merge()> dataframes on columns that are NOT indexes, to reduce system effort by over 90%
def h_joinCol(this : pd.DataFrame, df : pd.DataFrame, col : str, idx = 'C_KPI_ID', fillval = None):
    srs = (
        df
        .set_index(idx)
        .reindex(this.set_index(idx).index)
        .set_index(this.index)
        [col]
    )

    if fillval is not None:
        srs = srs.where(srs.notnull(), fillval)

    return(srs)

print('300. Prepare calendar')
args_cln_rpt = modifyDict(
    getOption['args.Calendar']
    ,{
        'clnBgn' : intnx('day', cmpn_bgn, -30, daytype = 'C')
        ,'clnEnd' : intnx('day', cmpn_end, 30, daytype = 'C')
        ,'dateBgn' : cmpn_bgn
        ,'dateEnd' : cmpn_end
    }
)
cln_rpt = UserCalendar(**args_cln_rpt)

print('400. Modify configuration table')
cfg_this = (
    cfg_kpi
    .drop(columns = ['C_KPI_SHORTNAME'])
    .merge(
        rpt_kpi[['C_KPI_ID','C_KPI_SHORTNAME']]
        ,how = 'inner'
        ,on = 'C_KPI_ID'
    )
)

print('500. Load the sources')
#510. Prepare the modification upon the default arguments with current business requirements
args_kpi = modifyDict(
    getOption['args.def.GTSFK']
    ,{
        'inKPICfg' : cfg_this
        ,'InfDatCfg' : {
            'InfDat' : os.path.basename(L_srcflnm1)
            ,'_paths' : os.path.dirname(L_srcflnm1)
            ,'DatType' : 'SAS'
            #Below is a demo, please modify the function where necessary
            ,'_func' : h_subCust
            #Below option is used for the function defined above
            ,'_func_opt' : {}
        }
        ,'fImp_opt' : 'options'
        ,'SingleInf' : True
        ,'dnDates' : cln_rpt.d_AllWD
        #[ASSUMPTION]
        #[1] Change <MergeProc> to <MERGE> will reflect the change in <C_KPI_SHORTNAME>
        ,'MergeProc' : 'SET'
        ,'keyvar' : ['nc_cifno']
        ,'SetAsBase' : 'k'
        #Process in parallel for small number of small data files are MUCH SLOWER than sequential mode
        ,'_parallel' : False
        ,'fDebug' : False
        ,'values_fn' : np.nansum
    }
)

#530. Load data
#[ASSUMPTION]
#[1] <C_KPI_ID> will be deduplicated in this function
kpi_src = DBuse_GetTimeSeriesForKpi(**args_kpi)

#570. Save the debug data
if isinstance((df_miss := kpi_src.get('G_miss_files')), pd.DataFrame):
    if os.path.isfile(L_stpflnm2): os.remove(L_stpflnm2)
    print(f'List of missing source files are exported to key <G_miss_files> in below file:\n{L_stpflnm2}')
    rc_debug = dataIO['HDFS'].push(
        {
            'G_miss_files' : df_miss
        }
        ,L_stpflnm2
    )

print('700. Retrieve report categories')
kpi_data = (
    kpi_src.get('data')
    .rename(columns = {'NC_CIFNO' : 'nc_cifno'})
    .assign(**{
        v : partial(h_joinCol, df = rpt_kpi, col = v)
        for v in rpt_kpi.columns.to_series().loc[lambda x: ~x.isin(['C_KPI_ID'])]
    })
    .assign(**{
        'A_KPI_VAL' : lambda x: x['A_KPI_VAL'].div(x['N_UNIT'])
    })
)

print('999. Save the result to harddrive')
if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    {
        'kpi_data' : kpi_data
    }
    ,L_stpflnm1
)
