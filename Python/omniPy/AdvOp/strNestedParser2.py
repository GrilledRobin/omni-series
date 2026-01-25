#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import pandas as pd
from typing import Optional

def strNestedParser2(
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
#   |This function is intended to parse the nested structures surrounded by the provided boundaries, same as <strNestedParser> but with #
#   | different approach.                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] See documentation of its counterparty <strNestedParser>                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |TERMINOLOGY                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] <re.split()> will split the raw string into a <list> with below convention, which is not described in the official document    #
#   |    [1] Starting from the first item, every <1 + M> items form a group, where                                                      #
#   |        [1] This <1> denotes a <substring> slicing the raw string from the start or the previous <encloser> to current one,        #
#   |             regardless of opener or closer. It is empty when the raw string starts from a matched <encloser>, but it only exists  #
#   |             when there is at least one match of <enclosers>                                                                       #
#   |        [2] This <M> denotes a sequence of the matches against the capturing groups (RegExp) of <enclosers> with no skip, the shape#
#   |             of which is as <[None,...,None,re.Match,None,...,None]>. Here the <re.Match> is the only one group that matches one   #
#   |             among all the capturing groups, while all the rest groups are <None>. E.g. when we provide enclosers as <{'(':')'}>   #
#   |             and there is one match for the opener at some position, then <M> at that position is <[re.Match,None]>; similarly,    #
#   |             if there is one match for the closer at some position, then <M> at that position is <[None,re.Match]>.                #
#   |    [2] There are <K * [1, M]> groups in the entire <list>, followed by an isolated substring <end>, where                         #
#   |        [1] This <K> denotes the number of all matches in the raw string, and it could be 0                                        #
#   |        [2] This <end> denotes the substring starting from the last matching <encloser> to the end of the raw string, it also could#
#   |             be empty, but it always exists in the parsed <list>                                                                   #
#   |    [3] Therefore, the general form of the <list> is <K * [1, M] + [1]> (all flattened and concatenated)                           #
#   |[2] In order to get the proper sequence during <re.split()>, we set the pattern as <((?:opener1))\u2502((?:closer1))\u2502...>     #
#   |    [1] All the openers and closers are combined together as one capturing pattern, which is different from <strNestedParser> for  #
#   |         the obvious purpose that we need their respective matching positions, so each one needs a capturing group                 #
#   |    [2] We neutralize the capturing group by setting an internal non-capturing pattern, to save the Auxiliary Space, because we do #
#   |         not need the pattern itself for the <re.Match>, as we already have its positional <ID> for retrieval elsewhere. This is   #
#   |         also why we only have to match once in this solution.                                                                     #
#   |    [3] As a fair point, such solution brings exactly <M> extra Auxiliary Space to every match in the raw string, and that is why  #
#   |         its Auxiliary Space is <O(m * n)> instead of <O(m + n)>. The overall system effort is tested to be 2 times of the basic   #
#   |         solution as <strNestedParser> on 3 pairs of <enclosers>, and it increases fast for more <enclosers>                       #
#   |[3] We leverage such feature of the <list>, to iterate only once over <range(K)>, and grab every <[1, M]> items at each iteration. #
#   |    [1] Directly append this <1> substring to the <stack> when it is not empty                                                     #
#   |    [2] Identify the <position> of the only item that is not <None> within the sequence of <M> sub-items, this <position> is just  #
#   |         where we locate the requested <encloser> as well                                                                          #
#   |    [3] The we operate on the <stack> in terms of the identified <encloser>, which is the same as that in <strNestedParser>        #
#   |[4] At last, there is an <end> substring, and we append it to the <stack> when it is not empty                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] By setting each of the enclosers as a capture group, the Auxiliary Space is <O(m * n)>, instead of <O(m + n)> of its           #
#   |     counterparty <strNestedParser>; the size of its <tokens> as split is exactly <m * n>                                          #
#   |[2] For the same setting, this function only match the input once, so the Time Complexity is <O(m * n)>; f.y.i that of its         #
#   |     counterparty <strNestedParser> is <O(m * n) ~ O(m * n * 1.5)>, where <n> is the number of <enclosers> including openers and   #
#   |     closers. With the number <n> far smaller than <m>, this saving is trivial.                                                    #
#   |[3] That is why we set this one as a toy function for study only, due to its poor efficiency on large number of <enclosers>.       #
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
#   |<dict>            :   Same as <strNestedParser>, see details in that function                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260104        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
    enclosers_len = len(enclosers) * 2
    enclosers_id = {}
    enclosers_pair = {}
    item_per_group = enclosers_len + 1

    for i,(k,v) in enumerate(enclosers.items()):
        enclosers_id[i * 2] = k
        enclosers_id[i * 2 + 1] = v
        #[ASSUMPTION]
        #[1] We set `closer` as the key to simplify the matching at later steps
        enclosers_pair[i * 2 + 1] = i * 2

    # priority: longer definition string first (heuristic; same as R version)
    enclosers_ord = {k:v for k,v in sorted(enclosers_id.items(), key = lambda x: len(x[1]), reverse = True)}
    enclosers_pos_to_id = {i:k for i,k in enumerate(enclosers_ord.keys())}
    ptn_bound = re.compile(
        '|'.join(['((?:{}))'.format(v if rx else re.escape(v)) for v in enclosers_ord.values()])
        ,flags = flags
    )

    #090. Prepare meta parameters
    #[ASSUMPTION]
    #[1] <dict> is ordered for Python >= 3.7
    if meta_:
        opener_pair_id = {v:i for i,(k,v) in enumerate(enclosers_pair.items())}
        closer_pair_id = {k:i for i,(k,v) in enumerate(enclosers_pair.items())}
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
    tokens_len = len(tokens)
    k_iter = tokens_len // item_per_group
    nil_match = len(tokens) == 0

    #300. Calculate the stats for the content as split
    if meta_:
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

            return(m.start(), m.end(), x_id, enclosers_id[x_id], x)

        #500. Collect them as a data frame
        #[ASSUMPTION]
        #[1] Abover iterator is a one-off object, i.e. destroyed immediately after one loop over it
        #[2] The result may have a length of 0 if there is no match
        #[3] <index> of below data frame is crucial for slicing at later steps, make sure it is set by default, starting from 0
        token_stats = (
            pd.DataFrame(
                [h_locEncloser(m) for m in ptn_bound.finditer(txt)]
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
    #501. Direct return if none among the enclosers is identified
    if nil_match:
        meta_nil = {'META' : {}} if meta_ else {}
        return({'RESULT' : tokens} | meta_nil)

    #550. Main process
    for k in range(k_iter):
        #010. Local environment
        group_bgn = k * item_per_group
        x_before = tokens[group_bgn]

        #100. Append the free text into the stack
        #[ASSUMPTION]
        #[1] `x_before` could be empty, while we would skip it
        if x_before:
            stack[-1].append(x_before)

            #900. Collect meta information
            if meta_:
                #200. Register current segment
                #[ASSUMPTION]
                #[1] Under this condition, <enc_id> has not been incremented, which means current segment of free text
                #     is AFTER the dedicated <enc_id>
                #[2] We only need to calculate the beginning of currnet segment out of the <end> of that <enc_id>
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
                    ,'text' : x_before
                }
                seg_this.update({'end' : seg_this['start'] + len(x_before)})
                stack_segs.append(seg_this)

        #200. Determine the enclosers that exactly match current token
        #[ASSUMPTION]
        #[1] There should be only one match for one pattern in one enclosers group
        x = None
        x_pos = -1
        while (x is None) and (x_pos < item_per_group):
            x_pos += 1
            x = tokens[group_bgn + x_pos + 1]

        x_ptn_id = enclosers_pos_to_id[x_pos]

        #400. Process if x is opener
        if x_ptn_id not in enclosers_pair:
            #100. Resister meta information
            if meta_:
                #100. Update current node
                enc_id += 1
                node_id += 1
                pair_id = opener_pair_id[x_ptn_id]
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
                    ,'pair_id' : pair_id
                    ,'closed' : False
                    ,'unmatched' : False
                    ,'opener_def' : x if not rx else enclosers_id[x_ptn_id]
                    ,'closer_def' : enclosers_id[{v:k for k,v in enclosers_pair.items()}[x_ptn_id]]
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
                    ,'pair_id' : pair_id
                    ,'text' : None
                }
                stack_segs.append(seg_this)

            #800. Nest a new list inside the current stack
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
            stack_lb[-1].append([x_ptn_id])
            stack_lb.append([x_ptn_id])
            continue

        #600. Process if x is closer
        else:
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
            id_rb = enclosers_pair[x_ptn_id]
            k = len(stack)
            found = False
            for i in range(k-1, -1, -1):
                if isinstance(stack[i][0], str):
                    if stack_lb[i][0] == id_rb:
                        found = True
                        break

            #500. Roll back to the substructure as found
            if found:
                del stack[(i+1):]
                del stack_lb[(i+1):]

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
                            if target_node.get('pair_id', -1) == closer_pair_id[x_ptn_id]:
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

            #600. Complete this substructure with current closer (and hence refresh all its references)
            stack[-1].append(x)

            #800. Pop the completed substructure, or raise if it cannot be completed as per request
            if found:
                stack.pop()
                stack_lb.pop()
            elif strict_:
                raise ValueError(f'[{LfuncName}]Group opener is missing for closer: `{x}`{at_pos}')
            else:
                #900. Collect meta information
                if meta_:
                    #200. Make it a normal text segment
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
                        ,'start' : token_stats.at[enc_id, 'start']
                        ,'end' : token_stats.at[enc_id, 'end']
                        ,'type' : 'text'
                        ,'text' : x
                    }
                    stack_segs.append(seg_this)

    #560. Append the last item as free text if any
    if (not nil_match) and tokens[-1]:
        stack[-1].append(tokens[-1])

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
                ,'text' : tokens[-1]
            }
            seg_this.update({'end' : seg_this['start'] + len(tokens[-1])})
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
#End strNestedParser2

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
    from omniPy.AdvOp import strNestedParser2

    #100. Prepare strings
    teststr = '-- (bb (cc (dd))) aa (ee (ff)) ~~'
    testjinja = '-- {{ bb {{ cc{{ dd }} }} }} aa{{ ee {{ ff }} }}'
    testhtml = '<div a="1">bbb<div id="2"> ccc</div>ddd <div id="3">eee</div>fff</div> ggg'

    #200. Extraction
    ext_parens = strNestedParser2(
        teststr
        ,enclosers = {'(' : ')'}
        ,rx = False
    )
    print(ext_parens['RESULT'])
    # ['-- ', ['(', 'bb ', ['(', 'cc ', ['(', 'dd', ')'], ')'], ')'], ' aa ', ['(', 'ee ', ['(', 'ff', ')'], ')'], ' ~~']

    ext_jinja = strNestedParser2(
        testjinja
        ,enclosers = {'{{' : '}}'}
        ,rx = False
    )
    print(ext_jinja['RESULT'])
    # ['-- ',
    #  ['{{', ' bb ', ['{{', ' cc', ['{{', ' dd ', '}}'], ' ', '}}'], ' ', '}}'],
    #  ' aa',
    #  ['{{', ' ee ', ['{{', ' ff ', '}}'], ' ', '}}']]

    ext_html = strNestedParser2(
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
    print(strNestedParser2('')['RESULT'])
    # []

    print(strNestedParser2(r'a')['RESULT'])
    # ['a']

    print(strNestedParser2(r'(a b)')['RESULT'])
    # [['(', 'a b', ')']]

    print(strNestedParser2(r'a (b)')['RESULT'])
    # ['a ', ['(', 'b', ')']]

    print(strNestedParser2(r'(a) b')['RESULT'])
    # [['(', 'a', ')'], ' b']

    print(strNestedParser2(r'(a ((b) c (d))) e (f (g))')['RESULT'])
    # [['(', 'a ', ['(', ['(', 'b', ')'], ' c ', ['(', 'd', ')'], ')'], ')'], ' e ', ['(', 'f ', ['(', 'g', ')'], ')']]

    print(strNestedParser2(r'(a ((b) c (d))) e (f (g))', include = False)['RESULT'])
    # [['a ', [['b'], ' c ', ['d']]], ' e ', ['f ', ['g']]]

    #330. Multiple enclosers
    txt = '-- (bb [cc (dd)]) aa {ee (ff)} ~~'

    #[ASSUMPTION]
    #[1] There are multiple enclosers to identify, hence the output result should include all enclosers
    #[2] <include> is forced to be True regardless of user request
    print(strNestedParser2(
        txt
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
    # ['-- ', ['(', 'bb ', ['[', 'cc ', ['(', 'dd', ')'], ']'], ')'], ' aa ', ['{', 'ee ', ['(', 'ff', ')'], '}'], ' ~~']

    print(strNestedParser2(
        txt
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,include = False
    )['RESULT'])
    # [strNestedParser2]Multiple enclosers are requested, [include] is set to True anyway.
    # ['-- ', ['(', 'bb ', ['[', 'cc ', ['(', 'dd', ')'], ']'], ')'], ' aa ', ['{', 'ee ', ['(', 'ff', ')'], '}'], ' ~~']

    #340. Unmatched enclosers
    txt2 = 'a [(b { c) [ (d} e) f ] g'

    print(strNestedParser2(
        txt2
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
    # ValueError: [strNestedParser2]Group closer is missing

    txt3 = 'a (b { c) [ (d} e) f ] g'

    #[ASSUMPTION]
    #[1] The first opening '{' holds an open <node> without <closer>
    print(strNestedParser2(
        txt3
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
    # ['a ', ['(', 'b ', ['{', ' c'], ')'], ' ', ['[', ' ', ['(', 'd', '}', ' e', ')'], ' f ', ']'], ' g']

    txt4 = 'a [b] c ]'

    #[ASSUMPTION]
    #[1] When <include = True> and <strict_ = False>, all enclosers are included in the result
    #[2] Hence if any closer misses its corresponding opener, it will be treated as a normal text
    print(strNestedParser2(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = True
        ,strict_ = False
    )['RESULT'])
    # ['a ', ['[', 'b', ']'], ' c ', ']']

    #[ASSUMPTION]
    #[1] When <strict_ = True>, if any closer misses its corresponding opener, exception will be raised
    print(strNestedParser2(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = True
        ,strict_ = True
    )['RESULT'])
    # ValueError: [strNestedParser2]Group opener is missing for closer: `]`

    #[ASSUMPTION]
    #[1] When <include = False>, all enclosers are excluded from the result
    #[2] Hence if any closer misses its corresponding opener, exception will be raised
    #[3] In such case, <strict_> is ignored
    print(strNestedParser2(
        txt4
        ,enclosers = {'[' : ']'}
        ,rx = False
        ,include = False
    )['RESULT'])
    # ValueError: [strNestedParser2]Group opener is missing for closer: `]`

    txt5 = 'a {b'

    #[ASSUMPTION]
    #[1] When the string is not closed by encloser, exception will be raised anyway
    #[2] Both <include> and <strict_> take no effect
    print(strNestedParser2(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,include = True
    )['RESULT'])
    # ValueError: [strNestedParser2]Group closer is missing

    print(strNestedParser2(
        txt5
        ,enclosers = {'{' : '}'}
        ,rx = False
        ,include = False
    )['RESULT'])
    # ValueError: [strNestedParser2]Group closer is missing

    #360. Crossing enclosers
    cross1 = '[{aaa]}'

    print(strNestedParser2(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
    )['RESULT'])
    # [['[', ['{', 'aaa'], ']'], '}']

    print(strNestedParser2(
        cross1
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = True
    )['RESULT'])
    # ValueError: [strNestedParser2]Group opener is missing for closer: `}`

    #500. Compare to the basic function
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
    unmatch_parsed2 = strNestedParser2(
        unmatch_but_closable
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = False
        ,meta_ = True
    )

    assert unmatch_parsed['RESULT'] == unmatch_parsed2['RESULT']
    assert unmatch_parsed['META']['nodes'].eq(unmatch_parsed2['META']['nodes']).all(axis = None)
    assert unmatch_parsed['META']['nodes_unclosed'].eq(unmatch_parsed2['META']['nodes_unclosed']).all(axis = None)
    assert unmatch_parsed['META']['segments'].eq(unmatch_parsed2['META']['segments']).all(axis = None)

    # [CPU] Intel Core i9-14900K 8-Core 5.00GHz
    # [RAM] 128GB DDR5 4800MHz
    #900. Test timing
    #910. Large string for RegExp
    str_large = testhtml * 10000
    time_bgn = dt.datetime.now()
    ext_large = strNestedParser2(str_large, enclosers = {r'<div.*?>' : r'</div>'}, rx = True)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # 0:00:00.039709

    #930. Large string for plain enclosers
    #[ASSUMPTION]
    #[1] When the enclosers are plain texts, the function falls back to (x in patterns) which reduces Time Complexity
    str_large2 = txt * 10000
    time_bgn = dt.datetime.now()
    ext_large2 = strNestedParser2(str_large2, enclosers = {'(' : ')', '{' : '}', '[' : ']'}, rx = False)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # best result
    # 0:00:00.088001
#-Notes- -End-
'''

'''
#-Terminology- -Begin-
see <strNestedParser>
'''
