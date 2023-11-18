#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
from copy import deepcopy

def strNestedParser(
    txt : str
    ,lBound : str = '[(]'
    ,rBound : str = '[)]'
    ,rx : bool = True
    ,include : bool = True
    ,flags : re.RegexFlag = re.NOFLAG
) -> list[str | list[str | list]]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the nested structures surrounded by the provided boundaries, in terms of the concept of         #
#   | Balanced Group in Regular Expression (while NOT using RegExp as it would fail in many cases)                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote:                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/1099178/matching-nested-structures-with-regular-expressions-in-python                      #
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
#   |               [True       ] <Default> Treat them as regular expressions                                                           #
#   |               [False      ]           Treat them as raw character strings                                                         #
#   |include    :   Whether to include the bounding characters in the output structure                                                  #
#   |               [True       ] <Default> Include the bounds as output                                                                #
#   |               [False      ]           Exclude the bounds as output                                                                #
#   |flags      :   Flags to modify the parsing of the RegExp upon <lBound> and <rBound>                                                #
#   |               [re.NOFLAG  ] <Default> Parse the RegExp <lBound> and <rBound> using no modifier                                    #
#   |               [RegexFlag  ]           Any (union of) <re.RegexFlag> to modify the parsing                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List of nested structures out of each pair of boundaries as a Balanced Group                                        #
#   |               [IMPORTANT]                                                                                                         #
#   |               [1] If the bounds do not exist in pairs, exception is raised                                                        #
#   |               [2] Standalone substrings, i.e. those not enclosed by the provided boundaries, are also included in the result      #
#   |               [RESULT PATTERN] Assume any substring that is not enclosed by the boundaries, we mark the substring as <S>          #
#   |               [1] As long as paired boundaries are identified, they are captured in one <sub-list>, including the content between #
#   |                    them as separated items                                                                                        #
#   |               [2] <S> can only exist in the outmost list                                                                          #
#   |               [3] Substrings identifying both boundaries cannot exist in the outmost list, according to rule [1]                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20231118        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
    stack = [[]]

    #100. Split the input string by the boundaries
    #Return value of below function is a list of tuples comprised of start and end positions
    ptn_bound = re.compile(r'({}|{})'.format(lBound, rBound), flags = flags)
    tokens = ptn_bound.split(txt)
    ptn_lBound = re.compile(lBound, flags = flags)
    ptn_rBound = re.compile(rBound, flags = flags)

    #500. Extract the nested structure
    for x in tokens:
        if not x:
            continue
        if ptn_lBound.match(x):
            #100. Nest a new list inside the current list
            #[ASSUMPTION]
            #[1] We add the boundary as well in the nested structure
            if include:
                current = [x]
            else:
                current = []

            #[ASSUMPTION]
            #[1] <list> object is mutable
            #[2] When a list appended inside another object is modified, all references to it will also be updated
            #[3] The same validates if a list is extended
            #[4] This mechanism cannot be resembled in another language without mutability, e.g. <R> language
            stack[-1].append(current)
            stack.append(current)
        elif ptn_rBound.match(x):
            #[ASSUMPTION]
            #[1] We add the boundary as well in the nested structure
            if include:
                stack[-1].append(x)
            stack.pop()
            if not stack:
                raise ValueError(f'[{LfuncName}]Group opener is missing')
        else:
            stack[-1].append(x)

    #600. Raise if the numbers of left boundaries and right boundaries do not match
    if len(stack) > 1:
        print(stack)
        raise ValueError(f'[{LfuncName}]Group closer is missing')

    #900. Purge
    re.purge()

    #999. Emit the updated structure
    return stack.pop()
#End strNestedParser

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
    from omniPy.AdvOp import strNestedParser

    #100. Prepare strings
    teststr = '-- (bb (cc (dd))) aa (ee (ff)) ~~'
    testjinja = '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg'

    #200. Extraction
    ext_parens = strNestedParser(
        teststr
        ,lBound = '('
        ,rBound = ')'
        ,rx = False
    )
    # ['-- ', ['(', 'bb ', ['(', 'cc ', ['(', 'dd', ')'], ')'], ')'], ' aa ', ['(', 'ee ', ['(', 'ff', ')'], ')'], ' ~~']

    ext_jinja = strNestedParser(
        testjinja
        ,lBound = '{{'
        ,rBound = '}}'
        ,rx = False
    )
    # ['-- ',
    # ['{{', ' bb ', ['{{', ' cc', ['{{', ' dd ', '}}'], ' ', '}}'], ' ', '}}'],
    # ' aa',
    # ['{{', ' ee ', ['{{', ' ff ', '}}'], ' ', '}}']]

    ext_html = strNestedParser(
        testhtml
        ,lBound = r'<div.*?>'
        ,rBound = r'</div>'
        ,rx = True
    )
    # [['<div a="1">',
    #  'bbb',
    #  ['<div id="2">', 'ccc ', '</div>'],
    #  ' ddd',
    #  ['<div id="3">', 'eee', '</div>'],
    #  'fff',
    #  '</div>'],
    # ' ggg']

    ext_html2 = strNestedParser(
        testhtml
        ,lBound = r'<div.*?>'
        ,rBound = r'</div>'
        ,rx = True
        ,include = False
    )
    # [['bbb', [' ccc'], 'ddd ', ['eee'], 'fff'], ' ggg']

    #300. Special cases
    print(strNestedParser(''))
    # []

    print(strNestedParser(r'a'))
    # ['a']

    print(strNestedParser(r'(a b)'))
    # [['(', 'a b', ')']]

    print(strNestedParser(r'a (b)'))
    # ['a ', ['(', 'b', ')']]

    print(strNestedParser(r'(a) b'))
    # [['(', 'a', ')'], ' b']

    print(strNestedParser(r'(a ((b) c (d))) e (f (g))'))
    # [['(', 'a ', ['(', ['(', 'b', ')'], ' c ', ['(', 'd', ')'], ')'], ')'], ' e ', ['(', 'f ', ['(', 'g', ')'], ')']]

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    ext_large = strNestedParser(str_large, lBound = r'<div.*?>', rBound = r'</div>')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.061015
#-Notes- -End-
'''
