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

print('Load the KPI core configuration')
import os
import pandas as pd
import xlwings as xw
from omniPy.Dates import asDates

#010. Local environment
#Quote: DeepSeek -> <python locate package by name>
L_srcflnm1 = os.path.join(dir_data_raw, 'CFG_KPI.xlsx')
L_stpflnm1 = os.path.join(dir_data_src, 'CFG_KPI.hdf')
dataIO.add('HDFS')

print('100. Define helper functions')
#110. Function to join several columns into one valid file path in a DataFrame
#[ASSUMPTION]
#[1] We set the prefix of all helper functions as <h_>
#[2] This is to distinguish the objects from those imported from other modules or packages
#130. Function to join the paths out of pd.Series
def h_joinPath(srs : pd.Series):
    vfy_srs = srs.apply(pd.isnull)
    if vfy_srs.all():
        return('')
    else:
        return(os.path.join(*srs.str.strip()))

#130. Function to read the data from <xw.Range>
def h_readRange(xlwb : xw.Book, sheetname : str) -> pd.DataFrame:
    #200. Prepare the specific arguments for current table
    args_axis = {
        'index' : False
        ,'header' : True
    }

    #300. Define the Sheet object
    xlsh = xlwb.sheets[sheetname]

    #400. Define the range
    xlrng = (
        xlsh.range((1,1)).expand()
        #[ASSUMPTION]
        #[1] It is tested that chains of [options()] only validate the last one [xlwings <= 0.28.5]
        .options(pd.DataFrame, **args_axis)
        # .options(formatter = fmt_bold)
    )

    #900. Load the data
    return(xlrng.value)

#150. Function to load EXCEL via <xlwings>
#[ASSUMPTION]
#[1] <pandas.read_excel()> always tries to convert number-like characterss to numeric, which cannot be switched off
#[2] Such behavior leads to weird result: when a cell contains numbers with leading zeros and stores as TEXT, its value
#     will miss out all the leading zeros, even if <dtype='O'> or <converters = str> are specified
#[3] Quote: https://github.com/pandas-dev/pandas/issues/20828
#[4] <xlwings> will not convert number-like characters to numeric imperatively
def h_readEXCEL(infile : str | os.PathLike, sheets = list[str]) -> dict[str, pd.DataFrame]:
    if isinstance(sheets, str):
        sheets = []

    with xw.App( visible = False, add_book = False ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Open the book
        xlwb = xlapp.books.open(infile)

        #500. Execution
        rstOut = { sh : h_readRange(xlwb, sh) for sh in sheets }

        #999. Purge
        xlapp.screen_updating = True

    return(rstOut)

print('200. Determine whether to refresh the HDF Store')
def h_vfy_cfg():
    if os.path.isfile(L_stpflnm1):
        if os.path.getmtime(L_srcflnm1) < os.path.getmtime(L_stpflnm1):
            print('<CFG_KPI> is the latest, no need to import again.')
            return()

    print('300. Import the raw data')
    cfg_kpi_pre = h_readEXCEL(L_srcflnm1, ['KPIConfig','LibConfig'])

    print('500. Reshape the KPI configuration')
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
            cfg_kpi_pre['KPIConfig']
            .assign(**{
                'C_LIB_NAME' : lambda x: x['C_LIB_NAME'].fillna('')
            })
            .merge(
                cfg_kpi_pre['LibConfig']
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
            #500. We always save the full base and leave the filtration to the subsequent process where needed
            # .loc[lambda x: x['D_BGN'].le(asDates(L_curdate))]
            # .loc[lambda x: x['D_END'].ge(asDates(L_curdate))]
            # .loc[lambda x: x['F_KPI_INUSE'].eq(1)]
            #800. Create fields that further facilitate the process in <AdvDB.DBuse_GetTimeSeriesForKpi>
            #[ASSUMPTION]
            #[1] We do not upcase the paths, to ensure the output files are in the same case as user defined
            .assign(**{
                'C_KPI_FILE_NAME' : lambda x: x['C_KPI_FILE_NAME'].str.strip()
                ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('').str.strip()
                ,'C_KPI_FILE_TYPE' : lambda x: x['C_KPI_FILE_TYPE'].str.strip()
                ,'DF_NAME' : lambda x: x['DF_NAME'].fillna('dummy').str.strip()
                ,'options' : lambda x: x['options'].fillna('{}').str.strip()
            })
            #900. Create fields that further facilitate the process in <AdvDB.aggrByPeriod>
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
            'KPIConfig' : cfg_kpi_pre['KPIConfig']
            ,'LibConfig' : cfg_kpi_pre['LibConfig']
            ,'cfg_kpi' : cfg_kpi
        }
        ,L_stpflnm1
        ,kw_put = {
            k : {
                #[ASSUMPTION]
                #[1] Column in dtype='O' that contains objects other than <string> cannot be stored using <format=table>
                #[2] To align the behavior of Data Mart management, we ensure all tables are stored using <format=fixed>
                'format' : 'fixed'
                # If you need to compress the table, place below option for it
                # ,complevel = 5
            }
            for k in ['KPIConfig','LibConfig','cfg_kpi']
        }
    )

h_vfy_cfg()
