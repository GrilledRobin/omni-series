#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from collections.abc import Mapping
from copy import deepcopy

def modifyDict( d , u , inplace = False ) -> 'Recursively Modify Items of a Dict':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to modify a dict by a sub-dict in recursion, resembling [modifyList] in R language                       #
#   |[Quote]     https://stackoverflow.com/questions/3232943/update-value-of-a-nested-dictionary-of-varying-depth                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |d          :   Dict to be updated, with any depth of sub-dicts                                                                     #
#   |u          :   Dict used to update[d], with any depth of sub-dicts                                                                 #
#   |               [IMPORTANT] This dict is dedicated to replace the corresponding items in [d]                                        #
#   |inplace    :   Whether to overwrite the input [d]                                                                                  #
#   |               [False    ]  <Default> Create a new dict and leave the input [d] un-impacted                                        #
#   |               [True     ]            Replace the input [d]                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Dict    ] :   The updated [d] as a new dict (by default), or in place if required                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210311        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, collections, copy                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(inplace, bool): inplace = False

    #100. Determine whether to replace the input dict
    if inplace:
        d_out = d
    else:
        d_out = deepcopy(d)

    #900. Conduct the update
    for k, v in u.items():
        if isinstance(v, Mapping):
            d_out[k] = modifyDict(d_out.get(k, {}), v)
        else:
            d_out[k] = v
    return d_out
#End modifyDict

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010. Create envionment.
    import sys
    from copy import deepcopy
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import exec_file, modifyDict

    #100. Load the pre-defined dict for testing
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #200. Update a part of the dict and create a new dict by default without impacting the input dict
    cfg_local = modifyDict(
        getOption['args.def.GTSFK']
        ,{
            'inKPICfg' : 'KPICfg_all'
            ,'InfDatCfg' : {
                'InfDat' : 'acctinfo'
            }
        }
    )
    print(cfg_local)
    print(getOption['args.def.GTSFK'])

    #300. Replace the input dict with the updated one
    #In such case there is no need to assign values to [tt2] using [tt2=...] as [tt] will have been modified anyway.
    tt = deepcopy(getOption['args.def.GTSFK'])
    tt2 = modifyDict(
        tt
        ,{
            'inKPICfg' : 'KPICfg_test'
            ,'InfDatCfg' : {
                'InfDat' : 'acctinfo'
            }
        }
        ,inplace = True
    )
    print(tt)
    print(tt2)
    print(getOption['args.def.GTSFK'])
#-Notes- -End-
"""
