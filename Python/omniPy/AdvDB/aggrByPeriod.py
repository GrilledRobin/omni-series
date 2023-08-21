#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os
import re
import datetime as dt
import numpy as np
import pandas as pd
import math
import statistics as st
from collections import Counter
from collections.abc import Iterable
from pathos.threading import ThreadPool
from warnings import warn
from functools import partial
from typing import Optional, Union
from omniPy.Dates import asDates, UserCalendar, ObsDates
from omniPy.AdvOp import debug_comp_datcols, thisFunction
from omniPy.AdvDB import std_read_HDFS, std_read_RAM, std_read_SAS, parseDatName

def aggrByPeriod(
    inDatPtn : Union[str, pd.DataFrame] = None
    ,inDatType : str = 'SAS'
    ,in_df : Optional[str] = None
    ,fImp_opt : dict = {
        'SAS' : {
            'encoding' : 'GB2312'
        }
    }
    ,fTrans : Optional[dict] = None
    ,fTrans_opt : dict = {}
    ,_parallel : bool = True
    ,cores : int = 4
    ,dateBgn = None
    ,dateEnd = None
    ,chkDatPtn : Optional[str] = None
    ,chkDatType : str = 'SAS'
    ,chkDat_df : Optional[str] = None
    ,chkDat_opt : dict = {
        'SAS' : {
            'encoding' : 'GB2312'
        }
    }
    ,chkDatVar : Optional[str] = None
    ,chkBgn = None
    ,byVar : Optional[Iterable] = None
    ,copyVar : Optional[Iterable] = None
    ,aggrVar : str = 'A_KPI_VAL'
    ,outVar : str = 'A_VAL_OUT'
    ,genPHMul : bool = True
    ,calcInd : str = 'C'
    ,funcAggr : callable = np.nanmean
    ,miss_files : str = 'G_miss_files'
    ,err_cols : str = 'G_err_cols'
    ,outDTfmt : dict = {
        'L_d_curr' : '%Y%m%d'
        ,'L_m_curr' : '%Y%m'
    }
    ,fDebug : bool = False
    ,**kw
) -> 'Aggregate specified single column of KPI within a certain period of dates':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the summary stats for each respective group of [byVar] by the provided aggregation function #
#   | [funcAggr] in terms of a time-series data source based on indication of calculation for Calendar Days, Workdays or Tradedays      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |It is used to minimize the computer resource consumption when the process is conducted on a daily basis, for it can leverage the   #
#   | calculated result of the previous workday to calculate the value of current day, prior to the aggregation of all datasets in the  #
#   | given period of time.                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT:                                                                                                                         #
#   |[1] If there is any Descriptive Information in the series of input datasets, the Last Existing one will be kept in the output      #
#   |     dataset. E.g. if a customer only exists from 1st to 15th in a month, his/her status on 15th will be kept in the output data.  #
#   |[2] If there are multiple rows for the same [byVar] in a single import data (i.e. the daily snapshot of database), their [aggrVar] #
#   |     will be aggregated by [sum] in the first place, before being merged to other data in the series. This is to avoid uncertainty.#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate the Date-to-Date average value of the KPI, such as ANR (i.e. Average Net Receivables)                                #
#   |[2] Identify the maximum or minimum value of the KPI over the period                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |110.   Input dataset information: (Daily snapshot of database)                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDatPtn   :   Naming pattern of the series of datasets for calculation (such as Daily Account Balances)                           #
#   |               [IMPORTANT] If a pd.DataFrame is provided, it MUST match below naming convention:                                   #
#   |               |------------------------------------------------------------------------------------------------------------------ #
#   |               |Column Name     |Required?  |Description                                                                           #
#   |               |----------------+-----------+--------------------------------------------------------------------------------------#
#   |               |FileName        |Yes        | The naming pattern of data files to be located in the candidate paths                #
#   |               |FilePath        |Yes        | The naming pattern of the candidate paths to store the data (incl. file name)        #
#   |               |PathSeq         |Yes        | The sequence of candidate paths to search for the data file. Should the same data    #
#   |               |                |           |  exist in many among these paths, the one with the smaller [PathSeq] is retrieved    #
#   |               |[inDatType]     |Yes        | The types of data files that indicates the method for this function to import data   #
#   |               |                |           | [RAM     ] Try to load the data frame from RAM in current session                    #
#   |               |                |           | [HDFS    ] Try to import as HDFStore file                                            #
#   |               |                |           | [SAS     ] Try to import via [pyreadstat.read_sas7bdat]                              #
#   |               |[in_df]         |No         | For some cases, such as [inDatType=HDFS] there should be such an additional field    #
#   |               |                |           |  indicating the name of data.frame stored in the data file (i.e. container)          #
#   |               |                |           | It is required if [inDatType] on any record is [HDFS]                                #
#   |               |----------------+-----------+--------------------------------------------------------------------------------------#
#   |               [--> IMPORTANT  <--] Program will translate several columns in below way as per requested by [fTrans], see local    #
#   |                                     variable [trans_var].                                                                         #
#   |                                    [1] [fTrans] is NOT provided: assume that the value in this field is a valid file path         #
#   |                                    [2] [fTrans] is provided a named list or vector: Translate the special strings in accordance   #
#   |                                          as data file names. in such case, names of the provided parameter are treated as strings #
#   |                                          to be replaced; while the values of the provided parameter are treated as variables in   #
#   |                                          the parent environment and are [get]ed for translation, e.g.:                            #
#   |                                        [1] ['&c_date.' = 'G_d_curr'  ] Current reporting/data date in SAS syntax [&c_date.] to be #
#   |                                              translated by the value of Python variable [G_d_curr] in the parent frame            #
#   |               |------------------------------------------------------------------------------------------------------------------ #
#   |inDatType  :   The type of data files that indicates the method for this function to import data                                   #
#   |               [SAS             ] <Default> Try to import as the SAS dataset                                                       #
#   |               [RAM             ]           Try to load the data frame from RAM in current environment                             #
#   |               [HDFS            ]           Try to import as HDFStore file                                                         #
#   |               [<column name>   ]           Column name indicating the data file type if [inDatPtn] is provided a pd.DataFrame     #
#   |in_df      :   For some containers, such as [inDatType=HDFS] we should provide the name of data.frame stored inside it for loading #
#   |               [None            ] <Default> No need for default SAS data loading                                                   #
#   |               [<column name>   ]           Column name indicating the data key if [inDatPtn] is provided a pd.DataFrame           #
#   |fImp_opt   :   List of options during the data file import for different engines; each element of it is a separate list, too       #
#   |               Valid names of the option lists are set in the argument [inDatType]                                                 #
#   |               [SAS             ] <Default> Options for [omniPy.AdvDB.std_read_SAS]                                                #
#   |                                            [encoding = 'GB2312' ]  <Default> Read SAS data in this encoding                       #
#   |               [{<name>:<dict>} ]           Other dictionaries for different engines, such as [R=dict()] and [HDFS=dict()]         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |120.   Naming pattern translation/mapping                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fTrans     :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process    #
#   |               [None            ] <Default> For time series process, please ensure this argument is manually defined, otherwise    #
#   |                                             the result is highly unexpected                                                       #
#   |fTrans_opt :   Additional options for value translation on [fTrans], see document for [AdvOp.apply_MapVal]                         #
#   |               [{}              ] <Default> Use default options in [apply_MapVal]                                                  #
#   |               [<dict>          ]           Use alternative options as provided by a dict, see documents of [apply_MapVal]         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |130.   Multi-processing support                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |_parallel  :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but may be slow for small ones  #
#   |               [True            ] <Default> Use multiple CPU cores to load the data files in parallel                              #
#   |               [False           ]           Load the data files sequentially                                                       #
#   |cores      :   Number of system cores to read the data files in parallel                                                           #
#   |               [4               ] <Default> No need when [_parallel=False]                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |150.   Calculation period control                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dateBgn    :   Beginning of the calculation period. It will be converted to [Date] by [Dates$asDates] internally, hence please     #
#   |                follow the syntax of this function during input                                                                    #
#   |               [None            ] <Default> Function will raise error if it is NOT provided                                        #
#   |dateEnd    :   Ending of the calculation period. It will be converted to [Date] by [Dates$asDates] internally, hence please        #
#   |                follow the syntax of this function during input                                                                    #
#   |               [None            ] <Default> Function will raise error if it is NOT provided                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |160.   Retrieval of previously aggregated result for Checking Period                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |chkDatPtn  :   Naming pattern of the datasets that store the previously aggregated KPI for minimization of system effort, such as  #
#   |                MTD Daily Average Balance by Account                                                                               #
#   |               [IMPORTANT] This pattern will be translated by [fTrans], hence please ensure the correct convention                 #
#   |               [None            ] <Default> Function will not use existing results for performance improvement                     #
#   |chkDatType :   The type of data files for Checking Period that indicates the method for this function to import data               #
#   |               [SAS             ] <Default> Try to import as the SAS dataset                                                       #
#   |               [RAM             ]           Try to load the data frame from RAM in current environment                             #
#   |               [HDFS            ]           Try to import as HDFStore file                                                         #
#   |chkDatVar  :   Variable name in the [data as of Checking Period], which is used for calculation in [Checking Period]               #
#   |               [None            ] <Default> Not in use if [Checking Period] is not involved, or raise error when required          #
#   |               [<str>           ]           Use this column to calculate [Leading Period] out of [Checking Period]                 #
#   |chkDat_df  :   For some containers, such as [inDatType=HDFS] we should provide the name of data.frame stored inside it for loading #
#   |               [None            ] <Default> No need for default SAS data loading                                                   #
#   |chkDat_opt :   List of options during the data file import for different engines; each element of it is a separate list, too       #
#   |               Valid names of the option lists are set in the field [inDatType]                                                    #
#   |               [SAS             ] <Default> Options for [omniPy.AdvDB.std_read_SAS]                                                #
#   |                                            [encoding = 'GB2312' ]  <Default> Read SAS data in this encoding                       #
#   |               [{<name>:<dict>} ]           Other named lists for different engines, such as [R=dict()] and [HDFS=dict()]          #
#   |chkBgn     :   Beginning of the Checking Period. It will be converted to [Date] by [Dates.asDates] internally, hence please        #
#   |                follow the syntax of this function during input                                                                    #
#   |               [None            ] <Default> Function will set it the same as [dateBgn]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |170.   Column inclusion                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |byVar      :   The list/vector of column names that are to be used as the group to aggregate the KPI                               #
#   |               [IMPORTANT] All these columns MUST exist in both [inDatPtn] and [chkDatPtn]                                         #
#   |               [None            ] <Default> Function will raise error if it is NOT provided                                        #
#   |copyVar    :   The list/vector of column names that are to be copied during the aggregation                                        #
#   |               [Note 1] All these columns MUST exist in both [inDatPtn] and [chkDatPtn]                                            #
#   |               [Note 2] Only those values in the Last Existing observation/record can be copied to the output                      #
#   |               [None            ] <Default> There is no additional column to be retained for the output                            #
#   |aggrVar    :   The single column name in [inDatPtn] that represents the value to be applied by function [funcAggr]                 #
#   |               [A_KPI_VAL       ] <Default> Function will aggregate this column                                                    #
#   |outVar     :   The single column name as the aggregated value in the output data                                                   #
#   |               [A_VAL_OUT       ] <Default> Function will output this column                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |180.   Indicators and methods for aggregation                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |genPHMul   :   Whether to generate the data on Public Holidays by resembling their respective Previous Workdays/Tradedays with     #
#   |                proper Multipliers, to minimize the system effort                                                                  #
#   |               [True            ] <Default> Resemble the data on Public Holidays with their respective Previous Workdays/Tradedays #
#   |                                            in terms of the indicator [calcInd]                                                    #
#   |                                            [IMPORTANT] Function will ignore any existing data on Public Holidays                  #
#   |               [False           ]           Function will NOT generate pseudo data for Public Holidays                             #
#   |                                            [IMPORTANT] Function will raise error if there is no existing data on Public Holidays  #
#   |calcInd    :   The indicator for the function to calculate based on Calendar Days, Workdays or Tradedays                           #
#   |               [C               ] <Default> Conduct calculation based on Calendar Days                                             #
#   |               [W               ]           Conduct calculation based on Workdays. Namingly, [genPHMul] will hence take no effect  #
#   |               [T               ]           Conduct calculation based on Tradedays. Namingly, [genPHMul] will hence take no effect #
#   |funcAggr   :   The function to aggregate the input time series data. It should be provided a [function]                            #
#   |               [IMPORTANT] All [NaN] values are excluded as they create meaningless results for all aggregation functions          #
#   |               [np.nanmean      ] <Default> Calculate the average of [aggrVar] per [byVar] as a time series, with NaN removed      #
#   |               [<other aggr.>   ]           Other aggregation functions that are supported in current environment                  #
#   |                                            [IMPORTANT] One can define specific aggregation function and use it here               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fDebug     :   The switch of Debug Mode. Valid values are [F] or [T].                                                              #
#   |               [False           ] <Default> Do not print debug messages during calculation                                         #
#   |               [True            ]           Print debug messages during calculation                                                #
#   |miss_files :   Name of the global variable to store the debug data frame with missing file paths and names                         #
#   |               [G_miss_files    ] <Default> If any data files are missing, please check this global variable to see the details    #
#   |               [chr string      ]           User defined name of global variable that stores the debug information                 #
#   |err_cols   :   Name of the global variable to store the debug data frame with error column information                             #
#   |               [G_err_cols      ] <Default> If any columns are invalidated, please check this global variable to see the details   #
#   |               [chr string      ]           User defined name of global variable that stores the debug information                 #
#   |outDTfmt   :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                    #
#   |               [ <dict>         ] <Default> See the function definition as the default argument of usage                           #
#   |kw         :   Any other arguments that are required by [funcAggr]. Please check the documents for it before defining this one     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[dict]     :   The dictionary that contains below keys as results:                                                                 #
#   |               [data            ] [pd.DataFrame] that contains the combined result                                                 #
#   |               [ <miss_files>   ] [None] if all data files are successfully loaded, or [pd.DataFrame] that contains the paths to   #
#   |                                   the data files that are required but missing                                                    #
#   |               [ <err_cols>     ] [None] if all data files are successfully loaded, or [pd.DataFrame] that contains the column     #
#   |                                   names as well as the data files in which they are located, which cannot be concatenated due to  #
#   |                                   different [dtypes]                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210515        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210529        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [omniPy.AdvDB.parseDatName] as standardization     #
#   |      |[2] Introduce an argument [outDTfmt] aligning above change, to bridge the mapping from [fTrans] to the date series          #
#   |      |[3] Correct the part of frame lookup when assigning values to global variables for user request                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210607        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Change the output into a [dict] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210828        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now accept [inDatPtn] as a pd.DataFrame which contains patterns of data files in different candidate paths              #
#   |      |[2] If multiple [inDatPtn] are provided, each one must exist in at least one among the candidate paths                      #
#   |      |[3] Now execute in silent mode by default. If one needs to see the calculation progress, switch to [fDebug = True]          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220815        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when [chkBgn] > [chkEnd] so that the program no longer tries to conduct calculation for Checking Period in  #
#   |      |     such case                                                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220917        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Removed excessive calculation for Actual Calculation Period to simplify the logic                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230111        | Version | 3.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when [inDatCfg] is provided a pd.DataFrame while [in_df] is not specified                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 3.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 3.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 3.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <thisFunction> to actually find the current callable being called instead of its name                         #
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
#   |   |sys, os, datetime, numpy, pandas, math, statistics, collections, pathos, warnings, functools, typing                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |asDates                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |debug_comp_datcols                                                                                                         #
#   |   |   |thisFunction                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |std_read_HDFS                                                                                                              #
#   |   |   |std_read_RAM                                                                                                               #
#   |   |   |std_read_SAS                                                                                                               #
#   |   |   |parseDatName                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'
    recall = thisFunction()

    #012. Parameter buffer
    if isinstance(inDatPtn, pd.DataFrame):
        if inDatType not in inDatPtn.columns:
            raise ValueError('['+LfuncName+']'+'[inDatType] must be an existing column in the data frame [inDatPtn]!')
        if 'HDFS' in inDatPtn[inDatType]:
            if in_df not in inDatPtn.columns:
                raise ValueError('['+LfuncName+']'+'[in_df] must be an existing column in the data frame [inDatPtn]!')

        inDatCfg = inDatPtn.copy(deep=True)
    else:
        if (not inDatPtn) | (not isinstance(inDatPtn, str)):
            raise TypeError('['+LfuncName+']'+'[inDatPtn] must be a single character string!')
        if not inDatType: inDatType = 'SAS'
        inDatType = inDatType.upper()
        if inDatType not in ['SAS','HDFS','RAM']:
            raise ValueError('['+LfuncName+']'+'[inDatType] should be any among [SAS, HDFS, RAM]!')
        if inDatType in ['HDFS']:
            if not in_df: raise ValueError('['+LfuncName+']'+'[in_df] is not provided for [inDatType='+inDatType+']!')

        inDatCfg = pd.DataFrame(
            {
                'FilePath' : inDatPtn
                ,'PathSeq' : pd.Series(1, dtype = 'int8')
                ,'FileName' : os.path.basename(inDatPtn)
                ,'FileType' : inDatType
                ,'DF_NAME' : pd.Series(in_df, dtype = 'object')
            }
            ,index = [0]
        )

    if fTrans_opt is None: fTrans_opt = {}
    if not isinstance(_parallel, bool): _parallel = False
    if _parallel:
        if not cores: cores = 4
    if not dateBgn: raise ValueError('['+LfuncName+']'+'[dateBgn] is not provided!')
    if not dateEnd: raise ValueError('['+LfuncName+']'+'[dateEnd] is not provided!')
    if chkDatPtn:
        if not isinstance(chkDatPtn, str): raise TypeError('['+LfuncName+']'+'[chkDatPtn] must be a single character string!')
    if not chkDatType: chkDatType = 'SAS'
    chkDatType = chkDatType.upper()
    if chkDatType not in ['SAS','HDFS','RAM']:
        raise ValueError('['+LfuncName+']'+'[chkDatType] should be any among [SAS, HDFS, RAM]!')
    if not chkBgn:
        print('['+LfuncName+']'+'[chkBgn] is not provided. It will be set the same as [dateBgn].')
        chkBgn = dateBgn
    if chkDatType in ['HDFS']:
        if not chkDat_df: raise ValueError('['+LfuncName+']'+'[chkDat_df] is not provided for [chkDatType='+chkDatType+']!')
    if isinstance(byVar, str):
        byVar = [byVar]
    elif isinstance(byVar, Iterable):
        byVar = list(byVar)
        if not np.alltrue([ isinstance(v,str) for v in byVar ]):
            raise TypeError('['+LfuncName+']'+'[byVar] should only be a list of [str]!')
    else:
        raise TypeError('['+LfuncName+']'+'[byVar] should be either [str] or [list of str] instead of [{0}]!'.format(type(byVar)))
    if isinstance(copyVar, str):
        copyVar = [copyVar]
    elif isinstance(copyVar, Iterable):
        copyVar = list(copyVar)
        if not np.alltrue([ isinstance(v,str) for v in copyVar ]):
            raise TypeError('['+LfuncName+']'+'[copyVar] should only be a list of [str]!')
    else:
        raise TypeError('['+LfuncName+']'+'[copyVar] should be either [str] or [list of str] instead of [{0}]!'.format(type(copyVar)))
    if (not aggrVar) | (not isinstance(aggrVar, str)):
        print('['+LfuncName+']'+'[aggrVar] is not provided, use the default one [A_KPI_VAL] instead.')
        aggrVar = 'A_KPI_VAL'
    if not isinstance(genPHMul, bool):
        print(
            '['+LfuncName+']'+'[genPHMul] is not provided as logical value.'
            +' Program resembles the data on Public Holidays by their respective Previous Workdays.'
        )
        genPHMul = True
    if not calcInd: calcInd = 'C'
    calcInd = calcInd.upper()
    if calcInd not in ['C','W','T']:
        raise ValueError('['+LfuncName+']'+'[calcInd] should be any among [C, W, T]!')
    if not callable(funcAggr): raise TypeError('['+LfuncName+']'+'[funcAggr] should be provided a function!')
    if not isinstance(fDebug, bool): fDebug = False
    if (not outVar) | (not isinstance(outVar, str)): outVar = 'A_VAL_OUT'
    if (not miss_files) | (not isinstance(miss_files, str)): miss_files = 'G_miss_files'
    if (not err_cols) | (not isinstance(err_cols, str)): err_cols = 'G_err_cols'
    if kw is None: kw = {}

    #020. Local environment
    indat_col_parse = 'FilePath'
    indat_col_file = 'FileName'
    indat_col_dirseq = 'PathSeq'
    indat_col_date = 'dates'
    if isinstance(inDatPtn, pd.DataFrame):
        indat_col_type = inDatType
        indat_col_df = in_df if in_df is not None else '.nulcol.'
    else:
        indat_col_type = 'FileType'
        indat_col_df = 'DF_NAME'
    f_get_in_df = indat_col_df in inDatCfg.columns

    outDict = {
        'data' : None
        ,miss_files : None
        ,err_cols : None
    }
    ABP_errors = False
    dateBgn = asDates(dateBgn)
    dateEnd = asDates(dateEnd)
    func_means = [np.mean, np.nanmean, st.mean]
    if chkBgn: chkBgn = asDates(chkBgn)
    fLeadCalc, fUsePrev, calcDate, calcMult = False, False, None, None

    #025. Verify the requested aggregation function
    #Find all [numpy.nan<funcs>]
    #Quote: https://stackoverflow.com/questions/3061/calling-a-function-of-a-module-by-using-its-name-a-string
    ptn_nan = re.compile(r'nan([a-z\d]+)', flags = re.I)
    func_nans = { getattr(np, ptn_nan.sub(r'\1', f)):getattr(np, f) for f in dir(np) if ptn_nan.fullmatch(f) }
    re.purge()
    #Identify the provided function within above list
    chkfunc = func_nans.get(funcAggr, None)
    #Determine the function to use internally
    if funcAggr in (func_means + [sum, np.sum, math.fsum]):
        LFuncAggr = np.nansum
    elif chkfunc is not None:
        #Change all [numpy] functions into [numpy.nan<funcs>] to make the output result reasonable
        LFuncAggr = chkfunc
    else:
        LFuncAggr = funcAggr

    #030. Define the helper function to retrieve the last record of the provided column, no matter whether it is within a group
    def _last(col):
        return( col.tail(1) )

    #032. Create a list of unique column names for selection from the input data
    select_at = []
    if isinstance(byVar, list):
        select_at.extend(byVar)
    else:
        select_at.append(byVar)
    #[copyVar] could possibly not be provided
    if copyVar:
        if isinstance(copyVar, list):
            select_at.extend(copyVar)
        else:
            select_at.append(copyVar)
    #We directly append [aggrVar] as it must be the name of a single column as defined by this function
    select_at.append(aggrVar)
    #Dedup
    select_at = list(Counter(select_at).keys())

    #035. Define the dictionary of columns to be aggregated by certain functions respectively
    #Only retrieve the last occurrence of [copyVar] for each group
    #[copyVar] could possibly not be provided
    aggrDict = {}
    if copyVar:
        if isinstance(copyVar, list):
            aggrDict.update({ c : _last for c in copyVar })
        else:
            aggrDict.update({ copyVar : _last })

    #036. Calculate the sum of [aggrVar]
    #Ensure [aggrVar] is at the right-most position in the output data frame
    aggrDict.update({ '.Tmp_Val' : np.nansum })

    #039. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'Debug mode...')
        print('['+LfuncName+']'+'Parameters are listed as below:')
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        getvar = sys._getframe().f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print('['+LfuncName+']'+'[{0}]=[{1}]'.format(v,locals().get(v)))

    #040. Create calendar for calculation of time series
    ABP_Clndr = UserCalendar(
        dateBgn = dateBgn
        ,dateEnd = dateEnd
        ,clnBgn = chkBgn - dt.timedelta(days=30)
        ,clnEnd = dateEnd + dt.timedelta(days=30)
    )
    ABP_ObsDates = ObsDates(
        obsDate = dateEnd
        ,clnBgn = chkBgn - dt.timedelta(days=30)
        ,clnEnd = dateEnd + dt.timedelta(days=30)
    )

    #050. Determine [chkEnd] by the implication of [genPHMul]
    if genPHMul & (calcInd!='C'):
        chkEnd = ABP_ObsDates.shiftDays(kshift = -1, preserve = False, daytype = calcInd)[0]
    else:
        chkEnd = dateEnd - dt.timedelta(days=1)

    #070. Retrieve the Previous Days by the implication of [calcInd]
    if calcInd=='C':
        periodOut = (dateEnd - dateBgn + dt.timedelta(days=1)).days
        periodChk = (chkEnd - chkBgn + dt.timedelta(days=1)).days
        pdCalcBgn = dateBgn - dt.timedelta(days=1)
        pdCalcEnd = dateEnd - dt.timedelta(days=1)
        pdChkBgn = chkBgn - dt.timedelta(days=1)
        pdChkEnd = chkEnd - dt.timedelta(days=1)
    elif calcInd=='W':
        periodOut = ABP_Clndr.kWorkDay
        if chkEnd>=chkBgn:
            ABP_Clndr.dateBgn = chkBgn
            ABP_Clndr.dateEnd = chkEnd
            periodChk = ABP_Clndr.kWorkDay
        else:
            periodChk = 0
        ABP_ObsDates.values = [dateBgn, dateEnd, chkBgn, chkEnd]
        pdCalcBgn, pdCalcEnd, pdChkBgn, pdChkEnd = ABP_ObsDates.prevWorkDay
    else:
        periodOut = ABP_Clndr.kTradeDay
        if chkEnd>=chkBgn:
            ABP_Clndr.dateBgn = chkBgn
            ABP_Clndr.dateEnd = chkEnd
            periodChk = ABP_Clndr.kTradeDay
        else:
            periodChk = 0
        ABP_ObsDates.values = [dateBgn, dateEnd, chkBgn, chkEnd]
        pdCalcBgn, pdCalcEnd, pdChkBgn, pdChkEnd = ABP_ObsDates.prevTradeDay

    #075. Define the multiplier for Checking Period
    multiplier_CP = periodChk if funcAggr in func_means else 1

    #080. Calculate the difference of # date coverage by the implication of [calcInd]
    periodDif = periodOut - periodChk

    #099. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'[chkEnd]=[{0}]'.format(str(chkEnd)))
        print('['+LfuncName+']'+'[periodOut]=[{0}]'.format(str(periodOut)))
        print('['+LfuncName+']'+'[periodChk]=[{0}]'.format(str(periodChk)))
        print('['+LfuncName+']'+'[periodDif]=[{0}]'.format(str(periodDif)))
        print('['+LfuncName+']'+'[pdCalcBgn]=[{0}]'.format(str(pdCalcBgn)))
        print('['+LfuncName+']'+'[pdCalcEnd]=[{0}]'.format(str(pdCalcEnd)))
        print('['+LfuncName+']'+'[pdChkBgn]=[{0}]'.format(str(pdChkBgn)))
        print('['+LfuncName+']'+'[pdChkEnd]=[{0}]'.format(str(pdChkEnd)))

    #100. Calculate the summary for the leading period from [chkBgn] to [dateBgn], if applicable
    #110. Calculate the prerequisites for the data as of Checking Period
    if isinstance(chkDatPtn, str) & isinstance(chkBgn, dt.date):
        #100. Determine the name of the data as dependency in Checking Period
        parse_chkDat = parseDatName(
            datPtn = chkDatPtn
            ,parseCol = None
            ,dates = chkEnd
            ,outDTfmt = outDTfmt
            ,inRAM = (chkDatType=='RAM')
            ,chkExist = True
            ,dict_map = fTrans
            ,**fTrans_opt
        )

        #500. Extract the values for later steps
        chkDat = parse_chkDat.at[0, 'datPtn.Parsed']
        LchkExist = parse_chkDat.at[0, 'datPtn.chkExist']

    #150. Call the same function in recursion when necessary
    if not chkBgn:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'Procedure will not conduct calculation in Leading Period'
                +' since [chkBgn] is not provided'
            )
    elif chkBgn>=dateBgn:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'Procedure will not conduct calculation in Leading Period'
                +' since [chkBgn='+str(chkBgn)+'] >= [dateBgn='+str(dateBgn)+']'
            )
    elif periodDif!=0:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'Procedure will not conduct calculation in Leading Period'
                +' since its date period coverage is not identical to current one'
            )
    elif LFuncAggr != np.nansum:
        #001. Debug mode
        if fDebug:
            #[IMPORTANT] The internal function has been corrected to [numpy.nan<funcs>] where applicable
            print(
                '['+LfuncName+']'+'Procedure will not conduct calculation in Leading Period'
                +' for the functions other than [sum, np.sum, np.nansum, math.fsum, np.mean, np.nanmean, statistics.mean]'
            )
    elif not chkDatPtn:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'[chkDatPtn] is not provided. Skip the calculation for Leading Period'
            )
    elif not LchkExist:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'The data [chkDat='+chkDat+'] does not exist.'
                +' Skip the calculation for Leading Period'
            )
    else:
        #001. Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Entering calculation for Leading Period...')

        #100. Call the function to calculate the summary in Leading Period
        #[1] There is no such [chkDatPtn] to leverage for the Leading Period
        #[2] The end date of the Leading Period is determined by [calcInd]
        #[3] We will only apply [SUM] for the calculation in Leading Period, for later subtraction
        ABP_LeadPeriod = recall(
            inDatPtn = inDatPtn
            ,inDatType = inDatType
            ,in_df = in_df
            ,fTrans = fTrans
            ,fTrans_opt = fTrans_opt
            ,fImp_opt = fImp_opt
            ,_parallel = _parallel
            ,cores = cores
            ,dateBgn = chkBgn
            ,dateEnd = pdCalcBgn
            ,chkDatPtn = None
            ,chkDatType = chkDatType
            ,chkDat_df = chkDat_df
            ,chkDat_opt = chkDat_opt
            ,chkDatVar = chkDatVar
            ,chkBgn = None
            ,byVar = byVar
            ,copyVar = copyVar
            ,aggrVar = aggrVar
            ,genPHMul = genPHMul
            ,calcInd = calcInd
            ,funcAggr = LFuncAggr
            ,outVar = '.CalcLead.'
            ,miss_files = miss_files
            ,err_cols = err_cols
            ,fDebug = fDebug
        )

        #199. Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Exiting calculation for Leading Period...')

        #900. Mark the availability of this process
        fLeadCalc = True

    #200. Determine whether to leverage [chkDat] as overall control
    if not chkDatPtn:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'[chkDatPtn] is not provided. Skip the calculation for Checking Period'
            )
    elif not LchkExist:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'The data [chkDat='+chkDat+'] does not exist.'
                +' Skip the calculation for Checking Period'
            )
    elif chkBgn > chkEnd:
        #001. Debug mode
        if fDebug:
            print(
                '['+LfuncName+']'+'Procedure will not conduct calculation in Checking Period'
                +' since [chkBgn='+str(chkBgn)+'] > [chkEnd='+str(chkEnd)+']'
            )
    elif (dateBgn==chkBgn) | fLeadCalc:
        #001. Debug mode
        if fDebug:
            print('['+LfuncName+']'+'Prepare the calculation for Checking Period...')

        #[1] [dateBgn] = [chkBgn], which usually represents a continuous calculation at fixed beginning, such as MTD ANR
        #[2] [fLeadCalc] = 1, which implies that the Leading Period has already been involved hence the entire
        #     Previous Calculation Result MUST also be involved
        fUsePrev = True

    #300. Determine the datasets to be used for calculation in current period
    #310. Determine the beginning of retrieval
    if fUsePrev:
        #We set the actual beginning date as the next Calendar Day of the date [chkEnd] if the previous calculation
        # result is to be leveraged
        actBgn = chkEnd + dt.timedelta(days=1)
    else:
        #We set the actual beginning date as of the date [dateBgn] if there is no previous result to leverage
        actBgn = dateBgn

    #329. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'Actual Calculation Period: [actBgn='+str(actBgn)+'][dateEnd='+str(dateEnd)+']')

    #350. Go through the period from [actBgn] to [dateEnd] and determine the resolution for [inDatPtn]
    #351. Retrieve all the date information within the period
    #[IMPORTANT] Using below sequence of statements is because the latest [ABP_Clndr$dateEnd] is sometimes earlier than [actBgn]
    ABP_Clndr.dateEnd = dateEnd
    ABP_Clndr.dateBgn = actBgn

    #355. Create necessary variables for calculation in the actually required period
    if calcInd=='W':
        #This situation has nothing to do with the parameter [genPHMul]
        calcDate = ABP_Clndr.d_AllWD
    elif calcInd=='T':
        #This situation has nothing to do with the parameter [genPHMul]
        calcDate = ABP_Clndr.d_AllTD
    elif genPHMul:
        ABP_ObsDates.values = ABP_Clndr.d_AllCD
        #Assumptions:
        #[1] In such case, we never know whether to predate the beginning of the actual calculation period by Workdays or Tradedays
        #[2] # Workdays is more than # Tradedays in the same period, hence we only resemble the data on holidays with the data
        #     on Workdays
        #[3] When there is absolute requirement to resemble the data on holidays by that on Tradedays, try to modify the Calendar
        #     Adjustment data by setting all Workdays to the same as Tradedays BEFORE using this function
        availDate = ABP_ObsDates.shiftDays(kshift = -1, preserve = True, daytype = 'W')
        #Quote[#312]: https://stackoverflow.com/questions/12282232/how-do-i-count-unique-values-inside-a-list
        calcMult = Counter(availDate)
        calcDate = list(calcMult.keys())
    else:
        calcDate = ABP_Clndr.d_AllCD

    #357. Reset the multiplier for data on each date for special cases
    if (not genPHMul) | (calcInd!='C') | (LFuncAggr != np.nansum):
        calcMult = { d:1 for d in calcDate }

    #399. Print necessary information for debugging purpose
    if fDebug:
        #100. Print the necessities for Leading Period
        if fLeadCalc:
            print('['+LfuncName+']'+'[Leading Period] Dataset to use: [ABP_LeadPeriod]')

        #400. Print the necessities for Checking Period
        if fUsePrev:
            print('['+LfuncName+']'+'[Checking Period] Dataset to use: [{0}]'.format(chkDat))
            print('['+LfuncName+']'+'[Checking Period] Data multiplier: [{0}]'.format(multiplier_CP))

        #700. Print the necessities for Actual Calculation Period
        print('['+LfuncName+']'+'[Actual Calculation Period] Dataset to use: [{0}]'.format(inDatCfg))
        for i,d in enumerate(calcDate):
            print(
                '['+LfuncName+'][Actual Calculation Period]'
                +' Date[{0}]: [{1}]'.format(i, d)
                +', Multiplier[{0}]: [{1}]'.format(i,calcMult.get(d))
            )

    #400. Verify the existence of the data files that are actually required
    #410. Parse the naming pattern into the physical file path
    parse_calcDat = parseDatName(
        datPtn = inDatCfg
        ,parseCol = indat_col_parse
        ,dates = calcDate
        ,outDTfmt = outDTfmt
        ,inRAM = (inDatCfg[indat_col_type]=='RAM')
        ,chkExist = True
        ,dict_map = fTrans
        ,**fTrans_opt
    )

    #420. Search in all candidate paths of the the libraries for the data files and identify the first occurrences respectively
    exist_calcDat = (
        parse_calcDat
        .loc[parse_calcDat[indat_col_parse + '.chkExist']]
        .sort_values([indat_col_file, indat_col_date, indat_col_dirseq])
        .groupby([indat_col_file, indat_col_date], as_index = False)
        .head(1)
        .copy(deep=True)
    )
    n_files = len(exist_calcDat)

    #429. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'There are ['+str(n_files)+'] data files to involve in the Actual Calculation Period')
        print('['+LfuncName+']'+'Actual Calculation Period Covers below dates:')
        print(calcDate)
        print('['+LfuncName+']'+'Their respective multipliers are as below:')
        print(calcMult)

    #450. Identify the files that do not exist in any among the candidate paths
    nonexist_calcDat = (
        parse_calcDat
        .merge(exist_calcDat[[indat_col_file, indat_col_date]].drop_duplicates(), how = 'left', indicator = True)
        .loc[lambda x: x['_merge'] == 'left_only']
        .drop(columns = ['_merge'])
    )

    #490. Abort the program for certain conditions
    #491. Abort the process if any of the data files do not exist
    if len(nonexist_calcDat):
        #500. Output a global data frame storing the information of the missing data files
        # sys._getframe(1).f_globals.update({ miss_files : parse_calcDat[~parse_calcDat['datPtn.chkExist']].copy(deep=True) })
        outDict.update({ miss_files : nonexist_calcDat.copy(deep=True) })

        #999. Abort the process
        warn('['+LfuncName+']'+'Some data files do not exist! Check the data frame ['+miss_files+'] in the output result!')
        ABP_errors = True

    #495. Verify the exit condition from the calculation of the Leading Period
    if fLeadCalc:
        if ABP_LeadPeriod.get(miss_files) is not None:
            #500. Output a global data frame storing the information of the missing data files
            outDict.update({
                miss_files : pd.concat([ABP_LeadPeriod.get(miss_files), outDict.get(miss_files)], ignore_index = True)
            })

            #999. Abort the process
            warn('['+LfuncName+']'+'Some data files do not exist! Check the data frame ['+miss_files+'] in the output result!')
            ABP_errors = True

    #499. Abort if the flag of errors is True
    if ABP_errors: return(outDict)

    #500. Import the source data within the Actual Calculation Period
    #510. Define the function for reading one data file per batch
    def ABP_parallel(i):
        #100. Set parameters
        #We use [df.iat()] in case its index is nonlexical i.e. non-ordinal
        inDat = exist_calcDat.iat[i, exist_calcDat.columns.get_loc(indat_col_parse + '.Parsed')]
        if f_get_in_df:
            inDat_df = exist_calcDat.iat[i, exist_calcDat.columns.get_loc(indat_col_df)]
        else:
            inDat_df = None
        inDat_type = exist_calcDat.iat[i, exist_calcDat.columns.get_loc(indat_col_type)]
        L_date = exist_calcDat.iat[i, exist_calcDat.columns.get_loc('dates')]
        L_d_curr = L_date.strftime('%Y%m%d')

        #300. Prepare the function to apply to the process list
        opt_hdfs = {
            'infile' : inDat
            ,'key' : inDat_df
        }
        if fImp_opt.get('HDFS',{}):
            opt_hdfs.update(fImp_opt.get('HDFS',{}))
        opt_sas = {
            'infile' : inDat
        }
        if fImp_opt.get('SAS',{}):
            opt_sas.update(fImp_opt.get('SAS',{}))
        imp_func = {
            'RAM' : {
                '_func' : std_read_RAM
                ,'_opt' : {
                    'infile' : inDat
                }
            }
            ,'HDFS' : {
                '_func' : std_read_HDFS
                ,'_opt' : opt_hdfs
            }
            ,'SAS' : {
                '_func' : std_read_SAS
                ,'_opt' : opt_sas
            }
        }

        #500. Call functions to import data from current path
        #590. Load the data and conduct the requested transformation
        imp_data = (
            imp_func[inDat_type]['_func'](**imp_func[inDat_type]['_opt'])
            #100. Only select necessary columns
            .loc[:, select_at].copy(deep=True)
            #300. Fill [NaN] values with 0 to avoid meaningless results
            .fillna(value = { aggrVar : 0 })
            #900. Create identifier of current data within the time series
            .assign(**{
                '.Period' : 'A'
                ,'.date' : L_d_curr
                ,'.N_ORDER' : i
                ,'.Tmp_Val' : lambda x: x[aggrVar].mul(calcMult[L_date])
            })
        )

        #700. Assign additional attributes to the data frame for column class check
        imp_dict = {
            'name' : L_d_curr
            ,'data' : imp_data
            ,'DF_NAME' : inDat_df
        }

        #999. Return the result
        return(imp_dict)

    #550. Create a list of imported data frames and bind all rows of them together as one data frame
    #551. Debug mode
    if fDebug:
        print('['+LfuncName+']'+'Import data files in '+('Parallel' if _parallel else 'Sequential')+' mode...')
    #[IMPOTANT] There could be fields/columns in the same name but not the same types in different data files,
    #            but we throw the errors at the step [pandas.concat] to ask user to correct the input data,
    #            instead of guessing the correct types here, for it takes quite a lot of unnecessary effort.
    if _parallel:
        #100. Set the cores to be used and instantiate a pool
        mychunk = int(np.ceil(n_files / cores))
        #[IMPORTANT] According to below link, we adopt the method of [Parent: ThreadPool] -> [Child: Pool] for multiprocessing
        #Quote: https://izziswift.com/python-process-pool-non-daemonic/
        #[1] [Pool] does not support spawning childs in recursion for good reason
        #[2] [Pool]s from other packages will not function as per test
        #[3] [pathos] functions well as it does not require user-defined requirements to be setup for each [child]
        mypool = ThreadPool(cores)

        #900. Read the files and store the imported data frames into a list
        #Quote: https://stackoverflow.com/questions/15881055/combine-output-multiprocessing-python
        files_import = list(mypool.imap( ABP_parallel, range(n_files), chunksize = mychunk ))

        #990. Complete the Pool stage
        #Quote: https://pathos.readthedocs.io/en/latest/pathos.html#module-pathos.multiprocessing
        mypool.clear()
        mypool.close()
        mypool.join()
        #How to close the multiprocessing pool on exception:
        #Quote[#5]: https://stackoverflow.com/questions/44587669/
        mypool.terminate()
    else:
        #900. Read the files sequentially
        #We do not directly combine the data, for there may be columns with different dtypes.
        files_import = list(map( ABP_parallel, range(n_files) ))

    #560. Check the list of imported data on the classes of columns
    chk_cls = debug_comp_datcols(**{ d['name']:d['data'] for d in files_import })

    #569. Abort the program if any inconsistency is found on columns of data frames
    if len(chk_cls):
        #500. Output a global data frame storing the information of the column inconsistency
        # sys._getframe(1).f_globals.update({ err_cols : chk_cls })
        outDict.update({ err_cols : chk_cls })

        #999. Abort the process
        warn('['+LfuncName+']'+'Some columns cannot be bound due to different dtypes!')
        warn('['+LfuncName+']'+'Check data frame ['+err_cols+'] in the output result for these columns!')
        ABP_errors = True

    #590. Abort the program for certain conditions
    #591. Verify the exit condition from the calculation of the Leading Period
    if fLeadCalc:
        #100. Abort if any columns cannot be concatenated
        if ABP_LeadPeriod.get(err_cols) is not None:
            #500. Output a global data frame storing the information of the column inconsistency
            outDict.update({ err_cols : pd.concat([ABP_LeadPeriod.get(err_cols), outDict.get(err_cols)], ignore_index = True) })

            #999. Abort the process
            warn('['+LfuncName+']'+'Some columns cannot be bound due to different dtypes!')
            warn('['+LfuncName+']'+'Check data frame ['+err_cols+'] in the output result for these columns!')
            ABP_errors = True

    #599. Abort if the flag of errors is True
    if ABP_errors: return(outDict)

    #600. Set all the required data
    #610. Data for the Leading Period
    #The values in this data should be subtracted from those in the Actual Calculation Period
    if fLeadCalc:
        #300. Create a list of unique column names for selection from the input data
        sel_LP = []
        if isinstance(byVar, list):
            sel_LP.extend(byVar)
        else:
            sel_LP.append(byVar)
        #[copyVar] could possibly not be provided
        if copyVar:
            if isinstance(copyVar, list):
                sel_LP.extend(copyVar)
            else:
                sel_LP.append(copyVar)
        #We directly append the predefined column name
        sel_LP.append('.CalcLead.')
        #Dedup
        sel_LP = list(Counter(sel_LP).keys())

        #500. Only retrieve certain columns for Leading Period
        ABP_set_LP = (
            ABP_LeadPeriod.get('data')
            .loc[:, sel_LP]
            .copy(deep=True)
            .fillna(value = { '.CalcLead.' : 0 })
            .assign(**{
                '.Period' : 'L'
                ,'.date' : 'Leading'
                ,'.N_ORDER' : -1
                ,'.Tmp_Val' : lambda x: x['.CalcLead.'].mul(-1)
            })
        )
    else:
        ABP_set_LP = None

    #630. Data for [chkDat], i.e. Checking Period
    if fUsePrev:
        #300. Prepare the function to apply to the process list
        opt_hdfs = {
            'infile' : chkDat
            ,'key' : chkDat_df
        }
        if chkDat_opt.get('HDFS',{}):
            opt_hdfs.update(chkDat_opt.get('HDFS',{}))
        opt_sas = {
            'infile' : chkDat
        }
        if chkDat_opt.get('SAS',{}):
            opt_sas.update(chkDat_opt.get('SAS',{}))
        imp_func = {
            'RAM' : {
                '_func' : std_read_RAM
                ,'_opt' : {
                    'infile' : chkDat
                }
            }
            ,'HDFS' : {
                '_func' : std_read_HDFS
                ,'_opt' : opt_hdfs
            }
            ,'SAS' : {
                '_func' : std_read_SAS
                ,'_opt' : opt_sas
            }
        }

        #500. Call functions to import data from current path
        #510. Create a list of unique column names for selection from the input data
        sel_CP = []
        if isinstance(byVar, list):
            sel_CP.extend(byVar)
        else:
            sel_CP.append(byVar)
        #[copyVar] could possibly not be provided
        if copyVar:
            if isinstance(copyVar, list):
                sel_CP.extend(copyVar)
            else:
                sel_CP.append(copyVar)
        #We directly append [chkDatVar] as it must be the name of a single column as defined by this function
        sel_CP.append(chkDatVar)
        #Dedup
        sel_CP = list(Counter(sel_CP).keys())

        #590. Load the data and conduct the requested transformation
        ABP_set_CP = (
            imp_func[chkDatType]['_func'](**imp_func[chkDatType]['_opt'])
            #100. Only select necessary columns
            .loc[:, sel_CP]
            .copy(deep=True)
            .assign(**{
                '.Period' : 'C'
                ,'.date' : 'Checking'
                ,'.N_ORDER' : 0
                ,'.Tmp_Val' : lambda x: x[chkDatVar].mul(multiplier_CP)
            })
        )
    else:
        ABP_set_CP = None

    #690. Combine the data
    ABP_setall = pd.concat([ d['data'] for d in files_import ] + [ABP_set_LP] + [ABP_set_CP])
    # sys._getframe(1).f_globals.update({ 'chkABP' : ABP_setall })

    #700. Aggregate by the provided function
    #710. Create a list of unique column names for sorting in the input data
    sort_cols = []
    if isinstance(byVar, list):
        sort_cols.extend(byVar)
    else:
        sort_cols.append(byVar)
    #We directly append the predefined column name
    sort_cols.append('.N_ORDER')
    #Dedup
    sort_cols = list(Counter(sort_cols).keys())

    #750. Define the dictionary of columns to be aggregated by certain functions respectively
    #751. Create an empty dict
    out_Aggr = {}

    #755. Only retrieve the last occurrence of [copyVar] for each group
    #[copyVar] could possibly not be provided
    if copyVar:
        if isinstance(copyVar, list):
            out_Aggr.update({ c : _last for c in copyVar })
        else:
            out_Aggr.update({ copyVar : _last })

    #758. Calculate the aggregation of [.Tmp_Val]
    #Ensure [.Tmp_Val] is at the right-most position in the output data frame
    out_Aggr.update({ '.Tmp_Val' : partial(LFuncAggr, **kw) })

    #790. Aggregation
    outDat = (
        ABP_setall
        #100. Sort the data by [byVar] plus [.N_ORDER]
        .sort_values(sort_cols)
        #200. Fill [NaN] values with 0 to avoid meaningless results
        .fillna(value = { '.Tmp_Val' : 0 })
        #400. Aggregate by [byVar] on each date in the first place
        #[1] This is to handle the case when there are multiple records for the same [byVar] on the same date
        #[2] It is tested that any function which accepts [scalar] or [pd.Series] can be applied here, such as [_last] as we defined.
        .groupby(byVar + ['.Period', '.date'], as_index = False, dropna = False)
        .agg(aggrDict)
        #500. Prepare the groups for aggregation
        .groupby(byVar, as_index = False)
        #700. Aggregation by each group
        .agg(out_Aggr)
        #900. Reset index
        .reset_index(drop = True)
        #910. Correct the output value for the function [mean]
        .assign(**{
            outVar : lambda x: x['.Tmp_Val'].div(periodOut if funcAggr in func_means else 1)
        })
        #999. Drop excessive columns
        .drop(columns = ['.Tmp_Val'])
    )

    #999. Return the table
    outDict.update({ 'data' : outDat })
    return(outDict)
#End aggrByPeriod

'''
#-Notes- -Begin-
#[Concept]
%*--  Below For Period Description  ------------------------------------------------------------------------------------------;
[1] The entire period of dates to be involved in this calculation process can be split into below sections:

  [chkBgn]             [dateBgn]                                                       [chkEnd]                       [dateEnd]
 /                      /                                                                 \                                \
|--Leading Period [L]--|                                                                   \                                \
|------------------------------------------Checking Period [C]------------------------------|                                \
                       |----------------------------------New Calculation Period [N]------------------------------------------|
                                                       ( Figure 1 )

[2] Given the dataset [C] exists and Len([C]) = Len([N]), the Actual Calculation Period [A] is set as below:

|------------------------------------------Checking Period [C]------------------------------|
                       |----------------------------------New Calculation Period [N]------------------------------------------|
                                                                                            |--Actual Calculation Period [A]--|
                                                                                           /                                 /
                                                                                        [actBgn]                       [actEnd]
                                                       ( Figure 2 )

[3] Given the dataset [C] does not exist or Len([C]) ^= Len([N]), the Actual Calculation Period [A] is set the same as [N].

[4] The final involvement of sections is as below: (by setting datasets of all sections)
Output = [funcAggr]( [L] (if any, needs to be subtracted) + [C] (if any) + [A] )

%*--  Below For Terminology  -------------------------------------------------------------------------------------------------;
[L]   : It may not exist, depending on the value of [chkBgn], but has to be subtracted from [C] for SUM or MEAN functions.
[C]   : In a continuous process, such as ANR calculation, the result on each date is stored, and we will check them each time
         we conduct a new round of calculation.
[N]   : Current period within which we intend to conduct calculation.
[A]   : The actual involvement of basic daily KPI data.
Len() : The # of dates that a specific period covers, depending on whether [calcInd] indicates to use Calendar Day or Workday.

%*--  When to SKIP calculation of Leading Period [L]  ------------------------------------------------------------------------;
If any of below conditions is tiggered, we will NOT take the Leading Period into account.
[1] : [chkBgn] >= [dateBgn]. Obviously the date span of Leading Period is 0. (See [Figure 1] above)
[2] : [chkBgn] <  [dateBgn] while Len([C]) ^= Len([N]). e.g. if dataset [ANR20170831] was calculated out of 6 calendar
       days from [Bal20170826] to [Bal20170831], while we only need to calculate [ANR20170901] out of the series of datasets
       [Bal20170828-Bal20170901], then we will not leverage [ANR20170831] to calculate [ANR20170901].
[3] : [funcAggr] does NOT represent [SUM] or [MEAN]. e.g. if the [MAX] value lies in the Leading Period, it cannot be involved
       in any period later than the end of the Leading Period.
[4] : [chkDatPtn] is NOT provided.
[5] : Resolved [chkDatPtn] DOES NOT exist as a data source.

%*--  When to SKIP the involvement of Checking Period [C]  -------------------------------------------------------------------;
If any of below conditions is tiggered, we will NOT take the Checking Period into account.
[1] : [chkDatPtn] is NOT provided.
[2] : Resolved [chkDatPtn] DOES NOT exist as a data source.
[3] : [chkBgn] > [chkEnd] which indicates a non-existing period to be involved.

%*--  Calculation Process  ---------------------------------------------------------------------------------------------------;
[1] : If [L] should be involved, call the same macro to calculate the aggregation summary for [L], for later subtraction.
      The intermediate result in such case is marked as [L1].
      If [funcAggr] represents [MEAN], [L1] should be calculated by [SUM] instead for subtraction purpose.
[2] : Aggregate all datasets to be used in [A] by the specified [byVar] respectively, to avoid any possible erroneous result.
[3] : Set all required datasets together: (1) [L1] if any, (2) [C] if any, (3) the series of datasets generated in step [2].
[4] : Apply multiplier to above sections: (1) is multiplied by -1 since it is to be subtracted, (2) is multiplied by 1 or
       Len([C]) depending on whether the function [funcAggr] represents [MEAN], (3) is always multiplied by 1.
[5] : Sum up the values in all above observations if [funcAggr] represents [MEAN] or [SUM], while resolve the [MIN] or [MAX]
       values if otherwise, and at last, divide the summed value by Len([N]) if [funcAggr] represents [MEAN].

#[Index of Examples]
%*100. Data Preparation.;
%*110. Create Calendar dataset.;
%*120. Retrieve all date information for the period of 20160229 to 20160603.;
%*130. Create the test KPI tables.;
%*150. Retrieve all date information for the period of 20160901 to 20161201.;
%*170. Create the test KPI tables.;

%*200. Using the same Beginning of a series of periods.;
%*210. Mean of all Calendar Days from 20160501 to 20160516.;
%*220. Mean of all Calendar Days from 20160501 to 20160517.;
%*230. Mean of all Working Days from 20160501 to 20160516.;
%*240. Mean of all Working Days from 20160501 to 20160517.;
%*250. Max of all Calendar Days from 20160501 to 20160516.;
%*260. Max of all Calendar Days from 20160501 to 20160517.;
%*270. Max of all Working Days from 20160501 to 20160516.;
%*280. Max of all Working Days from 20160501 to 20160517.;

%*300. Rolling 10 days.;
%*310. Mean of all Calendar Days from 20160401 to 20160410.;
%*311. Mean of all Calendar Days from 20160402 to 20160411.;
%*312. Mean of all Calendar Days from 20160403 to 20160412.;

%*400. Rolling 5 Working Days.;
%*410. Mean of all Working Days from 20160401 to 20160408.;
%*411. Mean of all Working Days from 20160401 to 20160409.;
%*412. Mean of all Working Days from 20160405 to 20160411.;

%*430. Rolling 5 Trade Days.;
%*431. Mean of all Trade Days from 20160926 to 20161008.;
%*432. Mean of all Trade Days from 20160926 to 20161009.;
%*433. Mean of all Trade Days from 20160927 to 20161010.;
%*434. Mean of all Trade Days from 20160928 to 20161011.;

%*500. Using the same Beginning of a series of periods.;
%*510. Mean of all Calendar Days from 20160901 to 20160910.;
%*520. Mean of all Calendar Days from 20160901 to 20160911.;
%*530. Mean of all Working Days from 20160901 to 20160911.;
%*540. Mean of all Working Days from 20160901 to 20160912.;
%*550. Max of all Calendar Days from 20161001 to 20161010.;
%*560. Max of all Calendar Days from 20161001 to 20161011.;
%*570. Min of all Working Days from 20161001 to 20161010.;
%*580. Min of all Working Days from 20161001 to 20161011.;

%*600. Rolling 5 Calendar Days.;
%*610. Mean of all Calendar Days from 20161007 to 20161011.;
%*611. Mean of all Calendar Days from 20161008 to 20161012.;
%*612. Mean of all Calendar Days from 20161009 to 20161013.;

%*700. Rolling 5 Working Days.;
%*710. Mean of all Working Days from 20160930 to 20161011.;
%*711. Mean of all Working Days from 20161007 to 20161012.;
%*712. Mean of all Working Days from 20161008 to 20161013.;
%*713. Mean of all Working Days from 20161010 to 20161014, with a data frame provided as [inDatPtn];

#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys, os
    import numpy as np
    import pandas as pd
    import datetime as dt
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import exec_file, modifyDict
    from omniPy.AdvDB import aggrByPeriod
    from omniPy.Dates import asDates, ObsDates

    #010. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Set the default arguments for all test cases
    opt_def_ABP = {
        'inDatPtn' : r'D:\R\omniR\SampleKPI\testAggr\kpi&L_curdate..sas7bdat'
        ,'inDatType' : 'SAS'
        ,'in_df' : None
        ,'fImp_opt' : {
            'SAS' : {
                'encoding' : 'GB2312'
            }
        }
        ,'fTrans' : getOption['fmt.def.GTSFK']
        ,'fTrans_opt' : getOption['fmt.opt.def.GTSFK']
        ,'_parallel' : False
        ,'cores' : 4
        ,'chkDatType' : 'RAM'
        ,'byVar' : ['nc_cifno','nc_acct_no']
        ,'copyVar' : 'C_KPI_ID'
        ,'aggrVar' : 'A_KPI_VAL'
        ,'genPHMul' : True
        ,'calcInd' : 'C'
        ,'funcAggr' : np.mean
        ,'miss_files' : 'G_miss_files'
        ,'err_cols' : 'G_err_cols'
        ,'outDTfmt' : getOption['fmt.parseDates']
    }

    #200. Using the same Beginning of a series of periods
    #210. Mean of all Calendar Days from 20160501 to 20160516
    if True:
        DtBgn = asDates('20160501')
        DtEnd = asDates('20160516')
        args_ABP_CMEAN = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'avgKpi&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : DtBgn
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'avgKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((24*2+23+22+21+20*3+19+18+17+16+15*3+14)/16)

    #220. Mean of all Calendar Days from 20160501 to 20160517
    if True:
        DtEnd = asDates('20160517')
        args_ABP_CMEAN = modifyDict(
            args_ABP_CMEAN
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'avgKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((24*2+23+22+21+20*3+19+18+17+16+15*3+14+13)/17)

    #230. Mean of all Working Days from 20160501 to 20160516
    if True:
        DtBgn = asDates('20160501')
        DtEnd = asDates('20160516')
        args_ABP_WMEAN = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'WDavgKpi&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : DtBgn
                ,'calcInd' : 'W'
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'WDavgKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((23+22+21+20+19+18+17+16+15+14)/10)

    #240. Mean of all Working Days from 20160501 to 20160517
    if True:
        DtEnd = asDates('20160517')
        args_ABP_WMEAN = modifyDict(
            args_ABP_WMEAN
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'WDavgKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((23+22+21+20+19+18+17+16+15+14+13)/11)

    #250. Max of all Calendar Days from 20160501 to 20160516
    if True:
        DtBgn = asDates('20160501')
        DtEnd = asDates('20160516')
        args_ABP_CMAX = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'CDmaxKpi&L_curdate.'
                ,'chkDatVar' : 'A_KPI_MAX'
                ,'chkBgn' : DtBgn
                ,'funcAggr' : max
                ,'outVar' : 'A_KPI_MAX'
                ,'fDebug' : False
            }
        )
        outdat = 'CDmaxKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_CMAX).get('data') })
        print(globals()[outdat]['A_KPI_MAX'])
        print(max(24,23,22,21,20,19,18,17,16,15,14))

    #260. Max of all Calendar Days from 20160501 to 20160517
    if True:
        DtEnd = asDates('20160517')
        args_ABP_CMAX = modifyDict(
            args_ABP_CMAX
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'CDmaxKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_CMAX).get('data') })
        print(globals()[outdat]['A_KPI_MAX'])
        print(max(24,23,22,21,20,19,18,17,16,15,14,13))

    #270. Max of all Working Days from 20160501 to 20160516
    if True:
        DtBgn = asDates('20160501')
        DtEnd = asDates('20160516')
        args_ABP_WMAX = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'WDmaxKpi&L_curdate.'
                ,'chkDatVar' : 'A_KPI_MAX'
                ,'chkBgn' : DtBgn
                ,'calcInd' : 'W'
                ,'funcAggr' : np.max
                ,'outVar' : 'A_KPI_MAX'
                ,'fDebug' : False
            }
        )
        outdat = 'WDmaxKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_WMAX).get('data') })
        print(globals()[outdat]['A_KPI_MAX'])
        print(max(23,22,21,20,19,18,17,16,15,14))

    #280. Max of all Working Days from 20160501 to 20160517
    if True:
        DtEnd = asDates('20160517')
        args_ABP_WMAX = modifyDict(
            args_ABP_WMAX
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'WDmaxKpi' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_WMAX).get('data') })
        print(globals()[outdat]['A_KPI_MAX'])
        print(max(23,22,21,20,19,18,17,16,15,14,13))

    #300. Rolling 10 days
    #310. Mean of all Calendar Days from 20160401 to 20160410
    if True:
        DtBgn = asDates('20160401')
        DtEnd = asDates('20160410')
        pDate = DtBgn - dt.timedelta(days=1)
        args_ABP_roll_CMEAN = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'R10ANR&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : pDate
                ,'calcInd' : 'C'
                ,'funcAggr' : np.mean
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'R10ANR' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((25*4+26+27+28+29*3)/10)

    #311. Mean of all Calendar Days from 20160402 to 20160411
    if True:
        DtBgn = asDates('20160402')
        DtEnd = asDates('20160411')
        pDate = DtBgn - dt.timedelta(days=1)
        args_ABP_roll_CMEAN = modifyDict(
            args_ABP_roll_CMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R10ANR' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((25*3+26+27+28+29*3+30)/10)

    #312. Mean of all Calendar Days from 20160403 to 20160412
    if True:
        DtBgn = asDates('20160403')
        DtEnd = asDates('20160412')
        pDate = DtBgn - dt.timedelta(days=1)
        args_ABP_roll_CMEAN = modifyDict(
            args_ABP_roll_CMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R10ANR' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((25*2+26+27+28+29*3+30+31)/10)

    #400. Rolling 5 Working Days
    L_obsDates = ObsDates(obsDate = '20160401', clnBgn = '20160301', clnEnd = '20160601')

    #410. Mean of all Working Days from 20160401 to 20160408
    if True:
        DtEnd = asDates('20160408')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -4, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        args_ABP_roll_WMEAN = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'R5WMEAN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : pDate
                ,'calcInd' : 'W'
                ,'funcAggr' : np.mean
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'R5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((25+26+27+28+29)/5)

    #411. Mean of all Working Days from 20160401 to 20160409
    if True:
        DtEnd = asDates('20160409')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -6, preserve = False, daytype = 'W')[0]
        args_ABP_roll_WMEAN = modifyDict(
            args_ABP_roll_WMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((25+26+27+28+29)/5)

    #412. Mean of all Working Days from 20160405 to 20160411
    if True:
        DtEnd = asDates('20160411')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -4, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        args_ABP_roll_WMEAN = modifyDict(
            args_ABP_roll_WMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((26+27+28+29+30)/5)

    #430. Rolling 5 Trade Days
    L_obsDates = ObsDates(obsDate = '20160930', clnBgn = '20160901', clnEnd = '20161101')

    #431. Mean of all Trade Days from 20160926 to 20161008
    if True:
        DtEnd = asDates('20161008')
        L_obsDates.values = DtEnd
        L_kshift = 0 if L_obsDates.isTradeDay[0] else 1
        DtBgn = L_obsDates.shiftDays(kshift = -4 - L_kshift, preserve = False, daytype = 'T')[0]
        pDate = L_obsDates.shiftDays(kshift = -5 - L_kshift, preserve = False, daytype = 'T')[0]
        args_ABP_roll_TMEAN = modifyDict(
            opt_def_ABP
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'R5TMEAN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : pDate
                ,'calcInd' : 'T'
                ,'funcAggr' : np.mean
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'R5TMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_TMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((26+27+28+29+30)/5)

    #432. Mean of all Trade Days from 20160926 to 20161009
    if True:
        DtEnd = asDates('20161009')
        L_obsDates.values = DtEnd
        L_kshift = 0 if L_obsDates.isTradeDay[0] else 1
        DtBgn = L_obsDates.shiftDays(kshift = -4 - L_kshift, preserve = False, daytype = 'T')[0]
        pDate = L_obsDates.shiftDays(kshift = -5 - L_kshift, preserve = False, daytype = 'T')[0]
        args_ABP_roll_TMEAN = modifyDict(
            args_ABP_roll_TMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R5TMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_TMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((26+27+28+29+30)/5)

    #433. Mean of all Trade Days from 20160927 to 20161010
    if True:
        DtEnd = asDates('20161010')
        L_obsDates.values = DtEnd
        L_kshift = 0 if L_obsDates.isTradeDay[0] else 1
        DtBgn = L_obsDates.shiftDays(kshift = -4 - L_kshift, preserve = False, daytype = 'T')[0]
        pDate = L_obsDates.shiftDays(kshift = -5 - L_kshift, preserve = False, daytype = 'T')[0]
        args_ABP_roll_TMEAN = modifyDict(
            args_ABP_roll_TMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R5TMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_TMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((27+28+29+30+40)/5)

    #434. Mean of all Trade Days from 20160928 to 20161011
    #This step is to test the utilization of the calculation result of the previous Trade Day
    if True:
        DtEnd = asDates('20161011')
        L_obsDates.values = DtEnd
        L_kshift = 0 if L_obsDates.isTradeDay[0] else 1
        DtBgn = L_obsDates.shiftDays(kshift = -4 - L_kshift, preserve = False, daytype = 'T')[0]
        pDate = L_obsDates.shiftDays(kshift = -5 - L_kshift, preserve = False, daytype = 'T')[0]
        args_ABP_roll_TMEAN = modifyDict(
            args_ABP_roll_TMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'R5TMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_ABP_roll_TMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((28+29+30+40+41)/5)

    #500. Using the same Beginning of a series of periods
    #Below For [genPHMul = False]
    args_ABP_noMul = modifyDict( opt_def_ABP, { 'genPHMul' : False } )

    #510. Mean of all Calendar Days from 20160901 to 20160910
    if True:
        DtBgn = asDates('20160901')
        DtEnd = asDates('20160910')
        args_noMul_CMEAN = modifyDict(
            args_ABP_noMul
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'CCMEAN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : DtBgn
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'CCMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((1+2+3+4+5+6+7+8+9+10)/10)

    #520. Mean of all Calendar Days from 20160901 to 20160911
    if True:
        DtEnd = asDates('20160911')
        args_noMul_CMEAN = modifyDict(
            args_noMul_CMEAN
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'CCMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((1+2+3+4+5+6+7+8+9+10+11)/11)

    #530. Mean of all Working Days from 20160901 to 20160911
    if True:
        DtBgn = asDates('20160901')
        DtEnd = asDates('20160911')
        args_noMul_WMEAN = modifyDict(
            args_ABP_noMul
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'CWMEAN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : DtBgn
                ,'calcInd' : 'W'
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'CWMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((1+2+5+6+7+8+9)/7)

    #540. Mean of all Working Days from 20160901 to 20160912
    if True:
        DtEnd = asDates('20160912')
        args_noMul_WMEAN = modifyDict(
            args_noMul_WMEAN
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'CWMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((1+2+5+6+7+8+9+12)/8)

    #550. Max of all Calendar Days from 20161001 to 20161010
    if True:
        DtBgn = asDates('20161001')
        DtEnd = asDates('20161010')
        args_noMul_CMAX = modifyDict(
            args_ABP_noMul
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'CCMAX&L_curdate.'
                ,'chkDatVar' : 'A_KPI_MAX'
                ,'chkBgn' : DtBgn
                ,'funcAggr' : max
                ,'outVar' : 'A_KPI_MAX'
                ,'fDebug' : False
            }
        )
        outdat = 'CCMAX' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_CMAX).get('data') })
        print(globals()[outdat]['A_KPI_MAX'])
        print(max(31,32,33,34,35,36,37,38,39,40))

    #560. Max of all Calendar Days from 20161001 to 20161011
    if True:
        DtEnd = asDates('20161011')
        args_noMul_CMAX = modifyDict(
            args_noMul_CMAX
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'CCMAX' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_CMAX).get('data') })
        print(globals()[outdat]['A_KPI_MAX'])
        print(max(31,32,33,34,35,36,37,38,39,40,41))

    #570. Min of all Working Days from 20161001 to 20161010
    if True:
        DtBgn = asDates('20161001')
        DtEnd = asDates('20161010')
        args_noMul_WMIN = modifyDict(
            args_ABP_noMul
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'CWMIN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_MIN'
                ,'chkBgn' : DtBgn
                ,'calcInd' : 'W'
                ,'funcAggr' : min
                ,'outVar' : 'A_KPI_MIN'
                ,'fDebug' : False
            }
        )
        outdat = 'CWMIN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_WMIN).get('data') })
        print(globals()[outdat]['A_KPI_MIN'])
        print(min(38,39,40))

    #580. Min of all Working Days from 20161001 to 20161011
    if True:
        DtEnd = asDates('20161011')
        args_noMul_WMIN = modifyDict(
            args_noMul_WMIN
            ,{
                'dateEnd' : DtEnd
            }
        )
        outdat = 'CWMIN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_WMIN).get('data') })
        print(globals()[outdat]['A_KPI_MIN'])
        print(min(38,39,40,41))

    #600. Rolling 5 Calendar Days
    #610. Mean of all Calendar Days from 20161007 to 20161011
    if True:
        DtBgn = asDates('20161007')
        DtEnd = asDates('20161011')
        pDate = DtBgn - dt.timedelta(days=1)
        args_noMul_roll_CMEAN = modifyDict(
            args_ABP_noMul
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'RC5CMEAN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : pDate
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'RC5CMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((37+38+39+40+41)/5)

    #611. Mean of all Calendar Days from 20161008 to 20161012
    if True:
        DtBgn = asDates('20161008')
        DtEnd = asDates('20161012')
        pDate = DtBgn - dt.timedelta(days=1)
        args_noMul_roll_CMEAN = modifyDict(
            args_noMul_roll_CMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'RC5CMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((38+39+40+41+42)/5)

    #612. Mean of all Calendar Days from 20161009 to 20161013
    if True:
        DtBgn = asDates('20161009')
        DtEnd = asDates('20161013')
        pDate = DtBgn - dt.timedelta(days=1)
        args_noMul_roll_CMEAN = modifyDict(
            args_noMul_roll_CMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'RC5CMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_CMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((39+40+41+42+43)/5)

    #700. Rolling 5 Working Days
    L_obsDates = ObsDates(obsDate = '20160930', clnBgn = '20160901', clnEnd = '20161101')

    #710. Mean of all Working Days from 20160930 to 20161011
    if True:
        DtEnd = asDates('20161011')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -4, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        args_noMul_roll_WMEAN = modifyDict(
            args_ABP_noMul
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkDatPtn' : 'RC5WMEAN&L_curdate.'
                ,'chkDatVar' : 'A_KPI_ANR'
                ,'chkBgn' : pDate
                ,'calcInd' : 'W'
                ,'funcAggr' : np.mean
                ,'outVar' : 'A_KPI_ANR'
                ,'fDebug' : False
            }
        )
        outdat = 'RC5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((30+38+39+40+41)/5)

    #711. Mean of all Working Days from 20161007 to 20161012
    if True:
        DtEnd = asDates('20161012')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -4, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        args_noMul_roll_WMEAN = modifyDict(
            args_noMul_roll_WMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'RC5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((38+39+40+41+42)/5)

    #712. Mean of all Working Days from 20161008 to 20161013
    if True:
        DtEnd = asDates('20161013')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -4, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        args_noMul_roll_WMEAN = modifyDict(
            args_noMul_roll_WMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
            }
        )
        outdat = 'RC5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((39+40+41+42+43)/5)

    #713. Mean of all Working Days from 20161010 to 20161014, with a data frame provided as [inDatPtn]
    if True:
        DtEnd = asDates('20161014')
        L_obsDates.values = DtEnd
        DtBgn = L_obsDates.shiftDays(kshift = -4, preserve = False, daytype = 'W')[0]
        pDate = L_obsDates.shiftDays(kshift = -5, preserve = False, daytype = 'W')[0]
        datCfg = pd.DataFrame(
            {
                'FilePath' : args_noMul_roll_WMEAN['inDatPtn']
                ,'PathSeq' : pd.Series(1, dtype = 'int8')
                ,'FileName' : os.path.basename(args_noMul_roll_WMEAN['inDatPtn'])
                ,'chkType' : args_noMul_roll_WMEAN['inDatType']
                ,'chkdf' : None
            }
            ,index = [0]
        )
        args_noMul_roll_WMEAN = modifyDict(
            args_noMul_roll_WMEAN
            ,{
                'dateBgn' : DtBgn
                ,'dateEnd' : DtEnd
                ,'chkBgn' : pDate
                ,'inDatPtn' : datCfg
                ,'inDatType' : 'chkType'
                ,'in_df' : 'chkdf'
            }
        )
        outdat = 'RC5WMEAN' + DtEnd.strftime('%Y%m%d')
        globals().update({ outdat : aggrByPeriod(**args_noMul_roll_WMEAN).get('data') })
        print(globals()[outdat]['A_KPI_ANR'])
        print((40+41+42+43+44)/5)
#-Notes- -End-
'''
