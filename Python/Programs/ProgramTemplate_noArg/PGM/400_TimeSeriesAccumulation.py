#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#[FEATURE]
#[1] Prioritize retrieval of the data files with the same name in the same folders on different drives
#[2] Concatenate the customer information files from different platforms (such as T1, T2, etc.)
#[3] Leverage KPI data structure for data retrieval
#[4] Minimize the RAM usage by reading the least data files at the same time
logger.info('Accumulate the snapshot on time series')
import os, re
import datetime as dt
import pandas as pd
import numpy as np
import pyreadstat as pyr
from omniPy.Dates import asDates, intnx, UserCalendar
from omniPy.AdvDB import parseDatName, loadSASdat, DBuse_GetTimeSeriesForKpi
from omniPy.AdvOp import modifyDict
from omniPy.FileSystem import getMemberByStrPattern

#Identify the reporting date as the end of the previous month to current execution date
L_curdate = intnx('month', G_obsDates.values[0], -1, 'e', daytype = 'w')
L_srcflnm1 = r'cust_T1_&L_curdate..sas7bdat'
L_srcflnm2 = r'cust_T2_&L_curdate..sas7bdat'
L_srcflnm3 = r'D:\R\omniR\SampleKPI\KPI\K1\cfg_kpi.sas7bdat'
L_srcflnm4 = r'D:\R\omniR\SampleKPI\KPI\K1\cfg_lib.sas7bdat'
L_stpflnm1 = os.path.join(dir_data_db, 'EverQ' + L_curdate.strftime('%Y%m%d') + '.hdf')
key_hdf_cust = 'MaxAUM_MonthEnd_cust'
key_hdf_acct = 'MaxAUM_MonthEnd_acct'
bgn_Proj = dt.date(2016,5,1)
cond_Q = 800000.0
#The sequence of drives in below list determines the priority to search for the same file name
drives = [ (d + ':\ ').strip() for d in ['D', 'E', 'F'] ]
#Keys in below dicts should exist in the field [C_KPI_ID] of [L_srcflnm3]
map_pdtname = {
    '100100' : 'ProdA'
    ,'100101' : 'ProdB'
}
map_pdttype = {
    '100100' : 'Type1'
    ,'100101' : 'Type2'
}

#050. Helper functions
#051. Function to extract the drive from an absolute path
def getBasePath(path):
    basePath, relPath = os.path.split(path)
    while len(relPath):
        basePath, relPath = os.path.split(basePath)

    return(basePath, path[len(basePath):])

logger.info('100. Import the KPI configuration')
cfg_kpi = (
    loadSASdat(L_srcflnm3, encoding = 'GB2312')[0]
    .merge(
        loadSASdat(L_srcflnm4, encoding = 'GB2312')[0]
        ,on = 'C_KPI_DAT_LIB'
        ,how = 'left'
        ,suffixes = ('', '.y')
    )
    .assign(**{
        'C_KPI_FILE_TYPE' : 'SAS'
        ,'C_KPI_FILE_NAME' : lambda x: x['C_KPI_DAT_NAME'] + '.sas7bdat'
    })
)

logger.info('300. Determine the calculation period')
#310. Prepare the pattern of the source data paths
#Below paths are from [main.py]
drive_T1, relPath_T1 = getBasePath(dir_DM_T1)
drive_T2, relPath_T2 = getBasePath(dir_DM_T2)
df_cust_ptn = (
    pd.merge(
        pd.DataFrame({ 'drive':drives, 'priority':[i for i,v in enumerate(drives)] })
        ,pd.DataFrame({
            'relpath' : [relPath_T1, relPath_T2]
            ,'datname' : [L_srcflnm1, L_srcflnm2]
        })
        ,how = 'cross'
    )
    .assign(**{
        'fullpath' : lambda x: x[['drive', 'relpath', 'datname']].apply(os.path.join, axis = 1)
    })
    .drop(columns = ['drive'])
)

#350. Find all output data files and locate the latest one BEFORE current reporting date
ptn_PM = r'EverQ(\d{8}).hdf'
parse_PM = getMemberByStrPattern(
    dir_data_db
    ,inRegExp = ptn_PM
    ,chkType = 1
    ,FSubDir = False
)
all_PM = [ m[0] for m in parse_PM if re.search(ptn_PM, m[0]).group(1) < L_curdate.strftime('%Y%m%d') ]

#370. Set the period beginning as the next working day to above data if it exists
if len(all_PM) == 0:
    output_PM = None
    prd_bgn = bgn_Proj
else:
    output_PM = sorted(all_PM, key = lambda x: re.search(ptn_PM, x).group(1))[-1]
    prd_bgn = intnx('day', re.search(ptn_PM, output_PM).group(1), 1, daytype = 'w')

#390. Define the dates to retrieve all time series files
L_clndr = UserCalendar( clnBgn = prd_bgn, clnEnd = L_curdate )

logger.info('500. Calculate maximum AUM on daily basis')
#510. Locate all source data files
#[getOption] is from [autoexec.py]
parse_data = parseDatName(
    datPtn = df_cust_ptn
    ,parseCol = 'fullpath'
    ,dates = L_clndr.LastWDofMon
    ,outDTfmt = getOption['fmt.parseDates']
    ,inRAM = False
    ,chkExist = True
    ,dict_map = getOption['fmt.def.GTSFK']
    ,**getOption['fmt.opt.def.GTSFK']
)

#520. Filter the locations in terms of the priority of harddrives
loop_data = (
    parse_data
    .loc[lambda x: x['fullpath.chkExist']]
    .sort_values(['relpath', 'datname', 'dates', 'priority'])
    .groupby(['relpath', 'datname', 'dates'], as_index = False)
    .head(1)
)

#530. Prepare the base of the calculation
if output_PM is not None:
    cust_MaxAUM = pd.read_hdf(output_PM, key_hdf_cust)
    acct_MaxAUM = pd.read_hdf(output_PM, key_hdf_acct)
else:
    cust_MaxAUM = (
        pd.DataFrame(columns = ['custID', 'd_table'], dtype = 'object')
        .assign(**{ 'a_aum' : 0.0 })
        .set_index('custID')
    )
    acct_MaxAUM = pd.DataFrame(columns = ['custID'], dtype = 'object')

#540. Prepare the helper function to loop the calculation
def h_calc(d, df_AUM = cust_MaxAUM, df_Prod = acct_MaxAUM):
    #001. Identify the source files on current date
    #[ASSUMPTION]
    #[1] Any among the source files could be missing on current date
    #[2] Columns may be different from different sources, hence we need to handle them respectively
    cfg_T1 = loop_data.loc[lambda x: x['dates'].eq(d) & x['datname'].eq(L_srcflnm1)]
    cfg_T2 = loop_data.loc[lambda x: x['dates'].eq(d) & x['datname'].eq(L_srcflnm2)]

    #100. Retrieve AUM from different platforms
    aum_T1 = [
        loadSASdat(f, encoding = 'GB2312', usecols = ['custID', 'a_aum'])[0]
        for f in cfg_T1['fullpath.Parsed']
    ]

    #150. Helper function to handle the situation when a column may not exist in a time series
    def procT2(f):
        df, meta = pyr.read_sas7bdat(f, metadataonly = True)
        accttype = ['acct_type'] if 'acct_type' in meta.column_names else []
        cols = ['custID', 'a_aum'] + accttype
        df = loadSASdat(f, encoding = 'GB2312', usecols = cols)[0]
        if 'acct_type' in meta.column_names:
            df = (
                df.copy(deep = True)
                .loc[lambda x: x['acct_type'].eq('N')]
                .drop(columns = ['acct_type'])
            )
        return(df)

    #170. Load data from another platform
    aum_T2 = [ procT2(f) for f in cfg_T2['fullpath.Parsed'] ]

    #199. Combine the data
    aum_PFS = (
        pd.concat(aum_T1 + aum_T2, ignore_index = True)
        .groupby('custID', as_index = False)
        .agg({'a_aum' : np.nansum})
        .set_index('custID')
        .assign(**{ 'd_table' : d })
    )

    #300. Update the AUM history
    #310. [a10] New customers are to be added into the history
    #[ASSUMPTION]
    #[1] They have to be Qualified as a threshold to be registered
    aum_cust_add = (
        aum_PFS
        .loc[lambda x: ~x.index.isin(df_AUM.index)]
        .loc[lambda x: x['a_aum'].round(2).ge(cond_Q)]
    )

    #350. [a20] AUM of existing customers are to be replaced with the larger one
    #[ASSUMPTION]
    #[1] We have to use [reindex] to ensure the ourput has the same axis-0 as the historical database
    aum_cust_rep = (
        aum_PFS
        .reindex(df_AUM.index)
        .loc[lambda x: x['a_aum'].round(2).gt(df_AUM['a_aum'])]
    )

    #370. Combine the customer list
    aum_upd = pd.concat([aum_cust_add, aum_cust_rep])

    #379. Directly return if this customer list is empty
    if len(aum_upd) == 0:
        return(df_AUM.copy(deep = True), df_Prod.copy(deep = True))

    #390. Update the AUM database
    aum_hist = pd.concat([
        df_AUM.copy(deep = True).loc[lambda x: ~x.index.isin(aum_upd.index)]
        ,aum_upd
    ])

    #500. Load the product balance for the customers to be updated
    #510. Prepare the customer base for the retireval
    cust_info = aum_upd.reset_index()[['custID']]

    #530. Prepare the modification upon the default arguments with current business requirements
    args_GTSFK = modifyDict(
        getOption['args.def.GTSFK']
        ,{
            'inKPICfg' : cfg_kpi
            ,'InfDatCfg' : {
                'InfDat' : 'cust_info'
                ,'DatType' : 'RAM'
            }
            ,'SingleInf' : True
            ,'dnDates' : d
            ,'MergeProc' : 'SET'
            ,'keyvar' : ['custID']
            ,'SetAsBase' : 'i'
            ,'KeepInfCol' : False
            #Process in parallel for small number of small data files are MUCH SLOWER than sequential mode
            ,'_parallel' : False
        }
    )

    #550. Retrieve product balance
    #[ASSUMPTION]
    #[1] All column names including [custID] will be upcased by below function
    bal_upd = (
        DBuse_GetTimeSeriesForKpi(**args_GTSFK)['data']
        .rename(columns = {'CUSTID' : 'custID'})
        .assign(**{
            'ProdName' : lambda x: x['C_KPI_ID'].map(map_pdtname)
            ,'ProdType' : lambda x: x['C_KPI_ID'].map(map_pdttype)
        })
    )

    #700. Update the product balance history
    bal_hist = pd.concat([
        df_Prod.copy(deep = True).loc[lambda x: ~x['custID'].isin(bal_upd['custID'])]
        ,bal_upd
    ])

    #999. Return the updated data
    return(aum_hist, bal_hist)

#570. Define the dates to loop over the period
loop_dates = loop_data['dates'].drop_duplicates().sort_values()

#590. Loop the calculation
#[ASSUMPTION]
#[1] We avoid to load all Time Series data into RAM at the same time
#[2] Arguments [df_AUM] and [df_Prod] MUST be provided at each iteration, to validate the recursion
for d in loop_dates:
    logger.info('Processing ' + d.strftime('%Y-%m-%d'))
    cust_MaxAUM, acct_MaxAUM = h_calc(d, df_AUM = cust_MaxAUM, df_Prod = acct_MaxAUM)

logger.info('999. Save the result to harddrive')
if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
with pd.HDFStore(L_stpflnm1, mode = 'w') as store:
    store.put(key_hdf_cust, cust_MaxAUM)
    store.put(key_hdf_acct, acct_MaxAUM)
