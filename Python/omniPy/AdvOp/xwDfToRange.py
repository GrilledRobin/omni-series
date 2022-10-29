#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import numpy as np
import xlwings as xw
from collections.abc import Iterable
from collections import OrderedDict
from typing import Union, List, Optional
from omniPy.AdvOp import rsetattr
from omniPy.Styles import theme_xwtable

def xwDfToRange(
    rng : xw.Range
    ,df : pd.DataFrame
    ,index : bool = True
    ,index_name : bool = True
    ,header : bool = True
    ,mergeIdx : Union[bool, int, Iterable[Optional[int]]] = True
    ,mergeHdr : Union[bool, int, Iterable[Optional[int]]] = True
    ,stripe : bool = True
    ,theme : str = 'BlackGold'
    ,fmtRow : List[dict] = []
    ,fmtCol : List[dict] = []
    ,asformatter : bool = False
) -> 'Export the data frame to the specified xw.Range with certain theme':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to export the data frame to the specified xw.Range with certain theme                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Setup universal styles when exporting multiple data frames into EXCEL                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |rng         :   EXCEL range object, in which to pour the data                                                                      #
#   |df          :   Data frame to be output to [rng], from which also to extract sub-ranges for styling                                #
#   |index       :   Logical value indicating whether to export [df.index] as well                                                      #
#   |                [True        ] <Default> Export [df.index] to the left of the data range                                           #
#   |                [False       ]           Do not export [df.index]                                                                  #
#   |index_name  :   Logical value indicating whether to keep [df.index.names] during export                                            #
#   |                [True        ] <Default> Export [df.index.names] to the bottom of the box, given a [box] is to be written          #
#   |                [False       ]           Do not export [df.index.names]                                                            #
#   |header      :   Logical value indicating whether to export [df.columns] as well                                                    #
#   |                [True        ] <Default> Export [df.columns] to the upper side of the data range                                   #
#   |                [False       ]           Do not export [df.columns]                                                                #
#   |mergeIdx    :   Various value indicating whether to merge vertically adjacent cells with the same values in [df.index], or such    #
#   |                 cells in any provided [levels] of [df.index]                                                                      #
#   |                [True        ] <Default> Merge cells on all levels other than [levels[-1]] in [df.index], indicating a pivot table #
#   |                [False       ]           Do not merge the adjacent cells                                                           #
#   |                [<int>       ]           Merge cells on the dedicated level id                                                     #
#   |                [<str>       ]           Merge cells on the dedicated level name                                                   #
#   |                [Iterable    ]           Accept either Iterable[int] or Iterable[names], where [names] indicate the names of the   #
#   |                                          pd.Index                                                                                 #
#   |mergeHdr    :   Various value indicating whether to merge horizontally adjacent cells with the same values in [df.columns], or such#
#   |                 cells in any provided [levels] of [df.columns]                                                                    #
#   |                [True        ] <Default> Merge cells on all levels other than [levels[-1]] in [df.columns], indicating a pivot     #
#   |                                          table                                                                                    #
#   |                [False       ]           Do not merge the adjacent cells                                                           #
#   |                [<int>       ]           Merge cells on the dedicated level id                                                     #
#   |                [<str>       ]           Merge cells on the dedicated level name                                                   #
#   |                [Iterable    ]           Accept either Iterable[int] or Iterable[names], where [names] indicate the names of the   #
#   |                                          pd.Index                                                                                 #
#   |stripe      :   Logical value indicating whether to create stripes on data rows, resembling the empirical EXCEL styles             #
#   |                [True        ] <Default> Create stripes on data rows, as well as df.index.get_level_values(-1) if [index=True]     #
#   |                [False       ]           Do not create stripes                                                                     #
#   |theme       :   Theme of styles for the exported range, see details in [omniPy.Styles.theme_xwtable]                               #
#   |                [BlackGold   ] <Default> Default theme                                                                             #
#   |                [<str>       ]           Other predefined theme name                                                               #
#   |fmtRow      :   List of dicts, in which the items represent various value indicating which rows to be patched by what formats:     #
#   |                 List[{'slicer':[],'attrs':{}},...], where 'slicer' is a slicer (int, index name, or Iterable of the previous) to  #
#   |                 the index while 'attrs' is a dict of arguments to the function [omniPy.AdvOp.rsetattr], see                       #
#   |                 the function [omniPy.Styles.theme_xwtable] for its usage                                                          #
#   |                Possible values for 'slicer' are as below:                                                                         #
#   |                [<int>       ]           Number of rows counting from 0 to be formatted                                            #
#   |                [<str>       ]           Index of rows to be formatted, must be at least one tuple enclosed by a list for a        #
#   |                                          pd.MultiIndex                                                                            #
#   |                [Iterable    ]           Accept either Iterable[int] or Iterable[names], where [names] indicate the names of the   #
#   |                                          pd.Index                                                                                 #
#   |fmtCol      :   List of dicts, in which the items represent various value indicating which columns to be patched by what formats:  #
#   |                 List[{'slicer':[],'attrs':{}},...], where 'slicer' is a slicer (int, column name, or Iterable of the previous) to #
#   |                 the column while 'attrs' is a dict of arguments to the function [omniPy.AdvOp.rsetattr], see                      #
#   |                 the function [omniPy.Styles.theme_xwtable] for its usage                                                          #
#   |                [IMPORTANT   ] The formatting applied to columns is later than that applied to rows, hence overwrites it anyway    #
#   |                Possible values for 'slicer' are as below:                                                                         #
#   |                [<int>       ]           Number of columns counting from 0 to be formatted                                         #
#   |                [<str>       ]           Index of columns to be formatted, must be at least one tuple enclosed by a list for a     #
#   |                                          pd.MultiIndex                                                                            #
#   |                [Iterable    ]           Accept either Iterable[int] or Iterable[names], where [names] indicate the names of the   #
#   |                                          pd.Index                                                                                 #
#   |asformatter :   Logical value indicating whether to act as a formatter function for xw.Range. One needs to call [functools.partial]#
#   |                 to set the parameters other than [rng] and [df] in order to use it in such case                                   #
#   |                [False       ] <Default> Call this function to export [df] to the predefined [rng] directly                        #
#   |                [True        ]           Only format the predefined [rng] without exporting the data of [df]                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not have return value                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20221029        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas, numpy, xlwings, collections, typing                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |rsetattr                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Styles                                                                                                                  #
#   |   |   |theme_xwtable                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    if isinstance(mergeIdx, bool):
        idx_to_merge = list(range(df.index.nlevels - 1)) if (index and mergeIdx) else []
    elif isinstance(mergeIdx, int):
        idx_to_merge = [mergeIdx]
    elif isinstance(mergeIdx, Iterable):
        if np.all(list(map(lambda x: isinstance(x, int), mergeIdx))):
            idx_to_merge = mergeIdx
        else:
            idx_to_merge = pd.Index(df.index.names).get_indexer([mergeIdx] if isinstance(mergeIdx, str) else mergeIdx)
    else:
        raise TypeError('[' + LfuncName + '][mergeIdx]:[{0}] cannot be processed!'.format( type(mergeIdx) ))

    if isinstance(mergeHdr, bool):
        hdr_to_merge = list(range(df.columns.nlevels - 1)) if (header and mergeHdr) else []
    elif isinstance(mergeHdr, int):
        hdr_to_merge = [mergeHdr]
    elif isinstance(mergeHdr, Iterable):
        if np.all(list(map(lambda x: isinstance(x, int), mergeHdr))):
            hdr_to_merge = mergeHdr
        else:
            hdr_to_merge = pd.Index(df.columns.names).get_indexer([mergeHdr] if isinstance(mergeHdr, str) else mergeHdr)
    else:
        raise TypeError('[' + LfuncName + '][mergeHdr]:[{0}] cannot be processed!'.format( type(mergeHdr) ))

    #050. Local parameters
    seq_ranges = ['table','data.int','data.float','data','index','index.merge','header','header.merge','box','stripe']
    row_adj = df.columns.nlevels if header else 0
    col_adj = df.index.nlevels if index else 0
    xlsh = rng.sheet
    table_top, table_left = rng.row, rng.column
    table_bottom = table_top + row_adj + len(df) - 1
    table_right = table_left + col_adj + len(df.columns) - 1
    data_top = table_top + row_adj
    data_left = table_left + col_adj
    box_bottom = data_top - 1
    box_right = data_left - 1
    xlrng = {}

    #100. Helper functions
    #110. Function to identify the adjacent rows/columns to merge in terms of [attr]
    def h_idx_merge_grp(i, attr):
        idx_reset = getattr(df, attr).get_level_values(i).to_series().reset_index(drop = True)
        idx_tail = idx_reset.ne(idx_reset.shift(1, fill_value = True)).cumsum().value_counts().sort_index().cumsum()
        idx_head = idx_tail.shift(1, fill_value = 0).add(1)
        pos = list(zip(idx_head[idx_head.ne(idx_tail)].to_list(), idx_tail[idx_head.ne(idx_tail)].to_list()))
        return(pos)

    #200. Identify the areas to be merged
    #210. Merged indexes
    merged_idx = { i:h_idx_merge_grp(i, 'index') for i in idx_to_merge }
    xlmerge_idx = [
        xlsh.range(
            (data_top + pos[0] - 1, table_left + k)
            ,(data_top + pos[-1] - 1, table_left + k)
        )
        for k,v in merged_idx.items()
        for pos in v
    ]

    #220. Merged headers
    merged_hdr = { i:h_idx_merge_grp(i, 'columns') for i in hdr_to_merge }
    xlmerge_hdr = [
        xlsh.range(
            (table_top + k, data_left + pos[0] - 1)
            ,(table_top + k, data_left + pos[-1] - 1)
        )
        for k,v in merged_hdr.items()
        for pos in v
    ]

    #400. Define dedicated ranges
    #410. Range for the entire table
    xlrng['table'] = [
        xlsh.range(
            (table_top, table_left)
            ,(table_bottom, table_right)
        )
    ]

    #420. Ranges by data types
    #421. Integers
    col_int_flag = df.dtypes.apply(pd.api.types.is_integer_dtype)
    col_int = [
        i + table_left + col_adj
        for i,v in enumerate(df.columns)
        if col_int_flag[i]
    ]
    xlrng['data.int'] = [
        xlsh.range(
            (data_top, col)
            ,(table_bottom, col)
        )
        for col in col_int
    ]

    #422. Floats
    col_float_flag = df.dtypes.apply(pd.api.types.is_float_dtype)
    col_float = [
        i + table_left + col_adj
        for i,v in enumerate(df.columns)
        if col_float_flag[i]
    ]
    xlrng['data.float'] = [
        xlsh.range(
            (data_top, col)
            ,(table_bottom, col)
        )
        for col in col_float
    ]

    #430. Ranges expanded from the merged ones
    #431. Ranges expanded from the vertically merged index levels
    xlrng['index.merge'] = [
        xlsh.range(
            (data_top + pos[0] - 1, table_left + k)
            ,(data_top + pos[-1] - 1, table_right)
        )
        for k,v in merged_idx.items()
        for pos in v
    ]

    #432. Ranges expanded from the horizontally merged column levels
    xlrng['header.merge'] = [
        xlsh.range(
            (table_top + k, data_left + pos[0] - 1)
            ,(table_bottom, data_left + pos[-1] - 1)
        )
        for k,v in merged_hdr.items()
        for pos in v
    ]

    #440. Range for the box crossing index and header
    if index & header:
        xlrng['box'] = [
            xlsh.range(
                (table_top, table_left)
                ,(box_bottom, box_right)
            )
        ]
    else:
        xlrng['box'] = []

    #450. Range for the data part
    xlrng['data'] = [
        xlsh.range(
            (data_top, data_left)
            ,(table_bottom, table_right)
        )
    ]

    #460. Header
    if header:
        xlrng['header'] = [
            xlsh.range(
                (table_top, data_left)
                ,(box_bottom, table_right)
            )
        ]
    else:
        xlrng['header'] = []

    #470. Index
    if index:
        xlrng['index'] = [
            xlsh.range(
                (data_top, table_left)
                ,(table_bottom, box_right)
            )
        ]
    else:
        xlrng['index'] = []

    #480. Stripes
    #481. Identify the levels to create stripes within [df.index] range
    lvl_stripe = [ i for i in range(df.index.nlevels) if i not in idx_to_merge ]
    xlstripe_idx = [
        xlsh.range(
            (data_top, table_left + i)
            ,(table_bottom, table_left + i)
        )
        for i in lvl_stripe
    ]

    #489. Combine the list of ranges to create the stripes
    if stripe:
        xlrng['stripe'] = xlstripe_idx + xlrng['data']
    else:
        xlrng['stripe'] = []

    #500. Export the data to the entire range
    if not asformatter:
        #100. Create a copy of the data frame to avoid modification on the original object
        df_copy = df.copy(deep = True)

        #300. Remove the names of [df.index] during the export
        if not (index & header & index_name):
            df_copy.index.names = [ None for i in range(len(df_copy.index.names)) ]

        #900. Write the data
        rng.value = df_copy

    #600. Setup styles for the predefined ranges
    #610. Retrieve the theme as requested
    table_theme = theme_xwtable(theme)

    #630. Reorder the ranges so that the styles for the latters overwrite those for the formers
    xlrng = OrderedDict({ k:xlrng.get(k) for k in seq_ranges if k in xlrng })

    #650. Set the styles in loop
    for k,v in xlrng.items():
        #100. Retrieve the styles for current item
        item_theme = table_theme.get(k, {})
        if not len(item_theme): continue

        #500. Differentiate the scenarios
        # print(k)
        for r in v:
            for debugname, attr in item_theme.items():
                # print([r.row, r.column])
                # print(debugname)
                if k in ['stripe']:
                    # print(r.address)
                    #Quote: https://docs.xlwings.org/en/latest/converters.html
                    for ix, row in enumerate(r.rows):
                        if ix % 2 == 0:
                            rsetattr(row, **attr)
                else:
                    rsetattr(r, **attr)

    #700. Set the styles of the requested ranges
    #710. Specific rows of the data part
    for m in fmtRow:
        #001. Extract the members
        k,v = m.get('slicer'), m.get('attrs')

        #100. Translate the indexer
        if k == '.all.':
            row_to_fmt = list(range(len(df.index)))
        elif isinstance(k, int):
            row_to_fmt = [k]
        elif isinstance(k, Iterable):
            if np.all(list(map(lambda x: isinstance(x, int), k))):
                row_to_fmt = k
            else:
                row_to_fmt = df.index.get_indexer([k] if isinstance(k, str) else k)
        else:
            raise TypeError('[' + LfuncName + f'][fmtRow]:[{str(k)}] cannot be used to slice df.index!' )

        #500. Set the styles row by row (since the slicer may not be continuous)
        row_to_fmt = [ i for i in row_to_fmt if i in range(len(df)) ]
        for f_row in row_to_fmt:
            #100. Identify the range
            row_rng = xlsh.range(
                (data_top + f_row, data_left)
                ,(data_top + f_row, table_right)
            )

            #500. Set the styles
            for attr in v.values():
                rsetattr(row_rng, **attr)

    #720. Specific columns of the data part
    for m in fmtCol:
        #001. Extract the members
        k,v = m.get('slicer'), m.get('attrs')

        #100. Translate the indexer
        if k == '.all.':
            col_to_fmt = list(range(len(df.columns)))
        elif isinstance(k, int):
            col_to_fmt = [k]
        elif isinstance(k, Iterable):
            if np.all(list(map(lambda x: isinstance(x, int), k))):
                col_to_fmt = k
            else:
                col_to_fmt = df.columns.get_indexer([k] if isinstance(k, str) else k)
        else:
            raise TypeError('[' + LfuncName + f'][fmtCol]:[{str(k)}] cannot be used to slice df.columns!' )

        #500. Set the styles column by column (since the slicer may not be continuous)
        col_to_fmt = [ i for i in col_to_fmt if i in range(len(df.columns)) ]
        for f_col in col_to_fmt:
            #100. Identify the range
            col_rng = xlsh.range(
                (data_top, data_left + f_col)
                ,(table_bottom, data_left + f_col)
            )

            #500. Set the styles
            for attr in v.values():
                rsetattr(col_rng, **attr)

    #800. Merge the ranges as requested
    for r in xlmerge_idx + xlmerge_hdr:
        r.merge()
#End xwDfToRange

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import numpy as np
    import pandas as pd
    import xlwings as xw
    from functools import partial
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import xwDfToRange

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
    upvt = pd.pivot_table(udf, values='D', index=['A', 'B'],columns=['C','D'], aggfunc=np.sum, fill_value = 0)

    #200. Set the universal parameters
    args_xw = {
        'index' : True
        ,'header' : True
        ,'mergeIdx' : True
        ,'mergeHdr' : True
        ,'stripe' : True
        ,'theme' : 'BlackGold'
        ,'fmtRow' : []
        ,'fmtCol' : [
            {
                'slicer' : [1,5]
                ,'attrs' : {
                    'NumberFormat' : {
                        'attr' : 'api.NumberFormat'
                        ,'val' : '_( * #,##0.00,,"M"_) ;_ (* #,##0.00,,"M")_ ;_( * "-"??_) ;_ @_ '
                    }
                }
            }
            ,{
                'slicer' : [('large', 7)]
                ,'attrs' : {
                    'NumberFormat' : {
                        'attr' : 'api.NumberFormat'
                        ,'val' : '_( * #,##0.00%_) ;_ (* #,##0.00%)_ ;_( * "-"??_) ;_ @_ '
                    }
                }
            }
        ]
    }

    xwfmtter = partial(xwDfToRange, asformatter = True, **args_xw)

    #300. Export the data into an EXCEL file with default theme
    xlfile = os.path.join(dir_omniPy, 'omniPy', 'AdvOp', 'test.xlsx')
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
        xlrng = xlsh.range('B2').expand().options(pd.DataFrame, index = True, header = True)

        #500. Export the data
        xwDfToRange(
            xlrng
            ,upvt
            ,asformatter = False
            ,**args_xw
        )

        #600. Export the data as the formatter
        #20221029 It is tested that the formatter has no effect where [xlwings <= 0.27.15]
        xlrng2 = xlsh.range('B20').expand().options(pd.DataFrame, index = True, header = True, formatter = xwfmtter)
        xlrng2.value = upvt

        #999. Purge
        xlwb.save(xlfile)
        xlwb.close()
        xlapp.screen_updating = True

    if os.path.isfile(xlfile): os.remove(xlfile)
#-Notes- -End-
'''
