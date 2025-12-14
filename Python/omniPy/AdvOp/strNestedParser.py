#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re

def strNestedParser(
    txt : str
    ,enclosers : dict[str, str] = {'(' : ')'}
    ,rx : bool = False
    ,include : bool = True
    ,strict_ : bool = False
    ,flags : re.RegexFlag = re.NOFLAG
) -> list[str | list[str | list[...]]]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the nested structures surrounded by the provided boundaries, in terms of the concept of         #
#   | Balanced Group in Regular Expression (while NOT using that in RegExp as it would fail in many cases)                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote:                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/1099178/matching-nested-structures-with-regular-expressions-in-python                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use [BeautifulSoup] instead)            #
#   |[2] Resolve the jinja-like expression such as: f<g<a>>, when [a] is a variable, [g<a>] is another, and so forth                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt               :   <str     > Character string from which to extract the substrings                                             #
#   |enclosers         :   <dict    > Mapping of enclosers with <key> as the left bound or opener, <value> as the right bound or closer #
#   |                      [(see def.)          ] <Default> Use the default values as defined                                           #
#   |rx                :   <bool    > Whether to treat the items in <enclosers> as Regular Expression                                   #
#   |                      [True                ] <Default> Treat them as regular expressions                                           #
#   |                      [False               ]           Treat them as raw character strings                                         #
#   |include           :   <bool    > Whether to include the enclosers in the output structure. When there are multiple items inside    #
#   |                       the argument <enclosers>, this argument is ignored and forced to be True                                    #
#   |                      [True                ] <Default> Include the bounds as output                                                #
#   |                      [False               ]           Exclude the bounds as output                                                #
#   |strict_           :   <bool    > Whether to avoid raising exception given the opener is missing for any among the closers, given   #
#   |                       the argument <include> is True                                                                              #
#   |                      [False               ] <Default> Avoid exception if any closer misses its opener and treat it as normal text #
#   |                      [True                ]           Raise exception if any closer misses its opener                             #
#   |flags             :   <int     > Flags to modify the parsing of the RegExp upon <enclosers>.                                       #
#   |                      [(see def.)          ] <Default> Parse the RegExp <enclosers> using no modifier                              #
#   |                      [RegexFlag           ]           Any (union of) <re.RegexFlag> to modify the parsing                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>            :   List of nested structures out of each pair of enclosers as a Balanced Group                                  #
#   |                      [1] If the bounds do not exist in pairs, exception is raised. Special cases are as below                     #
#   |                          [1] When <include=True>, <strict_=False> and there are missing openers, exception is suppressed          #
#   |                      [2] Standalone substrings, i.e. those not enclosed by the enclosers, are also included in the result         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20231118        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251213        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now supports multiple enclosers                                                                                         #
#   |      |[2] Now strictly lookup from left to right of the input to determine the depth of nesting                                   #
#   |      |[3] Exception of missing openers now can be suppressed                                                                      #
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
#   |   |sys, re                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if not isinstance(txt, str):
        raise TypeError(f'[{LfuncName}]<txt>:<{type(txt)}> must be provided a character string!')
    if not txt:
        return([])
    if not isinstance(rx, bool):
        raise TypeError(f'[{LfuncName}]<rx>:<{type(rx)}> must be provided a bool!')
    if not rx:
        enclosers = {re.escape(k):re.escape(v) for k,v in enclosers.items()}
    if len(enclosers) > 1:
        if not include:
            print(f'[{LfuncName}]Multiple enclosers are requested, <include> is set to True anyway.')
        include = True
    if not isinstance(strict_, bool):
        raise TypeError(f'[{LfuncName}]<strict_>:<{type(strict_)}> must be provided a bool!')

    #050. Local parameters
    #[ASSUMPTION]
    #[1] Create a separate stack to store the index of the left bound, to avoid matching all tokens to its RegExp at every iteration
    #[2] This reduces the Time Complexity
    stack = [[]]
    stack_lb = [[]]

    #100. Split the input string by the boundaries
    ptn_bound = re.compile('(' + '|'.join([j for i in [(k,v) for k,v in enclosers.items()] for j in i]) + ')', flags = flags)
    tokens = ptn_bound.split(txt)

    #300. Prepare the enclosers
    #[ASSUMPTION]
    #[1] In order to reduce the Time Complexity, we only loop the patterns once
    ptn_lBound = {}
    ptn_rBound = {}
    for i,(k,v) in enumerate(enclosers.items()):
        ptn_lBound[i] = re.compile(k, flags = flags)
        ptn_rBound[i] = re.compile(v, flags = flags)

    #500. Extract the nested structure
    for x in tokens:
        #100. Ignore the empty strings extracted when there are consecutive enclosers in the input
        if not x:
            continue

        #500. Match the token to any of the openers
        ptn_lb = None
        idx_lb = None
        for i,ptn in ptn_lBound.items():
            if ptn.match(x):
                ptn_lb = ptn
                idx_lb = i
                break

        #700. Different paths
        if ptn_lb is not None:
            #100. Nest a new list inside the current list
            #[ASSUMPTION]
            #[1] We add the boundary as well in the nested structure as requested
            if include:
                current = [x]
            else:
                current = []

            #[ASSUMPTION]
            #[1] <list> object is mutable
            #[2] When a list appended inside another object is modified, all references to it will also be refreshed
            #[3] The same validates if a list is extended
            #[4] This mechanism cannot be resembled in another language without mutability, e.g. <R> language
            stack[-1].append(current)
            stack.append(current)
            stack_lb[-1].append([idx_lb])
            stack_lb.append([idx_lb])
        else:
            ptn_rb = None
            idx_rb = None
            for i,ptn in ptn_rBound.items():
                if ptn.match(x):
                    ptn_rb = ptn
                    idx_rb = i
                    break

            if ptn_rb is not None:
                #100. Shrink the Auxiliary Space when it is not requested to include the closers
                if not include:
                    stack.pop()
                    stack_lb.pop()

                    if not stack:
                        raise ValueError(f'[{LfuncName}]Group opener is missing for closer: {x}')

                    continue

                #400. Look backwards to find any substructure with the corresponding opener
                k = len(stack)
                found = False
                for i in range(k-1, -1, -1):
                    if isinstance(stack[i][0], str):
                        if stack_lb[i][0] == idx_rb:
                            found = True
                            break

                #500. Roll back to the substructure as found
                if found:
                    del stack[(i+1):]
                    del stack_lb[(i+1):]

                #600. Complete this substructure with current closer (and hence refresh all its references)
                stack[-1].append(x)

                #800. Pop the completed substructure, or raise if it cannot be completed as per request
                if found:
                    stack.pop()
                    stack_lb.pop()
                elif strict_:
                    raise ValueError(f'[{LfuncName}]Group opener is missing for closer: {x}')
            else:
                stack[-1].append(x)

    #600. Raise if the numbers of left boundaries and right boundaries do not match
    if len(stack) > 1:
        print(stack)
        raise ValueError(f'[{LfuncName}]Group closer is missing')

    #900. Purge
    re.purge()

    #999. Emit the updated structure
    return stack.pop()
#End strNestedParser

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
    from omniPy.AdvOp import strNestedParser

    #100. Prepare strings
    teststr = '-- (bb (cc (dd))) aa (ee (ff)) ~~'
    testjinja = '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg'

    #200. Extraction
    ext_parens = strNestedParser(
        teststr
        ,enclosers = {'(' : ')'}
        ,rx = False
    )
    print(ext_parens)
    # ['-- ', ['(', 'bb ', ['(', 'cc ', ['(', 'dd', ')'], ')'], ')'], ' aa ', ['(', 'ee ', ['(', 'ff', ')'], ')'], ' ~~']

    ext_jinja = strNestedParser(
        testjinja
        ,enclosers = {'{{' : '}}'}
        ,rx = False
    )
    # ['-- ',
    #  ['{{', ' bb ', ['{{', ' cc', ['{{', ' dd ', '}}'], ' ', '}}'], ' ', '}}'],
    #  ' aa',
    #  ['{{', ' ee ', ['{{', ' ff ', '}}'], ' ', '}}']]

    ext_html = strNestedParser(
        testhtml
        ,enclosers = {r'<div.*?>' : r'</div>'}
        ,rx = True
    )
    # [['<div a="1">',
    #  'bbb',
    #  ['<div id="2">', 'ccc ', '</div>'],
    #  ' ddd',
    #  ['<div id="3">', 'eee', '</div>'],
    #  'fff',
    #  '</div>'],
    # ' ggg']

    #300. Special cases
    print(strNestedParser(''))
    # []

    print(strNestedParser(r'a'))
    # ['a']

    print(strNestedParser(r'(a b)'))
    # [['(', 'a b', ')']]

    print(strNestedParser(r'a (b)'))
    # ['a ', ['(', 'b', ')']]

    print(strNestedParser(r'(a) b'))
    # [['(', 'a', ')'], ' b']

    print(strNestedParser(r'(a ((b) c (d))) e (f (g))'))
    # [['(', 'a ', ['(', ['(', 'b', ')'], ' c ', ['(', 'd', ')'], ')'], ')'], ' e ', ['(', 'f ', ['(', 'g', ')'], ')']]

    print(strNestedParser(r'(a ((b) c (d))) e (f (g))', include = False))
    # [['a ', [['b'], ' c ', ['d']]], ' e ', ['f ', ['g']]]

    #330. Multiple enclosers
    txt = '-- (bb [cc (dd)]) aa {ee (ff)} ~~'

    #[ASSUMPTION]
    #[1] There are multiple enclosers to identify, hence the output result should include all enclosers
    #[2] <include> is forced to be True regardless of user request
    print(strNestedParser(
        txt
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # ['-- ', ['(', 'bb ', ['[', 'cc ', ['(', 'dd', ')'], ']'], ')'], ' aa ', ['{', 'ee ', ['(', 'ff', ')'], '}'], ' ~~']

    print(strNestedParser(
        txt
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,include = False
    ))
    # [strNestedParser]Multiple enclosers are requested, [include] is set to True anyway.
    # ['-- ', ['(', 'bb ', ['[', 'cc ', ['(', 'dd', ')'], ']'], ')'], ' aa ', ['{', 'ee ', ['(', 'ff', ')'], '}'], ' ~~']

    #340. Unmatched enclosers
    txt2 = 'a [(b { c) [ (d} e) f ] g'

    print(strNestedParser(
        txt2
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # ValueError: [strNestedParser]Group closer is missing

    txt3 = 'a (b { c) [ (d} e) f ] g'

    #[ASSUMPTION]
    #[1] The first opening '{' is treated as a normal text
    print(strNestedParser(
        txt3
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # ['a ', ['(', 'b ', ['{', ' c'], ')'], ' ', ['[', ' ', ['(', 'd', '}', ' e', ')'], ' f ', ']'], ' g']

    txt4 = 'a [b] c ]'

    #[ASSUMPTION]
    #[1] When <include = True> and <strict_ = False>, all enclosers are included in the result
    #[2] Hence if any closer misses its corresponding opener, it will be treated as a normal text
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = True
        ,strict_ = False
    ))
    # ['a ', ['[', 'b', ']'], ' c ', ']']

    #[ASSUMPTION]
    #[1] When <strict_ = True>, if any closer misses its corresponding opener, exception will be raised
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = True
        ,strict_ = True
    ))
    # ValueError: [strNestedParser]Group opener is missing for closer: ]

    #[ASSUMPTION]
    #[1] When <include = False>, all enclosers are excluded from the result
    #[2] Hence if any closer misses its corresponding opener, exception will be raised
    #[3] In such case, <strict_> is ignored
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = False
    ))
    # ValueError: [strNestedParser]Group opener is missing for closer: ]

    txt5 = 'a {b'

    #[ASSUMPTION]
    #[1] When the string is not closed by encloser, exception will be raised anyway
    #[2] Both <include> and <strict_> take no effect
    print(strNestedParser(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,include = True
    ))
    # ValueError: [strNestedParser]Group closer is missing

    print(strNestedParser(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,include = False
    ))
    # ValueError: [strNestedParser]Group closer is missing

    #360. Crossing enclosers
    cross1 = '[{aaa]}'

    print(strNestedParser(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    ))
    # [['[', ['{', 'aaa'], ']'], '}']

    print(strNestedParser(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = True
    ))
    # ValueError: [strNestedParser]Group opener is missing for closer: }

    # [CPU] Intel Core i9-14900K 8-Core 5.00GHz
    # [RAM] 128GB DDR5 4800MHz
    #900. Test timing
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    ext_large = strNestedParser(str_large, enclosers = {r'<div.*?>' : r'</div>'}, rx = True)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # 0:00:00.065996
#-Notes- -End-
'''

'''
#-Terminology- -Begin-
G-5-nano-0807
### 前提定义
- 记文本长度为 n = len(txt)。
- enclosers 的大小为 m = len(enclosers)。
- 通过 ptn_bound.split(txt) 得到的 token 数量记为 t。显然 t <= n + 1，且多数情况下 t = O(n)。
- 其他辅助结构的规模在常量级别或与 m 相关：ptn_lBound 和 ptn_rBound 各包含大约 m 个正则对象。

### 推导过程
1. 预处理与正则构造
- 将 enclosers 转换为转义后的键值对（当 rx 为 False 时），以及构造 ptn_bound（一个用于分割 txt 的正则）。
- 这一步的时间开销大致与 enclosers 的大小和字符长度相关，通常记作 O(sum(len(k) + len(v)) + m)，在实际使用中通常是 O(m)。
- 空间也为 O(m) 用于存放编译后的正则对象及中间字符串。
- ptn_bound.split(txt) 的代价是遍历并在匹配处分割，时间大致为 O(n)；产生的 token 数量为 t，空间为 O(t)（以及输出的 token 本身所需的额外空间）。
- 为每个 encloser 的双边界分别编译正则，这共需要 O(m) 次编译，单次编译成本与模式长度相关，记作 O(sum(len(k) + len(v)))，通常为 O(m)；空间为 O(m)。

2. 主循环对每个 token 的处理
- 对每个 x in tokens（共 t 个，长度为 Lx，且 ∑ Lx = O(n)）执行两次线性搜索：
  - 左边界检测：遍历 ptn_lBound 的 m 个模式，逐一执行 ptn.match(x)。最坏情况要对每个模式都尝试一次且每次的匹配代价与 Lx 成正比
    - 因此这步最坏时间为 O(m * Lx)。
    - 对全部 token 的总和为 O(m * ∑ Lx) = O(m * n)。
  - 右边界检测：同理，O(m * n)。
- 其余的栈操作为常数时间的 append / pop；但在遇到左界后可能会执行 del stack[(i+1):] 等切片删除操作。该操作的成本与要删除的深度相关，
  - 最坏情况下可能达到 O(depth) 而 depth 最多为 m（嵌套深度的上界）。在极端情况下，这些切片操作对每个左界都可能触发一次，总体可被把控在 O(n * m) 级别。

#### 综合主循环的时间复杂度：
- 最坏情况的时间上界可以近似写成 O(n * m)，其中 n 为文本长度，m 为 enclosers 的个数。若 m 与 n 同阶，即 m = Θ(n)，则最坏时间复杂度为 O(n^2)。

#### 需要强调的点：
- 实际运行时的常数因子很大程度取决于实际文本的分割情况、嵌套深度以及匹配是否能较早命中某个模式（这会降低常数项）。
- 该实现的最关键瓶颈在于“对所有左边界模式和所有右边界模式的逐个逐个匹配”，以及在深嵌套时的切片删除成本。

3. 空间复杂度
- 输出结果的尺寸等同于最终 return 的 stack（经处理后弹出的最终列表）。在最坏情况下，输出大小为 O(n)。
- 主循环中维护的栈 stack 与 stack_lb 的最大深度取决于嵌套层数，深度 upper bound 为 m；
- 因此这两者的额外空间开销为 O(n)（用于存放当前未闭合的 tokens，总和不超过文本中 token 的总数）加上 O(m) 的正则对象引用。
- 其他辅助结构，如 ptn_bound、ptn_lBound、ptn_rBound、以及局部变量等，合计为 O(m)。
- 综上，整体空间复杂度为 O(n + m)。

### 结论
- **Time Complexity**：在一般记号下，最坏情况大致为 O(n * m)。若 m 与 n 同量级（如 m = Θ(n)），则最坏情况下是 O(n^2)。
- **Auxiliary Space**：O(n + m)。

### 额外的注意与优化建议（可选）
- 该实现的主要时间成本来自对 m 个左边界模式和 m 个右边界模式的逐个匹配。若 enclosers 规模较大，可以考虑：
  - 将多模式匹配合并成一个单一的正则（若可行）或者使用一个字典结构将左边界字符快速定位到候选索引，减少不必要的正则匹配次数。
  - 采用堆栈结构的替代实现，避免对深度较大时的切片删除操作带来的 O(depth) 代价（例如通过维护一个指针/区间来表示当前层级，而非对列表进行切片删减）。
  - 若对嵌套深度有控制需求，可以在文档中约束 m 的上限，或对极端输入进行特殊处理（如提前抛错、改写为流式解析）。
'''
