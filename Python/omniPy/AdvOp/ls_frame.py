#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import inspect
from collections.abc import Callable
from typing import Any

def ls_frame(
    frame = None
    ,predicate : Callable[[Any, ...], bool] = lambda x: True
    ,scope : str | list[str] = ['f_locals','f_globals']
    ,pattern : str | re.Pattern = r'.*'
    ,flags : int = re.NOFLAG
    ,verbose : bool = False
) -> list[str] | dict[str, Any]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to list the object names or the dict[name:object] if verbose, in the provided frame or all frames along  #
#   | the call stack, by matching a specific pattern to the names and the predicate upon the objects                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Search for certain pattern of functions within current session                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |frame       :   <frame> object in which to search for objects                                                                      #
#   |                [None        ] <Default> Search in all frames along the call stack                                                 #
#   |                [frame       ]           Dedicated <frame> in which to search the objects                                          #
#   |predicate   :   Callable predicate to apply to the objects as found, only those with True predicates will be returned              #
#   |                [<see def.>  ] <Default> Do not apply predicate                                                                    #
#   |                [callable    ]           Callable with the first argument to be applied upon the object as found, and return bool  #
#   |scope       :   Which scope to search for the variables in the frames along the call stacks                                        #
#   |                IMPORTANT: This must be provided a sequence or a single string, indicating the search order of the scopes          #
#   |                [<see def.>  ] <Default> Search for the variables in <f_locals> and then <f_globals> until the last try            #
#   |                [f_locals    ]           Only search for the variables in <f_locals> of every frame along the call stacks          #
#   |                [f_globals   ]           Only search for the variables in <f_globals> of every frame along the call stacks         #
#   |pattern     :   Regex pattern to search within the object names, used for <re.Search> instead of <re.Match>                        #
#   |                [<see def.>  ] <Default> Search for all names without filtration                                                   #
#   |                [str         ]           Valid Regex string representation                                                         #
#   |                [re.Pattern  ]           Valid Pattern object compiled by <re.compile>                                             #
#   |flags       :   Regex flags to create the internal pattern if <pattern> is provided a string                                       #
#   |                [<see def.>  ] <Default> No certain flag is applied                                                                #
#   |                [flags       ]           Valid flags defined in package <re>                                                       #
#   |verbose     :   Whether to return verbose results                                                                                  #
#   |                [False       ] <Default> Only return a list of names found by the conditions                                       #
#   |                [True        ]           Return a dict[name:object]                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>   :   This function output different values in below convention:                                                         #
#   |                [1] If <verbose == False>, return a [list] of names matching the conditions                                        #
#   |                [2] If <verbose == True>, return a [dict] of names pairing the objects, which match the conditions                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240218        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, re, inspect, collections, typing                                                                                          #
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
    vld_scope = ['f_locals','f_globals']
    if isinstance(scope, str):
        scope = [scope]
    vfy_scope = [ s for s in scope if s not in vld_scope ]
    if len(vfy_scope):
        raise ValueError(f'[{LfuncName}][scope] must be among {str(vld_scope)}!')
    if isinstance(pattern, str):
        ptn = re.compile(pattern, flags)
    elif isinstance(pattern, re.Pattern):
        ptn = pattern
    else:
        raise ValueError(f'[{LfuncName}][pattern] cannot be compiled as Regex, given {str(pattern)}!')

    #050. Local parameters

    #100. Define helper functions
    #[ASSUMPTION]
    #[1] When searching for a variable in both scopes, while it exists in both, the search result is only from <f_globals>
    #     of current frame <Python <= 3.11.2>
    def h_globframe(frame):
        rstOut = {}
        for s in scope:
            rstOut = {
                **rstOut
                ,**{
                    k:v
                    for k,v in frame.__getattribute__(s).items()
                    if ptn.search(k) and predicate(v) and (k not in rstOut)
                }
            }
        return(rstOut)

    #300. Directly export when a frame is specified
    if inspect.isframe(frame):
        rstOut = h_globframe(frame)
        if verbose:
            return(rstOut)
        else:
            return(list(rstOut.keys()))

    #500. Search starting from the parent frame and backwards
    frame = sys._getframe(1)
    rstOut = {}
    #Avoid errors to be raised when reaching the global environment
    #Quote: https://stackoverflow.com/questions/39265823/python-sys-getframe
    while frame:
        rstOut = {
            **rstOut
            ,**{
                k:v
                for k,v in h_globframe(frame).items()
                if k not in rstOut
            }
        }
        frame = frame.f_back

    #700. Search within [global] environment
    rstOut = {
        **rstOut
        ,**{
            k:v
            for k,v in globals().items()
            if ptn.search(k) and predicate(v) and (k not in rstOut)
        }
    }

    #900. Output
    if verbose:
        return(rstOut)
    else:
        return(list(rstOut.keys()))
#End ls_frame

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    from functools import partial
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import ls_frame

    #100. Create objects
    aa1 = 1
    def aa2(): pass
    aa3 = {}
    ab1 = 'aa'

    #200. Define predicates for the function to filter objects
    def pr_instance(obj, instance):
        if instance is callable:
            return(callable(obj))
        else:
            return(isinstance(obj, instance))

    #300. Simple test
    ls_frame(pattern = r'^aa')
    # ['aa1', 'aa2', 'aa3']

    ls_frame(pattern = r'^aa', verbose = True)
    # {'aa1': 1, 'aa2': <function __main__.aa2()>, 'aa3': {}}

    ls_frame(pattern = r'^aa', predicate = partial(pr_instance, instance = dict))
    # ['aa3']

    #400. Test the search within specific scopes
    def testscope():
        frame = sys._getframe()

        def aa2(): pass
        aa3 = {1 : 3}

        #100. Include all global variables, with those local variables found prior to the globals if they share the same names
        print('All:')
        print(ls_frame(frame = frame, pattern = r'^aa'))

        #300. Only include local variables defined in current frame
        print('Locals:')
        print(ls_frame(frame = frame, pattern = r'^aa', scope = 'f_locals'))

    testscope()
    # All:
    # ['aa2', 'aa3', 'aa1']
    # Locals:
    # ['aa2', 'aa3']

    #500. Verify whether the members of <ls_frame> can be obtained
    ls_frame(pattern = r'h_globframe')
    # []
#-Notes- -End-
'''
