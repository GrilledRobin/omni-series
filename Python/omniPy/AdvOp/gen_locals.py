#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def gen_locals( **kw ) -> 'Assign values to variables in the same frame as the caller program':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create or assign values to multiple variables at the same time within current frame/environment       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Test the internal scripts for a function with many arguments by assigning values to them respectively to act like variables    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |kw         :   Various named parameters, whose [names] will be used to create variables while [values] will be assigned to them    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[NULL]     :   This function does not return values                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210301        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210319        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the dependency of the module [inspect] as its result is not the expected one                                     #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #900. Append the dict of local variables by the provided arguments
    #[1] How to find the lower layer among the [call stacks] is demonstrated below:
    #    https://stackoverflow.com/questions/39265823/python-sys-getframe
    #[2] [f_locals] comes from the answer (#3) in below article:
    #    https://stackoverflow.com/questions/55698126/access-the-locals-available-in-the-previous-stack-frame
    #[3] [update] method for [locals()] is demonstrated below (#72):
    #    https://stackoverflow.com/questions/1373164/how-do-i-create-variable-variables
    #[4] Default behavior when calling this function results the variables to be defined among [globals()], see:
    #    https://stackoverflow.com/questions/8178633/can-you-assign-to-a-variable-defined-in-a-parent-function
    #[5] Prior to Python<=3.13 as indicated by PEP667, this function will not work as it is designed to:
    #    https://peps.python.org/pep-0667/
    sys._getframe(1).f_locals.update(kw)
    #frame.f_locals.update(kw)
#End gen_locals

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import gen_locals

    #100. Execute a script with a simple process
    v_dict = { 'aa':'1' , 'bb':2 }
    gen_locals(**v_dict)
    print('aa='+str(aa))

    gen_locals(cc=3)
    print('cc='+str(cc))

    def myfunc():
        def func1():
            gen_locals(dd=4)

        func1()

        #Below would fail
        #print('locals()[dd]='+str(locals()['dd']))

        #Below would succeed
        print('dd='+str(dd))

        def func2():
            #Below would fail
            #print('dd='+str(sys._getframe(1).f_locals['dd']))

            #Below would succeed
            print('dd+1='+str(dd+1))
        func2()

    myfunc()

    #Test result: it eventually becomes one among [globals()]
    print('dd='+str(dd))
#-Notes- -End-
'''