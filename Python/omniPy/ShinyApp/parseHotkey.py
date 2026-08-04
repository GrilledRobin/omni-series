#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from warnings import warn
from omniPy.AdvOp import strNestedParser

def parseHotkey(
    label : str
    ,enclosers : dict[str, str] = {'(' : ')'}
) -> tuple[str | None, str | None]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the display label of a (preferrably an actionable) web element, e.g. button, and split it into  #
#   | two parts - the clean label without the keyboard shortcut, and the shortcut as a character string as well, or None if there is no #
#   | shortcut indicated in the label                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The input <label> should be comprised of one or two parts, e.g. `Open` or `Open (ctrl+O)`                                      #
#   |[2] Should there be a latter part, it is parsed in this function to standardize its format                                         #
#   |    [1] Lower the character case                                                                                                   #
#   |    [2] Eliminate the white spaces                                                                                                 #
#   |[3] The parsed shortcut can be a valid string passed to <ShinyApp.jsHotkeyManager> for element manipulation                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |label             :   <str> Character string as the label of a web element, that may contain keyboard shortcut as indication       #
#   |enclosers         :   <dict    > Mapping of enclosers with <key> as the left bound or opener, <value> as the right bound or closer #
#   |                      [(see def.)          ] <Default> Use the default values as defined                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<tuple>           :   2-tuple indicating the label without shortcut, and the parsed shortcut itself                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260622        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |sys, warnings                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |strNestedParser                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #050. Local parameters
    if not isinstance(label, str):
        return(None, None)

    #100. Define helper functions
    #110. Function to join the nested structures into strings respectively with recursion
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

    #300. 匹配括号内的快捷键定义：{单字母} 或 (修饰键组合)
    if not any((k in label) and (v in label) for k,v in enclosers.items()):
        return(label, None)

    #320. Extract the nested structures
    label_nest = strNestedParser(label, enclosers = enclosers)

    #360. The content enclosed by paired enclosers should exist as the last characters
    shortcut_chr = label_nest['RESULT'][-1]
    if isinstance(shortcut_chr, str):
        warn(f'[{LfuncName}]Shortcut should be the last characters in <{label}>!')
        return(label, None)

    #380. Eliminate the enclosers
    shortcut_removal = h_conj_str(shortcut_chr)[0]
    shortcut_text = shortcut_removal[1:-1]

    #400. 去除快捷键部分，保留纯显示文本
    display = label.replace(shortcut_removal, '').strip()

    #999. Fall back to the same output shape
    return(display, shortcut_text.lower().replace(' ', ''))
#End parseHotkey

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp import parseHotkey
    print(parseHotkey.__doc__)

    #100. Label without shortcut
    print(parseHotkey('Open'))
    # ('Open', None)

    #200. Label with shortcut
    print(parseHotkey('Open (Alt+O)'))
    # ('Open', 'alt+o')

    #300. Label with shortcut enclosed by other enclosers
    print(parseHotkey('Open （Alt+O）', enclosers = {'（' : '）'}))
    # ('Open', 'alt+o')

    #400. Complex label within which only the content inside the last pair of enclosers is taken as the shortcut
    print(parseHotkey('Open (without change) [ctrl+O]', enclosers = {'(' : ')', '[' : ']'}))
    # ('Open (without change)', 'ctrl+o')

    #800. Invalid cases
    print(parseHotkey('(Alt+O) Open'))
    # ('(Alt+O) Open', None)
    # UserWarning: [parseHotkey]Shortcut should be the last characters in <(Alt+O) Open>!
    #   warn(f'[{LfuncName}]Shortcut should be the last characters in <{label}>!')
#-Notes- -End-
'''
