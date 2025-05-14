#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys, ast
import pandas as pd
import numpy as np
from pathos.multiprocessing import ProcessPool as Pool
#Quote: https://izziswift.com/python-process-pool-non-daemonic/
#[billiard] cannot accomplish the job by executing eternally...
#from billiard.pool import Pool
#[ProcessPoolExecutor] does not support [imap] method
#from concurrent.futures import ProcessPoolExecutor as Pool
from warnings import warn
from collections.abc import Iterable
from typing import Optional, Any
from omniPy.AdvOp import debug_comp_datcols, modifyDict
from omniPy.AdvDB import parseDatName, DataIO, validateDMCol

#For annotations in function arguments, see [PEP 604 -- Allow writing union types as X | Y] for [Python >= 3.10]
def DBuse_SetKPItoInf(
    inKPICfg : pd.DataFrame
    ,InfDat : Optional[pd.DataFrame] = None
    ,keyvar : Optional[Iterable] = None
    ,SetAsBase : str = 'I'
    ,KeepInfCol : bool = False
    ,fTrans : Optional[dict] = {}
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
    ,kw_DataIO : dict = {}
) -> dict:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to merge the KPI data to the given (descriptive) information data, in terms of different merging methods #
#   | and set all the datasets together for reporting purpose.                                                                          #
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
#   |InfDat      :   The dataset that stores the descriptive information at certain level (Acct level or Cust level).                   #
#   |                Default: [None]                                                                                                    #
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
#   |fTrans      :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process   #
#   |                Default: [None]                                                                                                    #
#   |fTrans_opt  :   Additional options for value translation on [fTrans], see document for [AdvOp.apply_MapVal]                        #
#   |                [{}              ]  <Default> Use default options in [apply_MapVal]                                                #
#   |                [<dict>          ]            Use alternative options as provided by a list, see documents of [apply_MapVal]       #
#   |fImp_opt    :   List of options during the data file import for different engines; each element of it is a separate list, too      #
#   |                Valid names of the option lists are set in the field [inKPICfg$C_KPI_FILE_TYPE]                                    #
#   |                [SAS             ]  <Default> Options for [pyreadstat.read_sas7bdat]                                               #
#   |                                              [encoding = 'GB18030' ]  <Default> Read SAS data in this encoding                    #
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
#   |kw_DataIO   :   Arguments to instantiate <DataIO>                                                                                  #
#   |                [ empty-<dict>   ] <Default> See the function definition as the default argument of usage                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   A dictionary that contains below keys:                                                                             #
#   |                [data            ] [pd.DataFrame] that contains the combined result                                                #
#   |                [ <miss_files>   ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the paths to the#
#   |                                    data files that are required but missing                                                       #
#   |                [ <err_cols>     ] [None] if all KPI data are successfully loaded, or [pd.DataFrame] that contains the column names#
#   |                                    as well as the data files in which they are located, which cannot be concatenated due to       #
#   |                                    different [dtypes]                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210306        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210503        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
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
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210605        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Change the output into a [dict] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220820        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fix a bug that causes duplication when there are more than 1 KPI stored in the same data file during retrieval          #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250514        | Version | 3.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when multiple KPIs are stored in one data file                                                              #
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
#   |   |sys, os, ast, pandas, numpy, pathos, warnings, collections, typing                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |debug_comp_datcols                                                                                                         #
#   |   |   |modifyDict                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
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

    if not isinstance(inKPICfg, pd.DataFrame):
        raise ValueError(f'[{LfuncName}][inKPICfg] must be pd.DataFrame!')
    if InfDat is not None:
        keyvar = [ h_convStr(v) for v in validateDMCol(keyvar) ]
        if not keyvar:
            raise ValueError(f'[{LfuncName}][keyvar] is not provided for mapping to [InfDat]!')
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

    #021. Instantiate the IO operator for data migration
    dataIO = DataIO(**kw_DataIO)

    #050. Local environment
    outDict = {
        'data' : None
        ,miss_files : None
        ,err_cols : None
    }
    #Quote: (#361) https://stackoverflow.com/questions/20625582/how-to-deal-with-settingwithcopywarning-in-pandas
    #Quote: https://www.dataquest.io/blog/settingwithcopywarning/
    #pd.options.mode.chained_assignment = None
    #calc_var = [ 'C_KPI_ID', 'A_KPI_VAL', 'D_TABLE' ]
    trans_var = ['C_KPI_FULL_PATH', 'C_KPI_FILE_NAME']
    params_funcs = ['DF_NAME']
    opt_is_col = False
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
    elif inKPICfg.columns.isin(fImp_opt_col := validateDMCol(fImp_opt)).any():
        opt_is_col = True
        params_funcs += fImp_opt_col
        opt_ram = {'exist_Opt' : inKPICfg[fImp_opt_col[0]]}
    else:
        raise ValueError(
            f'[{LfuncName}]<fImp_opt> must be dict or existing name in <inKPICfg>'
            +f', given <{str(fImp_opt)}> as type <{type(fImp_opt).__name__}>'
        )
    comb_func = {
        'I' : 'left'
        ,'K' : 'right'
        ,'B' : 'inner'
        ,'F' : 'outer'
    }

    #099. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Debug mode...')
        print(f'[{LfuncName}]Parameters are listed as below:')
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        getvar = sys._getframe().f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print(f'[{LfuncName}]'+'[{0}]=[{1}]'.format(v,str(locals().get(v))))

    #100. Translate the configurations once required
    #110. Define the full path of data files
    KPICfg = inKPICfg.assign(
        C_KPI_FULL_PATH = inKPICfg.apply( lambda x: os.path.join(x['C_LIB_PATH'], x['C_KPI_FILE_NAME']), axis = 1 )
    )

    #150. Map any dynamic values in the data file paths
    #[ASSUMPTION]:
    #[1] [dates=None] The variables of date values for translation have been defined in the frames at lower call stacks
    #[2] Separately find the full path of KPI data file by differing the file type as input
    #[3] The output data frame of below function has the same index as its input, given [dates=None]
    parse_kpicfg = (
        parseDatName(
            datPtn = KPICfg[trans_var]
            ,parseCol = None
            ,dates = None
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

    #190. Assign values for the necessary columns
    KPICfg[trans_var] = parse_kpicfg[[ v + '.Parsed' for v in trans_var ]]
    KPICfg['f_exist'] = parse_kpicfg['C_KPI_FULL_PATH.chkExist']

    #500. Import the KPI data files
    #510. Search in all paths of the libraries for the data files and identify the first occurrences respectively for later import
    cols = [ 'C_KPI_ID', 'N_LIB_PATH_SEQ', 'C_KPI_FILE_TYPE' ] + trans_var + params_funcs
    #We have to eliminate the columns that are NOT existing in the configuration table, before we subset it.
    #Quote: https://codedestine.com/python-set-union-example/
    cols = list( set(cols) & set(KPICfg.columns.values) )
    files_exist = (
        KPICfg.loc[KPICfg['f_exist']][cols]
        .sort_values(['C_KPI_ID', 'N_LIB_PATH_SEQ'])
        .groupby('C_KPI_ID', as_index = False).head(1)
    )

    #519. Abort the process if there is no available data file found
    if len(files_exist)==0:
        #500. Output a global data frame storing the information of the missing files
        # sys._getframe(1).f_globals.update({ miss_files : KPICfg })
        outDict.update({ miss_files : KPICfg })

        #999. Abort the process if no missing file is accepted
        if not miss_skip:
            warn(f'[{LfuncName}]User requests not to skip the missing files!')
            warn(f'[{LfuncName}]Check the data frame [{miss_files}] in the output result for missing files!')
        else:
            print(f'[{LfuncName}]No data file is available! None result is returned!')
            print( KPICfg[['C_KPI_ID', 'C_KPI_FULL_PATH']] )

        return(outDict)

    #530. Identify the files that are requested but do not exist
    #Except those existing ones from the requested files, the rest will be those do not exist in any provided paths
    files_chk_miss = (
        KPICfg['C_KPI_FILE_NAME']
        .drop_duplicates()
        .loc[lambda x: ~x.isin(files_exist['C_KPI_FILE_NAME'])]
    )

    #535. Print the names of all missing files in the log and create a global data frame for debug
    if len(files_chk_miss):
        #001. Print messages
        print(f'[{LfuncName}]Below files are requested but do not exist.')
        print(files_chk_miss)

        #500. Output a global data frame storing the information of the missing files
        # sys._getframe(1).f_globals.update({ miss_files : KPICfg.merge( files_chk_miss ) })
        outDict.update({ miss_files : KPICfg.merge( files_chk_miss ) })

        #999. Abort the process if no missing file is accepted
        if not miss_skip:
            warn(f'[{LfuncName}]User requests not to skip the missing files!')
            warn(f'[{LfuncName}]Check the data frame [{miss_files}] in the output result for missing files!')
            return(outDict)

    #540. Define helper functions to convert dict into hashable and then convert it back
    #[ASSUMPTION]
    #[1] There could be <dict> stored inside the column <options> for I/O tool to import the data file
    #[2] We cannot directly sort or deduplicate such column due to TypeError: unhashable type
    #[3] Hence we define the helper functions to convert SIMPLE <dict> into hashable object for sort and dedup
    #    Quote: Baidu/DeepSeek <python如何将dict转换为hashable> and <根据以上解决方案，如何将结果再转换回dict>
    #[4] Above solution is based on SIMPLE <dict>, i.e. there is no unhashable objects stored in the values of that <dict>
    #[5] It should be guarenteed that <options> column only contains SIMPLE <dict> where applicable
    #[6] As a safe solution, we only drop duplicates by necessary columns and only keep the first value of column <options>,
    #     assuming that all the options for different KPIs in the same data file are the same (which it should be); hence below
    #     helper functions are no longer in use
    #[7] These helper functions are still useful in necessary scenarios so we keep them in this source code
    def make_hashable(obj):
        """转换时添加类型标记（字典、列表、集合）"""
        if isinstance(obj, dict):
            return ('__dict__', tuple(sorted((k, make_hashable(v)) for k, v in obj.items())))
        elif isinstance(obj, list):
            return ('__list__', tuple(make_hashable(e) for e in obj))
        elif isinstance(obj, set):
            return ('__set__', frozenset(make_hashable(e) for e in obj))
        else:
            return obj

    def reverse_hashable(obj):
        """根据类型标记恢复原始数据结构"""
        if isinstance(obj, tuple) and len(obj) > 0:
            type_tag, content = obj[0], obj[1]
            if type_tag == '__dict__':
                return {k: reverse_hashable(v) for k, v in content}
            elif type_tag == '__list__':
                return [reverse_hashable(e) for e in content]
            elif type_tag == '__set__':
                return {reverse_hashable(e) for e in content}
            else:
                return [reverse_hashable(e) for e in obj]
        elif isinstance(obj, frozenset):
            return {reverse_hashable(e) for e in obj}
        else:
            return obj

    #550. Prepare the import statement given there could be multiple KPIs stored in the same data file
    #551. Search for all columns EXCEPT [C_KPI_ID] for grouping
    #[ASSUMPTION]
    #[1] The loading options for the same file MUST BE the same in one process batch
    #[2] There could be <dict> stored in the column <options>, which is un-hashable during grouping
    #[3] Hence we ignore the column of <options> when determining the files to load
    if isinstance(fImp_opt, dict):
        files_prep_names = files_exist.drop(columns=['C_KPI_ID']).columns.to_list()
    else:
        files_prep_names = files_exist.drop(columns=['C_KPI_ID',fImp_opt]).columns.to_list()

    #555. Concatenate [C_KPI_ID] for each unique absolute file path
    #Quote: https://stackoverflow.com/questions/27298178/concatenate-strings-from-several-rows-using-pandas-groupby
    files_prep = (
        files_exist
        #[ASSUMPTION]
        #[1] <DF_NAME> may contain <NaN> values hence we do not drop them from the group
        .groupby(files_prep_names, dropna = False)
        .agg({ 'C_KPI_ID' : '|'.join })
        .reset_index()
        .rename(columns = { 'C_KPI_ID' : 'kpis' })
    )

    #557. Add the <options> column back when necessary
    if opt_is_col:
        files_prep.loc[:, fImp_opt_col[0]] = (
            files_exist
            [['C_KPI_FULL_PATH','DF_NAME',fImp_opt_col[0]]]
            # .assign(**{
            #     fImp_opt_col[0] : lambda x: x[fImp_opt_col[0]].apply(make_hashable)
            # })
            .drop_duplicates(['C_KPI_FULL_PATH','DF_NAME'])
            # .assign(**{
            #     fImp_opt_col[0] : lambda x: x[fImp_opt_col[0]].apply(reverse_hashable)
            # })
            .set_index(['C_KPI_FULL_PATH','DF_NAME'])
            .reindex(files_prep.set_index(['C_KPI_FULL_PATH','DF_NAME']).index)
            .set_index(files_prep.index)
            [fImp_opt_col[0]]
        )

    #559. Determine the loop
    n_files = len(files_prep)

    #570. Define the function to be called in parallel
    def func_parallel(i):
        #001. Initialize the environment

        #100. Set parameters
        imp_KPI = files_prep.at[i, 'kpis'].split('|')
        imp_type = files_prep.at[i, 'C_KPI_FILE_TYPE']
        imp_path = files_prep.at[i, 'C_KPI_FULL_PATH']
        if imp_type in ['HDFS']: imp_df = files_prep.at[i, 'DF_NAME']
        else: imp_df = None
        if isinstance(fImp_opt, dict):
            _opt_this = fImp_opt.get(imp_type,{})
        else:
            #Quote: https://stackoverflow.com/questions/988228/convert-a-string-representation-of-a-dictionary-to-a-dictionary/
            _opt_this = files_prep.at[i, fImp_opt_col[0]]
            if not isinstance(_opt_this, dict):
                _opt_this = ast.literal_eval(_opt_this)

        #199. Debug mode
        if fDebug:
            print(
                f'[{LfuncName}]'
                +'[i]=['+str(i)+']'
                +'[imp_KPI]=['+'|'.join(imp_KPI)+']'
                +'[imp_type]=['+imp_type+']'
                +'[imp_path]=['+imp_path+']'
                +'[imp_df]=['+ (imp_df or 'NULL') +']'
                +'[_opt_this]=['+str(_opt_this)+']'
            )

        #300. Prepare the function to apply to the process list
        dataIO.add(imp_type)
        _opt_in = {
            'infile' : imp_path
            #For unification purpose, some APIs would omit below arguments
            ,'key' : imp_df
        }
        modifyDict(_opt_in, _opt_this, inplace = True)

        #309. Debug mode
        if fDebug:
            print(f'[{LfuncName}]Loading from file: <{imp_path}>')

        #500. Call functions to import data from current path
        imp_data = (
            dataIO[imp_type].pull(**_opt_in)
            #100. Upcase the field names for all imported data, to facilitate the later [bind_rows]
            #Ensure the field used at below steps are all referred to in upper case
            .rename( h_convStr, axis = 1 )
            #500. Only keep the KPIs that are defined in [inKPICfg] to reduce the RAM expense
            #Quote: https://stackoverflow.com/questions/19960077/how-to-filter-pandas-dataframe-using-in-and-not-in-like-in-sql
            .loc[lambda x: x['C_KPI_ID'].isin(imp_KPI)]
        )

        #900. Assign additional attributes to the data frame for column class check at later steps
        imp_dict = {
            'path' : imp_path
            ,'data' : imp_data
            ,'DF_NAME.InfDat' : imp_type
        }

        #999. Return the result
        return(imp_dict)

    #590. Create a list of imported data frames and bind all rows of them together as one data frame
    #591. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Import data files in '+('Parallel' if _parallel else 'Sequential')+' mode...')
    #[IMPOTANT] There could be fields/columns in the same name but not the same types in different data files,
    #            but we throw the errors at the step [pandas.concat] to ask user to correct the input data,
    #            instead of guessing the correct types here, for it takes quite a lot of unnecessary effort.
    if _parallel:
        #100. Set the cores to be used and instantiate a pool
        mychunk = int(np.ceil(n_files / cores))
        mypool = Pool(cores)

        #900. Read the files and store the imported data frames into a list
        #Quote: https://stackoverflow.com/questions/15881055/combine-output-multiprocessing-python
        files_import = list(mypool.imap( func_parallel, range(n_files), chunksize = mychunk ))

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
        files_import = list(map( func_parallel, range(n_files) ))

    #600. Combine the results
    #610. Check the list of imported data on the dtypes of columns
    chk_cls = debug_comp_datcols(**{ d['path']:d['data'] for d in files_import })

    #619. Abort the program if any inconsistency is found on columns of data frames
    if len(chk_cls):
        #500. Output a global data frame storing the information of the column inconsistency
        # sys._getframe(1).f_globals.update({ err_cols : chk_cls })
        outDict.update({ err_cols : chk_cls })

        #999. Abort the process
        warn(f'[{LfuncName}]Some columns cannot be bound due to different dtypes!')
        warn(f'[{LfuncName}]Check data frame [{err_cols}] in the output result for these columns!')
        return(outDict)

    #680. Combine the data
    files_combine = pd.concat([ d['data'] for d in files_import ], ignore_index = True)

    #700. Return the above result if [InfDat] is not provided for combination
    if InfDat is None:
        outDict.update({ 'data' : files_combine })
        return(outDict)

    #800. Retrieve the information table as per request
    #801. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Combine [InfDat] with the loaded KPI data...')

    #810. Mark the same columns in both data for further [drop] process
    tbl_out = (
        InfDat.rename( h_convStr, axis = 1 )
        .merge( files_combine , on = keyvar , how = comb_func[SetAsBase] , suffixes=('._inf_', '._kpi_') )
        #850. Determine to drop any fields from above data as per indicated
        #Quote: (#58) https://stackoverflow.com/questions/19071199/
        .loc[:, lambda x: ~x.columns.str.endswith('._kpi_' if KeepInfCol else '._inf_')]
    )

    #870. Rename the rest of the additioinal columns
    sfx_rename = '._inf_' if KeepInfCol else '._kpi_'
    col_rename = tbl_out.columns[tbl_out.columns.str.endswith(sfx_rename)].to_list()
    if col_rename:
        bat_rename = { v:v[:-len(sfx_rename)] for v in col_rename }
        tbl_out.rename(columns=bat_rename, inplace = True)

    #990. Restore the default behavior
    #pd.options.mode.chained_assignment = 'warn'

    #999. Return the table
    outDict.update({ 'data' : tbl_out })
    return(outDict)
#End DBuse_SetKPItoInf

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys, os
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import loadSASdat, DBuse_SetKPItoInf
    from omniPy.Dates import UserCalendar, asDates

    #100. Set parameters
    G_d_curr = '20160310'
    G_m_curr = G_d_curr[:6]
    acctinfo, meta_acct = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\acctinfo.sas7bdat', encoding = 'GB2312')
    CFG_KPI, meta_kpi = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_kpi.sas7bdat', encoding = 'GB2312')
    CFG_LIB, meta_lib = loadSASdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_lib.sas7bdat', encoding = 'GB2312')

    #190. Combine the configuration tables
    mask_kpi = CFG_KPI.apply(lambda x: x['D_BGN'] <= asDates(G_d_curr) <= x['D_END'], axis = 1)
    mask_lib = CFG_LIB.apply(lambda x: x['D_BGN'] <= asDates(G_d_curr) <= x['D_END'], axis = 1)
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
    KPI_rst = DBuse_SetKPItoInf(
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
    )

    #400. Read the KPI data in parallel mode
    KPI_rst2 = DBuse_SetKPItoInf(
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
        ,fDebug = True
        ,miss_skip = True
        ,miss_files = 'G_miss_files'
        ,err_cols = 'G_err_cols'
        ,outDTfmt = {
            'L_d_curr' : '%Y%m%d'
            ,'L_m_curr' : '%Y%m'
        }
    )
#-Notes- -End-
'''
