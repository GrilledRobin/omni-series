#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numpy as np
from importlib import import_module

def importByStr(
    *pos
    ,asModule : bool = False
    ,importAll : bool = False
    ,**kw
) -> 'Import function/class by providing names as string':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to import a function/class dynamically when the name as character string is provided                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Dynamically import functions/classes from any module into global environment and rename them for programmatic usage            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |pos        :   Positional arguments for [importlib.import_module]                                                                  #
#   |asModule   :   Whether to maintain the imported object as [module], same as [import aaa]                                           #
#   |                [False       ] <Default> Try to get the object in the same name, i.e. func('bbb', package = 'aaa') is the same as  #
#   |                                          [from aaa import bbb], also as is when func('aaa.bbb')                                   #
#   |                [True        ]           Maintain the structure of the imported module, same as [import aaa]                       #
#   |importAll  :   Whether to import [*] from the provided module, same as [from aaa import *]                                         #
#   |                [False       ] <Default> Only import the named object                                                              #
#   |                [True        ]           Import all objects from the named package [*pos] (or [**kw] if [pos] is not provided)     #
#   |kw         :   Named arguments for [importlib.import_module]                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[object]   :   The imported object                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230304        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, numpy, importlib                                                                                                          #
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
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Parameter buffer
    if not isinstance(asModule, (bool, np.bool_)):
        raise TypeError(f'[{LfuncName}][asModule]:[{type(asModule)}] must be boolean!')
    if not isinstance(importAll, (bool, np.bool_)):
        raise TypeError(f'[{LfuncName}][importAll]:[{type(importAll)}] must be boolean!')

    #100. Directly import the module as requested
    #[ASSUMPTION]
    #[1] Result of below statement is a type of [types.ModuleType]
    obj = import_module(*pos, **kw)

    #300. Output if it is requested to maintain its structure
    if asModule:
        return(obj)

    #500. Differentiate the outputs
    if not importAll:
        #100. Output a parsed object if it is NOT requested to import all objects from this module
        #Quote: https://stackoverflow.com/questions/3061/calling-a-function-of-a-module-by-using-its-name-a-string
        return(getattr(obj, pos[0].split('.')[-1]))
    else:
        #100. Update the globals with all the objects imported from the requested package
        #Quote: https://stackoverflow.com/questions/44492803/dynamic-import-how-to-import-from-module-name-from-variable
        globals().update(
            {n: getattr(obj, n) for n in obj.__all__} if hasattr(obj, '__all__')
            else
            {k: v for (k, v) in obj.__dict__.items() if not k.startswith('_')
        })
#End importByStr

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import importByStr, xwDfToRange

    #100. Import a specific function (instead of a module)
    #Below statement is the same as: from omniPy.AdvOp import xwDfToRange as myfunc
    myfunc = importByStr('omniPy.AdvOp.xwDfToRange')
    print(myfunc is xwDfToRange)

    #200. Another syntax to import a specific function (instead of a module)
    #[ASSUMPTION]
    #[1] [..] indicates to search in the grand-parent module
    #[2] [.] indicates to search in the module specified in [package=] argument
    #[3] Below statement is the same as: from omniPy.AdvOp import xwDfToRange as myfunc2
    myfunc2 = importByStr('.xwDfToRange', package = 'omniPy.AdvOp')
    print(myfunc2 is xwDfToRange)

    #300. Import objects from an entire module (note there is no conceivable return value)
    #Same as: from omniPy.Styles import *
    importByStr('omniPy.Styles', importAll = True)
    print(callable(theme_xwtable))

    #400. Another syntax to import objects from an entire module (note there is no conceivable return value)
    #Same as: from omniPy.RPA import *
    importByStr('.RPA', package = 'omniPy', importAll = True)
    print(callable(clicks))

    #500. Import a module and rename it
    #Same as: import omniPy.Stats as ost
    ost = importByStr('omniPy.Stats', asModule = True)
    print(callable(ost.userBasedCF))
#-Notes- -End-
'''
