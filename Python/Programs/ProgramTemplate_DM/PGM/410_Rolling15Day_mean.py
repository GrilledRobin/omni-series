#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create Rolling-15-Day aggregation upon the captioned KPIs                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Different aggregation process should be handled by separate scripts, e.g. <sum> and <mean> should be conducted at different    #
#   |     steps; otherwise the configuration becomes too complicated                                                                    #
#   |[2] Since function <AdvDB.kfFunc_ts_roll> is introduced, there is no need to consider the split of process in terms of the storage #
#   |     file path, for this function handles such case internally                                                                     #
#   |[3] In most cases, one only has to specify the KPI mapping table and leaves the calculation to the standard function               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Right after <D_BGN> of a Daily KPI, its Rolling companion only takes data as of EXISTING dates within <k-1> days.              #
#   |    [1] For instance, 140112 in the demo on the date 20250415 is the average of 140110 on the dates 20250414 and 20250415 instead  #
#   |         of 15 days, 140112 in the demo on the date 20250415 is the average of 140110 on the dates 20250414 and 20250415 instead of#
#   |         15 days, regardless of whether there are any existing data files on other dates                                           #
#   |    [2] This is logical but maybe less readable                                                                                    #
#   |    [3] For most of Business cases, suggest using such rolling aggregation when all data process is between <D_BGN> and <D_END> of #
#   |         any provided Daily KPIs, e.g. in this demo start using 140112 from 20250428 which covers all 15 days from 20250414        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250404        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Aggregate KPI using <mean> for Rolling-15-Day period')
import os
import pandas as pd
import numpy as np
from collections.abc import Iterable
from omniPy.AdvOp import get_values
from omniPy.AdvDB import parseDatName, kfFunc_ts_roll

#010. Local environment
L_srcflnm1 = os.path.join(dir_data_src, f'CFG_KPI.hdf')
L_stpflnm1 = os.path.join(dir_data_db, 'Logger', f'rc_R15_mean{L_curdate}.hdf')
k_roll_days = 15
dataIO.add('HDFS')

#040. Load the data in current session
if not isinstance(get_values('cfg_kpi', inplace = False), pd.DataFrame):
    cfg_kpi = dataIO['HDFS'].pull(L_srcflnm1, 'cfg_kpi')

print('100. Define mapper of KPIs [Daily] -> [Rolling-15-Day]')
#[ASSUMPTION]
#[1] Values in one tuple indicate the mapping in this order: Daily KPI -> Rolling-15-Day KPI
#[2] <columns> should be set as is, which is required by the factory
map_agg = pd.DataFrame.from_records(
    [
        ('130100','130102')
        ,('140110','140112')
    ]
    ,columns = ['mapper_fr','mapper_to']
)

print('200. Create the output folders for the factory')
#[ASSUMPTION]
#[1] The factory does not create the output folders
#[2] The factory always create the data file into <C_LIB_PATH> at top priority
#210. Helper function to create folder
def h_mkdir(path : str) -> int:
    if not os.path.isdir(path):
        return(os.makedirs(path))
    return(-1)

#130. Helper function to create folders
def h_md_from_cfg(cfg : pd.DataFrame, select : Iterable) -> pd.DataFrame:
    rstOut = (
        cfg
        .loc[lambda x: x['C_KPI_ID'].isin(select)]
        .loc[lambda x: x['N_LIB_PATH_SEQ'].eq(
            x.groupby('C_LIB_NAME')
            ['N_LIB_PATH_SEQ'].min()
            .reindex(x['C_LIB_NAME'])
            .set_axis(x.index)
        )]
        .assign(**{
            'FilePath.Parsed' : lambda x: (
                parseDatName(
                    datPtn = x['FilePath']
                    ,dates = L_curdate
                    ,outDTfmt = getOption['fmt.parseDates']
                    ,inRAM = False
                    ,chkExist = False
                    ,dict_map = getOption['fmt.def.GTSFK']
                    ,**getOption['fmt.opt.def.GTSFK']
                )
                .set_index('FilePath')
                .reindex(x['FilePath'])
                .set_index(x.index)
                ['FilePath.Parsed']
            )
        })
        .assign(**{
            'dir_to_create_' : lambda x: x['FilePath.Parsed'].apply(lambda row: os.path.dirname(row))
        })
        [['dir_to_create_']]
        .drop_duplicates()
        .assign(**{
            'rc' : lambda x: x['dir_to_create_'].apply(h_mkdir).astype(float)
        })
        .set_index('dir_to_create_')
    )
    return(rstOut)

#150. Create the folders
rc_MkDir_R15 = h_md_from_cfg(cfg_kpi, map_agg['mapper_to'])

print('300. Prepare the modification upon the default arguments with current Business requirements')
#[ASSUMPTION]
#[1] The factory only leverages daily KPI starting from <D_BGN>, regardless of whether the daily KPI data exists before that date
#[2] E.g. if <140110> starts on <20250303> with initial value as 6, its <R15 mean> on <20250303> will be 6, even if there
#     exists a data file on <20250301> and <20250302>
#[3] <_parallel> and <cores> are reserved for the scenario when ALL captioned Daily KPIs are stored in different files. Setting
#    <_parallel=True> and provided sufficient <cores> under such scenario would raise the efficiency a lot
#[4] <byVar> is Business decision, usually contains Customer ID and Account ID. For details such as transaction KPIs, Transaction ID
#     can be involved; for lower details such as customer level flags, Account ID can be removed
#[5] <copyVar> ensures the table format consistent with Daily KPIs, while the respective values at the <last record> will be retained
#     to the output result for each <byVar> group
#[6] <genPHMul> and <calcInd> control the calculation on workday, tradeday or calendar day, see document for <AdvDB.aggrByPeriod>
#[7] <fTrans>, <fTrans_opt> and <outDTfmt> control the mapping for date placeholder translation, see <autoexec.py>. As a standard
#     process, they can be set as is with no necessary change
#[8] <fDebug> is useful when there is error or confusion on the calculation logic
args_ts_roll = {
    'inKPICfg' : cfg_kpi
    ,'mapper' : map_agg
    ,'inDate' : L_curdate
    ,'kDays' : k_roll_days
    ,'_parallel' : False
    ,'cores' : 4
    ,'aggrVar' : 'A_KPI_VAL'
    ,'byVar' : ['NC_CUST','NC_ACCT']
    ,'copyVar' : '_all_'
    ,'genPHMul' : True
    ,'calcInd' : 'C'
    ,'funcAggr' : np.nanmean
    ,'fTrans' : getOption['fmt.def.GTSFK']
    ,'fTrans_opt' : getOption['fmt.opt.def.GTSFK']
    ,'outDTfmt' : getOption['fmt.parseDates']
    ,'fDebug' : False
}

print('400. Conduct rolling calculation')
rc_R15 = kfFunc_ts_roll(**args_ts_roll)

print('999. Save the result to harddrive')
if not os.path.isdir(rst_dir := os.path.dirname(L_stpflnm1)):
    os.makedirs(rst_dir)

if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    {
        'rc_MkDir_R15' : rc_MkDir_R15
        ,'rc_R15' : rc_R15
    }
    ,L_stpflnm1
    ,kw_put = {
        'rc_R15' : {
            'complevel' : 9
        }
    }
)
