#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from omniPy.AdvOp import strNestedParser, ExpandSignature

#[ASSUMPTION]
#[1] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module

@(eSig := ExpandSignature(strNestedParser))
def strBalancedGroup(
    *pos
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
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use [BeautifulSoup] instead)            #
#   |[2] Resolve the jinja-like expression such as: f<g<a>>, when [a] is a variable, [g<a>] is another, and so forth                    #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |strNestedParser                                                                                                            #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #012. Parameter buffer

    #050. Local parameters
    args_share = {}
    eSig.vfyConflict(args_share)
    pos_out, kw_out = eSig.insParams(args_share, pos, kw)

    #100. Parse the nested structure out of the input string
    nest_struct = eSig.src(*pos_out, **kw_out)

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

    #500. Remove all <S> from the outmost layer of the nested structure
    #[ASSUMPTION]
    #[1] Given any substring that is not enclosed by the boundaries, we mark it as <S>
    #[2] According to the feature of the nested structure, <S> can only exist as L[0] or L[-1] in the outmost layer
    #[3] According to the feature of the nested structure, neither of the boundaries can exist in the outmost layer
    #[4] <S> in the outmost layer is not included in the output result of this function as designed
    nest_struct_cln = [ m for m in nest_struct if isinstance(m, list)]

    #900. Export
    return([ j for i in map(h_conj_str, nest_struct_cln) for j in i ])
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
    # ['bb  cc dd', 'cc dd', 'dd', 'ee  ff', 'ff']

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

    chkrst2 = strBalancedGroup(chkstr, enclosers = {r'<div.*?>' : r'</div>'}, rx = True, include = False)
    print(chkrst2)
    # ['bbb cccddd eeefff', ' ccc', 'eee', ' hhh ']

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
    # ['a b c d', 'b c d', 'b', 'd', 'f g', 'g']

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
