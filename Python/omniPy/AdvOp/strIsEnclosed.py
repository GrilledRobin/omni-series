#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from omniPy.AdvOp import strNestedParser, ExpandSignature

#[ASSUMPTION]
#[1] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module

@(eSig := ExpandSignature(strNestedParser))
def strIsEnclosed(
    *pos
    ,**kw
) -> bool:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to verify whether the provided <txt> is surrounded by the dedicated pair of enclosers, meanwhile it      #
#   | strictly detects whether the left bound corresponds to its right bound by searching in all nested structure                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Signature Expansion]                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Signature of this function is expanded from <strNestedParser>, see its documents for detailed argument list                    #
#   |[2] With the Signature Expansion functionality, one can obtain the correct signature of this function at runtime in below ways     #
#   |    [1] Type <help(func)> in the console to see its full documents including the docstring brought from the ancestors              #
#   |    [2] Type <print(func.__doc__)> in the console to see its full documents including the docstring brought from the ancestors     #
#   |    [3] Type <print(inspect.signature(func).parameters)> in the console to see its full signature                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/1099178/matching-nested-structures-with-regular-expressions-in-python                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Fast verification of enclosed string and falls back to <strNestedParser> for complex scenarios                                 #
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
#   |<bool>            :   True if <txt> is surrounded by any pair among the <enclosers>, False if otherwise                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20251215        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |AdvOp                                                                                                                          #
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
    args_share = {}
    eSig.vfyConflict(args_share)
    pos_in, kw_in = eSig.insParams(args_share, pos, kw)

    #060. Ensure no extra effort
    meta_ = eSig.getParam('meta_', pos_in, kw_in, inc_default = True)
    if meta_:
        print(f'[{LfuncName}]<meta_> is set as False as this function does not require extra effort.')
    pos_out, kw_out = eSig.updParams({'meta_' : False}, pos_in, kw_in)

    #300. Quick result if the input does not start with the dedicated opener, or does not end with its corresponding closer
    if not eSig.getParam('rx', pos_out, kw_out, inc_default = True):
        quick_rst = False
        closer = None
        for k,v in eSig.getParam('enclosers', pos_out, kw_out, inc_default = True).items():
            if eSig.getParam('txt', pos_out, kw_out, inc_default = True).startswith(k):
                quick_rst = True
                closer = v
        if not quick_rst:
            return(False)
        if not eSig.getParam('txt', pos_out, kw_out, inc_default = True).endswith(closer):
            return(False)

    #500. Fall back to the string split process
    try:
        #100. Parse the nested structure out of the input string
        nest_struct = eSig.src(*pos_out, **kw_out)['RESULT']

        #500. Determine if the structure only contains one substructure
        if (len(nest_struct) != 1):
            return(False)

        #900. Determine if the only one substructure is a list
        return(isinstance(nest_struct[0], list))
    except:
        return(False)
#End strIsEnclosed

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
    from omniPy.AdvOp import strIsEnclosed

    #090. Simple tests
    def test_correctness():
        test_cases = [
            # (input, expected result)
            ('[1] [abc]', False)
            ,('(hello)', True)
            ,('[(hello)]', True)
            ,('{[hello]}', True)
            ,('(hello', False)
            ,('hello)', False)
            ,('([hello)]', False)
            ,('((hello))', True)
            ,('a(b)c', False)
            ,('', False)
            ,('()', True)
            ,('[]', True)
            ,('{}', True)
            ,('[test]', True)
            ,('{test}', True)
            ,('(test)', True)
            ,('[a(b)c]', True)
            ,('[(test])', False)
        ]

        for func in [strIsEnclosed]:
            print(f'\ntest function: {func.__name__}')
            all_passed = True

            for test_str, expected in test_cases:
                result = func(test_str, enclosers = {'(' : ')', '{' : '}', '[' : ']'})
                if result != expected:
                    print(f'  Fail: `{test_str}` - expected {expected}, got {result}')
                    all_passed = False

            if all_passed:
                print('  All tests passed!')

    test_correctness()

    #100. Prepare strings
    teststr = '(bb (cc (dd))) aa (ee (ff))'
    testjinja = '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div>'

    #200. Verification
    # Various nested structures, but there are 2 top-level substructures
    print(strIsEnclosed(
        teststr
        ,enclosers = {'(' : ')'}
        ,rx = False
    ))
    # False

    # The beginning is not the left bound
    print(strIsEnclosed(
        testjinja
        ,enclosers = {'(' : ')'}
        ,rx = False
    ))
    # False

    # Worst case for Time Complexity and Auxiliary Space
    print(strIsEnclosed(
        testhtml
        ,enclosers = {r'<div.*?>' : r'</div>'}
        ,rx = True
    ))
    # True

    #300. Special cases
    #330. Multiple enclosers
    txt = '(bb [cc (dd)]) aa {ee (ff)}'

    # Different opener and closer
    print(strIsEnclosed(
        txt
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # False

    #340. Unmatched enclosers
    txt2 = '[(b { c) [ (d} e) f ]'

    # The first opening '[' does not have its pairing closer
    print(strIsEnclosed(
        txt2
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # False

    txt3 = '(b { c)'

    #[ASSUMPTION]
    #[1] The opening '{' is treated as a normal text
    #[2] To validate such result, below conditions should all be satisified
    #    [1] There should be multiple enclosers as requested
    #    [2] There can only be isolated openers in the nested structures (see below test, isolated closers causes failure)
    #[3] This has the same concept as <strNestedParser>, strictly scanning the text from left to right only once. The opener is
    #     always stored into the stack hence its isolation is not verified when it is surrounded by another type of enclosers,
    #     as its stacking status is erased when that pair of enclosers complete their stack.
    print(strIsEnclosed(
        txt3
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # True

    #[ASSUMPTION]
    #[1] The closing '}' is treated as a normal text when <strict_=False>, as it is sourrounded by another type of enclosers
    #[2] The same falls to False when <strict_=True>
    print(strIsEnclosed(
        '(b } c)'
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = False
    ))
    # True

    print(strIsEnclosed(
        '(b } c)'
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = True
    ))
    # False

    txt4 = '[b] c ]'

    # Isolated closers
    print(strIsEnclosed(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
    ))
    # False

    #360. Crossing enclosers
    cross1 = '[{aaa]}'

    # Different opener and closer
    print(strIsEnclosed(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # False

    # [CPU] Intel Core i9-14900K 8-Core 5.00GHz
    # [RAM] 128GB DDR5 4800MHz
    #900. Test timing
    #910. Large string for RegExp
    #[ASSUMPTION]
    #[1] The worst scenario when the entire string is scanned
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    print(strIsEnclosed(
        str_large
        ,enclosers = {r'<div.*?>' : r'</div>'}
        ,rx = True
    ))
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # False
    # 0:00:00.062000

    time_bgn = dt.datetime.now()
    print(strIsEnclosed(
        f'<div class = 1>{str_large}</div>'
        ,enclosers = {r'<div.*?>' : r'</div>'}
        ,rx = True
    ))
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # True
    # 0:00:00.062001

    #930. Large string for plain enclosers
    #[ASSUMPTION]
    #[1] When the enclosers are plain texts, the function falls back to (x in patterns) which reduces Time Complexity
    str_large2 = teststr * 10000
    time_bgn = dt.datetime.now()
    print(strIsEnclosed(
        str_large2
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # False
    # 0:00:00.043052

    str_large3 = f'[{txt * 10000}]'
    time_bgn = dt.datetime.now()
    print(strIsEnclosed(
        str_large3
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # True
    # 0:00:00.043994
#-Notes- -End-
'''

'''
#-Terminology- -Begin-
The same as <strNestedParser>, see its document for details
- **Time Complexity**：在一般记号下，最坏情况大致为 O(n * m)。若 m 与 n 同量级（如 m = Θ(n)），则最坏情况下是 O(n^2)。
- **Auxiliary Space**：O(n + m)。
'''
