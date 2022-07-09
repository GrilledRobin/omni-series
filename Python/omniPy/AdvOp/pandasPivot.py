#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
from collections.abc import Iterable
from functools import partial
from typing import Optional
from omniPy.AdvOp import modifyDict

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
    ,**kw
) -> 'Grant [pandas.pivot_table] with Grand Totals and Subtotals at the same time for both axes':
    #000.   Info.
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
#   |df         :   [pd.DataFrame] to be pivoted                                                                                        #
#   |rowSortAsc :   Whether to sort the values in ascending order for [index] dimensions                                                #
#   |               [True       ] <Default> Follow the default behavior as [pd.pivot_table]                                             #
#   |               [False      ]           Sort the respective [index] dimensions in descending order                                  #
#   |fRowTot    :   Whether to display the Grand Totals for [index] axis                                                                #
#   |               [True       ] <Default> Display Grand Total as extra rows in the pivot table                                        #
#   |               [False      ]           Suppress Grand Total of [index] axis from being calculated                                  #
#   |fRowSubt   :   Whether to display the Subtotals for respective [index] dimensions                                                  #
#   |               [True       ] <Default> Display Subtotals as extra rows in the pivot table                                          #
#   |               [False      ]           Suppress Subtotals of [index] dimensions from being calculated                              #
#   |rowTot     :   Name of the Grand Total stats for [index] axis as displayed in the pivot table                                      #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Character string that DOES NOT match any data value within either [index] or [columns]      #
#   |rowSubt    :   Name of the Subtotals stats for [index] dimensions as displayed in the pivot table                                  #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Character string that DOES NOT match any data value within either [index] or [columns]      #
#   |posRowTot  :   Where to place Grand Total stats for [index] axis                                                                   #
#   |               [after      ] <Default> Place the Grand Total AFTER all stats in the pivot table                                    #
#   |               [before     ]           Place the Grand Total BEFORE all stats in the pivot table                                   #
#   |posRowSubt :   Where to place Subtotals within each group for [index] dimensions                                                   #
#   |               [after      ] <Default> Place the Subtotals AFTER all stats in the same group of the pivot table                    #
#   |               [before     ]           Place the Subtotals BEFORE all stats in the same group of the pivot table                   #
#   |colSortAsc :   Whether to sort the values in ascending order for [columns] dimensions                                              #
#   |               [True       ] <Default> Follow the default behavior as [pd.pivot_table]                                             #
#   |               [False      ]           Sort the respective [columns] dimensions in descending order                                #
#   |fColTot    :   Whether to display the Grand Totals for [columns] axis                                                              #
#   |               [True       ] <Default> Display Grand Total as extra column in the pivot table                                      #
#   |               [False      ]           Suppress Grand Total of [columns] axis from being calculated                                #
#   |fColSubt   :   Whether to display the Subtotals for respective [columns] dimensions                                                #
#   |               [True       ] <Default> Display Subtotals as extra columns in the pivot table                                       #
#   |               [False      ]           Suppress Subtotals of [columns] dimensions from being calculated                            #
#   |colTot     :   Name of the Grand Total stats for [columns] axis as displayed in the pivot table                                    #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Character string that DOES NOT match any data value within either [index] or [columns]      #
#   |colSubt    :   Name of the Subtotals stats for [columns] dimensions as displayed in the pivot table                                #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Character string that DOES NOT match any data value within either [index] or [columns]      #
#   |posColTot  :   Where to place Grand Total stats for [columns] axis                                                                 #
#   |               [after      ] <Default> Place the Grand Total AFTER all stats in the pivot table                                    #
#   |               [before     ]           Place the Grand Total BEFORE all stats in the pivot table                                   #
#   |posColSubt :   Where to place Subtotals within each group for [columns] dimensions                                                 #
#   |               [after      ] <Default> Place the Subtotals AFTER all stats in the same group of the pivot table                    #
#   |               [before     ]           Place the Subtotals BEFORE all stats in the same group of the pivot table                   #
#   |name_vals  :   Level name in the pivot table that represents the dimension [values], baiscally for sorting purpose, see example    #
#   |                for actual usage                                                                                                   #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Character string that DOES NOT match any value within [values]                              #
#   |name_stats :   Level name in the pivot table that represents the dimension of user requested stats, baiscally for sorting purpose, #
#   |                see example for actual usage                                                                                       #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Character string that DOES NOT match any callable names within [aggfunc]                    #
#   |keyPatcher :   <dict> to patch the default sorter of dimension values, useful to tweak the display order of several values         #
#   |               It must be provided in the form: {<column_name>:{<value1>:<sequence1>,...},...}; where <column_name> must be among  #
#   |                [index] or [columns] for the pivot table, while <value<n>> represents the <n>th unique value as described by       #
#   |                <df>[<column_name>].unique() and <sequence<n>> must be within range(len(<df>[<column_name>].unique())) representing#
#   |                the order for sorting. See example for actual usage                                                                #
#   |               [None       ] <Default> Follow the default sorting behavior of [pandas.pivot_table]                                 #
#   |               [<dict>     ]           Overwrite part of the default sorting behavior as tweak to the display order of categories  #
#   |kw         :   Same arguments as those for [pandas.DataFrame.pivot_table()]                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<df>       :   [pandas.DataFrame] as pivoted table                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220709        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas, collections, functools, typing                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |modifyDict                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    posRowTot = posRowTot.lower()
    posRowSubt = posRowSubt.lower()
    posColTot = posColTot.lower()
    posColSubt = posColSubt.lower()
    cand_pos = ['after','before']
    if posRowTot not in cand_pos:
        raise ValueError('[' + LfuncName + '][posRowTot]:[{0}] must be among: [{1}]!'.format(posRowTot, ','.join(cand_pos)))
    if posRowSubt not in cand_pos:
        raise ValueError('[' + LfuncName + '][posRowSubt]:[{0}] must be among: [{1}]!'.format(posRowSubt, ','.join(cand_pos)))
    if posColTot not in cand_pos:
        raise ValueError('[' + LfuncName + '][posColTot]:[{0}] must be among: [{1}]!'.format(posColTot, ','.join(cand_pos)))
    if posColSubt not in cand_pos:
        raise ValueError('[' + LfuncName + '][posColSubt]:[{0}] must be among: [{1}]!'.format(posColSubt, ','.join(cand_pos)))
    kw_proc = kw.copy()
    if len(kw_proc.get('index', [])) == 0:
        fRowTot = False
        fRowSubt = False
    else:
        if isinstance(kw_proc['index'], str):
            kw_proc['index'] = [kw_proc['index']]
        elif isinstance(kw_proc['index'], Iterable):
            kw_proc['index'] = list(kw_proc['index'])
    if len(kw_proc.get('columns', [])) == 0:
        fColTot = False
        fColSubt = False
    else:
        if isinstance(kw_proc['columns'], str):
            kw_proc['columns'] = [kw_proc['columns']]
        elif isinstance(kw_proc['columns'], Iterable):
            kw_proc['columns'] = list(kw_proc['columns'])
    #Ensure the same behavior as [pd.pivot_table]
    if 'margins' in kw:
        fRowTot = kw_proc['margins']
        fRowSubt = kw_proc['margins']
        fColTot = kw_proc['margins']
        fColSubt = kw_proc['margins']
        kw_proc.pop('margins')
    if 'margins_name' in kw:
        rowTot = kw_proc['margins_name']
        colTot = kw_proc['margins_name']
        kw_proc.pop('margins_name')
    if 'sort' in kw:
        rowSortAsc = kw_proc['sort']
        colSortAsc = kw_proc['sort']
        kw_proc['sort'] = False

    #050. Local parameters
    var_rows = kw_proc.get('index', [])
    var_cols = kw_proc.get('columns', [])
    f_rows = len(var_rows) > 0
    f_cols = len(var_cols) > 0
    f_totals_row = f_rows & ( fRowTot | fRowSubt )
    f_totals_col = f_cols & ( fColTot | fColSubt )
    f_totals_cross = f_totals_row & f_totals_col
    name_vals = '.pivot.values.'
    name_stats = '.pivot.stats.'

    #060. Calculate levels of all dimensions for later sorting
    #[ASSUMPTION]
    #[1] The order of values is defined automatically at this step
    dim_cols = var_rows + var_cols
    val_unique = {
        c : { v:i for i,v in enumerate(df[c].sort_values().unique().tolist()) }
        for c in dim_cols
    }

    #070. Patch the default order of values when required
    if isinstance(keyPatcher, dict):
        val_unique = modifyDict(val_unique, keyPatcher)

    #079. Abort if the names of Grand Totals or Subtotals are the same as any among the unique data values
    val_any = [ k for c in list(val_unique.values()) for k in list(c.keys()) ]
    if f_totals_row:
        if fRowTot and (rowTot in val_any):
            raise ValueError('[' + LfuncName + '][rowTot]:[{0}] conflicts with the data dimension values!'.format(str(rowTot)))
        if fRowSubt and (rowSubt in val_any):
            raise ValueError('[' + LfuncName + '][rowSubt]:[{0}] conflicts with the data dimension values!'.format(str(rowSubt)))
    if f_totals_col:
        if fColTot and (colTot in val_any):
            raise ValueError('[' + LfuncName + '][colTot]:[{0}] conflicts with the data dimension values!'.format(str(colTot)))
        if fColSubt and (colSubt in val_any):
            raise ValueError('[' + LfuncName + '][colSubt]:[{0}] conflicts with the data dimension values!'.format(str(colSubt)))

    #100. Create base pivot table
    pvt_base = df.copy(deep = True).pivot_table(**kw_proc)

    #200. Helper functions
    #210. Function to act as key for sorting of any [pd.Series]
    def h_sort(vec, ascending, pos_total, pos_subtotal, val_total, val_subtotal):
        #100. Obtain the dedicated sequence of unique values for current input vector
        vec_unique = val_unique.get(vec.name, {})
        if len(vec_unique) == 0: return(vec)

        #400. Determine the position of Grand Totals and Subtotals
        if ascending:
            rst_total = -2 if pos_total == 'before' else len(vec_unique) + 2
            rst_subtotal = -1 if pos_subtotal == 'before' else len(vec_unique) + 1
        else:
            rst_total = -2 if pos_total != 'before' else len(vec_unique) + 2
            rst_subtotal = -1 if pos_subtotal != 'before' else len(vec_unique) + 1

        #700. Set the sequence of the values for the input vector
        rstOut = (
            vec
            .copy(deep = True)
            .map(vec_unique)
            .where(vec != val_total, rst_total)
            .where(vec != val_subtotal, rst_subtotal)
        )

        #999. Return the final sequence
        return(rstOut)

    #230. Function to prepare the combination of subtotals and grand totals
    def h_dim(obj, i, val_total, val_subtotal):
        placeholder = val_total if i == 0 else val_subtotal
        rstOut = {
            v : (placeholder if j == i else '')
            for j,v in enumerate(obj)
            if j >= i
        }
        return(rstOut)

    #250. Function to mutate the data and calculate pivot
    def h_pivot(df, ren):
        df_mutate = df.copy(deep = True)
        df_mutate.loc[:, list(ren.keys())] = df_mutate[list(ren.keys())].astype('object')
        rstOut = (
            df_mutate
            .assign(**ren)
            .pivot_table(**kw_proc)
        )
        return(rstOut)

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
        pvt_base = pd.concat(
            [ pvt_base, pvt_by_y ]
            ,axis = 0
            ,sort = False
            ,ignore_index = False
        )

    #640. Add column totals if any
    if f_totals_col:
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
    pvt_base.sort_values(pvt_base.index.names, inplace = True, ascending = rowSortAsc, key = h_sort_row)

    #840. Sort columns
    #841. Set the names for special levels
    pvt_base.columns.set_names(name_vals, inplace = True, level = 0)
    if pvt_base.columns.nlevels == len(var_cols) + 2:
        pvt_base.columns.set_names(name_stats, inplace = True, level = 1)

    #842. Extract the y-axis index from the pivot table
    idx_cols = pvt_base.columns

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
    idx_cols_sorted = idx_cols.sort_values(ascending = colSortAsc, key = h_sort_col)

    #849. Assign the new columns as the final result
    pvt_base = pvt_base.copy(deep = True).reindex(idx_cols_sorted, axis = 'columns')

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
    udf_pvt2 = pandasPivot(
        udf
        ,index = ['mode','choice']
        ,columns = ['psize','hinc']
        ,values = ['invc','gc']
        ,aggfunc = { 'invc' : [np.nansum, srs_nunique], 'gc' : [np.nanmean, np.nanmax] }
        ,fill_value = 0
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
            ,'.pivot.stats.' : { np.nanmean.__name__ : 0, np.nanmax.__name__ : 1 }
        }
    )
#-Notes- -End-
'''