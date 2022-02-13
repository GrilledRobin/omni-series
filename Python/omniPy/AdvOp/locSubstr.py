#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re

def locSubstr(
    regexp
    ,txt
    ,overlap = False
) -> 'Get the start and end of substrings matching [regexp] in the provided [txt], with or without overlapping':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the start and end of substrings matching [regexp] in the provided [txt], with or without          #
#   | overlapping                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[QUOTE]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/5616822/python-regex-find-all-overlapping-matches                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |regexp     :   Regular expression used to search for substrings                                                                    #
#   |txt        :   Character string from which to extract the substrings                                                               #
#   |overlap    :   Whether to conduct the search in an overlapping mode, as it is always non-overlapping in the official package [re]  #
#   |               [False      ] <Default> Conduct non-overlapping search, following the logic in the official package [re]            #
#   |               [True       ]           Search for all possible matches one character next to another from left to right            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List of 2-element tuples, indicating [start, end] of each match of [regexp], or an empty list if nothing is found   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220122        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, collections                                                                                                               #
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
    if not isinstance( regexp , str ):
        raise TypeError('[' + LfuncName + '][regexp]:[{0}] must be provided a character string!'.format( type(regexp) ))
    if not isinstance( txt , str ):
        raise TypeError('[' + LfuncName + '][txt]:[{0}] must be provided a character string!'.format( type(txt) ))

    #050. Local parameters

    #100. Search for the input values within all frames along the call stacks
    if overlap:
        return([ m.span(1) for m in re.finditer('(?=(' + regexp + '))', txt) ])
    else:
        return([ m.span() for m in re.finditer(regexp, txt) ])
#End locSubstr

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import locSubstr

    #100. Prepare a string
    teststr = 'dafafafaeagafafffaafa'

    #200. Test output with [overlap==False]
    print(locSubstr('afa', teststr))

    #300. Test output with [overlap==True]
    print(locSubstr('afa', teststr, overlap = True))
#-Notes- -End-
'''