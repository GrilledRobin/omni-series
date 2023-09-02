#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os
import pandas as pd
from collections.abc import Iterable
from omniPy.AdvOp import apply_MapVal, get_values
from omniPy.Dates import asDates

def parseDatName(
    datPtn = None
    ,parseCol = None
    ,dates = None
    ,outDTfmt : dict = {
        'L_d_curr' : '%Y%m%d'
        ,'L_m_curr' : '%Y%m'
    }
    ,inRAM : bool = False
    ,chkExist : (bool, str) = True
    ,dict_map : dict = {}
    ,**kw
) -> 'Parse the names of the files from the input string pattern and check their existence if requested':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the input string by the provided mapping dictionary, esp. for the provided [dates], to generate #
#   | the full paths of the files as indicated in the input string                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Generate a list of file full paths in terms of the provided naming convention and date series, also check their existence if   #
#   |     requested                                                                                                                     #
#   |[2] Translate the string patterns in all cells of a provided data frame by the provided [dict_map], resembling the similar         #
#   |     function as [omniPy.AdvOp.apply_MapVal]                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |datPtn     :   The naming pattern of the data files, either located on the harddisk or in RAM of current session                   #
#   |               [ <str>          ]           Single string that represent the naming convention of a series of data files           #
#   |               [ <Iterable>     ]           Iterable of <str> in the same convention as above                                      #
#   |parseCol   :   The column(s) to be parsed if [datPtn] is provided a [pd.DataFrame]                                                 #
#   |               [None            ] <Default> Parse all columns for [datPtn] where applicable                                        #
#   |dates      :   Date series that is used to substitute the corresponding naming patterns in [datPtn] to generate valid data paths   #
#   |               [ <date>         ]           Any value that can be parsed by the default arguments of [omniPy.Dates.asDates]        #
#   |outDTfmt   :   Format of dates as string to be used for substitution. Its [keys] should exist in the [values] of [dict_map]        #
#   |               [ <dict>         ] <Default> See the function definition as the default argument of usage                           #
#   |inRAM      :   Whether the [datPtn] that corresponds to the full paths of data files indicates they are in RAM of current session  #
#   |               [False           ] <Default> Indicates that the data files are stored on harddisk                                   #
#   |               [True            ]           Indicates that the data files are stored in RAM of current session                     #
#   |               [ <Iterable>     ]           Iterable of <bool> in the same convention as above                                     #
#   |chkExist   :   Whether to check the data file existence after the parse of the full paths of the them                              #
#   |               [True            ] <Default> Try to locate the parsed data paths                                                    #
#   |               [False           ]           Do not check the existence of the parsed data paths                                    #
#   |               [ <str>          ]           Try to locate the parsed data paths by appending the requested naming suffix, see      #
#   |                                             the output naming convention as in [Return values]                                    #
#   |dict_map   :   Same argument as in [omniPy.AdvOp.apply_MapVal]                                                                     #
#   |               [{}              ] <Default> Indicates that [datPtn] does not require translation by pattern                        #
#   |kw         :   Various named parameters for [omniPy.AdvOp.apply_MapVal] during import; see its official document                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |df         :   [pd.DataFrame] with below set of columns:                                                                           #
#   |               [1] When [datPtn] is a string or [datPtn] is an unnamed [Iterable], add two columns with the translated paths as:   #
#   |                   ['datPtn'] and ['datPtn.Parsed']                                                                                #
#   |               [2] When [datPtn] is a named [Iterable] or a [pd.DataFrame], add column(s) with the translated paths as:            #
#   |                   [datPtn.names] and [ c + '.Parsed' for c in datPtn.names ]                                                      #
#   |               [3] When [dates] is provided, add one column created by [omniPy.Date.asDates] as:                                   #
#   |                   ['dates'] <dtype: object> with values in the class as <datetime.date>                                           #
#   |               [4] When [datPtn] is a string or [datPtn] is an unnamed [Iterable], add one column with the indicator as:           #
#   |                   ['datPtn.inRAM']                                                                                                #
#   |               [5] When [datPtn] is a named [Iterable] or a [pd.DataFrame], add column(s) with the indicator(s) as:                #
#   |                   [ c + '.inRAM' for c in datPtn.names ]                                                                          #
#   |               [6] When [datPtn] is a string or [datPtn] is an unnamed [Iterable] and [chkExist!=False], add one column as:        #
#   |                   ['datPtn.' + ( 'chkExist' if chkExist or <str> )]                                                               #
#   |               [7] When [datPtn] is a named [Iterable] or a [pd.DataFrame] and [chkExist!=False], add column(s) as:                #
#   |                   [ c + '.' + ( 'chkExist' if chkExist or <str> ) for c in datPtn.names ]                                         #
#   |               [8] When [datPtn] is a named [Iterable] or a [pd.DataFrame] there is a column [dates] in it, rename it as:          #
#   |                   ['dates.original']  (to differ from ['dates'] that is created in this function)                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210529        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210614        | Version | 1.01        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when the input [datPtn] has zero length                                                                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210828        | Version | 1.02        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Reset the index of input data frame anyway, as there may be cartesian join between it and the date values and we should #
#   |      |     therefore ensure a consistent output                                                                                   #
#   |      |[2] Change the way to assign list of values to a subset of data frame, to facilitate the syntax of [pandas >= 1.2.1]        #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211228        | Version | 1.03        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] No longer reset the index when there is no cartesian join                                                               #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, os, pandas, collections                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |get_values                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |asDates                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.
    #from imp import find_module

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Handle the parameter buffer.
    #We avoid ambiguous statement if this argument is provided a [pd.DataFrame] or [pd.Series]
    if dates is not None:
        if not isinstance(outDTfmt, dict):
            raise TypeError('[' + LfuncName + '][outDTfmt] must be a dict!')
    if not dict_map: dict_map = {}
    if not isinstance(dict_map, dict):
        raise TypeError('[' + LfuncName + '][dict_map] must be a dict!')
    if kw is None: kw = {}

    #013. Define the local environment.

    #020. Transform [dates]
    if dates is not None:
        dates = (
            pd.DataFrame(asDates(pd.Series(dates, dtype = 'object')))
            .rename(columns = { 0 : 'dates' })
        )

    #030. Transform [datPtn]
    if isinstance(datPtn, pd.DataFrame):
        df_ptn = datPtn.copy(deep=True)
    elif isinstance(datPtn, pd.Series):
        df_ptn = pd.DataFrame(datPtn)
    elif isinstance(datPtn, Iterable):
        df_ptn = pd.DataFrame({ 'datPtn' : pd.Series(datPtn, dtype = 'object') })
    else:
        raise TypeError('[' + LfuncName + '][datPtn] must be a string, or [Iterable] of the previous!')
    #Quote: https://www.geeksforgeeks.org/how-to-rename-columns-in-pandas-dataframe/
    if 'dates' in df_ptn.columns:
        df_ptn.rename(columns = { 'dates' : 'dates.original' }, inplace = True)

    #040. Transform [parseCol]
    if isinstance(parseCol, str):
        parseCol = [parseCol]
    elif isinstance(parseCol, Iterable):
        parseCol = list(parseCol)
    if isinstance(datPtn, pd.DataFrame) & (parseCol is not None):
        names_trans = parseCol
    else:
        names_trans = df_ptn.columns
    names_resolve = [ v + '.Parsed' for v in names_trans ]

    #070. Transform [inRAM]
    if isinstance(inRAM, pd.DataFrame):
        pass
    elif isinstance(inRAM, Iterable):
        inRAM = pd.DataFrame(inRAM, dtype = 'bool')
    elif isinstance(inRAM, bool):
        inRAM = df_ptn[names_trans].map(lambda x: inRAM)
    else:
        raise TypeError('[' + LfuncName + '][inRAM] must be boolean, or [Iterable] of the previous!')
    df_ptn[[ v + '.inRAM' for v in names_trans ]] = inRAM

    #080. Translate [chkExist]
    if isinstance(chkExist, bool):
        col_exist = [ v + '.chkExist' for v in names_trans ] if chkExist else None
    elif isinstance(chkExist, str):
        col_exist = [ v + '.' + chkExist for v in names_trans ]
    else:
        raise TypeError('[' + LfuncName + '][chkExist] must be boolean or a single string!')

    #100. Define helper functions to be applied to interim data frames
    #110. Translate naming patterns by the mapping dictionary
    def rowTranslate(row):
        #001. Directly return the input if it has no row

        #100. Assign local variables for later step to get their respective values by batch
        #These variables may be created in the frames at the lower call stacks,
        # hence it is not necessary to create them in current frame
        if 'dates' in ptn_comb.columns:
            sys._getframe().f_locals.update({ k : row['dates'].strftime(v) for k,v in outDTfmt.items() })

        #400. Translate the mapping dictionary at first by the values of above local variables
        get_Trans_val = get_values(**dict_map)

        #700. Translate the naming patterns by the new mapping dictionary
        rst = apply_MapVal( row[names_trans], dict_map = get_Trans_val, **kw )

        #999. Return the result
        return(rst)

    #150. Create column(s) that indicate the data file existence
    def rowExistence(row):
        #100. Verify the file existence in terms of the indicators
        rst = tuple(
            isinstance(get_values(row[names_resolve[i]]), pd.DataFrame) if row[v + '.inRAM'] else os.path.isfile(row[names_resolve[i]])
            for i,v in enumerate(names_trans)
        )

        #500. Only output a single value if the input has only one element
        if len(names_trans) == 1: rst = rst[0]

        #999. Return the result
        return(rst)

    #400. Conduct translation of the naming pattern
    ptn_comb = df_ptn.copy(deep=True)
    if (len(dict_map) > 0) & (len(ptn_comb) > 0):
        #100. Create cartesian join of the naming patterns and dates
        if isinstance(dates, pd.DataFrame):
            if len(dates):
                ptn_comb = df_ptn.merge(dates, how = 'cross')
            if len(dates) > 1:
                ptn_comb.reset_index(drop = True, inplace = True)

        #500. Translation by the helper function
        # sys._getframe(1).f_globals.update({ 'chkdat' : ptn_comb })
        ptn_comb[names_resolve] = ptn_comb.apply(rowTranslate, axis = 1)
    else:
        #100. Consider there is no need for translation
        ptn_comb[names_resolve] = ptn_comb[names_trans]

    #700. Check file existence if requested
    if col_exist:
        #The output value could possibly be [pd.Series with value type as 'tuple'],
        # hence we have to transform it into [list] for assignment of multiple columns
        if len(ptn_comb):
            ptn_comb.loc[:, col_exist] = ptn_comb.apply(rowExistence, axis = 1).tolist()
        else:
            ptn_comb[col_exist] = False

    #999. Return the result
    return(ptn_comb)
#End parseDatName

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
    from omniPy.AdvOp import exec_file
    from omniPy.AdvDB import parseDatName

    #050. Prepare necessities
    #Dictionary [getOption] is defined in below file
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Test if a data frame exists in current session
    aa = pd.DataFrame({ 'a' : [1,2,3] })
    exist_aa = parseDatName(
        datPtn = 'aa'
        ,inRAM = True
    )

    #200. Test for multiple file patterns in multiple dates
    exist_bb = parseDatName(
        datPtn = [
            r"D:\R\omniR\SampleKPI\KPI\k ','\kpi&L_curdate..sas7bdat"
            ,r'D:\R\omniR\SampleKPI\KPI\K 2\kpi2_&L_curdate..sas7bdat'
        ]
        ,dates = ['20160329', '20160603', '20161019']
        ,outDTfmt = getOption['fmt.parseDates']
        ,inRAM = False
        ,dict_map = getOption['fmt.def.GTSFK']
        ,**getOption['fmt.opt.def.GTSFK']
    )

    #300. Test multiple files
    test20160604 = pd.DataFrame({ 'a' : [1,2,3] })
    testmulti = pd.DataFrame(
        {
            'datIn' : r"D:\R\omniR\SampleKPI\KPI\k ','\kpi&L_curdate..sas7bdat"
            ,'datOut' : 'test&L_curdate.'
            ,'fRAM_In' : False
            ,'fRAM_Out' : True
        }
        ,index = [0]
    )
    exist_cc = parseDatName(
        datPtn = testmulti[['datIn', 'datOut']]
        ,dates = ['20160602', '20160603', '20160604']
        ,outDTfmt = getOption['fmt.parseDates']
        ,inRAM = testmulti[['fRAM_In', 'fRAM_Out']]
        ,chkExist = True
        ,dict_map = getOption['fmt.def.GTSFK']
        ,**getOption['fmt.opt.def.GTSFK']
    )

    #390. Test if the input has zero [nrow]
    testmulti2 = testmulti[[False]]
    exist_dd = parseDatName(
        datPtn = testmulti2[['datIn', 'datOut']]
        ,dates = ['20160602', '20160603', '20160604']
        ,outDTfmt = getOption['fmt.parseDates']
        ,inRAM = testmulti2[['fRAM_In', 'fRAM_Out']]
        ,chkExist = True
        ,dict_map = getOption['fmt.def.GTSFK']
        ,**getOption['fmt.opt.def.GTSFK']
    )
#-Notes- -End-
'''
