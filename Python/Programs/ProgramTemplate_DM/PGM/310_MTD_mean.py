#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create MTD aggregation upon the captioned KPIs                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Different aggregation process should be handled by separate scripts, e.g. <sum> and <mean> should be conducted at different    #
#   |     steps; otherwise the configuration becomes too complicated                                                                    #
#   |[2] Since function <AdvDB.kfFunc_ts_mtd> is introduced, there is no need to consider the split of process in terms of the storage  #
#   |     file path, for this function handles such case internally                                                                     #
#   |[3] In most cases, one only has to specify the KPI mapping table and leaves the calculation to the standard function               #
#   |[4] Full Month calculation only validates when Last Workday of a month is NOT the Last Calendar Day of it; if they are the same,   #
#   |     a copy of the MTD data is created as Full Month data                                                                          #
#   |[5] For many Business requirements, the Time Series analysis needs the result representing all calendar days in a month. For       #
#   |     instance, MTD Average Balance is not accurate for Revenue calculation, while Full Month Average Balance is the solution       #
#   |[6] Full Month aggregation only leverages on two data: MTD aggregation result on the Last Workday of a month, and the Daily KPI    #
#   |     data on the same workday. So please ensure both exist for this step                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When a Daily KPI starts on a workday whose previous calendar day is NOT workday, its MTD companion MUST start later than it    #
#   |    [1] <AdvDB.kfFunc_ts_mtd> can only fabricate the <chkDat> on its previous workday using the data on current date, with a gap of#
#   |         several holidays between them                                                                                             #
#   |    [2] <AdvDB.aggrByPeriod> will try to fabricate data on all these holidays using the Daily KPI on that <previous workday>, which#
#   |         certainly fails if the Daily KPI also starts on current date, i.e. there is no data for Daily KPI on <previous workday>   #
#   |    [3] If the MTD companion starts on the next several workdays to current date, e.g. 20250415 for 140111, the fabrication in     #
#   |         <AdvDB.kfFunc_ts_mtd> will only use Daily KPI on 20250415 and ignore that on 20250414. This is a hallucination of the     #
#   |         function and an error during data management                                                                              #
#   |    [4] Solutions for such caveat could be two                                                                                     #
#   |        [1] Make a Daily KPI and its MTD companion start on a workday whose previous calendar day is also a workday, just like     #
#   |             130100 and 130101 in the demo (this is irrational as Business decisions are not dependent upon data requirement)      #
#   |        [2] Let the MTD aggregation start on the first workday of the NEXT month to the <D_BGN> of the Daily KPI, like 140110 and  #
#   |             140111 in the demo (which is easy to justify as there is no need to use the data of a partial Business month)         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250404        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Aggregate KPI using <mean> on MTD basis')
import os
import pandas as pd
import numpy as np
from collections.abc import Iterable
from omniPy.AdvOp import get_values, modifyDict
from omniPy.AdvDB import parseDatName, kfFunc_ts_mtd, kfFunc_ts_fullmonth
from omniPy.Dates import intnx

#010. Local environment
L_srcflnm1 = os.path.join(dir_data_src, f'CFG_KPI.hdf')
L_stpflnm1 = os.path.join(dir_data_db, 'Logger', f'rc_MTD_mean{L_curdate}.hdf')
dataIO.add('HDFS')

#040. Load the data in current session
if not isinstance(get_values('cfg_kpi', inplace = False), pd.DataFrame):
    cfg_kpi = dataIO['HDFS'].pull(L_srcflnm1, 'cfg_kpi')

print('100. Define mapper of KPIs [Daily] -> [MTD]')
#[ASSUMPTION]
#[1] Values in one tuple indicate the mapping in this order: Daily KPI -> MTD KPI -> Full Month KPI
#[2] <columns> should be set as is, which is required by the factory
#[3] If any chain has no requirement for Full Month calculation, e.g. MTD Max, just leave an empty string <''> for <mapper_fm>
map_agg = pd.DataFrame.from_records(
    [
        ('130100','130101','130109')
        ,('140110','140111','140119')
    ]
    ,columns = ['mapper_daily','mapper_mtd','mapper_fm']
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
rc_MkDir_MTD = h_md_from_cfg(cfg_kpi, map_agg['mapper_mtd'])
rc_MkDir_FM = h_md_from_cfg(cfg_kpi, map_agg['mapper_fm'])

print('300. Prepare the modification upon the default arguments with current Business requirements')
#[ASSUMPTION]
#[1] The factory only leverages daily KPI starting from <D_BGN>, regardless of whether the daily KPI data exists before that date
#[2] E.g. if <140110> starts on <20250303> with initial value as 6, its <MTD mean> on <20250303> will be 6/3 = 2, even if there
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
args_ts_mtd = {
    'inKPICfg' : cfg_kpi
    ,'mapper' : (
        map_agg
        .rename(columns = {
            'mapper_daily' : 'mapper_fr'
            ,'mapper_mtd' : 'mapper_to'
        })
    )
    ,'inDate' : L_curdate
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

print('400. Conduct MTD calculation')
rc_MTD = kfFunc_ts_mtd(**args_ts_mtd)

print('600. Determine whether to conduct Full Month calculation')
def h_FM():
    #100. Skip if current date is not the last workday of a month
    if L_curdate != (monthEnd := intnx('month', L_curdate, 0, 'e', daytype = 'w').strftime('%Y%m%d')):
        print(f'Current data date <{L_curdate}> is not the last workday <{monthEnd}> of this month. Skip full month aggregation.')
        return(None)

    #500. Prepare arguments for Full Month aggregation
    args_ts_fm = modifyDict(
        args_ts_mtd
        ,{
            'mapper' : map_agg.loc[lambda x: x['mapper_fm'].where(x['mapper_fm'].notnull(), '').ne('')]
        }
    )

    print('700. Conduct Full Month calculation')
    rc = kfFunc_ts_fullmonth(**args_ts_fm)

    return(rc)

rc_FM = h_FM()

print('800. Collect the returncode')
rc_all = (
    {
        'rc_MkDir_MTD' : rc_MkDir_MTD
        ,'rc_MkDir_FM' : rc_MkDir_FM
        ,'rc_MTD' : rc_MTD
    }
    | ({'rc_FM' : rc_FM} if isinstance(rc_FM, pd.DataFrame) else {})
)
kw_put_all = { k : {'complevel' : 9} for k in rc_all.keys() }

print('999. Save the result to harddrive')
if not os.path.isdir(rst_dir := os.path.dirname(L_stpflnm1)):
    os.makedirs(rst_dir)

if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    rc_all
    ,L_stpflnm1
    ,kw_put = kw_put_all
)
