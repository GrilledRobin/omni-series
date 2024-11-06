#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time, traceback
from functools import wraps
from omniPy.AdvOp import simplifyDeco

@simplifyDeco
def tryProc(
    fn : callable
    ,times : int = 1
    ,interval : float = 0.0
) -> callable:
    #000. Info.
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
#   |[3] https://stackoverflow.com/questions/653368/how-to-create-a-decorator-that-can-be-used-either-with-or-without-parameters        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fn          :   The callable to be decorated                                                                                       #
#   |times       :   How many times to try the decorated process                                                                        #
#   |                 [1           ] <Default> Call the function once                                                                   #
#   |                 [<int>       ]           Call the function by <n> times                                                           #
#   |interval    :   <float> number of seconds to sleep before the next trials to be called, given the first call fails                 #
#   |                 [<0.0>       ] <Default> Does not sleep between each two calls                                                    #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230403        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add new argument <interval> to control the interval between each try                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20241023        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add new argument <fn> by wrapping itself with a decorator to enable simplified call, see User Manual for details        #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20241106        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Collect tracebacks and exceptions for all failures, for logging and handling purposes                                   #
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
#   |   |time, functools                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |simplifyDeco                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.

    #012. Parameter buffer

    #500. Create the decorator
    @wraps(fn)
    def wrapper(*pos, **kw):
        #010. Prepare the collection of tracebacks
        tbs = [f'[{fn.__name__}] failed for {str(times)} times! Program terminated!']
        errors = []

        #100. Try the function for certain times
        for k in range(times):
            print(f'[{fn.__name__}] try the process, counting: {str(k)}')
            try:
                rstOut = fn(*pos, **kw)
                return(rstOut)
            except Exception as e:
                tbs.append('\n'.join([
                    f'[{fn.__name__}]<Failure {str(k)}>'
                    ,traceback.format_exc()
                ]))
                errors.append(e)
                time.sleep(interval)
                continue

        #999. Raise exception if it still fails
        #[ASSUMPTION]
        #[1] We need to print the error message in the log
        #[2] Also store the exceptions (instead of the messages) in the exception object, for error handling where necessary
        #[3] Quote: https://stackoverflow.com/questions/12826291/raise-two-errors-at-the-same-time
        raise ExceptionGroup(
            '\n'.join(tbs)
            ,errors
        )

    return(wrapper)
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
    @tryProc(5, interval = 1)
    def testfunc(x,y):
        return(x/y)

    #200. Test valid numbers
    testfunc(4,2)
    # [testfunc] try the process, counting: 0
    # Out[11]: 2.0

    #300. Test invalid numbers
    testfunc(4,0)
    # RuntimeError: [testfunc] failed for 5 times! Program terminated!

    #400. Decorate the function in a simplified way, using default parameters
    @tryProc
    def testfunc2(x,y):
        return(x/y)

    testfunc2(4,0)
    # RuntimeError: [testfunc2] failed for 1 times! Program terminated!

    #450. Same function as above
    @tryProc()
    def testfunc3(x,y):
        return(x/y)

    testfunc3(4,0)
    # RuntimeError: [testfunc3] failed for 1 times! Program terminated!

#-Notes- -End-
'''
