#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import datetime as dt
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from omniPy.Dates import asDates, intnx
from omniPy.AdvDB import kfCore_ts_agg

anno_return = kfCore_ts_agg.__annotations__.get('return', None)

def kfFunc_ts_roll(
    inDate : str | dt.date = None
    ,kDays : int = 0
    ,**kw
) -> anno_return:
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
#   |[1] Naming: <K>PI <F>actory <FUNC>tion for <T>ime <S>eries by <ROLL>ing period algorithm                                           #
#   |[2] It is a high level interface of <kfCore_ts_agg>, which tweaks the date variables to facilitate various scenarios               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FUNCTION]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Map the rolling period aggregation of KPIs listed on the left side of <mapper> to those on the right side of it                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate Rolling 30 days ANR of product holding balances along the time series, by recognizing the data on each weekend as    #
#   |     the same as its previous workday, also leveraging the aggregation result on its previous workday                              #
#   |[2] Calculate the same as above, but only conduct the process on workdays while set <genPHMul = True>                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |150.   Calculation period control                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDate     :   The date to which to calculate the MTD aggregation from the first calendar day in the same month                    #
#   |                follow the syntax of this function during input                                                                    #
#   |               [None            ] <Default> Function will raise error if it is NOT provided                                        #
#   |kDays      :   Positive number of days to roll back from <inDate>                                                                  #
#   |               [0               ] <Default> Function will raise error if it is NOT positive                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |kw         :   Any other arguments that are required by <kfCore_ts_agg>                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[DataFrame]:   See the return result from <kfCore_ts_agg>                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240114        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |   |sys, datetime, inspect                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |asDates                                                                                                                    #
#   |   |   |intnx                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |kfCore_ts_agg                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(kDays, int):
        raise ValueError(f'[{LfuncName}]<kDays> must be a positive integer!')
    if kDays < 1:
        raise ValueError(f'[{LfuncName}]<kDays> must be a positive integer!')

    #020. Local environment
    k_roll = 1 - kDays

    #100. Get the signature of the core function
    sig_core = signature(kfCore_ts_agg).parameters
    fDebug = kw.get('fDebug', sig_core['fDebug'].default)

    #200. Clean up the parameters
    #210. Identify all valid arguments for the core function
    kw_raw = [
        s.name
        for s in sig_core.values()
        if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.default is not s.empty
    ]

    #230. Since the core function takes variant keywords, we also identify them
    if len([ s.name for s in sig_core.values() if s.kind == s.VAR_KEYWORD ]) > 0:
        kw_varkw = { k:v for k,v in kw.items() if k not in kw_raw }
    else:
        kw_varkw = {}

    #250. Identify the arguments to be used
    kw_oth = {
        k:v
        for k,v in kw.items()
        if k in kw_raw
        and (k not in kw_varkw)
        and (k not in ['dateBgn','dateEnd','chkBgn'])
    }

    #500. Tweak the parameters for function call
    #510. Ending date
    kw_d = kw_oth.get('kw_d', sig_core['kw_d'].default)
    kw_cal = kw_oth.get('kw_cal', sig_core['kw_cal'].default)
    dateEnd_d = asDates(inDate, **kw_d)

    #530. Beginning date
    #[ASSUMPTION]
    #[1] Rolling days aggregation requires the indication of <daytype>
    calcInd = kw_oth.get('calcInd', sig_core['calcInd'].default)
    dtBgn = intnx('day', dateEnd_d, k_roll, 'b', daytype = calcInd, kw_cal = kw_cal)

    #550. Determine <chkEnd> by the implication of <genPHMul>
    genPHMul = kw_oth.get('genPHMul', sig_core['genPHMul'].default)
    if genPHMul:
        chkEnd_d = intnx('day', dateEnd_d, -1, daytype = ('W' if calcInd=='C' else calcInd), kw_cal = kw_cal)
    else:
        chkEnd_d = intnx('day', dateEnd_d, -1, daytype = 'C', kw_cal = kw_cal)

    #570. Determine <chkBgn>
    chkBgn = intnx('day', chkEnd_d, k_roll, 'b', daytype = calcInd, kw_cal = kw_cal)

    #599. Finalize the parameters
    kw_fnl = {
        'dateBgn' : dtBgn
        ,'dateEnd' : dateEnd_d
        ,'chkBgn' : chkBgn
        ,**kw_oth
        ,**kw_varkw
    }

    #989. Debug mode
    if fDebug:
        print(f'[{LfuncName}]Debug mode...')
        print(f'[{LfuncName}]Tweaked parameters are listed as below:')
        print(f'[{LfuncName}][dateBgn]=[{str(dtBgn)}]')
        print(f'[{LfuncName}][dateEnd]=[{str(dateEnd_d)}]')
        print(f'[{LfuncName}][chkBgn]=[{str(chkBgn)}]')

    #999. Call the core function
    return(kfCore_ts_agg(**kw_fnl))
#End kfFunc_ts_roll

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
    from omniPy.AdvDB import aggrByPeriod, kfFunc_ts_roll
    from omniPy.Dates import asDates, UserCalendar, intnx

    #010. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Set parameters
    #[ASSUMPTION]
    #[1] Below date indicates the beginning of one KPI among those in the config table
    G_d_rpt = '20160526'
    cfg_kpi = (
        pd.read_excel(
            os.path.join(dir_omniPy, 'omniPy', 'AdvDB', 'CFG_KPI_Example.xlsx')
            ,dtype = object
        )
        .rename(columns = {
            'D_BGN' : '_D_BGN'
            ,'D_END' : '_D_END'
            ,'F_KPI_INUSE' : '_F_KPI_INUSE'
            ,'N_LIB_PATH_SEQ' : '_N_LIB_PATH_SEQ'
        })
        .assign(**{
            'D_BGN' : lambda x: asDates(x['_D_BGN'])
            ,'D_END' : lambda x: asDates(x['_D_END'])
            ,'F_KPI_INUSE' : lambda x: x['_F_KPI_INUSE'].astype(int)
            ,'N_LIB_PATH_SEQ' : lambda x: x['_N_LIB_PATH_SEQ'].astype(int)
            ,'C_LIB_PATH' : lambda x: x['C_LIB_PATH'].fillna('')
        })
        .loc[:, lambda x: ~x.columns.str.startswith('_')]
    )

    #150. Mapper to indicate the aggregation
    map_dict = {
        '130100' : '130102'
        ,'140110' : '140112'
    }
    map_agg = pd.DataFrame(
        {
            'mapper_fr' : list(map_dict.keys())
            ,'mapper_to' : list(map_dict.values())
        }
        ,index = list(range(len(map_dict)))
    )

    #300. Call the factory to create Rolling 15-day ANR
    #310. Prepare the modification upon the default arguments with current Business requirements
    k_roll_days = 15
    args_ts_roll = {
        'inKPICfg' : cfg_kpi
        ,'mapper' : map_agg
        ,'inDate' : G_d_rpt
        ,'kDays' : k_roll_days
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

    #350. Call the process
    time_bgn = dt.datetime.now()
    rst = kfFunc_ts_roll(**args_ts_roll)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)

    #400. Verify the result
    #410. Retrieve the newly created data
    file_kpi1 = rf'D:\Temp\r15_{G_d_rpt}.hdf'
    rst_kpi1 = (
        pd.read_hdf(file_kpi1, 'kpi1')
        .loc[lambda x: x['C_KPI_ID'].eq('130102')]
    )
    rst_kpi2 = (
        pd.read_hdf(file_kpi1, 'kpi2')
        .loc[lambda x: x['C_KPI_ID'].eq('140112')]
    )

    #420. Prepare unanimous arguments
    cln = UserCalendar( intnx('day', G_d_rpt, 1 - k_roll_days, 'b', daytype = 'c'), G_d_rpt )
    byvar_kpis = args_ts_roll.get('byVar')
    if isinstance(byvar_kpis, (str, tuple)):
        byvar_kpis = [byvar_kpis]
    #[ASSUMPTION]
    #[1] One should NEVER use <+=> to append new items to a list, as it modifies the original object
    #[2] Use other syntax to avoid modification of the object
    # byvar_kpis += ['C_KPI_ID']
    byvar_kpis = list(set(byvar_kpis + ['C_KPI_ID']))
    aggvar_kpis = args_ts_roll.get('aggrVar')

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
            for k,v in args_ts_roll.items()
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
        })
    )

    #490. Assertion
    rst_kpi1.eq(man_kpi1).all(axis = None)
    rst_kpi2.eq(man_kpi2).all(axis = None)

    #600. Calculate Rolling 15-day ANR for the next workday
    #[ASSUMPTION]
    #[1] Since <G_d_next> is later than <D_BGN> of <kpi2>, one should avoid calling the factory for <G_d_next> BEFORE the call
    #     to the factory for <G_d_rpt> is complete. i.e. the MTD calculation on the first data date should be ready
    #[2] The factory does not validate the above data and will leverage any existing Daily KPI data file inadvertently, which
    #     would produce unexpected result in such case
    G_d_next = intnx('day', G_d_rpt, 1, daytype = 'w').strftime('%Y%m%d')
    args_ts_roll2 = modifyDict(
        args_ts_roll
        ,{
            'inDate' : G_d_next
            #[ASSUMPTION]
            #[1] Check the log on whether the process leveraged the result on the previous workday
            ,'fDebug' : True
        }
    )

    #650. Call the process
    time_bgn = dt.datetime.now()
    rst2 = kfFunc_ts_roll(**args_ts_roll2)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)

    #700. Verify the result for the next workday
    #710. Retrieve the newly created data
    file_kpi1_2 = rf'D:\Temp\r15_{G_d_next}.hdf'
    rst_kpi1_2 = (
        pd.read_hdf(file_kpi1_2, 'kpi1')
        .loc[lambda x: x['C_KPI_ID'].eq('130102')]
    )
    rst_kpi2_2 = (
        pd.read_hdf(file_kpi1_2, 'kpi2')
        .loc[lambda x: x['C_KPI_ID'].eq('140112')]
    )

    #720. Prepare unanimous arguments
    cln2 = UserCalendar( intnx('day', G_d_next, 1 - k_roll_days, 'b', daytype = 'c'), G_d_next )

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
