#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import sys
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from omniPy.AdvOp import get_values, importByStr, modifyDict

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
#   |   |   |                      [<str>               ]          Package name valid for function <omniPy.AdvOp.importByStr>           #
#   |   |   |apiPfxPull        :   <str     > Prefix of the puller API name to search                                                   #
#   |   |   |                      [<empty>             ]<Default> No specific prefix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper prefix to validate the search                           #
#   |   |   |apiSfxPull        :   <str     > Suffix of the puller API name to search                                                   #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper suffix to validate the search                           #
#   |   |   |apiPullHdl        :   <callable> Function with only one argument as handler to process the data pulled at once             #
#   |   |   |                      [lambda x: x         ]<Default> No handler is required                                               #
#   |   |   |                      [<callable>          ]          Function to process the pulled data                                  #
#   |   |   |apiPkgPush        :   <str     > Name of the package from which to obtain the API function to push the data                #
#   |   |   |                      [None                ]<Default> Obtain the API from current session in global environment            #
#   |   |   |                      [<str>               ]          Package name valid for function <omniPy.AdvOp.importByStr>           #
#   |   |   |apiPfxPush        :   <str     > Prefix of the pusher API name to search                                                   #
#   |   |   |                      [<empty>             ]<Default> No specific prefix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper prefix to validate the search                           #
#   |   |   |apiSfxPush        :   <str     > Suffix of the pusher API name to search                                                   #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper suffix to validate the search                           #
#   |   |   |apiPushHdl        :   <callable> Function with only one argument as handler to process the data pushed at once             #
#   |   |   |                      [lambda x: x         ]<Default> No handler is required                                               #
#   |   |   |                      [<callable>          ]          Function to process the pushed data                                  #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, inspect                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#   |   |   |importByStr                                                                                                                #
#   |   |   |modifyDict                                                                                                                 #
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
        ,apiPkgPull : str = None
        ,apiPfxPull : str = ''
        ,apiSfxPull : str = ''
        ,apiPullHdl : callable = lambda x: x
        ,apiPkgPush : str = None
        ,apiPfxPush : str = ''
        ,apiSfxPush : str = ''
        ,apiPushHdl : callable = lambda x: x
    ):
        #001. Handle parameters
        if apiPkgPush is None: apiPkgPush = apiPkgPull
        if apiPfxPull is None: apiPfxPull = ''
        if apiSfxPull is None: apiSfxPull = ''
        if apiPfxPush is None: apiPfxPush = ''
        if apiSfxPush is None: apiSfxPush = ''

        #100. Assign values to local variables
        #Quote[#379]: https://stackoverflow.com/questions/582056/getting-list-of-parameter-names-inside-python-function
        allargs = sys._getframe().f_code.co_varnames
        mcs.__exargs__ = [ v for v in allargs if v not in ['mcs', 'cls', 'bases', 'attrs'] ]

        #200. Define dynamic data reader based on pattern: <apiPfxPull + cls + apiSfxPull>
        def pull(self, *pos, **kw):
            #100. Define dynamic data reader
            apiPtnPull = str(apiPfxPull) + cls + str(apiSfxPull)

            #200. Prepare the callable core for creating the reader method
            try:
                if apiPkgPull is None:
                    __func_pull__ = get_values(apiPtnPull)
                else:
                    __func_pull__ = importByStr('.' + apiPtnPull, package = apiPkgPull)
            except:
                __func_pull__ = None

            #300. Verify whether the core reader is callable on the fly
            if not callable(__func_pull__):
                raise TypeError(f'[{cls}][{apiPtnPull}] is not callable!')

            #500. Overwrite the keyword arguments if they are not provided for each call of this method, but given at instantiation
            #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
            kw_new = modifyDict(self.__inputkw_pull__, kw)
            sig_raw = signature(__func_pull__).parameters.values()

            #510. Obtain all defaults of keyword arguments of the raw API
            kw_raw = {
                s.name : s.default
                for s in sig_raw
                if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
                and s.default is not s.empty
            }

            #550. In case the raw API takes any variant keywords, we also identify them
            #[ASSUMPTION]
            #[1] This only validates when the API takes variant keywords
            #[2] If the created class takes keyword arguments for both <pull> and <push>, there will not be KeyError raised
            #     when we add below handler to eliminate superfluous arguments for current API
            if len([ s.name for s in sig_raw if s.kind == s.VAR_KEYWORD ]) > 0:
                kw_varkw = { k:v for k,v in kw_new.items() if k not in kw_raw }
            else:
                kw_varkw = {}

            #590. Create the final keyword arguments for calling the API
            kw_final = modifyDict({ k:v for k,v in kw_new.items() if k in kw_raw }, kw_varkw)

            #900. Pull the data from the API
            self.__pulled__ = self.hdlPull(__func_pull__(*pos, **kw_final))

            #900. Return values
            #[ASSUMPTION]
            #[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
            # return(self)

        #300. Define dynamic data writer based on pattern: <apiPfxPush + cls + apiSfxPush>
        def push(self, *pos, **kw):
            #100. Define dynamic data writer
            apiPtnPush = str(apiPfxPush) + cls + str(apiSfxPush)

            #200. Prepare the callable core for creating the writer method
            try:
                if apiPkgPush is None:
                    __func_push__ = get_values(apiPtnPush)
                else:
                    __func_push__ = importByStr('.' + apiPtnPush, package = apiPkgPush)
            except:
                __func_push__ = None

            #300. Verify whether the core writer is callable on the fly
            if not callable(__func_push__):
                raise TypeError(f'[{cls}][{apiPtnPush}] is not callable!')

            #500. Overwrite the keyword arguments if they are not provided for each call of this method, but given at instantiation
            #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
            kw_new = modifyDict(self.__inputkw_push__, kw)
            sig_raw = signature(__func_push__).parameters.values()

            #510. Obtain all defaults of keyword arguments of the raw API
            kw_raw = {
                s.name : s.default
                for s in sig_raw
                if s.kind in ( s.KEYWORD_ONLY, s.POSITIONAL_OR_KEYWORD )
                and s.default is not s.empty
            }

            #550. In case the raw API takes any variant keywords, we also identify them
            if len([ s.name for s in sig_raw if s.kind == s.VAR_KEYWORD ]) > 0:
                kw_varkw = { k:v for k,v in kw_new.items() if k not in kw_raw }
            else:
                kw_varkw = {}

            #590. Create the final keyword arguments for calling the API
            kw_final = modifyDict({ k:v for k,v in kw_new.items() if k in kw_raw }, kw_varkw)

            #900. Push the data via the API
            self.__pushed__ = self.hdlPush(__func_push__(*pos, **kw_final))

        #400. Define the private environment of the class to be created
        #410. Initialization structure
        # attrs['__init__'] = __init

        #430. Slots to protect the privacy
        slots = ('__pulled__','__pushed__','__hdlpull__','__hdlpush__','__inputkw_pull__','__inputkw_push__','__inputkw__')
        if '__slots__' in attrs:
            attrs['__slots__'] += slots
        else:
            attrs['__slots__'] = slots

        #450. Methods
        #451. Public methods
        attrs['pull'] = pull
        attrs['push'] = push

        #450. Private methods
        if '__init__' in attrs:
            attrs['__init_org__'] = attrs['__init__']
            attrs.pop('__init__')
        else:
            def funcLambda(self, *pos, **kw): pass
            attrs['__init_org__'] = funcLambda

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
        def __init__(self, *pos, kw_pull_ = {}, kw_push_ = {}, **kw):
            #005. Set the default handlers BEFORE initialization, to allow the user to customize them at initialization
            self.hdlPull = hdlPull
            self.hdlPush = hdlPush

            #010. Hijack the original <__init__> and conduct its process ahead of the processes defined in the metaclass
            self.__init_org__(*pos, **kw)

            #100. Assign values to local variables
            self.__pulled__ = None
            self.__pushed__ = None
            self.__inputkw_pull__ = kw_pull_
            self.__inputkw_push__ = kw_push_
            self.__inputkw__ = kw

        return(__init__)

    #100. Properties that can be accessed by the newly created class
    #[ASSUMPTION]
    #[1] These methods should be bound to <self> instead of <mcs>, i.e. they are only accessed in the newly created class
    #[2] There should not be references of any private variables that are bound to <mcs> within these method definitions,
    #     as they are only valid for use at metaclass level, just similar to MACRO facility in SAS
    def pulled(self):
        return(self.__pulled__)

    def pushed(self):
        return(self.__pushed__)

    def getHdlPull(self):
        return(self.__hdlpull__)

    def setHdlPull(self, func : callable):
        self.__hdlpull__ = func

    def getHdlPush(self):
        return(self.__hdlpush__)

    def setHdlPush(self, func : callable):
        self.__hdlpush__ = func

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

    #210. Reload data from the API
    aaa_obj.pull()

    #230. Check if it is successful
    #Return: RAM
    aaa_obj.pulled.get('address')

    #250. Try to obtain a non-existing property since <__init__> is not customized
    #AttributeError: 'testMeta' object has no attribute 'bcd'
    aaa_obj.bcd

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
    #AttributeError: 'NoneType' object has no attribute 'get'
    bbb.pulled.get('address')

    #330. Manually read data from the API
    bbb.pull()

    #350. Now check the result
    #Return: 'test API'
    bbb.pulled.get('name')

    #360. Try to obtain the removed attribute (by the customized handler)
    bbb.pulled.get('address', 'not exist')
    # not exist

    #390. Try to obtain the customized attribute
    bbb.bcd

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
        def add(self, attr, **kw):
            #100. Create API class on the fly
            #How to pass arguments to metaclass in class definition: (#2)
            #Quote: https://stackoverflow.com/questions/27258557/
            cls = OpenSourceApiMeta(attr, (object,), {}, apiPkgPull = self.pkg_loader, apiPfxPull = self.pfx_loader)

            #200. Prepare keyword arguments for reading data from the API
            #[ASSUMPTION]
            #[1] We take the default keyword arguments in current API as top priority,
            #     given neither <args_loader> nor <kw> is provided
            #[2] Given <args_loader> is non-empty while <**kw> is empty, we take <args_loader> to call the API
            #[3] Given <**kw> is provided, we call the API with it
            kw_add = modifyDict(self.args_loader.get(attr, {}), kw)

            #500. Instantiate the API and read data from it at once
            obj = cls(kw_pull_ = kw_add)

            #600. Pull data via the API at initialization by default
            #[ASSUMPTION]
            #[1] One can change this behavior when necessary
            obj.pull()

            #700. Add current API to the attribute list of current framework
            setattr(self, attr, obj)

            #900. Modify private environment
            modifyDict(self.__lists_active__, { attr : True }, inplace = True)

        #320. Add all available APIs to current private environment
        def addfull(self, **kw):
            kw_add = modifyDict(self.args_loader, kw)
            for a in self.full:
                self.add(a, **kw_add.get(a, {}))

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

    #530. Load data from all APIs with default arguments
    addAPI.addfull()

    #590. Purge all active APIs and remove their loaded data
    addAPI.purge()

    #599. Try to list all names of the APIs in vain as they have been purged at above step
    #ValueError: [ApiOnTheFly][names] is empty as there is no active API!
    addAPI.names

    #600. Add the API defined above
    addAPI.add('testMeta')

    #610. Check the address of the data retrieved from current API
    #Return: 'RAM'
    addAPI.testMeta.pulled.get('address')

    #630. Refresh data from the API with default arguments
    addAPI.testMeta.pull()

    #700. Overwrite the default arguments to register APIs
    diff_args = {
        'fly' : {
            'arg_in' : [2,3,4]
        }
    }

    #705. Create a new API on the fly
    def api_fly(arg_in = [5]):
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
    addAPI.addfull(**diff_args)

    #730. Check the added APIs at current step
    ttt = addAPI.added

    #740. Remove an API from the namespace, together with its retrieved data
    addAPI.remove('testMeta')

    #750. Register and load data from a specific API with modified arguments
    addAPI.add('fly', **diff_args.get('fly', {}))

    #800. Check properties at current stage
    #810. List the mappings of API names
    addAPI.names

    #830. Check the status of registered APIs
    addAPI.lists_active

    #850. Instantiate the framework with default arguments
    addAPI = ApiOnTheFly(args_loader = diff_args)

    #855. Load data from API with the modified default arguments
    addAPI.add('fly')
    addAPI.added

    #900. Try to add an API that does not exist in vain
    #TypeError: [pseudo][api_pseudo] is not callable!
    addAPI.add('pseudo')

#-Notes- -End-
'''
