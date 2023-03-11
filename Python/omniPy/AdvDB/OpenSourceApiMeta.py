#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import sys
import inspect
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from omniPy.AdvOp import get_values, importByStr

#100. Definition of the class.
class OpenSourceApiMeta(type):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to unify the APIs to communicate with various open sources, e.g. FTP, File System and DB Engines to <pull>  #
#   | data or <push> data in simplified and standardized manner                                                                         #
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
#   |   |   |pullOnInit        :   <bool    > Whether to pull data from the API on instantiation of the newly created class             #
#   |   |   |                      [True                ]<Default> Pull data on instantiation to simplify the usage                     #
#   |   |   |                      [False               ]          Do not pull data on instantiation                                    #
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
#   |   |   |pushOnInit        :   <bool    > Whether to push data via the API on instantiation of the newly created class              #
#   |   |   |                      [True                ]<Default> Push data on instantiation to simplify the usage                     #
#   |   |   |                      [False               ]          Do not push data on instantiation                                    #
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
        ,pullOnInit : bool = True
        ,apiPfxPull : str = ''
        ,apiSfxPull : str = ''
        ,apiPullHdl : callable = lambda x: x
        ,apiPkgPush : str = None
        ,pushOnInit : bool = False
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
        mcs.__pullOnInit__ = pullOnInit
        mcs.__pushOnInit__ = pushOnInit

        #200. Define dynamic data reader based on pattern: <apiPfxPull + cls + apiSfxPull>
        mcs.apiPtnPull = str(apiPfxPull) + cls + str(apiSfxPull)

        #210. Prepare the callable core for creating the reader method
        try:
            if apiPkgPull is None:
                mcs.__func_pull__ = get_values(mcs.apiPtnPull)
            else:
                mcs.__func_pull__ = importByStr('.' + mcs.apiPtnPull, package = apiPkgPull)
        except:
            mcs.__func_pull__ = None
        mcs.__pullCallable__ = callable(mcs.__func_pull__)

        #250. Define checker for whether the translated name leads to a callable
        #[ASSUMPTION]
        #[1] The reason why we do not define this function as we define <mcs.pull>, is that it references the variables
        #     at metaclass level, e.g. <mcs>, which only validates at <__new__> stage
        #[2] All the metaclass-level variables referenced in below function definition are retrieved at <__new__> stage
        #[3] Hence the entire function is registered to the newly created class as a CONSTANT
        #[4] That is why we can set it as a method in the newly created class and call it where necessary
        def __chkPullCallable__(self):
            #[ASSUMPTION]
            #[1] Similar to MACRO facility in SAS, <mcs.__pullCallable__> is translated to a boolean CONSTANT in the
            #     newly created class
            if not mcs.__pullCallable__:
                raise TypeError(f'[{cls}][{mcs.apiPtnPull}] is not callable!')

        #290. Create the reader method
        def pull(self, *pos, **kw):
            #100. Verify whether the core reader is callable on the fly
            self.__chkPullCallable__()

            #500. Pull the data from the API
            self.__pulled__ = apiPullHdl(mcs.__func_pull__(*pos, **kw))

            #900. Return values
            #[ASSUMPTION]
            #[1] We MUST NOT return self as it will lead to massive recursion when called in the instance
            # return(self)

        #300. Define dynamic data writer based on pattern: <apiPfxPush + cls + apiSfxPush>
        mcs.apiPtnPush = str(apiPfxPush) + cls + str(apiSfxPush)

        #310. Prepare the callable core for creating the writer method
        try:
            if apiPkgPull is None:
                mcs.__func_push__ = get_values(mcs.apiPtnPush)
            else:
                mcs.__func_push__ = importByStr('.' + mcs.apiPtnPush, package = apiPkgPush)
        except:
            mcs.__func_push__ = None
        mcs.__pushCallable__ = callable(mcs.__func_push__)

        #350. Define checker for whether the translated name leads to a callable
        def __chkPushCallable__(self):
            if not mcs.__pushCallable__:
                raise TypeError(f'[{cls}][{mcs.apiPtnPush}] is not callable!')

        #390. Create the writer method
        def push(self, *pos, **kw):
            #100. Verify whether the core writer is callable on the fly
            self.__chkPushCallable__()

            #500. Push the data via the API
            self.__pulled__ = apiPushHdl(mcs.__func_push__(*pos, **kw))

        #500. Define the <__init__> structure during instantiation of the newly created class
        #[ASSUMPTION]
        #[1] <*pos> here basically represent 3 variables: <cls>, <bases> and <attrs> that are passed to the metaclass
        #[2] If we remove <*pos> in the arguments, we can only create class in below way:
        #    aaa = OpenSourceApiMeta('clsname', (object,), {}, apiPkgPull = None, ...)
        #[3] If we keep <*pos> in the arguments, we can also create class in below way:
        #    class bbb(metaclass = OpenSourceApiMeta('clsname', (object,), {}, apiPkgPull = None, ...)): pass
        #[4] This method will hijack the instantiation of the newly created class, hence any <__init__> defined in the
        #     newly created class fails to take effect
        def __init(self, *pos, **kw):
            #100. Assign values to local variables
            self.__pulled__ = None
            self.__pushed__ = None

            #400. Read data at initialization when requested
            #[ASSUMPTION]
            #[1] Similar to MACRO facility in SAS, <if mcs.__pullOnInit__:...> is translated to <if True/False:...> in
            #     the newly created class, i.e. the condition is set as CONSTANT at metaclass level
            if mcs.__pullOnInit__:
                #[ASSUMPTION]
                #[1] If we try to get signature of <self.pull>, we only get <*pos> and <**kw>, just as what we defined above
                #[2] Hence we need to get signature of the metaclass-level method <mcs.__func_pull__> for its defaults and
                #     set them as CONSTANT in the newly created class
                #[3] Unlike that one defined in <self.pull>, exception should be raised before we call the reader method,
                #     before we get the signature of <mcs.__func_pull__>, otherwise the exception raised will be different
                #     from what we desire
                #100. Verify whether the core reader is callable on the fly
                self.__chkPullCallable__()

                #400. Verify which among the keyword arguments provided are also among the core reader method
                #410. Retrieve the signature of the core reader method
                args_r = signature(mcs.__func_pull__).parameters.values()

                #450. Only validate the keyword arguments that are allowed by the reader method
                kw_r_name = [ s.name for s in args_r if s.default is not inspect._empty ]
                kw_r = { k:v for k,v in kw.items() if k in kw_r_name }

                #700. Pull data from the API
                self.pull(**kw_r)

            #700. Write data via API at initialization when requested
            if mcs.__pushOnInit__:
                #100. Verify whether the core reader is callable on the fly
                self.__chkPushCallable__()

                #400. Verify which among the keyword arguments provided are also among the core reader method
                #410. Retrieve the signature of the core reader method
                args_w = signature(mcs.__func_push__).parameters.values()

                #450. Only validate the keyword arguments that are allowed by the reader method
                kw_w_name = [ s.name for s in args_w if s.default is not inspect._empty ]
                kw_w = { k:v for k,v in kw.items() if k in kw_w_name }

                #700. Pull data from the API
                self.push(**kw_w)
        #End __init

        #700. Define the private environment of the class to be created
        #710. Initialization structure
        attrs['__init__'] = __init

        #730. Slots to protect the privacy
        attrs['__slots__'] = ('__pulled__','__pushed__')

        #750. Methods
        #751. Public methods
        attrs['pull'] = pull
        attrs['push'] = push

        #750. Private methods
        attrs['__chkPullCallable__'] = __chkPullCallable__
        attrs['__chkPushCallable__'] = __chkPushCallable__

        #800. Properties
        #810. Read-only properties, aka active bindings
        #Quote: https://stackoverflow.com/questions/27629944/how-to-add-properties-to-a-metaclass-instance
        attrs['pulled'] = property(mcs.pulled)
        attrs['pushed'] = property(mcs.pushed)

        #900. Create the new class on the fly
        return( super().__new__(mcs, cls, bases, attrs) )

    #100. Properties that can be accessed by the newly created class
    #[ASSUMPTION]
    #[1] These methods should be bound to <self> instead of <mcs>, i.e. they are only accessed in the newly created class
    #[2] There should not be references of any private variables that are bound to <mcs> within these method definitions,
    #     as they are only valid for use at metaclass level, just similar to MACRO facility in SAS
    def pulled(self):
        return(self.__pulled__)

    def pushed(self):
        return(self.__pushed__)

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

    #200. Create a class with <pullOnInit = True> as default
    #[ASSUMPTION]
    #[1] The metaclass only takes 3 positional arguments: <cls>, <bases> and <attrs>
    #[2] <apiPfxPull + cls> here refers to the API name: 'api_testMeta'
    class aaa(metaclass = OpenSourceApiMeta('testMeta', (object,), {}, apiPfxPull = 'api_')):
        #[ASSUMPTION]
        #[1] <__init__> has been hijacked in the metaclass, it takes no effect any more
        def __init__(self):
            self.bcd = 1

    #210. Check if it is successful
    #Return: RAM
    aaa.pulled.get('address')

    #230. Reload data from the API
    aaa.pull()

    #250. Try to obtain a non-existing property since <__init__> is no longer effective
    #AttributeError: 'testMeta' object has no attribute 'bcd'
    aaa.bcd

    #300. Create a class with <pullOnInit = False>
    class bbb(metaclass = OpenSourceApiMeta('testMeta', (object,), {}, apiPfxPull = 'api_', pullOnInit = False)):
        pass

    #310. Try to obtain data from a non-existing API
    #AttributeError: 'NoneType' object has no attribute 'get'
    bbb.pulled.get('address')

    #330. Manually read data from the API
    bbb.pull()

    #350. Now check the result
    #Return: 'test API'
    bbb.pulled.get('name')

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
            self.__lists__ = {}
            self.pkg_loader = pkg_loader
            self.pfx_loader = pfx_loader
            self.args_loader = args_loader
            self.__lists_active__ = { k:False for k in self.full }

        #200. Private methods
        #210. Method to get attributes that are pre-defined at class instantiation
        def __getattr__(self, attr):
            vfy_lists = [ a for a,s in self.lists_active.items() if not a ]
            if attr in vfy_lists:
                raise AttributeError(f'[{self.__class__.__name__}][{attr}] is not an active API')

            if attr not in self.full:
                raise AttributeError(f'[{self.__class__.__name__}][{attr}] is not registered as an API')

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
            obj = cls(**kw_add)

            #700. Add current API to the attribute list of current framework
            setattr(self, attr, obj)

            #900. Modify private environment
            modifyDict(self.__lists__, { attr : obj.pulled.get('data', {}).get('series') }, inplace = True)
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
            return({ k:v for k,v in self.__lists__.items() if self.lists_active.get(k, False) })

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

    #900. Try to add an API that does not exist in vain
    #TypeError: [pseudo][api_pseudo] is not callable!
    addAPI.add('pseudo')

#-Notes- -End-
'''
