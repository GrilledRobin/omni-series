#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os, ast
import numpy as np
import pandas as pd
from functools import partial
from typing import Any
from omniPy.Dates import asDates, intnx
from omniPy.AdvOp import modifyDict, vecStack, ExpandSignature
from omniPy.AdvDB import parseDatName, DataIO, DBuse_GetTimeSeriesForKpi, kfFunc_ts_mtd, validateDMCol

#[ASSUMPTION]
#[1] We leave the annotation as empty, to inherit from the ancestor functions
#[2] To avoid this block of comments being collected as docstring, we skip an empty line below
eSig = ExpandSignature(kfFunc_ts_mtd)

@eSig
def kfFunc_ts_fullmonth(
    *pos
    ,**kw
):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to standardize the generation of KPI datasets by minimize the calculation effort and consumption of      #
#   | system resources                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[TERMINOLOGY]                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Naming: <K>PI <F>actory <FUNC>tion for <T>ime <S>eries by <FULL> <MONTH> algorithm                                             #
#   |[2] It is primarily designed for scenarios where <genPHMul == True> on the last workday/tradeday of a month                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FUNCTION]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Further aggregate MTD KPIs to their Full Month aggregations, useful when the last workday/tradeday is NOT the last calendar day#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate Full Month ANR of product holding balances along the time series, by recognizing the data on each weekend as the same#
#   |     as its previous workday, also leveraging the aggregation result on the last workday of the month                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |*pos          :   Various positional arguments to expand from its ancestor; see its official document                              #
#   |**kw          :   Various keyword arguments to expand from its ancestor; see its official document                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Anno>        :   See the return result from the ancestor function                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240211        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250201        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |      |[2] For the same functionality, enable diversified parameter provision in accordance with its expanded signature            #
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
#   |   |sys, os, ast, numpy, pandas, functools, typing                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |   |intnx                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |modifyDict                                                                                                                 #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |validateDMCol                                                                                                              #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_GetTimeSeriesForKpi                                                                                                  #
#   |   |   |kfFunc_ts_mtd                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    frame = sys._getframe()
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = frame.f_code.co_name

    #012. Parameter buffer
    def h_convStr(vec : Any, func : callable):
        if isinstance(vec, str):
            return(func(vec))
        else:
            return(vec)

    #020. Local environment
    args_share = {}
    pos_in, kw_in = eSig.insParams(args_share, pos, kw)

    inDate = eSig.getParam('inDate', pos_in, kw_in)
    inKPICfg = eSig.getParam('inKPICfg', pos_in, kw_in)
    mapper = eSig.getParam('mapper', pos_in, kw_in)
    _parallel = eSig.getParam('_parallel', pos_in, kw_in)
    cores = eSig.getParam('cores', pos_in, kw_in)
    aggrVar = eSig.getParam('aggrVar', pos_in, kw_in)
    byVar = eSig.getParam('byVar', pos_in, kw_in)
    copyVar = eSig.getParam('copyVar', pos_in, kw_in)
    tableVar = eSig.getParam('tableVar', pos_in, kw_in)
    genPHMul = eSig.getParam('genPHMul', pos_in, kw_in)
    calcInd = eSig.getParam('calcInd', pos_in, kw_in)
    fDebug = eSig.getParam('fDebug', pos_in, kw_in)
    fTrans = eSig.getParam('fTrans', pos_in, kw_in)
    fTrans_opt = eSig.getParam('fTrans_opt', pos_in, kw_in)
    outDTfmt = eSig.getParam('outDTfmt', pos_in, kw_in)
    kw_d = eSig.getParam('kw_d', pos_in, kw_in)
    kw_cal = eSig.getParam('kw_cal', pos_in, kw_in)
    kw_DataIO = eSig.getParam('kw_DataIO', pos_in, kw_in)

    if not isinstance(inKPICfg, (vfyType := pd.DataFrame)):
        raise TypeError(f'[{LfuncName}][inKPICfg] must be of the type <{vfyType}>!')
    if not isinstance(mapper, (vfyType := pd.DataFrame)):
        raise TypeError(f'[{LfuncName}][mapper] must be of the type <{vfyType}>!')

    aggrVar = validateDMCol(aggrVar)[0]
    byVar = validateDMCol(byVar)
    copyVar = validateDMCol(copyVar)

    if not isinstance(genPHMul, bool):
        print(
            f'[{LfuncName}][genPHMul] is not provided as logical value.'
            +' Program resembles the data on Public Holidays by their respective Previous Workdays.'
        )
        genPHMul = True
    if not calcInd: calcInd = 'C'
    calcInd = calcInd.upper()
    if calcInd not in (vldInd := ['C','W','T']):
        raise ValueError(f'[{LfuncName}][calcInd] should be any among {str(vldInd)}!')
    if not isinstance(fDebug, bool): fDebug = False

    keep_all_col = '_ALL_' in [ h_convStr(v, func = str.upper) for v in copyVar ]
    hasKeys = ['HDFS']
    mapper_chain = ['mapper_daily','mapper_mtd','mapper_fm']
    cfg_unique_row = ['C_KPI_ID','N_LIB_PATH_SEQ']
    dateChk_d = asDates(inDate, **kw_d)
    int_sfx = '&kffmdate.'
    if int_sfx not in fTrans:
        fTrans = {
            int_sfx : 'kffm_curr___'
            ,**{ k:v for k,v in fTrans.items() }
        }
        if 'kffm_curr___' not in outDTfmt:
            outDTfmt = {
                'kffm_curr___' : '%Y%m%d'
                ,**{ k:v for k,v in outDTfmt.items() }
            }

    if genPHMul:
        benchofMon = intnx('month', dateChk_d, 0, 'e', daytype = (calcInd if calcInd == 'T' else 'W'), kw_cal = kw_cal)
    else:
        benchofMon = intnx('month', dateChk_d, 0, 'e', daytype = calcInd, kw_cal = kw_cal)

    #[ASSUMPTION]
    #[1] Last day of month is always indicated by <calcInd>
    lastCDofMon = intnx('month', dateChk_d, 0, 'e', daytype = calcInd, kw_cal = kw_cal)
    #[ASSUMPTION]
    #[1] We would redirect the MTD KPI data to RAM for calculation
    #[2] There is no literal <key> for any object in RAM, hence we should differ the objects by names
    cfg_unique_file = ['C_LIB_PATH','C_KPI_FILE_NAME','C_KPI_FILE_TYPE']
    cfg_unique_key = cfg_unique_file + ['DF_NAME']

    #Abort under certain conditions
    if dateChk_d != benchofMon:
        raise RuntimeError(
            f'[{LfuncName}][inDate][{str(dateChk_d)}] should be the last <{calcInd}> of a month,'
            +f' i.e. [{str(benchofMon)}]'
        )

    #021. Instantiate the IO operator for data migration
    #[ASSUMPTION]
    #[1] We use separate IO tool for all internal process where necessary, to avoid unexpected result
    dataIO = DataIO(**kw_DataIO)
    dataIO_int = DataIO(**kw_DataIO)

    #099. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Debug mode...')
        print(f'[{LfuncName}]Parameters are listed as below:')
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        getvar = sys._getframe().f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print(f'[{LfuncName}]'+'[{0}]=[{1}]'.format(v,str(locals().get(v))))

    #100. Minimize the KPI config table for current process
    #101. Function to join the paths out of pd.Series
    def h_joinPath(srs : pd.Series):
        vfy_srs = srs.apply(pd.isnull)
        if vfy_srs.all():
            return('')
        else:
            return(os.path.join(*srs))

    #110. Identify the full base
    cfg_kpi_pre = (
        inKPICfg
        .loc[lambda x: x['D_BGN'].le(dateChk_d)]
        .loc[lambda x: x['D_END'].ge(dateChk_d)]
        .loc[lambda x: x['F_KPI_INUSE'].eq(1)]
        .loc[lambda x: x['C_KPI_ID'].isin(mapper[mapper_chain].stack())]
    )

    #130. Validate the KPIs involved in any chain
    #[ASSUMPTION]
    #[1] All KPIs along any chain must exist at the same time
    mapper_vld = mapper.loc[(
        mapper
        .loc[:, mapper_chain]
        .isin(cfg_kpi_pre['C_KPI_ID'].to_list())
        .all(axis = 1)
    )]

    #150. Mutate the involved config table
    #[ASSUMPTION]
    #[1] We cannot upcase the paths, since <DBuse_GetTimeSeriesForKpi> is called to locate the file paths in their
    #     original character case, esp. for the sources residing in RAM
    cfg_kpi = (
        cfg_kpi_pre
        .loc[lambda x: x['C_KPI_ID'].isin(mapper_vld[mapper_chain].stack())]
        .assign(**{
            'C_KPI_FILE_NAME' : lambda x: x['C_KPI_FILE_NAME'].str.strip()
            ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('').str.strip()
            ,'C_KPI_FILE_TYPE' : lambda x: x['C_KPI_FILE_TYPE'].str.strip()
            ,'DF_NAME' : lambda x: x['DF_NAME'].fillna('dummy').str.strip()
            ,'options' : lambda x: x['options'].fillna('{}').str.strip()
        })
        .assign(**{
            'FilePath' : lambda x: x[['C_LIB_PATH','C_KPI_FILE_NAME']].apply(h_joinPath, axis = 1)
        })
    )

    #160. Only validate the paths at top priority for all Full Month KPIs
    #[ASSUMPTION]
    #[1] These KPIs are only CREATED to the paths of their respective top priority, while not SEARCHED in this process
    cfg_kpi_fm_pre = (
        cfg_kpi
        .loc[lambda x: x['C_KPI_ID'].isin(mapper_vld['mapper_fm'])]
        .loc[lambda x: (
            x[cfg_unique_row]
            .isin(
                x.sort_values(cfg_unique_row)
                .groupby('C_KPI_ID', as_index = False)
                .head(1)
                [cfg_unique_row]
            )
            .all(axis = 1)
        )]
    )

    #170. Determine the unique paths for Full Month KPIs
    file_fm_unique = (
        cfg_kpi_fm_pre
        .drop_duplicates(cfg_unique_file)
        .set_index(cfg_unique_file)
        .assign(**{
            'df_i' : lambda x: range(len(x))
        })
    )

    #180. Determine the unique <keys> for Full Month KPIs
    key_fm_unique = (
        cfg_kpi_fm_pre
        .drop_duplicates(cfg_unique_key)
        .assign(**{
            'key_i' : lambda x: x.groupby(cfg_unique_file)['C_KPI_ID'].cumcount()
        })
        .set_index(cfg_unique_key)
    )

    #190. Create config table for Full Month KPIs
    cfg_kpi_fm = (
        cfg_kpi_fm_pre
        .assign(**{
            'out_unique' : lambda x: (
                x.drop_duplicates(cfg_unique_key)
                .sort_values(cfg_unique_key)
                .assign(**{
                    'out_unique' : lambda y: range(len(y))
                })
                .set_index(cfg_unique_key)
                .reindex(x.set_index(cfg_unique_key).index)
                .set_index(x.index)
                ['out_unique']
            )
        })
        .assign(**{
            'kfts_org_path' : lambda x: x['C_LIB_PATH']
            ,'kfts_org_file' : lambda x: x['C_KPI_FILE_NAME']
            ,'kfts_org_type' : lambda x: x['C_KPI_FILE_TYPE']
            ,'kfts_org_key' : lambda x: x['DF_NAME']
            ,'kfts_org_opt' : lambda x: x['options']
            ,'kfts_org_fullpath' : lambda x: x['FilePath']
            ,'df_i' : lambda x: (
                file_fm_unique
                .reindex(x.set_index(cfg_unique_file).index)
                .set_index(x.index)
                ['df_i']
            )
            ,'key_i' : lambda x: (
                key_fm_unique
                .reindex(x.set_index(cfg_unique_key).index)
                .set_index(x.index)
                ['key_i']
            )
        })
        .assign(**{
            'C_LIB_PATH' : ''
            ,'C_KPI_FILE_NAME' : lambda x: (
                x['df_i'].apply(str)
                .add('_').add(x['key_i'].apply(str))
                #[ASSUMPTION]
                #[1] Below string pattern must be able to translate as indicated in <fTrans>
                .radd('kfts_').add('_').add(int_sfx)
            )
            ,'C_KPI_FILE_TYPE' : 'RAM'
            ,'DF_NAME' : 'dummy'
            ,'options' : '{}'
        })
        .assign(**{
            'FilePath' : lambda x: x[['C_LIB_PATH','C_KPI_FILE_NAME']].apply(h_joinPath, axis = 1)
        })
    )

    #500. Helper functions
    #520. Column filter during loading data
    def h_keepVar(df : pd.DataFrame):
        if keep_all_col:
            return(df.columns)
        else:
            keepVars = (
                pd.concat([vecStack('C_KPI_ID'),vecStack(aggrVar),vecStack(byVar),vecStack(copyVar)])
                .astype({'.val.' : 'O'})
                .assign(**{
                    '.val.' : lambda x: x['.val.'].apply(h_convStr, func = str.upper)
                })
            )
            return(df.head(0).rename(columns = partial(h_convStr, func = str.upper)).columns.isin(keepVars['.val.']))

    #560. Function to only retrieve the empty table structure with 0 length on axis 0
    def h_nullify(df : pd.DataFrame):
        return(df.head(0))

    #570. Function to process a single output file name
    def h_outkey(row : pd.Series):
        #009. Debug mode
        if fDebug:
            if row['C_KPI_FILE_TYPE'] in hasKeys:
                print(f'''[{LfuncName}]Collect MTD KPI data for output key: <{row['DF_NAME']}>''')
            else:
                print(f'''[{LfuncName}]Collect MTD KPI data frame for dummy key''')

        #100. Subset the config table
        #110. Retrieve the mapper for current step
        mapper_load = (
            mapper
            .loc[lambda m: m['mapper_fm'].isin(
                cfg_kpi_fm
                .loc[lambda f: f['out_unique'].eq(row['out_unique']), 'C_KPI_ID']
            )]
        )

        #150. Filter the KPI config table
        #[ASSUMPTION]
        #[1] We only need to load the MTD KPI data into RAM
        cfg_mtd = (
            cfg_kpi
            .loc[lambda x: x['C_KPI_ID'].isin(mapper_load['mapper_mtd'])]
        )

        #170. Differ the mapping logic
        map_kpi_id = dict(mapper_load[['mapper_mtd','mapper_fm']].values)

        #179. Debug mode
        if fDebug:
            print(f'[{LfuncName}]Directly map below MTD KPIs to Full Month ID:')
            print(str(map_kpi_id))

        #200. Define helper functions
        #210. Function to only retrieve the involved map-to KPIs right after loading the data
        def h_to(df : pd.DataFrame):
            return(df.loc[lambda x: x['C_KPI_ID'].isin(cfg_mtd['C_KPI_ID']), h_keepVar])

        #300. Patch the behavior when loading data source
        kw_io = modifyDict(
            kw_DataIO
            ,{ 'argsPull' : { apiname : { 'funcConv' : h_to } for apiname in dataIO.full } }
        )

        #500. Prepare the common arguments for the data retrieval
        args_GTSFK = {
            'inKPICfg' : cfg_mtd
            ,'dnDates' : dateChk_d
            ,'ColRecDate' : 'D_RecDate'
            ,'fImp_opt' : 'options'
            ,'MergeProc' : 'SET'
            ,'keyvar' : byVar
            ,'SetAsBase' : 'k'
            ,'fTrans' : fTrans
            ,'fTrans_opt' : fTrans_opt
            ,'outDTfmt' : outDTfmt
            ,'_parallel' : _parallel
            ,'cores' : cores
            ,'fDebug' : fDebug
            ,'miss_files' : 'G_miss_files'
            ,'err_cols' : 'G_err_cols'
            ,'values_fn' : np.nansum
            ,'kw_DataIO' : kw_io
        }

        #700. Retrieve the data
        #[ASSUMPTION]
        #[1] We do not ignore the user warninggs at this step, since the data sources are designed to exist
        #[2] If none of the input data exists, below function raises exception, hence result can never be <None>
        #[3] We would verify the warnings later at abort the process, for the same reason as [1]
        rstPre = DBuse_GetTimeSeriesForKpi(**args_GTSFK)

        #790. Abort upon any warnings
        msgs = []
        if (vfyCol := rstPre.get('G_err_cols', None)) is not None:
            msgs += ['unmatched column types']
            print(f'[{LfuncName}]Error column types:')
            print(vfyCol)
        if (vfyMis := rstPre.get('G_miss_files', None)) is not None:
            msgs += ['missing source files']
            print(f'[{LfuncName}]Missing source data files:')
            print(vfyMis['C_KPI_FULL_PATH'])
        if len(msgs) > 0:
            raise RuntimeError(f'''[{LfuncName}]Process fails due to {' and '.join(msgs)}, please check above log!''')

        #800. Mutate the result
        rstOut = (
            rstPre.get('data', None)
            .drop(columns = ['D_RecDate'])
            .assign(**{
                'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_kpi_id)
            })
        )
        if tableVar in rstOut.columns:
            rstOut = (
                rstOut
                .assign(**{
                    tableVar : lambda x: asDates(dateChk_d)
                })
            )

        #999. Output
        return(rstOut)

    #570. Function to process a single output file name
    def h_outfile(row : pd.Series):
        #100. Register API
        dataIO.add(row['kfts_org_type'])

        #300. Load data as <chkDat> for all unique <key>s in current output file
        rstInt = (
            cfg_kpi_fm
            .loc[lambda x: x['kfts_org_path'].eq(row['kfts_org_path'])]
            .loc[lambda x: x['kfts_org_file'].eq(row['kfts_org_file'])]
            .assign(**{
                'agg_df' : lambda x: x.apply(h_outkey, axis = 1)
                ,'chkDat' : lambda x: (
                    parseDatName(
                        datPtn = x['FilePath']
                        ,dates = dateChk_d
                        ,outDTfmt = outDTfmt
                        ,chkExist = False
                        ,dict_map = fTrans
                        ,**fTrans_opt
                    )
                    .set_index('FilePath')
                    .reindex(x['FilePath'])
                    .set_index(x.index)
                    ['FilePath.Parsed']
                )
                ,'outDat' : lambda x: (
                    parseDatName(
                        datPtn = x['FilePath']
                        ,dates = lastCDofMon
                        ,outDTfmt = outDTfmt
                        ,chkExist = False
                        ,dict_map = fTrans
                        ,**fTrans_opt
                    )
                    .set_index('FilePath')
                    .reindex(x['FilePath'])
                    .set_index(x.index)
                    ['FilePath.Parsed']
                )
            })
        )

        #500. Determine the output file name
        #[ASSUMPTION]
        #[1] There is only one output file name at this step
        outfile = (
            parseDatName(
                datPtn = (
                    rstInt[['kfts_org_path','kfts_org_file']]
                    .drop_duplicates()
                    .apply(h_joinPath, axis = 1)
                    .rename('FilePath')
                )
                ,dates = lastCDofMon
                ,outDTfmt = outDTfmt
                ,chkExist = False
                ,dict_map = fTrans
                ,**fTrans_opt
            )
            ['FilePath.Parsed']
            .iat[0]
        )

        #509. Debug mode
        if fDebug:
            print(f'''[{LfuncName}]Dedicated Full Month file is: <{outfile}>''')

        #600. Patch the behavior to write data
        if row['kfts_org_type'] in hasKeys:
            kw_patcher = {
                'kw_put' : dict(
                    rstInt
                    .assign(**{
                        'opt.ast.Parsed' : lambda x: x['kfts_org_opt'].apply(ast.literal_eval)
                    })
                    [['kfts_org_key','opt.ast.Parsed']]
                    .values
                )
            }
        else:
            kw_patcher = ast.literal_eval(row['kfts_org_opt'])

            if row['kfts_org_type'] == 'SAS':
                if kw_patcher.get('encoding', '').upper().startswith('GB'):
                    kw_patcher = modifyDict(
                        kw_patcher
                        ,{ 'encoding' : 'GB2312' }
                    )

        #700. Differ the process
        if dateChk_d == lastCDofMon:
            #009. Debug mode
            if fDebug:
                print(f'[{LfuncName}]Directly convert MTD data to Full Month file')

            #900. Write the data
            rc = dataIO[row['kfts_org_type']].push(
                dict(rstInt[['kfts_org_key','agg_df']].values)
                ,outfile
                ,**kw_patcher
            )
        else:
            #009. Debug mode
            if fDebug:
                print(f'[{LfuncName}]Prepare MTD data as <chkDat>')

            #100. Create <chkDat>
            #110. Register API
            dataIO_int.add('RAM')

            #170. Helper function to loop the process
            def h_pushRAM(srs : pd.Series):
                rc = dataIO_int['RAM'].push(
                    { srs['DF_NAME'] : srs['agg_df'] }
                    ,srs['chkDat']
                    ,frame = frame
                )
                return(rc)

            #190. Write the data
            rc_chk = rstInt.apply(h_pushRAM, axis = 1)

            #199. Assert the success
            if fDebug:
                print(f'[{LfuncName}]Verify the success for creation of <chkDat>')
                print(rstInt['chkDat'])
            assert rc_chk.eq(0).all()

            #500. Call the standard process for calculation
            #509. Debug mode
            if fDebug:
                print(f'[{LfuncName}]Create interim Full Month data in current frame')

            #510. Create mapper for current step
            mapper_DtoFM = (
                mapper
                .loc[
                    lambda x: x['mapper_fm'].isin(rstInt['C_KPI_ID'])
                    ,['mapper_daily','mapper_fm']
                ]
                .rename(columns = {
                    'mapper_daily' : 'mapper_fr'
                    ,'mapper_fm' : 'mapper_to'
                })
            )

            #530. Patch the behavior when writing the data
            kw_io = modifyDict(
                kw_DataIO
                ,{ 'argsPush' : { 'RAM' : { 'frame' : frame } } }
            )

            #550. Prepare KPI config table
            cfg_out = pd.concat([
                cfg_kpi.loc[lambda x: x['C_KPI_ID'].isin(mapper_DtoFM['mapper_fr'])]
                ,cfg_kpi_fm.loc[lambda x: x['C_KPI_ID'].isin(mapper_DtoFM['mapper_to'])]
            ])

            #570. Prepare the modification upon the signature with Business requirement
            #[ASSUMPTION]
            #[1] Below local variables have been modified at earlier steps, so we cannot mix them up with the raw input
            args_mtd = {
                'inDate' : lastCDofMon
                ,'inKPICfg' : cfg_out
                ,'mapper' : mapper_DtoFM
                ,'aggrVar' : aggrVar
                ,'byVar' : byVar
                ,'copyVar' : copyVar
                ,'tableVar' : tableVar
                ,'fTrans' : fTrans
                ,'outDTfmt' : outDTfmt
                ,'kw_DataIO' : kw_io
            }
            pos_mtd, kw_mtd = eSig.updParams(args_mtd, pos_in, kw_in)

            #590. Call the process
            rc_int = eSig.src(*pos_mtd, **kw_mtd)

            #599. Assert the success
            if fDebug:
                print(f'[{LfuncName}]Verify the success for creation of interim Full Month data')
                print(rc_int)
            assert rc_int['rc'].eq(0).all()

            #900. Write the data via the dedicated API
            #909. Debug mode
            if fDebug:
                print(f'[{LfuncName}]Write the data via the dedicated API')

            #990. Call the API
            rc = dataIO[row['kfts_org_type']].push(
                dict(rstInt[['kfts_org_key','outDat']].values)
                ,outfile
                ,**kw_patcher
            )

        #899. Remove the API to purge the RAM used
        dataIO.remove(row['kfts_org_type'])

        #999. Output the result
        return({outfile : rc})

    #700. Execute the process
    #709. Verify the duplication of file type
    vfy_type = (
        cfg_kpi_fm
        [['kfts_org_path','kfts_org_file','kfts_org_type']]
        .drop_duplicates()
        .assign(**{
            'FilePath' : lambda x: x[['kfts_org_path','kfts_org_file']].apply(h_joinPath, axis = 1)
        })
        .groupby(['FilePath'], as_index = False)
        ['kfts_org_type']
        .count()
        .loc[lambda x: x['kfts_org_type'].gt(1)]
    )
    if len(vfy_type):
        raise ValueError(
            f'''[{LfuncName}]Ambiguous <C_KPI_FILE_TYPE> for {str(vfy_type['FilePath'].to_list())}!'''
            +' Check <inKPICfg> for detailed <C_KPI_FILE_TYPE> of these file names.'
        )

    #719. Verify the duplication of file API options
    vfy_opt = (
        cfg_kpi_fm
        .loc[
            lambda x: ~x['kfts_org_type'].isin(hasKeys)
            ,['kfts_org_path','kfts_org_file','kfts_org_opt']
        ]
        .drop_duplicates()
        .assign(**{
            'FilePath' : lambda x: x[['kfts_org_path','kfts_org_file']].apply(h_joinPath, axis = 1)
        })
        .groupby(['FilePath'], as_index = False)
        ['kfts_org_opt']
        .count()
        .loc[lambda x: x['kfts_org_opt'].gt(1)]
    )
    if len(vfy_opt):
        raise ValueError(
            f'''[{LfuncName}]Ambiguous <options> for {str(vfy_type['FilePath'].to_list())}!'''
            +' Check <inKPICfg> for detailed <options> of these file names.'
        )

    #750. Execution
    rstOut = (
        cfg_kpi_fm
        [['kfts_org_path','kfts_org_file','kfts_org_type','kfts_org_opt']]
        .drop_duplicates()
        .assign(**{
            'rc_pre' : lambda x: x.apply(h_outfile, axis = 1)
        })
        .assign(**{
            'FilePath' : lambda x: x['rc_pre'].apply(lambda row: list(row.keys())[0])
            ,'rc' : lambda x: x['rc_pre'].apply(lambda row: list(row.values())[0])
        })
        .rename(columns = {'kfts_org_type' : 'C_KPI_FILE_TYPE'})
        [['FilePath','C_KPI_FILE_TYPE','rc']]
    )

    #999. Validate the completion
    return(rstOut)
#End kfFunc_ts_fullmonth

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys, os, ast
    import numpy as np
    import pandas as pd
    import datetime as dt
    from inspect import signature
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import exec_file, modifyDict
    from omniPy.AdvDB import aggrByPeriod, kfFunc_ts_mtd, kfFunc_ts_fullmonth
    from omniPy.Dates import asDates, UserCalendar, intnx

    #010. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Set parameters
    #[ASSUMPTION]
    #[1] Below date indicates the beginning of one KPI among those in the config table
    G_d_rpt = '20160429'
    bgn_kpi2 = intnx('day', G_d_rpt, -1, daytype = 'w')
    G_d_out = intnx('month', G_d_rpt, 0, 'e', daytype = 'c').strftime('%Y%m%d')
    cfg_kpi_file = os.path.join(dir_omniPy, 'omniPy', 'AdvDB', 'CFG_KPI_Example.xlsx')
    cfg_kpi = (
        pd.read_excel(
            cfg_kpi_file
            ,sheet_name = 'KPIConfig'
            ,dtype = 'object'
        )
        .assign(**{
            'C_LIB_NAME' : lambda x: x['C_LIB_NAME'].fillna('')
        })
        .merge(
            pd.read_excel(
                cfg_kpi_file
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
            ,'N_LIB_PATH_SEQ' : lambda x: x['N_LIB_PATH_SEQ'].fillna(0).astype(int)
            ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('')
        })
        .assign(**{
            'D_BGN' : lambda x: (
                x['D_BGN']
                .where(
                    ~x['C_KPI_SHORTNAME'].str.startswith('kpi2')
                    ,bgn_kpi2
                )
            )
        })
    )

    #150. Mapper to indicate the aggregation
    #[ASSUMPTION]
    #[1] <D_BGN> of KPI <140111> is the same as <G_d_rpt>, hence its result only leverages daily KPI starting from <D_BGN>,
    #     regardless of whether the daily KPI data exists before that date
    map_dict = {
        0 : ['130100','130101','130109']
        ,1 : ['140110','140111','140119']
    }
    map_agg = pd.DataFrame.from_dict(
        map_dict
        ,orient = 'index'
        ,columns = ['mapper_daily','mapper_mtd','mapper_fm']
    )
    map_DtoFM = dict(map_agg[['mapper_daily','mapper_fm']].values)

    #300. Call the factory to create Full Month ANR
    #310. Prepare arguments for MTD ANR
    args_ts_mtd = {
        'inKPICfg' : cfg_kpi
        ,'mapper' : (
            map_agg
            .rename(columns = {
                'mapper_daily' : 'mapper_fr'
                ,'mapper_mtd' : 'mapper_to'
            })
        )
        ,'inDate' : G_d_rpt
        ,'_parallel' : False
        ,'cores' : 4
        ,'aggrVar' : 'A_KPI_VAL'
        ,'byVar' : ['nc_cifno','nc_acct_no']
        ,'copyVar' : '_all_'
        ,'genPHMul' : True
        ,'calcInd' : 'C'
        ,'funcAggr' : np.mean
        ,'fDebug' : False
        ,'fTrans' : getOption['fmt.def.GTSFK']
        ,'fTrans_opt' : getOption['fmt.opt.def.GTSFK']
        ,'outDTfmt' : getOption['fmt.parseDates']
    }

    #330. Prepare MTD ANR for all required workdays, literally from the beginning of <kpi2>
    #[ASSUMPTION]
    #[1] In such case that a KPI does not exist in all required days in a month, its initial MTD aggregation should exist
    #     for all subsequent daily aggregation processes, otherwise the result from <aggrByPeriod> is unexpected
    cln_init = UserCalendar(bgn_kpi2, G_d_rpt)
    for d in cln_init.d_AllWD:
        args_ts_init = modifyDict(
            args_ts_mtd
            ,{'inDate' : d}
        )
        time_bgn = dt.datetime.now()
        rst_init = kfFunc_ts_mtd(**args_ts_init)
        time_end = dt.datetime.now()
        print(time_end - time_bgn)

    #350. Prepare arguments for Full Month ANR
    args_ts_fm = modifyDict(
        args_ts_mtd
        ,{
            'inDate' : G_d_rpt
            ,'mapper' : map_agg
        }
    )

    #370. Call the process
    time_bgn = dt.datetime.now()
    rst_fm = kfFunc_ts_fullmonth(**args_ts_fm)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:06.247022

    #400. Verify the result
    #410. Retrieve the newly created data
    ptn_0 = r'D:\Temp\agg{currdate}.hdf'
    ptn_1 = r'D:\Temp\fm_{currdate}.hdf'
    file_kpi1 = ptn_1.format(currdate = G_d_out)
    rst_kpi1 = (
        pd.read_hdf(file_kpi1, 'kpi1')
        .loc[lambda x: x['C_KPI_ID'].eq('130109')]
    )
    rst_kpi2 = (
        pd.read_hdf(file_kpi1, 'kpi2')
        .loc[lambda x: x['C_KPI_ID'].eq('140119')]
    )

    #420. Prepare unanimous arguments
    cln = UserCalendar(
        intnx('month', G_d_rpt, 0, 'b', daytype = 'c')
        ,intnx('month', G_d_rpt, 0, 'e', daytype = 'c')
    )
    byvar_kpis = args_ts_mtd.get('byVar')
    if isinstance(byvar_kpis, (str, tuple)):
        byvar_kpis = [byvar_kpis]
    #[ASSUMPTION]
    #[1] One should NEVER use <+=> to append new items to a list, as it modifies the original object
    #[2] Use other syntax to avoid modification of the object
    # byvar_kpis += ['C_KPI_ID']
    byvar_kpis = list(set(byvar_kpis + ['C_KPI_ID']))
    aggvar_kpis = args_ts_mtd.get('aggrVar')

    #430. Modify the config table to adapt to <aggrByPeriod>
    cfg_agg = (
        cfg_kpi
        .assign(**{
            'FilePath' : lambda x: x.apply( lambda row: os.path.join(row['C_LIB_PATH'], row['C_KPI_FILE_NAME']), axis = 1 )
            ,'FileName' : lambda x: x['C_KPI_FILE_NAME']
            ,'PathSeq' : lambda x: x['N_LIB_PATH_SEQ']
        })
    )

    #440. Calculate the ANR manually for <kpi1>
    datptn_agg_kpi1 = (
        cfg_agg
        .loc[lambda x: x['C_KPI_ID'].eq('130100')]
    )
    agg_opt_kpi1 = ast.literal_eval((
        datptn_agg_kpi1
        ['options']
        .fillna('')
        .drop_duplicates()
        .iat[0]
    ))
    args_agg_kpi1 = modifyDict(
        {
            k:v
            for k,v in args_ts_mtd.items()
            if k in [ s.name for s in signature(aggrByPeriod).parameters.values() ]
        }
        ,{
            'inDatPtn' : datptn_agg_kpi1
            ,'inDatType' : 'C_KPI_FILE_TYPE'
            ,'in_df' : 'DF_NAME'
            ,'fImp_opt' : agg_opt_kpi1
            ,'dateBgn' : cln.d_AllCD[0]
            ,'dateEnd' : cln.d_AllCD[-1]
            ,'byVar' : byvar_kpis
            ,'outVar' : aggvar_kpis
        }
    )
    man_kpi1 = (
        aggrByPeriod(**args_agg_kpi1).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_DtoFM)
            ,'D_TABLE' : asDates(G_d_out)
        })
    )

    #460. Calculate the ANR manually for <kpi2>
    datptn_agg_kpi2 = (
        cfg_agg
        .loc[lambda x: x['C_KPI_ID'].eq('140110')]
    )
    agg_opt_kpi2 = ast.literal_eval((
        datptn_agg_kpi2
        ['options']
        .fillna('')
        .drop_duplicates()
        .iat[0]
    ))
    args_agg_kpi2 = modifyDict(
        args_agg_kpi1
        ,{
            'inDatPtn' : datptn_agg_kpi2
            ,'fImp_opt' : agg_opt_kpi2
            #[ASSUMPTION]
            #[1] Since <D_BGN> is changed (see the data <cfg_agg>), we should only involve data file
            #     on two dates for identical calculation
            ,'dateBgn' : bgn_kpi2
        }
    )
    man_kpi2 = (
        aggrByPeriod(**args_agg_kpi2).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_DtoFM)
            ,'D_TABLE' : asDates(G_d_out)
            #[ASSUMPTION]
            #[1] Since we only used two data files, we need to divide the result by the number of calendar days in the
            #     calculation period
            ,aggvar_kpis : lambda x: x[aggvar_kpis].mul(3).div(cln.kClnDay)
        })
    )

    #490. Assertion
    rst_kpi1.eq(man_kpi1).all(axis = None)
    # True
    rst_kpi2.eq(man_kpi2).all(axis = None)
    # True

    #600. Calculate MTD ANR for the next month, with its last workday the same as its last calendar day
    G_d_rpt2 = intnx('month', G_d_rpt, 1, 'e', daytype = 'w').strftime('%Y%m%d')
    G_d_out2 = intnx('month', G_d_rpt2, 0, 'e', daytype = 'c').strftime('%Y%m%d')
    args_ts_mtd2 = modifyDict(
        args_ts_mtd
        ,{
            'inDate' : G_d_rpt2
            #[ASSUMPTION]
            #[1] Check the log on whether the process leveraged the result on the previous workday
            ,'fDebug' : True
        }
    )

    #630. Prepare MTD ANR for the requested date
    time_bgn = dt.datetime.now()
    rst_mtd2 = kfFunc_ts_mtd(**args_ts_mtd2)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:05.548223

    #650. Prepare arguments for Full Month ANR
    args_ts_fm2 = modifyDict(
        args_ts_mtd2
        ,{
            'inDate' : G_d_rpt2
            ,'mapper' : map_agg
        }
    )

    #670. Call the process
    time_bgn = dt.datetime.now()
    rst_fm2 = kfFunc_ts_fullmonth(**args_ts_fm2)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:01.595124

    #700. Verify the result for the next workday
    #710. Retrieve the newly created data
    file_kpi1_2 = ptn_1.format(currdate = G_d_out2)
    rst_kpi1_2 = (
        pd.read_hdf(file_kpi1_2, 'kpi1')
        .loc[lambda x: x['C_KPI_ID'].eq('130109')]
    )
    rst_kpi2_2 = (
        pd.read_hdf(file_kpi1_2, 'kpi2')
        .loc[lambda x: x['C_KPI_ID'].eq('140119')]
    )

    #720. Prepare unanimous arguments
    cln2 = UserCalendar( intnx('month', G_d_out2, 0, 'b', daytype = 'c'), G_d_out2 )

    #740. Calculate the ANR manually for <kpi1>
    args_agg_kpi1_2 = modifyDict(
        args_agg_kpi1
        ,{
            'dateBgn' : cln2.d_AllCD[0]
            ,'dateEnd' : G_d_out2
        }
    )
    man_kpi1_2 = (
        aggrByPeriod(**args_agg_kpi1_2).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_DtoFM)
            ,'D_TABLE' : asDates(G_d_rpt2)
        })
    )

    #760. Calculate the ANR manually for <kpi2>
    args_agg_kpi2_2 = modifyDict(
        args_agg_kpi1_2
        ,{
            'inDatPtn' : datptn_agg_kpi2
            ,'fImp_opt' : agg_opt_kpi2
        }
    )
    man_kpi2_2 = (
        aggrByPeriod(**args_agg_kpi2_2).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_DtoFM)
            ,'D_TABLE' : asDates(G_d_rpt2)
        })
    )

    #790. Assertion
    rst_kpi1_2.eq(man_kpi1_2).all(axis = None)
    # True
    rst_kpi2_2.eq(man_kpi2_2).all(axis = None)
    # True

    #900. Purge
    for d in cln_init.d_AllWD:
        f = ptn_0.format(currdate = d.strftime('%Y%m%d'))
        if os.path.isfile(f): os.remove(f)
    if os.path.isfile(ptn_0.format(currdate = G_d_rpt2)): os.remove(ptn_0.format(currdate = G_d_rpt2))
    if os.path.isfile(ptn_1.format(currdate = G_d_out)): os.remove(ptn_1.format(currdate = G_d_out))
    if os.path.isfile(ptn_1.format(currdate = G_d_out2)): os.remove(ptn_1.format(currdate = G_d_out2))
#-Notes- -End-
'''
