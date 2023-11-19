#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
from copy import deepcopy
from warnings import warn
from omniPy.AdvOp import strNestedParser

def strBalancedGroup(
    txt : str
    ,lBound : str = '('
    ,rBound : str = ')'
    ,rx : bool = False
    ,include : bool = True
    ,flags : re.RegexFlag = re.NOFLAG
) -> list[str]:
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
#   |flags      :   Flags to modify the parsing of the RegExp upon <lBound> and <rBound>                                                #
#   |               [re.NOFLAG  ] <Default> Parse the RegExp <lBound> and <rBound> using no modifier                                    #
#   |               [RegexFlag  ]           Any (union of) <re.RegexFlag> to modify the parsing                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List of substrings out of each pair of boundaries as a Balanced Group                                               #
#   |               [IMPORTANT]                                                                                                         #
#   |               [1] If the bounds do not exist in pairs, an empty list is returned with a warning                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231118        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to uplift the efficiency by 450 times                                                              #
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
#   |   |sys, re, copy, warnings                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |strNestedParser                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(txt, str):
        raise TypeError(f'[{LfuncName}][txt]:[{type(txt)}] must be provided a character string!')
    if not txt:
        return([])
    if not isinstance(lBound, str):
        raise TypeError(f'[{LfuncName}][txt]:[{type(lBound)}] must be provided a character string!')
    lBound = deepcopy(lBound.strip())
    if len(lBound) == 0:
        raise ValueError(f'[{LfuncName}][lBound]:[{lBound}] must be at least one non white space character!')
    if not isinstance(rBound, str):
        raise TypeError(f'[{LfuncName}][txt]:[{type(rBound)}] must be provided a character string!')
    rBound = deepcopy(rBound.strip())
    if len(rBound) == 0:
        raise ValueError(f'[{LfuncName}][rBound]:[{rBound}] must be at least one non white space character!')
    if lBound == rBound:
        raise ValueError(f'[{LfuncName}][lBound]:[{lBound}] and [rBound]:[{rBound}] must be different strings!')
    if not isinstance(rx, bool):
        raise TypeError(f'[{LfuncName}][rx]:[{type(rx)}] must be provided a bool!')
    if not rx:
        lBound = re.escape(lBound)
        rBound = re.escape(rBound)

    #050. Local parameters

    #100. Parse the nested structure out of the input string
    #[ASSUMPTION]
    #[1] We always call the parser with RegExp, since the boundaries are already escaped when requested
    #[2] Since the parser will raise exception when there is un-Balanced Group, we catch it and return empty list as designed
    try:
        nest_struct = strNestedParser(txt, lBound, rBound, rx = True, include = include, flags = flags)
    except ValueError:
        warn(f'[{LfuncName}]Input string `{txt}` has un-Balanced boundaries!')
        nest_struct = []

    #200. Define helper functions
    #210. Function to join the nested structures into strings respectively with recursion
    def h_conj_str(struct : list):
        #[ASSUMPTION]
        #[1] Input structure always has the form: [<lBound,> <string | nested struct>, <rBound>], where
        #    [a] <lBound> and <rBound> exist or miss at the same time
        #    [b] When both boundaries are missing given <include is True>, the middle part must be a <nested struct>
        #[2] Hence there is no need to match the boundaries any more, we just need to join all strings directly.
        #100. Initialize
        rstOut = []
        str_struct = ''

        #500. Loop over the nested structure
        for m in struct:
            if isinstance(m, list):
                #100. Further process the structure of the next layer
                #[ASSUMPTION]
                #[1] We should never introduce <thisFunction()> to capture the frame as recursion in such a CPU-intense task
                #[2] The major CPU expense is on the dynamic compilation of such frame
                #[3] This function is never mutated (e.g. by decoration), hence there is no need to capture its frame dynamically
                next_struct = h_conj_str(m)

                #500. Extend the final result
                rstOut.extend(next_struct)

                #900. Extend the string for the structure of current layer
                str_struct += next_struct[-1]
            else:
                str_struct += m

        #800. Append the string of current structure to the final result
        rstOut.append(str_struct)

        #999. Purge
        return(rstOut)

    #500. Remove all <S> from the outmost layer of the nested structure
    #[ASSUMPTION]
    #[1] Given any substring that is not enclosed by the boundaries, we mark it as <S>
    #[2] According to the feature of the nested structure, <S> can only exist as L[0] or L[-1] in the outmost layer
    #[3] According to the feature of the nested structure, neither of the boundaries can exist in the outmost layer
    #[4] <S> in the outmost layer is not included in the output result of this function as designed
    nest_struct_cln = [ m for m in nest_struct if isinstance(m, list)]

    #900. Export
    return([ j for i in map(h_conj_str, nest_struct_cln) for j in i ])
#End strBalancedGroup

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import datetime as dt
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import strBalancedGroup

    #100. Prepare strings
    teststr = '-- (bb (cc (dd))) aa (ee (ff)) ~~'
    testjinja = '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg'

    #200. Extraction
    bg_parens = strBalancedGroup(
        teststr
        ,lBound = '('
        ,rBound = ')'
        ,rx = False
        ,include = True
    )

    bg_jinja = [
        m.strip()
        for m in strBalancedGroup(
            testjinja
            ,lBound = '{{'
            ,rBound = '}}'
            ,rx = False
            ,include = False
        )
    ]

    bg_html = [
        m.strip()
        for m in strBalancedGroup(
            testhtml
            ,lBound = '<div.*?>'
            ,rBound = '</div>'
            ,rx = True
            ,include = True
        )
    ]

    #300. Special cases
    chkstr = '-- <div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg <div id="4"> hhh </div> ~~'
    chkrst = strBalancedGroup(chkstr, lBound = r'<div.*?>', rBound = r'</div>', rx = True)
    # ['<div id="2"> ccc</div>',
    # '<div id="3">eee</div>',
    # '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div>',
    # '<div id="4"> hhh </div>']

    chkrst2 = strBalancedGroup(chkstr, lBound = r'<div.*?>', rBound = r'</div>', rx = True, include = False)
    # [' ccc', 'eee', 'bbb cccddd eeefff', ' hhh ']

    print(strBalancedGroup(''))
    # []

    print(strBalancedGroup(r'a'))
    # []

    print(strBalancedGroup(r'(a b)'))
    # ['(a b)']

    print(strBalancedGroup(r'a (b)'))
    # ['(b)']

    print(strBalancedGroup(r'(a) b'))
    # ['(a)']

    print(strBalancedGroup(r'(a ((b) c (d))) e (f (g))'))
    # ['(b)', '(d)', '((b) c (d))', '(a ((b) c (d)))', '(g)', '(f (g))']

    print(strBalancedGroup(r'(a ((b) c (d))) e (f (g))', include = False))
    # ['b', 'd', 'b c d', 'a b c d', 'g', 'f g']

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    bg_large = strBalancedGroup(str_large, lBound = r'<div.*?>', rBound = r'</div>', rx = True)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.091090
#-Notes- -End-
'''
