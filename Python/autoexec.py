#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This script is intended to act as the [autoexec] as in other languages, to load necessary environment when a project is initiated  #
#   |Please [call] this script at the beginning of the scripts in your project to conduct below processes:                              #
#   |[1] Activate all user defined functions from [omniPy] directory into current session                                               #
#   |[2] Find the location of [Calendar Adjustment Data] in preparation of any date-related operations                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Generated global environments, i.e. accessing the dictionary [getOption] via [getOption[attr]]                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |file.autoexec       :   Absolute path of the global environment setter script [autoexec.py]                                        #
#   |CountryCode         :   Country Code for specifying during function calls, such as [UserCalendar]                                  #
#   |ClndrAdj            :   Physically existing file path to the [Calendar Adjustment Data], the same value as [path_ClndrAdj]         #
#   |fmt.def.GTSFK       :   Default format to translate strings into date strings for function [DBuse_GetTimeSeriesForKpi]             #
#   |fmt.opt.def.GTSFK   :   Default options for the format [fmt.def.GTSFK] as defined above, both basically used in [apply_MapVal]     #
#   |args.def.GTSFK      :   Default arguments for function [DBuse_GetTimeSeriesForKpi]                                                 #
#   |fmt.parseDates      :   Default behavior to format the date values before assigning them to their respective local variables       #
#   |args.Calendar       :   Default arguments for instantiation of classes: [omniPy.Dates.UserCalendar] and [omniPy.Dates.ObsDates]    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Generated global variables                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |paths_omniPy        :   Candidate directory names to search for the user defined library of [name_omniPy]                          #
#   |name_omniPy         :   Name of the user defined library, which contains many useful functions                                     #
#   |candidate_ClndrAdj  :   Candidate full paths of the [Calendar Adjustment Data]                                                     #
#   |path_omniPy         :   Physically existing directory of the user defined library as [name_omniPy]                                 #
#   |G_clndr             :   Business calendar from 5 years ago to 1 month later, counting from [datetime.date.today()]                 #
#   |G_obsDates          :   Business date-shifting tool covering the period from 5 years ago to 1 month later, counting from           #
#   |                         [datetime.date.today()]; with default [G_obsDates.values==datetime.date.today()]                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210216        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210307        | Version | 1.01        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add the date conversion method from SAS to Python, esp. for the package [pyreadstat]                                    #
#   |      |[2] Introduce [inspect.getsourcefile] to locate the current executing script                                                #
#   |      |    [IMPORTANT] DO NOT create another function to encapsulate it! Just use this function where necessary!                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210529        | Version | 1.02        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce [fmt.parseDates] to assign the formatted date values to their corresponding local variables                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210816        | Version | 1.03        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now search for the subdirectory [omnimacro] among all candidate directories                                             #
#   |      |[2] Add default arguments [args.Calendar] for date-related classes                                                          #
#   |      |[3] Add option [file.autoexec] for current session to locate [autoexec.py]                                                  #
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
#   |   |os, sys, datetime, inspect, importlib, itertools                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
'''

#100. Establish environment
import os, sys
import datetime as dt
from inspect import getsourcefile
from importlib import reload
from itertools import product

#101. Identify the absolute path of current script
#LfileName : str = sys._getframe().f_code.co_filename
#LfileName : str = __file__
#Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
LfileName : str = getsourcefile(lambda:0)
#print('LfileName=['+LfileName+']')

#110. Define the hard coding inputs
drives_autoexec = [ d + os.sep for d in ['D:', 'C:'] ]
paths_autoexec = ['Python', 'Robin', 'RobinLu', 'SAS']
name_omniPy = r'omniPy'
name_omnimacro = r'omnimacro'
#Quote: https://stackoverflow.com/questions/533905/get-the-cartesian-product-of-a-series-of-lists
comb_autoexec = list(product(drives_autoexec, paths_autoexec))
paths_omniPy = [ os.path.join( *p ) for p in comb_autoexec ]
paths_omnimacro = [ os.path.join( *p, name_omnimacro ) for p in comb_autoexec ]
candidate_ClndrAdj = [ os.path.join(d, r'Dates',r'CalendarAdj.csv') for d in paths_omnimacro ]

#200. Import the user defined package
#210. Only retrieve the first valid path from the list of candidate paths
#Quote: https://stackoverflow.com/questions/8933237/how-to-find-if-directory-exists-in-python
#[os.path.isdir] only return [True] when the candidate is an existing path
path_omniPy = [ d for d in paths_omniPy if os.path.isdir(os.path.join(d,name_omniPy)) ][0]

#280. Attach the path to the system path list for the method [__import__]
#[IMPORTANT] The path which [__import__] is looking for a package is the [Parent Directory] to its name!
if path_omniPy not in sys.path:
    sys.path.append( path_omniPy )

#290. Import the functions from the package
import omniPy as opy
#Ensure to refresh the [omniPy] module during debugging
#[NOTE] This action DOES NOT refresh the definition of [class]; one still needs to restart the Python session for this situation
reload(opy)

#400. Identify the dates to be adjusted based on government policy
path_ClndrAdj = list(filter( os.path.isfile , candidate_ClndrAdj ))[0]

#500. Create global system options (similar to global variables, but more specific when being referenced to during program call)
#Below options are dependencies to the rest options
getOption = {
    'file.autoexec' : LfileName
    ,'fmt.def.GTSFK' : {
        #The values of this list are the names of local variables defined in [DBuse_GetTimeSeriesForKpi]
        '&c_date.' : 'L_d_curr'
        ,'&L_curdate.' : 'L_d_curr'
        ,'&L_curMon.' : 'L_m_curr'
        ,'&L_prevMon.' : 'L_m_curr'
    }
    ,'fmt.opt.def.GTSFK' : {
        #See syntax of function [apply_MapVal]
        'PRX' : False
        ,'fPartial' : True
        ,'full_match' : False
        ,'ignore_case' : True
    }
    ,'fmt.parseDates' : {
        'L_d_curr' : '%Y%m%d'
        ,'L_m_curr' : '%Y%m'
    }
    ,'omniPy_ini' : LfileName
    ,'CountryCode' : 'CN'
    ,'ClndrAdj' : path_ClndrAdj
}

getOption.update({
    'path.omniPy' : path_omniPy
    ,'args.Calendar' : {
        'countrycode' : getOption['CountryCode']
        ,'CalendarAdj' : getOption['ClndrAdj']
        ,'fmtDateIn' : ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
        ,'fmtDateOut' : '%Y%m%d'
        ,'DateOutAsStr' : False
        #[1826 = 365 * 5 + 2 - 1] as there are 2 leap years within 5 years period
        ,'clnBgn' : dt.date.today() - dt.timedelta(days=1826)
        #30 days is enough to determine whether current date is the last workday/tradeday of current month
        ,'clnEnd' : dt.date.today() + dt.timedelta(days=30)
    }
    ,'args.def.GTSFK' : {
        'inKPICfg' : None
        ,'InfDatCfg' : {
            'InfDat' : None
            ,'_paths' : None
            ,'DatType' : 'RAM'
            ,'DF_NAME' : None
            ,'_trans' : getOption['fmt.def.GTSFK']
            ,'_trans_opt' : getOption['fmt.opt.def.GTSFK']
            ,'_imp_opt' : {
                'SAS' : {
                    'encoding' : 'GB2312'
                }
            }
            ,'_func' : None
            #[IMPORTANT] Below parameter is expected to be a dict in the real case, hence we cannot set it [None], otherwise it
            #             cannot be updated by [modifyDict]
            ,'_func_opt' : {}
        }
        ,'SingleInf' : False
        ,'dnDates' : None
        ,'ColRecDate' : 'D_RecDate'
        ,'MergeProc' : 'MERGE'
        ,'keyvar' : 'nc_cifno'
        ,'SetAsBase' : 'k'
        ,'KeepInfCol' : False
        ,'fTrans' : getOption['fmt.def.GTSFK']
        ,'fTrans_opt' : getOption['fmt.opt.def.GTSFK']
        ,'fImp_opt' : {
            'SAS' : {
                'encoding' : 'GB2312'
            }
        }
        #Whether to use multiple CPU cores to import the data in parallel; [T] is recommended for large number of large data files
        ,'_parallel' : True
        ,'cores' : 4
        ,'fDebug' : False
        ,'miss_skip' : True
        ,'miss_files' : 'G_miss_files'
        ,'err_cols' : 'G_err_cols'
        ,'outDTfmt' : getOption['fmt.parseDates']
        ,'dup_KPIs' : 'G_dup_kpiname'
        #Provide the same value for [AggrBy] as [keyvar], or just [AggrBy=None] to keep all columns from [InfDat]
        ,'AggrBy' : None
        #Below paramter is an alias for [aggfunc] within function [pandas.DataFrame.pivot_table]
        ,'values_fn' : sum
        #Below parameters represent [**kw] for [DBuse_MrgKPItoInf]
        ,'fill_value' : 0
    }
})

#700. Instantiate universal calendar objects for date retrieval and shifting process
#Below classes are from [omniPy.Dates]
#710. Create Business calendar from 5 years ago to 1 month later, counting from [datetime.date.today()]
G_clndr = opy.Dates.UserCalendar( **getOption['args.Calendar'] )

#720. Create Business date-shifting tool covering the period from 5 years ago to 1 month later, counting from [datetime.date.today()]
G_obsDates = opy.Dates.ObsDates( **getOption['args.Calendar'] )
