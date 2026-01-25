#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re, html
from collections.abc import Iterable
from omniPy.Styles import TxtConverterReqMsg

def mdListToHTML(
    indPerLvl : int = 2
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This generator is to convert the Markdown text, that represents the nested ordered-lists/unordered-lists or mixture of both, into  #
#   | the normal HTML text with the same nesting levels                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Many of the Markdown parsers cannot parse nested lists correctly, esp. when there is a depth over 2 levels                     #
#   |[2] This generator could literally parse the nested lists in any depth                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Remediate the Markdown text by HTML tags at certain position where there are nested lists                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indPerLvl   :   <int      > Number of nimble spaces indicating the indent per level                                                #
#   |                [int <2>         ]  <Default> Each 2 consecutive spaces determine a further indent level                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Received messages.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   This generator receives the <dict> message with below possible items                                               #
#   |                [task     ] :   <str      > The requested task for current batch of process                                        #
#   |                                [add      ] Add the <value> to the pool of internal tags                                           #
#   |                                [finish   ] Stop the generation and thus return the generated HTML taglist. Sending this will      #
#   |                                             ignore all other items in the same batch of sending message, and close the generator. #
#   |                [value    ] :   <str      > The value to be included as the content of the HTML tag split by carriage return to    #
#   |                                             indicate multi-line input; should contain the leading signs for each line, i.e.       #
#   |                                             numbers for <ol> and <*>/<-> for <ul>                                                 #
#   |                                [str      ] Will be split by <str.splitlines()>                                                    #
#   |                                [Iterable ] Iterable of character strings, each will be split by <str.splitlines()>                #
#   |                [escape   ] :   <bool     > Whether to escape the input <value> to prevent HTML injection                          #
#   |                                [True     ] Escape any input <value>                                                               #
#   |                                [False    ] Keep the raw input                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |910.   Yield Values by position.                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   Do not yield any value as it is designed to return the complete taglist when requested                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |990.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str >      :   The complete HTML taglist at the request of <{'task' : 'finish'}>                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20251222        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, re, html, collections                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Styles                                                                                                                         #
#   |   |   |TxtConverterReqMsg                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer

    #050. Local parameters
    task_cand = ('add','finish')
    rx_ul = re.compile(r'^([ \t]*)([*+-])\s+(.*)$')
    rx_ol = re.compile(r'^([ \t]*)(\d+)[\.)]\s+(.*)$')
    parts = []
    #[ASSUMPTION]
    #[1] This is a multi-layer list holding a dict at every layer: {'type' : 'ul/ol', 'open_li' : bool}
    stack = []

    #200. Helper functions
    #201. Convert spaces to depth
    def h_sp_to_depth(s : str) -> int:
        # One tab is translated into 4 consecutive spaces
        s = s.replace('\t', ' ' * 4)
        return(len(s) // indPerLvl)

    #210. Open a tag of certain type
    def h_open_tag(tag : str):
        parts.append('  ' * len(stack) + f'<{tag}>')
        stack.append({'type' : tag, 'open_li' : False})

    #220. Close the last tag and complete the substructure
    def h_close_tag():
        last_tag = stack[-1]['type']
        parts.append('  ' * len(stack) + f'</{last_tag}>')
        stack.pop()

    #240. Open an empty <li> when needed for level skipping, as a host of the nested levels
    def h_open_li():
        if stack and not stack[-1]['open_li']:
            parts.append('  ' * len(stack) + '<li><span aria-hidden="true" style="display:none"></span>')
            stack[-1]['open_li'] = True

    #250. Close an item of current substructure
    def h_close_li():
        if stack and stack[-1]['open_li']:
            parts.append('  ' * len(stack) + '</li>')
            stack[-1]['open_li'] = False

    #290. Process each line of input
    def h_proc_line(raw : str, escape : bool):
        #001. Should there be a bunch of lines sent in one batch, we split them and thus may create excessive carriage return signs
        raw = raw.rstrip('\n')

        #005. Skip empty input
        if not raw.strip():
            return

        #100. Determine the type and depth of the input
        m = rx_ul.match(raw)
        if m:
            tag_type = 'ul'
        else:
            m = rx_ol.match(raw)
            # Currently ignore any none list input, one may extend the functionality here
            if not m:
                return
            tag_type = 'ol'

        depth = h_sp_to_depth(m.group(1))
        content = html.escape(m.group(3)) if escape else m.group(3)

        #200. Define the top level taglist
        #[ASSUMPTION]
        #[1] Always keep a top level tag for the reasoning of taglist depth
        #[2] Depth of the top level tag is 0, container layer is 1
        target_levels = depth + 1

        #300. Open the nested layers till the dedicated depth
        #[ASSUMPTION]
        #[1] Keep the status of the parent <li> as open
        while len(stack) < target_levels:
            #100. Ensure to open a <li> as a container for sub-items at the deepest level till now
            if len(stack) > 0:
                h_open_li()

            #900. Open the root container based on current type
            #[ASSUMPTION]
            #[1] Open a container for the next nesting level as a bridge to wrap the contents with skipping levels
            h_open_tag(tag_type)

        #400. Close the nested layers of <li>
        #[ASSUMPTION]
        #[1] Close current <li> and all the excessive containers backwards along the stack
        while len(stack) > target_levels:
            h_close_li()
            h_close_tag()

        #500. Switch between ul/ol at current layer
        if stack and stack[-1]['type'] != tag_type:
            #100. Close the last open containers
            h_close_li()
            h_close_tag()

            #900. Open another container of the same type immediately
            h_open_tag(tag_type)

        #600. Close the previous <li> for the case of brother item
        h_close_li()

        #900. Assign current <li>
        parts.append('  ' * len(stack) + f'<li>{content}')
        stack[-1]['open_li'] = True

    #500. Protocol as a generator
    #510. Activate the generator with the first generated value as None
    msg : TxtConverterReqMsg = yield None

    #550. Main process
    while True:
        #001. Shut down if invalid message is sent to the generator
        if not isinstance(msg, dict):
            raise TypeError(f'[{LfuncName}]Require to call with input as dict!')
        if not msg:
            raise ValueError(f'[{LfuncName}]Require to call with specific instructions!')
        if 'task' not in msg:
            raise ValueError(f'[{LfuncName}]Require to call with specific <task>: {task_cand}!')
        if not isinstance(msg['task'], str):
            raise TypeError(f'[{LfuncName}]<task> should be character string as: {task_cand}!')
        if msg['task'].strip().lower() not in task_cand:
            raise ValueError(f'[{LfuncName}]Require to call with specific <task>: {task_cand}!')
        if msg['task'].strip().lower() == 'add':
            if 'value' not in msg:
                raise ValueError(f'[{LfuncName}]Require character string <value> to add tags!')
            if not isinstance(msg['value'], Iterable):
                raise TypeError(f'[{LfuncName}]<value> should be <str> or Iterable[str]!')
            if 'escape' not in msg:
                raise ValueError(f'[{LfuncName}]Require <escape> to indicate whether to escape HTML text for task to add tags!')
            if not isinstance(msg['escape'], bool):
                raise TypeError(f'[{LfuncName}]<escape> should be bool!')

        #100. Finish the taglist and shut down the generator with the return HTML text
        if msg['task'].strip().lower() == 'finish':
            while stack:
                h_close_li()
                h_close_tag()
            # One should obtain this from StopIteration(value=result)
            return('\n'.join(parts))

        #500. Handle different input
        if isinstance(msg['value'], str):
            for line in msg['value'].splitlines():
                h_proc_line(line, escape = msg['escape'])
        elif isinstance(msg['value'], Iterable):
            for it in msg['value']:
                for line in str(it).splitlines():
                    h_proc_line(line, escape = msg['escape'])

        #990. Wait for another batch of input
        msg : TxtConverterReqMsg = yield None
#End mdListToHTML

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import os
    from collections.abc import Iterable
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Styles import mdListToHTML

    #100. Helper function to convert the input text as a whole batch
    def wrap_mdListToHTML(md_text : str | Iterable[str], *pos, **kw):
        #300. Setup the generator
        inner_gen = mdListToHTML(*pos, **kw)

        #500. Activation
        next(inner_gen)

        #600. Conversion as one batch
        inner_gen.send({'task' : 'add', 'value' : md_text, 'escape' : False})

        #900. Collect the final result
        try:
            inner_gen.send({'task' : 'finish'})
        except StopIteration as e:
            return(e.value)
        return('')

    #200. Prepare test case
    #[ASSUMPTION]
    #[1] The first line contains one indent, i.e. without parent list, hence there will be a parent <ul> created
    #     for it as placeholder (in the same type as this one)
    #[2] Similar placeholders, a.k.a. bridge containers, are created when there are levels skipping certain indents
    md_text = '\n'.join([
         '  - Level 2 A'
        ,'    - Level 3 A-1'
        ,'      - Level 4 A-1-1'
        ,'- Level 1 B'
        ,'  1. Level 2 B-1'
        ,'    1. Level 3 B-1-1'
        ,'      - Level 4 B-1-1-1'
        ,'      - Level 4 B-1-1-2'
        ,'    2. Level 3 B-1-2'
        ,'  2. Level 2 B-2'
    ])

    #300. Conversion
    html1 = wrap_mdListToHTML(md_text)

    outfile = r'D:\Temp\parsed_docstring.html'
    with open(outfile, 'w', encoding = 'utf-8') as f:
        f.write(html1)

    print(html1)
    # <ul>
    #   <li><span aria-hidden="true" style="display:none"></span>
    #   <ul>
    #     <li>Level 2 A
    #     <ul>
    #       <li>Level 3 A-1
    #       <ul>
    #         <li>Level 4 A-1-1
    #         </li>
    #         </ul>
    #       </li>
    #       </ul>
    #     </li>
    #     </ul>
    #   </li>
    #   <li>Level 1 B
    #   <ol>
    #     <li>Level 2 B-1
    #     <ol>
    #       <li>Level 3 B-1-1
    #       <ul>
    #         <li>Level 4 B-1-1-1
    #         </li>
    #         <li>Level 4 B-1-1-2
    #         </li>
    #         </ul>
    #       </li>
    #       <li>Level 3 B-1-2
    #       </li>
    #       </ol>
    #     </li>
    #     <li>Level 2 B-2
    #     </li>
    #     </ol>
    #   </li>
    #   </ul>

    if os.path.isfile(outfile):
        os.remove(outfile)

#-Notes- -End-
'''

'''
#-Terminology- -Begin-
ChatGPT-5.0
### 思路概述
- 逐行扫描：用正则匹配“前导空格 + 列表标记 + 内容”
- 层级计算：每 2 空格为一层，可调
- 栈维护：用一个栈记录当前打开的列表容器（ul/ol）以用同层是否有尚未闭合的<li>
- 根容器规则：始终维持根列表容器存在（栈长度 = depth + 1），这样可以自然地在顶层做同级兄弟项和跨类型切换
- 开闭时机：
  - 进入更深层（len(stack) < depth + 1）：在父<li>未闭合的情况下打开新的列表容器（嵌套列表必须出现在<li>内部）
  - 返回上层（len(stack) > depth + 1）：先闭合当前<li>，再依次闭合多余的列表容器
  - 同层兄弟项：先闭合上一条的<li>，再输出新<li>
  - 同层切换ul/ol：闭合上一条<li>与当前容器，重新打开目标类型的容器

### 结论
- **Time Complexity**：O(n * 2)。n为对输入值仅进行单次扫描，2为匹配ul/ol次数（各一次）
- **Auxiliary Space**：O(n + d)。n是为n个输入行预留的子空间，d为最大嵌套深度
'''
