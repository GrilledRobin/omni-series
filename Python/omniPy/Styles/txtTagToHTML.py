#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re, html
from collections.abc import Iterable
from omniPy.Styles import TxtConverterReqMsg

def txtTagToHTML(
    leadSign : str = '>'
    ,tag : str = 'blockquote'
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This generator is to convert the (preferrably) Markdown text, that represents the nested tags, e.g. Block Quotes, into the normal  #
#   | HTML text with the same nesting levels                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Many of the Markdown parsers cannot parse nested blockquotes correctly, esp. when there is a depth over 2 levels               #
#   |[2] This generator could literally parse the nested lists in any depth                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Remediate the Markdown text by HTML tags at certain position where there are nested tags                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |leadSign    :   <str      > The leading signs to match with RegExp, which can exist multiple times, indicating respective nesting  #
#   |                 levels, in the same line of the text to be parsed                                                                 #
#   |                [&gt;            ]  <Default> The right triangle indicating Blockquotes in Markdown                                #
#   |tag         :   <str      > Name of a valid HTML tag, which should also be able to nest in any depth, such as <blockquote>         #
#   |                [blockquote      ]  <Default> Use this tag in the output HTML                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Received messages.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   This generator receives the <dict> message with below possible items                                               #
#   |                [task     ] :   <str      > The requested task for current batch of process                                        #
#   |                                [add      ] Add the <value> to the pool of internal tags                                           #
#   |                                [finish   ] Stop the generation and thus return the generated HTML taglist. Sending this will      #
#   |                                             ignore all other items in the same batch of sending message, and close the generator. #
#   |                [value    ] :   <str      > The value to be included as the content of the HTML tag split by carriage return to    #
#   |                                             indicate multi-line input; should contain the leading signs for each line             #
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
#   | Date |    20251224        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
    rx_tag = re.compile(r'^(' + leadSign + r'+)\s+(.*)$')
    parts = []
    stack = []

    #200. Helper functions
    #210. Open a tag of certain type
    def h_open_tag(tag : str = tag):
        parts.append('  ' * len(stack) + f'<{tag}>')
        # Value of the item does not matter as it is only a placeholder to identify the depth of the stack
        stack.append(True)

    #220. Close the last tag and complete the substructure
    def h_close_tag(tag : str = tag):
        parts.append('  ' * len(stack) + f'</{tag}>')
        stack.pop()

    #290. Process each line of input
    def h_proc_line(raw : str, escape : bool):
        #001. Should there be a bunch of lines sent in one batch, we split them and thus may create excessive carriage return signs
        raw = raw.rstrip('\n')

        #005. Skip empty input
        if not raw.strip():
            return

        #100. Determine the type and depth of the input
        m = rx_tag.match(raw)
        if not m:
            return

        depth = m.group(1).count(leadSign)
        content = html.escape(m.group(2)) if escape else m.group(2)

        #200. Ensure to open the top level tag
        #[ASSUMPTION]
        #[1] Always keep a top level tag for the reasoning of taglist depth
        if not stack:
            h_open_tag(tag)

        #300. Open the nested layers till the dedicated depth
        if depth == 1:
            while len(stack) > 1:
                h_close_tag(tag)
        else:
            while len(stack) < depth:
                h_open_tag(tag)

            while len(stack) > depth:
                h_close_tag(tag)

        #500. Assign current value
        parts.append('  ' * len(stack) + content)

        #900. Close current container
        if depth != 1:
            h_close_tag(tag)

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
                h_close_tag(tag)
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
#End txtTagToHTML

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
    from omniPy.Styles import txtTagToHTML

    #100. Helper function to convert the input text as a whole batch
    def wrap_txtTagToHTML(md_text : str | Iterable[str], *pos, **kw):
        #300. Setup the generator
        inner_gen = txtTagToHTML(*pos, **kw)

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
    md_text = '\n'.join([
         '> AdvOp'
        ,'>> debug_comp_datcols'
        ,'>> modifyDict'
        ,'> Dates'
        ,'>> asDates'
        ,'> AdvDB'
        ,'>> DataIO'
        ,'>> parseDatName'
        ,'>> DBuse_SetKPItoInf'
        ,'>> DBuse_MrgKPItoInf'
        ,'>> validateDMCol'
    ])

    #300. Conversion
    html1 = wrap_txtTagToHTML(md_text)

    outfile = r'D:\Temp\parsed_docstring.html'
    with open(outfile, 'w', encoding = 'utf-8') as f:
        f.write(html1)

    print(html1)
    # <blockquote>
    #   AdvOp
    #   <blockquote>
    #     debug_comp_datcols
    #     </blockquote>
    #   <blockquote>
    #     modifyDict
    #     </blockquote>
    #   Dates
    #   <blockquote>
    #     asDates
    #     </blockquote>
    #   AdvDB
    #   <blockquote>
    #     DataIO
    #     </blockquote>
    #   <blockquote>
    #     parseDatName
    #     </blockquote>
    #   <blockquote>
    #     DBuse_SetKPItoInf
    #     </blockquote>
    #   <blockquote>
    #     DBuse_MrgKPItoInf
    #     </blockquote>
    #   <blockquote>
    #     validateDMCol
    #     </blockquote>
    #   </blockquote>

    if os.path.isfile(outfile):
        os.remove(outfile)

#-Notes- -End-
'''
