#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import types
from functools import wraps

def simplifyDeco(
    fn : callable
) -> callable:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to decorate the dedicated decorator so that the wrapped decorator can be called in several conventional  #
#   | ways. See the [Full Test Program] section for the detailed usage                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |The decorated decorator can be called in below ways, given the signature of <deco> as: deco(fn, *args, **kw)                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] @deco              #If there is no <*args> and the necessary <kw> have default values or being handled                         #
#   |[2] @deco()            #If there is no <*args> and the necessary <kw> have default values or being handled                         #
#   |[3] @deco(*args, **kw) #Normal way of a parametric decorator invocation                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote:                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/653368/how-to-create-a-decorator-that-can-be-used-either-with-or-without-parameters        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fn          :   The callable decorator to enable multiple calling methods                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>  :   Return the decorated callable                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241023        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |types, functools                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    if not isinstance(fn, types.FunctionType):
        raise NotImplementedError('Class decorator is not designed to be wrapped with extra arguments!')

    #012. Parameter buffer

    #500. Create the decorator
    @wraps(fn)
    def deco(*args, **kwargs):
        if len(args) == 1 and len(kwargs) == 0 and callable(args[0]):
            # actual decorated function
            return(fn(args[0]))
        else:
            # decorator arguments
            return(lambda realf: fn(realf, *args, **kwargs))

    #999. Return the decorator
    return(deco)
#End simplifyDeco

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    from functools import wraps
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import simplifyDeco

    #100. Define test function
    @simplifyDeco
    def mult(f, factor=2):
        @wraps(f)
        def wrap(*args, **kwargs):
            return factor*f(*args,**kwargs)
        return wrap

    # try normal
    @mult
    def f(x, y):
        return x + y

    # try args
    @mult(3)
    def f2(x, y):
        return x*y

    # try kwargs
    @mult(factor=5)
    def f3(x, y):
        return x - y

    assert f(2,3) == 10
    assert f2(2,5) == 30
    assert f3(8,1) == 5*7

#-Notes- -End-
'''
