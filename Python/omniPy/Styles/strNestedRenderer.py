#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import html
import pandas as pd
from typing import Optional, Any
from collections.abc import Iterable
from functools import partial

def strNestedRenderer(
    txt : str
    ,meta : dict[str, pd.DataFrame]
    ,*
    ,include : bool = True
    ,colorBy : str = 'pair_id'
    ,palette : Iterable[str] = ['#fff3b0', '#cce5ff', '#d4edda', '#f8d7da', '#e2d6f9', '#d1ecf1']
    ,alpha : float = 0.55
    ,alphaBorder : float = 0.95
    ,collapsible : bool = True
    ,collapsed : bool = False
    ,showTooltip : bool = True
    ,wrap : str = 'all'
    ,fromRoot : int = 0
    ,body_ids : Optional[Iterable[Any]] = None
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is to render the character string as HTML, with each piece surrounded by pairing enclosers, e.g. parentheses and/or  #
#   | brackets, highlighted in different background colors.                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The argument <meta> should be provided with the one extracted by <AdvOp.strNestedParser> for the same <txt>                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |txt               :   <str     > Character string to be rendered                                                                   #
#   |meta              :   <dict    > Dedicated <META> information collection for rendering, should be <dict[str, pd.DataFrame]> as     #
#   |                                  extracted from <txt> via the core function <AdvOp.strNestedParser>                               #
#   |include           :   <bool    > Whether to include the enclosers in the output result.                                            #
#   |                      [True                ] <Default> Include the bounds as output                                                #
#   |                      [False               ]           Exclude the bounds as output                                                #
#   |colorBy           :   <str     > Render different colors for segments on which strategy                                            #
#   |                      [pair_id             ] <Default> Differ the color setting by <pair_id> as indicated in the meta information  #
#   |                      [depth               ]           Render different colors based on <depth> of each structure                  #
#   |palette           :   <Iterable> Iterable of HEX color codes to render different <segment>s                                        #
#   |                      [<see def.>          ] <Default> Use a series of colors to differ the <segment>s in the result               #
#   |                      [<Iterable[str]>     ]           Iterable of color codes                                                     #
#   |alpha             :   <float   > Transparency of the rendered background color, between 0 and 1                                    #
#   |                      [<see def.>          ] <Default> Set certain transparency for the highlighting                               #
#   |                      [<float>             ]           Other <float> number that is between 0 and 1                                #
#   |alphaBorder       :   <float   > Transparency of the border for the <unmatched nodes> if any, between 0 and 1                      #
#   |                      [<see def.>          ] <Default> Set certain transparency for the highlighting                               #
#   |                      [<float>             ]           Other <float> number that is between 0 and 1                                #
#   |collapsible       :   <bool    > Whether to set the <node>s as collapsible with interactivity                                      #
#   |                      [True                ] <Default> Set the <node>s as collapsible                                              #
#   |                      [False               ]           Disable the collapse and only display the content                           #
#   |collapsed         :   <bool    > Whether to display the <node>s as collapsed at the initial view, given <collapsible=True>         #
#   |                      [False               ] <Default> Fully expand all <node>s at initial view                                    #
#   |                      [True                ]           Show all <node>s as collapsed at initial view                               #
#   |showTooltip       :   <bool    > Whether to show a tooltip on hovering the <node>s with a bunch of stats for investigation         #
#   |                      [True                ] <Default> Show tooltip when hover the mouse over the <node>s                          #
#   |                      [False               ]           Suppress the tooltip                                                        #
#   |wrap              :   <str     > How to generate the output result                                                                 #
#   |                      [all                 ] <Default> Create the result as a complete HTML with certain <CSS> and <JS> tools      #
#   |                      [fragment            ]           Only prepare the content and leave the <CSS> and <JS>. This is useful when  #
#   |                                                        rendering a list of strings while there is no need to attach <CSS> and <JS>#
#   |                                                        scripts for all of them                                                    #
#   |fromRoot          :   <int     > Starting from which <node> to its all child <node>s should the rendering be done                  #
#   |                      [int <0>             ] <Default> Render the entire <txt>, i.e. starting from <node_id=0>                     #
#   |                      [<int>               ]           Render the provided <node_id> and all its child <node>s                     #
#   |body_ids          :   <Iterable> Iterable of any objects that can be coerced to character string representation, indicating the    #
#   |                       globally unique <body_id> of each colored section                                                           #
#   |                      [None                ] <Default> Do not provide this, so the function calculates for it                      #
#   |                      [<Iterable[Any]>     ]           Iterable of objects that can be coerced to character string representation  #
#   |                                                        matching all the sections to render, usually <str> or <int>                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |990.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str >            :   The result rendered into HTML string representation                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260110        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, html, pandas, functools                                                                                                   #
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
        return('')
    if not isinstance(include, bool):
        raise TypeError(f'[{LfuncName}]<include>:<{type(include)}> must be provided a bool!')
    if colorBy not in ('pair_id','depth'):
        raise NotImplementedError(f'[{LfuncName}]<{colorBy=!r}> is not recognized!')
    if not isinstance(collapsible, bool):
        raise TypeError(f'[{LfuncName}]<collapsible>:<{type(collapsible)}> must be provided a bool!')
    if not isinstance(collapsed, bool):
        raise TypeError(f'[{LfuncName}]<collapsed>:<{type(collapsed)}> must be provided a bool!')
    if not isinstance(showTooltip, bool):
        raise TypeError(f'[{LfuncName}]<showTooltip>:<{type(showTooltip)}> must be provided a bool!')
    if wrap not in ('all','fragment'):
        raise NotImplementedError(f'[{LfuncName}]<{wrap=!r}> is not recognized!')
    has_body_id = body_ids is not None
    if has_body_id:
        if not isinstance(body_ids, Iterable):
            raise TypeError(f'[{LfuncName}]<body_ids>:<{type(body_ids)}> must be provided an Iterable of unique values!')
        if len(set(body_ids)) != len(body_ids):
            raise TypeError(f'[{LfuncName}]<body_ids>:<{type(body_ids)}> must be provided an Iterable of unique values!')

    #100. Collect information of all <node>s
    nodes_all = pd.concat([v for k,v in meta.items() if k in ('nodes','nodes_unclosed')], ignore_index = True)

    #110. Customize the <body_id> as required by <JS>
    n_nodes = len(nodes_all)
    len_body_ids = len(body_ids) if has_body_id else 0
    if n_nodes > 0:
        if has_body_id:
            if len_body_ids != n_nodes:
                raise ValueError(f'[{LfuncName}]<body_ids>:<{len_body_ids}> should match the rows in <nodes_all>:<{n_nodes}>!')
            nodes_all['provided_id'] = [v for v in body_ids]
        else:
            nodes_all['provided_id'] = nodes_all['node_id'].astype(str)
    else:
        if len_body_ids != 1:
            err_body_id = ','.join(body_ids)
            raise ValueError(f'[{LfuncName}]<body_ids>:<{err_body_id}> for <txt> without node should be a single value!')
        nodes_all['provided_id'] = nodes_all['node_id'].astype(str)

    #200. Define helper functions
    #210. Function to convert the HEX color codes into representation of JS function call <rgba()>
    def h_hex_to_rgba(row : pd.Series, alpha : float) -> str:
        return(f'rgba({row[0]}, {row[1]}, {row[2]}, {alpha:.3f})')

    #230. Function to obtain the fields from another dataframe as a step in the chain of operations upon <pd.DataFrame>
    #[ASSUMPTION]
    #[1] This is to avoid <merge()> dataframes on columns that are NOT indexes, to reduce system effort by over 90%
    def h_joinCol(this : pd.DataFrame, df : pd.DataFrame, col : str, idx = 'node_id', fillval = None):
        srs = (
            df
            .set_index(idx)
            .reindex(this.set_index(idx).index)
            .set_index(this.index)
            [col]
        )

        if fillval is not None:
            srs = srs.where(srs.notnull(), fillval)

        return(srs)

    #250. Function to get the substring from the raw input if current segment is <unknown>
    def h_get_unknown(row : pd.Series, from_str : str) -> str:
        if pd.isnull(row['start']) or pd.isnull(row['end']):
            return('')
        if row['start'] > row['end']:
            return('')
        return(from_str[row['start'] : row['end']])

    #270. Function to render the result in recursion
    def h_render(pid : int, store : dict[int, pd.DataFrame]) -> str:
        if pid not in store:
            return('')
        grp = (
            store.get(pid)
            .assign(**{
                'inner' : lambda x: (
                    x['node_id']
                    .map(partial(h_render, store = store), na_action = 'ignore')
                )
            })
            .assign(**{
                'rst' : lambda x: (
                    x['span_open']
                    .add(x['part_summary'])
                    .add(x['part_preview'])
                    .add(x['part_collapsible'])
                    .add(x['opener'])
                    .add(x['inner'])
                    .add(x['closer'])
                    .add(x['part_collapsible_close'])
                    .add(x['span_close'])
                    .where(
                        ~x['is_node'].eq(False)
                        ,x['text']
                    )
                    .where(
                        ~x['is_unknown'].eq(True)
                        ,(
                            x.apply(h_get_unknown, from_str = txt, axis = 1)
                            .map(html.escape, na_action = 'ignore')
                            .radd('<span class="ec-unknown">')
                            .add('</span>')
                        )
                    )
                )
            })
        )
        return(''.join(grp['rst']))

    #300. Prepare colors for the <node>s
    #[ASSUMPTION]
    #[1] When there is no <segment> wrapped inside any among the <enclosers>, <nodes_all> would be empty and <str.extractall()>
    #     fails to create consistent shape of result
    if len(nodes_all) == 0:
        node_css = (
            nodes_all
            .reindex(columns = ['node_id','pair_id','depth','color','leftw','bg','bd','node_CSS'])
            .astype({
                'color' : str
                ,'leftw' : str
                ,'bg' : str
                ,'bd' : str
                ,'node_CSS' : str
            })
        )
    else:
        node_css = (
            nodes_all
            .loc[:, ['node_id','pair_id','depth']]
            .assign(**{
                'color' : lambda x: x[colorBy].mod(len(palette)).map({i:v for i,v in enumerate(palette)})
                ,'leftw' : lambda x: x['depth'].where(~x['depth'].gt(4), 4).add(1)
            })
            .assign(**{
                'bg' : lambda x: (
                    x['color']
                    .str.strip()
                    .str.lstrip('#')
                    .str.extractall(r'(.{2})')[0]
                    .unstack()
                    .map(int, base = 16)
                    .apply(h_hex_to_rgba, alpha = alpha, axis = 1)
                )
                ,'bd' : lambda x: (
                    x['color']
                    .str.strip()
                    .str.lstrip('#')
                    .str.extractall(r'(.{2})')[0]
                    .unstack()
                    .map(int, base = 16)
                    .apply(h_hex_to_rgba, alpha = alphaBorder, axis = 1)
                )
            })
            .assign(**{
                'node_CSS' : lambda x: (
                    x['bg']
                    .radd('background: ').add(';')
                    .add('border: 1px solid ').add(x['bd']).add(';')
                    .add('border-left-width: ').add(x['leftw'].astype(str)).add('px;')
                    .add('border-radius: 4px;')
                    .add('padding: 0px 2px;')
                    .add('margin: 0px 1px;')
                    .add('white-space: pre-wrap;')
                )
            })
        )

    #500. Prepare the segments data for render
    seg_for_render = (
        meta['segments']
        .assign(**{
            'include' : include
            ,'colorBy' : colorBy
            ,'showTooltip' : showTooltip
            ,'collapsible' : collapsible
            ,'collapsed' : collapsed
            ,'node_CSS' : lambda x: (
                node_css
                .set_index('node_id')
                .reindex(x['node_id'])
                .set_index(x.index)
                ['node_CSS']
            )
        })
        .assign(**{
            v : partial(h_joinCol, df = nodes_all, col = v)
            for v in ('opener_match','closer_match','span_start','span_end','closed','provided_id')
        })
        .assign(**{
            'is_node' : lambda x: ~(x['type'].isin(['text']))
        })
        .assign(**{
            'is_collapsible_node' : lambda x: x['is_node'].eq(True) & x['collapsible'].eq(True) & x['closed'].eq(True)
            ,'is_unknown' : lambda x: ~(x['type'].isin(['text']) | x['node_id'].isin(meta['nodes']['node_id']))
        })
        .assign(**{
            'opener' : lambda x: (
                x['opener_match']
                .map(html.escape, na_action = 'ignore')
                .where(
                    x['include']
                    ,''
                )
                .fillna('')
            )
            ,'closer' : lambda x: (
                x['closer_match']
                .map(html.escape, na_action = 'ignore')
                .where(
                    x['include']
                    ,''
                )
                .fillna('')
            )
        })
        .assign(**{
            'tooltip' : lambda x: (
                x['node_id'].astype(str)
                .radd('title="node=').add(' ')
                .add('parent=').add(x['parent_id'].astype(str)).add(' ')
                .add('depth=').add(x['depth'].astype(str)).add(' ')
                .add('pair=').add(x['pair_id'].astype(str)).add(' ')
                .add('closed=').add(x['closed'].astype(str)).add(' ')
                .add('colorBy=').add(x['colorBy']).add(' ')
                .add('[').add(x['span_start'].astype(str)).add(', ').add(x['span_end'].astype(str)).add(']')
                .add('"')
                .where(
                    ~x['is_node'].eq(False)
                    ,''
                )
            )
        })
        .assign(**{
            'body_id' : lambda x: x['provided_id'].astype(str).radd('ec_body_')
            ,'marker' : lambda x: x['collapsed'].map({True : '&#9656;', False : '&#9662;'})
            ,'body_disp' : lambda x: x['collapsed'].map({True : 'none', False : 'inline'})
            ,'preview' : lambda x: (
                x['opener'].fillna('')
                .add('<span class="ec-ellipsis">…</span>')
                .add(x['closer'].fillna(''))
                .where(
                    x['include']
                    ,'<span class="ec-ellipsis">…</span>'
                )
                .where(
                    ~x['is_node'].eq(False)
                    ,''
                )
            )
            ,'span_open' : lambda x: (
                x['collapsible']
                .map({True : ' ec-collapsible', False : ''})
                .radd('<span class="ec-node')
                .add(' ').add('ec-depth-').add(x['depth'].astype(str))
                .add(' ').add('ec-pair-').add(x['pair_id'].astype(str))
                .add('"')
                .add(' ').add(x['tooltip'])
                .add(' ').add('data-node="').add(x['node_id'].astype(str)).add('"')
                .add(' ').add('data-parent="').add(x['parent_id'].astype(str)).add('"')
                .add(' ').add('data-depth="').add(x['depth'].astype(str)).add('"')
                .add(' ').add('data-pair="').add(x['pair_id'].astype(str)).add('"')
                .add(' ').add('style="').add(x['node_CSS'].astype(str)).add('"')
                .add('>')
                .where(
                    ~x['is_node'].eq(False)
                    ,''
                )
            )
            ,'span_close' : lambda x: (
                x['is_node']
                .map({True : '</span>', False : ''})
            )
        })
        .assign(**{
            'part_summary' : lambda x: (
                x['body_id']
                .radd('<span class="ec-summary" onclick="ecToggle(\'').add('\', this)">')
                .add(x['marker'])
                .add('</span>')
                .where(
                    ~x['is_collapsible_node'].eq(False)
                    ,''
                )
            )
            ,'part_preview' : lambda x: (
                x['preview']
                .radd('<span class="ec-preview">')
                .add('</span>')
                .where(
                    ~x['is_collapsible_node'].eq(False)
                    ,''
                )
            )
            ,'part_collapsible' : lambda x: (
                x['body_id']
                .radd('<span id="').add('"')
                .add(' ').add('class="ec-body" style="display:').add(x['body_disp']).add(';">')
                .where(
                    ~x['is_collapsible_node'].eq(False)
                    ,''
                )
            )
            ,'part_collapsible_close' : lambda x: (
                x['is_collapsible_node']
                .map({True : '</span>', False : ''})
            )
        })
    )

    #600. Render
    #610. Split the <segments> by <parent_id>, as a necessity for recursive calculation
    segs_by_parent = {k:grp for k,grp in seg_for_render.groupby('parent_id')}

    #680. Conduct the calculation in terms of the request
    rstOut = h_render(fromRoot, store = segs_by_parent)

    #690. Return the body as requested
    if wrap == 'fragment':
        return(f'<div class="ec-root">{rstOut}</div>')

    #800. Prepare necessary styles for the output
    css = (
        '<style>'
        '.ec-root{font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, '
        '"Liberation Mono", "Courier New", monospace;'
        'font-size:12px; line-height:1.6; white-space:pre-wrap; word-break:break-word;}'
        '.ec-node{box-decoration-break:clone; -webkit-box-decoration-break:clone;}'
        '.ec-summary{cursor:pointer; user-select:none; font-weight:700; padding:0 2px;}'
        '.ec-preview{opacity:0.65;}'
        '.ec-ellipsis{padding:0 1px;}'
        '.ec-body{white-space:pre-wrap;}'
        '.ec-unknown{background:rgba(200,200,200,0.35); border:1px dashed rgba(120,120,120,0.8);'
        'border-radius:4px; padding:0px 2px;}'
        '</style>'
    )
    js =(
        '<script>'
        'function ecToggle(id, el){'
        '  var body=document.getElementById(id); if (!body) return;'
        '  var isHidden=(body.style.display==="none");'
        '  body.style.display=isHidden?"inline":"none";'
        '  if(el){el.innerHTML=isHidden?"&#9662;":"&#9656;";}'
        '}'
        '</script>'
    )

    #990. Return full HTML
    return(css + js + f'<div class="ec-root">{rstOut}</div>')
#End strNestedRenderer

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import os
    import pandas as pd
    from collections.abc import Iterable
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import strNestedParser
    from omniPy.Styles import strNestedRenderer

    out_html = r'D:\Temp\nestedEnclosers.html'

    #100. Collect <META> information
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

    #200. Test the render result
    unmatch_rendered = strNestedRenderer(
        unmatch_but_closable
        ,meta = unmatch_parsed['META']
        ,colorBy = 'pair_id'
    )

    #209. Directly output an HTML file
    with open(out_html, 'w', encoding = 'utf-8') as f:
        f.write(unmatch_rendered)

    #300. Test the color by <depth>
    unmatch_by_depth = strNestedRenderer(
        unmatch_but_closable
        ,meta = unmatch_parsed['META']
        ,colorBy = 'depth'
    )

    #309. Directly output an HTML file
    with open(out_html, 'w', encoding = 'utf-8') as f:
        f.write(unmatch_by_depth)

    #400. Only render the first valid <node>
    unmatch_node1 = strNestedRenderer(
        unmatch_but_closable
        ,meta = unmatch_parsed['META']
        ,fromRoot = 1
    )

    #409. Directly output an HTML file
    with open(out_html, 'w', encoding = 'utf-8') as f:
        f.write(unmatch_node1)

    #500. Render a plain text without any enclosers
    #[ASSUMPTION]
    #[1] The result is plain text without highlighting
    txt_parsed = strNestedParser(
        'abc'
        ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
        ,rx = False
        ,strict_ = False
        ,meta_ = True
    )
    txt_rendered = strNestedRenderer(
        'abc'
        ,meta = txt_parsed['META']
        ,colorBy = 'pair_id'
    )

    #509. Directly output an HTML file
    with open(out_html, 'w', encoding = 'utf-8') as f:
        f.write(txt_rendered)

    #700. Render a series of texts
    vec_mapper = {
        'normal' : '-- (bb [cc (dd)]) aa {ee (ff)} ~~'
        ,'plain' : 'ab'
        ,'enclosed' : '(a b)'
        ,'hijacked' : 'a (b { c) [ (d} e) f ] g'
        ,'unmatched' : 'a [b] c ]'
        ,'crossing' : '[{aaa]}'
        ,'empty' : ''
    }
    testvec = pd.Series(vec_mapper.values(), index = vec_mapper.keys())

    #730. Parse the vector
    vec_parsed_meta = (
        testvec
        .apply(
            strNestedParser
            ,enclosers = {'(' : ')', '{' : '}', '[' : ']'}
            ,rx = False
            ,strict_ = False
            ,meta_ = True
        )
        .apply(lambda row: row['META'])
    )

    #750. Prepare correct parameters
    #[ASSUMPTION]
    #[1] We need them to be rendered in one HTML file, so the <CSS> and <JS> scripts should only be exported once
    #[2] <body_id> of all the nodes should be globally unique
    wrap_mod = pd.Series(['fragment' for v in vec_mapper], index = testvec.index)
    wrap_mod.iat[0] = 'all'

    #770. Helper functions
    def h_get_k_ids(df : pd.DataFrame):
        k_ids = len(df['segments'].loc[lambda t: t['type'].isin(['node'])])
        if k_ids == 0:
            return(1)
        else:
            return(k_ids)

    def h_render(row : pd.Series):
        return(strNestedRenderer(
            row['txt']
            ,meta = row['meta']
            ,colorBy = 'pair_id'
            ,wrap = row['wrap']
            ,body_ids = row['body_ids']
        ))

    #780. Render
    vec_df = (
        pd.concat([testvec, vec_parsed_meta, wrap_mod], axis = 1, ignore_index = False)
        .rename(columns = {i:v for i,v in enumerate(['txt', 'meta', 'wrap'])})
        #[ASSUMPTION]
        #[1] This is to demonstrate how to prepare the globally unique <body_id> out of the META information table
        .assign(**{
            'ids_end' : lambda x: (
                x['meta']
                .apply(h_get_k_ids)
                .cumsum()
            )
        })
        .assign(**{
            'ids_bgn' : lambda x: x['ids_end'].shift(1).fillna(0).astype(int)
        })
        .assign(**{
            'body_ids' : lambda x: x.apply(lambda row: list(range(row['ids_bgn'], row['ids_end'])), axis = 1)
        })
        .assign(**{
            'rendered' : lambda x: x.apply(h_render, axis = 1)
        })
    )

    #790. Export
    with open(out_html, 'w', encoding = 'utf-8') as f:
        f.write('<br />'.join(vec_df['rendered'].to_list()))

    #990. Garbage collection
    if os.path.isfile(out_html): os.remove(out_html)

#-Notes- -End-
'''
