#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
from copy import deepcopy
from . import locSubstr

def strBalancedGroup(
    txt
    ,lBound = '('
    ,rBound = ')'
    ,rx = False
    ,include = True
) -> 'Get the substrings in terms of the balanced group surrounded by the provided boundaries':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the substrings surrounded by the provided boundaries, in terms of the concept of Balanced     #
#   | Group in Regular Expression (while NOT using RegExp as it would fail in many cases)                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use [BeautifulSoup] instead)            #
#   |[2] Resolve the jinja-like expression such as: f<g<a>>, when [a] is a variable, [g<a>] is another, and so forth                    #
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
#   |include    :   Whether to include the bounding characters in the output substrings                                                 #
#   |               [True       ] <Default> Include the bounds as output                                                                #
#   |               [False      ]           Exclude the bounds as output                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List of substrings out of each pair of boundaries as a Balanced Group                                               #
#   |               [IMPORTANT]                                                                                                         #
#   |               [1] If the bounds do not exist in pairs, a list of [None] is returned                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, re, copy                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
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
        return([None])
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
        lBound = re.escape(lBound)
        rBound = re.escape(rBound)

    #050. Local parameters

    #100. Compare the occurrences of both bounds and stop if they do not match
    #Return value of below function is a list of tuples comprised of start and end positions
    posLB = locSubstr(lBound, txt, overlap = False)
    posRB = locSubstr(rBound, txt, overlap = False)
    kLB = len(posLB)
    kRB = len(posRB)

    #109. Return a list of [None] to form a consistent output
    if (kLB == 0) or (kLB != kRB):
        return([None])

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

    #500. Identify the start and end positions to extract for each group
    #[ASSUMPTION]
    #[1] The number of Balanced Groups is the same as the number of left bounds
    pos_ext = []
    for m in posLB:
        #100. Get the index of current group among all the positions
        #Quote: https://stackoverflow.com/questions/176918/finding-the-index-of-an-item-in-a-list
        idx = pos_all.index(m)

        #300. Define the start position to extract for the output of current group
        bgn = m[0 if include else -1]

        #500. Retrieve the marker of current group, i.e. the counter of current group
        marker = balgrp[idx]

        #700. Define the end position to extract
        #[ASSUMPTION]
        #[1] We locate the very first one of the same markers from the right side of current one
        #[2] the [idx] of the left bound will always be less then the length of the input string, hence add it by 1 is safe
        end = pos_all[balgrp.index(marker, idx + 1)][-1 if include else 0]

        #900. Append current output group to the final result
        pos_ext.append((bgn,end))

    #900. Extract the substrings in the same sequence as the occurrences of the left bounds
    return([ txt[bgn:end] for bgn,end in pos_ext ])
#End strBalancedGroup

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import strBalancedGroup

    #100. Prepare strings
    teststr = '(bb (cc (dd))) aa (ee (ff))'
    testjinja = '{{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1"><div id="2"></div><div id="3"></div></div>'

    #200. Extraction
    ext_parens = strBalancedGroup(
        teststr
        ,lBound = '('
        ,rBound = ')'
        ,rx = False
        ,include = True
    )

    ext_jinja = [
        m.strip()
        for m in strBalancedGroup(
            testjinja
            ,lBound = '{{'
            ,rBound = '}}'
            ,rx = False
            ,include = False
        )
    ]

    ext_html = [
        m.strip()
        for m in strBalancedGroup(
            testhtml
            ,lBound = '<div.*?>'
            ,rBound = '</div>'
            ,rx = True
            ,include = True
        )
    ]
#-Notes- -End-
'''