#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from typing import Optional
from omniPy.AdvOp import importByStr, ls_frame, withDefaults

def lookupMethod(
    apiCls : str = None
    ,apiPkg : Optional[str] = None
    ,apiPfx : str = ''
    ,apiSfx : str = ''
    ,lsOpt : dict = {}
    ,attr_handler : Optional[str] = None
    ,attr_kwInit : Optional[str] = None
    ,attr_assign : Optional[str] = None
    ,attr_return : Optional[str] = None
    ,coerce_ : bool = True
) -> callable:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to lookup the callable from a dedicated package, a frame, or a stack of frames, by the provided pattern  #
#   | of name, and escalate it into a separate callable with <self> as the first positional argument, for further binding to an         #
#   | instance as a method. Meanwhile, it enables to call the further bound method by ignoring excessive parameters.                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Dynamically lookup the method for an instance                                                                                  #
#   |[2] Prepare descriptor to enable dynamic method lookup                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |apiCls            :   <str     > Class/owner name of the method to lookup and bind                                                 #
#   |                      [None                ]<Default> System would raise exception if it is not provided                           #
#   |                      [str                 ]          Any string that is legal to form attribute names of a class                  #
#   |apiPkg            :   <str     > Package name in which to lookup the dedicated callable                                            #
#   |                      [None                ]<Default> System would search the callable from current session                        #
#   |                      [str                 ]          System would search the callable from within the package                     #
#   |apiPfx            :   <str     > Prefix of the pattern to search for the name of the callable: <apiPfx> + <apiCls> + <apiSfx>      #
#   |                      [<empty str>         ]<Default> No specific prefix                                                           #
#   |                      [str                 ]          Set a proper prefix to validate the search                                   #
#   |apiSfx            :   <str     > Suffix of the pattern to search for the name of the callable: <apiPfx> + <apiCls> + <apiSfx>      #
#   |                      [<empty str>         ]<Default> No specific suffix                                                           #
#   |                      [str                 ]          Set a proper suffix to validate the search                                   #
#   |lsOpt             :   <dict    > Additional options for <ls_frame> given <apiPkg> is not provided, for search in current session   #
#   |                      [<empty dict>        ]<Default> No additional options, see function definition for details                   #
#   |                      [dict                ]          See <AdvOp.ls_frame> for additional options                                  #
#   |attr_handler      :   <str     > Attribute name to get from the bound instance, to mutate the result returned from the method call #
#   |                      [None                ]<Default> No need to mutate the result from the newly bound method                     #
#   |                      [str                 ]          Existing attribute to handle the result from the newly bound method          #
#   |attr_kwInit       :   <str     > Attribute name to get from the bound instance, to initialize the keyword arguments of the newly   #
#   |                       bound method at the binding stage                                                                           #
#   |                      [None                ]<Default> No need to adjust the default keyword arguments of the newly bound method    #
#   |                      [str                 ]          Existing attribute to initialize the keyword arguments of the newly bound    #
#   |                                                       method                                                                      #
#   |attr_assign       :   <str     > Attribute name to get from the bound instance, to assign the result from the newly bound method   #
#   |                      [None                ]<Default> No need to store the result of the newly bound method to another attribute   #
#   |                      [str                 ]          Existing attribute to store the result from the newly bound method           #
#   |attr_return       :   <str     > Attribute name to get from the bound instance, to return from the newly bound method              #
#   |                      [None                ]<Default> Only return the result from the newly bound method                           #
#   |                      [str                 ]          Only return the value of the dedicated attribute, similar to <property>      #
#   |coerce_            :   <bool    > Whether to raise exception if the dedicated callable is not found                                #
#   |                      [True                ]<Default> Return <None> if the callable is not found                                   #
#   |                      [False               ]          Raise exception if the callable is not found                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<callable>        :   The new method which can be bound to any dedicated instance                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250104        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, re, inspect, typing                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |importByStr                                                                                                                #
#   |   |   |modifyDict                                                                                                                 #
#   |   |   |ls_frame                                                                                                                   #
#   |   |   |withDefaults                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(apiCls, str):
        raise TypeError(f'[{LfuncName}][apiCls] must be <str>!')
    if not apiCls:
        raise ValueError(f'[{LfuncName}][apiCls] cannot be empty!')

    #020. Local environment
    lsOptNew = {
        'verbose' : True
        ,'predicate' : callable
        ,'flags' : re.NOFLAG
        ,**{ k:v for k,v in lsOpt.items() if k not in ['pattern','verbose','predicate','flags'] }
    }
    hasPkg = False
    if isinstance(apiPkg, str):
        if len(apiPkg) > 0:
            hasPkg = True

    #100. Define the name pattern for search
    apiPtn = str(apiPfx) + apiCls + str(apiSfx)

    #200. Lookup the callable core
    try:
        if hasPkg:
            __dfl_func_ = importByStr('.' + apiPtn, package = apiPkg)
        else:
            __dfl_func_ = list(ls_frame(pattern = f'^{apiPtn}$', **lsOptNew).values())
            if len(__dfl_func_) == 1:
                __dfl_func_ = __dfl_func_[0]
            else:
                __dfl_func_ = None
    except:
        __dfl_func_ = None

    #300. Verify whether it can be found
    if not callable(__dfl_func_):
        if coerce_:
            return(None)
        else:
            raise TypeError(f'[{LfuncName}][{apiPtn}] is not callable!')

    #400. Get the signature of the callable
    sig_raw = signature(__dfl_func_).parameters.values()

    #500. Identify the existence of <self> argument, to act as a bound method
    #[ASSUMPTION]
    #[1] <self> must be the first positional argument of the callable
    has_self = [
        i
        for i,s in enumerate(sig_raw)
        if s.kind in ( s.POSITIONAL_ONLY, s.POSITIONAL_OR_KEYWORD )
        and s.name == 'self'
    ] == [0]

    #700. Define a method-like callable to wrap the original API
    def func_(self, *pos, **kw):
        #010. Local environment
        clsname_ = apiCls or self.__class__.__name__

        #100. Verify input parameters
        #101. Create a pseudo parameter when necessary
        if has_self:
            pos = (self,) + pos

        #300. Identify whether there are default values for API call, as provided at instantiation
        if attr_kwInit:
            if not hasattr(self, attr_kwInit):
                raise AttributeError(f'[{clsname_}] has no attribute as [{attr_kwInit}]')
            kw_def = getattr(self, attr_kwInit, {})
        else:
            kw_def = {}

        #500. Wrap the API by setting defaults for necessary arguments
        #[ASSUMPTION]
        #[1] This will also enable keyword provision for POSITIONAL_ONLY arguments and positional input for KEYWORD_ONLY, that say,
        #     various input patterns for all kinds of arguments
        #[2] Below decorator accepts arguments so it is a double-wrapper, we thus have to call it in this way (as we cannot use
        #     the Python sugar syntax @deco)
        __dfl_def_ = withDefaults(**kw_def)(__dfl_func_)

        #500. Pull the data from the API
        rstOut = __dfl_def_(*pos, **kw)

        #600. Handle the result if required
        #[ASSUMPTION]
        #[1] Currently it only takes one positional argument
        if attr_handler:
            rstOut = getattr(self, attr_handler)(rstOut)

        #700. Assign the result to another attribute if required
        if attr_assign:
            setattr(self, attr_assign, rstOut)

        #900. Return values
        #[ASSUMPTION]
        #[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
        # return(self)
        if attr_return:
            return(getattr(self, attr_return))
        else:
            return(rstOut)

    #900. Export
    return(func_)
#End lookupMethod

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import types
    from typing import Optional
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import lookupMethod

    #100. Define the API which can be bound as a method of some instance
    def loader_api001(self, b):
        return(self.aaa + b)

    #200. Directly call the function to bind the API to an instance
    #[ASSUMPTION]
    #[1] There should be an extra method <add> to bind the API and an extra step to add it, which is less efficient
    #[2] One can mannually assign any value to the newly added API, which is a risk of injection
    #[3] However, method lookup can become dynamic
    class MyClass:
        def __init__(self):
            self.aaa = 10

        def add(self, attr):
            func_ = lookupMethod(
                apiCls = attr
                ,apiPkg = None
                ,apiPfx = 'loader_'
                ,apiSfx = ''
                ,lsOpt = {}
                ,attr_handler = None
                ,attr_kwInit = None
                ,attr_assign = None
                ,attr_return = None
                ,coerce_ = False
            )
            setattr(self, attr, types.MethodType(func_, self))

    testadd = MyClass()
    testadd.add('api001')
    testadd.api001(20)
    # 30

    #300. Use the magic method <__getattr__> to enable dynamic attribute creation
    #[ASSUMPTION]
    #[1] This solution usually can only enable looking up the method for the first time it is invoked in an instance
    #[2] We can neither prevent injection, even using <__setattr__> to do the trick is not recommended, as it will be complicated
    #     to differ those pre-defined internal attributes from the newly bound methods
    #    https://www.pythonmorsels.com/python-setattr/
    class MyClass1:
        def __init__(self):
            self.aaa = 10

        def __getattr__(self, attr):
            func_ = lookupMethod(
                apiCls = attr
                ,apiPkg = None
                ,apiPfx = 'loader_'
                ,apiSfx = ''
                ,lsOpt = {}
                ,attr_handler = None
                ,attr_kwInit = None
                ,attr_assign = None
                ,attr_return = None
                ,coerce_ = False
            )
            print('Identified the method for the first time')
            setattr(self, attr, types.MethodType(func_, self))
            return(getattr(self, attr))

    testadd1 = MyClass1()
    testadd1.api001(20)
    # Identified the method for the first time
    # 30

    # No longer print the pre-defined message as the method has already been bound to the instance
    testadd1.api001(30)
    # 40

    #500. Embed this function into a descriptor
    #[ASSUMPTION]
    #[1] Any pre-defined class attribute can be dynamically searched in the dedicated way
    #[2] If necessary, one can set the descriptor as a read-only data descriptor, to prevent injection
    #[3] The class attribute should be pre-defined, and its name cannot be dynamically created
    #[4] The descriptor takes no effect in any instance
    #[5] Use the descriptor in a metaclass can enable dynamic method lookup in a dynamically created class
    #310. Prepare a descriptor
    class MyDescriptor:
        #010. Constructor
        def __init__(
            self
            ,apiCls : str = None
            ,apiPkg : Optional[str] = None
            ,apiPfx : str = ''
            ,apiSfx : str = ''
            ,lsOpt : dict = {}
            ,attr_handler : Optional[str] = None
            ,attr_kwInit : Optional[str] = None
            ,attr_assign : Optional[str] = None
            ,attr_return : Optional[str] = None
            ,coerce_ : bool = True
        ):
            #100. Assign values to local variables
            self.apiCls = apiCls
            self.apiPkg = apiPkg
            self.apiPfx = apiPfx
            self.apiSfx = apiSfx
            self.lsOpt = lsOpt
            self.attr_handler = attr_handler
            self.attr_kwInit = attr_kwInit
            self.attr_assign = attr_assign
            self.attr_return = attr_return
            self.coerce_ = coerce_

        #100. Assign attribute name
        def __set_name__(self, owner, name):
            self._dfl_public_name_ = name
            self._dfl_private_name_ = f'__dfl_{name}_'

        #300. Define non-data part of the descriptor
        def __get__(self, instance, objtype = None):
            #100. Search for the method on the fly
            func_ = lookupMethod(
                apiCls = self.apiCls or self._dfl_public_name_
                ,apiPkg = self.apiPkg
                ,apiPfx = self.apiPfx
                ,apiSfx = self.apiSfx
                ,lsOpt = self.lsOpt
                ,attr_handler = self.attr_handler
                ,attr_kwInit = self.attr_kwInit
                ,attr_assign = self.attr_assign
                ,attr_return = self.attr_return
                ,coerce_ = self.coerce_
            )

            #900. Export
            return(types.MethodType(func_, instance))

        #500. Ensure it is a read-only data descriptor
        def __set__(self, instance, value):
            apiCls = self.apiCls or self._dfl_public_name_
            raise AttributeError(f'[{instance.__class__.__name__}]Attribute [{apiCls}] is read-only!')

    #350. Use the descriptor in the class
    class MyClass5:
        api001 = MyDescriptor(
            apiCls = None
            ,apiPkg = None
            ,apiPfx = 'loader_'
            ,apiSfx = ''
            ,lsOpt = {}
            ,attr_handler = None
            ,attr_kwInit = None
            ,attr_assign = None
            ,attr_return = None
            ,coerce_ = False
        )

        def __init__(self):
            self.aaa = 10

    testadd5 = MyClass5()

    #[ASSUMPTION]
    #[1] Extra named parameters are omitted
    testadd5.api001(20, e = 5)
    # 30

    #560. Try to assign the API with another object
    testadd5.api001 = 111
    # AttributeError: [MyClass2]Attribute [api001] is read-only!
#-Notes- -End-
'''
