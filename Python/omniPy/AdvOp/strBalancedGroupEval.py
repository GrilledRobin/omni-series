#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
from copy import deepcopy
from omniPy.AdvOp import get_values, locSubstr

def strBalancedGroupEval(
    txt
    ,lBound = '('
    ,rBound = ')'
    ,rx = False
) -> 'Evaluate the string in terms of the balanced group surrounded by the provided boundaries':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to evaluate the substrings surrounded by the provided boundaries, in terms of the concept of Balanced    #
#   | Group in Regular Expression (while NOT using RegExp as it would fail in many cases), and then replace their respective positions  #
#   | with their parsed values in current environment, i.e. treat them as variables in current session                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Resolve the jinja-like expression such as: f<g<a>>, when [a] is a variable, [g<a>] is another, and so forth                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt        :   Character string from which to extract the substrings                                                               #
#   |lBound     :   Left bound of the substring, can be provided with a string, which will be stripped and then treated as a whole      #
#   |               [(          ] <Default> A single left parenthesis                                                                   #
#   |rBound     :   Right bound of the substring, can be provided with a string, which will be stripped and then treated as a whole     #
#   |               [)          ] <Default> A single right parenthesis                                                                  #
#   |rx         :   Whether to treat the [lBound] and [rBound] as Regular Expression                                                    #
#   |               [False      ] <Default> Treat them as raw character strings                                                         #
#   |               [True       ]           Treat them as regular expressions                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>      :   The character string with possible replacement at the positions of Balanced Group Expressions                       #
#   |               [1] Expressions such as : f<g<a>>, will be evaluated in recursion                                                   #
#   |               [2] Given that any expression, such as: <a>, is not a known variable in current session, it will be treated as      #
#   |                    plain text with the bounds removed in the output result                                                        #
#   |               [Special Case] When the whole string is surrounded by the bounds and its evaluation is successful, the return value #
#   |                               will be the same as its referenced object, which may be of any type                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
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
#   |   |sys, re, copy                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#   |   |   |locSubstr                                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance( txt , str ):
        raise TypeError('[' + LfuncName + '][txt]:[{0}] must be provided a character string!'.format( type(txt) ))
    if len(txt) == 0:
        return('')
    if not isinstance( lBound , str ):
        raise TypeError('[' + LfuncName + '][lBound]:[{0}] must be provided a character string!'.format( type(lBound) ))
    lBound = deepcopy(lBound).strip()
    if len(lBound) == 0:
        raise ValueError('[' + LfuncName + '][lBound]:[{0}] must be at least one non white space character!'.format( lBound ))
    if not isinstance( rBound , str ):
        raise TypeError('[' + LfuncName + '][rBound]:[{0}] must be provided a character string!'.format( type(rBound) ))
    rBound = deepcopy(rBound).strip()
    if len(rBound) == 0:
        raise ValueError('[' + LfuncName + '][rBound]:[{0}] must be at least one non white space character!'.format( rBound ))
    if lBound == rBound:
        raise ValueError('[' + LfuncName + '][lBound]:[{0}] and [rBound]:[{1}] must be different strings!'.format( lBound, rBound ))
    if not isinstance( rx , bool ):
        raise TypeError('[' + LfuncName + '][rx]:[{0}] must be provided a bool!'.format( type(rx) ))
    if not rx:
        lBound_i = re.escape(lBound)
        rBound_i = re.escape(rBound)
    else:
        lBound_i = lBound
        rBound_i = rBound

    #050. Local parameters

    #100. Compare the occurrences of both bounds and stop if they do not match
    #Return value of below function is a list of tuples comprised of start and end positions
    posLB = locSubstr(lBound_i, txt, overlap = False)
    posRB = locSubstr(rBound_i, txt, overlap = False)
    kLB = len(posLB)
    kRB = len(posRB)

    #109. Return the input string if the left bound and the right one do not exist in pairs
    if (kLB == 0) or (kLB != kRB):
        return(deepcopy(txt))

    #300. Prepare Balanced Group
    #Quote: https://stackoverflow.com/questions/49138587/find-all-parentheses-in-a-string-by-pairs-python-3
    #310. Combine all the positions found and sort the list by their starting positions
    pos_all = sorted(posLB + posRB, key = lambda x: x[0])

    #330. Prepare the adjuster of the Balanced Group
    pos_adj = [ 0 if m in posLB else 1 for m in pos_all ]

    #350. Add 1 on group ID if we encounter the left bound, or subtract by 1 if we encounter the round bound
    pos_cnt = []
    cnt_i = 0
    for m in pos_all:
        if m in posLB:
            cnt_i += 1
        else:
            cnt_i -= 1

        pos_cnt.append(cnt_i)

    #370. Post-increment by 1 for the counters on the right bound
    balgrp = [ v + pos_adj[i] for i,v in enumerate(pos_cnt) ]

    #500. Replace the group with the largest ID (aka the inner-most group) with its parsed value
    #510. Identify the ID of the inner-most groups
    max_grp = max(balgrp)
    #Retrieve the first among the IDs as initiation
    #Quote: https://stackoverflow.com/questions/176918/finding-the-index-of-an-item-in-a-list
    idx_grp = balgrp.index(max_grp)
    #The same Group ID always exists in pairs
    k_grp = int(balgrp.count(max_grp) / 2)

    #550. Determine the replacement of each identified group
    rep_grp = []
    for i in range(k_grp):
        #100. Define the start position of current group
        bgn_get = pos_all[idx_grp][-1]
        bgn_rep = pos_all[idx_grp][0]

        #300. Define the right bound of current group
        #[ASSUMPTION]
        #[1] We locate the very first one of the same markers from the right side of current one
        #[2] the [idx] of the left bound will always be less then the length of the input string, hence add it by 1 is safe
        idx_right = balgrp.index(max_grp, idx_grp + 1)

        #500. Define the end position of current group
        end_get = pos_all[idx_right][0]
        end_rep = pos_all[idx_right][-1]

        #700. Evaluate the extracted expression after stripping it
        val = get_values( txt[bgn_get:end_get].strip(), inplace = True )

        #800. Directly return the evaluated result if the entire string is surrounded by the bounds
        if bgn_rep == 0 and end_rep == len(txt):
            return(val)

        #900. Append indicators for later replacement process
        rep_grp.append((bgn_rep, end_rep, val))

        #990. Increment the counter
        try:
            idx_grp = balgrp.index(max_grp, idx_right + 1)
        except ValueError:
            break

    #570. Conduct replacement from right to left, which is safe
    #[list.reverse()] method replaces the original object
    rep_grp.reverse()
    rstMid = deepcopy(txt)
    for b,e,v in rep_grp:
        rstMid = rstMid[:b] + str(v) + rstMid[e:]

    #700. Process the new string by the provided bounds in recursion
    rstOut = strBalancedGroupEval(
        rstMid
        ,lBound = lBound
        ,rBound = rBound
        ,rx = rx
    )

    #900. Return the result
    return(rstOut)
#End strBalancedGroupEval

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import strBalancedGroupEval

    #100. Prepare strings
    fill_a = 'bb'
    fill_bb = 5
    teststr = '(gg (fill_(fill_a))) aa (ee (ff))'
    testjinja = '{{ fill_{{ fill_a }} }}'

    #200. Evaluation
    eval_str = strBalancedGroupEval(
        teststr
        ,lBound = '('
        ,rBound = ')'
        ,rx = False
    )

    eval_jinja = strBalancedGroupEval(
        testjinja
        ,lBound = '{{'
        ,rBound = '}}'
        ,rx = False
    )
#-Notes- -End-
'''
