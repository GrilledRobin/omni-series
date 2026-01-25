#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import pandas as pd
from typing import Optional

def strNestedParser(
    txt : str
    ,enclosers : dict[str, str] = {'(' : ')'}
    ,rx : bool = False
    ,include : bool = True
    ,strict_ : bool = False
    ,flags : re.RegexFlag = re.NOFLAG
    ,meta_ : bool = False
) -> dict[str, list[str | list[str | list[...]]] | dict[str, pd.DataFrame]]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the nested structures surrounded by the provided boundaries, in terms of the concept of         #
#   | Balanced Group in Regular Expression (while NOT using that in RegExp as it would fail in many cases)                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/1099178/matching-nested-structures-with-regular-expressions-in-python                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Extract the contents of balanced tags from an HTML tagset (it is highly recommended to use [BeautifulSoup] instead)            #
#   |[2] Resolve the jinja-like expression such as: <f{g{a}}>, when <a> is a variable, <g{a}> is another, and so forth                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt               :   <str     > Character string from which to extract the substrings                                             #
#   |enclosers         :   <dict    > Mapping of enclosers with <key> as the left bound or opener, <value> as the right bound or closer #
#   |                      [(see def.)          ] <Default> Use the default values as defined                                           #
#   |rx                :   <bool    > Whether to treat the items in <enclosers> as Regular Expression                                   #
#   |                      [False               ] <Default> Treat them as raw character strings                                         #
#   |                      [True                ]           Treat them as regular expressions                                           #
#   |include           :   <bool    > Whether to include the enclosers in the output structure. When there are multiple items inside    #
#   |                       the argument <enclosers>, this argument is ignored and forced to be True                                    #
#   |                      [True                ] <Default> Include the bounds as output                                                #
#   |                      [False               ]           Exclude the bounds as output                                                #
#   |                       [IMPORTANT] Setting it as <False> prevents the function to collect <META> information of <closers> and thus #
#   |                                    lead to unexpected result when requested. So it is suggested to set <include=True> when you    #
#   |                                    also need <meta_=True>, although it is not verified.                                           #
#   |strict_           :   <bool    > Whether to avoid raising exception given the opener is missing for any among the closers, given   #
#   |                       the argument <include> is True                                                                              #
#   |                      [False               ] <Default> Avoid exception if any closer misses its opener and treat it as normal text #
#   |                      [True                ]           Raise exception if any closer misses its opener                             #
#   |flags             :   <int     > Flags to modify the parsing of the RegExp upon <enclosers>.                                       #
#   |                      [(see def.)          ] <Default> Parse the RegExp <enclosers> using no modifier                              #
#   |                      [RegexFlag           ]           Any (union of) <re.RegexFlag> to modify the parsing                         #
#   |meta_             :   <bool    > Whether to export the meta information during the matching and extraction                         #
#   |                      [False               ] <Default> Do not collect meta information and keep high efficiency                    #
#   |                      [True                ]           Collect meta information for debug or visualization purposes                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>            :   Dict of below content                                                                                        #
#   |                      [RESULT ] <list> of nested structures out of each pair of enclosers as a Balanced Group                      #
#   |                                [1] If the bounds do not exist in pairs, exception is raised. Special cases are as below           #
#   |                                    [1] When <include=True>, <strict_=False> and there are missing openers, exception is suppressed#
#   |                                [2] Standalone substrings, i.e. those not enclosed, are also included in the result                #
#   |                      [META   ] <dict> of various <pd.DataFrame> holding the meta information during the extraction. Details are   #
#   |                                 as listed in below section <META details>                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |950.   META details.                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   nodes                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |A <node> is defined at an <opener> determined by <enclosers>, and starts with 0 as <root node>, meaning that the entire    #
#   |   |   | input string is a <node> at the ID of 0, also at the <depth> of 0. However,this table does not store the <root node>,     #
#   |   |   | hence the <node>s in it can only start with 1 and larger.                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |IMPORTANT                                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[1] A <node> with <unmatched==True> status is stored in another table <nodes_unclosed>, as its <opener> is wrapped inside  #
#   |   |   |     another complete <node>, and lost its nature                                                                          #
#   |   |   |[2] Isolated <closer> does not form a <node> and is taken as free text                                                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |node_id         |Int64       |No       |ID of current <node>                                                               #
#   |   |   |parent_id       |Int64       |No       |ID of the parent <node> to current one                                             #
#   |   |   |depth           |Int64       |No       |How far current <node> is related to the <root node>, defined as being wrapped by  #
#   |   |   |                |            |         | how many <unclosed opener>s, except those identified as <unmatched> during parsing#
#   |   |   |pair_id         |Int64       |No       |ID of the <enclosers> as requested in the dedicated sequence at input. <N> pairs of#
#   |   |   |                |            |         | <enclosers> corresponds to the same number of <ID>s                               #
#   |   |   |opener_def      |str         |No       |Definition of the <opener> as requested, may be the representation of RegExp       #
#   |   |   |closer_def      |str         |No       |Definition of the <closer> as requested, may be the representation of RegExp       #
#   |   |   |opener_match    |str         |No       |Identified <opener> text during parsing                                            #
#   |   |   |                |            |         | [1] same as <opener> when <rx=False>                                              #
#   |   |   |                |            |         | [2] substring matching the <opener> when <rx=True>                                #
#   |   |   |closer_match    |str         |No       |Identified <closer> text during parsing                                            #
#   |   |   |                |            |         | [1] same as <closer> when <rx=False>                                              #
#   |   |   |                |            |         | [2] substring matching the <closer> when <rx=True>                                #
#   |   |   |opener_start    |Int64       |No       |start position of the identified <opener_match>                                    #
#   |   |   |opener_end      |Int64       |No       |end position of the identified <opener_match>, useful when <rx=True>               #
#   |   |   |closer_start    |Int64       |No       |start position of the identified <closer_match>                                    #
#   |   |   |closer_end      |Int64       |No       |end position of the identified <closer_match>, useful when <rx=True>               #
#   |   |   |span_start      |Int64       |No       |start position of the <span> covering the identified <opener_start>                #
#   |   |   |                |            |         | [NOTE] A <span> is only for a complete <node> with proper <closer>, hence it is   #
#   |   |   |                |            |         |         not defined for the <root node> or <nodes_unclosed>                       #
#   |   |   |span_end        |Int64       |No       |end position of the <span> covering the identified <closer_end>                    #
#   |   |   |inner_start     |Int64       |No       |start position of the wrapped content, excluding the identified <opener_match>     #
#   |   |   |                |            |         | [NOTE] <inner> is only for a complete <node> with proper <closer>, hence it is not#
#   |   |   |                |            |         |         defined for the <root node> or <nodes_unclosed>                           #
#   |   |   |inner_end       |Int64       |No       |end position of the wrapped content, excluding the identified <closer_match>       #
#   |   |   |closed          |bool        |No       |Whether current <node> is complete with proper <closer> during parsing, literally  #
#   |   |   |                |            |         | all <True> in this table                                                          #
#   |   |   |unmatched       |bool        |No       |Whether current <opener> cannot match a proper <closer> and is wrapped inside      #
#   |   |   |                |            |         | another complete <node>, literally all <False> in this table                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |150.   nodes_unclosed                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |All <opener>s that cannot match proper <closer>s and are wrapped inside other complete <node>s, will be deemed             #
#   |   |   | <unmatched>, since they are defined as a <node> at the meantime, they are stored in this table                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |IMPORTANT                                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[1] If <strict_=True>, function raises exception when any <nodes_unclosed> is identified, hence there is no <META> for use #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |node_id         |Int64       |No       |ID of current <node>                                                               #
#   |   |   |parent_id       |Int64       |No       |ID of the parent <node> to current one                                             #
#   |   |   |depth           |Int64       |No       |How far current <node> is related to the <root node>, defined as being wrapped by  #
#   |   |   |                |            |         | how many <unclosed opener>s, except those identified as <unmatched> during parsing#
#   |   |   |pair_id         |Int64       |No       |ID of the <enclosers> as requested in the dedicated sequence at input. <N> pairs of#
#   |   |   |                |            |         | <enclosers> corresponds to the same number of <ID>s                               #
#   |   |   |opener_def      |str         |No       |Definition of the <opener> as requested, may be the representation of RegExp       #
#   |   |   |closer_def      |str         |No       |Definition of the <closer> as requested, may be the representation of RegExp       #
#   |   |   |opener_match    |str         |No       |Identified <opener> text during parsing                                            #
#   |   |   |                |            |         | [1] same as <opener> when <rx=False>                                              #
#   |   |   |                |            |         | [2] substring matching the <opener> when <rx=True>                                #
#   |   |   |opener_start    |Int64       |No       |start position of the identified <opener_match>                                    #
#   |   |   |opener_end      |Int64       |No       |end position of the identified <opener_match>, useful when <rx=True>               #
#   |   |   |closed          |bool        |No       |Whether current <node> is complete with proper <closer> during parsing, literally  #
#   |   |   |                |            |         | all <False> in this table                                                         #
#   |   |   |unmatched       |bool        |No       |Whether current <opener> cannot match a proper <closer> and is wrapped inside      #
#   |   |   |                |            |         | another complete <node>, literally all <True> in this table                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |200.   segments                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |All substrings that are split by the <enclosers> are deemed as <segments>, so that it is useful to identify each piece of  #
#   |   |   | the raw string for investigation, visualization and other text analysis                                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DEFINITION                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[1] All substrings excluding the <enclosers> are deemed as <segments>, taking their nearby whitespaces along with them,    #
#   |   |   |     since it is the way <re.split> is in use                                                                              #
#   |   |   |[2] All <node>s are deemed as <segments>, they may overlap the substrings defined at above step but it is OK, as they are  #
#   |   |   |     of different purposes                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |seg_id          |Int64       |No       |ID of current <segment>, starting from the primitive indexing number of <Python>   #
#   |   |   |parent_id       |Int64       |No       |ID of the parent <node>. Parent <node> for a <segment> is identified in below way: #
#   |   |   |                |            |         | [1] Looking behind current <segment> for the nearest <node> that is not <closed>  #
#   |   |   |                |            |         |      and not marked <unmatched> as well. Then this <segment> is tagged to it      #
#   |   |   |                |            |         | [2] If no such <node> is found, the <segment> is tagged to <root node>            #
#   |   |   |depth           |Int64       |No       |How far current <segment> is related to the <root node>, defined as wrapped by how #
#   |   |   |                |            |         | many <unclosed opener>s, except those identified as <unmatched> during parsing    #
#   |   |   |type            |str         |No       |Type of the <segment>                                                              #
#   |   |   |                |            |         | [text] substring at current position                                              #
#   |   |   |                |            |         | [node] collection as a <node> holding many substrings                             #
#   |   |   |start           |Int64       |No       |start position. It covers the <enclosers> for a <segment> denoted by a <node>      #
#   |   |   |end             |Int64       |No       |end position. It covers the <enclosers> for a <segment> denoted by a <node>        #
#   |   |   |text            |str         |No       |The substring denoted by <start> and <end>                                         #
#   |   |   |node_id         |Int64       |Yes      |ID of the <node> denoting current <segment>, can be <None> if it is not a <node>   #
#   |   |   |pair_id         |Int64       |Yes      |ID of the <enclosers> as requested in the dedicated sequence at input for the      #
#   |   |   |                |            |         | <node>. It can be <None> if current <segment> is not a <node>                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |300.   edges                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |This table stores the relationship edges between the parent and child <node>s, excluding those marked <unmatched> as they  #
#   |   |   | are not complete <node>s                                                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |DICTIONARY                                                                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   Field Name   |   dtype    |Nullable?|   Description                                                                     #
#   |   |   |----------------|------------|---------|-----------------------------------------------------------------------------------#
#   |   |   |from_node       |Int64       |No       |From which <node> to expand the relationship tree                                  #
#   |   |   |to_node         |Int64       |No       |To which <node> to expand the relationship tree                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20260108        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <meta_> to enable meta information extraction for other purposes e.g. debug, highlighting, etc.      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, re, pandas, typing                                                                                                        #
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
    if not isinstance(rx, bool):
        raise TypeError(f'[{LfuncName}]<rx>:<{type(rx)}> must be provided a bool!')
    if len(enclosers) > 1:
        if not include:
            print(f'[{LfuncName}]Multiple enclosers are requested, <include> is set to True anyway.')
        include = True
    if not isinstance(strict_, bool):
        raise TypeError(f'[{LfuncName}]<strict_>:<{type(strict_)}> must be provided a bool!')
    if not isinstance(meta_, bool):
        raise TypeError(f'[{LfuncName}]<meta_>:<{type(meta_)}> must be provided a bool!')

    #050. Local parameters
    len_txt = len(txt)
    #[ASSUMPTION]
    #[1] Create a separate stack to store the index of the left bound, to avoid matching all tokens to its RegExp at every iteration
    #[2] This reduces the Time Complexity
    stack = [[]]
    stack_lb = [[]]

    #060. Prepare the enclosers
    #[ASSUMPTION]
    #[1] In order to reduce the Time Complexity, we only loop the patterns once
    #[2] We set longer definition string first (heuristic; same as R version)
    #[3] Wrap token with non-capturing pattern (?:...) to neutralize inner capturing groups
    enclosers_id = {}
    ptn_lBound = {}
    ptn_rBound = {}
    for i,(k,v) in enumerate(enclosers.items()):
        ptn_lBound[k if not rx else re.compile(k, flags = flags)] = i
        ptn_rBound[v if not rx else re.compile(v, flags = flags)] = i
        enclosers_id[i * 2] = k
        enclosers_id[i * 2 + 1] = v
    enclosers_ord = {k:v for k,v in sorted(enclosers_id.items(), key = lambda x: len(x[1]), reverse = True)}
    ptn_bound = re.compile(
        '((?:' + '|'.join([v if rx else re.escape(v) for v in enclosers_ord.values()]) + '))'
        ,flags = flags
    )

    #090. Prepare meta parameters
    #[ASSUMPTION]
    #[1] <dict> is ordered for Python >= 3.7
    if meta_:
        enclosers_len = len(enclosers) * 2
        ord_rBound = list(ptn_rBound)
        # <enc_id> is the ID of current encloser for mapping into <token_stats>, regardless of opener or closer
        enc_id = -1

        #100. nodes
        #[ASSUMPTION]
        #[1] There is a root node for the whole raw string, hence all the rest <node_id>s start with 1, we set its initial
        #     value as 0 for later steps of incremental
        stack_nodes : list[dict[str, Optional[str | int | bool]]] = [{
            'node_id' : 0
            ,'parent_id' : None
            ,'depth' : 0
            ,'pair_id' : None
            ,'opener_def' : None
            ,'closer_def' : None
            ,'opener_match' : None
            ,'opener_start' : None
            ,'opener_end' : None
        }]
        node_id = stack_nodes[-1]['node_id']

        #200. segments
        #[ASSUMPTION]
        #[1] A <segment> is registered when any of below conditions is triggered
        #    [1] free text substring (between any of the <tokens> as well as the start/end of the raw input)
        #    [2] any <node> regardless of whether it is unclosed
        stack_segs : list[dict[str, Optional[str | int | bool]]] = []
        seg_id = -1

    #100. Split the input string by the boundaries
    tokens = ptn_bound.split(txt)

    #300. Calculate the stats for the content as split
    if meta_:
        #100. Sort the enclosers for higher efficiency
        #[ASSUMPTION]
        #[1] priority: longer definition string first (heuristic; same as R version)
        enclosers_pos_to_id = {i:k for i,k in enumerate(enclosers_ord.keys())}
        ptn_bound_meta = re.compile(
            '|'.join(['((?:{}))'.format(v if rx else re.escape(v)) for v in enclosers_ord.values()])
            ,flags = flags
        )

        #200. Define helper functions
        #201. Helper function to locate the match in the enclosers
        def h_locEncloser(m : re.Match) -> tuple[int, int, int, str, str]:
            #100. Obtain all the groups, the length of which is the same as <enclosers_len>
            x_group = m.groups()

            #500. Determine the enclosers that exactly match current token
            #[ASSUMPTION]
            #[1] There should be only one match for one pattern in one enclosers group
            #[2] Below method is faster than <next()> on large number of enclosers
            # x_pos, x = next((i, v) for i, v in enumerate(x_group) if v is not None)
            x = None
            x_pos = -1
            while (x is None) and (x_pos < enclosers_len):
                x_pos += 1
                x = x_group[x_pos]

            #700. Retrieve the encloser ID
            x_id = enclosers_pos_to_id[x_pos]

            return(m.start(), m.end(), x_id, enclosers_id.get(x_id), x)

        #500. Collect them as a data frame
        #[ASSUMPTION]
        #[1] Abover iterator is a one-off object, i.e. destroyed immediately after one loop over it
        #[2] The result may have a length of 0 if there is no match
        #[3] <index> of below data frame is crucial for slicing at later steps, make sure it is set by default, starting from 0
        token_stats = (
            pd.DataFrame(
                [h_locEncloser(m) for m in ptn_bound_meta.finditer(txt)]
                ,columns = ['start','end','encloser_id','encloser','encloser_matched']
            )
            .astype({'start' : 'Int64', 'end' : 'Int64', 'encloser_id' : 'Int64'})
        )

        if len(token_stats) == 0:
            token_stats = (
                pd.DataFrame(
                    {
                        'start' : 0
                        ,'end' : len_txt
                        ,'encloser_id' : -1
                        ,'encloser' : ''
                        ,'encloser_matched' : ''
                    }
                    ,index = [0]
                )
                .astype({'start' : 'Int64', 'end' : 'Int64', 'encloser_id' : 'Int64'})
            )

        #550. Determine the beginning of the content other than the enclosers
        token_stats['text_bgn'] = token_stats['end'].shift(1).fillna(0).astype(int)

    #500. Extract the nested structure
    for x in tokens:
        #100. Ignore the empty strings extracted when there are consecutive enclosers in the input
        if not x:
            continue

        #500. Match the token to any of the openers
        idx_lb = None
        if not rx:
            if x in ptn_lBound:
                idx_lb = ptn_lBound[x]
        else:
            for ptn,i in ptn_lBound.items():
                if ptn.match(x):
                    idx_lb = i
                    break

        #700. Different paths
        #710. Current token is one of the openers
        if idx_lb is not None:
            #100. Resister meta information
            if meta_:
                #100. Update current node
                enc_id += 1
                node_id += 1
                # root stack len=1 => first child depth=1
                depth = len(stack)
                for j in range(len(stack_nodes)-1, -1, -1):
                    if (not stack_nodes[j].get('closed', False)) and (stack_nodes[j].get('depth') == depth - 1):
                        parent_id = stack_nodes[j]['node_id']
                        break
                node_this = {
                    'node_id' : node_id
                    ,'parent_id' : parent_id
                    ,'depth' : depth
                    ,'pair_id' : idx_lb
                    ,'closed' : False
                    ,'unmatched' : False
                    ,'opener_def' : x if not rx else ptn
                    ,'closer_def' : ord_rBound[idx_lb]
                    ,'opener_match' : x
                    ,'opener_start' : token_stats.at[enc_id, 'start']
                    ,'opener_end' : token_stats.at[enc_id, 'end']
                }
                stack_nodes.append(node_this)

                #200. Register current segment
                #[ASSUMPTION]
                #[1] At this point, we only know the <start> of it, hence will update its <end> afterwards
                seg_id += 1
                seg_this = {
                    'seg_id' : seg_id
                    ,'parent_id' : parent_id
                    ,'depth' : depth
                    ,'start' : node_this['opener_start']
                    ,'type' : 'node'
                    ,'node_id' : node_id
                    ,'pair_id' : idx_lb
                    ,'text' : None
                }
                stack_segs.append(seg_this)

            #800. Nest a new list inside the current list
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

        #750. Other cases
        else:
            #100. Match the token to any of the closers
            idx_rb = None
            if not rx:
                if x in ptn_rBound:
                    idx_rb = ptn_rBound[x]
            else:
                for ptn,i in ptn_rBound.items():
                    if ptn.match(x):
                        idx_rb = i
                        break

            #500. Current token is one of the closers
            if idx_rb is not None:
                #100. Register meta information
                at_pos = ''
                if meta_:
                    #100. Whenever a token is identified, we increment the ID of encloser, for search inside <token_stats>
                    enc_id += 1

                    #900. Logging
                    at_pos = ' at position: <' + str(token_stats.at[enc_id, 'start']) + '>'

                #200. Shrink the Auxiliary Space when it is not requested to include the closers
                if not include:
                    stack.pop()
                    stack_lb.pop()

                    if not stack:
                        raise ValueError(f'[{LfuncName}]Group opener is missing for closer: `{x}`{at_pos}')

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

                    #900. Collect meta information
                    if meta_:
                        #100. Update all related nodes
                        #110. Determine the most recent <meta> along the stack, which matches current <closer>
                        #[ASSUMPTION]
                        #[1] A <closer> without a matching <opener> does not form a <node>, but only form a <segment>
                        len_nodes = len(stack_nodes)
                        for j in range(len_nodes-1, -1, -1):
                            target_node = stack_nodes[j]
                            if not target_node.get('closed', False):
                                #010. Locate the segment to be updated
                                seg_this = next(d for d in reversed(stack_segs) if d.get('node_id') == target_node['node_id'])

                                #100. Break if located
                                if target_node.get('pair_id', -1) == idx_rb:
                                    break

                                #300. Mark that <node> as unmatched, as it is wrapped by a complete pair of enclosers
                                target_node.update({'unmatched' : True})

                                #400. Update the dedicated segment
                                #[ASSUMPTION]
                                #[1] We do not correct the <parent_id> for any of the <segments> until the pairing <node_id>.
                                #    [1] For extensive usage of <META>, we could extract/highlight the <unmatched nodes> from
                                #         inside the raw string, together with all text <segments> tagged to them. So if we correct
                                #         these <segments>, it is difficult to identify them again. See [Full Test Program] #500 for
                                #         the related demonstration.
                                #[2] In case of many <unmatched nodes> are in between, we set the <end> of them to the same
                                seg_this.update({'end' : token_stats.at[enc_id, 'start']})

                        #150. Only complete the <node> when it is not marked as <unmatched>
                        if not target_node.get('unmatched', True):
                            #100. Update current node
                            closer_start = token_stats.at[enc_id, 'start']
                            closer_end = token_stats.at[enc_id, 'end']
                            target_node.update({
                                'closer_start' : closer_start
                                ,'closer_end' : closer_end
                                ,'closer_match' : x
                                ,'closed' : True
                                ,'span_start' : target_node['opener_start']
                                ,'span_end' : closer_end
                                ,'inner_start' : target_node.get('opener_end', None)
                                ,'inner_end' : closer_start
                            })

                            #200. Update the dedicated segment
                            seg_this.update({'end' : closer_end})
                elif strict_:
                    raise ValueError(f'[{LfuncName}]Group opener is missing for closer: `{x}`{at_pos}')
                else:
                    #900. Collect meta information
                    if meta_:
                        #200. Make it a normal text segment
                        len_nodes = len(stack_nodes)
                        for j in range(len_nodes-1, -1, -1):
                            target_node = stack_nodes[j]
                            if (not target_node.get('closed', False)) and (not target_node.get('unmatched', False)):
                                break
                        seg_id += 1
                        seg_this = {
                            'seg_id' : seg_id
                            ,'parent_id' : target_node['node_id']
                            ,'depth' : target_node['depth']
                            ,'start' : token_stats.at[enc_id, 'start']
                            ,'end' : token_stats.at[enc_id, 'end']
                            ,'type' : 'text'
                            ,'text' : x
                        }
                        stack_segs.append(seg_this)

            #900. Other types of text
            else:
                #100. Append to the stack
                stack[-1].append(x)

                #900. Collect meta information
                if meta_:
                    #200. Register current segment
                    #[ASSUMPTION]
                    #[1] Under this condition, <enc_id> has not been incremented, which means current segment of free text
                    #     is AFTER the dedicated <enc_id>
                    #[2] We only need to calculate the beginning of current segment out of the <end> of that <enc_id>
                    len_nodes = len(stack_nodes)
                    for j in range(len_nodes-1, -1, -1):
                        target_node = stack_nodes[j]
                        if (not target_node.get('closed', False)) and (not target_node.get('unmatched', True)):
                            break
                    seg_id += 1
                    seg_this = {
                        'seg_id' : seg_id
                        ,'parent_id' : target_node['node_id']
                        ,'depth' : target_node['depth']
                        ,'start' : 0 if enc_id == -1 else token_stats.at[enc_id, 'end']
                        ,'type' : 'text'
                        ,'text' : x
                    }
                    seg_this.update({'end' : seg_this['start'] + len(x)})
                    stack_segs.append(seg_this)

    #590. Raise if the numbers of left boundaries and right boundaries do not match
    if len(stack) > 1:
        at_pos = ''
        if meta_:
            first_unclosed = next(
                d for i,d in enumerate(stack_nodes)
                if i > 0 and (d.get('unmatched', True) or (not d.get('closed', False)))
            )
            at_pos = (
                ' for opener: `' + str(first_unclosed['opener_match'])
                + '` at position: <' + str(first_unclosed['opener_start']) + '>'
            )
        raise ValueError(f'[{LfuncName}]Group closer is missing{at_pos}')

    #595. Purge
    re.purge()

    #600. Emit the updated structure
    if not meta_:
        return({'RESULT' : stack.pop()})

    #700. Collect the meta information
    #701. Define the output standard
    #[ASSUMPTION]
    #[1] Nullable <int>: https://pandas.pydata.org/docs/dev/user_guide/integer_na.html
    field_types = {
        #100. For <nodes>
        'node_id' : 'Int64'
        ,'parent_id' : 'Int64'
        ,'depth' : 'Int64'
        ,'pair_id' : 'Int64'
        ,'opener_start' : 'Int64'
        ,'opener_end' : 'Int64'
        ,'closer_start' : 'Int64'
        ,'closer_end' : 'Int64'
        ,'span_start' : 'Int64'
        ,'span_end' : 'Int64'
        ,'inner_start' : 'Int64'
        ,'inner_end' : 'Int64'
        ,'closed' : bool
        ,'unmatched' : bool
        ,'opener_def' : str
        ,'closer_def' : str
        ,'opener_match' : str
        ,'closer_match' : str

        #200. For <segments>
        ,'seg_id' : 'Int64'
        ,'type' : str
        ,'start' : 'Int64'
        ,'end' : 'Int64'
        ,'text' : str

        #300. For <edges>
        ,'from_node' : 'Int64'
        ,'to_node' : 'Int64'
    }

    #710. Determine <nodes>
    nodes = [d for i,d in enumerate(stack_nodes) if i > 0 and (not d.get('unmatched', True))]
    kw_nodes = {'index' : [0]} if len(nodes) == 1 else {}
    col_nodes = [
        'node_id'
        ,'parent_id'
        ,'depth'
        ,'pair_id'
        ,'opener_def'
        ,'closer_def'
        ,'opener_match'
        ,'closer_match'
        ,'opener_start'
        ,'opener_end'
        ,'closer_start'
        ,'closer_end'
        ,'span_start'
        ,'span_end'
        ,'inner_start'
        ,'inner_end'
        ,'closed'
        ,'unmatched'
    ]

    #715. Determine the unclosed <nodes>, i.e. with a valid <opener> but it is deemed as content text
    nodes_unclosed = [d for i,d in enumerate(stack_nodes) if i > 0 and d.get('unmatched', True)]
    kw_nodes_unclosed = {'index' : [0]} if len(nodes_unclosed) == 1 else {}
    col_nodes_unclosed = [
        'node_id'
        ,'parent_id'
        ,'depth'
        ,'pair_id'
        ,'opener_def'
        ,'closer_def'
        ,'opener_match'
        ,'opener_start'
        ,'opener_end'
        ,'closed'
        ,'unmatched'
    ]

    #720. Determine <segments>
    kw_segs = {'index' : [0]} if len(stack_segs) == 1 else {}
    col_segs = [
        'seg_id'
        ,'parent_id'
        ,'depth'
        ,'type'
        ,'start'
        ,'end'
        ,'text'
        ,'node_id'
        ,'pair_id'
    ]

    #730. Determine <edges>
    edges = [
        {'from_node': r['parent_id'], 'to_node': r['node_id']}
        for r in stack_nodes
        if not r.get('unmatched', True)
    ]
    kw_edges = {'index' : [0]} if len(edges) == 1 else {}
    col_edges = [
        'from_node'
        ,'to_node'
    ]

    #989. Form the final <meta> collection
    meta = {
        'nodes' : (
            pd.DataFrame.from_records(nodes, **kw_nodes)
            .reindex(columns = col_nodes)
            .astype({
                k:v for k,v in field_types.items()
                if k in col_nodes
            })
        )
        ,'nodes_unclosed' : (
            pd.DataFrame.from_records(nodes_unclosed, **kw_nodes_unclosed)
            .reindex(columns = col_nodes_unclosed)
            .astype({
                k:v for k,v in field_types.items()
                if k in col_nodes_unclosed
            })
        )
        ,'segments' : (
            pd.DataFrame.from_records(stack_segs, **kw_segs)
            .reindex(columns = col_segs)
            .astype({
                k:v for k,v in field_types.items()
                if k in col_segs
            })
        )
        ,'edges' : (
            pd.DataFrame.from_records(edges, **kw_edges)
            .reindex(columns = col_edges)
            .astype({
                k:v for k,v in field_types.items()
                if k in col_edges
            })
        )
    }

    return({'RESULT' : stack.pop(), 'META' : meta})
#End strNestedParser

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import datetime as dt
    import pandas as pd
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
    print(ext_parens['RESULT'])
    # ['-- ', ['(', 'bb ', ['(', 'cc ', ['(', 'dd', ')'], ')'], ')'], ' aa ', ['(', 'ee ', ['(', 'ff', ')'], ')'], ' ~~']

    ext_jinja = strNestedParser(
        testjinja
        ,enclosers = {'{{' : '}}'}
        ,rx = False
    )
    print(ext_jinja['RESULT'])
    # ['-- ',
    #  ['{{', ' bb ', ['{{', ' cc', ['{{', ' dd ', '}}'], ' ', '}}'], ' ', '}}'],
    #  ' aa',
    #  ['{{', ' ee ', ['{{', ' ff ', '}}'], ' ', '}}']]

    ext_html = strNestedParser(
        testhtml
        ,enclosers = {r'<div.*?>' : r'</div>'}
        ,rx = True
    )
    print(ext_html['RESULT'])
    # [['<div a="1">',
    #  'bbb',
    #  ['<div id="2">', 'ccc ', '</div>'],
    #  ' ddd',
    #  ['<div id="3">', 'eee', '</div>'],
    #  'fff',
    #  '</div>'],
    # ' ggg']

    #300. Special cases
    print(strNestedParser('')['RESULT'])
    # []

    print(strNestedParser(r'a')['RESULT'])
    # ['a']

    print(strNestedParser(r'(a b)')['RESULT'])
    # [['(', 'a b', ')']]

    print(strNestedParser(r'a (b)')['RESULT'])
    # ['a ', ['(', 'b', ')']]

    print(strNestedParser(r'(a) b')['RESULT'])
    # [['(', 'a', ')'], ' b']

    print(strNestedParser(r'(a ((b) c (d))) e (f (g))')['RESULT'])
    # [['(', 'a ', ['(', ['(', 'b', ')'], ' c ', ['(', 'd', ')'], ')'], ')'], ' e ', ['(', 'f ', ['(', 'g', ')'], ')']]

    print(strNestedParser(r'(a ((b) c (d))) e (f (g))', include = False)['RESULT'])
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
    )['RESULT'])
    # ['-- ', ['(', 'bb ', ['[', 'cc ', ['(', 'dd', ')'], ']'], ')'], ' aa ', ['{', 'ee ', ['(', 'ff', ')'], '}'], ' ~~']

    print(strNestedParser(
        txt
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,include = False
    )['RESULT'])
    # [strNestedParser]Multiple enclosers are requested, [include] is set to True anyway.
    # ['-- ', ['(', 'bb ', ['[', 'cc ', ['(', 'dd', ')'], ']'], ')'], ' aa ', ['{', 'ee ', ['(', 'ff', ')'], '}'], ' ~~']

    #340. Unmatched enclosers
    txt2 = 'a [(b { c) [ (d} e) f ] g'

    print(strNestedParser(
        txt2
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
    # ValueError: [strNestedParser]Group closer is missing

    # Turn on <meta_> to see detailed exception
    print(strNestedParser(
        txt2
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,meta_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group closer is missing for opener: `[` at position: <2>

    txt3 = 'a (b { c) [ (d} e) f ] g'

    #[ASSUMPTION]
    #[1] The first opening '{' holds an open <node> without <closer>
    print(strNestedParser(
        txt3
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
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
    )['RESULT'])
    # ['a ', ['[', 'b', ']'], ' c ', ']']

    #[ASSUMPTION]
    #[1] When <strict_ = True>, if any closer misses its corresponding opener, exception will be raised
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = True
        ,strict_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group opener is missing for closer: `]`

    # Turn on <meta_> to see detailed exception
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = True
        ,strict_ = True
        ,meta_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group opener is missing for closer: `]` at position: <8>

    #[ASSUMPTION]
    #[1] When <include = False>, all enclosers are excluded from the result
    #[2] Hence if any closer misses its corresponding opener, exception will be raised
    #[3] In such case, <strict_> is ignored
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = False
    )['RESULT'])
    # ValueError: [strNestedParser]Group opener is missing for closer: `]`

    # Turn on <meta_> to see detailed exception
    print(strNestedParser(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = False
        ,meta_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group opener is missing for closer: `]` at position: <8>

    txt5 = 'a {b'

    #[ASSUMPTION]
    #[1] When the string is not closed by encloser, exception will be raised anyway
    #[2] Both <include> and <strict_> take no effect
    print(strNestedParser(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,include = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group closer is missing

    print(strNestedParser(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,include = False
    )['RESULT'])
    # ValueError: [strNestedParser]Group closer is missing

    # Turn on <meta_> to see detailed exception
    #[ASSUMPTION]
    #[1] Above two scenarios lead to the same detailed exception as below
    print(strNestedParser(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,meta_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group closer is missing for opener: `{` at position: <2>

    #360. Crossing enclosers
    cross1 = '[{aaa]}'

    print(strNestedParser(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
    # [['[', ['{', 'aaa'], ']'], '}']

    print(strNestedParser(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group opener is missing for closer: `}`

    # Turn on <meta_> to see detailed exception
    print(strNestedParser(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = True
        ,meta_ = True
    )['RESULT'])
    # ValueError: [strNestedParser]Group opener is missing for closer: `}` at position: <6>

    #500. Collect <META> information
    #501. Parse the string
    #[ASSUMPTION]
    #[1] the second opener `{` in below case can be wrapped by a complete pair of enclosers, so we set <strict_=False>
    unmatch_but_closable = 'a (b { c) [ (d} e) f ] g'
    unmatch_parsed = strNestedParser(
        unmatch_but_closable
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = False
        ,meta_ = True
    )

    #510. Calculate the parenting path
    parent_of = unmatch_parsed['META']['edges'].set_index('to_node')['from_node'].to_dict()
    def h_get_path(target_id : int, parents : dict[int, int], path_sep : str = '/') -> str:
        if not target_id or target_id == 0:
            return('0')
        chain: list[int] = []
        cur = int(target_id)
        guard = 0
        while cur and cur != 0:
            chain.insert(0, cur)
            nxt = parents.get(cur)
            if nxt is None:
                break
            cur = int(nxt)
            guard += 1
            if guard > 10000:
                break
        return path_sep.join(['0'] + [str(x) for x in chain])

    def h_apply_path(srs : pd.Series) -> str:
        if srs['type'] == 'node':
            return(h_get_path(srs['node_id'], parent_of))
        else:
            return(h_get_path(srs['parent_id'], parent_of))

    #[ASSUMPTION]
    #[1] <seg_id> 3 denotes the <unmatched node> '{...' at position 5. We use ellipsis as it does not know where to end
    #[2] <seg_id> 4 denotes the free text <segment> ' c', and its <parent_id> is 2 which is just the above <unmatched node>
    #[3] Glad that we did not update the <parent_id> of this text <segment> in the function to its corrected-parent, and now
    #     we have a chance to find its parent-to-be during the text segment highlighting for debug purpose
    paths = (
        unmatch_parsed['META']['segments']
        .apply(h_apply_path, axis = 1)
    )
    print(paths)
    # 0         0
    # 1       0/1
    # 2       0/1
    # 3       0/2
    # 4       0/2
    # 5         0
    # 6       0/3
    # 7       0/3
    # 8     0/3/4
    # 9     0/3/4
    # 10    0/3/4
    # 11    0/3/4
    # 12      0/3
    # 13        0
    # dtype: object

    #520. See <Styles.strNestedRenderer> for full test program of how to render the nested structure in HTML

    # [CPU] Intel Core i9-14900K 8-Core 5.00GHz
    # [RAM] 128GB DDR5 4800MHz
    #900. Test timing
    #910. Large string for RegExp
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    ext_large = strNestedParser(str_large, enclosers = {r'<div.*?>' : r'</div>'}, rx = True)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # 0:00:00.065996

    #930. Large string for plain enclosers
    #[ASSUMPTION]
    #[1] When the enclosers are plain texts, the function falls back to (x in patterns) which reduces Time Complexity
    str_large2 = txt * 10000
    time_bgn = dt.datetime.now()
    ext_large2 = strNestedParser(str_large2, enclosers = {'(' : ')', '{' : '}', '[' : ']'}, rx = False)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # 0:00:00.040994
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

### `path` of `segments` 规则
- 路径使用 `'/'` 连接节点 id，固定以根 `0` 开头，例如： `'0/3/4'`
- 对 `type = 'text'` ：路径定位到其 **父容器**： `0/.../parent_id`
- 对 `type = 'node'` ：路径定位到该 **节点自身**： `0/.../node_id`

## 推荐用法：四表联动
- **构树/分析层级**： `nodes + edges`
- **高亮/截取/覆盖统计**： `nodes + spans`
- **渲染/复原结构**： `segments` （递归按 `parent_id` 渲染）
- **BI 聚合**：按 `path` of `segments` 分组统计（如每条路径的文本长度/节点数量/深度分布）
'''
