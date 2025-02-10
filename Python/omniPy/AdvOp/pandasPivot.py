#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import warnings
import pandas as pd
from functools import partial
from typing import Optional
from operator import itemgetter
from omniPy.AdvOp import modifyDict, ExpandSignature

#[ASSUMPTION]
#[1] We leave the annotation as empty, to inherit from the ancestor functions
#[2] If you need to chain the expansion, make sure either of below designs is set
#    [1] Each of the nodes is in a separate module
#    [2] The named instances (e.g. <eSig> here) have unique names among all nodes, if they are in the same module
#[3] To avoid this block of comments being collected as docstring, we skip an empty line below

@(eSig := ExpandSignature(pd.pivot_table))
def pandasPivot(
    df : pd.DataFrame
    ,rowSortAsc : bool = True
    ,fRowTot : bool = True
    ,fRowSubt : bool = True
    ,rowTot : str = 'Grand Total'
    ,rowSubt : str = 'Subtotal'
    ,posRowTot : str = 'after'
    ,posRowSubt : str = 'after'
    ,colSortAsc : bool = True
    ,fColTot : bool = True
    ,fColSubt : bool = True
    ,colTot : str = 'Grand Total'
    ,colSubt : str = 'Subtotal'
    ,posColTot : str = 'after'
    ,posColSubt : str = 'after'
    ,name_vals : str = '.pivot.values.'
    ,name_stats : str = '.pivot.stats.'
    ,keyPatcher : Optional[dict] = None
    ,data : pd.DataFrame = None
    ,*pos
    ,**kw
):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate pivot table for the provided dimensions, while providing freedom to adjust the sorting      #
#   | sequence of dimension values, and to place the Grand Totals and Subtotals in different positions for either axis                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate Grand Totals and Subtotals and put them in different positions in the pivot table                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Known Limits:                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] (v1.00) Groupers and Arrays in [index] and [columns] arguments are not tested, hence may cause unexpected results              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |df            :   [pd.DataFrame] to be pivoted                                                                                     #
#   |rowSortAsc    :   Whether to sort the values in ascending order for [index] dimensions                                             #
#   |                  [True            ] <Default> Follow the default behavior as [pd.pivot_table]                                     #
#   |                  [False           ]           Sort the respective [index] dimensions in descending order                          #
#   |fRowTot       :   Whether to display the Grand Totals for [index] axis                                                             #
#   |                  [True            ] <Default> Display Grand Total as extra rows in the pivot table                                #
#   |                  [False           ]           Suppress Grand Total of [index] axis from being calculated                          #
#   |fRowSubt      :   Whether to display the Subtotals for respective [index] dimensions                                               #
#   |                  [True            ] <Default> Display Subtotals as extra rows in the pivot table                                  #
#   |                  [False           ]           Suppress Subtotals of [index] dimensions from being calculated                      #
#   |rowTot        :   Name of the Grand Total stats for [index] axis as displayed in the pivot table                                   #
#   |                  [<see def.>      ] <Default> See function definition                                                             #
#   |                  [<str>           ]           Character string that DOES NOT match any data value within either [index] or        #
#   |                                                [columns]                                                                          #
#   |rowSubt       :   Name of the Subtotals stats for [index] dimensions as displayed in the pivot table                               #
#   |                  [<see def.>      ] <Default> See function definition                                                             #
#   |                  [<str>           ]           Character string that DOES NOT match any data value within either [index] or        #
#   |                                                [columns]                                                                          #
#   |posRowTot     :   Where to place Grand Total stats for [index] axis                                                                #
#   |                  [after           ] <Default> Place the Grand Total AFTER all stats in the pivot table                            #
#   |                  [before          ]           Place the Grand Total BEFORE all stats in the pivot table                           #
#   |posRowSubt    :   Where to place Subtotals within each group for [index] dimensions                                                #
#   |                  [after           ] <Default> Place the Subtotals AFTER all stats in the same group of the pivot table            #
#   |                  [before          ]           Place the Subtotals BEFORE all stats in the same group of the pivot table           #
#   |colSortAsc    :   Whether to sort the values in ascending order for [columns] dimensions                                           #
#   |                  [True            ] <Default> Follow the default behavior as [pd.pivot_table]                                     #
#   |                  [False           ]           Sort the respective [columns] dimensions in descending order                        #
#   |fColTot       :   Whether to display the Grand Totals for [columns] axis                                                           #
#   |                  [True            ] <Default> Display Grand Total as extra column in the pivot table                              #
#   |                  [False           ]           Suppress Grand Total of [columns] axis from being calculated                        #
#   |fColSubt      :   Whether to display the Subtotals for respective [columns] dimensions                                             #
#   |                  [True            ] <Default> Display Subtotals as extra columns in the pivot table                               #
#   |                  [False           ]           Suppress Subtotals of [columns] dimensions from being calculated                    #
#   |colTot        :   Name of the Grand Total stats for [columns] axis as displayed in the pivot table                                 #
#   |                  [<see def.>      ] <Default> See function definition                                                             #
#   |                  [<str>           ]           Character string that DOES NOT match any data value within either [index] or        #
#   |                                                [columns]                                                                          #
#   |colSubt       :   Name of the Subtotals stats for [columns] dimensions as displayed in the pivot table                             #
#   |                  [<see def.>      ] <Default> See function definition                                                             #
#   |                  [<str>           ]           Character string that DOES NOT match any data value within either [index] or        #
#   |                                                [columns]                                                                          #
#   |posColTot     :   Where to place Grand Total stats for [columns] axis                                                              #
#   |                  [after           ] <Default> Place the Grand Total AFTER all stats in the pivot table                            #
#   |                  [before          ]           Place the Grand Total BEFORE all stats in the pivot table                           #
#   |posColSubt    :   Where to place Subtotals within each group for [columns] dimensions                                              #
#   |                  [after           ] <Default> Place the Subtotals AFTER all stats in the same group of the pivot table            #
#   |                  [before          ]           Place the Subtotals BEFORE all stats in the same group of the pivot table           #
#   |name_vals     :   Level name in the pivot table that represents the dimension [values], baiscally for sorting purpose, see example #
#   |                   for actual usage                                                                                                #
#   |                  [<see def.>      ] <Default> See function definition                                                             #
#   |                  [<str>           ]           Character string that DOES NOT match any value within [values]                      #
#   |name_stats    :   Level name in the pivot table that represents the dimension of user requested stats, baiscally for sorting       #
#   |                   purpose, see example for actual usage                                                                           #
#   |                  [<see def.>      ] <Default> See function definition                                                             #
#   |                  [<str>           ]           Character string that DOES NOT match any callable names within [aggfunc]            #
#   |keyPatcher    :   <dict> to patch the default sorter of dimension values, useful to tweak the display order of several values      #
#   |                  It must be provided in the form: {<column_name>:{<value1>:<sequence1>,...},...}; where <column_name> must be     #
#   |                   among [index] or [columns] for the pivot table, while <value<n>> represents the <n>th unique value as described #
#   |                   by <df>[<column_name>].unique() and <sequence<n>> must be within range(len(<df>[<column_name>].unique()))       #
#   |                   representing the order for sorting. See example for actual usage                                                #
#   |                  [None            ] <Default> Follow the default sorting behavior of [pandas.pivot_table]                         #
#   |                  [<dict>          ]           Overwrite part of the default sorting behavior as tweak to the display order of     #
#   |                                                categories                                                                         #
#   |data          :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <df> so it no      #
#   |                   longer takes effect                                                                                             #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                  [<see def.>      ] <Default> Calculated out of <df>                                                              #
#   |*pos          :   Various positional arguments to expand from its ancestor; see its official document                              #
#   |**kw          :   Various keyword arguments to expand from its ancestor; see its official document                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Anno>        :   See the return result from the ancestor function                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220709        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221024        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when there is only a single column involved in either [index] or [columns] dimensions                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221026        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Changed the behavior of the native argument [observed] for pd.pivot_table() to indicate whether only to embed the       #
#   |      |     observed combinations in the result for dimensions other than categorical type                                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230112        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when no [columns] is provided and [aggfunc] only contain one field with one aggregation method              #
#   |      |[2] Now set the placeholder for subtotals as a single white space to facilitate EXCEL formatting where necessary            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230218        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Allow [keyPatcher] to have uncontinuous sequence, and if it contains equal sequence numbers, further sort the keys to   #
#   |      |     ensure a unique sequence number for each item in the final value list                                                  #
#   |      |[2] Correct the sequence of values in the output totals and subtotals of [columns]                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230609        | Version | 1.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug of losing <column totals> and <column subtotals> when <observed = True>                                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230708        | Version | 1.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug where non-existing combinations of <index> or <columns> dimension values in subtotals and totals            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250207        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |      |[2] For the same functionality, enable diversified parameter provision in accordance with its expanded signature            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250210        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Added support of input as <pd.Grouper> for <index> and <columns>, now literally support all inputs for <index> and      #
#   |      |     <columns> that are accepted by the ancestor function                                                                   #
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
#   |   |sys, warnings, pandas, functools, typing, operator                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |modifyDict                                                                                                                 #
#   |   |   |ExpandSignature                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    args_ins = {'data' : None}
    eSig.vfyConflict(args_ins)

    posRowTot = posRowTot.lower()
    posRowSubt = posRowSubt.lower()
    posColTot = posColTot.lower()
    posColSubt = posColSubt.lower()
    cand_pos = ['after','before']
    if posRowTot not in cand_pos:
        raise ValueError(f'[{LfuncName}][posRowTot]:[{str(posRowTot)}] must be among: [{str(cand_pos)}]!')
    if posRowSubt not in cand_pos:
        raise ValueError(f'[{LfuncName}][posRowSubt]:[{str(posRowSubt)}] must be among: [{str(cand_pos)}]!')
    if posColTot not in cand_pos:
        raise ValueError(f'[{LfuncName}][posColTot]:[{str(posColTot)}] must be among: [{str(cand_pos)}]!')
    if posColSubt not in cand_pos:
        raise ValueError(f'[{LfuncName}][posColSubt]:[{str(posColSubt)}] must be among: [{str(cand_pos)}]!')

    #030. Prepare correct structure of the input parameters for the call to <src>
    #[ASSUMPTION]
    #[1] Due to the argument expansion, all arguments will have been provided with their default values given that <data> has no
    #     default value nor provision at runtime
    #[2] That is why we can only verify the related arguments with values, rather than their provision status
    pos_fnl, kw_fnl = pos_in, kw_in = eSig.insParams(args_ins, pos, kw)

    #Ensure the same behavior as [pd.pivot_table]
    if mgn_flag := eSig.getParam('margins', pos_in, kw_in):
        fRowTot = fRowSubt = fColTot = fColSubt = mgn_flag
        pos_fnl, kw_fnl = eSig.updParams({'margins' : False}, pos_fnl, kw_fnl)
    if (mgn_name := eSig.getParam('margins_name', pos_in, kw_in)) is not eSig.args_src.get('margins_name'):
        rowTot = colTot = mgn_name
    if sort_flag := eSig.getParam('sort', pos_in, kw_in):
        rowSortAsc = colSortAsc = sort_flag
        pos_fnl, kw_fnl = eSig.updParams({'sort' : False}, pos_fnl, kw_fnl)

    #050. Local parameters
    var_rows = eSig.getParam('index', pos_fnl, kw_fnl) or []
    if isinstance(var_rows, str):
        var_rows = [var_rows]
    if var_rows:
        if isinstance(var_rows, pd.Grouper):
            var_rows = list(
                df.groupby(var_rows)
                [eSig.getParam('values', pos_fnl, kw_fnl)].min()
                .index.names
            )
        else:
            var_rows = list(df.set_index(var_rows).index.names)

    var_cols = eSig.getParam('columns', pos_fnl, kw_fnl) or []
    if isinstance(var_cols, str):
        var_cols = [var_cols]
    if var_cols:
        if isinstance(var_cols, pd.Grouper):
            var_cols = list(
                df.groupby(var_cols)
                [eSig.getParam('values', pos_fnl, kw_fnl)].min()
                .index.names
            )
        else:
            var_cols = list(df.set_index(var_cols).index.names)

    f_rows = len(var_rows) > 0
    f_cols = len(var_cols) > 0
    if not f_rows:
        fRowTot = fRowSubt = False
    if not f_cols:
        fColTot = fColSubt = False
    f_totals_row = f_rows & ( fRowTot | fRowSubt )
    f_totals_col = f_cols & ( fColTot | fColSubt )
    f_totals_cross = f_totals_row & f_totals_col
    name_vals = '.pivot.values.'
    name_stats = '.pivot.stats.'
    reorder_vals = []
    reorder_stats = []

    #060. Calculate levels of all dimensions for later sorting
    #[ASSUMPTION]
    #[1] The order of values is defined automatically at this step
    dim_cols = var_rows + var_cols
    val_unique = {
        c : { v:i for i,v in enumerate(pd.Series(df[c].unique()).sort_values().tolist()) }
        for c in dim_cols
    }

    #070. Patch the default order of values when required
    if isinstance(keyPatcher, dict):
        val_unique = modifyDict(val_unique, keyPatcher)

    #079. Abort if the names of Grand Totals or Subtotals are the same as any among the unique data values
    val_any = [ k for c in list(val_unique.values()) for k in list(c.keys()) ]
    if f_totals_row:
        if fRowTot and (rowTot in val_any):
            raise ValueError(f'[{LfuncName}][rowTot]:[{str(rowTot)}] conflicts with the data dimension values!')
        if fRowSubt and (rowSubt in val_any):
            raise ValueError(f'[{LfuncName}][rowSubt]:[{str(rowSubt)}] conflicts with the data dimension values!')
    if f_totals_col:
        if fColTot and (colTot in val_any):
            raise ValueError(f'[{LfuncName}][colTot]:[{str(colTot)}] conflicts with the data dimension values!')
        if fColSubt and (colSubt in val_any):
            raise ValueError(f'[{LfuncName}][colSubt]:[{str(colSubt)}] conflicts with the data dimension values!')

    #100. Helper functions
    #110. Function to reorder the given dict with continuous sequence, starting from 0
    #Quote: https://docs.python.org/3/howto/sorting.html#sortinghowto
    #[ASSUMPTION]
    #[1] The input [keyPatcher] could be uncontinuous
    #[2] There could also be equal sequence numbers in the patched values, e.g. { 'a' : 1, 'b' : 1, ... }
    #[3] We have to reorder the patched values with continuous sequence
    #[4] In case [2] happens, we first sort the values then sort the keys to determine a unique sequence number for each
    def h_reorderDict(d):
        vals = sorted([ (k,v) for k,v in d.items() ], key = itemgetter(1,0))
        return({ v[0]:i for i,v in enumerate(vals) })

    #119. Reorder the patched values on axes to ensure totals and subtotals can be placed correctly
    val_unique = { k:h_reorderDict(v) for k,v in val_unique.items() }

    #130. Function to act as key for sorting of any [pd.Series]
    def h_sort(vec, ascending, pos_total, pos_subtotal, val_total, val_subtotal):
        #100. Obtain the dedicated sequence of unique values for current input vector
        vec_unique = val_unique.get(vec.name, {})
        if len(vec_unique) == 0: return(vec)

        #300. Retrieve the max sequence number in the mapper
        max_val = max(vec_unique.values())

        #400. Determine the position of Grand Totals and Subtotals
        if ascending:
            rst_total = -2 if pos_total == 'before' else max_val + 2
            rst_subtotal = -1 if pos_subtotal == 'before' else max_val + 1
        else:
            rst_total = -2 if pos_total != 'before' else max_val + 2
            rst_subtotal = -1 if pos_subtotal != 'before' else max_val + 1

        #700. Set the sequence of the values for the input vector
        rstOut = (
            vec
            .copy(deep = True)
            .map(vec_unique)
            .where(vec != val_subtotal, rst_subtotal)
            .where(vec != val_total, rst_total)
        )

        #999. Return the final sequence
        return(rstOut)

    #150. Function to prepare the combination of subtotals and grand totals
    def h_dim(obj, i, val_total, val_subtotal):
        placeholder = val_total if i == 0 else val_subtotal
        rstOut = {
            v : (placeholder if j == i else ' ')
            for j,v in enumerate(obj)
            if j >= i
        }
        return(rstOut)

    #170. Function to convert the data type of all levels within a pd.MultiIndex
    #Quote: Get respective levels of pd.MultiIndex
    #Quote: https://stackoverflow.com/questions/36909457
    def h_AsObj(idx):
        if isinstance(idx, pd.MultiIndex):
            obj = [ idx.get_level_values(i).astype('object') for i in range(idx.nlevels) ]
            return(pd.MultiIndex.from_arrays(obj))
        else:
            return(idx.astype('object'))

    #190. Function to mutate the data and calculate pivot
    def h_pivot(df, ren = {}):
        #100. Assign subtotals and totals to necessary dimensions
        df_mutate = df.copy(deep = True)
        if len(ren) > 0:
            df_mutate.loc[:, list(ren.keys())] = df_mutate[list(ren.keys())].astype('object')
            df_mutate = df_mutate.assign(**ren)

        #300. Pivoting
        pos_rpt, kw_rpt = eSig.updParams({'data' : df_mutate}, pos_fnl, kw_fnl)
        rstOut = eSig.src(*pos_rpt, **kw_rpt)

        #700. Remove combinations of dimensions that are not observed
        if eSig.getParam('observed', pos_rpt, kw_rpt) or False:
            #400. On axis-0
            if f_rows:
                #100. Different number of dimensions
                if len(var_rows) == 1:
                    get_row = var_rows[0]
                    func_idx = pd.Index
                else:
                    func_idx = pd.MultiIndex.from_frame
                    get_row = var_rows

                #500. Determine the existing combinations of dimension values
                #Quote: python 忽略警告（warning）的几种方法
                #Quote: https://blog.csdn.net/time_forgotten/article/details/104792200
                #[ASSUMPTION][pandas = 1.4.2]
                #[1] Creating index out of dataframe constructed by <object> dtype leads to <FutureWarning>
                #[2] Since we always have to convert the index into <object> dtype, this warning should be ignored
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', category = FutureWarning)
                    min_idx = h_AsObj(func_idx(df_mutate.loc[:, get_row].drop_duplicates()))

                #900. Mitigation of non-existing cobminations
                rstOut = rstOut.copy(deep = True).loc[lambda x: h_AsObj(x.index).isin(min_idx)]

            #700. On axis-1
            if f_cols:
                #100. Different number of dimensions
                if len(var_cols) == 1:
                    func_idx = pd.Index
                    get_col = var_cols[0]
                else:
                    func_idx = pd.MultiIndex.from_frame
                    get_col = var_cols

                #500. Determine the existing combinations of dimension values
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', category = FutureWarning)
                    min_col = h_AsObj(func_idx((
                        rstOut.columns
                        .to_frame()
                        .astype('object')
                        .reset_index(drop = True)
                        .merge(
                            df_mutate.loc[:, get_col].drop_duplicates()
                            ,on = get_col
                            ,how = 'inner'
                        )
                    )))

                #900. Mitigation of non-existing cobminations
                rstOut = rstOut.copy(deep = True).loc[:, lambda x: h_AsObj(x.columns).isin(min_col)]
            #End if observed

        return(rstOut)

    #200. Create base pivot table
    pvt_base = h_pivot(df)

    #400. Calculate totals
    #410. Row totals
    if f_totals_row:
        #100. Combination of row totals
        ren_rows = [ h_dim(var_rows, i, rowTot, rowSubt) for i in range(len(var_rows)) ]
        if not fRowTot:
            if len(ren_rows) == 1:
                ren_rows = [{ var_rows[0] : rowSubt }]
            else:
                ren_rows = ren_rows[1:]
        if not fRowSubt:
            ren_rows = [ren_rows[0]]

        #500. Totals by different combinations of row values and merge them on x-axis
        pvt_by_y = pd.concat(
            [ h_pivot(df, x) for x in ren_rows ]
            ,axis = 0
            ,sort = False
            ,ignore_index = False
        )

    #440. Column totals
    if f_totals_col:
        #100. Combination of column totals
        ren_cols = [ h_dim(var_cols, i, colTot, colSubt) for i in range(len(var_cols)) ]
        if not fColTot:
            if len(ren_cols) == 1:
                ren_cols = [{ var_cols[0] : colSubt }]
            else:
                ren_cols = ren_cols[1:]
        if not fColSubt:
            ren_cols = [ren_cols[0]]

        #500. Totals by different combinations of column values and merge them on y-axis
        pvt_by_x = pd.concat(
            [ h_pivot(df, x) for x in ren_cols ]
            ,axis = 1
            ,sort = False
            ,ignore_index = False
        )

    #470. Cross-axis totals
    if f_totals_cross:
        #100. Combination of totals on both axes
        #[ASSUMPTION]
        #[1] We do not directly calculate the cartesian product of the dimensions, as we have to merge them on dedicated axes
        ren_comb = [
            [ {**x,**y} for y in ren_cols ]
            for x in ren_rows
        ]

        #500. Totals by different combinations of subtotals
        pvt_totals = pd.concat(
            [
                pd.concat(
                    [ h_pivot(df, y) for y in x ]
                    ,axis = 1
                    ,sort = False
                    ,ignore_index = False
                )
                for x in ren_comb
            ]
            ,axis = 0
            ,sort = False
            ,ignore_index = False
        )

    #600. Merge all pieces of the stats
    #610. Add row totals if any
    if f_totals_row:
        pvt_base.index = h_AsObj(pvt_base.index)
        pvt_by_y.index = h_AsObj(pvt_by_y.index)
        pvt_base = pd.concat(
            [ pvt_base, pvt_by_y ]
            ,axis = 0
            ,sort = False
            ,ignore_index = False
        )

    #640. Add column totals if any
    if f_totals_col:
        pvt_base.columns = h_AsObj(pvt_base.columns)
        pvt_by_x.columns = h_AsObj(pvt_by_x.columns)
        #[ASSUMPTION][pandas = 1.3.1]
        #[1] Regardless of [sort=False], [pd.concat] still sorts the values of column labels
        #[2] When the input values of columns levels are NOT character strings, it issues RuntimeWarning for unorderable data
        #[3] This does not affect the result hence we ignore it to clean up the log
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', category = RuntimeWarning)
            pvt_base = pd.concat(
                [ pvt_base, pvt_by_x ]
                ,axis = 1
                ,sort = False
                ,ignore_index = False
            )

    #670. Add cross-axis totals if any
    if f_totals_cross:
        pvt_base.loc[pvt_totals.index, pvt_totals.columns] = pvt_totals

    #800. Rearrange the rows and columns of the pivot table as required
    #810. Sort rows
    #814. Helper callable as [key] for sorting
    h_sort_row = partial(
        h_sort
        ,ascending = rowSortAsc
        ,pos_total = posRowTot
        ,pos_subtotal = posRowSubt
        ,val_total = rowTot
        ,val_subtotal = rowSubt
    )

    #817. Sort by above [key]
    if f_rows:
        pvt_base.sort_index(axis = 0, inplace = True, ascending = rowSortAsc, key = h_sort_row)

    #840. Sort columns
    #841. Set the names for special levels
    vfy_cols = [ c for c in pvt_base.columns.names if c not in var_cols ]
    if len(vfy_cols) > 0:
        reorder_vals = [name_vals]
        setlvl = None if pvt_base.columns.nlevels == 1 else 0
        pvt_base.columns.set_names(name_vals, inplace = True, level = setlvl)
        if f_totals_col:
            pvt_by_x.columns.set_names(name_vals, inplace = True, level = setlvl)
        if f_totals_cross:
            pvt_totals.columns.set_names(name_vals, inplace = True, level = setlvl)

    if len(vfy_cols) == 2:
        reorder_stats = [name_stats]
        pvt_base.columns.set_names(name_stats, inplace = True, level = 1)
        if f_totals_col:
            pvt_by_x.columns.set_names(name_stats, inplace = True, level = 1)
        if f_totals_cross:
            pvt_totals.columns.set_names(name_stats, inplace = True, level = 1)

    #842. Re-assign the column indexes before sorting
    colReorder = var_cols + reorder_vals + reorder_stats
    if isinstance(pvt_base.columns, pd.MultiIndex):
        pvt_base.columns = pvt_base.columns.reorder_levels(colReorder)
    if f_totals_col:
        if isinstance(pvt_by_x.columns, pd.MultiIndex):
            pvt_by_x.columns = pvt_by_x.columns.reorder_levels(colReorder)
    if f_totals_cross:
        if isinstance(pvt_totals.columns, pd.MultiIndex):
            pvt_totals.columns = pvt_totals.columns.reorder_levels(colReorder)

    #844. Helper callable as [key] for sorting
    #[ASSUMPTION]
    #[1] All the [values] columns are pivoted in the same dimension on y-axis, which is exactly [0]
    #[2] The [columns] are on the rest dimensions of y-axis, i.e. starting from [1]
    h_sort_col = partial(
        h_sort
        ,ascending = colSortAsc
        ,pos_total = posColTot
        ,pos_subtotal = posColSubt
        ,val_total = colTot
        ,val_subtotal = colSubt
    )

    #847. Sort by above [key]
    pvt_base.sort_index(axis = 1, inplace = True, ascending = colSortAsc, key = h_sort_col)

    #999. Output
    return(pvt_base)
#End pandasPivot

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import pandasPivot
    from statsmodels import datasets

    #100. Prepare the data for pivoting
    udf = datasets.modechoice.load_pandas().data

    #200. Prepare pseudo function to obtain the number of unique values in a [pd.Series]
    def srs_nunique(serie):
        return(serie.nunique())

    #300. Test pivot table with Grand Totals and Subtotals
    udf_pvt = pandasPivot(
        udf
        ,index = ['mode','choice']
        ,columns = ['psize','hinc']
        ,values = ['invc','gc']
        ,aggfunc = { 'invc' : [np.nansum, srs_nunique], 'gc' : [np.nanmean, np.nanmax] }
        ,fill_value = 0
        ,observed = False
        ,rowSortAsc = False
        ,fRowTot = True
        ,fRowSubt = True
        ,rowTot = 'Row Total'
        ,rowSubt = 'Row Subtotal'
        ,posRowTot = 'after'
        ,posRowSubt = 'before'
        ,colSortAsc = True
        ,fColTot = True
        ,fColSubt = True
        ,colTot = 'Column Total'
        ,colSubt = 'Column Subtotal'
        ,posColTot = 'before'
        ,posColSubt = 'after'
        ,name_vals = '.pivot.values.'
        ,name_stats = '.pivot.stats.'
        ,keyPatcher = None
    )

    #400. Switch the dimension value [hinc] : {2.0,4.0}
    #[ASSUMPTION]
    #[1] Below table is the same on stats as above one
    #[2] The position of columns are exchanged when [hinc == 2.0] and [hinc == 4.0]
    #[3] The sequence of groupers [invc] and [gc] are exchanged
    #[4] The sequence of stats [np.nanmean] and [np.nanmax] are exchanged
    #[5] Only display the existing combinations of dimension values, also for subtotals and totals
    udf_pvt2 = pandasPivot(
        udf
        ,index = ['mode','choice']
        ,columns = ['psize','hinc']
        ,values = ['invc','gc']
        ,aggfunc = { 'invc' : [np.nansum, srs_nunique], 'gc' : [np.nanmean, np.nanmax] }
        ,fill_value = 0
        ,observed = True
        ,rowSortAsc = False
        ,fRowTot = True
        ,fRowSubt = True
        ,rowTot = 'Row Total'
        ,rowSubt = 'Row Subtotal'
        ,posRowTot = 'after'
        ,posRowSubt = 'before'
        ,colSortAsc = True
        ,fColTot = True
        ,fColSubt = True
        ,colTot = 'Column Total'
        ,colSubt = 'Column Subtotal'
        ,posColTot = 'before'
        ,posColSubt = 'after'
        ,name_vals = '.pivot.values.'
        ,name_stats = '.pivot.stats.'
        ,keyPatcher = {
            'hinc' : { 2.0 : 1, 4.0 : 0 }
            ,'.pivot.values.' : { 'invc' : 0, 'gc' : 1 }
            ,'.pivot.stats.' : { np.nanmean.__name__ : 9, np.nanmax.__name__ : 10 }
        }
    )
#-Notes- -End-
'''
