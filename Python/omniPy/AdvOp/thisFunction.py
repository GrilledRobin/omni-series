#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import gc
import inspect
from typing import Optional

def thisFunction() -> Optional[callable]:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the frame as callable of its caller, instead of meerly its name, since name is not safe for  #
#   | calls in recursion                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Create user defined recursive functions without apparent reference to their respective names                                   #
#   |[2] https://stackoverflow.com/questions/4492559/how-to-get-current-function-into-a-variable/37099372                               #
#   |[3] https://snippets.snyk.io/python/python-get-current-function-name                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not take arguments                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Callable>  :   The callable that is calling this function                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230821        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |gc, inspect, typing                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #100. Determine the parent frame and its code
    frame = inspect.currentframe().f_back
    code = frame.f_code
    functype = type(lambda: 0)

    #200. Handle special names
    #[ASSUMPTION]
    #[1] Attempting to extract the function reference for these calls appears to be problematic
    if code.co_name in ['__del__','_remove','_removeHandlerRef']:
        return(None)

    #900. Determine the output
    try:
        #100. Obtain the callable from garbage collection
        referer = [
            ref
            for ref in gc.get_referrers(code)
            if getattr(ref, '__code__', None) is code
            and type(ref) is functype
            and inspect.getclosurevars(ref).nonlocals.items() <= frame.f_locals.items()
        ]

        #900. Determine the output
        if referer:
            return(referer[0])
        else:
            return(None)
    except ValueError:
        #100. <inspect.getclosurevars> can fail with ValueError: Cell is empty
        return(None)
#End thisFunction

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import functools
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import thisFunction

    #100. Test whether this returns the same function as being called
    def f3():
        print(thisFunction())

    f3()
    # <function f3 at 0x0000017235CB2B70>

    #200. Test as an inner call
    def f1(x):
        def f2(y):
            print(thisFunction())
            return x + y
        return f2

    f_var1 = f1(1)
    f_var1(3)
    # <function f1.<locals>.f2 at 0x00000292C5FEAB80>
    # 4

    f_var2 = f1(2)
    f_var2(3)
    # <function f1.<locals>.f2 at 0x0000017235CB2BF8>
    # 5

    #300. Test a decorated function
    def wrapper(func):
        functools.wraps(func)
        def wrapped(*args, **kwargs):
            return func(*args, **kwargs)
        return wrapped

    @wrapper
    def f4():
        print(thisFunction())

    f4()
    # <function f4 at 0x0000017235CB2A60>

    #400. Test a lambda function
    f5 = lambda: thisFunction()

    print(f5())
    # <function <lambda> at 0x0000017235CB2950>
#-Notes- -End-
'''
