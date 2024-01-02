#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from omniPy.AdvDB import OpenSourceApiMeta
from omniPy.AdvOp import modifyDict, importByStr

class DataIO():
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to unify the APIs to <pull> data from harddisk to RAM and <push> the data frames onto hardisk               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__init__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate the container of data input-output methods                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |apiPkgPull        :   <str     > Name of the package from which to obtain the API function to pull the data                #
#   |   |   |                      [omniPy.AdvDB        ]<Default> Obtain the API from current session in global environment            #
#   |   |   |                      [<str>               ]          Package name valid for function <omniPy.AdvOp.importByStr>           #
#   |   |   |apiPfxPull        :   <str     > Prefix of the puller API name to search                                                   #
#   |   |   |                      [std_read_           ]<Default> Search for the API names by this prefix                              #
#   |   |   |                      [<str>               ]          Set a proper prefix to validate the search                           #
#   |   |   |apiSfxPull        :   <str     > Suffix of the puller API name to search                                                   #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper suffix to validate the search                           #
#   |   |   |apiPullHdl        :   <callable> Function with only one argument as handler to process the data pulled at once             #
#   |   |   |                      [lambda x: x         ]<Default> No handler is required                                               #
#   |   |   |                      [<callable>          ]          Function to process the pulled data                                  #
#   |   |   |apiPkgPush        :   <str     > Name of the package from which to obtain the API function to push the data                #
#   |   |   |                      [omniPy.AdvDB        ]<Default> Obtain the API from current session in global environment            #
#   |   |   |                      [<str>               ]          Package name valid for function <omniPy.AdvOp.importByStr>           #
#   |   |   |apiPfxPush        :   <str     > Prefix of the pusher API name to search                                                   #
#   |   |   |                      [std_write_          ]<Default> Search for the API names by this prefix                              #
#   |   |   |                      [<str>               ]          Set a proper prefix to validate the search                           #
#   |   |   |apiSfxPush        :   <str     > Suffix of the pusher API name to search                                                   #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |                      [<str>               ]          Set a proper suffix to validate the search                           #
#   |   |   |apiPushHdl        :   <callable> Function with only one argument as handler to process the data pushed at once             #
#   |   |   |                      [lambda x: x         ]<Default> No handler is required                                               #
#   |   |   |                      [<callable>          ]          Function to process the pushed data                                  #
#   |   |   |argsPull          :   <dict    > Collection of keyword arguments set as default for <pull> methods when instantiating the  #
#   |   |   |                       class; <key> is the available API name, <value> is the kwargs for its <pull> method                 #
#   |   |   |                      [<see def.>          ]<Default> Pull SAS datasets with encoding <GB18030> as maximum compatibility   #
#   |   |   |                      [<dict>              ]          dict[<apiname> : dict[kw]]                                           #
#   |   |   |argsPush          :   <dict    > Collection of keyword arguments set as default for <push> methods when instantiating the  #
#   |   |   |                       class; <key> is the available API name, <value> is the kwargs for its <push> method                 #
#   |   |   |                      [<see def.>          ]<Default> Push SAS datasets with encoding <GB2312> as maximum compatibility    #
#   |   |   |                      [<dict>              ]          dict[<apiname> : dict[kw]]                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   Only for initialization                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[add]                                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to register an API with all its available methods to pull or push the data                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |attr              :   <str     > Name of the dedicated API to register, e.g. SAS, HDFS or RAM                              #
#   |   |   |kw_pull_          :   <dict    > kwargs for the <pull> method of the registered API as default arguments at initilization  #
#   |   |   |kw_push_          :   <dict    > kwargs for the <push> method of the registered API as default arguments at initilization  #
#   |   |   |kw                :   <dict    > Additional keyword arguments. Not in use, but with compatibility of unified process       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method only creates and instantiates the dynamic class by registering the API                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[addfull]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to register all available APIs found in the provided packages at once                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |kw_pull_          :   <dict    > kwargs for the <pull> method diferred for all APIs as default arguments at initilization  #
#   |   |   |kw_push_          :   <dict    > kwargs for the <push> method diferred for all APIs as default arguments at initilization  #
#   |   |   |kw                :   <dict    > Additional keyword arguments. Not in use, but with compatibility of unified process       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method only creates and instantiates the dynamic class by registering the APIs                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[remove]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to deactivate an API                                                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |attr              :   <str     > Name of the dedicated API to deactivate                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method only deactivates the API                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[removefull]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to deactivate all active APIs at once                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method only deactivates the APIs                                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_chkactive_]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to abort the process if some dedicated methods are to operate on the results from an API which #
#   |   |   |   | is NOT registered as an active one in current environment                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not return any value, except that it aborts the process when necessary              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_rem_affix_]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to extract the API name from the entire string, a.k.a. the name of the <pull> or <push>        #
#   |   |   |   | method, that contains the prefix and suffix                                                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |mthdname          :   <str   > Name of the method, from which to extract the API name                                      #
#   |   |   |pfx               :   <str   > Prefix of the method name to remove                                                         #
#   |   |   |                      [<empty>             ]<Default> No specific prefix, be careful to use this setting                   #
#   |   |   |sfx               :   <str   > Suffix of the method name to remove                                                         #
#   |   |   |                      [<empty>             ]<Default> No specific suffix, be careful to use this setting                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<str>             :   The extracted API name                                                                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[full]                                                                                                                         #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This property is to retrieve all the available APIs by validating the existence of their available methods             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<set>             :   Full set of available APIs to <pull> or <push> data per request                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[status]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This property is to retrieve the status of all available APIs, <True> means the API is activated and instantiated,     #
#   |   |   |   | <False> is otherwise                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<dict>            :   dict[<API> : bool]                                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[active]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This property is to retrieve the set of all active (i.e. instantiated) APIs                                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<set>             :   Set of active APIs                                                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240101        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |OpenSourceApiMeta                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |importByStr                                                                                                                #
#   |   |   |modifyDict                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #002. Constructor
    def __init__(
        self
        ,apiPkgPull : str = 'omniPy.AdvDB'
        ,apiPfxPull : str = 'std_read_'
        ,apiSfxPull : str = ''
        ,apiPullHdl : callable = lambda x: x
        ,apiPkgPush : str = 'omniPy.AdvDB'
        ,apiPfxPush : str = 'std_write_'
        ,apiSfxPush : str = ''
        ,apiPushHdl : callable = lambda x: x
        ,argsPull : dict = {
            'SAS' : {
                'encoding' : 'GB18030'
            }
        }
        ,argsPush : dict = {
            'SAS' : {
                'encoding' : 'GB2312'
            }
        }
    ):
        #100. Assign values to local variables
        self.apiPkgPull = apiPkgPull
        self.apiPfxPull = apiPfxPull
        self.apiSfxPull = apiSfxPull
        self.apiPullHdl = apiPullHdl
        self.apiPkgPush = apiPkgPush
        self.apiPfxPush = apiPfxPush
        self.apiSfxPush = apiSfxPush
        self.apiPushHdl = apiPushHdl
        self.argsPull = argsPull
        self.argsPush = argsPush
        self.__dict_active__ = { k:False for k in self.full }

    #200. Private methods
    #210. Method to get attributes that are pre-defined at class instantiation
    def __getattr__(self, attr):
        if attr not in self.full:
            raise AttributeError(f'[{self.__class__.__name__}][{attr}] is not registered as an API')

        vfy_lists = [ a for a,s in self.status.items() if not s ]
        if attr in vfy_lists:
            raise AttributeError(f'[{self.__class__.__name__}][{attr}] is not an active API')

        return(getattr(self, attr))

    #220. Method to enable slicing fashion during operation on APIs
    #Quote: https://www.liaoxuefeng.com/wiki/1016959663602400/1017590712115904
    def __getitem__(self, attr):
        return(self.__getattr__(attr))

    #300. Public methods
    def add(self, attr, kw_pull_ = {}, kw_push_ = {}, **kw):
        #100. Verify whether the API can be found in the candidate packages
        if attr not in self.full:
            raise ValueError(f'[{self.__class__.__name__}]No method is found to register API for [{attr}]!')

        #200. Create API class on the fly
        #How to pass arguments to metaclass in class definition: (#2)
        #Quote: https://stackoverflow.com/questions/27258557/
        cls = OpenSourceApiMeta(
            attr, (object,), {}
            ,apiPkgPull = self.apiPkgPull
            ,apiPfxPull = self.apiPfxPull
            ,apiSfxPull = self.apiSfxPull
            ,apiPullHdl = self.apiPullHdl
            ,apiPkgPush = self.apiPkgPush
            ,apiPfxPush = self.apiPfxPush
            ,apiSfxPush = self.apiSfxPush
            ,apiPushHdl = self.apiPushHdl
        )

        #300. Prepare keyword arguments for reading data from the API
        #[ASSUMPTION]
        #[1] We take the default keyword arguments in current API as top priority,
        #     given neither <argsPull> nor <kw> is provided
        #[2] Given <argsPull> is non-empty while <**kw> is empty, we take <argsPull> to call the API
        #[3] Given <**kw> is provided, we call the API with it
        #[4] Use the same logic to handle <argsPush>
        kw_pull = modifyDict(self.argsPull.get(attr, {}), kw_pull_)
        kw_push = modifyDict(self.argsPush.get(attr, {}), kw_push_)

        #500. Instantiate the API and read data from it at once
        obj = cls(kw_pull_ = kw_pull, kw_push_ = kw_push, **kw)

        #700. Add current API to the attribute list of current framework
        setattr(self, attr, obj)

        #900. Modify private environment
        modifyDict(self.__dict_active__, { attr : True }, inplace = True)

    #320. Add all available APIs to current private environment
    def addfull(self, kw_pull_ = {}, kw_push_ = {}, **kw):
        kw_pull = modifyDict(self.argsPull, kw_pull_)
        kw_push = modifyDict(self.argsPush, kw_push_)
        for a in self.full:
            self.add(a, kw_pull_ = kw_pull.get(a, {}), kw_push_ = kw_push.get(a, {}), **kw)

    #360. Remove API from private environment
    def remove(self, attr):
        if attr in self.active:
            delattr(self, attr)
            modifyDict(self.__dict_active__, { attr : False }, inplace = True)

    #370. Remove all active APIs from private environment
    def removefull(self):
        for a in self.active:
            self.remove(a)

    #400. Private methods
    #410. Verify whether there is at least 1 active API in the private environment
    def _chkactive_(self):
        LfuncName : str = sys._getframe(1).f_code.co_name
        if len(self.active) == 0:
            raise ValueError(f'[{self.__class__.__name__}][{LfuncName}] is empty as there is no active API!')

    #430. Remove the affixes from the API names
    def _rem_affix_(self, mthdname : str, pfx : str = '', sfx : str = ''):
        rstOut = mthdname
        if len(pfx):
            rstOut = rstOut[len(pfx):]
        if len(sfx):
            rstOut = rstOut[:-len(sfx)]
        return(rstOut)

    #500. Read-only properties
    #510. Obtain the full set of available APIs
    @property
    def full(self):
        #300. Identify all <pull> methods matching the provided pattern of API names
        pkg_pull = importByStr(self.apiPkgPull, asModule = True)
        api_pull = {
            self._rem_affix_(f, pfx = self.apiPfxPull, sfx = self.apiSfxPull)
            for f in dir(pkg_pull)
            if f.startswith(self.apiPfxPull) and f.endswith(self.apiSfxPull)
        }

        #500. Identify all <push> methods matching the provided pattern of API names
        pkg_push = importByStr(self.apiPkgPush, asModule = True)
        api_push = {
            self._rem_affix_(f, pfx = self.apiPfxPush, sfx = self.apiSfxPush)
            for f in dir(pkg_push)
            if f.startswith(self.apiPfxPush) and f.endswith(self.apiSfxPush)
        }

        #999. Return if there is either a <pull> method or <push> for the API
        return(api_pull | api_push)

    #520. Obtain the status of all APIs
    @property
    def status(self):
        return(self.__dict_active__)

    #530. Obtain the names of active APIs
    @property
    def active(self):
        return({ k for k,v in self.status.items() if v })
#End DataIO

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import os
    import pandas as pd
    import sys
    from functools import partial
    from collections.abc import Iterable
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import DataIO
    from omniPy.AdvDB import loadSASdat, inferContents
    from omniPy.AdvOp import get_values

    cwd = os.getcwd()

    #100. Launch the tool with default arguments
    datatrns = DataIO()

    #200. List all available APIs at present
    datatrns.full

    #300. Convert data using SAS API
    smpl_sas = os.path.join(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat')
    api = 'SAS'
    datatrns.add(api)

    #310. Load data
    #[ASSUMPTION]
    #[1] Most of the arguments for this method come from <pyreadstat.read_sas7bdat>
    #[2] Some of the arguments are from <omniPy.AdvDB.loadSASdat>
    #[3] Rest of the arguments are from <omniPy.AdvDB.std_read_SAS>
    #Quote: https://ofajardo.github.io/pyreadstat_documentation/_build/html/index.html#module-pyreadstat.pyreadstat
    sas_pulled = datatrns.__getattribute__(api).pull(smpl_sas)
    # Same as: datatrns.SAS.pull(smpl_sas)

    #330. Redirect the pulled data
    # A simpler way to operate on current API is to use slicing fashion
    sas_pulled2 = datatrns[api].pulled
    # pd.DataFrame

    #350. Write the data from RAM to the requested path
    #351. Load the meta information of the sample data
    _, meta = loadSASdat(smpl_sas, metadataonly = True)

    #355. Modify the inference of the output config
    meta_sas = inferContents(sas_pulled)
    meta_sas.loc[:, 'LENGTH'] = (
        pd.Series(
            meta.variable_storage_width.values()
            ,index = meta.variable_storage_width.keys()
            ,dtype = int
        )
        .reindex(meta_sas['NAME'])
        .set_axis(meta_sas.index)
    )
    meta_sas.loc[:, 'LABEL'] = (
        pd.Series(
            meta.column_names_to_labels.values()
            ,index = meta.column_names_to_labels.keys()
            ,dtype = str
        )
        .reindex(meta_sas['NAME'])
        .set_axis(meta_sas.index)
    )
    meta_sas.loc[lambda x: x['NAME'].eq('f_qpv'), 'FORMATD'] = 0

    #359. Push the data to the destination using the modified meta config table
    #[ASSUMPTION]
    #[1] 'test' is a placeholder for this API, just for unification purpose
    outf1 = os.path.join(cwd, 'vfysas1.sas7bdat')
    rc = datatrns[api].push({'test' : sas_pulled}, outfile = outf1, metaVar = meta_sas)
    if os.path.isfile(outf1): os.remove(outf1)

    #500. Convert data using HDFS API
    smpl_hdf = {
        'key1' : pd.DataFrame({'aa' : [1,3,5], 'bb' : ['c','d','e']})
        ,'key2' : pd.DataFrame({'aa' : [5,4,8], 'kk' : ['f','g','h']})
    }
    outf2 = os.path.join(cwd, 'vfyhdf1.hdf')
    api2 = 'HDFS'
    datatrns.add(api2)

    #510. Write the data from RAM to the requested path
    #[ASSUMPTION]
    #[1] HDFStore can store multiple objects in the same batch
    rc = datatrns[api2].push(smpl_hdf, outfile = outf2)

    #530. Load data from above storage
    #[ASSUMPTION]
    #[1] As a unified process, the <pull> method can only pull one object from the API
    hdf_pulled = datatrns[api2].pull(outf2, key = 'key2')

    #560. Change the handler of <pull> method for the API of HDFS
    #561. Prepare the function to remove the required column from the data frame
    def h_remcol(df : pd.DataFrame, col : str | list[str]):
        if isinstance(col, str):
            col = [col]
        elif not isinstance(col, Iterable):
            raise TypeError('[col] should be Iterable!')
        df_new = df.loc[:, lambda x: ~x.columns.isin(col)]
        return(df_new)

    #563. Modify the handler
    datatrns[api2].hdlPull = partial(h_remcol, col = ['bb','kk'])

    #570. Load data with the updated handler
    hdf_chk = datatrns[api2].pull(outf2, key = 'key1')

    #599. Purge
    if os.path.isfile(outf2): os.remove(outf2)

    #700. Operate in RAM
    dat_before = pd.DataFrame({'a' : [2,5,9]})
    api3 = 'RAM'
    datatrns.add(api3)

    #710. Read data from RAM by its name and mutate it
    def h_conv(df):
        df_new = df.assign(**{'b' : lambda x: pd.Series([5,4,1], index = x.index)})
        return(df_new)
    ram_redir = datatrns[api3].pull('dat_before', funcConv = h_conv)

    #750. Push the data to another address within RAM
    #[ASSUMPTION]
    #[1] Same as SAS, 'dummy' is a placeholder for this API, just for unification purpose
    rc = datatrns[api3].push({'dummy' : ram_redir}, outfile = 'ram_new')

    #770. Retrieve the exported data frame
    #[ASSUMPTION]
    #[1] According to PEP-558, direct reference of the object updated into <f_locals> is unacceptable for <Python <= 3.13>
    #[2] That is why <ram_new> is there and yet we can only reference it by below method
    #Quote: https://peps.python.org/pep-0558/
    ram_visible = get_values('ram_new', instance = pd.DataFrame)

    #900. Try to add an API that does not exist in vain
    #ValueError: [DataIO]No method is found to register API for [pseudo]!
    datatrns.add('pseudo')

#-Notes- -End-
'''
