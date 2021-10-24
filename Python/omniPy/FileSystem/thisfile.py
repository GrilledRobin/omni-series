#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, os, inspect

def thisfile(follow_symlinks = True) -> 'Get the absolute path of the executing script':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the full path of current executing script                                                    #
#   |Quote: https://stackoverflow.com/questions/279237/import-a-module-from-a-relative-path/6098238#6098238                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The script calling this function should be saved before being executed                                                         #
#   |[2] cmd_folder = os.path.dirname(os.path.abspath(__file__)) # DO NOT USE __file__ !!!                                              #
#   |[3] __file__ fails if the script is called in different ways on Windows.                                                           #
#   |[4] __file__ fails if someone does os.chdir() before.                                                                              #
#   |[5] sys.argv[0] also fails, because it doesn't not always contains the path.                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<NA>       :   This function does not take arguments                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[<str>]    :   Full path of current executing script as character string                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210306        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, os, inspect                                                                                                               #
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
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #900. Output
    #return( os.path.realpath(inspect.getfile(inspect.currentframe())) )
    #Quote: https://stackoverflow.com/questions/3718657/how-do-you-properly-determine-the-current-script-directory/22881871#22881871
    #Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
    if getattr(sys, 'frozen', False): # py2exe, PyInstaller, cx_Freeze
        path = os.path.abspath(sys.executable)
    else:
        path = inspect.getsourcefile(lambda:0)
    if follow_symlinks:
        path = os.path.realpath(path)
    return(path)
#End thisfile

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    import sys, os
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import exec_file
    from omniPy.FileSystem import thisfile

    #100. Create a temporary script file
    L_stpflnm = r'D:\Temp\testpath.py'

    #110. Remove the original file if exists
    if os.path.isfile(L_stpflnm): os.remove(L_stpflnm)

    #130. Create the values to be written
    val_lines = [
        'import sys, os'
        ,'dir_omniPy : str = r"D:\Python\ ".strip()'
        ,'if dir_omniPy not in sys.path:'
        ,'    sys.path.append( dir_omniPy )'
        ,'#from omniPy.FileSystem import thisfile'
        ,'from inspect import getsourcefile'
        ,'print(thisfile())'
        ,'print(getsourcefile(lambda:0))'
    ]

    #150. Write the lines
    with open( L_stpflnm , 'x' ) as obj:
        #100. Write current line
        #There is no additional new empty line if we do not append a metacharacter '\n'
        obj.writelines([ v + '\n' for v in val_lines ])

    #180. Run the file and check the log
    exec_file(L_stpflnm)

    #300. Find the path of this file in RStudio interactive mode
    print(thisfile())
    print(__file__)

    #999. Remove the temporary files
    if os.path.isfile(L_stpflnm): os.remove(L_stpflnm)
#-Notes- -End-
'''