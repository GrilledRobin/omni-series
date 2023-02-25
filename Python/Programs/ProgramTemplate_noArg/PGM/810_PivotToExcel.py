#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#[FEATURE]
#[1] Create customized pivot table
#[2] Export the pivot table to EXCEL
#[3] Set the theme for the pivot table in EXCEL
#[4] Highlight the top-3 values in the data part of the pivot table, as well as their respective axis names
#[5] Add groups and outlines for the necessary ranges and display the outline level 2 as common reporting convention
logger.info('Create themed pivot table in EXCEL')
import os
import pandas as pd
import numpy as np
import xlwings as xw
from functools import reduce, partial
from scipy.stats import rankdata
from xlwings.constants import LineStyle as xwLS
from xlwings.constants import BordersIndex as xwBI
from xlwings.constants import BorderWeight as xwBW
from omniPy.AdvOp import pandasPivot, xwDfToRange, xwGroupForDf

# scr_name = r'D:\Python\Programs\ProgramTemplate_noArg\PGM\main.py'

#100. Parameters
L_stpflnm = os.path.join(dir_out, 'xlPivot.xlsx')
xlsh_name = 'Pivot'
color_dark = '#202122'
color_light = '#FFE8CB'
#Classic green of MS PowerBI default theme
color_highlight = '#01B8AA'
pvt_topleft = (2,2)

#Below sample is from Pandas official website:
#Quote: https://pandas.pydata.org/docs/reference/api/pandas.pivot_table.html?highlight=pivot_table#pandas.pivot_table
testdf = pd.DataFrame({
    'A': ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar']
    ,'B': ['one', 'one', 'one', 'two', 'two', 'one', 'one', 'two', 'two']
    ,'C': ['small', 'large', 'large', 'small', 'small', 'large', 'small', 'small', 'large']
    ,'D': [1, 2, 2, 3, 3, 4, 5, 6, 7]
    ,'E': [2, 4, 5, 5, 6, 6, 8, 9, 9]
})

#200. Setup customization of styles
#210. Set the [totals] part as bold font with a line on the top edge
xw_totals = {
    'Borders.xlEdgeTop.LineStyle' : {
        'attr' : 'api.Borders.LineStyle'
        ,'val' : xwLS.xlContinuous
        ,'args' : {
            'api.Borders' : {
                'pos' : (xwBI.xlEdgeTop,)
            }
        }
    }
    ,'Borders.xlEdgeTop.Weight' : {
        'attr' : 'api.Borders.Weight'
        ,'val' : xwBW.xlThin
        ,'args' : {
            'api.Borders' : {
                'pos' : (xwBI.xlEdgeTop,)
            }
        }
    }
    ,'Borders.xlEdgeTop.Color' : {
        'attr' : 'api.Borders.Color'
        ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_light))
        ,'args' : {
            'api.Borders' : {
                'pos' : (xwBI.xlEdgeTop,)
            }
        }
    }
    ,'Font.Bold' : {
        'attr' : 'api.Font.Bold'
        ,'val' : True
    }
}

#230. Set the [Pct] column as percentage
xw_pct = {
    'NumberFormat' : {
        'attr' : 'api.NumberFormat'
        ,'val' : '_( * #,##0.00%_) ;_ (* #,##0.00%)_ ;_( * "-"??_) ;_ @_ '
    }
}

#270. Set the font color of the top 3 stats as the classic Green of MS PowerBI default theme
xw_highlight = {
    'Font.Color' : {
        'attr' : 'api.Font.Color'
        #[IMPORTANT] This value must be converted to [int] for above API [xlwings <= 0.27.15]
        ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_highlight))
    }
}

#300. Pivot table with customized subtotals and totals
args_sums = {
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
udf_pvt_pre = pandasPivot(
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
    ,**args_sums
)
udf_pvt_pre.columns = udf_pvt_pre.columns.droplevel(-1)

#350. Calculate the [Pct] column
udf_pvt = (
    udf_pvt_pre
    .assign(**{
        'Total' : lambda x: x['Total'].astype(int)
        ,'Pct' : lambda x: x['one'].div(x['Total'], fill_value = 0.0)
    })
)

#500. Identify the positions of the top 3 numbers within the pivot table
#510. Mask the rows other than [subtotals] and [totals]
mask_row_not_tot = list(reduce(
    lambda x,y: x & y
    ,[ ~udf_pvt_pre.index.get_level_values(i).isin(['Total','Subtotal']) for i in range(udf_pvt_pre.index.nlevels) ]
))

#530. Mask the columns other than [subtotals] and [totals]
mask_col_not_tot = list(reduce(
    lambda x,y: x & y
    ,[ ~udf_pvt_pre.columns.get_level_values(i).isin(['Total','Subtotal']) for i in range(udf_pvt_pre.columns.nlevels) ]
))

#550. Rank the full data (excluding the subtotals and totals) by descending order
udf_pvt_data = udf_pvt_pre.loc[mask_row_not_tot, mask_col_not_tot].copy(deep = True)
mat_pvt = np.matrix( udf_pvt_data.mul(-1) )
#Should any cells have the same value, we rank them by their ordinal position, first come first serve
maxval = rankdata(mat_pvt, method = 'ordinal').reshape(mat_pvt.shape)

#570. Locate the top 3 values within the matrix
#Quote: https://stackoverflow.com/questions/26193386/numpy-zip-function
pos_tops = np.stack(np.where(maxval <= 3), axis = 1)

#590. Translate the locations into the positions in the final pivot table
pos_tops_pvt = [
    (
        udf_pvt_data.index.take([i])
        ,udf_pvt_data.columns.take([j])
    )
    for i,j in pos_tops
]

#600. Set the arguments for exporting data to EXCEL
args_axis = {
    'index' : True
    ,'header' : True
}
args_idx = {
    'mergeIdx' : True
    ,'mergeHdr' : True
}
args_xw = {
    'stripe' : True
    ,'theme' : 'BlackGold'
    ,'fmtIdx' : [
        #Set style for the last row of index
        {
            'slicer' : -1
            ,'attrs' : xw_totals
        }
    ] + [
        #Highlight the values of the last level of index on which the top-3 values reside
        {
            'slicer' : i
            ,'attrs' : xw_highlight
            ,'levels' : -1
        }
        for i,j in pos_tops_pvt
    ]
    ,'fmtRow' : [
        #Set style for the last row of data part
        {
            'slicer' : -1
            ,'attrs' : xw_totals
        }
    ]
    ,'fmtHdr' : [
        #Highlight the values of the last level of column names on which the top-3 values reside
        {
            'slicer' : j
            ,'attrs' : xw_highlight
            ,'levels' : -1
        }
        for i,j in pos_tops_pvt
    ]
    ,'fmtCol' : [
        #Set below column as percentage
        {
            'slicer' : ['Pct']
            ,'attrs' : xw_pct
        }
    ]
    ,'fmtCell' : [
        #Highlight the top-3 values among the entire table in the data part
        {
            'slicer' : v
            ,'attrs' : xw_highlight
        }
        for v in pos_tops_pvt
    ]
}

#900. Export the data into an EXCEL file with default theme
#901. Prepare functions for easy calls
fmt_DfToRange = partial(
    xwDfToRange
    ,asformatter = True
    ,**args_axis
    ,**args_idx
    ,**args_xw
)
fmt_GroupForDf = partial(
    xwGroupForDf
    ,asformatter = False
    ,formatOnly = True
    ,kw_pvtLike = args_sums
    ,**args_axis
    ,**args_idx
)

if os.path.isfile(L_stpflnm): os.remove(L_stpflnm)
with xw.App( visible = False, add_book = True ) as xlapp:
    #010. Set options
    xlapp.display_alerts = False
    xlapp.screen_updating = False

    #100. Identify the EXCEL workbook
    xlwb = xlapp.books[0]

    #300. Define the sheet
    xlsh = xlwb.sheets[0]

    #400. Define the range
    xlrng = (
        xlsh.range(pvt_topleft).expand()
        #[ASSUMPTION]
        #[1] It is tested that chains of [options()] only validate the last one [xlwings <= 0.28.5]
        .options(pd.DataFrame, formatter = fmt_DfToRange, **args_axis)
        # .options(formatter = fmt_bold)
    )

    #500. Export the data
    xlsh.cells.color = xw.utils.hex_to_rgb(color_dark)
    xlrng.value = udf_pvt

    #600. Add groups and outlines
    #[ASSUMPTION]
    #[1] Since the column total is no longer the last column in [udf_pvt], the grouping function fails to locate it
    #[2] We should use [udf_pvt_pre] as the model dataframe for formatting instead
    fmt_GroupForDf(xlrng, udf_pvt_pre)

    #800. More settings
    xlsh.autofit()

    #999. Purge
    xlwb.save(L_stpflnm)
    xlwb.close()
    xlapp.screen_updating = True
