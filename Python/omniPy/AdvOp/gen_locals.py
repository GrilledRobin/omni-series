#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from typing import Any

def gen_locals( frame = None, scope : str = 'f_locals', **kw ) -> Any:
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
#   |frame       :   <frame> object in which to create the variables                                                                    #
#   |                [None        ] <Default> Create the variables in the caller frame                                                  #
#   |                [frame       ]           Dedicated <frame> in which to create the variables                                        #
#   |scope       :   Which scope to place the variables in the provided <frame>                                                         #
#   |                [f_locals    ] <Default> Create the variables in <f_locals> of the <frame>                                         #
#   |                [f_globals   ]           Create the variables in <f_globals> of the <frame>                                        #
#   |kw          :   Various named parameters, whose [names] will be used to create variables while [values] will be assigned to them   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[NULL]      :   This function does not return values                                                                               #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240203        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce arguments <frame> and <scope> to enable subtle control on the destination of created variables                #
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
#   |   |sys, typing                                                                                                                    #
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

    #500. Determine the frame in which to place the new variables
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
    if frame is None:
        frame = sys._getframe(1)

    #900. Append the dict of local variables by the provided arguments
    rc = frame.__getattribute__(scope).update(kw)
    #frame.f_locals.update(kw)

    return(rc)
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
    from omniPy.AdvOp import gen_locals, get_values

    #100. Execute a script with a simple process
    v_dict = { 'aa':'1' , 'bb':2 }
    gen_locals(**v_dict)
    print('aa='+str(aa))

    gen_locals(cc=3)
    print('cc='+str(cc))

    def myfunc():
        curr_frame = sys._getframe()

        def func1():
            gen_locals(dd=4, frame = curr_frame)

        func1()

        #Below would succeed
        print('locals()[dd]='+str(locals()['dd']))

        #Below would fail
        # print('dd='+str(dd))

        def func2():
            #Below would succeed
            print('dd + 1 = '+str(sys._getframe(1).f_locals['dd'] + 1))

            #Below would fail
            # print('dd+1='+str(dd+1))

            #Create variable in the <f_globals> scope of the top-most frame
            frame = sys._getframe()
            while frame.f_back:
                frame = frame.f_back
            gen_locals(frame = frame, scope = 'f_globals', **{'ee' : '6'})
        func2()

        #Test result
        frame = sys._getframe()
        while frame.f_back:
            frame = frame.f_back
        print('f_globals[ee]='+str(frame.f_globals['ee']))

    myfunc()

    #Test result: it is in lower stack than current one, hence has been recycled
    # print('locals()[dd]='+str(locals()['dd']))
    # KeyError: 'dd'

    #Find the variable created in the highest stack
    print(get_values('ee', scope = 'f_globals'))
    # 6
#-Notes- -End-
'''
