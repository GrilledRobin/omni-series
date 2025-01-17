#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import types
from typing import Optional
from omniPy.AdvOp import lookupMethod

class DynMethodLookup:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Descriptor is intended to unify the dynamic lookup of APIs in any dedicated class                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Enable dynamic method lookup in a dynamically created class                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__init__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |The constructor to initialize the arguments for dynamic method lookup                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |**kw              :   All the arguments are from <AdvOp.lookupMethod>, please check its document                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not return values                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__set_name__]                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to store the public name and private name of the dynamically created internal method, to ensure#
#   |   |   |   | uniqueness of the internal environment                                                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |owner             :   Owner of the descriptor                                                                              #
#   |   |   |name              :   The class attribute described by the descriptor                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not return values                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__get__]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method enables non-data part of the descriptor (a.k.a. non-data descriptor), acting as the lookup function        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |instance          :   The owner instance to which to bind the newly created method                                         #
#   |   |   |objtype           :   Optional object type to manipulate the function                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<callable>        :   Return the newly created method bound to the owner instance                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__set__]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method ensures this to be a read-only data descriptor, to prevent the newly created method from being modified    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |instance          :   The owner instance to which to bind the newly created method                                         #
#   |   |   |value             :   The updated value of the method, omitted on purpose                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<Exception>       :   Calling this method always raises exception, to prevent object mutation from inside                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
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
#   |   |types, typing                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |lookupMethod                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

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
        #[ASSUMPTION]
        #[1] Enable the functionality when calling the descriptor as Class Attribute
        #[2] That say: when a class is defined with descriptor, <instance> passed to this descriptor is not <None>
        #[3] Only the descriptor object is bound to the caller instance, the method returned here is NOT bound to that instance
        #[4] Hence we need to bind the method to <instance>
        #[5] 20250102 It is tested that binding to <self> or <instance> have the same effect, which is to be investigated
        if instance:
            return(types.MethodType(func_, instance))
        else:
            #[ASSUMPTION]
            #[1] This is the branch when triggered in a metaclass for method existence check
            return(func_)

    #500. Ensure it is a read-only data descriptor
    def __set__(self, instance, value):
        apiCls = self.apiCls or self._dfl_public_name_
        raise AttributeError(f'[{instance.__class__.__name__}]Attribute [{apiCls}] is read-only!')
#End DynMethodLookup

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
    from omniPy.AdvOp import DynMethodLookup

    #100. Define the API which can be bound as a method of some instance
    def loader_api001(self, b):
        return(self.aaa + b)

    #300. Dynamically search for API in a class
    class MyClass2:
        #[ASSUMPTION]
        #[1] There is no need to set <apiCls> as <api001> is the named owner of the descriptor
        #[2] <apiCls> is required when this descriptor is used in a metaclass to dynamically create a class
        api001 = DynMethodLookup(
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

    testadd2 = MyClass2()

    #[ASSUMPTION]
    #[1] Extra named parameters are omitted, enabling standardized call of diffferent methods (although not recommended as always!)
    testadd2.api001(20, e = 5)
    # 30

    #360. Try to assign the API with another object
    testadd2.api001 = 111
    # AttributeError: [MyClass2]Attribute [api001] is read-only!
#-Notes- -End-
'''
