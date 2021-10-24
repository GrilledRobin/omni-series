#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def exec_file( filepath, globals=None, locals=None ) -> 'Call another script within dedicated scope':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to call another script within the dedicated scope, resembling [execfile] before Python v3.0 at large     #
#   |[IMPORTANT] The called script can be a simple process instead of a function definition; hence we do not have to [import] anything  #
#   |             from inside it                                                                                                        #
#   |[Quote]     https://stackoverflow.com/questions/436198/what-is-an-alternative-to-execfile-in-python-3                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Concept (at answer #21 and updated at #75):                                                                                        #
#   |[1] Uses binary reading to avoid encoding issues                                                                                   #
#   |[2] Guaranteed to close the file (Python3.x warns about this)                                                                      #
#   |[3] Defines __main__, some scripts depend on this to check if they are loaded as a module or not for eg. if __name__ == "__main__" #
#   |[4] Setting __file__ is nicer for exception messages; some scripts use __file__ to get the paths of other files related to them    #
#   |[5] Takes optional globals & locals arguments, modifying them in-place as execfile does - so you can access any variables defined  #
#   |     by reading back the variables after running                                                                                   #
#   |[6] Unlike Python2's execfile this does not modify the current namespace by default. For that you have to explicitly pass in       #
#   |     globals() & locals()                                                                                                          #
#   |[7] As indicated at floor #21, it takes the globals and locals from the caller                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |filepath   :   The full path of the script to be called on harddisk, including the file extension                                  #
#   |               [IMPORTANT] Make sure the script is encoded as [utf-8] as always, even if it is not required here                   #
#   |globals    :   Whether to take global environment when calling the script; check document for the same argument of [exec]          #
#   |               [None     ]<Default> Directly take the same global environment as the caller program                                #
#   |locals     :   Whether to take local environment when calling the script; check document for the same argument of [exec]           #
#   |               [None     ]<Default> Directly take the same local environment as the caller program                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[None    ] :   This function does not return any value                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210214        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Handle the parameter buffer.
    if globals is None:
        globals = sys._getframe(1).f_globals
    #Some scripts depend on this to check if they are loading as a module or not for eg. if __name__ == '__main__'
    globals.update({
        '__file__': filepath,
        '__name__': '__main__',
    })
    if locals is None:
        locals = sys._getframe(1).f_locals

    #013. Define the local environment.

    #900. Execute the file with compilation upon the binary codes
    with open(filepath, 'rb') as file:
        exec(compile(file.read(), filepath, 'exec'), globals, locals)
#End exec_file

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import exec_file

    #100. Execute a script with a simple process
    test_txt = 'Hello world!'
    #Above text is to be printed by the external script
    exec_file(dir_omniPy + r'omniPy\AdvOp\_test_proc_exec_file.py')
    #Below text is from the called script; this is to test the environment transfer
    print(test_txt2)
#-Notes- -End-
"""