#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys
import pandas as pd
from typing import Union

def parseHDFStoreInfo(
    infile : Union[str, os.PathLike, pd.HDFStore]
) -> pd.DataFrame:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the text information produced by <pd.HDFStore.info> into re-usable data frame                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote:                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/50569465/determine-format-of-a-dataframe-in-pandas-hdf-file                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Verify whether the stored data is in the format of <fixed> or <table>, since they support different operations                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |infile      :   The name (as character string) of the file to be parsed                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[DataFrame] :   Data Frame indicating the process result with below columns:                                                       #
#   |               |------------------------------------------------------------------------------------------------------------------ #
#   |               |Column Name     |Nullable?  |Description                                                                           #
#   |               |----------------+-----------+--------------------------------------------------------------------------------------#
#   |               |key             |No         | The <key> stored in the file, without the leading slash </>                          #
#   |               |type            |No         | Internal type of the stored object                                                   #
#   |               |info            |No         | Detailed information about the stored object                                         #
#   |               |format          |No         | <fixed> or <table> as verified                                                       #
#   |               |----------------+-----------+--------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240117        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |os, sys, pandas                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #100. Retrieve the information of the file
    with pd.HDFStore(infile, mode = 'r') as store:
        info = store.info().splitlines()[2:]
        keys = store.keys()

    #500. Parse the text
    rstOut = (
        pd.DataFrame.from_dict(
            {
                i : ([v[0][1:]] + v[1][len(v[0]):].strip().split())
                for i,v in enumerate(zip(keys, info))
            }
            ,orient = 'index'
            ,columns = ['key','type','info']
        )
        .assign(**{
            'format' : lambda x: (
                (x['type'].str.endswith('_table') & x['info'].str.contains('typ->appendable'))
                .map({ True : 'table', False : 'fixed' })
            )
        })
    )

    #900. Output
    return(rstOut)
#End parseHDFStoreInfo

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import parseHDFStoreInfo

    #100. Prepare data to be exported
    file_tmp = r'D:\Temp\aaa.hdf'
    aaa = pd.DataFrame({'我 是' : [2,4,6], 'b' : [1,5,9]})
    bbb = pd.DataFrame({'c' : ['1','3']})

    #100. Export data in different formats
    with pd.HDFStore(file_tmp, mode = 'w') as store:
        store.put('aaa', aaa, format = 'fixed')
        store.put('bbb', bbb, format = 'table')

    #200. Retrieve the file information
    rst = parseHDFStoreInfo(file_tmp)

    #900. Purge
    if os.path.isfile(file_tmp): os.remove(file_tmp)
#-Notes- -End-
'''
