#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import sys
from typing import Optional
from omniPy.AdvOp import DynMethodLookup

#100. Definition of the class.
class OpenSourceApiMeta(type):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to unify the APIs to communicate with various open sources, e.g. FTP, File System and DB Engines to <pull>  #
#   | data or <push> data in simplified and standardized manner                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Reference:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Metaclass example: https://www.pythontutorial.net/python-oop/python-metaclass-example/                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__new__]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is to create a class with API methods on the fly and hijack the method <__init__> after creating it        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |mcs               :   The same variable indicating <self> within the metaclass, just to differ <self> to be used to create #
#   |   |   |                       the new class                                                                                       #
#   |   |   |cls               :   <str     > Name of the class to be created on the fly                                                #
#   |   |   |bases             :   <tuple   > Base classes for <cls> to inherit, remind to use tuple syntax if only one base is needed  #
#   |   |   |attrs             :   <dict    > Attributes used to create the new class, instead of instantiating it                      #
#   |   |   |apiPkgPull        :   <str     > Name of the package from which to obtain the API function to pull the data                #
#   |   |   |                      [None                ]<Default> Obtain the API from current session in global environment            #
#   |   |   |                      [<str>               ]          Package name valid for function <AdvOp.importByStr>                  #
#   |   |   |apiPfxPull        :   <str     > Prefix of the puller API name to search as regular expression                             #
#   |   |   |                      [<empty>             ]<Default> No specific prefix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper prefix to validate the search                           #
#   |   |   |apiSfxPull        :   <str     > Suffix of the puller API name to search as regular expression                             #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper suffix to validate the search                           #
#   |   |   |apiPullHdl        :   <callable> Function with only one argument as handler to process the data pulled at once             #
#   |   |   |                      [lambda x: x         ]<Default> No handler is required                                               #
#   |   |   |                      [<callable>          ]          Function to process the pulled data                                  #
#   |   |   |lsPullOpt         :   <dict    > Options to list the <pull> callables given <apiPkgPull == None>                           #
#   |   |   |                      [<empty>             ]<Default> Use the default arguments during searching                           #
#   |   |   |                      [<dict>              ]          See definition of <AdvOp.ls_frame>                                   #
#   |   |   |apiPkgPush        :   <str     > Name of the package from which to obtain the API function to push the data                #
#   |   |   |                      [None                ]<Default> Obtain the API from current session in global environment            #
#   |   |   |                      [<str>               ]          Package name valid for function <AdvOp.importByStr>                  #
#   |   |   |apiPfxPush        :   <str     > Prefix of the pusher API name to search as regular expression                             #
#   |   |   |                      [<empty>             ]<Default> No specific prefix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper prefix to validate the search                           #
#   |   |   |apiSfxPush        :   <str     > Suffix of the pusher API name to search as regular expression                             #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper suffix to validate the search                           #
#   |   |   |apiPushHdl        :   <callable> Function with only one argument as handler to process the data pushed at once             #
#   |   |   |                      [lambda x: x         ]<Default> No handler is required                                               #
#   |   |   |                      [<callable>          ]          Function to process the pushed data                                  #
#   |   |   |lsPushOpt         :   <dict    > Options to list the <push> callables given <apiPkgPush == None>                           #
#   |   |   |                      [<empty>             ]<Default> Use the default arguments during searching                           #
#   |   |   |                      [<dict>              ]          See definition of <AdvOp.ls_frame>                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<class>           :   Return the newly created class (but not instantiate it)                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[pulled]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to be added to available method lists to the newly created class, to obtain the data pulled    #
#   |   |   |   | from the API                                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<object>          :   Any object pulled via the API                                                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[pushed]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to be added to available method lists to the newly created class, to obtain the data pushed    #
#   |   |   |   | via the API                                                                                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<object>          :   Any object pushed via the API                                                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[getHdlPull]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to setup the mutable properties for the newly created class                                    #
#   |   |   |   |Get the handler for <pull> method                                                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   Callable for data processing                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[setHdlPull]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to setup the mutable properties for the newly created class                                    #
#   |   |   |   |Set the handler for <pull> method                                                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<func>            :   Callable to be set as new handler for <pull> method                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This is an attribute setter hence returns nothing                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[getHdlPush]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to setup the mutable properties for the newly created class                                    #
#   |   |   |   |Get the handler for <push> method                                                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   Callable for data processing                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[setHdlPush]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to setup the mutable properties for the newly created class                                    #
#   |   |   |   |Set the handler for <push> method                                                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<func>            :   Callable to be set as new handler for <push> method                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This is an attribute setter hence returns nothing                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230311        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230314        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Revmoed arguments <pullOnInit> and <pushOnInit> to leave the flexibility to the caller programs                         #
#   |      |[2] Fixed bugs of incorrect scopes of the methods                                                                           #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230325        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Enable <__init__> to be customized when creating dynamic classes                                                        #
#   |      |[2] Should any private variables are to be created via customized <__init__>, define a customized <__slots__> to facilitate #
#   |      |     its scoping as well, see the demo programs for detailed usage                                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240101        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <kw_pull_> and <kw_push_> to enable different pre-defined arguments for either methods                        #
#   |      |[2] Introduce set-table properties <hdlPull> and <hdlPush> to the newly created class, allowing user to modify these        #
#   |      |     handlers AFTER the class is instantiated.                                                                              #
#   |      |    <hdlPull> corresponds to <apiPullHdl> at class creation                                                                 #
#   |      |    <hdlPush> corresponds to <apiPushHdl> at class creation                                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240217        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Make <apiPullHdl> and <apiPushHdl> optional to enable stability when invalid input is taken                             #
#   |      |[2] Make the search in current session more flexible, e.g. enable searching in provided frame                               #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250104        | Version | 4.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the descriptor <DynMethodLookup> to unify the function to search for methods                                  #
#   |      |[2] Modify the internal attribute names to avoid conflict with the system attributes                                        #
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
#   |   |sys, typing                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |DynMethodLookup                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Identify the qualified name of current class (for logging purpose at large)
    #Quote: https://www.python.org/dev/peps/pep-3155/
    #[1] [__qualname__] attribute is valid for a [class] or [function], but invalid for an [object] instantiated from a [class]
    LClassName = __qualname__
    #<__slots__> MUST BE empty as indicated by the nature of a metaclass
    __slots__ = ()

    #002. Constructor
    def __new__(
        mcs, cls, bases, attrs
        ,apiPkgPull : Optional[str] = None
        ,apiPfxPull : str = ''
        ,apiSfxPull : str = ''
        ,apiPullHdl : Optional[callable] = lambda x: x
        ,lsPullOpt : dict = {}
        ,apiPkgPush : Optional[str] = None
        ,apiPfxPush : str = ''
        ,apiSfxPush : str = ''
        ,apiPushHdl : Optional[callable] = lambda x: x
        ,lsPushOpt : dict = {}
    ):
        #001. Handle parameters
        if not isinstance(apiPfxPull, str): apiPfxPull = ''
        if not isinstance(apiSfxPull, str): apiSfxPull = ''
        if not isinstance(apiPfxPush, str): apiPfxPush = ''
        if not isinstance(apiSfxPush, str): apiSfxPush = ''
        if not callable(apiPullHdl) : apiPullHdl = lambda x: x
        if not callable(apiPushHdl) : apiPushHdl = lambda x: x

        #100. Assign values to local variables
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        allargs = sys._getframe().f_code.co_varnames
        mcs.__exargs__ = [ v for v in allargs if v not in ['mcs', 'cls', 'bases', 'attrs'] ]

        #400. Define the private environment of the class to be created
        #410. Initialization structure
        # attrs['__init__'] = __init

        #430. Slots to protect the privacy
        slots = (
            '__pulled___','__pushed___','__hdlpull___','__hdlpush___','__inputkw_pull___','__inputkw_push___','__inputkw___'
        )
        if '__slots__' in attrs:
            attrs['__slots__'] += slots
        else:
            attrs['__slots__'] = slots

        #450. Methods
        #451. Public methods

        #450. Private methods
        if '__init__' in attrs:
            attrs['__init_org___'] = attrs['__init__']
            attrs.pop('__init__')
        else:
            def funcLambda(self, *pos, **kw): pass
            attrs['__init_org___'] = funcLambda

        #460. Properties
        #461. Read-only properties, aka active bindings
        #Quote: https://stackoverflow.com/questions/27629944/how-to-add-properties-to-a-metaclass-instance
        attrs['pulled'] = property(mcs.pulled)
        attrs['pushed'] = property(mcs.pushed)

        #465. Mutable properties
        attrs['hdlPull'] = property(mcs.getHdlPull, mcs.setHdlPull)
        attrs['hdlPush'] = property(mcs.getHdlPush, mcs.setHdlPush)

        #500. Create the new class on the fly
        newcls = super().__new__(mcs, cls, bases, attrs)

        #600. Create the initialization structure
        #[ASSUMPTION]
        #[1] This step is primarily for demostration of the usage of <staticmethod>
        #[2] <init> is defined as staticmethod of the metaclass
        #[3] When we need to call a staticmethod, we should prepend it with the newly created class <newcls>
        #[4] We pass the newly created class-object to the argument <clsobj> for possible reference of its private environment
        #     created while NOT instantiated
        setattr(newcls, '__init__', newcls.init(newcls, apiPullHdl, apiPushHdl))

        #700. Assign additional methods
        #710. Create the <pull> and <push> methods
        #[ASSUMPTION]
        #[1] Descriptors only work when used as class variables. When put in instances, they have no effect.
        #    https://docs.python.org/3/howto/descriptor.html
        #[2] When assigning the descriptor to a class attribute in metaclass, i.e. <mcs.pull_> and <mcs.push_>
        #    [1] <instance> is passed an object (not the newly created class) to below descriptor, demonstrating that descriptors
        #         are invoked after <newcls> is created by <__new__> and before it is instantiated by <__init__>
        #    [2] Since <mcs.pull_> and <mcs.push_> are class attributes, every time they are invoked, the descriptor will be called,
        #         which will consume excessive system resources
        #    [3] For this case, the descriptor is triggered once (or twice given both methods can be found) in the <if> clause
        #    [4] The same descriptor is called once per <setattr> statement due to the same reason
        #    [5] That is why we have to avoid such design
        #[3] When assigning the descriptor to a local variable, i.e. <pull_> and <push_>
        #    [1] There is no extra descriptor triggered during the class creation
        #    [2] The descriptor is only triggered once at getting the attribute via dot syntax, in the instantiated object
        #    [3] When the descriptor is triggered, <instance> is passed as not <None>; hence we need to bind the returned callable
        #         to the <instance> for correct processing
        pull_ = DynMethodLookup(
            apiCls = cls
            ,apiPkg = apiPkgPull
            ,apiPfx = apiPfxPull
            ,apiSfx = apiSfxPull
            ,lsOpt = lsPullOpt
            ,attr_handler = 'hdlPull'
            ,attr_kwInit = '__inputkw_pull___'
            ,attr_assign = '__pulled___'
            ,attr_return = 'pulled'
            ,coerce_ = True
        )
        push_ = DynMethodLookup(
            apiCls = cls
            ,apiPkg = apiPkgPush
            ,apiPfx = apiPfxPush
            ,apiSfx = apiSfxPush
            ,lsOpt = lsPushOpt
            ,attr_handler = 'hdlPush'
            ,attr_kwInit = '__inputkw_push___'
            ,attr_assign = '__pushed___'
            ,attr_return = 'pushed'
            ,coerce_ = True
        )

        #715. Verify whether the class should be created
        setattr(mcs, 'pull_', pull_)
        setattr(mcs, 'push_', push_)
        #[ASSUMPTION]
        #[1] This step would trigger the descriptor by providing <instance == None>
        #[2] Since we need to verify both methods, <coerce_> should be set as <True> to prevent early exception from being raised
        if (mcs.pull_ is None) and (mcs.push_ is None):
            raise TypeError(f'[{mcs.__name__}]No method found for class [{cls}] creation!')
        delattr(mcs, 'pull_')
        delattr(mcs, 'push_')

        #719. Creation
        setattr(newcls, 'pull', pull_)
        setattr(newcls, 'push', push_)

        #999. Export
        return( newcls )

    #500. Define the <__init__> structure during instantiation of the newly created class
    #[ASSUMPTION]
    #[1] <*pos> here basically represent 3 variables: <cls>, <bases> and <attrs> that are passed to the metaclass
    #[2] If we remove <*pos> in the arguments, we can only create class in below way:
    #    aaa = OpenSourceApiMeta('clsname', (object,), {}, apiPkgPull = None, ...)
    #[3] If we keep <*pos> in the arguments, we can also create class in below way:
    #    class clsname(metaclass = OpenSourceApiMeta, apiPkgPull = None, ...): pass
    #[4] This method will hijack the instantiation of the newly created class, hence any <__init__> defined in the
    #     newly created class is processed before the processes defined in the metaclass
    @staticmethod
    def init(clsobj, hdlPull : callable, hdlPush : callable):
        def __init__(self, *pos, argsPull = {}, argsPush = {}, **kw):
            #005. Set the default handlers BEFORE initialization, to allow the user to customize them at initialization
            self.hdlPull = hdlPull
            self.hdlPush = hdlPush

            #010. Hijack the original <__init__> and conduct its process ahead of the processes defined in the metaclass
            self.__init_org___(*pos, **kw)

            #100. Assign values to local variables
            self.__pulled___ = None
            self.__pushed___ = None
            self.__inputkw_pull___ = argsPull
            self.__inputkw_push___ = argsPush
            self.__inputkw___ = kw

        return(__init__)

    #100. Properties that can be accessed by the newly created class
    #[ASSUMPTION]
    #[1] These methods should be bound to <self> instead of <mcs>, i.e. they are only accessed in the newly created class
    #[2] There should not be references of any private variables that are bound to <mcs> within these method definitions,
    #     as they are only valid for use at metaclass level, just similar to MACRO facility in SAS
    def pulled(self):
        return(self.__pulled___)

    def pushed(self):
        return(self.__pushed___)

    def getHdlPull(self):
        return(self.__hdlpull___)

    def setHdlPull(self, func : callable):
        self.__hdlpull___ = func

    def getHdlPush(self):
        return(self.__hdlpush___)

    def setHdlPush(self, func : callable):
        self.__hdlpush___ = func

#End OpenSourceApiMeta

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import pandas as pd
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import OpenSourceApiMeta
    from omniPy.AdvOp import modifyDict

    #100. Prepare API in current session
    def api_testMeta():
        return({
            'name' : 'test API'
            ,'address' : 'RAM'
            ,'data' : {
                'rawdata' : [1,2,3]
                ,'series' : pd.Series([1,2,3])
            }
            ,'rc' : 0
        })

    #200. Create a class dynamically
    #[ASSUMPTION]
    #[1] The metaclass only takes 3 positional arguments: <cls>, <bases> and <attrs>
    #[2] <apiPfxPull + cls> here refers to the API name: 'api_testMeta'
    aaa = OpenSourceApiMeta('testMeta', (object,), {}, apiPfxPull = 'api_')
    aaa_obj = aaa()

    #210. Load data from the API
    rst = aaa_obj.pull()

    #230. Check if it is successful
    #[ASSUMPTION]
    #[1] Below statements return the same result
    rst.get('address')
    aaa_obj.pulled.get('address')
    # RAM

    #250. Try to obtain a non-existing property since <__init__> is not customized
    aaa_obj.bcd
    # AttributeError: 'testMeta' object has no attribute 'bcd'

    #300. Create a class in a conventional way
    #301. Prepare the function to remove the key <address> from the pulled data
    def h_remaddr(inval):
        rst = { k:v for k,v in inval.items() if k not in ['address'] }
        return(rst)

    #Quote: https://peps.python.org/pep-0487/
    #[ASSUMPTION]
    #[1] By doing this, all keyword arguments for the metaclass can be passed in via below syntax
    class testMeta(metaclass = OpenSourceApiMeta, apiPfxPull = 'api_'):
        #010. Define the additional slots (as there are some pre-defined slots in the metaclass)
        __slots__ = ('bcd',)

        #100. Define the customized initialization method
        def __init__(self):
            self.bcd = 112
            #Attach customized handler
            self.hdlPull = h_remaddr

    bbb = testMeta()

    #310. Try to obtain data from a non-existing API
    bbb.pulled.get('address')
    # AttributeError: 'NoneType' object has no attribute 'get'

    #330. Manually read data from the API
    rst2 = bbb.pull()

    #350. Now check the result
    rst2.get('name')
    # 'test API'

    #360. Try to obtain the removed attribute (by the customized handler)
    bbb.pulled.get('address', 'not exist')
    # not exist

    #390. Try to obtain the customized attribute
    bbb.bcd
    # 112

    #400. Create a universal framework to use API dynamically
    #[ASSUMPTION]
    #[1] This framework unifies the methods to call APIs when they are introduced on the fly
    #[2] One can define how to use these APIs by universal configurations
    class ApiOnTheFly():
        #002. Constructor
        def __init__(
            self
            #Search for the callable APIs from current session
            ,pkg_loader = None
            #Search for the APIs given their names start with this string
            ,pfx_loader = 'api_'
            #Default keyword arguments for all APIs when they are called
            ,args_loader = {}
        ):
            #100. Assign values to local variables
            self.pkg_loader = pkg_loader
            self.pfx_loader = pfx_loader
            self.args_loader = args_loader
            self.__lists_active__ = { k:False for k in self.full }

        #200. Private methods
        #210. Method to get attributes that are pre-defined at class instantiation
        def __getattr__(self, attr):
            if attr not in self.full:
                raise AttributeError(f'[{self.__class__.__name__}][{attr}] is not registered as an API')

            vfy_lists = [ a for a,s in self.lists_active.items() if not s ]
            if attr in vfy_lists:
                raise AttributeError(f'[{self.__class__.__name__}][{attr}] is not an active API')

            return(getattr(self, attr))

        #300. Public methods
        #310. Add an API by its name and read from it at initialization (as requested implicitly via <pullOnInit = True>)
        #[ASSUMPTION]
        #[1] Pass <**kw> to indicate different arguments for different APIs
        #[2] Create the class of APIs on the fly, and assign their names as attributes to this framework
        def add(self, attr, argsPull = {}, **kw):
            #010. Prepare an internal counter for each call of the API
            def _init(self):
                self.cnt = 0

            #100. Create API class on the fly
            #How to pass arguments to metaclass in class definition: (#2)
            #Quote: https://stackoverflow.com/questions/27258557/
            cls = OpenSourceApiMeta(
                attr, (object,), {'__slots__' : ('cnt',), '__init__' : _init}
                , apiPkgPull = self.pkg_loader, apiPfxPull = self.pfx_loader
            )

            #200. Prepare keyword arguments for reading data from the API
            #[ASSUMPTION]
            #[1] We take the default keyword arguments in current API as top priority,
            #     given neither <args_loader> nor <argsPull> is provided
            #[2] Given <args_loader> is non-empty while <**argsPull> is empty, we take <args_loader> to call the API
            #[3] Given <**argsPull> is provided, we call the API with it
            kw_add = modifyDict(self.args_loader.get(attr, {}), argsPull)

            #500. Instantiate the API and read data from it at once
            obj = cls(argsPull = kw_add, **kw)

            #600. Pull data via the API at initialization by default
            #[ASSUMPTION]
            #[1] One can change this behavior when necessary
            #[2] Prevent showing messages in the log as the method always returns result
            _ = obj.pull(**kw)

            #700. Add current API to the attribute list of current framework
            setattr(self, attr, obj)

            #900. Modify private environment
            modifyDict(self.__lists_active__, { attr : True }, inplace = True)

        #320. Add all available APIs to current private environment
        def addfull(self, argsPull = {}):
            for a in self.full:
                self.add(a, argsPull = argsPull.get(a, {}))

        #360. Remove API from private environment
        def remove(self, attr):
            delattr(self, attr)
            modifyDict(self.__lists_active__, { attr : False }, inplace = True)

        #370. Remove all active APIs from private environment
        def purge(self):
            for a in self.added:
                self.remove(a)

        #400. Private methods
        #410. Verify whether there is at least 1 active API in the private environment
        def _chkactive_(self):
            #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
            LfuncName : str = sys._getframe(1).f_code.co_name
            if len(self.added) == 0:
                raise ValueError(f'[{self.__class__.__name__}][{LfuncName}] is empty as there is no active API!')

        #500. Read-only properties
        #510. Obtain the full list of available APIs
        @property
        def full(self):
            apinames = [
                f[len(self.pfx_loader):]
                for f in globals().keys()
                if f.startswith(self.pfx_loader) and (not (f.startswith('__') and f.endswith('__')))
            ]
            return(apinames)

        #520. Obtain all active APIs
        @property
        def added(self):
            return({ k:self.__getattr__(k).pulled.get('data', {}).get('series') for k,v in self.lists_active.items() if v })

        #530. Obtain the status of all APIs, active: True, inactive: False
        @property
        def lists_active(self):
            return(self.__lists_active__)

        #550. Obtain the mapping of all active APIs to their names as obtained via their respective reader methods
        @property
        def names(self):
            self._chkactive_()
            return({ k:self.__getattr__(k).pulled.get('name') for k in self.added.keys() })
    #End ApiOnTheFly

    #500. Instantiate the class with default arguments
    addAPI = ApiOnTheFly()

    #510. List all available APIs at present
    addAPI.full
    # ['testMeta']

    #530. Load data from all APIs with default arguments
    addAPI.addfull()

    #590. Purge all active APIs and remove their loaded data
    addAPI.purge()

    #599. Try to list all names of the APIs in vain as they have been purged at above step
    addAPI.names
    # ValueError: [ApiOnTheFly][names] is empty as there is no active API!

    #600. Add the API defined above
    addAPI.add('testMeta')

    #610. Check the address of the data retrieved from current API
    addAPI.testMeta.pulled.get('address')
    # 'RAM'

    #630. Refresh data from the API with default arguments
    rst3 = addAPI.testMeta.pull()

    #700. Overwrite the default arguments to register APIs
    diff_args = {
        'fly' : {
            'arg_in' : [2,3,4]
        }
    }

    #705. Create a new API on the fly
    #[ASSUMPTION]
    #[1] Set this API as a method-like function, to count the times of call to it
    def api_fly(self, arg_in = [5]):
        self.cnt += 1
        return({
            'name' : 'on-the-fly'
            ,'address' : 'RAM'
            ,'data' : {
                'rawdata' : [2,3,5]
                ,'series' : pd.Series(arg_in)
            }
            ,'rc' : None
        })

    #710. Register and load data from all available APIs with the modified arguments
    addAPI.addfull(argsPull = diff_args)

    #730. Check the added APIs at current step
    ttt = addAPI.added

    #740. Remove an API from the namespace, together with its retrieved data
    addAPI.remove('testMeta')

    #750. Register and load data from a specific API with modified arguments
    addAPI.add('fly', argsPull = diff_args.get('fly', {}))

    #800. Check properties at current stage
    #810. List the mappings of API names
    addAPI.names
    # {'fly': 'on-the-fly'}

    #830. Check the status of registered APIs
    addAPI.lists_active
    # {'testMeta': False, 'fly': True}

    #850. Instantiate the framework with default arguments
    addAPI = ApiOnTheFly(args_loader = diff_args)

    #855. Load data from API with the modified default arguments
    addAPI.add('fly')

    addAPI.added
    # {'fly': 0    2
    #  1    3
    #  2    4
    #  dtype: int64}

    addAPI.fly.cnt
    # 1

    #Verify the counter
    rst4 = addAPI.fly.pull(arg_in = [5,6,7])

    addAPI.fly.cnt
    # 2

    rst4 = addAPI.fly.pull([8])

    addAPI.fly.pulled['data']['series']
    # 0    8
    # dtype: int64

    addAPI.fly.cnt
    # 3

    #900. Try to add an API that does not exist in vain
    addAPI.add('pseudo')
    # TypeError: [OpenSourceApiMeta]No method found for [pseudo] creation!

#-Notes- -End-
'''
