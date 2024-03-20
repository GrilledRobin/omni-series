#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys
import pandas as pd
import numpy as np
import datetime as dt
from collections.abc import Iterable
from pathos.threading import ThreadPool
#Quote: https://izziswift.com/python-process-pool-non-daemonic/
#[billiard] cannot accomplish the job by executing eternally...
#from billiard.pool import Pool
#[ProcessPoolExecutor] does not support [imap] method
#from concurrent.futures import ProcessPoolExecutor as Pool
from warnings import warn
from typing import Optional, Union, Any
from omniPy.AdvOp import debug_comp_datcols, modifyDict
from omniPy.Dates import asDates
from omniPy.AdvDB import DBuse_SetKPItoInf, DBuse_MrgKPItoInf, parseDatName, DataIO, validateDMCol

#For annotations in function arguments, see [PEP 604 -- Allow writing union types as X | Y] for [Python >= 3.10]
def DBuse_GetTimeSeriesForKpi(
    inKPICfg : pd.DataFrame
    ,InfDatCfg : dict = {
        'InfDat' : None
        ,'_paths' : None
        ,'DatType' : 'RAM'
        ,'DF_NAME' : None
        ,'_trans' : {}
        ,'_trans_opt' : {}
        ,'_imp_opt' : {
            'SAS' : {
                'encoding' : 'GB18030'
            }
        }
        ,'_func' : None
        ,'_func_opt' : None
    }
    ,SingleInf : bool = False
    ,dnDates : Union[Iterable, dt.date] = None
    ,ColRecDate : str = 'D_RecDate'
    ,MergeProc : str = 'SET'
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
    ,_parallel : bool = False
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
    ,AggrBy : Optional[Iterable] = None
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
#   | in a periodical way, and combine the output as one single data frame                                                              #
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
#   |[5] This function splits the data processing by the provided period of dates, to avoid the drastic increment of RAM consumption    #
#   |     during [join] and [pivot] processes                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKPICfg    :   The dataset that stores the full configuration of the KPI. It MUST contain below fields:                           #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |C_KPI_ID        |No         | KPI ID used as part of keys for mapping and aggregation                             #
#   |                |C_KPI_FILE_TYPE |No         | File type to determine the API for data I/O process, see <DataIO>                   #
#   |                |N_LIB_PATH_SEQ  |No         | Priority to determine the candidate paths when loading and writing data files, the  #
#   |                |                |           |  lesser the higher. E.g. 1 represents the primary path, 2 indicates the backup      #
#   |                |                |           |  location of historical data files                                                  #
#   |                |C_LIB_PATH      |Yes        | Candidate path to store the KPI data file. Used together with <N_LIB_PATH_SEQ>      #
#   |                |                |           | It can be empty for data type <RAM>                                                 #
#   |                |C_KPI_FILE_NAME |No         | Data file name, should be the same for all candidate paths                          #
#   |                |DF_NAME         |Yes        | For some cases, such as [inDatType=HDFS] there should be such an additional field   #
#   |                |                |           |  indicating the name of data.frame stored in the data file (i.e. container)         #
#   |                |                |           | It is required if [C_KPI_FILE_TYPE] on any record is similar to [HDFS]              #
#   |                |options         |Yes        | Literal string representation of <dict> representing the options used for the API   #
#   |                |                |           |  when loading and writing data files, see <DataIO>                                  #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                [--> IMPORTANT  <--] Program will translate several columns in below way as per requested by [fTrans], see local   #
#   |                                      variable [trans_var].                                                                        #
#   |                                     [1] [fTrans] is NOT provided: assume that the value in this field is a valid file path        #
#   |                                     [2] [fTrans] is provided a named list or vector: Translate the special strings in accordance  #
#   |                                           as data file names. in such case, names of the provided parameter are treated as strings#
#   |                                           to be replaced; while the values of the provided parameter are treated as variables in  #
#   |                                           the parent environment and are [get]ed for translation, e.g.:                           #
#   |                                         [1] ['&c_date.' = 'G_d_curr'  ] Current reporting/data date in SAS syntax [&c_date.] to be#
#   |                                               translated by the value of Python variable [G_d_curr] in the parent frame           #
#   |InfDatCfg   :   The dict that stores the full configuration of the Information Table. It MUST contain below keys:                  #
#   |                [InfDat          ] : Character string as the name of Information Table, or its [prefix] if [SingleInf=F]           #
#   |                                     [None    ] <Default> No Information Table is required                                         #
#   |                [_paths          ] : Character vector of the candidate paths to search for the [InfDat]; the position of the       #
#   |                                      character strings represents the priority for searching, i.e. if the same data file exists   #
#   |                                      in several candidate paths, the first one will be used for import                            #
#   |                                     [None    ] <Default> No Information Table is required                                         #
#   |                [DatType         ] : Character string as the type of Information Table for this function to import                 #
#   |                                     [RAM     ] <Default> Directly use it as an existing [pd.DataFrame] in current session         #
#   |                                     [HDFS    ]           Try to import as [.hdf] file                                             #
#   |                                     [SAS     ]           Try to import via [pyreadstat.read_sas7bdat]                             #
#   |                [DF_NAME         ] : For some cases, such as [DatType=HDFS] there should be such an additional field indicating the#
#   |                                      name of data frame stored in the data file (i.e. container) for loading                      #
#   |                                     [None    ] <Default> No need if [DatType] indicates the data is an object instead of a        #
#   |                                                           container with many objects                                             #
#   |                [_trans          ] : Dict to translate strings within the configuration to resolve the actual data                 #
#   |                                      file name for process                                                                        #
#   |                                     [<preset>] <Default> Same as the universal parameter [fTrans]                                 #
#   |                                     [<dict>  ]           A dict for date value translation                                        #
#   |                [_trans_opt      ] : Additional options for value translation on [_trans], see document for                        #
#   |                                      [AdvOp.apply_MapVal]                                                                         #
#   |                                     [<preset>] <Default> Same as the universal parameter [fTrans_opt]                             #
#   |                                     [<dict>  ]           Use alternative options as provided by a dict, see documents of          #
#   |                                                           [apply_MapVal]                                                          #
#   |                [_imp_opt        ] : Dict of options during the data file import for different engines; each element of it is a    #
#   |                                      separate dict, too. See the definition for the similar parameter [fImp_opt]                  #
#   |                                     [SAS     ] <Default> Options for [pyreadstat.read_sas7bdat]                                   #
#   |                                     [<dict>  ]           A dict for different engines, such as [SAS={}] and [HDFS={}]             #
#   |                [_func           ] : Function as pre-process before merging to KPI data; its first argument MUST take a            #
#   |                                      data.frame-like object                                                                       #
#   |                                     [None    ] <Default> No pre-process is applied to the Information Table                       #
#   |                                     [<func>  ]           An object of function to call                                            #
#   |                [_func_opt       ] : Additional arguments to [_func], provided as a dict                                           #
#   |                                     [None    ] <Default> No additional argument is required for [_func]                           #
#   |                                     [<dict>  ]           A dict acting as additional arguments to [_func]                         #
#   |SingleInf   :   Whether it is only requested to use one Information Table to merge to all KPI data                                 #
#   |                [False           ]  <Default> Information Table is also a time series input with snapshots on all provided dates   #
#   |                [True            ]            There is only one Information Table to merge to all KPI data                         #
#   |dnDates     :   [Iterable] of values that can be converted for date series process; if a single value is provided, it will be      #
#   |                 converted to a [list] with single date value                                                                      #
#   |                [None            ]  <Default> Abort the program as there is no request for data extraction                         #
#   |ColRecDate  :   Name of the column as [Date of Record] in the output data that indicates on which date the data record is obtained #
#   |                [D_RecDate       ]  <Default> Please take care of the character cases of this column name when using it            #
#   |                [<chr. string>   ]            Only a single character string is accepted; the first is taken if a vector is        #
#   |                                               provided with a warning message                                                     #
#   |MergeProc   :   In which type to merge the data                                                                                    #
#   |                [SET             ]  <Default> Conduct the [DBuse_SetKPItoInf] process for all provided dates                       #
#   |                [MERGE           ]            Conduct the [DBuse_MrgKPItoInf] process for all provided dates                       #
#   |keyvar      :   The vector of Key field names during the merge. This requires that the same Key fields exist in both data.         #
#   |                [IMPORTANT] All attributes of [keyvar] are retained from [InfDat] if provided.                                     #
#   |                Default: [None]                                                                                                    #
#   |SetAsBase   :   The merging method indicating which of above data is set as the base during the merge.                             #
#   |                [I] Use "Inf" data as the base to left join the "KPI" data.                                                        #
#   |                [K] Use "KPI" data as the base to left join the "Inf" data.                                                        #
#   |                [B] Use either data as the base to inner join the other, meaning "both".                                           #
#   |                [F] Use either data as the base to full join the other, meaning "full".                                            #
#   |                 Above parameters are case insensitive, while the default one is set as [I].                                       #
#   |KeepInfCol  :   Whether to keep the columns from [InfDat] if they also exist in KPI data frames                                    #
#   |                [False           ]  <Default> Use those in KPI data frames as output                                               #
#   |                [True            ]            Keep those retained from [InfDat] as output                                          #
#   |fTrans      :   Dict to translate strings within the configuration to resolve the actual data file name for process                #
#   |                Default: [None]                                                                                                    #
#   |fTrans_opt  :   Additional options for value translation on [fTrans], see document for [AdvOp.apply_MapVal]                        #
#   |                [{}              ]  <Default> Use default options in [apply_MapVal]                                                #
#   |                [<dict>          ]            Use alternative options as provided by a list, see documents of [apply_MapVal]       #
#   |fImp_opt    :   List of options during the data file import for different engines; each element of it is a separate list, too      #
#   |                Valid names of the option lists are set in the field [inKPICfg$C_KPI_FILE_TYPE]                                    #
#   |                [SAS             ]  <Default> Options for [pyreadstat.read_sas7bdat]                                               #
#   |                                              [encoding = 'GB2312'  ]  <Default> Read SAS data in this encoding                    #
#   |                [<dict>          ]            Other dicts for different engines, such as [R:{}] and [HDFS:{}]                      #
#   |                [<col. name>     ]            Column name in <inKPICfg> that stores the options as a literal string that can be    #
#   |                                               parsed as a <dict>                                                                  #
#   |_parallel   :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but many be slow for small ones#
#   |                [False           ]  <Default> Load the data files sequentially                                                     #
#   |                [True            ]            Use multiple CPU cores to load the data files in parallel. When using this option,   #
#   |                                               please ensure correct environment is passed to <kw_DataIO> for API searching, given #
#   |                                               that RAM is the requested location for search                                       #
#   |cores       :   Number of system cores to read the data files in parallel                                                          #
#   |                Default: [4]                                                                                                       #
#   |fDebug      :   The switch of Debug Mode. Valid values are [False] or [True].                                                      #
#   |                Default: [False]                                                                                                   #
#   |miss_skip   :   Whether to skip loading the files which are requested but missing in all provided paths                            #
#   |                [True            ]  <Default> Skip missing files, but issue a message to inform the user                           #
#   |                [False           ]            Abort the process if any of the requested files do not exist                         #
#   |miss_files  :   Name of the key in the output [dict] to store the debug data frame with missing file paths and names               #
#   |                [G_miss_files    ]  <Default> If any data files are missing, please check this [key] to see the details            #
#   |                [chr string      ]            User defined [key] of the output result that stores the debug information            #
#   |err_cols    :   Name of the key in the output [dict] to store the debug data frame with error column information                   #
#   |                [G_err_cols      ]  <Default> If any columns are invalidated, please check this [key] to see the details           #
#   |                [chr string      ]            User defined [key] of the output result that stores the debug information            #
#   |outDTfmt    :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                   #
#   |                [ <dict>         ]  <Default> See the function definition as the default argument of usage                         #
#   |dup_KPIs    :   Name of the key in the output [dict] to store the debug data frame with duplicated [C_KPI_SHORTNAME]               #
#   |                [G_dup_kpiname   ]  <Default> If any duplication is found, please check this [key] to see the details              #
#   |                [chr string      ]            User defined [key] of the output result that stores the debug information            #
#   |AggrBy      :   The list/tuple of field names that are to be used as the classes to aggregate the source data.                     #
#   |                [IMPORTANT] This list of columns are NOT affected by [keyvar] during aggregation.                                  #
#   |                [<keyvar>        ]  <Default> The same as the list of [keyvar]                                                     #
#   |values_fn   :   The same parameter as passed into function [pandas.DataFrame.pivot_table] to summarize the column [A_KPI_VAL]      #
#   |                [np.sum          ]  <Default> Sum the values of input records of any KPI                                           #
#   |                [<function>      ]            Function to be applied, as an object instead of a character string                   #
#   |kw_DataIO   :   Arguments to instantiate <DataIO>                                                                                  #
#   |                [ empty-<dict>   ] <Default> See the function definition as the default argument of usage                          #
#   |kw          :   The additional arguments for [pandas.DataFrame.pivot_table]                                                        #
#   |                [IMPORTANT] Do not use these args: [index], [columns] and [aggfunc] as they are encapsulated in this function      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   A dictionary that contains below keys:                                                                             #
#   |                [data            ] [pd.DataFrame] that stores the result in terms of [MergeProc]:                                  #
#   |                                   [SET  ] Stores the result with columns including those in the same names as in [InfDat] if it is#
#   |                                            provided with their values determined by [KeepInfCol], as well as all available columns#
#   |                                            in all KPI data files                                                                  #
#   |                                   [MERGE] Stores the result with columns including [available KPIs] and the pivoting [ID]s        #
#   |                                            determined as:                                                                         #
#   |                                           [1] If [InfDat] is not provided, we only use [AggrBy] as [ID] during pivoting           #
#   |                                           [2] If [InfDat] is provided:                                                            #
#   |                                               [1] If [AggrBy] has the same values as [keyvar], we add to [AggrBy] by all other    #
#   |                                                    columns than [keyvar] in [InfDat] as [ID]                                      #
#   |                                               [2] Otherwise we follow the rule when [InfDat] is not provided                      #
#   |                [ <dup_KPIs>     ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the paths to the#
#   |                                    data files that are required but missing                                                       #
#   |                [ <miss_files>   ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the paths to the#
#   |                                    data files that are required but missing                                                       #
#   |                [ <err_cols>     ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the column names#
#   |                                    as well as the data files in which they are located, which cannot be concatenated due to       #
#   |                                    different [dtypes]                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210312        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |      |[2] Standardize the functions to read the source data files. Check the series of functions as [AdvDB.std_read_*]            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210529        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [AdvDB.parseDatName] as standardization            #
#   |      |[2] Introduce an argument [outDTfmt] aligning above change, to bridge the mapping from [fTrans] to the date series          #
#   |      |[3] Correct the part of frame lookup when assigning values to global variables for user request                             #
#   |      |[4] Argument [dnDates] now accepts any value that can be converted by [Dates.asDates]                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210605        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Change the output into a [dict] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220314        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug that always raise error when there are multiple paths provided for [InfDatCfg] and [InfDat] does not exist  #
#   |      |     in any among them                                                                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240102        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the low level APIs of data retrieval with <DataIO> to unify the processes                                       #
#   |      |[2] Accept <fImp_opt> to be a column name in <inKPICfg>, to differ the args by source files                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240112        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when the KPI data is stored in RAM                                                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240209        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce function <validateDMCol> to unify the validation of related columns                                           #
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
#   |   |sys, os, pandas, numpy, datetime, collections, pathos, warnings, typing                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |debug_comp_datcols                                                                                                         #
#   |   |   |modifyDict                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_SetKPItoInf                                                                                                          #
#   |   |   |DBuse_MrgKPItoInf                                                                                                          #
#   |   |   |validateDMCol                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    def h_convStr(vec : Any, func : callable = str.upper):
        if isinstance(vec, str):
            return(func(vec))
        else:
            return(vec)

    if inKPICfg is None: raise ValueError(f'[{LfuncName}][inKPICfg] is not provided!')
    if not isinstance(SingleInf, bool): SingleInf = False
    if not dnDates: raise ValueError(f'[{LfuncName}][dnDates] is not provided!')
    d_Dates = asDates(dnDates)
    if isinstance(d_Dates, Iterable):
        if len(d_Dates) == 0:
            raise ValueError(f'[{LfuncName}][dnDates]:[{str(dnDates)}] should be able to convert to date values!')
        invdates = [ str(dnDates[i]) for i in range(len(dnDates)) if pd.isnull(d_Dates[i]) ]
        if invdates:
            raise ValueError(f'[{LfuncName}]Some values among [dnDates] cannot be converted to dates! {str(invdates)}')
    elif isinstance(d_Dates, dt.date):
        d_Dates = [d_Dates]
    else:
        raise ValueError(f'[{LfuncName}][dnDates]:[{str(dnDates)}] should be able to convert to date values!')
    if not ColRecDate: ColRecDate = 'D_RecDate'
    MergeProc = MergeProc.upper()
    if MergeProc not in (vfyVal := ['SET','MERGE']):
        raise ValueError(f'[{LfuncName}][MergeProc] should be any among {str(vfyVal)}!')
    SetAsBase = SetAsBase.upper()
    if SetAsBase not in (vfyVal := ['I','K','B','F']):
        raise ValueError(f'[{LfuncName}][SetAsBase] should be any among {str(vfyVal)}!')
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
    if not values_fn: values_fn = np.sum
    if InfDatCfg is None: InfDatCfg = {}
    if not isinstance(InfDatCfg, dict):
        raise ValueError(f'[{LfuncName}][InfDatCfg] must be a dict!')
    if InfDatCfg.get('InfDat', None) is not None:
        keyvar = [ h_convStr(v) for v in validateDMCol(keyvar) ]
    AggrBy = [ h_convStr(v) for v in validateDMCol(AggrBy) ]
    if not AggrBy: AggrBy = keyvar
    if MergeProc == 'MERGE':
        if not AggrBy:
            raise ValueError(f'[{LfuncName}][AggrBy] is not provided for pivoting, as [MergeProc]==[{MergeProc}]!')
    if kw is None: kw = {}

    #021. Instantiate the IO operator for data migration
    dataIO = DataIO(**kw_DataIO)

    #050. Local environment
    outDict = {
        'data' : None
        ,dup_KPIs : None
        ,miss_files : None
        ,err_cols : None
    }
    f_ts_errors = False
    #Quote: (#361) https://stackoverflow.com/questions/20625582/how-to-deal-with-settingwithcopywarning-in-pandas
    #Quote: https://www.dataquest.io/blog/settingwithcopywarning/
    #pd.options.mode.chained_assignment = None
    #calc_var = [ 'C_KPI_ID', 'A_KPI_VAL', 'D_TABLE' ]
    n_dates = len(d_Dates)
    trans_var = ['C_KPI_FULL_PATH', 'C_KPI_FILE_NAME', 'C_KPI_SHORTNAME']
    if 'C_KPI_BIZNAME' in inKPICfg.columns: trans_var.append('C_KPI_BIZNAME')
    GTSFK_getFunc = {
        'SET' : DBuse_SetKPItoInf
        ,'MERGE' : DBuse_MrgKPItoInf
    }
    if isinstance(values_fn, str) | callable(values_fn):
        #How to summarize the values
        dict_agg = { 'A_KPI_VAL' : values_fn }
    else:
        #Presume the input is a dict, see official document of [pandas.core.groupby.DataFrameGroupBy.aggregate]
        dict_agg = values_fn

    if isinstance(fImp_opt, dict):
        opt_ram = fImp_opt.get('RAM', None)
        if isinstance(opt_ram, dict):
            opt_ram = {
                'exist_Opt' : pd.Series(
                    [ opt_ram for i in range(len(inKPICfg)) ]
                    ,dtype = 'O'
                    ,index = inKPICfg.index
                )
            }
        else:
            opt_ram = {}
    elif fImp_opt in inKPICfg.columns:
        opt_ram = {'exist_Opt' : inKPICfg[fImp_opt]}
    else:
        raise ValueError(
            f'[{LfuncName}]<fImp_opt> must be dict or existing name in <inKPICfg>'
            +f', given <{str(fImp_opt)}> as type <{type(fImp_opt).__name__}>'
        )

    #060. Handle the configuration for Information Tables
    cfg_local = { k:v for k,v in InfDatCfg.items() }
    imp_df = cfg_local.get('DF_NAME', None)
    if len(cfg_local.get('_trans', {})) == 0: cfg_local.update({'_trans':fTrans})
    if len(cfg_local.get('_trans_opt', {})) == 0: cfg_local.update({'_trans_opt':fTrans_opt})
    DatType = cfg_local.get('DatType').upper()
    _paths = cfg_local.get('_paths')
    if isinstance(_paths, str):
        _paths = [_paths]
    elif isinstance(_paths, Iterable):
        _paths = list(_paths)
    else:
        if DatType not in ['RAM']:
            raise ValueError(f'[{LfuncName}][GTSFK_getInfDat][_paths] should be [str], or [Iterable] of the previous!')

    #065. Combine the file path
    if _paths:
        InfDat_path = [ os.path.join(v, cfg_local.get('InfDat')) for v in _paths ]
    else:
        InfDat_path = [cfg_local.get('InfDat')]

    #099. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Debug mode...')
        print(f'[{LfuncName}]Parameters are listed as below:')
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        getvar = sys._getframe().f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print('['+LfuncName+']'+'[{0}]=[{1}]'.format(v,locals().get(v)))

    #300. Define helper functions
    #310. Prepare to import the Information Table
    def GTSFK_getInfDat(i):
        #100. Set parameters
        InfDat = InfDat_exist.at[i, 'datPtn.Parsed']

        #500. Prepare the function to apply to the process list
        dataIO.add(DatType)
        _opt_inf = {
            'infile' : InfDat
            #For unification purpose, some APIs would omit below arguments
            ,'key' : imp_df
        }
        modifyDict(_opt_inf, cfg_local.get('_imp_opt',{}).get(DatType,{}), inplace = True)

        #509. Debug mode
        if fDebug:
            print(f'[{LfuncName}]Loading from file: <{InfDat}>')

        #700. Call functions to import data from current path
        imp_data = dataIO[DatType].pull(**_opt_inf)

        #750. Conduct pre-process as requested and upcase the field names for all imported data, to facilitate the later [bind_rows]
        #Ensure the field used at below steps are all referred to in upper case
        if callable(cfg_local.get('_func')):
            imp_data = (
                cfg_local.get('_func')( imp_data, **cfg_local.get('_func_opt',{}) )
                .rename( h_convStr, axis = 1 )
            )

        #800. Assign additional attributes to the data frame for column class check at later steps
        imp_dict = {
            'data' : imp_data
            ,'DF_NAME' : imp_df
            ,'path.InfDat' : InfDat
        }

        #999. Return the result
        return(imp_dict)

    #350. Prepare to retrieve both the Information Table and KPI data files by period in parallel
    def GTSFK_parallel(i):
        #100. Set parameters
        KPICfg = kpiDat_exist.loc[kpiDat_exist['dates'] == d_Dates[i]]

        #500. Retrieve the Information Table if requested
        if InfDatCfg.get('InfDat') is not None:
            if SingleInf:
                InfDat = GTSFK_uni_Inf
            else:
                InfDat = GTSFK_getInfDat(i)
        else:
            InfDat = {}

        #700. Conduct the merge process for current date
        #710. Prepare the primary parameter dict for the function [DBuse_SetKPItoInf]
        #[1] [fTrans] and [fTrans_opt] are of no use as we have done the translation in the mapping table at earlier steps.
        curr_args = {
            'InfDat' : InfDat.get('data')
            ,'keyvar' : keyvar
            ,'SetAsBase' : SetAsBase
            ,'KeepInfCol' : KeepInfCol
            ,'fTrans' : None
            ,'fTrans_opt' : {}
            ,'fImp_opt' : fImp_opt
            ,'outDTfmt' : outDTfmt
            ,'_parallel' : _parallel
            ,'cores' : cores
            ,'fDebug' : fDebug
            ,'miss_skip' : miss_skip
            ,'miss_files' : miss_files
            ,'err_cols' : err_cols
            ,'kw_DataIO' : kw_DataIO
        }

        #730. Append those parameters for [DBuse_MrgKPItoInf] if any
        if MergeProc in ['MERGE']:
            curr_args.update({
                'dup_KPIs' : dup_KPIs
                ,'AggrBy' : AggrBy
                ,'values_fn' : values_fn
            })
            if len(kw):
                curr_args.update(kw)

        #739. Debug mode
        if fDebug:
            print(f'[{LfuncName}]Arguments for current iteration [i={str(i)}][curr_args]:')
            print(curr_args)

        #790. Call the function as per request
        KPI_set = GTSFK_getFunc[MergeProc]( KPICfg , **curr_args )
        kpidat = KPI_set.get('data')

        #791. Create new column to mark the retrieval of KPI data
        if isinstance(kpidat.columns, pd.MultiIndex):
            ColRecIdx = tuple([ '' for i in range(len(kpidat.columns.names)-1) ] + [ColRecDate])
        else:
            ColRecIdx = ColRecDate
        #[IMPORTANT] We DO NOT convert the date flag into [pd.Timestamp] as always.
        if kpidat is not None:
            if len(kpidat):
                kpidat[ColRecIdx] = asDates(pd.Series([ d_Dates[i] for j in range(len(kpidat)) ], dtype = 'object'))
            else:
                kpidat[ColRecIdx] = pd.Series([], dtype = 'object')

        #900. Assign additional attributes to the data frame for column class check at later steps
        imp_dict = {
            'name' : d_Dates[i].strftime('%Y%m%d')
            ,'data' : kpidat
            ,'DF_NAME.InfDat' : InfDat.get('DF_NAME')
            ,'path.InfDat' : InfDat.get('path.InfDat')
            ,'miss_files' : KPI_set.get('miss_files')
            ,'err_cols' : KPI_set.get('err_cols')
        }
        if MergeProc in ['MERGE']:
            imp_dict.update({
                'dup_KPIs' : KPI_set.get('dup_KPIs')
            })

        #999. Return the result
        return(imp_dict)

    #400. Verify the existence of the Information Tables that are actually required
    if InfDatCfg.get('InfDat') is not None:
        #050. Determine the options to search for RAM objects if any
        if DatType == 'RAM':
            opt_inf_ram = cfg_local.get('_imp_opt').get('RAM')
            if isinstance(opt_inf_ram, dict):
                opt_inf_ram = {
                    'exist_Opt' : [ opt_inf_ram for i in range(len(InfDat_path)) ]
                }
            else:
                opt_inf_ram = {}
        else:
            opt_inf_ram = {}

        #100. Parse the provided naming pattern
        parse_infDat = parseDatName(
            datPtn = InfDat_path
            ,parseCol = None
            ,dates = (None if SingleInf else d_Dates)
            ,outDTfmt = outDTfmt
            ,inRAM = (DatType=='RAM')
            ,chkExist = True
            ,dict_map = cfg_local.get('_trans', {})
            ,**opt_inf_ram
            ,**cfg_local.get('_trans_opt', {})
        )

        #500. Verify the existence of the data files and only use the first one among the existing files
        #510. Find the first existing data file per group
        #Below statement is the same as [col_exist='datPtn.chkExist'], except that it demonstrates the usage of [.values]
        col_exist = 'datPtn.chkExist'
        if SingleInf:
            InfDat_exist = (
                parse_infDat[parse_infDat[col_exist].eq(True)]
                #[head(1)] works even if there is no observation that can be extracted
                .head(1)
                .reset_index(drop = True)
            )

            #Find the missing data files
            InfDat_miss = parse_infDat[~parse_infDat['datPtn'].isin(InfDat_exist['datPtn'])]
        else:
            InfDat_exist = (
                parse_infDat[parse_infDat[col_exist].eq(True)]
                .groupby('dates', as_index = False)
                .head(1)
                .reset_index(drop = True)
            )

            #Find the missing data files
            InfDat_miss = parse_infDat[~parse_infDat['dates'].isin(InfDat_exist['dates'])]

        #559. Abort if there is any one not found as Information Table is not skippable once requested
        if len(InfDat_miss):
            #001. Print messages
            print(f'[{LfuncName}]Below files of Information Table are requested but do not exist in the parsed path(s).')
            print(InfDat_miss[['datPtn', 'datPtn.Parsed']])

            #500. Output a global data frame storing the information of the missing files
            # sys._getframe(1).f_globals.update({ miss_files : InfDat_miss })
            outDict.update({ miss_files : InfDat_miss })

            #999. Abort the process
            warn(f'[{LfuncName}]Non-existence of Information Table cannot be skipped!')
            warn(f'[{LfuncName}]Check the data frame [{miss_files}] in the output result for missing files!')
            return(outDict)

        #900. Only read the source of Information Table once if requested, to minimize work load
        if SingleInf:
            #[IMPORTANT] Below result is a dict. Please extract its corresponding parts where necessary.
            GTSFK_uni_Inf = GTSFK_getInfDat(0)

    #500. Verify the existence of the KPI data files that are actually required
    #501. Define the full path of data files
    KPICfg = inKPICfg.assign(
        C_KPI_FULL_PATH = inKPICfg.apply( lambda x: os.path.join(x['C_LIB_PATH'], x['C_KPI_FILE_NAME']), axis = 1 )
    )

    #510. Parse the provided naming pattern
    #[ASSUMPTION]:
    #[1] Separately find the full path of KPI data file by differing the file type as input
    #[2] Keep all columns for determination of uniqueness
    parse_kpiDat = (
        parseDatName(
            datPtn = KPICfg
            ,parseCol = trans_var
            ,dates = d_Dates
            ,outDTfmt = outDTfmt
            ,inRAM = (
                KPICfg
                .assign(**{
                    'C_KPI_FULL_PATH' : lambda x: x['C_KPI_FILE_TYPE'].eq('RAM')
                })
                .loc[:, trans_var]
                .astype('O')
                .map(lambda x: x if isinstance(x, bool) else False)
                .astype(bool)
            )
            ,chkExist = True
            ,dict_map = fTrans
            ,**opt_ram
            ,**fTrans_opt
        )
    )

    #520. Set the useful columns to their parsed values for further data retrieval
    parse_kpiDat[trans_var] = parse_kpiDat[[ v + '.Parsed' for v in trans_var ]]

    #550. Verify the existence of the data files and only use the first one among the existing files for each KPI on each date
    #[ASSUMPTION]:
    #[1] Use [N_LIB_PATH_SEQ] to identify the first valid path in which the KPI data file on current date is located
    kpiDat_exist = (
        parse_kpiDat
        [parse_kpiDat['C_KPI_FULL_PATH.chkExist']]
        .sort_values(['C_KPI_ID', 'dates', 'N_LIB_PATH_SEQ'])
        .groupby(['C_KPI_ID', 'dates'], as_index = False)
        .head(1)
        .reset_index(drop = True)
    )

    #559. Abort the process if there is no data file found anywhere
    if len(kpiDat_exist) == 0:
        #500. Output a global data frame storing the information of the missing files
        # sys._getframe(1).f_globals.update({ miss_files : parse_kpiDat })
        outDict.update({ miss_files : parse_kpiDat })

        #999. Abort the process
        warn(f'[{LfuncName}]There is no KPI data file found in any of the parsed paths!')
        warn(f'[{LfuncName}]Check the data frame [{miss_files}] in the output result for missing files!')
        return(outDict)

    #580. Find the missing data files
    kpiDat_miss = (
        parse_kpiDat
        .merge(kpiDat_exist[['C_KPI_ID', 'dates']], how = 'left', indicator = True)
        .loc[lambda x: x['_merge'] == 'left_only']
    )

    #589. Abort the process if it is requested not to skip the missing KPI data files
    if len(kpiDat_miss):
        #001. Print messages
        print(f'[{LfuncName}]Below KPI data files are requested but do not exist in the parsed path(s).')
        print(kpiDat_miss[['C_KPI_ID', 'dates', 'C_KPI_FULL_PATH']])

        #500. Output a global data frame storing the information of the missing files
        # sys._getframe(1).f_globals.update({ miss_files : kpiDat_miss })
        outDict.update({ miss_files : kpiDat_miss })

        #999. Abort the process if no missing file is accepted
        if not miss_skip:
            warn(f'[{LfuncName}]User requests not to skip the missing files!')
            warn(f'[{LfuncName}]Check the data frame [{miss_files}] in the output result for missing files!')
            return(outDict)

    #700. Loop all provided date series to retrieve KPI data
    #591. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Import data files in '+('Parallel' if _parallel else 'Sequential')+' mode...')
    #[IMPOTANT] There could be fields/columns in the same name but not the same types in different data files,
    #            but we throw the errors at the step [pandas.concat] to ask user to correct the input data,
    #            instead of guessing the correct types here, for it takes quite a lot of unnecessary effort.
    if _parallel:
        #100. Set the cores to be used and instantiate a pool
        mychunk = int(np.ceil(n_dates / cores))
        #[IMPORTANT] According to below link, we adopt the method of [Parent: ThreadPool] -> [Child: Pool] for multiprocessing
        #Quote: https://izziswift.com/python-process-pool-non-daemonic/
        #[1] [Pool] does not support spawning childs in recursion for good reason
        #[2] [Pool]s from other packages will not function as per test
        #[3] [pathos] functions well as it does not require user-defined requirements to be setup for each [child]
        mypool = ThreadPool(cores)

        #900. Read the files and store the imported data frames into a list
        #Quote: https://stackoverflow.com/questions/15881055/combine-output-multiprocessing-python
        GTSFK_import = list(mypool.imap( GTSFK_parallel, range(n_dates), chunksize = mychunk ))

        #990. Complete the Pool stage
        #Quote: https://pathos.readthedocs.io/en/latest/pathos.html#module-pathos.multiprocessing
        mypool.clear()
        mypool.close()
        mypool.join()
        #How to close the multiprocessing pool
        #Quote: (#5) https://stackoverflow.com/questions/44587669/
        mypool.terminate()
    else:
        #900. Read the files sequentially
        #We do not directly combine the data, for there may be columns with different dtypes.
        GTSFK_import = list(map( GTSFK_parallel, range(n_dates) ))

    #750. Check the list of imported data on the [dtypes] of columns
    GTSFK_chk_cls = debug_comp_datcols(**{ d['name']:d['data'] for d in GTSFK_import })

    #759. Abort the program if any inconsistency is found on columns of data frames among the [requested dates]
    #We do not directly abort the program, for we need more error information for debug at once
    if len(GTSFK_chk_cls):
        # sys._getframe(1).f_globals.update({ err_cols : GTSFK_chk_cls })
        outDict.update({ err_cols : GTSFK_chk_cls })
        warn(f'[{LfuncName}]Some columns cannot be bound due to different dtypes between different dates!')
        warn(f'[{LfuncName}]Check data frame [{err_cols}] in the output result for these columns!')
        f_ts_errors = True

    #790. Abort the program for certain conditions
    #791. Abort if any duplications are found on [C_KPI_SHORTNAME]
    if MergeProc in ['MERGE']:
        if not np.all([ (d.get(dup_KPIs) is None) for d in GTSFK_import ]):
            #001. Print messages
            warn(f'[{LfuncName}]Below [C_KPI_SHORTNAME] are applied to more than 1 columns!')
            qc_KPI_id = (
                pd.concat([ d.get(dup_KPIs) for d in GTSFK_import ], ignore_index = True)
                .drop_duplicates()
                .reset_index(drop = True)
            )
            print(qc_KPI_id)

            #500. Output a global data frame storing the information of the duplicated [C_KPI_SHORTNAME]
            # sys._getframe(1).f_globals.update({ dup_KPIs : qc_KPI_id })
            outDict.update({ dup_KPIs : qc_KPI_id })

            #999. Abort the process
            warn(f'[{LfuncName}]Check the data frame [{dup_KPIs}] in the output result for duplications!')
            f_ts_errors = True

    #797. Abort if any columns cannot be concatenated among the KPI data on [each date]
    if not np.all([ (d.get(err_cols) is None) for d in GTSFK_import ]):
        #001. Print messages
        qc_err_cols = pd.concat(
            [ d.get(err_cols).assign(name_error = d.get('name')) for d in GTSFK_import if d.get(err_cols) is not None ]
            ,ignore_index = True
        )
        print(qc_err_cols)

        #500. Output a global data frame storing the information of the column inconsistency
        # sys._getframe(1).f_globals.update({ dup_KPIs : qc_KPI_id })
        outDict.update({ err_cols : pd.concat([qc_err_cols, outDict.get(err_cols)], ignore_index = True) })

        #999. Abort the process
        warn(f'[{LfuncName}]Some columns cannot be bound due to different dtypes between the data sources on the same date(s)!')
        warn(f'[{LfuncName}]Check data frame [{err_cols}] in the output result for these columns!')
        f_ts_errors = True

    #799. Abort if the flag of errors is True
    if f_ts_errors: return(outDict)

    #800. Combine the data
    #[IMPORTANT] We cannot remove [GTSFK_combine.columns.names] here, as there could be another table merged to it matching columns
    GTSFK_combine = pd.concat([ d['data'] for d in GTSFK_import ], ignore_index = True)

    #850. Fill the [NaN] values with the requested ones if there are still any during the concatenation of data frames
    if MergeProc in ['MERGE']:
        #100. Retrieve the KPI name list from the input configuration
        cols_kpi = inKPICfg['C_KPI_SHORTNAME'].drop_duplicates().to_list()

        #190. Prepare a MultiIndex if it is NOT indicated to output a one-level pivot table
        #Since there is only one column [C_KPI_SHORTNAME] unstacked by the pivoting, there are only 2 levels of the MultiIndex,
        # with the last level as [aggr_fnl]
        if isinstance(GTSFK_combine.columns, pd.MultiIndex):
            cols_kpi = pd.Index([ c for c in GTSFK_combine.columns if c[-1] in cols_kpi ])
        else:
            cols_kpi = pd.Index([ c for c in GTSFK_combine.columns if c in cols_kpi ])

        #300. Verify which among these KPIs have [Null] values
        #310. Retrieve the KPI columns in the combined data
        GTSFK_kpicol = GTSFK_combine.columns[GTSFK_combine.columns.isin(cols_kpi)]

        #350. Identify the rows and columns with [Null] values from within the combined data
        GTSFK_nanrow, GTSFK_nancol = np.where(GTSFK_combine[GTSFK_kpicol].isnull())

        #399. Directly return if there is no [Null] values to fill
        #We cannot use [if not GTSFK_nanrow] as it is a [np.ndarray]; Python will raise error for ambiguity.
        if not len(GTSFK_nanrow):
            #800. Remove the clogging text in the position of [box] as MS EXCEL Pivot Table
            #Quote: https://stackoverflow.com/questions/19851005/rename-pandas-dataframe-index
            #Below attribute represents the [box] text in a pivot table, which is quite annoying here; hence we remove it.
            if len(GTSFK_combine.columns.names):
                GTSFK_combine.columns.names = [None for i in range(len(GTSFK_combine.columns.names))]

            #999. Return the result
            outDict.update({ 'data' : GTSFK_combine })
            return(outDict)

        #500. Create a dummy data for all possible combinations of [KPI]s and [aggr_fnl], in terms of Cartesian Join
        #510. Retrieve the [AggrBy] columns for the rows with [Null] values, to conform [row] index for cartesian join
        #We regard all columns EXCEPT the [KPI] names as what we need for now.
        filldat_row = GTSFK_combine.loc[GTSFK_nanrow, ~GTSFK_combine.columns.isin(cols_kpi)].reset_index().drop(columns=['index'])

        #515. Only keep the last level of the column index to tally the columns from the input data
        if isinstance(GTSFK_combine.columns, pd.MultiIndex):
            filldat_row.columns = pd.Index([ c[-1] for c in filldat_row.columns ])

        #530. Retrieve the [KPI] names for the rows with [Null] values, to conform [column] index for cartesian join
        #We create a [set] of KPI names for dedup, then convert it into [list] for data frame creation upon syntax requirement
        if isinstance(GTSFK_combine.columns, pd.MultiIndex):
            filldat_col = pd.DataFrame({ 'C_KPI_SHORTNAME':list({ c[-1] for c in GTSFK_kpicol[GTSFK_nancol] }) })
        else:
            filldat_col = pd.DataFrame({ 'C_KPI_SHORTNAME':list(set(GTSFK_kpicol[GTSFK_nancol])) })

        #570. Cartesian Join
        #[IMPORTANT] Below process requires [pandas >= 1.2]
        #Quote: (#67) https://stackoverflow.com/questions/53699012/performant-cartesian-product-cross-join-with-pandas
        filldat = filldat_row.merge(filldat_col, how = 'cross')

        #580. Ensure all [values] referred in the pivot table request have the initial value as [NaN]
        filldat[list(dict_agg.keys())] = np.nan

        #590. Tabulation as if it were the combined data frame at earlier step
        filldat_tab = (
            filldat
            .pivot_table(
                index = filldat_row.columns.to_list()
                , columns = 'C_KPI_SHORTNAME'
                , aggfunc = dict_agg
                , **kw
            )
            .reset_index(col_level = -1)
        )

        #600. Unify the [dtype] for KPIs
        fill_dtypes = filldat_tab.dtypes
        fill_unify = pd.Index([ c for c in filldat_tab.columns if c[-1] in filldat_col and fill_dtypes[c] != 'float64' ])
        if len(fill_unify):
            filldat_tab[fill_unify] = filldat_tab[fill_unify].astype(np.float64)

        #700. Determine whether to flatten the column index, as indicated by the levels of the requested measures
        #When there are only 2 levels from [unstack], the level-0 represents the column measured by request; hence we can remove it.
        filldat_collvl = len(filldat_tab.columns.names)
        rst_flatten = filldat_collvl == 2

        #800. Reset the table index if there is only one measure to output
        if rst_flatten:
            #Quote: (#65) https://stackoverflow.com/questions/22233488/pandas-drop-a-level-from-a-multi-level-column-index
            filldat_tab.columns = filldat_tab.columns.droplevel(0)
            #Quote: https://stackoverflow.com/questions/19851005/rename-pandas-dataframe-index
            #Below attribute represents the [box] text in a pivot table, which is quite annoying here; hence we remove it.
            filldat_tab.columns.names = [None]

        #900. Fill the [NaN] values with the requested values
        GTSFK_combine = GTSFK_combine.fillna(filldat_tab)

    #870. Remove the clogging text in the position of [box] as MS EXCEL Pivot Table
    #Quote: https://stackoverflow.com/questions/19851005/rename-pandas-dataframe-index
    #Below attribute represents the [box] text in a pivot table, which is quite annoying here; hence we remove it.
    if len(GTSFK_combine.columns.names):
        GTSFK_combine.columns.names = [None for i in range(len(GTSFK_combine.columns.names))]

    #999. Return the table
    outDict.update({ 'data' : GTSFK_combine })
    return(outDict)
#End DBuse_GetTimeSeriesForKpi

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys, os
    import pandas as pd
    import numpy as np
    import datetime as dt
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import exec_file, modifyDict
    from omniPy.AdvDB import loadSASdat, DBuse_GetTimeSeriesForKpi
    from omniPy.Dates import UserCalendar, asDates

    #010. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Set parameters
    G_d_bgn = '20160301'
    G_d_curr = '20160310'
    G_m_curr = G_d_curr[:6]
    acctinfo, meta_acct = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\acctinfo.sas7bdat', encoding = 'GB2312')
    CFG_KPI, meta_kpi = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_kpi.sas7bdat', encoding = 'GB2312')
    CFG_LIB, meta_lib = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_lib.sas7bdat', encoding = 'GB2312')

    #190. Combine the configuration tables
    mask_kpi = CFG_KPI.apply(lambda x: x['D_BGN'] <= asDates(G_d_curr) <= x['D_END'], axis = 1)
    mask_lib = CFG_LIB.apply(lambda x: x['D_BGN'] <= asDates(G_d_curr) <= x['D_END'], axis = 1)
    KPICfg_all = (
        CFG_KPI[mask_kpi]
        .merge( CFG_LIB[mask_lib], on = 'C_KPI_DAT_LIB', suffixes = ('', '.y') )
        .loc[:, lambda x: ~x.columns.str.endswith('.y')]
        .assign(**{
            'C_KPI_FILE_TYPE' : 'SAS'
            ,'C_KPI_FILE_NAME' : lambda x: x['C_KPI_DAT_NAME'].add('.sas7bdat')
            # Content of below column must be a literal string as required
            ,'options' : lambda x: [str({'encoding' : 'GB18030'}) for i in range(len(x))]
        })
    )

    #150. Prepare the date list
    cln = UserCalendar(
        G_d_bgn
        , G_d_curr
        , clnBgn = '20160101'
        , countrycode = getOption['CountryCode']
        , CalendarAdj = getOption['ClndrAdj']
    )
    #Change the output values into formatted character strings (this format is required by [DBuse_GetTimeSeriesForKpi])
    cln.fmtDateOut = '%Y%m%d'

    #200. Prepare a demo function to process the [InfDat] for each KPI on each date
    def func_inf(df, a = 1, b = 2):
        print('a=['+str(a)+']; b=['+str(b)+']')
        return(df)

    #300. Read the KPI data in sequential mode
    #310. Prepare the modification upon the default arguments with current business requirements
    args_GTSFK = modifyDict(
        getOption['args.def.GTSFK']
        ,{
            'inKPICfg' : KPICfg_all
            ,'InfDatCfg' : {
                'InfDat' : 'acctinfo'
                ,'_paths' : None
                ,'DatType' : 'RAM'
                #Below is a demo, please modify the function where necessary
                ,'_func' : func_inf
                #Below option is used for the function defined above
                ,'_func_opt' : {
                    'a' : 3
                    ,'b' : 4
                }
            }
            ,'fImp_opt' : 'options'
            ,'SingleInf' : True
            ,'dnDates' : cln.d_AllWD
            ,'MergeProc' : 'MERGE'
            ,'keyvar' : ['nc_cifno','nc_acct_no']
            ,'SetAsBase' : 'i'
            #Process in parallel for small number of small data files are MUCH SLOWER than sequential mode
            ,'_parallel' : False
            ,'fDebug' : False
            ,'values_fn' : np.sum
        }
    )

    #350. Test the timing
    time_bgn = dt.datetime.now()
    KPI_ts = DBuse_GetTimeSeriesForKpi(**args_GTSFK)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)

    #600. Test if there is no [InfDat]
    args_GTSFK2 = modifyDict(
        getOption['args.def.GTSFK']
        ,{
            'inKPICfg' : KPICfg_all
            ,'dnDates' : cln.d_AllWD
            ,'MergeProc' : 'MERGE'
            ,'keyvar' : ['nc_cifno','nc_acct_no']
            ,'SetAsBase' : 'k'
            ,'_parallel' : False
            ,'fDebug' : False
            ,'values_fn' : np.sum
        }
    )
    KPI_ts2 = DBuse_GetTimeSeriesForKpi(**args_GTSFK2)
#-Notes- -End-
'''
