#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from wcwidth import wcswidth

def alignWidth(
    *objects
    ,fill : str = ' '
    ,align : str = '<'
    ,width : int = None
) -> str | tuple[str]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to align the width of the input objects during printing                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] String representation created by this function can be properly displayed in the Command Console                                #
#   |[2] Most fonts, including monospace fonts such as <Courier New>, cannot display the MBCS characters in such aligned width, as they #
#   |     do not set the width of a 2-byte character exactly the same as the width of 2 consecutive 1-byte characters                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Align the width of MBCS characters: https://blog.csdn.net/weixin_45715159/article/details/106176454                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |objects     :   Objects that have <__str__> or <__repr__> methods for character representation                                     #
#   |fill        :   How to fill the whitespaces if the desired width is larger than the input width of <*objects>                      #
#   |                [single space    ] <Default> Use a single space to fill the string representation                                  #
#   |                [<str>           ]           Any string to fill the extra blanks                                                   #
#   |align       :   How to align the input string, see official: https://docs.python.org/3/library/string.html#formatspec              #
#   |                [<               ] <Default> Align the strings on the left side of the output                                      #
#   |                [<see doc>       ]           See above official document for <f-string>                                            #
#   |width       :   Width of the output string representation                                                                          #
#   |                [None            ] <Default> Output the same width as the longest displayed string in <*objects>                   #
#   |                [<int>           ]           Output the required width, which will never truncate the input                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |tuple[str]  :   Differentiate when <*objects> is provided on different purposes                                                    #
#   |                [1] <None> when len<objects> == 0                                                                                  #
#   |                [2] <str> when len<objects> == 1                                                                                   #
#   |                [3] <tuple[str]> when len<output> == len<objects>, this is the most common usage                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241225        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, wcwidth                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if len(objects) == 0:
        return(None)
    if not width:
        width = max([ wcswidth(k) for k in objects ])

    #050. Local parameters

    #100. Helper functions
    #110. Function to pad a single string
    def h_align(txt):
        chr_count = wcswidth(txt) - len(txt)
        chr_width = max(0, width - chr_count)
        return(f'{txt:{fill}{align}{chr_width}}')

    #500. Pad the strings
    rstOut = tuple( h_align(t) for t in objects )

    #900. Differentiate the output
    if len(objects) == 1:
        return(rstOut[0])
    else:
        return(rstOut)
#End alignWidth

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.AdvOp import alignWidth
    print(alignWidth.__doc__)

    #100. Set the input
    txts = {
        'CN Mixed' : '《深度学习 deep learning》'
        ,'en' : '<c++ primer plus>'
        ,'JP Mixed' : '日文 名探偵コナン'
    }

    #200. Align the output
    rst = alignWidth(*txts.values(), fill = '*')
    #[ASSUMPTION]
    #[1] Below texts are displyed in the same width in Command Console, for it displays 2-byte characters exactly the same as 2 1-byte
    #     character
    print('\n'.join(rst))
    # 《深度学习 deep learning》
    # <c++ primer plus>*********
    # 日文 名探偵コナン*********

    #300. Set the unified width
    rst2 = alignWidth(*txts.values(), fill = '*', width = 8)
    print('\n'.join(rst2))
    # 《深度学习 deep learning》
    # <c++ primer plus>
    # 日文 名探偵コナン
#-Notes- -End-
'''
