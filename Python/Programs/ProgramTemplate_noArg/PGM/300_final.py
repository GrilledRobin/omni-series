#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#This step is to standardize the usage of multi-processing
#[Capture exceptions raised by any threads inside the parent thread]
#Quote: https://www.geeksforgeeks.org/handling-a-threads-exception-in-the-caller-thread-in-python/
#[IMPORTANT]
#[1] All MP scripts MUST BE executed within the [main] module, as they will spawn child processes out of it!
#[2] It is tested that we can put the statement [if __name__=='__main__':] at the start of this script to enable MP
#[3] There is no need of this statement if there is no MP to execute
if __name__=='__main__':
    #001. We also need to put the logger inside the [main] module when there is statement for MP
    logger.info('step 3')

    #010. Create envionment.
    import pandas as pd
    import numpy as np
    import datetime as dt
    from omniPy.AdvOp import modifyDict
    from omniPy.AdvDB import loadSASdat, DBuse_GetTimeSeriesForKpi
    from omniPy.Dates import UserCalendar

    #100. Set parameters
    G_d_bgn = '20160301'
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
            ,'_parallel' : True
            ,'fDebug' : False
            ,'values_fn' : np.sum
        }
    )
    KPI_ts2 = DBuse_GetTimeSeriesForKpi(**args_GTSFK2)
