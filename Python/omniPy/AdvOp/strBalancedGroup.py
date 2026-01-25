#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
from omniPy.AdvOp import strNestedParser, ExpandSignature

#[ASSUMPTION]
#[1] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module

@(eSig := ExpandSignature(strNestedParser))
def strBalancedGroup(
    *pos
    ,precise : bool = False
    ,**kw
) -> list[str]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the substrings surrounded by the provided boundaries, in terms of the concept of Balanced     #
#   | Group in Regular Expression (while NOT using that in RegExp as it would fail in many cases)                                       #
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
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use <BeautifulSoup> instead)            #
#   |[2] Resolve the jinja-like expression such as: <f{g{a}}>, when <a> is a variable, <g{a}> is another, and so forth                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The argument <include=False> for this function has different meaning to its source function, as it only excludes the enclosers #
#   |     at the top level of each Balanced Group, for it has to resemble a direct <substring>                                          #
#   |[2] There is no convenient way to only exclude the top level enclosers in a recursive calculation                                  #
#   |[3] For above reasons, the function falls back to the extraction using META information table <nodes>, when <include=False>, which #
#   |     drastically slows down the process as it introduces many extra stack operations                                               #
#   |[4] For other cases, it uses recursive string concatenation out of the nested structure as parsed internally, which is fast        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Should there be any <opener> in the input vector that matches no <closer>, and yet is marked as <unmatched> as it is enclosed  #
#   |     inside another complete <node>, this function recognizes it as a <Balanced Group> when <precise=FALSE>. If you need to avoid  #
#   |     such situation, set <precise=TRUE> to ensure fallback to META extraction but suffer great addition of time consumption.       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |*pos              :   All positional arguments taken from the source function                                                      #
#   |precise           :   <bool> Whether to force the function to fall back to extraction from META table <nodes>. This will result    #
#   |                       in great addition of time consumption but can recognize <unmatched> groups, so choose it wisely.            #
#   |                      [False               ] <Default> Fast solution with no recognition of <unmatched> groups                     #
#   |                      [True                ]           Recognize <unmatched> groups at cost of great addition of time consumption, #
#   |                                                        but is safe for most of cases. Use this if your data is not clean.         #
#   |**kw              :   All keyword arguments taken from the source function                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>            :   List of substrings out of each pair of boundaries as a Balanced Group. Exceptions are raised in the same way #
#   |                       as the dependent function                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231118        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to uplift the efficiency by 450 times                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251211        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now exports the content in the same way as RegExp would, i.e. the output sequence of captured content as enclosed will  #
#   |      |     be in the same sequence as when the Opening Token, a.k.a Left Bound, is encountered                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251214        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now behave in the same way as the source function                                                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20260120        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now only exclude the top level enclosers when <include=False>, leveraging the META table <nodes> internally             #
#   |      |[2] For above case, the process slows down a lot due to extra stack processes, but until now there is no convenient solution#
#   |      |[3] Introduce argument <precise> to determine whether to fall back to META extraction to recognize <unmatched> groups at    #
#   |      |     most cases. One is encouraged to set it as <True> if the input data is not clean with expected pairs of enclosers      #
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
#   |   |sys, pandas                                                                                                                    #
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
    if not isinstance(precise, bool):
        raise TypeError(f'[{LfuncName}]<precise>:<{type(precise)}> must be provided a bool!')

    #050. Local parameters
    args_share = {}
    eSig.vfyConflict(args_share)
    pos_in, kw_in = eSig.insParams(args_share, pos, kw)
    include = eSig.getParam('include', pos_in, kw_in, inc_default = True)

    #060. Ensure no extra effort
    meta_ = eSig.getParam('meta_', pos_in, kw_in, inc_default = True)
    if meta_:
        print(f'[{LfuncName}]<meta_> is useless as this function does not require extra effort.')

    #200. Define helper functions
    #210. Function to join the nested structures into strings respectively with recursion
    def h_conj_str(struct : list):
        #[ASSUMPTION]
        #[1] Input structure always has the form: [<lBound,> <string | nested struct>, <rBound>], where
        #    [a] <lBound> and <rBound> exist or miss at the same time
        #    [b] When both boundaries are missing given <include is True>, the middle part must be a <nested struct>
        #[2] Hence there is no need to match the boundaries any more, we just need to join all strings directly.
        #100. Initialize
        rstOut = []
        str_struct = ''

        #500. Loop over the nested structure
        for m in struct:
            if isinstance(m, list):
                #100. Further process the structure of the next layer
                #[ASSUMPTION]
                #[1] We should never introduce <thisFunction()> to capture the frame as recursion in such a CPU-intense task
                #[2] The major CPU expense is on the dynamic compilation of such frame
                #[3] This function is never mutated (e.g. by decoration), hence there is no need to capture its frame dynamically
                next_struct = h_conj_str(m)

                #500. Extend the final result
                rstOut.extend(next_struct)

                #900. Extend the string for the structure of current layer
                str_struct += next_struct[0]
            else:
                str_struct += m

        #800. Append the string of current structure to the final result
        rstOut.insert(0, str_struct)

        #999. Purge
        return(rstOut)

    #230. Function to determine the approach to extract the substring
    def h_ext(row : pd.Series, txt_ : str, include_ : bool):
        if include_:
            return(txt_[row['span_start']:row['span_end']])
        else:
            return(txt_[row['inner_start']:row['inner_end']])

    #400. Fall back to the extraction via META information table
    #[ASSUMPTION]
    #[1] There is no convenient way of recursion to only exclude the enclosers at the top level
    if (not include) or precise:
        #100. Parse the text with META extracted as well
        #[ASSUMPTION]
        #[1] We do not remove the enclosers in the first place, otherwise it is difficult to add them back when required
        #[2] For any nested structures, we only need to remove the enclosers of the top one given <include=F>, which matches
        #     the direct substring extraction from the text
        txt = eSig.getParam('txt', pos_in, kw_in, inc_default = True)
        args_upd = {
            'include' : True
            ,'meta_' : True
        }
        pos_out, kw_out = eSig.updParams(args_upd, pos_in, kw_in)
        nest_struct = eSig.src(*pos_out, **kw_out)

        #900. Collect the meta information for all complete <nodes>
        return(
            nest_struct['META']['nodes']
            .apply(h_ext, txt_ = txt, include_ = include, axis = 1)
            .to_list()
        )

    #600. Parse the nested structure out of the input string
    #[ASSUMPTION]
    #[1] Given any substring that is not enclosed by the boundaries, we mark it as <S>
    #[2] According to the feature of the nested structure, <S> can only exist as L[0] or L[-1] in the top layer
    #[3] According to the feature of the nested structure, neither of the boundaries can exist in the top layer
    #[4] <S> in the top layer is not included in the output result of this function as designed
    args_upd = {
        'meta_' : False
    }
    pos_out, kw_out = eSig.updParams(args_upd, pos_in, kw_in)
    nest_struct = [ m for m in eSig.src(*pos_out, **kw_out)['RESULT'] if isinstance(m, list)]

    #900. Export
    return([ j for i in map(h_conj_str, nest_struct) for j in i ])
#End strBalancedGroup

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
    from omniPy.AdvOp import strBalancedGroup

    #100. Prepare strings
    teststr = '-- (bb (cc (dd))) aa (ee (ff)) ~~'
    testjinja = '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg'

    #200. Extraction
    bg_parens = strBalancedGroup(
        teststr
        ,enclosers = {'(' : ')'}
        ,rx = False
        ,include = True
    )
    print(bg_parens)
    # ['(bb (cc (dd)))', '(cc (dd))', '(dd)', '(ee (ff))', '(ff)']

    #[ASSUMPTION]
    #[1] This is weigh much slower than <include=True> as it falls back to the extraction using META information, which
    #     consumes lots of calculation effort of extra stacks
    bg_jinja = [
        m.strip()
        for m in strBalancedGroup(
            testjinja
            ,enclosers = {'{{' : '}}'}
            ,rx = False
            ,include = False
        )
    ]
    print(bg_jinja)
    # ['bb {{ cc{{ dd }} }}', 'cc{{ dd }}', 'dd', 'ee {{ ff }}', 'ff']

    bg_html = [
        m.strip()
        for m in strBalancedGroup(
            testhtml
            ,enclosers = {r'<div.*?>' : r'</div>'}
            ,rx = True
            ,include = True
        )
    ]
    print(bg_html)
    # ['<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div>', '<div id="2"> ccc</div>', '<div id="3">eee</div>']

    #300. Special cases
    chkstr = '-- <div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg <div id="4"> hhh </div> ~~'
    chkrst = strBalancedGroup(chkstr, enclosers = {r'<div.*?>' : r'</div>'}, rx = True)
    print(chkrst)
    # ['<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div>',
    #  '<div id="2"> ccc</div>',
    #  '<div id="3">eee</div>',
    #  '<div id="4"> hhh </div>']

    #[ASSUMPTION]
    #[1] In case of the extraction from HTML, we need all tags inside the top level enclosers to remain intact
    chkrst2 = strBalancedGroup(chkstr, enclosers = {r'<div.*?>' : r'</div>'}, rx = True, include = False)
    print(chkrst2)
    # ['bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff', ' ccc', 'eee', ' hhh ']

    print(strBalancedGroup(''))
    # []

    print(strBalancedGroup(r'a'))
    # []

    print(strBalancedGroup(r'(a b)'))
    # ['(a b)']

    print(strBalancedGroup(r'a (b)'))
    # ['(b)']

    print(strBalancedGroup(r'(a) b'))
    # ['(a)']

    print(strBalancedGroup(r'(a ((b) c (d))) e (f (g))'))
    # ['(a ((b) c (d)))', '((b) c (d))', '(b)', '(d)', '(f (g))', '(g)']

    print(strBalancedGroup(r'(a ((b) c (d))) e (f (g))', include = False))
    # ['a ((b) c (d))', '(b) c (d)', 'b', 'd', 'f (g)', 'g']

    #350. Unmatched groups
    #[ASSUMPTION]
    #[1] In the cases like `hijacked` below, any <opener> that is marked <unmatched> cannot trigger as an error in terms of
    #     the design of the source function <strNestedParser>
    hijacked = r'a (b { c) [ (d} e) f ] g'
    print(strBalancedGroup(
        hijacked
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # ['(b { c)', '{ c', '[ (d} e) f ]', '(d} e)']

    #355. Set <precise=True> to recognize and eliminate <unmatched> groups
    #[ASSUMPTION]
    #[1] As you can see, the <unmatched> groups in `hijacked` are now eliminated
    #[2] The same elimination is also led by <include=False>, which makes the logic consistent. Note that in such case the
    #     argument <precise> is omitted as the function already falls back to META extraction.
    print(strBalancedGroup(
        hijacked
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,precise = True
    ))
    # ['(b { c)', '[ (d} e) f ]', '(d} e)']

    #356. Set <include=False>
    print(strBalancedGroup(
        hijacked
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,include = False
    ))
    # ['b { c', ' (d} e) f ', 'd} e']

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    bg_large = strBalancedGroup(str_large, enclosers = {r'<div.*?>' : r'</div>'}, rx = True)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.123028
#-Notes- -End-
'''
