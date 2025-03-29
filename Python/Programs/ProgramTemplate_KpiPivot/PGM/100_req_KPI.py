#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to load the KPI configuration as well as the requested KPIs for current report                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] There may be multiple steps to load different KPIs under different conditions, hence we make this step standalone              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250329        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Load the requested KPI for reporting')
import os
import pandas as pd
from importlib import import_module
from omniPy.Dates import asDates

#010. Local environment
#Quote: DeepSeek -> <python locate package by name>
pkg_AdvDB = import_module('omniPy.AdvDB')
L_srcflnm1 = os.path.join(os.path.dirname(pkg_AdvDB.__file__), 'CFG_KPI_Example.xlsx')
L_srcflnm10 = os.path.join(dir_data_raw, 'rpt_KPI.xlsx')
L_stpflnm1 = os.path.join(dir_data_db, f'kpi_req.hdf')
dataIO.add('HDFS')

print('100. Define helper functions')
#[ASSUMPTION]
#[1] We set the prefix of all helper functions as <h_>
#[2] This is to distinguish the objects from those imported from other modules or packages
#130. Function to join the paths out of pd.Series
def h_joinPath(srs : pd.Series):
    vfy_srs = srs.apply(pd.isnull)
    if vfy_srs.all():
        return('')
    else:
        return(os.path.join(*srs))

print('300. Import the KPI requirements')
rpt_kpi = (
    pd.read_excel(
        L_srcflnm10
        ,sheet_name = 'KPI_Req'
        ,dtype = 'object'
    )
    .loc[lambda x: x['C_KPI_ID'].notnull()]
    .assign(**{
        'N_UNIT' : lambda x: x['N_UNIT'].astype(float)
    })
)

print('500. Import the KPI configuration')
#510. Prepare sufficient context for execution
#[ASSUMPTION]
#[1] We have to provide sufficient context for <pd.option_context()>
#[2] For pandas<=2.1 and pandas>=3.0, there is no option <future.no_silent_downcasting>
#[3] That is why we have to prepare some option that MUST exist in all versions of <pandas>
#[4] <compute.use_numexpr> is set <True> by default
#    Quote: https://pandas.pydata.org/docs/reference/api/pandas.set_option.html
opt_context = {
    'compute.use_numexpr' : True
}
try:
    opt_context |= {'future.no_silent_downcasting' : True} if pd.get_option('future.no_silent_downcasting') else {}
except:
    pass

#550. Load the data
#[ASSUMPTION]
#[2] For pandas<=2.1 and pandas>=3.0, <fillna()> issues a warning for inference of dtype, we should bypass it
with pd.option_context(*[s for v in [(k,v) for k,v in opt_context.items()] for s in v]):
    cfg_kpi = (
        pd.read_excel(
            L_srcflnm1
            ,sheet_name = 'KPIConfig'
            ,dtype = 'object'
        )
        .assign(**{
            'C_LIB_NAME' : lambda x: x['C_LIB_NAME'].fillna('')
        })
        .merge(
            pd.read_excel(
                L_srcflnm1
                ,sheet_name = 'LibConfig'
                ,dtype = 'object'
            )
            ,on = 'C_LIB_NAME'
            ,how = 'left'
        )
        .assign(**{
            'D_BGN' : lambda x: asDates(x['D_BGN'])
            ,'D_END' : lambda x: asDates(x['D_END'])
            ,'F_KPI_INUSE' : lambda x: x['F_KPI_INUSE'].astype(int)
            ,'N_LIB_PATH_SEQ' : lambda x: x['N_LIB_PATH_SEQ'].fillna(0).infer_objects(copy=False).astype(int)
            ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('')
        })
        .loc[lambda x: x['D_BGN'].le(asDates(L_curdate))]
        .loc[lambda x: x['D_END'].ge(asDates(L_curdate))]
        .loc[lambda x: x['F_KPI_INUSE'].eq(1)]
        .loc[lambda x: x['C_KPI_ID'].isin(rpt_kpi['C_KPI_ID'])]
        #800. Create fields that further facilitate the process in <omniPy.AdvDB.DBuse_GetTimeSeriesForKpi>
        .assign(**{
            'C_KPI_FILE_NAME' : lambda x: x['C_KPI_FILE_NAME'].str.strip().str.upper()
            ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('').str.strip().str.upper()
            ,'C_KPI_FILE_TYPE' : lambda x: x['C_KPI_FILE_TYPE'].str.strip()
            ,'DF_NAME' : lambda x: x['DF_NAME'].fillna('dummy').str.strip()
            ,'options' : lambda x: x['options'].fillna('{}').str.strip()
        })
        #900. Create fields that further facilitate the process in <omniPy.AdvDB.aggrByPeriod>
        .assign(**{
            'FileName' : lambda x: x['C_KPI_FILE_NAME']
            ,'FilePath' : lambda x: x[['C_LIB_PATH','C_KPI_FILE_NAME']].apply(h_joinPath, axis = 1)
            ,'PathSeq' : lambda x: x['N_LIB_PATH_SEQ']
        })
    )

print('999. Save the result to harddrive')
if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    {
        'rpt_kpi' : rpt_kpi
        ,'cfg_kpi' : cfg_kpi
    }
    ,L_stpflnm1
)
