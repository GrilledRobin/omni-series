#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from collections import OrderedDict
from typing import Any

def get_values(
    *arg
    ,inplace : bool = True
    ,instance : Any = object
    ,**kw
) -> 'Get the values by regarding the provided [values] as variables':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the values of the provided [values] (by regarding them as variable names) from the closest   #
#   | call stack, which could possibly be [global], if they are defined more than once in different frames                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Map the values of variables as they are provided [character strings]                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |arg        :   Any positional arguments that represent [variable names] for search                                                 #
#   |               [IMPORTANT] Function will NOT validate whether these values can act as [variable name] by syntax                    #
#   |inplace    :   Whether to keep the output the same as the input values if any cannot be found as [variable names] from the frames  #
#   |               [True       ] <Default> Keep the input values as output if they cannot be identified as [variables]                 #
#   |               [False      ]           Output [None] for those which cannot be identified as [variables]                           #
#   |instance   :   Instance of which to identify the object, or callable if we need to find one                                        #
#   |               [<see def.> ] <Default> Search for all objects                                                                      #
#   |               [instance   ]           Anyone that can be used in function <isinstance>                                            #
#   |               [callable   ]           Search for callable, as this is actually not an instance                                    #
#   |kw         :   Various named parameters, whose [names] are used as names in output, while their [values] will be used to search as #
#   |                [variable names] within all frames along the call stacks                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>  :   This function output different values in below convention:                                                          #
#   |               [1] If [kw] is provided with at least one element, return a [dict], with:                                           #
#   |                   [names ] [str('.arg' + pos. num)] for [positional arguments] and [keys] for [kw]                                #
#   |                   [values] when NOT found:                                                                                        #
#   |                            [None          ] if [inplace==False]                                                                   #
#   |                            [input values  ] if [inplace==True]                                                                    #
#   |               [2] If there is only one positional argument provided, return the value assigned to it if any                       #
#   |               [3] In other cases (i.e. multiple positional arguments), return a [tuple] with values in the same order as provided #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210302        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210731        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Change the return value from [list] to [tuple] for case [3] in the [Return Values] to simplify the usage                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce new argument <instance> to indicate which instance or <callable> is to be retrieved in terms of the searching #
#   |      |     priority, i.e. from the closest stack to the top one                                                                   #
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
#   |   |sys, collections                                                                                                               #
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

    #012. Parameter buffer
    if inplace is None: inplace = True
    if not isinstance( inplace , bool ): inplace = True
    if (not arg) and (not kw): return()

    #050. Local parameters
    dict_found , dict_rest , list_pop = {} , {} , []
    if arg:
        arg_arglen = len(str(len(arg)))
        dict_rest.update({ '.arg'+str(i).zfill(arg_arglen) : arg[i] for i in range(len(arg)) })
    if kw: dict_rest.update(kw)

    #100. Search for the input values within all frames along the call stacks
    frame = sys._getframe()
    #Avoid errors to be raised when reaching the global environment
    #Quote: https://stackoverflow.com/questions/39265823/python-sys-getframe
    while len(dict_rest) and frame:
        #100. Update the [dict] for output and the [list] for pop-out when found
        for k,v in dict_rest.items():
            #100. Try to get the value for the input [value] by regarding it as [variable name] in current frame
            val = frame.f_locals.get(v)

            #300. Verify its instance
            if instance is callable:
                if not callable(val): continue
            else:
                if not isinstance(val, instance): continue

            #500. Update related dictionaries if anything is identified
            if val is not None:
                dict_found.update({k:val})
                list_pop.append(k)

        #500. Reduce the pool for further search if anythin is not identified
        if list_pop:
            #100. Pop the items as they are identified in current frame
            for k in list_pop:
                dict_rest.pop(k)

            #900. Clear the interim list for next iteration
            list_pop = []

        #900. Trace back one stack along the call stacks
        frame = frame.f_back

    #500. Search for [global] environment if anything is not identified in the enclosed call stacks
    if dict_rest:
        #100. Update the [dict] for output and the [list] for pop-out when found
        for k,v in dict_rest.items():
            #100. Try to get the value for the input [value] by regarding it as [variable name] in current frame
            val = globals().get(v)

            #300. Verify its instance
            if instance is callable:
                if not callable(val): continue
            else:
                if not isinstance(val, instance): continue

            #500. Update related dictionaries if anything is identified
            if val is not None:
                dict_found.update({k:val})
                list_pop.append(k)

        #500. Reduce the pool for further search if anythin is not identified
        if list_pop:
            #100. Pop the items as they are identified in current frame
            for k in list_pop:
                dict_rest.pop(k)

            #900. Clear the interim list for next iteration
            list_pop = []

    #800. Determine the output
    #850. Update the output values if there are still anything not identified
    if dict_rest:
        dict_found.update({ k : v if inplace else None for k,v in dict_rest.items() })

    #900. Output
    if kw:
        return(dict_found)
    elif len(arg)==1:
        return(list(dict_found.values())[0])
    else:
        return(tuple(OrderedDict(sorted(dict_found.items())).values()))
#End get_values

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import get_values

    #100. Execute a script with a simple process
    aa = 1
    bb = 3
    v_dict = { 'testvar1':'aa' , 'testvar2':'ee' }
    v_list = ['ff','bb']

    v_rst = {}
    def testf():
        global v_rst
        #Make the value of the local variable different to that of the global one
        aa = 2
        v_rst = get_values( *v_list , **v_dict )

    testf()
    print(v_rst)

    #200. Test output with [inplace==False]
    v_rst2 = {}
    def testf2():
        global v_rst2
        #Make the value of the local variable different to that of the global one
        aa = 2
        v_rst2 = get_values( *v_list , inplace = False , **v_dict )

    testf2()
    print(v_rst2)

    #300. Test output with only one input value
    print( get_values('aa') )

    #400. Test output with only positional arguments
    print( get_values(*v_list) )

    #700. Test real case
    fTrans = {
        '&L_curdate.' : 'G_d_curr'
        ,'&L_curMon.' : 'G_m_curr'
        ,'&L_prevMon.' : 'G_m_prev'
        ,'&c_date\\.' : 'G_d_curr'
    }
    G_d_curr = '20160310'
    G_m_curr = G_d_curr[:6]

    get_list_val = get_values(**fTrans)
    print(get_list_val)

    #800. Test when the variable names are stored in a [collections.abc.Iterable]
    v_df = pd.DataFrame({ 'vars':['aa' , 'ee'] })
    testseries = get_values(*v_df['vars'])
    testseries2 = v_df['vars'].apply(get_values)

    #900. Test to search for specific instance when the same name exists in different stacks
    def outerf():
        print('from outer function')
    def innerf():
        outerf = 'aa'
        bb = get_values('outerf', instance = callable)
        bb()
    innerf()
    # from outer function

    def innerf2():
        outerf = 'aa'
        bb = get_values('outerf')
        print(bb)
    innerf2()
    # aa
#-Notes- -End-
'''
