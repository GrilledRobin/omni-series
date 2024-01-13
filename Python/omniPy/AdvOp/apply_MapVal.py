#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import pandas as pd
from copy import deepcopy
from collections.abc import Iterable

def apply_MapVal(
    vec
    ,dict_map
    ,preserve : bool = True
    ,placeholder : bool = True
    ,force_mark : str = '...'
    ,fPartial : bool = False
    ,PRX : bool = False
    ,full_match : bool = True
    ,ignore_case : bool = False
) -> any:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to map the values within the provided list or vector into another set of values by the given dictionary  #
#   | a.k.a. the similar function as [Format Procedure] in SAS.                                                                         #
#   |It also acts as a helper function to conduct value mapping in a data frame via [apply] function from [pandas] package, see below   #
#   | examples. However, it is strongly recommended NOT to use [Series.apply(f)], but use [f(Series)], to make it efficient.            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Special case: when using [df['aa'] = df['bb'].apply( functools.partial(apply_MapVal , mydict) )] or [lambda]                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT] For any zero-length pd.Series, make sure to use [astype] as below to convert the column type if the type of [value] in #
#   |             the provided [dict] is NOT [str]! Otherwise [pandas] will imperatively convert the output (whic is also zero-length)  #
#   |             into [np.float64], which might be unexpected.                                                                         #
#   |[EXAMPLE  ] mytypes = list(set([ type(v) for v in mydict.values() ]))                                                              #
#   |            df['aa'] = df['bb'].apply( functools.partial(apply_MapVal , mydict) ).astype(mytypes[0])                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec         :   List or vector of values to be mapped into another set of values (also accept a column in a data.frame when used   #
#   |                 in [mutate] function of [dplyr] package)                                                                          #
#   |dict_map    :   List or vector of value mapping within which: [names] represent the values to be mapped from the [vec]; [values]   #
#   |                 represent the new values as mapping result                                                                        #
#   |                [IMPORTANT] Unlike FORMAT Procedure in SAS, the same name cannot exist twice in a Python [dict]; hence we cannot   #
#   |                             define the process for a multiple match                                                               #
#   |preserve    :   Logical value indicating whether to preserve the input values if they cannot be mapped in the given dictionary     #
#   |                 [TRUE        ]  <Default> Preserve the original values if there is mo mapping for them                            #
#   |                 [FALSE       ]             Discard the input values and output an [NA] in place if there is no mapping for them   #
#   |placeholder :   The placeholder for output if the length (i.e. number of elements) of the entire input vector is 0                 #
#   |                 [TRUE        ]  <Default> Output a zero-length placeholder in the same type as the values in [dict_map]           #
#   |                 [FALSE       ]            Do not output a placeholder                                                             #
#   |force_mark  :   The name in the [dict_map] with value to force output when there is no mapping result for the input value while    #
#   |                 the parameter [preserve] is set FALSE.                                                                            #
#   |                 [...         ]  <Default> Output the value in the name of '...' in the [dict_map] when condition is fulfilled     #
#   |                 [(char. str) ]            Output the value in the name of '(char. str)' in the [dict_map] when condition is       #
#   |                                            fulfilled                                                                              #
#   |fPartial    :   Whether to partially replace the input values by the mapping dictionary                                            #
#   |                 [FALSE       ]  <Default> Replace the entire string if it matches any name in the dictionary, i.e. DO NOT keep    #
#   |                                            the rest of the the input [vec] given they are not matched in the dictionary           #
#   |                 [TRUE        ]            Replace the matching part of the string with the value in the dictionary                #
#   |PRX         :   Whether to use Perl Regular Expression to conduct the replacement                                                  #
#   |                 [FALSE       ]  <Default> Match the string without Perl Regular Expression, i.e. no special character patterns    #
#   |                 [TRUE        ]            Match the string with Perl Regular Expression                                           #
#   |                 [list/vector ]            Match each element in the input [dict_map] with/without PRX respectively                #
#   |full_match  :   Whether to match the entire input string within [vec]                                                              #
#   |                 [TRUE        ]  <Default> The match is valid ONLY WHEN the first match is on the first character AND its length   #
#   |                                            is the same as the number of characters of the input [vec]                             #
#   |                 [FALSE       ]            Any sub-string in [vec] that matches anyone in the dictionary will suffice the rule     #
#   |ignore_case :   Same as that in the official document for [gregexpr]                                                               #
#   |                 [list/vector ]            Extend the parameter by applying this rule to each element respectively                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ list  ]   :   The mapped result stored in a list (not a tuple as a tuple cannot be added as a column in a data frame if needed)  #
#   |                If the input is only a single string, the output is NO LONGER a list, but the same type of value as in [dict_map]  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210220        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210317        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add support for [pandas.DataFrame]                                                                                      #
#   |      |    One can now use the form of [aaa = apply_MapVal(df, **kw)] to process the whole data frame or a batch of columns        #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210503        | Version | 1.11        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Clean the process for different input types                                                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210620        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Arguments [PRX] and [ignore_case] now only accept [bool] values to reduce the function complexity                       #
#   |      |[2] Introduce [functools.reduce] to sanitize the function logic (although without performance improvement)                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210624        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the entire function to utilize the helper function for [re.sub], which raises the speed by 30 times             #
#   |      |[2] Remove the dependency on [functools.reduce]                                                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210923        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Create a deep copy of the input mapping dict to avoid its change in the caller frame                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240110        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when ignoring case during pattern matching                                                                  #
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
#   |   |sys, re, pandas, collections                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if not isinstance( dict_map , dict ):
        raise TypeError('[' + LfuncName + '][dict_map]:[{0}] must be [dict]!'.format( type(dict_map) ))
    if not isinstance( preserve , bool ):
        raise TypeError('[' + LfuncName + '][preserve]:[{0}] must be [bool]!'.format( type(preserve) ))
    if not isinstance( placeholder , bool ):
        raise TypeError('[' + LfuncName + '][placeholder]:[{0}] must be [bool]!'.format( type(placeholder) ))
    if not isinstance( fPartial , bool ):
        raise TypeError('[' + LfuncName + '][fPartial]:[{0}] must be [bool]!'.format( type(fPartial) ))
    if not isinstance( PRX , bool ):
        raise TypeError('[' + LfuncName + '][PRX]:[{0}] must be [bool]!'.format( type(PRX) ))
    if not isinstance( full_match , bool ):
        raise TypeError('[' + LfuncName + '][full_match]:[{0}] must be [bool]!'.format( type(full_match) ))
    if not isinstance( ignore_case , bool ):
        raise TypeError('[' + LfuncName + '][ignore_case]:[{0}] must be [bool]!'.format( type(ignore_case) ))

    #070. Determine the flags for regex
    flags = re.I if ignore_case else 0
    int_map = deepcopy(dict_map)

    #100. Translate [dict_map] on different scenarios
    #110. Extract the special mapping value [force_mark] as it has nothing to do with the substitution in general
    if force_mark in int_map:
        #100. Extract the value to replace all input ones that satisfy the conditions to force output
        map_force = str(int_map.get(force_mark))

        #900. Exclude the mapping for [force_mark] for general mapping process
        int_map.pop(force_mark)
    else:
        map_force = None

    #150. Convert the keys of [dict_map] into strings if they are not
    if PRX:
        int_map = { str(k) : str(v) for k,v in int_map.items() }
    else:
        int_map = { re.escape(str(k)) : str(v).replace('\\',r'\\') for k,v in int_map.items() }

    #170. Combine all patterns into one, using [|] to indicate [any] during the matching
    dict_comb = '|'.join( k for k in int_map.keys() )
    ptn_comb = re.compile(dict_comb, flags)

    #200. Prepare helper functions
    #210. Function to conduct substitution for each pair of [pattern -> replacement] respectively
    #[ASSUMPTION]
    #[1] [matchobj[0]] always represents the whole string if one requests [full match]
    #[2] We have to look up for which [key] in [int_map] that matches current element within [matchobj]
    def repl_pair(matchobj):
        for k,v in int_map.items():
            if re.fullmatch(k, matchobj[0], flags = flags):
                return(v)

    #600. Define the mapping function to apply to each element of [vec]
    def trans_val(val_in):
        #001. Change the [val_in] into string for further calculation
        val_rep = str(val_in)

        #100. Detect whether there is a match to any among the patterns
        v_match = ptn_comb.fullmatch(val_rep) if full_match else ptn_comb.search(val_rep)

        #500. Conduct the substitution on different scenarios
        if v_match:
            if fPartial:
                return(ptn_comb.sub(repl_pair, val_rep))
            else:
                for k,v in int_map.items():
                    #100. Prepare function to match each [key] in [int_map] respectively
                    ptn_mini = re.compile(k, flags)
                    match_func = ptn_mini.fullmatch if full_match else ptn_mini.search

                    #900. Output the whole [value] in [int_map] if any pattern is matched
                    if match_func(val_rep):
                        return( v if PRX else v.replace(r'\\','\\') )
        else:
            #100. Determine the output value
            if preserve: val_rep = str(val_in)
            elif (not preserve) & (map_force is not None): val_rep = map_force
            else: val_rep = None

            #999. Return the mapped result
            return(val_rep)

    #900. Output.
    #990. Determine the process for different input types
    if isinstance( vec , pd.DataFrame ):
        return( vec.map(trans_val).astype(str) )
    elif isinstance( vec , pd.Series ):
        return( vec.apply(trans_val).astype(str) )
    elif isinstance( vec , str ):
        return( trans_val(vec) )
    elif isinstance( vec , Iterable ):
        return( list(map(trans_val , vec)) )
    else:
        return( trans_val(vec) )
#End apply_MapVal

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import datetime as dt
    import numpy as np
    import pandas as pd
    from functools import partial
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import apply_MapVal
    print(apply_MapVal.__doc__)

    mydict = {
        'a' : 'old'
        ,'b' : 'new'
        ,'c' : 'unknown'
    }
    usr_val = [ 'a' , 'b' ]
    usr_val2 = 'a'
    usr_val3 = ''
    usr_df = pd.DataFrame( { 'old' : [ 'a' , 'b' , 'c' ] } )

    #100. Map the values in a vector
    map_val = apply_MapVal(usr_val, mydict)
    map_val2 = apply_MapVal(usr_val2, mydict)
    map_val3 = apply_MapVal(usr_val3, mydict)

    #200. Map the values in a data.frame
    map_df = usr_df.copy()
    map_df['new_var'] = apply_MapVal(map_df['old'], mydict)
    map_df['new_var2'] = map_df['old'].apply( partial(apply_MapVal, dict_map = mydict) )
    map_df.head()

    #300. Test upon an empty data.frame
    empty_df = pd.DataFrame( { 'old' : pd.Series([], dtype = str) } )
    empty_df['new_var'] = apply_MapVal(empty_df['old'], mydict)
    empty_df['new_var2'] = empty_df['old'].apply( partial(apply_MapVal, dict_map = mydict) )
    empty_df.dtypes

    #400. Test placeholder
    mydict3 = {
        'a' : 1
        ,'b' : 2
        ,'c' : 3
    }
    d3types = list(set([ type(v) for v in mydict3.values() ]))

    from sklearn.datasets import load_iris
    aa = pd.DataFrame( load_iris().data , columns = [ 'Sepal Length', 'Sepal Width', 'Petal Length' , 'Petal Width' ] )
    aa.columns.values
    bb = aa.loc[ aa['Sepal Length'] == 100 ].copy()
    bb['new_var'] = apply_MapVal(bb['Sepal Length'], mydict3)

    #[IMPORTANT] For any zero-length pd.Series, make sure to use [astype] as below to convert the column type if the
    #             type of [value] in the provided [dict] is NOT [str]! Otherwise [pandas] will imperatively convert
    #             the output (whic is also zero-length) into [np.float64], which might be unexpected.
    bb['new_var2'] = bb['Sepal Length'].apply( partial(apply_MapVal, dict_map = mydict3) ).astype(str)
    bb.dtypes

    #500. Test different value types in the mapping dictionary
    mydict4 = {
        3 : '6.5'
        ,4 : 7
        ,6 : np.int64(9)
        ,'8' : np.float64(15.5)
        #The name of below item should match that in the parameter [force_mark]
        ,'...' : 10.5
    }
    chkval = [4,3,5]
    chkvaltypes = list(set([ type(v) for v in chkval ]))

    map2_vec = apply_MapVal(chkval, mydict4)
    apply_MapVal(5, mydict4)

    #600. Test to partially replace a number
    mydict5 = {
        3.5 : '6.5'
        ,4 : 7
        #The name of below item should match that in the parameter [force_mark]
        ,'...' : 10.5
    }
    chkval2 = [4,13.5,5]

    map3_vec = apply_MapVal(chkval2, mydict5, fPartial = True, full_match = False)
    map3_vec2 = apply_MapVal(chkval2, mydict5, fPartial = True, full_match = False, preserve = False)

    #650. Test [fPartial] for [regex]
    dict_part = {r'a.+b' : 'cc'}
    chkval3 = 'a456bdd'
    map4_vec = apply_MapVal(chkval3, dict_part, fPartial = True, full_match = False, PRX = True)
    map4_vec2 = apply_MapVal(chkval3, dict_part, fPartial = False, full_match = False, PRX = True)

    #700. Test multiple occurrences in one string
    fTrans = {
        r'&L_curdate\.' : 'G_d_curr'
        ,r'&L_curMon\.' : 'G_m_curr'
        ,r'&L_prevMon\.' : 'G_m_prev'
        ,r'&c_date\.' : 'G_d_curr'
    }
    PRX = True
    test_var = [ 'rpt_&L_curMon._&c_date._&c_date..sas7bdat' , 'rpt_&L_curMon..sas7bdat' ]
    G_d_curr = '20160310'
    G_m_curr = G_d_curr[:6]

    #Quote: https://stackoverflow.com/questions/9437726/how-to-get-the-value-of-a-variable-given-its-name-in-a-string
    get_list_val = { k : locals()[v] if v in locals() else globals()[v] if v in globals() else v for k,v in fTrans.items() }

    test_opt = {
        'fPartial' : True
        ,'full_match' : False
        ,'ignore_case' : True
        ,'PRX' : PRX
    }

    match_v3 = apply_MapVal( test_var , get_list_val , **test_opt )

    #750. Test the timing
    test_sample = [
        v + '.sas7bdat'
        for v in [
            'rpt_&L_curMon._&c_date._&c_date.'
            ,'rpt_&L_curMon.'
            ,'rpt'
            ,'rpt_aa_&c_date.'
            ,'ttt&c_date.__bb'
            ,'ccc&L_curdate.__'
        ]
    ]
    ttt = np.random.choice(test_sample, 100000, replace = True)

    time_bgn = dt.datetime.now()
    test_result = apply_MapVal(ttt, get_list_val, **test_opt)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 1.2 s (5 times slower than the same function in R, as that one in R is based on C/C++)
    # 32.53 s (Using [for] loop or [functools.reduce] upon one [vec] out of [dict_map])
    test_result[-10:]

#-Notes- -End-
'''
