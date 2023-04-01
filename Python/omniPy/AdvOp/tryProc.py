#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from functools import wraps

def tryProc(
    times : int = 1
) -> callable:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to act as a decorator factory to create decorator of any function, so that the decorated function is     #
#   | always being called with tries of certain times until it still fails                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] If one tries to overwrite some file using a function, while the file to be overwritten is locked by unknown reason, this       #
#   |     decorator provides an n-time re-try for the process not to be aborted immediately                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote:                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] http://www.pythontutorial.net/advanced-python/python-decurator-arguments/                                                      #
#   |[2] https://stackoverflow.com/questions/5481623/python-dynamically-add-decorator-to-class-methods-by-decorating-class              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |times       :   How many times to try the decorated process                                                                        #
#   |                 [1           ] <Default> Call the function once                                                                   #
#   |                 [<int>       ]           Call the function by <n> times                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>  :   Return the decorated callable                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230401        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, functools                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer

    #500. Create the decorator
    def deco(fn):
        @wraps(fn)
        def wrapper(*pos, **kw):
            #100. Try the function for certain times
            for _ in range(times):
                try:
                    rstOut = fn(*pos, **kw)
                    return(rstOut)
                except:
                    continue

            #999. Raise exception if it still fails
            raise RuntimeError(f'[{fn.__name__}] failed for {str(times)} times! Program terminated!')

        return(wrapper)

    #999. Return the decorator
    return(deco)
#End tryProc

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import tryProc

    #100. Define test function
    @tryProc(5)
    def testfunc(x,y):
        return(x/y)

    #200. Test valid numbers
    testfunc(4,2)

    #300. Test invalid numbers
    testfunc(4,0)

#-Notes- -End-
'''
