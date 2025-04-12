#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create daily KPI in standard format                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Different KPIs may be stored in one <HDFS> file with different <key>s                                                          #
#   |[2] Key fields are <D_TABLE>, <C_KPI_ID>, <A_KPI_VAL>, as well as all other fields that are Business Keys and Categories           #
#   |[3] As a standard practice, use upper case for all field names, as other factory functions such as <AdvDB.aggrByPeriod> will do    #
#   |     the upcase anyway to ensure correct aggregation upon necessary fields                                                         #
#   |[4] Since there is always the field <D_TABLE> with <dt.date> values in dtype as <object>, the output result is ensured to store    #
#   |     with <format=fixed>; so there is no need to specify <kw_put={'format' : 'fixed'}> during output                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250404        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250412        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Ensure <N_LIB_PATH_SEQ> is the minimum among all <N_LIB_PATH_SEQ> of the same <C_LIB_NAME>, rather than globally        #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Create daily KPI')
import os
import pandas as pd
from omniPy.AdvOp import get_values
from omniPy.Dates import asDates
from omniPy.AdvDB import parseDatName

#010. Local environment
L_srcflnm1 = os.path.join(dir_data_src, f'CFG_KPI.hdf')
#[ASSUMPTION]
#[1] Below setting indicates these KPIs are stored in the same file on the same date
kpi_this = {
    '130100'
    ,'140110'
}
dataIO.add('HDFS')

#040. Load the data in current session
if not isinstance(get_values('cfg_kpi', inplace = False), pd.DataFrame):
    cfg_kpi = dataIO['HDFS'].pull(L_srcflnm1, 'cfg_kpi')

print('100. Define helper functions')
#[ASSUMPTION]
#[1] Below values are only for demonstration, real cases are more complex
d_date = asDates(L_curdate)

#110. Function to create the 1st KPI, same as all the rest ones
def h_f_130100() -> pd.DataFrame:
    rstOut = (
        pd.DataFrame.from_records([
            {
                'NC_CUST' : '0001'
                ,'NC_ACCT' : '001010'
                ,'C_RM' : 'a'
                ,'C_BRANCH' : 'SH'
                ,'A_KPI_VAL' : d_date.day * 1.7
            }
            ,{
                'NC_CUST' : '0002'
                ,'NC_ACCT' : '002010'
                ,'C_RM' : 'b'
                ,'C_BRANCH' : 'BJ'
                ,'A_KPI_VAL' : (d_date.month * 2.0 + d_date.day) * 1.5
            }
        ])
        .assign(**{
            'D_TABLE' : asDates(L_curdate)
            ,'C_KPI_ID' : '130100'
        })
    )
    return(rstOut)

#120. Function to create the 2nd KPI
def h_f_140110() -> pd.DataFrame:
    rstOut = (
        pd.DataFrame.from_records([
            {
                'NC_CUST' : '0001'
                ,'NC_ACCT' : '001010'
                ,'C_RM' : 'b'
                ,'C_BRANCH' : 'BJ'
                ,'A_KPI_VAL' : d_date.day * 0.9
            }
            ,{
                'NC_CUST' : '0002'
                ,'NC_ACCT' : '002010'
                ,'C_RM' : 'b'
                ,'C_BRANCH' : 'BJ'
                ,'A_KPI_VAL' : (d_date.month * 0.9 + d_date.day * 0.1) * 1.6
            }
        ])
        .assign(**{
            'D_TABLE' : asDates(L_curdate)
            ,'C_KPI_ID' : '140110'
        })
    )
    return(rstOut)

print('500. Function to collectively create KPIs in one batch')
def h_genKPI(kpi_id : str) -> pd.DataFrame:
    return(get_values(f'h_f_{kpi_id}')())

print('700. Create KPI data')
#710. Locate the captioned KPIs
cfg_this = (
    cfg_kpi
    .loc[lambda x: x['C_KPI_ID'].isin(kpi_this)]
    .loc[lambda x: x['D_BGN'].le(d_date)]
    .loc[lambda x: x['D_END'].ge(d_date)]
    .loc[lambda x: x['F_KPI_INUSE'].eq(1)]
    .loc[lambda x: x['N_LIB_PATH_SEQ'].eq(
        x.groupby(['C_KPI_ID','C_LIB_NAME'])
        ['N_LIB_PATH_SEQ'].min()
        .reindex(x.set_index(['C_KPI_ID','C_LIB_NAME']).index)
        .set_axis(x.index)
    )]
)

#719. Raise if the output files of these KPIs are NOT the same one
if len(cfg_this['FilePath'].str.upper().drop_duplicates()) > 1:
    raise ValueError(f'Captioned KPIs: {kpi_this} are in different output files and cannot be created in one batch!')

#750. Execution
rst_this = (
    cfg_this
    .assign(**{
        'df_out' : lambda x: x['C_KPI_ID'].apply(h_genKPI)
    })
    [['DF_NAME','df_out']]
)

#780. Determine the output file
#[ASSUMPTION]
#[1] <getOption> is defined in <autoexec>
rst_file = (
    parseDatName(
        datPtn = cfg_this['FilePath'].iat[0]
        ,dates = L_curdate
        ,outDTfmt = getOption['fmt.parseDates']
        ,inRAM = False
        ,chkExist = False
        ,dict_map = getOption['fmt.def.GTSFK']
        ,**getOption['fmt.opt.def.GTSFK']
    )
    ['datPtn.Parsed'].iat[0]
)

#790. Create the folder for the process
if not os.path.isdir(rst_dir := os.path.dirname(rst_file)):
    os.makedirs(rst_dir)

print('999. Save the result to harddrive')
if os.path.isfile(rst_file): os.remove(rst_file)
rc = dataIO['HDFS'].push(
    { k:v for k,v in rst_this.itertuples(index = False) }
    ,rst_file
)
