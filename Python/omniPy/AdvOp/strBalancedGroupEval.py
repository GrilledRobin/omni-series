#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from typing import Any
from omniPy.AdvOp import get_values, strNestedParser, ExpandSignature

#[ASSUMPTION]
#[1] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module

@(eSig := ExpandSignature(strNestedParser))
def strBalancedGroupEval(
    *pos
    ,**kw
) -> Any:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to evaluate the substrings surrounded by the provided boundaries, in terms of the concept of Balanced    #
#   | Group in Regular Expression (while NOT using that in RegExp as it would fail in many cases), and then replace their respective    #
#   | positions with their parsed values in current environment, i.e. treat them as variables in current session                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Signature Expansion]                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Signature of this function is expanded from <strNestedParser>, see its documents for detailed argument list                    #
#   |[2] With the Signature Expansion functionality, one can obtain the correct signature of this function at runtime in below ways     #
#   |    [1] Type <help(func)> in the console to see its full documents including the docstring brought from the ancestors              #
#   |    [2] Type <print(func.__doc__)> in the console to see its full documents including the docstring brought from the ancestors     #
#   |    [3] Type <print(inspect.signature(func).parameters)> in the console to see its full signature                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Resolve the jinja-like expression such as: <f{g{a}}>, when <a> is a variable, <g{a}> is another, and so forth                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |*pos              :   All positional arguments taken from the source function                                                      #
#   |**kw              :   All keyword arguments taken from the source function                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   The character string with possible replacement at the positions regarding Balanced Group Expressions         #
#   |                      [1] Expressions such as : <f{g{a}}>, will be evaluated in recursion                                          #
#   |                      [2] Given that any expression, such as: <{a}>, is not a known variable in current session, it will be treated#
#   |                           as plain text with the bounds removed in the output result                                              #
#   |                      [3] The whole concatenated substring between the boundaries (exclusive of them) is stripped for object lookup#
#   |                      [4] When the whole string is enclosed by the bounds and its evaluation is successful, the return value       #
#   |                           will be the same as its referenced object, which may be of any type                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <thisFunction> to actually find the current callable being called instead of its name                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231118        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to uplift the efficiency by 450 times                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251214        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now behave in the same way as the source function                                                                       #
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
#   |   |AdvOp                                                                                                                          #
#   |   |   |get_values                                                                                                                 #
#   |   |   |strNestedParser                                                                                                            #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer

    #050. Local parameters
    args_share = {'include' : False}
    eSig.vfyConflict(args_share)
    pos_in, kw_in = eSig.insParams(args_share, pos, kw)

    #060. Ensure no extra effort
    meta_ = eSig.getParam('meta_', pos_in, kw_in, inc_default = True)
    if meta_:
        print(f'[{LfuncName}]<meta_> is set as False as this function does not require extra effort.')
    pos_out, kw_out = eSig.updParams({'meta_' : False}, pos_in, kw_in)

    #100. Parse the nested structure out of the input string
    nest_struct = eSig.src(*pos_out, **kw_out)['RESULT']

    #200. Define helper functions
    #210. Function to join the nested structures into strings respectively, then evaluate the strings into new ones, with recursion
    def h_conj_str(struct : list):
        #[ASSUMPTION]
        #[1] Input structure always has the form: [<string | nested struct>]
        #[2] <nested struct> will be further processed by this function itself,
        #     with its evaluation result MUST BE able to convert to a string using <str()>
        #[3] All the evaluated items will be concatenated and then stripped, and then evaluated at current layer
        #100. Initialize
        str_struct = ''

        #500. Loop over the nested structure
        for m in struct:
            if isinstance(m, list):
                #100. Further process the structure of the next layer
                #[ASSUMPTION]
                #[1] We should never introduce <thisFunction()> to capture the frame as recursion in such a CPU-intense task
                #[2] The major CPU expense is on the dynamic compilation of such frame
                #[3] This function is never mutated (e.g. by decoration), hence there is no need to capture its frame dynamically
                #[4] Extend the string for the evaluation at current layer
                str_struct += str(h_conj_str(m))
            else:
                str_struct += m

        #999. Purge
        return(get_values(str_struct.strip(), inplace = True))

    #500. Differentiate the result
    #[ASSUMPTION]
    #[1] Given any substring that is not enclosed by the boundaries, we mark it as <S>
    #[2] According to the feature of the nested structure, if <S> exists in the outmost layer, we do separate concatenation WITHOUT
    #     further evaluation, as the outmost layer is never enclosed by boundaries
    #[3] According to the feature of the nested structure, every sub-layer <nested struct> is processed in recursion
    #[4] If <nest_struct> is empty, we export an empty string
    #[5] If <nest_struct> has only one <nested struct>, we honor its evaluated result type
    #[6] Otherwise we export a concatenated string
    len_struct = len(nest_struct)
    if len_struct == 0:
        return('')
    elif len_struct == 1:
        return(h_conj_str(nest_struct[0]))
    else:
        return(''.join([ (str(h_conj_str(i)) if isinstance(i, list) else i) for i in nest_struct ]))
#End strBalancedGroupEval

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import datetime as dt
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import strBalancedGroupEval

    #100. Prepare strings
    fill_a = 'bb'
    fill_bb = 5
    teststr = '(gg (fill_(fill_a))) aa (ee (ff))'
    testjinja = '{{ fill_{{ fill_a }} }}'

    #200. Evaluation
    eval_str = strBalancedGroupEval(
        teststr
        ,enclosers = {'(' : ')'}
        ,rx = False
    )
    print(eval_str)
    # 'gg 5 aa ee ff'

    eval_jinja = strBalancedGroupEval(
        testjinja
        ,enclosers = {'{{' : '}}'}
        ,rx = False
    )
    print(eval_jinja)
    # 5
    print(type(eval_jinja).__name__)
    # int

    #300. Special cases
    print(strBalancedGroupEval(''))
    # ''

    print(strBalancedGroupEval('()'))
    # ''

    print(strBalancedGroupEval(r'a'))
    # a

    print(strBalancedGroupEval(r'(a fill_a)'))
    # a fill_a

    print(strBalancedGroupEval(r'a (fill_a)'))
    # a bb

    print(strBalancedGroupEval(r'(fill_bb) b'))
    # 5 b

    print(strBalancedGroupEval(r'(a) fill_bb'))
    # a fill_bb

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    str_large = teststr * 10000
    time_bgn = dt.datetime.now()
    eval_large = strBalancedGroupEval(str_large)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.945214
#-Notes- -End-
'''
