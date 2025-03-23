#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os, ast
import warnings
import datetime as dt
import numpy as np
import pandas as pd
from functools import partial
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from collections.abc import Iterable
from typing import Optional, Union, Any
from omniPy.Dates import asDates, UserCalendar, ObsDates, intnx
from omniPy.AdvOp import modifyDict, vecStack
from omniPy.AdvDB import parseDatName, DataIO, DBuse_GetTimeSeriesForKpi, aggrByPeriod, validateDMCol

def kfCore_ts_agg(
    inKPICfg : pd.DataFrame = None
    ,mapper : pd.DataFrame = None
    ,dateBgn : str | dt.date = None
    ,dateEnd : str | dt.date = None
    ,chkBgn : str | dt.date = None
    ,_parallel : bool = False
    ,cores : int = 4
    ,aggrVar : str = 'A_KPI_VAL'
    ,byVar : Union[str, Iterable[str]] = None
    ,copyVar : Union[str, Iterable[str]] = None
    ,tableVar : str = 'D_TABLE'
    ,genPHMul : bool = True
    ,calcInd : str = 'C'
    ,funcAggr : callable = np.nanmean
    ,fDebug : bool = False
    ,fTrans : Optional[dict] = None
    ,fTrans_opt : dict = {}
    ,outDTfmt : dict = {
        'L_d_curr' : '%Y%m%d'
        ,'L_m_curr' : '%Y%m'
    }
    #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
    ,kw_d : dict = { s.name : s.default for s in signature(asDates).parameters.values() if s.name not in ['indate'] }
    ,kw_cal : dict = {
        s.name : s.default
        for s in signature(UserCalendar).parameters.values()
        if s.name not in ['dateBgn', 'dateEnd', 'clnBgn', 'clnEnd']
    }
    ,kw_DataIO : dict = {}
    ,**kw
) -> pd.DataFrame:
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
#   |[1] Naming: <K>PI <F>actory <CORE> function to provide <T>ime <S>eries algorithms in terms of <AGG>regation methods                #
#   |[2] KPIs listed in the mapper (on both sides) MUST have been registered in <inKPICfg>                                              #
#   |[3] <D_BGN> of the aggregated KPI must be equal to or later than that of its corresponding Daily Snapshot KPI                      #
#   |[4] Since <aggrByPeriod> does not verify <D_BGN>, please ensure NO DATA EXISTS for the registered Daily Snapshot KPIs before their #
#   |     respective <D_BGN>; otherwise those existing datasets will be inadvertently involved during aggregation                       #
#   |[5] This function is the low level interface of calculation over the period during time series aggregation                         #
#   |[6] One can realize various aggregation algorithms by providing customized <dateBgn>, <dateEnd> and <chkBgn>, with the common      #
#   |     modifiers as <genPHMul>, <calcInd> and <funcAggr>. See high level interfaces <kfFunc_ts_*> for demonstration                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FUNCTION]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Map the various aggregation of KPIs listed on the left side of <mapper> to those on the right side of it                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate MTD ANR of product holding balances along the time series, by recognizing the data on each weekend as the same as    #
#   |     its previous workday, also leveraging the aggregation result on its previous workday                                          #
#   |[2] Calculate rolling period MAX of product holding balances along the time series, for the similar case as above                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |110.   Input dataset information                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKPICfg    :   The dataset that stores the full configuration of the KPI. It MUST contain below fields:                           #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |D_BGN           |No         | Beginning date of the KPI data file existence                                       #
#   |                |D_END           |No         | Ending date of the KPI data file existence                                          #
#   |                |C_KPI_ID        |No         | KPI ID used as part of keys for mapping and aggregation                             #
#   |                |F_KPI_INUSE     |No         | Column of type <int> indicating whether the KPI is in use for current database, as  #
#   |                |                |           |  filter condition in the process                                                    #
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
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |mapper      :   Mapper from Daily KPI ID to aggregated KPI ID as a dataset. It MUST contain below fields:                          #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |mapper_fr       |No         | ID of (usually) Daily Snapshot KPI, in the same type as <C_KPI_ID> in <inKPICfg>    #
#   |                |mapper_to       |No         | ID of aggregated KPI, in the same type as <C_KPI_ID> in <inKPICfg>                  #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |120.   Naming pattern translation/mapping                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fTrans      :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process   #
#   |                [None            ] <Default> For time series process, please ensure this argument is manually defined, otherwise   #
#   |                                              the result is highly unexpected                                                      #
#   |fTrans_opt  :   Additional options for value translation on [fTrans], see document for [AdvOp.apply_MapVal]                        #
#   |                [{}              ] <Default> Use default options in [apply_MapVal]                                                 #
#   |                [<dict>          ]           Use alternative options as provided by a dict, see documents of [apply_MapVal]        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |130.   Multi-processing support                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |_parallel   :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but may be slow for small ones #
#   |                [False           ]  <Default> Load the data files sequentially                                                     #
#   |                [True            ]            Use multiple CPU cores to load the data files in parallel. When using this option,   #
#   |                                               please ensure correct environment is passed to <kw_DataIO> for API searching, given #
#   |                                               that RAM is the requested location for search                                       #
#   |cores       :   Number of system cores to read the data files in parallel                                                          #
#   |                [4               ] <Default> No need when [_parallel=False]                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |150.   Calculation period control                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dateBgn     :   Beginning of the calculation period. It will be converted to [Date] by [Dates.asDates] internally, hence please    #
#   |                 follow the syntax of this function during input                                                                   #
#   |                [None            ] <Default> Function will raise error if it is NOT provided                                       #
#   |dateEnd     :   Ending of the calculation period. It will be converted to [Date] by [Dates.asDates] internally, hence please       #
#   |                 follow the syntax of this function during input                                                                   #
#   |                [None            ] <Default> Function will raise error if it is NOT provided                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |160.   Retrieval of previously aggregated result for Checking Period                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |chkBgn      :   Beginning of the Checking Period. It will be converted to [Date] by [Dates.asDates] internally, hence please       #
#   |                 follow the syntax of this function during input                                                                   #
#   |                [None            ] <Default> Function will set it the same as [dateBgn]                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |170.   Column inclusion                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |byVar       :   The list/vector of column names that are to be used as the group to aggregate the KPI                              #
#   |                [None            ] <Default> Function will raise error if it is NOT provided                                       #
#   |                [list[col. name] ]           <list> of column names                                                                #
#   |copyVar     :   The list/vector of column names that are to be copied during the aggregation                                       #
#   |                [Note 1] Only those values in the Last Existing observation/record can be copied to the output                     #
#   |                [None            ] <Default> There is no additional column to be retained for the output                           #
#   |                [_all_           ]           Retain all related columns from all sources                                           #
#   |                [list[col. name] ]           <list> of column names                                                                #
#   |aggrVar     :   The single column name in the KPI data file that represents the value to be applied by function [funcAggr]         #
#   |                [A_KPI_VAL       ] <Default> Function will aggregate this column                                                   #
#   |tableVar    :   The single column name in the KPI data file that represents the table creation date as Time Series Convention      #
#   |                [D_TABLE         ] <Default> Function will update this column with <dateEnd>                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |180.   Indicators and methods for aggregation                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |genPHMul    :   Whether to generate the data on Public Holidays by resembling their respective Previous Workdays/Tradedays with    #
#   |                 proper Multipliers, to minimize the system effort                                                                 #
#   |                [True            ] <Default> Resemble the data on Public Holidays with their respective Previous Workdays/Tradedays#
#   |                                             in terms of the indicator [calcInd]                                                   #
#   |                                             [IMPORTANT] Function will ignore any existing data on Public Holidays                 #
#   |                [False           ]           Function will NOT generate pseudo data for Public Holidays                            #
#   |                                             [IMPORTANT] Function will raise error if there is no existing data on Public Holidays #
#   |calcInd     :   The indicator for the function to calculate based on Calendar Days, Workdays or Tradedays                          #
#   |                [C               ] <Default> Conduct calculation based on Calendar Days                                            #
#   |                [W               ]           Conduct calculation based on Workdays. Namingly, [genPHMul] will hence take no effect #
#   |                [T               ]           Conduct calculation based on Tradedays. Namingly, [genPHMul] will hence take no effect#
#   |funcAggr    :   The function to aggregate the input time series data. It should be provided a [function]                           #
#   |                [IMPORTANT] All [NaN] values are excluded as they create meaningless results for all aggregation functions         #
#   |                [np.nanmean      ] <Default> Calculate the average of [aggrVar] per [byVar] as a time series, with NaN removed     #
#   |                [<other aggr.>   ]           Other aggregation functions that are supported in current environment                 #
#   |                                             [IMPORTANT] One can define specific aggregation function and use it here              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fDebug      :   The switch of Debug Mode. Valid values are [F] or [T].                                                             #
#   |                [False           ] <Default> Do not print debug messages during calculation                                        #
#   |                [True            ]           Print debug messages during calculation                                               #
#   |outDTfmt    :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                   #
#   |                [ <dict>         ] <Default> See the function definition as the default argument of usage                          #
#   |kw_d        :   Arguments for function [Dates.asDates] to convert the [indate] where necessary                                     #
#   |                [<see def.>      ] <Default> Use the default arguments for [asDates]                                               #
#   |kw_cal      :   Arguments for instantiating the class [Dates.UserCalendar] if [cal] is NOT provided                                #
#   |                [<see def.>      ] <Default> Use the default arguments for [UserCalendar]                                          #
#   |kw_DataIO   :   Arguments to instantiate <DataIO>                                                                                  #
#   |                [ empty-<dict>   ] <Default> See the function definition as the default argument of usage                          #
#   |kw          :   Any other arguments that are required by [funcAggr]. Please check the documents for it before defining this one    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[DataFrame] :   Data Frame indicating the process result with below columns:                                                       #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |FilePath        |No         | Absolute path of the data files that are written by this process                    #
#   |                |                |           | When file type is <RAM>, it represents the object name in current session           #
#   |                |C_KPI_FILE_TYPE |No         | Same column retained from <inKPICfg>                                                #
#   |                |rc              |Yes        | Return code from the I/O, 0 indicates success, otherwise there are errors           #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240114        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240203        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now only create local variables within current frame, to avoid environment pollution                                    #
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
#   |   |sys, os, ast, datetime, numpy, pandas, functools, inspect, collections, warnings, typing                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#   |   |   |intnx                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |modifyDict                                                                                                                 #
#   |   |   |vecStack                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |validateDMCol                                                                                                              #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_GetTimeSeriesForKpi                                                                                                  #
#   |   |   |aggrByPeriod                                                                                                               #
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

    #020. Local environment
    #Below variable indicates the API name that can pull from or push to the file with specific <keys>
    keep_all_col = '_ALL_' in [ h_convStr(v, func = str.upper) for v in copyVar ]
    hasKeys = ['HDFS']
    byInt = list(set(byVar + ['C_KPI_ID']))
    cfg_unique_row = ['C_KPI_ID','N_LIB_PATH_SEQ']
    dateBgn_d = asDates(dateBgn, **kw_d)
    dateEnd_d = asDates(dateEnd, **kw_d)
    inObs = ObsDates(obsDate = dateEnd_d, **kw_cal)
    if chkBgn is None:
        if fDebug:
            print(f'[{LfuncName}]<chkBgn> is not provided, set it the same as <dateBgn>')
        chkBgn_d = dateBgn_d
    else:
        chkBgn_d = asDates(chkBgn, **kw_d)
    vfy_ci = fTrans_opt.get('ignore_case', True)
    if not vfy_ci:
        print(
            f'[{LfuncName}]<fTrans_opt> indicates NOT to ignore case'
            +', which is omitted as the function capitalizes pathnames during aggregation'
        )
    int_sfx = '&kfcoredate.'
    if int_sfx not in fTrans:
        fTrans = {
            int_sfx : 'core_curr___'
            ,**{ k:v for k,v in fTrans.items() }
        }
        if 'core_curr___' not in outDTfmt:
            outDTfmt = {
                'core_curr___' : '%Y%m%d'
                ,**{ k:v for k,v in outDTfmt.items() }
            }

    #021. Instantiate the IO operator for data migration
    #[ASSUMPTION]
    #[1] We use separate IO tool for all internal process where necessary, to avoid unexpected result
    dataIO = DataIO(**kw_DataIO)
    dataIO_int = DataIO(**kw_DataIO)

    #050. Determine <chkEnd> by the implication of <genPHMul>
    if genPHMul:
        chkEnd = (
            inObs.shiftDays(kshift = -1, preserve = False, daytype = ('W' if calcInd=='C' else calcInd))[0]
            .strftime('%Y%m%d')
        )
    else:
        chkEnd = (
            intnx('day', dateEnd_d, -1, daytype = 'C', kw_cal = kw_cal)
            .strftime('%Y%m%d')
        )

    #060. Identify the date that the latest Daily KPI dataset exists
    #[ASSUMPTION]
    #[1] Below variable is actually of no use as we abandoned the search for column attribute in the source data file
    #[2] For almost all APIs other than SAS, column length is always the largest while column format takes no effect for data management
    if (not genPHMul) & (calcInd == 'C'):
        aggdaily = dateEnd_d
    else:
        #[ASSUMPTION]
        #[1] Functionality of <Preservance> is the key to below process
        #[2] This restricts the usage of the source data, only when they are designed to exist
        if calcInd != 'C':
            aggdaily = inObs.shiftDays(kshift = -1, preserve = True, daytype = calcInd)[0]
        else:
            #[ASSUMPTION]
            #[1] In such case, we never know whether to predate by Workdays or Tradedays
            #[2] # Workdays is more than # Tradedays in the same period, hence we replicate the data on holidays with the data
            #     on Workdays
            #[3] When there is clear requirement to replicate the data on onlidays by that on Tradedays, try to modify the
            #     Calendar Adjustment data by setting all Workdays to the same as Tradedays BEFORE calling this process
            aggdaily = inObs.shiftDays(kshift = -1, preserve = True, daytype = 'W')[0]

    #080. Get the signature of the core function
    sig_agg = signature(aggrByPeriod).parameters.values()
    kw_agg_raw = {
        s.name : s.default
        for s in sig_agg
        if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.default is not s.empty
    }

    #085. Since the function takes variant keywords, we also identify them
    if len([ s.name for s in sig_agg if s.kind == s.VAR_KEYWORD ]) > 0:
        kw_varkw = { k:v for k,v in kw.items() if k not in kw_agg_raw }
    else:
        kw_varkw = {}

    #099. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Debug mode...')
        print(f'[{LfuncName}]Parameters are listed as below:')
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        getvar = sys._getframe().f_code.co_varnames
        for v in getvar:
            if v not in ['v','getvar']:
                print(f'[{LfuncName}]'+'[{0}]=[{1}]'.format(v,str(locals().get(v))))

    #100. Prepare mappers
    mapper_dict = dict(mapper[['mapper_fr','mapper_to']].values)

    #109. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Mapping from Daily KPI to periodical aggregation KPI: {str(mapper_dict)}')

    #300. Minimize the KPI config table for current process
    #310. Function to join the paths out of pd.Series
    def h_joinPath(srs : pd.Series):
        vfy_srs = srs.apply(pd.isnull)
        if vfy_srs.all():
            return('')
        else:
            return(os.path.join(*srs))

    #390. Mutation
    cfg_kpi = (
        inKPICfg
        .loc[lambda x: x['D_BGN'].le(dateEnd_d)]
        .loc[lambda x: x['D_END'].ge(dateEnd_d)]
        .loc[lambda x: x['F_KPI_INUSE'].eq(1)]
        .loc[lambda x: x['C_KPI_ID'].isin(list(mapper_dict.keys()) + list(mapper_dict.values()))]
        .assign(**{
            'C_KPI_FILE_NAME' : lambda x: x['C_KPI_FILE_NAME'].str.strip().str.upper()
            ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('').str.strip().str.upper()
            ,'C_KPI_FILE_TYPE' : lambda x: x['C_KPI_FILE_TYPE'].str.strip()
            ,'DF_NAME' : lambda x: x['DF_NAME'].fillna('dummy').str.strip()
            ,'options' : lambda x: x['options'].fillna('{}').str.strip()
        })
        .assign(**{
            'FilePath' : lambda x: x[['C_LIB_PATH','C_KPI_FILE_NAME']].apply(h_joinPath, axis = 1)
        })
    )

    #400. Map the input data files to the output ones, for later process upon files instead of KPIs
    #[ASSUMPTION]
    #[1] If there are multiple candidate paths for any output KPI, e.g. A and B, these paths should also apply to other KPIs
    #     that are stored in the same data file
    #[2] If such case happens, we would do as below:
    #    [1] When determining the output location, we only choose A since it is of higher priority
    #    [2] When loading <chkDat>, we search in both locations and choose the one residing in A since it is also at higher
    #         priority, given the same file name shows up in both paths
    cfg_rst = (
        cfg_kpi
        .loc[lambda x: x['C_KPI_ID'].isin(mapper_dict.values())]
        .sort_values(cfg_unique_row)
        .groupby('C_KPI_ID', as_index = False)
        .head(1)
    )

    #500. Helper functions
    #520. Column filter during loading data
    def h_keepVar(df : pd.DataFrame):
        if keep_all_col:
            return(df.columns)
        else:
            keepVars = (
                pd.concat([vecStack(aggrVar),vecStack(byVar),vecStack(copyVar)])
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
                print(f'''[{LfuncName}]Create interim data frame for output key: <{row['DF_NAME']}>''')
            else:
                print(f'''[{LfuncName}]Create interim data frame for dummy key''')

        #010. Initialize current iteration
        chkdat_pre = None

        #100. Subset the config table
        #110. Config table for searching of the previous periodical result
        #[ASSUMPTION]
        #[1] In APIs such as <RAM>, character case matters during object reference
        #[2] This function ensures the output of the data file names (object names for <RAM>) the same character case as
        #     defined in <inKPICfg>
        #[3] Hence we also have to search for the object for Checking Period in the same character case
        cfg_prd = (
            cfg_kpi
            .loc[lambda x: x['C_KPI_ID'].isin((
                cfg_rst
                .loc[lambda x: x['FilePath'].eq(row['FilePath'])]
                .loc[lambda x: x['DF_NAME'].eq(row['DF_NAME'])]
                ['C_KPI_ID']
            ))]
        )
        cfg_prd.loc[:, ['C_LIB_PATH','C_KPI_FILE_NAME']] = (
            inKPICfg
            .set_index(cfg_unique_row)
            .reindex(cfg_prd.set_index(cfg_unique_row).index)
            .set_index(cfg_prd.index)
            [['C_LIB_PATH','C_KPI_FILE_NAME']]
            .fillna('')
        )

        #130. Config table for searching of the daily KPI when necessary
        cfg_daily = (
            cfg_kpi
            .loc[lambda x: x['C_KPI_ID'].isin(cfg_prd['C_KPI_ID'].map({ v:k for k,v in mapper_dict.items() }))]
        )

        #300. Prepare <chkDat> for standardized aggregation
        #310. Verify whether ALL of the output KPIs are introduced to database ON the requested date
        #[ASSUMPTION]
        #[1] If no, <chkDat> is designed to be created by this function and may already exist, allowing us to load it directly
        #    However, this function does not verify the existence of the corresponding daily KPIs if <chkDat> DOES NOT EXIST,
        #     hence, one must make sure these daily KPIs exist on the correct dates, see <aggrByPeriod>
        #[2] If yes, there is no history of the creation of these KPIs, we will create empty <chkDat> from scratch
        bgn_today = cfg_prd['D_BGN'].eq(dateEnd_d).all()

        #350. Prepare the common arguments for the data retrieval
        args_GTSFK_cmn = {
            'fImp_opt' : 'options'
            ,'MergeProc' : 'SET'
            ,'keyvar' : byVar
            ,'SetAsBase' : 'k'
            ,'fTrans' : fTrans
            ,'fTrans_opt' : fTrans_opt
            ,'outDTfmt' : outDTfmt
            ,'_parallel' : _parallel
            ,'cores' : cores
            ,'fDebug' : fDebug
            ,'values_fn' : np.nansum
        }

        #370. Differ the process
        #[ASSUMPTION]
        #[1] Create empty <chkDat> only when <chkBgn> == <dateBgn>, such as MTD calculation
        if bgn_today & (dateBgn_d == chkBgn_d):
            #009. Debug mode
            if fDebug:
                print(f'[{LfuncName}]Create empty <chkDat> out of Daily KPIs as <D_BGN> equals <dateEnd>: <{str(dateEnd_d)}>')
                print(f'''[{LfuncName}]List of Daily KPIs to be directly translated: {str(cfg_daily['C_KPI_ID'].to_list())}''')

            #300. Patch the behavior when loading data source
            #[ASSUMPTION]
            #[1] Force all APIs to only load the data structure
            #[2] Ensure no data is loaded from SAS API, rather than nullify it after loading
            io_patcher = modifyDict(
                { apiname : { 'funcConv' : h_nullify } for apiname in dataIO.full }
                ,{ 'SAS' : { 'metadataonly' : True } }
            )
            kw_io = modifyDict(
                kw_DataIO
                ,{ 'argsPull' : io_patcher }
            )

            #500. Prepare arguments for the data structure retrieval
            args_GTSFK = {
                'inKPICfg' : cfg_daily
                ,'dnDates' : dateEnd_d
                ,'kw_DataIO' : kw_io
                ,**args_GTSFK_cmn
            }

            #700. Retrieve all involved <Daily KPIs>
            chkdat_pre = DBuse_GetTimeSeriesForKpi(**args_GTSFK).get('data', None)
        else:
            #009. Debug mode
            if fDebug:
                print(f'[{LfuncName}]Time series is designed to exist, search for the previous result as <chkDat>')
                print(f'''[{LfuncName}]List of historical KPIs to be retrieved: {str(cfg_prd['C_KPI_ID'].to_list())}''')

            #200. Helper functions
            #210. Function to only retrieve the involved map-to KPIs right after loading the data
            def h_to(df : pd.DataFrame):
                return(df.loc[lambda x: x['C_KPI_ID'].isin(cfg_prd['C_KPI_ID']), h_keepVar])

            #300. Patch the behavior when loading data source
            kw_io = modifyDict(
                kw_DataIO
                ,{ 'argsPull' : { apiname : { 'funcConv' : h_to } for apiname in dataIO.full } }
            )

            #500. Prepare arguments for the data retrieval
            args_GTSFK = {
                'inKPICfg' : cfg_prd
                ,'dnDates' : chkEnd
                ,'kw_DataIO' : kw_io
                ,**args_GTSFK_cmn
            }
            # globals().update(**{'vfy_GTSFK' : args_GTSFK})

            #700. Retrieve all involved <map-to KPIs>
            #[ASSUMPTION]
            #[1] Below function issues user warning when none of the requested KPIs exists
            #[2] However, we allow this to happen for this function
            with warnings.catch_warnings():
                warnings.simplefilter('ignore', category = UserWarning)
                chkdat_pre = DBuse_GetTimeSeriesForKpi(**args_GTSFK).get('data', None)

            #800. Reverse the mapping of KPI ID
            if chkdat_pre is not None:
                chkdat_pre = (
                    chkdat_pre
                    .assign(**{
                        'C_KPI_ID' : lambda x: x['C_KPI_ID'].map({ v:k for k,v in mapper_dict.items() })
                    })
                )

        #500. Determine the loop for aggregation
        #[ASSUMPTION]
        #[1] Candidate paths of all involved KPIs MUST BE all the same, indicating they are created in the same process
        #[2] All other cases are treated as different pathss and hence result in unnecessary extra system effort
        #[3] If different KPIs are stored in different <key>s in the container such as <HDFS>, we should also differ the process,
        #     for <aggrByPeriod> can only process one <key> at a time
        #[4] The loop is hence determined by unique <FileName> + <key>, taking into account all their candidate paths during searching
        #[5] To adapt to the function <aggrByPeriod>, <options> for loading the same file MUST be the same in the candidate paths
        loop_agg = cfg_daily[['C_KPI_FILE_NAME','DF_NAME','options']].drop_duplicates()

        #591. Raise exception if there are ambiguous parameters for the same file
        if len(loop_agg) != len(cfg_daily[['C_KPI_FILE_NAME','DF_NAME']].drop_duplicates()):
            raise ValueError(
                f'''[{LfuncName}]Ambiguous <options> for {str(cfg_daily['C_KPI_FILE_NAME'].to_list())}!'''
                +' Check <inKPICfg> for details of these file names.'
            )

        #700. Aggregation for time series per input data file name
        #709. Debug mode
        if fDebug:
            print(f'''[{LfuncName}]Aggregate Daily KPIs for output key: <{row['DF_NAME']}>''')

        #710. Helper function to handle each input
        def h_agg(incfg : pd.Series):
            #010. Initialize current iteration
            dateBgn_fnl = dateBgn_d
            chkBgn_fnl = chkBgn_d
            chkdat_vfy = chkdat_pre

            #100. Subset the config table for current iteration
            cfg_input = (
                cfg_daily
                .loc[lambda x: x['C_KPI_FILE_NAME'].eq(incfg['C_KPI_FILE_NAME'])]
                .loc[lambda x: x['DF_NAME'].eq(incfg['DF_NAME'])]
                #[ASSUMPTION]
                #[1] <rename> is unsafe if the renamed columns already exist
                .assign(**{
                    'FileName' : lambda x: x['C_KPI_FILE_NAME']
                    ,'PathSeq' : lambda x: x['N_LIB_PATH_SEQ']
                })
            )

            #105. Verify <chkBgn>
            #[ASSUMPTION]
            #[1] For aggregation with aligned <dateBgn> and <chkBgn>, no verification is needed
            #[2] For rolling period aggregation, <D_BGN> > <chkBgn> means that Daily KPI data file should exist
            #    [1] If a pseudo <chkDat> is created, <aggrByPeriod> searches for <Leading Period> based on the difference between
            #         <dateBgn> and <chkBgn>
            if dateBgn_d != chkBgn_d:
                #100. Verify whether all KPIs in this container have different <D_BGN>
                vfy_d_bgn = (
                    cfg_input
                    [['C_KPI_ID','D_BGN']]
                    .drop_duplicates()
                    .groupby(['C_KPI_ID'], as_index = False)
                    ['D_BGN']
                    .count()
                    .loc[lambda x: x['D_BGN'].gt(1)]
                )
                if len(vfy_d_bgn):
                    raise ValueError(
                        f'''[{LfuncName}]Different <D_BGN> found for KPIs: {str(vfy_d_bgn['C_KPI_ID'].to_list())}!'''
                        +' They should be the same for rolling period aggregation!'
                    )

                _d_bgn = cfg_input.iat[0, cfg_input.columns.get_loc('D_BGN')]

                #500. Differ the process
                if _d_bgn >= dateBgn_d:
                    #[ASSUMPTION]
                    #[1] In such case, the calculation only covers the period starting from <D_BGN> of the involved KPI
                    #[2] Hence <chkBgn> also starts on the same date
                    #[3] There should not be <Leading Period> as well
                    dateBgn_fnl = _d_bgn
                    chkBgn_fnl = _d_bgn
                elif _d_bgn > chkBgn_d:
                    #[ASSUMPTION]
                    #[1] In such case, there is no clue whether <Checking Period> is equal to <Request Period>
                    #[2] We conduct the process without <chkDat> to simplify the logic
                    #[3] Hence we set <chkDat> as nothing for good
                    #[4] Example
                    #    [1] KPI starts on 20160330
                    #    [2] The rolling 5-day ANR has been calculated from 20160328 to 20160401, which follows the logic at higher
                    #         priority as <dateBgn> is set to <D_BGN>
                    #    [3] Now we have to calculate rolling 5-day ANR from 20160401 to 20160405, i.e. the next workday of 20160401
                    #    [4] Literally we would leverage [2] as <chkDat>, but by the logic of <aggrByPeriod>, <Checking Period> covers
                    #         3 workdays while <Request Period> covers 2 workdays; hence <chkDat> is not used
                    chkdat_vfy = None

            #109. Debug mode
            if fDebug:
                print(f'''[{LfuncName}]KPIs to load: {str(cfg_input['C_KPI_ID'].drop_duplicates().to_list())}''')
                print(f'''[{LfuncName}]From daily source file: {incfg['C_KPI_FILE_NAME']}''')

            #300. Only check the involved KPI during aggregation, to save system effort
            #310. Register temporary API
            dataIO_int.add('RAM')

            #350. Differ the process
            if chkdat_vfy is not None:
                if fDebug:
                    print(f'''[{LfuncName}]Create pseudo <chkDat> <chk_kpi_pd{chkEnd}> for current input''')
                dataIO_int['RAM'].push(
                    indat = {
                        'tmp' : (
                            chkdat_vfy
                            .loc[lambda x: x['C_KPI_ID'].isin(cfg_input['C_KPI_ID'])]
                            .loc[:, lambda x: ~x.columns.isin(['D_RecDate'])]
                        )
                    }
                    ,outfile = f'chk_kpi_pd{chkEnd}'
                    ,frame = frame
                )
            else:
                if fDebug:
                    print(f'''[{LfuncName}]Remove the pseudo <chkDat> <chk_kpi_pd{chkEnd}> since it should not exist''')
                dataIO_int['RAM'].push(
                    indat = {
                        'tmp' : None
                    }
                    ,outfile = f'chk_kpi_pd{chkEnd}'
                    ,frame = frame
                )

            #390. Remove the temporary API
            dataIO_int.remove('RAM')

            #700. Prepare arguments
            #710. Set arguments
            args_agg = {
                'inDatPtn' : cfg_input
                ,'inDatType' : 'C_KPI_FILE_TYPE'
                ,'in_df' : 'DF_NAME'
                ,'fImp_opt' : ast.literal_eval(incfg['options'])
                ,'fTrans' : fTrans
                ,'fTrans_opt' : fTrans_opt
                ,'_parallel' : _parallel
                ,'cores' : cores
                ,'dateBgn' : dateBgn_fnl
                ,'dateEnd' : dateEnd_d
                ,'chkDatPtn' : f'chk_kpi_pd{int_sfx}'
                ,'chkDatType' : 'RAM'
                ,'chkDat_opt' : {
                    'RAM' : {
                        'frame' : frame
                    }
                }
                ,'chkDatVar' : aggrVar
                ,'chkBgn' : chkBgn_fnl
                ,'byVar' : byInt
                ,'copyVar' : copyVar
                ,'aggrVar' : aggrVar
                ,'outVar' : aggrVar
                ,'genPHMul' : genPHMul
                ,'calcInd' : calcInd
                ,'funcAggr' : funcAggr
                ,'outDTfmt' : outDTfmt
                ,'fDebug' : fDebug
                ,'kw_DataIO' : kw_DataIO
            }

            #750. Determine the rest of keyword arguments
            kw_oth = {
                k:v
                for k,v in kw_agg_raw.items()
                if (k not in kw_varkw)
                and (k not in args_agg)
            }

            #790. Finalize the arguments
            args_agg_fnl = {**args_agg, **kw_oth, **kw_varkw}
            # frame = sys._getframe()
            # while frame.f_back:
            #     frame = frame.f_back
            # frame.f_locals.update({'vfy_agg' : args_agg_fnl})

            #800. Aggregation
            #[ASSUMPTION]
            #[1] We do not cover the errors by setting default value when <get> fails, since the data should exist if everything
            #     goes well
            rstOut = aggrByPeriod(**args_agg_fnl).get('data')

            #999. Output
            return(rstOut)

        #790. Aggregation for the same <key> in current output file
        rstOut = (
            pd.concat(
                loop_agg.apply(h_agg, axis = 1).to_list()
                ,axis = 0
                ,ignore_index = True
            )
            .assign(**{
                'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(mapper_dict)
            })
        )

        #800. Update the indicator of the data refresh date
        if tableVar in rstOut.columns:
            rstOut = (
                rstOut
                .assign(**{
                    tableVar : lambda x: asDates(dateEnd_d)
                })
            )

        #999. Output
        return(rstOut)

    #570. Function to process a single output file name
    def h_outfile(row : pd.Series):
        #500. Conduct calculation for all unique <key>s in current output file
        rstOut = (
            cfg_rst
            .loc[lambda x: x['FilePath'].eq(row['FilePath'])]
            .assign(**{
                'agg_df' : lambda x: x.apply(h_outkey, axis = 1)
            })
        )

        #700. Prepare arguments to export the result
        #710. Register API
        dataIO.add(row['C_KPI_FILE_TYPE'])

        #740. Output file name
        #741. Locate the input filename pattern
        file_input = (
            inKPICfg
            .assign(**{
                'C_KPI_FILE_NAME' : lambda x: x['C_KPI_FILE_NAME'].str.strip()
                ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('').str.strip()
            })
            .assign(**{
                'FilePath' : lambda x: x[['C_LIB_PATH','C_KPI_FILE_NAME']].apply(h_joinPath, axis = 1)
                ,'inRAM' : lambda x: x['C_KPI_FILE_TYPE'].eq('RAM')
            })
            .loc[lambda x: x['FilePath'].str.upper().eq(row['FilePath'])]
            [['FilePath','inRAM']]
            .head(1)
        )

        #745. Parse the pattern with the data date
        outfile = (
            parseDatName(
                datPtn = file_input
                ,dates = dateEnd_d
                ,outDTfmt = outDTfmt
                ,chkExist = False
                ,dict_map = fTrans
                ,**fTrans_opt
            )
            ['FilePath.Parsed']
            .iat[0]
        )

        #749. Debug mode
        if fDebug:
            print(f'''[{LfuncName}]Creating data file: <{outfile}>''')

        #770. Patch the behavior to write data
        if row['C_KPI_FILE_TYPE'] in hasKeys:
            kw_patcher = {
                'kw_put' : dict(
                    rstOut
                    .assign(**{
                        'opt.ast.Parsed' : lambda x: x['options'].apply(ast.literal_eval)
                    })
                    [['DF_NAME','opt.ast.Parsed']]
                    .values
                )
            }
        else:
            kw_patcher = ast.literal_eval(row['options'])

            #[ASSUMPTION]
            #[1] During the writing of SAS data file, we can only set encoding <GB2312> in Chinese locale
            if row['C_KPI_FILE_TYPE'] == 'SAS':
                if kw_patcher.get('encoding', '').upper().startswith('GB'):
                    kw_patcher = modifyDict(
                        kw_patcher
                        ,{ 'encoding' : 'GB2312' }
                    )

        #800. Push the data in accordance with the config table
        rc = (
            dataIO[row['C_KPI_FILE_TYPE']]
            .push(
                dict(rstOut[['DF_NAME','agg_df']].values)
                ,outfile
                ,**kw_patcher
            )
        )

        #899. Remove the API to purge the RAM used
        dataIO.remove(row['C_KPI_FILE_TYPE'])

        #999. Output the result
        return({outfile : rc})

    #700. Execute the process
    #709. Verify the duplication of file type
    vfy_type = (
        cfg_rst
        [['FilePath','C_KPI_FILE_TYPE']]
        .drop_duplicates()
        .groupby(['FilePath'], as_index = False)
        ['C_KPI_FILE_TYPE']
        .count()
        .loc[lambda x: x['C_KPI_FILE_TYPE'].gt(1)]
    )
    if len(vfy_type):
        raise ValueError(
            f'''[{LfuncName}]Ambiguous <C_KPI_FILE_TYPE> for {str(vfy_type['FilePath'].to_list())}!'''
            +' Check <inKPICfg> for detailed <C_KPI_FILE_TYPE> of these file names.'
        )

    #719. Verify the duplication of file API options
    vfy_opt = (
        cfg_rst
        .loc[
            lambda x: ~x['C_KPI_FILE_TYPE'].isin(hasKeys)
            ,['FilePath','options']
        ]
        .drop_duplicates()
        .groupby(['FilePath'], as_index = False)
        ['options']
        .count()
        .loc[lambda x: x['options'].gt(1)]
    )
    if len(vfy_opt):
        raise ValueError(
            f'''[{LfuncName}]Ambiguous <options> for {str(vfy_type['FilePath'].to_list())}!'''
            +' Check <inKPICfg> for detailed <options> of these file names.'
        )

    #750. Execution
    rstOut = (
        cfg_rst
        [['FilePath','C_KPI_FILE_TYPE','options']]
        .drop_duplicates()
        .assign(**{
            'rc_pre' : lambda x: x.apply(h_outfile, axis = 1)
        })
        .assign(**{
            'FilePath' : lambda x: x['rc_pre'].apply(lambda row: list(row.keys())[0])
            ,'rc' : lambda x: x['rc_pre'].apply(lambda row: list(row.values())[0])
        })
        [['FilePath','C_KPI_FILE_TYPE','rc']]
    )

    #999. Validate the completion
    return(rstOut)
#End kfCore_ts_agg

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
    from omniPy.AdvOp import exec_file, modifyDict, get_values
    from omniPy.AdvDB import aggrByPeriod, kfCore_ts_agg
    from omniPy.Dates import asDates, UserCalendar, intnx

    #010. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Set parameters
    #[ASSUMPTION]
    #[1] Below date indicates the beginning of one KPI among those in the config table
    G_d_rpt = '20160526'
    cfg_kpi_file = os.path.join(dir_omniPy, 'omniPy', 'AdvDB', 'CFG_KPI_Example.xlsx')
    with pd.option_context('future.no_silent_downcasting', True):
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
                ,'N_LIB_PATH_SEQ' : lambda x: x['N_LIB_PATH_SEQ'].fillna(0).infer_objects(copy=False).astype(int)
                ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('')
            })
        )

    #150. Mapper to indicate the aggregation
    map_dict = {
        '130100' : '130101'
        ,'140110' : '140111'
    }
    map_agg = pd.DataFrame(
        {
            'mapper_fr' : list(map_dict.keys())
            ,'mapper_to' : list(map_dict.values())
        }
        ,index = list(range(len(map_dict)))
    )

    #300. Call the factory to create MTD ANR
    #310. Prepare the modification upon the default arguments with current Business requirements
    mtdBgn = intnx('month', G_d_rpt, 0, 'b', daytype = 'c').strftime('%Y%m%d')
    indate_mtd = {
        'dateBgn' : mtdBgn
        ,'dateEnd' : G_d_rpt
        ,'chkBgn' : mtdBgn
    }
    args_ts_mtd = {
        'inKPICfg' : cfg_kpi
        ,'mapper' : map_agg
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
        ,**indate_mtd
    }

    #350. Call the process
    time_bgn = dt.datetime.now()
    rst = kfCore_ts_agg(**args_ts_mtd)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)

    #400. Verify the result
    #410. Retrieve the newly created data
    file_kpi1 = rf'D:\Temp\agg{G_d_rpt}.hdf'
    rst_kpi1 = (
        pd.read_hdf(file_kpi1, 'kpi1')
        .loc[lambda x: x['C_KPI_ID'].eq('130101')]
    )
    rst_kpi2 = (
        get_values(rf'kpi2agg_{G_d_rpt}', instance = pd.DataFrame, inplace = False)
        .loc[lambda x: x['C_KPI_ID'].eq('140111')]
    )

    #420. Prepare unanimous arguments
    cln = UserCalendar( intnx('month', G_d_rpt, 0, 'b', daytype = 'c'), G_d_rpt )
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
            ,'dateEnd' : G_d_rpt
            ,'byVar' : byvar_kpis
            ,'outVar' : aggvar_kpis
        }
    )
    man_kpi1 = (
        aggrByPeriod(**args_agg_kpi1).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_dict)
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
            #[1] Since <D_BGN> is set to the same as <G_d_rpt> (see the data <cfg_agg>), we should only involve data file
            #     on one date for identical calculation
            ,'dateBgn' : G_d_rpt
        }
    )
    man_kpi2 = (
        aggrByPeriod(**args_agg_kpi2).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_dict)
            #[ASSUMPTION]
            #[1] Since we only used one data file, we need to divide the result by the number of calendar days in the
            #     calculation period
            ,aggvar_kpis : lambda x: x[aggvar_kpis].div(cln.kClnDay)
        })
    )

    #490. Assertion
    rst_kpi1.eq(man_kpi1).all(axis = None)
    rst_kpi2.eq(man_kpi2).all(axis = None)

    #600. Calculate MTD ANR for the next workday
    #[ASSUMPTION]
    #[1] Since <G_d_next> is later than <D_BGN> of <kpi2>, one should avoid calling the factory for <G_d_next> BEFORE the call
    #     to the factory for <G_d_rpt> is complete. i.e. the MTD calculation on the first data date should be ready
    G_d_next = intnx('day', G_d_rpt, 1, daytype = 'w').strftime('%Y%m%d')
    args_ts_mtd2 = modifyDict(
        args_ts_mtd
        ,{
            'dateEnd' : G_d_next
            #[ASSUMPTION]
            #[1] Check the log on whether the process leveraged the result on the previous workday
            ,'fDebug' : True
        }
    )

    #650. Call the process
    time_bgn = dt.datetime.now()
    rst2 = kfCore_ts_agg(**args_ts_mtd2)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)

    #700. Verify the result for the next workday
    #710. Retrieve the newly created data
    file_kpi1_2 = rf'D:\Temp\agg{G_d_next}.hdf'
    rst_kpi1_2 = (
        pd.read_hdf(file_kpi1_2, 'kpi1')
        .loc[lambda x: x['C_KPI_ID'].eq('130101')]
    )
    rst_kpi2_2 = (
        get_values(rf'kpi2agg_{G_d_next}', instance = pd.DataFrame, inplace = False)
        .loc[lambda x: x['C_KPI_ID'].eq('140111')]
    )

    #720. Prepare unanimous arguments
    cln2 = UserCalendar( intnx('month', G_d_next, 0, 'b', daytype = 'c'), G_d_next )

    #740. Calculate the ANR manually for <kpi1>
    args_agg_kpi1_2 = modifyDict(
        args_agg_kpi1
        ,{
            'dateBgn' : cln2.d_AllCD[0]
            ,'dateEnd' : G_d_next
        }
    )
    man_kpi1_2 = (
        aggrByPeriod(**args_agg_kpi1_2).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_dict)
        })
    )

    #760. Calculate the ANR manually for <kpi2>
    args_agg_kpi2_2 = modifyDict(
        args_agg_kpi1_2
        ,{
            'inDatPtn' : datptn_agg_kpi2
            ,'fImp_opt' : agg_opt_kpi2
            ,'dateBgn' : G_d_rpt
        }
    )
    man_kpi2_2 = (
        aggrByPeriod(**args_agg_kpi2_2).get('data')
        .assign(**{
            'C_KPI_ID' : lambda x: x['C_KPI_ID'].map(map_dict)
            ,aggvar_kpis : lambda x: x[aggvar_kpis].mul(2).div(cln2.kClnDay)
        })
    )

    #790. Assertion
    rst_kpi1_2.eq(man_kpi1_2).all(axis = None)
    rst_kpi2_2.eq(man_kpi2_2).all(axis = None)

    #900. Purge
    if os.path.isfile(file_kpi1): os.remove(file_kpi1)
    if os.path.isfile(file_kpi1_2): os.remove(file_kpi1_2)
#-Notes- -End-
'''
