#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys
import pandas as pd
import numpy as np
from collections import Counter
from collections.abc import Iterable
from warnings import warn
from typing import Optional, Union
from omniPy.AdvDB import parseDatName, DBuse_SetKPItoInf

#For annotations in function arguments, see [PEP 604 -- Allow writing union types as X | Y] for [Python >= 3.10]
def DBuse_MrgKPItoInf(
    inKPICfg : pd.DataFrame
    ,InfDat : Optional[pd.DataFrame] = None
    ,keyvar : Optional[Iterable] = None
    ,SetAsBase : str = 'I'
    ,KeepInfCol : bool = False
    ,fTrans : Optional[dict] = None
    ,fTrans_opt : dict = {}
    ,fImp_opt : dict | str = {
        'SAS' : {
            'encoding' : 'GB18030'
        }
    }
    ,_parallel : bool = True
    ,cores : int = 4
    ,fDebug : bool = False
    ,miss_skip : bool = True
    ,miss_files : str = 'G_miss_files'
    ,err_cols : str = 'G_err_cols'
    ,outDTfmt : dict = {
        'L_d_curr' : '%Y%m%d'
        ,'L_m_curr' : '%Y%m'
    }
    ,dup_KPIs : str = 'G_dup_kpiname'
    ,AggrBy : Iterable = None
    ,values_fn : Union[str, callable, dict] = np.sum
    ,kw_DataIO : dict = {}
    ,**kw
) -> dict:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to merge the KPI data to the given (descriptive) information data, in terms of different merging methods #
#   | and pivot all the requested KPIs into new columns to fit the data visualization.                                                  #
#   |IMPORTANT: If there is any variable in both [InfDat] and the KPI dataset, the latter will be taken for granted by default and can  #
#   |            be switched by [KeepInfCol] (can switch by parameter [KeepInfCol]). This is useful when the mapping result in the KPI  #
#   |            dataset is at higher priority during the merge.                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Description of the data storage:                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Daily [KPI]s are stored in different files; while 0 or NaN values of [KPI]s can be excluded to reduce disk expense             #
#   |[2] Different [KPI]s can be stored in the same file to reduce disk expense                                                         #
#   |[3] Naming convention of [KPI] data files: [<chr.>yyyymmdd<any extensions>]; while the file extensions impacts the input functions #
#   |[4] [keyvar] must exist in both [InfDat] and [KPI] data files (can be more than one) to facilitate the table joining               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKPICfg   :   The dataset that stores the full configuration of the KPI. It MUST contain below fields:                            #
#   |               [C_KPI_ID        ] : The ID of the KPI to be retrieved from the various data files.                                 #
#   |               [N_LIB_PATH_SEQ  ] : The sequence of paths to search for the KPI data file in the same library alias                #
#   |               [C_KPI_FILE_TYPE ] : The types of data files that indicates the method for this function to import data             #
#   |                                    [RAM     ] Try to load the data frame from RAM in current R session                            #
#   |                                    [HDFS    ] Try to import as HDFStore file                                                      #
#   |                                    [SAS     ] Try to import via [pyreadstat.read_sas7bdat]                                        #
#   |               [DF_NAME         ] : For some cases, such as [C_KPI_FILE_TYPE=R] there should be such an additional field           #
#   |                                     indicating the name of data.frame stored in the data file (i.e. container) for loading        #
#   |                                    Default: [None] i.e. no need for such field when [C_KPI_FILE_TYPE=SAS]                         #
#   |               [C_KPI_FILE_NAME ] : The names of data files for identification of file existence in all available paths            #
#   |               [C_LIB_PATH      ] : The absolute paths to store the KPI data (excl. file name). Program will conduct translation   #
#   |               [--> IMPORTANT  <--] Program will translate several columns in below way as per requested by [fTrans], see local    #
#   |                                     variable [trans_var].                                                                         #
#   |                                    [1] [fTrans] is NOT provided: assume that the value in this field is a valid file path         #
#   |                                    [2] [fTrans] is provided a named list or vector: Translate the special strings in accordance   #
#   |                                          as data file names. in such case, names of the provided parameter are treated as strings #
#   |                                          to be replaced; while the values of the provided parameter are treated as variables in   #
#   |                                          the parent environment and are [get]ed for translation, e.g.:                            #
#   |                                        [1] ['&c_date.' = 'G_d_curr'  ] Current reporting/data date in SAS syntax [&c_date.] to be #
#   |                                              translated by the value of Python variable [G_d_curr] in the parent frame            #
#   |InfDat     :   The dataset that stores the descriptive information at certain level (Acct level or Cust level).                    #
#   |               Default: [None]                                                                                                     #
#   |keyvar     :   The vector of Key field names during the merge. This requires that the same Key fields exist in both data.          #
#   |               [IMPORTANT] All attributes of [keyvar] are retained from [InfDat] if provided.                                      #
#   |               Default: [None]                                                                                                     #
#   |SetAsBase  :   The merging method indicating which of above data is set as the base during the merge.                              #
#   |               [I] Use "Inf" data as the base to left join the "KPI" data.                                                         #
#   |               [K] Use "KPI" data as the base to left join the "Inf" data.                                                         #
#   |               [B] Use either data as the base to inner join the other, meaning "both".                                            #
#   |               [F] Use either data as the base to full join the other, meaning "full".                                             #
#   |                Above parameters are case insensitive, while the default one is set as [I].                                        #
#   |KeepInfCol :   Whether to keep the columns from [InfDat] if they also exist in KPI data frames                                     #
#   |               [False           ]  <Default> Use those in KPI data frames as output                                                #
#   |               [True            ]            Keep those retained from [InfDat] as output                                           #
#   |fTrans     :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process    #
#   |               Default: [None]                                                                                                     #
#   |fTrans_opt :   Additional options for value translation on [fTrans], see document for [omniPy.AdvOp.apply_MapVal]                  #
#   |               [{}              ]  <Default> Use default options in [apply_MapVal]                                                 #
#   |               [<dict>          ]            Use alternative options as provided by a list, see documents of [apply_MapVal]        #
#   |fImp_opt   :   List of options during the data file import for different engines; each element of it is a separate list, too       #
#   |               Valid names of the option lists are set in the field [inKPICfg$C_KPI_FILE_TYPE]                                     #
#   |               [SAS             ]  <Default> Options for [pyreadstat.read_sas7bdat]                                                #
#   |                                             [encoding = 'GB2312'  ]  <Default> Read SAS data in this encoding                     #
#   |               [<dict>          ]            Other dicts for different engines, such as [R:{}] and [HDFS:{}]                       #
#   |               [<col. name>     ]            Column name in <inKPICfg> that stores the options as a literal string that can be     #
#   |                                              parsed as a <dict>                                                                   #
#   |_parallel  :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but many be slow for small ones #
#   |               [True            ]  <Default> Use multiple CPU cores to load the data files in parallel                             #
#   |               [False           ]            Load the data files sequentially                                                      #
#   |cores      :   Number of system cores to read the data files in parallel                                                           #
#   |               Default: [4]                                                                                                        #
#   |fDebug     :   The switch of Debug Mode. Valid values are [False] or [True].                                                       #
#   |               Default: [False]                                                                                                    #
#   |miss_skip  :   Whether to skip loading the files which are requested but missing in all provided paths                             #
#   |               [True            ]  <Default> Skip missing files, but issue a message to inform the user                            #
#   |               [False           ]            Abort the process if any of the requested files do not exist                          #
#   |miss_files :   Name of the key in the output [dict] to store the debug data frame with missing file paths and names                #
#   |               [G_miss_files    ]  <Default> If any data files are missing, please check this [key] to see the details             #
#   |               [chr string      ]            User defined [key] of the output result that stores the debug information             #
#   |err_cols   :   Name of the key in the output [dict] to store the debug data frame with error column information                    #
#   |               [G_err_cols      ]  <Default> If any columns are invalidated, please check this [key] to see the details            #
#   |               [chr string      ]            User defined [key] of the output result that stores the debug information             #
#   |outDTfmt   :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                    #
#   |               [ <dict>         ]  <Default> See the function definition as the default argument of usage                          #
#   |dup_KPIs   :   Name of the key in the output [dict] to store the debug data frame with duplicated [C_KPI_SHORTNAME]                #
#   |               [G_dup_kpiname   ]  <Default> If any duplication is found, please check this [key] to see the details               #
#   |               [chr string      ]            User defined [key] of the output result that stores the debug information             #
#   |AggrBy     :   The list/tuple of field names that are to be used as the classes to aggregate the source data.                      #
#   |               [IMPORTANT] This list of columns are NOT affected by [keyvar] during aggregation.                                   #
#   |               [<keyvar>        ]  <Default> The same as the list of [keyvar]                                                      #
#   |values_fn  :   The same parameter as passed into function [pandas.DataFrame.pivot_table] to summarize the column [A_KPI_VAL]       #
#   |               [np.sum          ]  <Default> Sum the values of input records of any KPI                                            #
#   |               [<function>      ]            Function to be applied, as an object instead of a character string                    #
#   |kw_DataIO  :   Arguments to instantiate <DataIO>                                                                                   #
#   |               [ empty-<dict>   ] <Default> See the function definition as the default argument of usage                           #
#   |kw         :   The additional arguments for [pandas.DataFrame.pivot_table]                                                         #
#   |               [IMPORTANT] Do not use these args: [index], [columns] and [aggfunc] as they are encapsulated in this function       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>     :   A dictionary that contains below keys:                                                                              #
#   |               [data            ] [pd.DataFrame] that stores the result with columns including [available KPIs] and the pivoting   #
#   |                                   [ID]s determined as:                                                                            #
#   |                                  [1] If [InfDat] is not provided, we only use [AggrBy] as [ID] during pivoting                    #
#   |                                  [2] If [InfDat] is provided:                                                                     #
#   |                                      [1] If [AggrBy] has the same values as [keyvar], we add to [AggrBy] by all other columns     #
#   |                                           than [keyvar] in [InfDat] as [ID]                                                       #
#   |                                      [2] Otherwise we follow the rule when [InfDat] is not provided                               #
#   |               [ <dup_KPIs>     ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the paths to the #
#   |                                   data files that are required but missing                                                        #
#   |               [ <miss_files>   ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the paths to the #
#   |                                   data files that are required but missing                                                        #
#   |               [ <err_cols>     ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the column names #
#   |                                   as well as the data files in which they are located, which cannot be concatenated due to        #
#   |                                   different [dtypes]                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210311        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210317        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace [pandas.DataFrame.pivot_table] with [pandas.DataFrame.GroupBy.agg + .unstack] to uplift the efficiency          #
#   |      |[2] Remove the [column type unification] step as it will bomb the RAM capacity on relatively large data                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210323        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Correct the process for [values_fn] and [fill_value] to make them fully compatible with the syntax in [pandas]          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210324        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Reuse the function [pandas.DataFrame.pivot_table] as the generalization for [values_fn] is complete, so that the rest   #
#   |      |     arguments in [pivot_table] can be utilized during the call of the function                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210503        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the usage of [\] as new-row-expansion with the officially recommended way [(multi-line-expr.)], see PEP-8       #
#   |      |[2] Fixed a bug which keeps the rows that only exists in [InfDat] from being output                                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210529        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [omniPy.AdvDB.parseDatName] as standardization     #
#   |      |[2] Introduce an argument [outDTfmt] aligning above change, to bridge the mapping from [fTrans] to the date series          #
#   |      |[3] Correct the part of frame lookup when assigning values to global variables for user request                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210605        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Change the output into a [dict] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240102        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the low level APIs of data retrieval with <DataIO> to unify the processes                                       #
#   |      |[2] Accept <fImp_opt> to be a column name in <inKPICfg>, to differ the args by source files                                 #
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
#   |   |sys, os, pandas, numpy, collections, warnings, typing                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_SetKPItoInf                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Parameter buffer
    if inKPICfg is None: raise ValueError('['+LfuncName+']'+'[inKPICfg] is not provided!')
    if InfDat is not None:
        if not keyvar:
            raise ValueError('['+LfuncName+']'+'[keyvar] is not provided for mapping to [InfDat]!')
        if not isinstance(keyvar, Iterable):
            raise TypeError('['+LfuncName+']'+'[keyvar] should be [Iterable]!')
        if isinstance(keyvar, str):
            keyvar = [keyvar.upper()]
        else:
            keyvar = [ v.upper() for v in keyvar ]
    SetAsBase = SetAsBase.upper()
    if SetAsBase not in ['I','K','B','F']:
        raise ValueError('['+LfuncName+']'+'[SetAsBase] should be any among [I, K, B, F]!')
    if not isinstance(KeepInfCol, bool): KeepInfCol = False
    if fTrans_opt is None: fTrans_opt = {}
    if not isinstance(_parallel, bool): _parallel = False
    if _parallel:
        if not cores: cores = 4
    if not isinstance(fDebug, bool): fDebug = False
    if not isinstance(miss_skip, bool): miss_skip = True
    if (not miss_files) | (not isinstance(miss_files, str)): miss_files = 'G_miss_files'
    if (not err_cols) | (not isinstance(err_cols, str)): err_cols = 'G_err_cols'
    if not dup_KPIs: dup_KPIs = 'G_dup_kpiname'
    if not AggrBy: AggrBy = keyvar
    if isinstance(AggrBy, str):
        AggrBy = [AggrBy.upper()]
    else:
        AggrBy = [ v.upper() for v in AggrBy ]
    if not values_fn: values_fn = np.sum
    if not AggrBy:
        raise ValueError('['+LfuncName+']'+'[AggrBy] is not provided for pivoting!')

    #050. Local environment
    outDict = {
        'data' : None
        ,dup_KPIs : None
        ,miss_files : None
        ,err_cols : None
    }
    #Quote: (#361) https://stackoverflow.com/questions/20625582/how-to-deal-with-settingwithcopywarning-in-pandas
    #Quote: https://www.dataquest.io/blog/settingwithcopywarning/
    #pd.options.mode.chained_assignment = None
    #calc_var = [ 'C_KPI_ID', 'A_KPI_VAL', 'D_TABLE' ]
    trans_var = [ 'C_KPI_FILE_NAME', 'C_KPI_FULL_PATH', 'C_KPI_SHORTNAME' ]
    if 'C_KPI_BIZNAME' in inKPICfg.columns: trans_var.append('C_KPI_BIZNAME')
    comb_func = {
        'I' : 'left'
        ,'K' : 'right'
        ,'B' : 'inner'
        ,'F' : 'outer'
    }
    if isinstance(values_fn, str) | callable(values_fn):
        #How to summarize the values
        dict_agg = { 'A_KPI_VAL' : values_fn }
    else:
        #Presume the input is a dict, see official document of [pandas.core.groupby.DataFrameGroupBy.aggregate]
        dict_agg = values_fn

    #099. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'Debug mode...')
        print('['+LfuncName+']'+'Parameters are listed as below:')
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        getvar = sys._getframe().f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print('['+LfuncName+']'+'[{0}]=[{1}]'.format(v,locals().get(v)))

    #100. Translate the configurations once required
    #110. Define the full path of data files
    KPICfg = inKPICfg.copy(deep=True).assign(
        C_KPI_FULL_PATH = inKPICfg.apply( lambda x: os.path.join(x['C_LIB_PATH'], x['C_KPI_FILE_NAME']), axis = 1 )
    )

    #150. Map any dynamic values in the data file paths
    #[ASSUMPTION]:
    #[1] [dates=None] The variables of date values for translation have been defined in the frames at lower call stacks
    #[2] [inRAM=False] All requested data files are on harddisk, rather than in RAM of current session
    #[3] [chkExist=False] We do not verify the data file existence here, and leave the verification to below steps
    #[4] The output data frame of below function has the same index as its input, given [dates=None]
    parse_kpicfg = parseDatName(
        datPtn = KPICfg[trans_var]
        ,parseCol = None
        ,dates = None
        ,outDTfmt = outDTfmt
        ,inRAM = False
        ,chkExist = False
        ,dict_map = fTrans
        ,**fTrans_opt
    )

    #190. Assign values for the necessary columns
    KPICfg[trans_var] = parse_kpicfg[[ v + '.Parsed' for v in trans_var ]]

    #200. Verify the duplication and abort the process if the same [C_KPI_SHORTNAME] is assigned to different [C_KPI_ID]
    #This is because we have to pivot the table by [C_KPI_SHORTNAME], hence it cannot be duplicated.
    #210. Extract the unique pairs of KPI ID and KPI Names for later pivoting and labeling where applicable
    KPI_names = KPICfg[['C_KPI_ID', 'C_KPI_SHORTNAME', 'C_KPI_BIZNAME']].drop_duplicates()

    #220. Count the frequency of each [C_KPI_SHORTNAME]
    #Quote: https://pandas.pydata.org/docs/reference/api/pandas.core.groupby.DataFrameGroupBy.aggregate.html
    qc_KPI_name = (
        KPI_names.groupby('C_KPI_SHORTNAME')
        .agg( cnt = pd.NamedAgg( column = 'C_KPI_ID' , aggfunc = 'count' ) )
        .reset_index()
        .loc[lambda x: x['cnt'] > 1]
    )

    #250. Extract the [C_KPI_SHORTNAME] with more than 1 [C_KPI_ID] for issuing error messages
    #[~] represents the negation of the following boolean series
    qc_KPI_id = (
        KPICfg[['C_KPI_ID', 'C_KPI_SHORTNAME']]
        .merge( qc_KPI_name , on = 'C_KPI_SHORTNAME' , how = 'inner' , suffixes = ( '' , '.y' ) )
        .loc[:, lambda x: ~x.columns.str.endswith('.y')]
    )

    #290. Abort the process if any duplication is found
    if len(qc_KPI_id):
        #001. Print messages
        warn('['+LfuncName+']'+'Below [C_KPI_SHORTNAME] are applied to more than 1 columns!')
        print(qc_KPI_id)

        #500. Output a global data frame storing the information of the duplicated [C_KPI_SHORTNAME]
        # sys._getframe(1).f_globals.update({ dup_KPIs : qc_KPI_id })
        outDict.update({ dup_KPIs : qc_KPI_id })

        #999. Abort the process
        warn('['+LfuncName+']'+'Check the data frame ['+dup_KPIs+'] in the output result for duplications!')
        return(outDict)

    #300. Set together all the requested KPI data files WITHOUT [InfDat]
    #[1] We do not provide [InfDat] here, for we will simplify the process by merging the information table later.
    #[2] [keyvar], [SetAsBase] and [KeepInfCol] are also of no use due to above reason.
    #[3] [fTrans] and [fTrans_opt] are of no use as we have done the translation in the mapping table at earlier steps.
    KPI_set = DBuse_SetKPItoInf(
        KPICfg
        ,InfDat = None
        ,keyvar = None
        ,SetAsBase = SetAsBase
        ,KeepInfCol = KeepInfCol
        ,fTrans = None
        ,fTrans_opt = {}
        ,fImp_opt = fImp_opt
        ,_parallel = _parallel
        ,cores = cores
        ,fDebug = fDebug
        ,miss_skip = miss_skip
        ,miss_files = miss_files
        ,err_cols = err_cols
        ,outDTfmt = outDTfmt
        ,kw_DataIO = kw_DataIO
    )

    #309. Return None if above function does not generate output
    if KPI_set.get('data') is None:
        outDict.update(KPI_set)
        return(outDict)

    #500. Merge the KPI data to [InfDat] if it is provided
    if InfDat is not None:
        #001. Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Combine [InfDat] with the loaded KPI data...')

        #100. Mark the same columns in both data for further [drop] process
        df_with_inf = (
            InfDat.rename( str.upper, axis = 1 )
            .merge( KPI_set.get('data') , on = keyvar , how = comb_func[SetAsBase] , suffixes=('._inf_', '._kpi_') )
        )

        #300. Determine to drop any fields from above data as per indicated
        sfx_drop = '._kpi_' if KeepInfCol else '._inf_'
        df_with_inf = df_with_inf.loc[:, ~df_with_inf.columns.str.endswith(sfx_drop)].copy(deep=True)

        #500. Rename the rest of the additioinal columns
        sfx_rename = '._inf_' if KeepInfCol else '._kpi_'
        col_rename = df_with_inf.columns[df_with_inf.columns.str.endswith(sfx_rename)].to_list()
        if col_rename:
            bat_rename = { v:v[:-len(sfx_rename)] for v in col_rename }
            df_with_inf.rename(columns=bat_rename, inplace = True)

        #700. Retrieve the names to be used for pivoting
        df_with_inf = (
            df_with_inf.copy(deep=True)
            .merge( KPI_names , on = 'C_KPI_ID' , how = 'left' , suffixes=('', '._nam_') )
            .loc[:, lambda x: ~x.columns.str.endswith('._nam_')]
        )
    else:
        #001. Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Process KPI data with no input of [InfDat]...')

        #100. Retrieve the names to be used for pivoting
        df_with_inf = (
            KPI_set.get('data')
            .merge( KPI_names , on = ['C_KPI_ID'] , how = 'left' , suffixes=('', '._nam_') )
            .loc[:, lambda x: ~x.columns.str.endswith('._nam_')]
        )

    #700. Aggregate the data as per user request
    #710. Determine the columns to act as [ID] during pivoting
    #Quote: https://www.geeksforgeeks.org/python-check-if-two-lists-are-identical/
    #Quote: https://stackoverflow.com/questions/7828867/how-to-efficiently-compare-two-unordered-lists-not-sets-in-python
    if ( InfDat is not None ) & ( Counter(AggrBy) == Counter(keyvar) ):
        list_inf = set([ v.upper() for v in InfDat.columns.to_list() ])
        list_agg = set(AggrBy)
        aggr_fnl = list(list_inf | list_agg)

        #Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Keep all columns that have the same names in [InfDat] as [ID] during pivoting...')
    else:
        aggr_fnl = AggrBy

        #Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Keep [AggrBy] as [ID] during pivoting...')

    #719. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'Columns used as [ID] during pivoting are listed as below:')
        print('['+LfuncName+']'+'[aggr_fnl]:')
        print(aggr_fnl)

    #730. Conduct pivoting
    #There could be some [keyvar] without any record on any of the KPIs, we will retrieve them separately at below steps.
    #Quote: https://stackoverflow.com/questions/55404617/faster-alternatives-to-pandas-pivot-table
    tbl_out = (
        df_with_inf.loc[~pd.isnull(df_with_inf['C_KPI_ID'])]
        .pivot_table(
            index = aggr_fnl
            , columns = 'C_KPI_SHORTNAME'
            , aggfunc = dict_agg
            , **kw
        )
        .reset_index(col_level = -1)
    )

    #740. Determine whether to flatten the column index, as indicated by the levels of the requested measures
    #When there are only 2 levels from [unstack], the level-0 represents the column measured by request; hence we can remove it.
    tbl_collvl = len(tbl_out.columns.names)
    rst_flatten = tbl_collvl == 2

    #750. Unify the [dtype] for KPIs
    kpi_dtypes = tbl_out.dtypes
    kpi_unify = df_with_inf.loc[~pd.isnull(df_with_inf['C_KPI_ID'])]['C_KPI_SHORTNAME'].drop_duplicates().to_list()
    kpi_unify = pd.Index([ c for c in tbl_out.columns if c[-1] in kpi_unify and kpi_dtypes[c] != 'float64' ])
    if len(kpi_unify):
        tbl_out[kpi_unify] = tbl_out[kpi_unify].astype(np.float64)

    #770. Retrieve those [aggr_fnl] without any KPI record but only existing in [InfDat]
    chk_miss_aggr = df_with_inf.loc[pd.isnull(df_with_inf['C_KPI_ID'])].copy(deep=True)
    if len(chk_miss_aggr):
        #001. Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Correcting KPI columns for those in [InfDat] but without KPI records...')

        #100. Retrieve all KPIs for cartesian join to [aggr_fnl]
        aggr_kpis = (
            df_with_inf.loc[~pd.isnull(df_with_inf['C_KPI_ID'])]['C_KPI_SHORTNAME']
            .drop_duplicates().reset_index().drop(columns=['index'])
        )

        #300. Retrieve unique combination of [aggr_fnl] from [df_with_inf]
        #There could be missing values in [aggr_fnl], hence they cannot conform a MultiIndex during merge.
        #[reset_index] will ensure the output is a [pd.DataFrame] instead of a [pd.Series] when the input has only one column
        aggr_keys = chk_miss_aggr[aggr_fnl].drop_duplicates().reset_index().drop(columns=['index'])

        #500. Create a dummy data for all possible combinations of [KPI]s and [aggr_fnl], in terms of Cartesian Join
        #[IMPORTANT] Below process requires [pandas >= 1.2]
        #Quote: (#67) https://stackoverflow.com/questions/53699012/performant-cartesian-product-cross-join-with-pandas
        tbl_cartesian = aggr_keys.merge(aggr_kpis, how = 'cross')

        #550. Ensure all [values] referred in the pivot table request have the initial value as [NaN]
        tbl_cartesian[list(dict_agg.keys())] = np.nan

        #600. Ensure there is no [NaN] value in the aggregation keys
        #Since [pd.where] modifies the values in condition of [False], we negate the filter here
        #[IMPORTANT] We DO NOT use [inplace=True] argument here, for it causes a warning message from [pandas]
        tbl_cartesian[aggr_fnl] = tbl_cartesian[aggr_fnl].where(~pd.isnull(tbl_cartesian[aggr_fnl]), 'PseudoNA')

        #700. Tabulation as if it is the combined data frame at earlier step
        #sys._getframe(1).f_globals.update({'chkpvt':tbl_cartesian})
        tbl_mis = (
            tbl_cartesian
            .pivot_table(
                index = aggr_fnl
                , columns = 'C_KPI_SHORTNAME'
                , aggfunc = dict_agg
                , **kw
            )
            .reset_index(col_level = -1)
        )

        #780. Reset the pseudo [NaN] values in the aggregation keys to there original [NaN] values
        #781. Correct form of column index for the modifier
        if isinstance(tbl_mis.columns, pd.MultiIndex):
            #Quote: https://stackoverflow.com/questions/16730339/python-add-item-to-the-tuple
            resetIdx = [ tuple('' for i in range(len(tbl_mis.columns.names)-1)) + (j,) for j in aggr_fnl ]
        else:
            resetIdx = aggr_fnl

        #789. Reset values
        #[IMPORTANT] We DO NOT use [inplace=True] argument here, for it causes a warning message from [pandas]
        tbl_mis[resetIdx] = tbl_mis[resetIdx].where(lambda x: x!='PseudoNA', np.nan)

        #800. Unify the [dtype] for KPIs
        mis_dtypes = tbl_mis.dtypes
        mis_unify = pd.Index([ c for c in tbl_mis.columns if c[-1] in aggr_kpis and mis_dtypes[c] != 'float64' ])
        if len(mis_unify):
            tbl_mis[mis_unify] = tbl_mis[mis_unify].astype(np.float64)

        #900. Combine the data together
        tbl_out = pd.concat([tbl_out, tbl_mis], ignore_index = True).copy(deep=True)

    #790. Add labels for the columns pivoted from KPI Names if requested
    #There is no attribute for columns in [pandas], hence we pass this step
    if 'C_KPI_BIZNAME' in inKPICfg.columns:
        if fDebug:
            print('['+LfuncName+']'+'No function to add Business Name to column names as attribute.')

    #910. Reset the table index if there is only one measure to output
    if rst_flatten:
        #Quote: (#65) https://stackoverflow.com/questions/22233488/pandas-drop-a-level-from-a-multi-level-column-index
        tbl_out.columns = tbl_out.columns.droplevel(0)
        #Quote: https://stackoverflow.com/questions/19851005/rename-pandas-dataframe-index
        #Below attribute represents the [box] text in a pivot table, which is quite annoying here; hence we remove it.
        tbl_out.columns.names = [None]

    #999. Return the table
    outDict.update(
        {
            'data' : tbl_out
            ,miss_files : KPI_set.get(miss_files)
            ,err_cols : KPI_set.get(err_cols)
        }
    )
    return(outDict)
#End DBuse_MrgKPItoInf

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys, os
    import pandas as pd
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import loadSASdat, DBuse_MrgKPItoInf

    #100. Set parameters
    G_d_curr = '20160310'
    G_m_curr = G_d_curr[:6]
    acctinfo, meta_acct = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\acctinfo.sas7bdat', encoding = 'GB2312')
    CFG_KPI, meta_kpi = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_kpi.sas7bdat', encoding = 'GB2312')
    CFG_LIB, meta_lib = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_lib.sas7bdat', encoding = 'GB2312')

    #190. Combine the configuration tables
    mask_kpi = CFG_KPI.apply(lambda x: x['D_BGN'] <= pd.to_datetime(G_d_curr) <= x['D_END'], axis = 1)
    mask_lib = CFG_LIB.apply(lambda x: x['D_BGN'] <= pd.to_datetime(G_d_curr) <= x['D_END'], axis = 1)
    KPICfg_all = CFG_KPI[mask_kpi].merge( CFG_LIB[mask_lib], on = 'C_KPI_DAT_LIB', suffixes = ('', '.y') )
    KPICfg_all = KPICfg_all.loc[:, ~KPICfg_all.columns.str.endswith('.y')]
    KPICfg_all['C_KPI_FILE_TYPE'] = 'SAS'
    KPICfg_all['C_KPI_FILE_NAME'] = KPICfg_all['C_KPI_DAT_NAME'] + '.sas7bdat'

    #150. Prepare to translate the date strings in the file names
    #Similar to FORMAT Procedure in SAS, we map the special strings with what we need in current session
    #The function will attempt to resolve the values of below list as if they are Python variables
    fmt_Trans = {
        '&c_date.' : 'G_d_curr'
        ,'&L_curdate.' : 'G_d_curr'
        ,'&L_curMon.' : 'G_m_curr'
        ,'&L_prevMon.' : 'G_m_curr'
    }
    #See syntax of function [omniPy.AdvOp.apply_MapVal]
    fmt_opt = {
        'PRX' : False
        ,'fPartial' : True
        ,'full_match' : False
        ,'ignore_case' : True
    }

    #300. Read the KPI data in sequential mode
    KPI_rst = DBuse_MrgKPItoInf(
        KPICfg_all
        ,InfDat = acctinfo
        ,keyvar = ['nc_cifno','nc_acct_no']
        ,SetAsBase = 'k'
        ,KeepInfCol = False
        ,fTrans = fmt_Trans
        ,fTrans_opt = fmt_opt
        ,fImp_opt = {
            'SAS' : {
                'encoding' : 'GB18030'
            }
        }
        ,_parallel = False
        ,cores = 4
        ,fDebug = False
        ,miss_skip = True
        ,miss_files = 'G_miss_files'
        ,err_cols = 'G_err_cols'
        ,outDTfmt = {
            'L_d_curr' : '%Y%m%d'
            ,'L_m_curr' : '%Y%m'
        }
        ,dup_KPIs = 'G_dup_kpiname'
        #Provide the same value for [AggrBy] as [keyvar], or just [AggrBy=None] to keep all columns from [InfDat]
        ,AggrBy = 'nc_cifno'
        ,values_fn = np.sum
        #Below parameters represent the reset arguments for [pd.DataFrame.pivot_table]
        ,fill_value = 0
    )

    #400. Read the KPI data in parallel mode
    KPI_rst2 = DBuse_MrgKPItoInf(
        KPICfg_all
        ,InfDat = acctinfo
        ,keyvar = ['nc_cifno','nc_acct_no']
        ,SetAsBase = 'k'
        ,KeepInfCol = False
        ,fTrans = fmt_Trans
        ,fTrans_opt = fmt_opt
        ,fImp_opt = {
            'SAS' : {
                'encoding' : 'GB18030'
            }
        }
        ,_parallel = True
        ,cores = 4
        ,fDebug = False
        ,miss_skip = True
        ,miss_files = 'G_miss_files'
        ,err_cols = 'G_err_cols'
        ,outDTfmt = {
            'L_d_curr' : '%Y%m%d'
            ,'L_m_curr' : '%Y%m'
        }
        ,dup_KPIs = 'G_dup_kpiname'
        #Provide the same value for [AggrBy] as [keyvar], or just [AggrBy=None] to keep all columns from [InfDat]
        ,AggrBy = 'nc_cifno'
        ,values_fn = sum
        #Below parameters represent the reset arguments for [pd.DataFrame.pivot_table]
        ,fill_value = 0.0
    )

    #600. Test if there is no [InfDat]
    KPI_rst3 = DBuse_MrgKPItoInf(
        KPICfg_all
        ,InfDat = None
        ,keyvar = 'nc_cifno'
        ,SetAsBase = 'k'
        ,KeepInfCol = False
        ,fTrans = fmt_Trans
        ,fTrans_opt = fmt_opt
        ,fImp_opt = {
            'SAS' : {
                'encoding' : 'GB18030'
            }
        }
        ,_parallel = True
        ,cores = 4
        ,fDebug = False
        ,miss_skip = False
        ,miss_files = 'G_miss_files'
        ,err_cols = 'G_err_cols'
        ,outDTfmt = {
            'L_d_curr' : '%Y%m%d'
            ,'L_m_curr' : '%Y%m'
        }
        ,dup_KPIs = 'G_dup_kpiname'
        #Provide the same value for [AggrBy] as [keyvar], or just [AggrBy=None] to keep all columns from [InfDat]
        ,AggrBy = None
    )
#-Notes- -End-
'''
