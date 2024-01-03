#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os
from itertools import product

#Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
from inspect import getsourcefile
getCalendarAdj_file : str = getsourcefile(lambda:0)

def getCalendarAdj(
    fname : str =  r'CalendarAdj.csv'
    ,lst_drives : list[str] = [ d + os.sep for d in ['D:', 'C:'] ]
    ,lst_parent : list[str] = ['Python', 'Robin', 'RobinLu', 'SAS']
    ,lst_fpath : list[str] = ['omnimacro', 'omniPy']
    ,lst_fcurr : list[str] = ['Dates']
) -> str:
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to locate the Calendar Adjustment file for Calendar related functions                                    #
#   |[IMPORTANT] If the dedicated file is in the same path as this function, its absolute path is directly returned, regardless of      #
#   |             whether the same file is in any of the candidate folders                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fname       :   Name of the calendar adjustment file; it should be CSV file, although it is not validated                          #
#   |lst_drives  :   Candidate drives to search for the file; sequence of strings listed determines the search order                    #
#   |                [ <see def.> ] <Default> The first drive with the existing file will be honored                                    #
#   |lst_parent  :   Candidate root directories in the drives to search for the file; sequence in which determines the search order     #
#   |                [ <see def.> ] <Default> The first root with the existing file will be honored                                     #
#   |lst_fpath   :   Candidate parent directories in the roots to search for the file; sequence in which determines the search order    #
#   |                [ <see def.> ] <Default> The first directory with the existing file will be honored                                #
#   |lst_fcurr   :   Candidate directories in the parents to search for the file; sequence in which determines the search order         #
#   |                [ <see def.> ] <Default> The first directory with the existing file will be honored                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ str   ]   :   Absolute path of the file on the harddisk                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210821        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240103        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Added arguments to generalize the function                                                                              #
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
#   |   |sys, os, itertools                                                                                                             #
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

    #012. Handle the parameter buffer.
    file_prior = getCalendarAdj_file

    #300. Directly return if the dedicated file is in the same folder as this function
    if file_prior:
        rst_prior = os.path.join(os.path.dirname(file_prior), fname)
        if os.path.isfile(rst_prior):
            return(rst_prior)

    #500. Get the full combinations of the candidate paths
    #[IMPORTANT] The sequence of the input lists determines below logics:
    #[1] Search order for the dedicated file
    #[2] Program efficiency on system I/O
    lst_cand = list(product(lst_drives, lst_parent, lst_fpath, lst_fcurr))

    #700. Identify the first one among the candidates that is a physical file
    fpath = [ os.path.join(*d, fname) for d in lst_cand ]
    fRst = [ f for f in fpath if os.path.isfile(f) ]
    if not fRst:
        raise ValueError('[' + LfuncName + ']File is not found in any among the candidate paths! Please update function definition!')

    #900. Translate the values
    return(fRst[0])
#End getCalendarAdj

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import getCalendarAdj
    print(getCalendarAdj.__doc__)

    #100. Print the identified path to the calendar adjustment file
    print(getCalendarAdj())
#-Notes- -End-
'''
