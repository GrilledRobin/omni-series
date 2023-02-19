#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
#We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings < 0.27.15] and [Python <= 3.7]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import xlwings as xw
import inspect
from inspect import signature
from functools import reduce
from collections.abc import Iterable
from typing import Union, Optional
from omniPy.AdvOp import pandasParseIndexer, modifyDict, pandasPivot, xwRangeAsGroup, xwDfToRange

def xwGroupForDf(
    rng : xw.Range
    ,df : pd.DataFrame
    ,index : bool = [
        s.default
        for s in signature(xwDfToRange).parameters.values()
        if s.name == 'index'
    ][0]
    ,index_name : bool = [
        s.default
        for s in signature(xwDfToRange).parameters.values()
        if s.name == 'index_name'
    ][0]
    ,header : bool = [
        s.default
        for s in signature(xwDfToRange).parameters.values()
        if s.name == 'header'
    ][0]
    ,mergeIdx : Union[bool, int, Iterable[Optional[int]]] = [
        s.default
        for s in signature(xwDfToRange).parameters.values()
        if s.name == 'mergeIdx'
    ][0]
    ,mergeHdr : Union[bool, int, Iterable[Optional[int]]] = [
        s.default
        for s in signature(xwDfToRange).parameters.values()
        if s.name == 'mergeHdr'
    ][0]
    ,kw_pvtLike : dict = {
        s.name : s.default
        for s in signature(pandasPivot).parameters.values()
        if reduce(lambda x,y:x|y, map(lambda v: s.name.startswith(v), ['pos','row','col','fRow','fCol']))
    }
    ,kw_asGroup : dict = {
        s.name : s.default
        for s in signature(xwRangeAsGroup).parameters.values()
        if s.default is not inspect._empty
    }
    ,asformatter : bool = False
    ,formatOnly : bool = False
    ,idxall : str = [
        s.default
        for s in signature(xwDfToRange).parameters.values()
        if s.name == 'idxall'
    ][0]
) -> None:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to add groups and outlines during the export of a pivot table to EXCEL                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Often work together with [pandasPivot] and [xwDfToRange] to create EXCEL report with fancy effects                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |rng         :   EXCEL range object, in which to pour the data                                                                      #
#   |df          :   Data frame to be output to [rng], from which also to extract sub-ranges for styling                                #
#   |index       :   Logical value indicating whether to export [df.index] as well                                                      #
#   |                [<see def.>  ] <Default> See definition of [xwDfToRange]                                                           #
#   |index_name  :   Logical value indicating whether to keep [df.index.names] during export                                            #
#   |                [<see def.>  ] <Default> See definition of [xwDfToRange]                                                           #
#   |header      :   Logical value indicating whether to export [df.columns] as well                                                    #
#   |                [<see def.>  ] <Default> See definition of [xwDfToRange]                                                           #
#   |mergeIdx    :   Various value indicating whether to merge vertically adjacent cells with the same values in [df.index], or such    #
#   |                 cells in any provided [levels] of [df.index]                                                                      #
#   |                [<see def.>  ] <Default> See definition of [xwDfToRange]                                                           #
#   |mergeHdr    :   Various value indicating whether to merge horizontally adjacent cells with the same values in [df.columns], or such#
#   |                 cells in any provided [levels] of [df.columns]                                                                    #
#   |                [<see def.>  ] <Default> See definition of [xwDfToRange]                                                           #
#   |kw_pvtLike  :   Keyword arguments from [pandasPivot] to calculate the groupers                                                     #
#   |                [<see def.>  ] <Default> See definition of [pandasPivot]                                                           #
#   |kw_asGroup  :   Keyword arguments from [xwRangeAsGroup] to determine the attributes of the groupers                                #
#   |                [<see def.>  ] <Default> See definition of [xwRangeAsGroup]                                                        #
#   |asformatter :   Logical value indicating whether to act as a formatter function for xw.Range. One needs to call [functools.partial]#
#   |                 to set the parameters other than [rng] and [df] in order to use it in such case                                   #
#   |                [False       ] <Default> Call this function to export [df] to the predefined [rng] directly                        #
#   |                [True        ]           Only format the predefined [rng] without exporting the data of [df]                       #
#   |formatOnly  :   Logical value indicating whether only to set the format to the give range while not pouring the data               #
#   |                [IMPORTANT   ] This argument only works when [asformatter = False]                                                 #
#   |                [False       ] <Default> Pour data into the range after formatting                                                 #
#   |                [True        ]           Only format the predefined [rng] without exporting the data of [df]                       #
#   |idxall      :   When matching the provision of [indexer], generate a full indexer for the provided pd.Index                        #
#   |                [<see def.>  ] <Default> See definition of [xwDfToRange]                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not have return value                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230219        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas, numpy, xlwings, inspect, functools, collections, typing                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |modifyDict                                                                                                                 #
#   |   |   |pandasParseIndexer                                                                                                         #
#   |   |   |pandasPivot                                                                                                                #
#   |   |   |xwRangeAsGroup                                                                                                             #
#   |   |   |xwDfToRange                                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if isinstance(mergeIdx, bool):
        idx_to_merge = list(range(df.index.nlevels - 1)) if (index and mergeIdx) else []
    else:
        idx_to_merge = pandasParseIndexer(pd.Index(df.index.names), mergeIdx, idxall = idxall, logname = 'mergeIdx')

    if isinstance(mergeHdr, bool):
        hdr_to_merge = list(range(df.columns.nlevels - 1)) if (header and mergeHdr) else []
    else:
        hdr_to_merge = pandasParseIndexer(pd.Index(df.columns.names), mergeHdr, idxall = idxall, logname = 'mergeHdr')
    if not isinstance(asformatter, (bool, np.bool_)):
        raise TypeError('[{0}][asformatter]:[{1}] must be boolean!'.format(LfuncName, type(asformatter)))
    if not isinstance(formatOnly, (bool, np.bool_)):
        raise TypeError('[{0}][formatOnly]:[{1}] must be boolean!'.format(LfuncName, type(formatOnly)))

    #050. Local parameters
    rng_Sheet = rng.sheet
    #[ASSUMPTION]
    #[1] We have to use all below parameters, in case [kw_pvtLike] does not contain all of them
    args_pvtLike = {
        s.name : s.default
        for s in signature(pandasPivot).parameters.values()
        if reduce(lambda x,y:x|y, map(lambda v: s.name.startswith(v), ['pos','row','col','fRow','fCol']))
    }
    args_pvtLike = modifyDict(args_pvtLike, kw_pvtLike)
    #[ASSUMPTION]
    #[1] We have to use all below parameters, in case [kw_pvtLike] does not contain all of them
    args_asGroup = {
        s.name : s.default
        for s in signature(xwRangeAsGroup).parameters.values()
        if s.default is not inspect._empty
    }
    args_asGroup = modifyDict(args_asGroup, kw_asGroup)
    row_asGroup = modifyDict(args_asGroup, { 'axis' : 0 })
    col_asGroup = modifyDict(args_asGroup, { 'axis' : 1 })
    row_adj = df.columns.nlevels if header else 0
    col_adj = df.index.nlevels if index else 0
    table_top, table_left = 0,0
    data_top = table_top + row_adj
    data_left = table_left + col_adj

    #070. Verify the imported arguments from the keywords
    cand_pos = ['after','before']
    posRowTot = args_pvtLike.get('posRowTot').lower()
    posRowSubt = args_pvtLike.get('posRowSubt').lower()
    posColTot = args_pvtLike.get('posColTot').lower()
    posColSubt = args_pvtLike.get('posColSubt').lower()
    if posRowTot not in cand_pos:
        raise ValueError('[' + LfuncName + '][posRowTot]:[{0}] must be among: [{1}]!'.format(posRowTot, ','.join(cand_pos)))
    if posRowSubt not in cand_pos:
        raise ValueError('[' + LfuncName + '][posRowSubt]:[{0}] must be among: [{1}]!'.format(posRowSubt, ','.join(cand_pos)))
    if posColTot not in cand_pos:
        raise ValueError('[' + LfuncName + '][posColTot]:[{0}] must be among: [{1}]!'.format(posColTot, ','.join(cand_pos)))
    if posColSubt not in cand_pos:
        raise ValueError('[' + LfuncName + '][posColSubt]:[{0}] must be among: [{1}]!'.format(posColSubt, ','.join(cand_pos)))
    fRowTot = args_pvtLike.get('fRowTot')
    fRowSubt = args_pvtLike.get('fRowSubt')
    fColTot = args_pvtLike.get('fColTot')
    fColSubt = args_pvtLike.get('fColSubt')
    rowTot = args_pvtLike.get('rowTot')
    colTot = args_pvtLike.get('colTot')
    axis = kw_asGroup.get('axis')
    key_axis = { 0 : 'row', 1 : 'column' }
    opt_axis = [None] + list(key_axis.keys())
    if axis not in opt_axis:
        raise ValueError('[{0}][axis]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(axis)
            ,','.join(map(str, opt_axis))
        ))
    rowGroup = (axis is None) or (axis == 0)
    colGroup = (axis is None) or (axis == 1)

    #090. Resize the range to ensure the slicing is successful
    if not asformatter:
        rng = rng.resize(len(df) + row_adj, len(df.columns) + col_adj)

    #100. Helper functions
    #110. Function to identify the adjacent rows/columns to merge in terms of [attr]
    def h_idx_merge_grp(i, attr):
        idx_reset = getattr(df, attr).get_level_values(i).to_series().reset_index(drop = True)
        idx_tail = (
            idx_reset
            .ne(idx_reset.shift(1, fill_value = '-' + str(idx_reset.iat[0])))
            .cumsum()
            .value_counts()
            .sort_index()
            .cumsum()
        )
        idx_head = idx_tail.shift(1, fill_value = 0).add(1)
        pos = list(zip(idx_head[idx_head.ne(idx_tail)].to_list(), idx_tail[idx_head.ne(idx_tail)].to_list()))
        return(pos)

    #130. Function to identify the positions other than [totals]
    def h_totals_grp(i, attr, pos_totals, totals):
        idx_reset = getattr(df, attr).get_level_values(i).to_series().reset_index(drop = True)
        if not idx_reset.eq(totals).any():
            return([])
        if pos_totals == 'before':
            idx_comp = idx_reset.shift(1, fill_value = totals)
        else:
            idx_comp = idx_reset
        idx_tail = (
            idx_comp
            .eq(totals)
            .cumsum()
            .value_counts()
            .sort_index()
            .cumsum()
        )
        idx_head = idx_tail.shift(1, fill_value = 0).add(1)
        pos = list(zip(idx_head[idx_head.ne(idx_tail)].to_list(), idx_tail[idx_head.ne(idx_tail)].to_list()))
        return(pos)

    #300. Determine the position modifiers
    #310. Row modifiers
    if posRowSubt == 'before':
        mod_grp_row_head = 1
    else:
        mod_grp_row_head = 0
    mod_grp_row_tail = 1 - mod_grp_row_head

    #350. Column modifiers
    if posColSubt == 'before':
        mod_grp_col_head = 1
    else:
        mod_grp_col_head = 0
    mod_grp_col_tail = 1 - mod_grp_col_head

    #500. Identify the areas to be grouped
    #510. Merged indexes
    merged_idx = { i:h_idx_merge_grp(i, 'index') for i in idx_to_merge }
    xlmerge_idx = [
        (
            slice(data_top + h + mod_grp_row_head - 1, data_top + t - mod_grp_row_tail - 1 + 1, None)
            ,slice(table_left + k, table_left + k + 1, None)
        )
        for k,v in merged_idx.items()
        for h,t in v
        if fRowSubt
    ]

    #530. Grouper for totals on index
    merged_idx_totals = {
        i:h_totals_grp(i, 'index', posRowTot, rowTot)
        for i in range(df.index.nlevels)
    }
    xlmerge_idx_totals = [
        (
            slice(data_top + h - 1, data_top + t - 1 + 1, None)
            ,slice(table_left + k, table_left + k + 1, None)
        )
        for k,v in merged_idx_totals.items()
        for h,t in v
        if fRowTot
    ]

    #550. Merged headers
    merged_hdr = { i:h_idx_merge_grp(i, 'columns') for i in hdr_to_merge }
    xlmerge_hdr = [
        (
            slice(table_top + k, table_top + k + 1, None)
            ,slice(data_left + h + mod_grp_col_head - 1, data_left + t - mod_grp_col_tail - 1 + 1, None)
        )
        for k,v in merged_hdr.items()
        for h,t in v
        if fColSubt
    ]

    #570. Grouper for totals on headers
    merged_hdr_totals = {
        i:h_totals_grp(i, 'columns', posColTot, colTot)
        for i in range(df.columns.nlevels)
    }
    xlmerge_hdr_totals = [
        (
            slice(table_top + k, table_top + k + 1, None)
            ,slice(data_left + h - 1, data_left + t - 1 + 1, None)
        )
        for k,v in merged_hdr_totals.items()
        for h,t in v
        if fColTot
    ]

    #700. Determine the positions of outlines
    #[ASSUMPTION]
    #[1] We take [posRowSubt] and [posColSubt] as top priority to locate the outlines
    #[2] If there is no [subtotals] on any axis, we then prioritize [posRowTot] and [posColTot]
    #[3] If program still cannot determine the outline position, it refers to the input values as last option
    #710. Axis-0
    if len(xlmerge_idx) > 0:
        row_asGroup = modifyDict(row_asGroup, { 'posOutline' : posRowSubt })
    elif len(xlmerge_idx_totals) > 0:
        row_asGroup = modifyDict(row_asGroup, { 'posOutline' : posRowTot })

    #750. Axis-1
    if len(xlmerge_hdr) > 0:
        col_asGroup = modifyDict(col_asGroup, { 'posOutline' : posColSubt })
    elif len(xlmerge_hdr_totals) > 0:
        col_asGroup = modifyDict(col_asGroup, { 'posOutline' : posColTot })

    #800. Group the ranges as requested
    #710. Axis-0
    if rowGroup:
        #100. Add group and outline
        for r in xlmerge_idx + xlmerge_idx_totals:
            xwRangeAsGroup(rng.__getitem__(r), **row_asGroup)

        #900. Display the outline level 2 as Business convention if applicable
        if len(xlmerge_idx) > 0:
            #Quote: https://github.com/xlwings/xlwings/issues/2115
            #Quote: https://github.com/xlwings/xlwings/blob/main/DEVELOPER_GUIDE.md#macos
            #[ASSUMPTION]
            #[1] Below method seems only to work for MacOS
            # rng_Sheet.api.outline_object.show_levels( row_levels = len(xlmerge_idx_totals) + 1 )
            #[2] It is tested for [xlwings <= 0.29.1], below statement takes no effect without errors
            rng_Sheet.api.Outline.ShowLevels( RowLevels = len(xlmerge_idx_totals) + 1 )

    #750. Axis-1
    if colGroup:
        #100. Add group and outline
        for r in xlmerge_hdr + xlmerge_hdr_totals:
            xwRangeAsGroup(rng.__getitem__(r), **col_asGroup)

        #900. Display the outline level 2 as Business convention if applicable
        if len(xlmerge_hdr) > 0:
            rng_Sheet.api.Outline.ShowLevels(ColumnLevels = len(xlmerge_idx_totals) + 1)

    #999. Export the data to the entire range
    if (not asformatter) and (not formatOnly):
        #100. Create a copy of the data frame to avoid modification on the original object
        df_copy = df.copy(deep = True)

        #300. Remove the names of [df.index] during the export
        if not (index & header & index_name):
            df_copy.index.names = [ None for i in range(len(df_copy.index.names)) ]

        #900. Write the data
        rng.value = df_copy
#End xwGroupForDf

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import numpy as np
    import pandas as pd
    #We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings <= 0.27.15] and [Python <= 3.8]
    #It is weird but works!
    #Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
    import pywintypes
    import xlwings as xw
    from functools import partial
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import xwGroupForDf
    from omniPy.AdvOp import pandasPivot

    #100. Prepare data frame
    udf = pd.DataFrame(
        {
            'A': ['foo', 'foo', 'foo', 'foo', 'foo','bar', 'bar', 'bar', 'bar'],
            'B': ['one', 'one', 'one', 'two', 'two','one', 'one', 'two', 'two'],
            'C': ['small', 'large', 'large', 'small','small', 'large', 'small', 'small','large'],
            'D': [1, 2, 2, 3, 3, 4, 5, 6, 7],
            'E': [2, 4, 5, 5, 6, 6, 8, 9, 9]
        }
    )
    arg_totals = {
        'fRowTot' : True
        ,'fRowSubt' : True
        ,'rowTot' : 'Total'
        ,'rowSubt' : 'Subtotal'
        ,'posRowTot' : 'after'
        ,'posRowSubt' : 'before'
        ,'fColTot' : True
        ,'fColSubt' : True
        ,'colTot' : 'Total'
        ,'colSubt' : 'Subtotal'
        ,'posColTot' : 'after'
        ,'posColSubt' : 'after'
    }
    udf_pvt = pandasPivot(
        testdf
        ,index = ['A','C']
        ,columns = ['B']
        ,values = ['D']
        ,aggfunc = { 'D' : np.nansum }
        ,fill_value = 0
        ,rowSortAsc = True
        ,colSortAsc = True
        ,name_vals = '.pivot.values.'
        ,name_stats = '.pivot.stats.'
        ,keyPatcher = {
            #Set [foo] ahead of [bar] in the result
            'A' : { 'foo' : 0, 'bar' : 1 }
        }
        ,**arg_totals
    )

    #200. Set the universal parameters
    args_xw = {
        'index' : True
        ,'header' : True
        ,'mergeIdx' : True
        ,'mergeHdr' : True
    }

    xwfmtter = partial(xwGroupForDf, asformatter = True, kw_pvtLike = arg_totals, **args_xw)

    #300. Export the data into an EXCEL file with default theme
    xlfile = os.path.join(dir_omniPy, 'omniPy', 'AdvOp', 'pvtGroup.xlsx')
    if os.path.isfile(xlfile): os.remove(xlfile)
    with xw.App( visible = False, add_book = True ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Identify the EXCEL workbook
        xlwb = xlapp.books[0]

        #300. Define the sheet
        xlsh = xlwb.sheets[0]

        #400. Define the range
        xlrng = xlsh.range('B2').expand().options(pd.DataFrame, index = True, header = True, formatter = xwfmtter)

        #500. Export the data
        xlrng.value = udf_pvt
        xlsh.autofit()

        #600. Only set the groups and outlines without pouring the data
        xlsh2 = xlwb.sheets.add('RAW')
        xlrng2 = xlsh2.range('B3').expand().options(pd.DataFrame, index = True, header = True)
        xwGroupForDf(
            xlrng2
            ,udf_pvt
            ,formatOnly = True
            ,kw_pvtLike = arg_totals
            ,**args_xw
        )
        xlsh2.autofit()

        #999. Purge
        xlwb.save(xlfile)
        xlwb.close()
        xlapp.screen_updating = True

    if os.path.isfile(xlfile): os.remove(xlfile)
#-Notes- -End-
'''