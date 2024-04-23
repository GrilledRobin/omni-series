#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re
import pandas as pd
import numpy as np
#We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings < 0.27.15] and [Python <= 3.7]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import xlwings as xw
import itertools as itt
from collections.abc import Iterable
from collections import OrderedDict
from typing import Union, List, Optional
from omniPy.AdvOp import rsetattr, pandasParseIndexer
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
    ,fmtIdx : List[dict] = []
    ,fmtRow : List[dict] = []
    ,fmtHdr : List[dict] = []
    ,fmtCol : List[dict] = []
    ,fmtCell : List[dict] = []
    ,asformatter : bool = False
    ,formatOnly : bool = False
    ,idxall : str = '.all.'
) -> None:
    #000. Info.
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
#   |fmtIdx      :   List of dicts, in which the items represent various value indicating which items to be patched on index:           #
#   |                 List[{'slicer':[],'attrs':{}},...], where 'slicer' is a slicer (int, index name, or Iterable of the previous) to  #
#   |                 the index while 'attrs' is a dict of arguments to the function [omniPy.AdvOp.rsetattr], see                       #
#   |                 the function [omniPy.Styles.theme_xwtable] for its usage                                                          #
#   |                Possible values for 'slicer' are as below:                                                                         #
#   |                [<int>       ]           Number of rows counting from 0 to be formatted                                            #
#   |                [<str>       ]           Index of rows to be formatted, must be at least one tuple enclosed by a list for a        #
#   |                                          pd.MultiIndex                                                                            #
#   |                [Iterable    ]           Accept either Iterable[int] or Iterable[names], where [names] indicate the names of the   #
#   |                                          pd.Index                                                                                 #
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
#   |fmtHdr      :   List of dicts, in which the items represent various value indicating which items to be patched on column names:    #
#   |                 List[{'slicer':[],'attrs':{}},...], where 'slicer' is a slicer (int, index name, or Iterable of the previous) to  #
#   |                 the index while 'attrs' is a dict of arguments to the function [omniPy.AdvOp.rsetattr], see                       #
#   |                 the function [omniPy.Styles.theme_xwtable] for its usage                                                          #
#   |                Possible values for 'slicer' are as below:                                                                         #
#   |                [<int>       ]           Number of columns counting from 0 to be formatted                                         #
#   |                [<str>       ]           Index of columns to be formatted, must be at least one tuple enclosed by a list for a     #
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
#   |fmtCell     :   List of dicts, in which the items represent various value indicating which cells to be patched:                    #
#   |                 List[{'slicer':[],'attrs':{}},...], where 'slicer' is a slicer (int, index name, or Iterable of the previous) to  #
#   |                 the index while 'attrs' is a dict of arguments to the function [omniPy.AdvOp.rsetattr], see                       #
#   |                 the function [omniPy.Styles.theme_xwtable] for its usage                                                          #
#   |                Possible values for 'slicer' are as below:                                                                         #
#   |                [<int>       ]           Number of rows counting from 0 to be formatted                                            #
#   |                [<str>       ]           Index of rows to be formatted, must be at least one tuple enclosed by a list for a        #
#   |                                          pd.MultiIndex                                                                            #
#   |                [Iterable    ]           Accept either Iterable[int] or Iterable[names], where [names] indicate the names of the   #
#   |                                          pd.Index                                                                                 #
#   |asformatter :   Logical value indicating whether to act as a formatter function for xw.Range. One needs to call [functools.partial]#
#   |                 to set the parameters other than [rng] and [df] in order to use it in such case                                   #
#   |                [False       ] <Default> Call this function to export [df] to the predefined [rng] directly                        #
#   |                [True        ]           Only format the predefined [rng] without exporting the data of [df]                       #
#   |formatOnly  :   Logical value indicating whether only to set the format to the give range while not pouring the data               #
#   |                [IMPORTANT   ] This argument only works when [asformatter = False]                                                 #
#   |                [False       ] <Default> Pour data into the range after formatting                                                 #
#   |                [True        ]           Only format the predefined [rng] without exporting the data of [df]                       #
#   |idxall      :   When matching the provision of [indexer], generate a full indexer for the provided pd.Index                        #
#   |                [.all.       ] <Default> When [indexer=='.all.'], generate a full indexer                                          #
#   |                [<str>       ]           Provide a unique value that is non-existing in [df.index] and [df.columns]                #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221103        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed bugs when sub ranges are not applicable                                                                           #
#   |      |[2] Now push data at the final step, so that all formats can be applied correctly                                           #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221104        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now use EXCEL COM API to set the zebra stripes as conditional formatting, ignoring hidden rows as special effect        #
#   |      |[2] Convert the number-like character columns into [text] format to align the input                                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221105        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce function [pandasParseIndexer] to parse the indexers                                                           #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221107        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when merging indexes with special values, such as [True]                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230111        | Version | 1.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when the input data is empty                                                                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230218        | Version | 1.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Ensure the zebra stripe benchmark range do not contain NA values (unless all cells and indices on a single row are NA)  #
#   |      |[2] Introduce boolean argument [formatOnly] to handle different scenarios when [asformatter == False]                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230228        | Version | 1.70        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Extract the process to create zebra stripes from the main process, to simplify the overall function                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230327        | Version | 1.71        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fix the bug that causes the entire table to be colored the same way as zebra stripes                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |      |[2] Replace <pd.Series[i]> with <pd.Series.iloc[i]> as the former will be deprecated since pandas==2.1.0                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231212        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now set the format of string-like index levels as text as well                                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240103        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when the input data is empty                                                                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240423        | Version | 2.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now respect the usage of <slice> during the preparation of <merge> on indexes                                           #
#   |      |[2] Correct the format when some items on a <merged> index level are not eventually merged, as they only show up in one cell#
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
#   |   |sys, re, pandas, numpy, xlwings, itertools, collections, typing                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |rsetattr                                                                                                                   #
#   |   |   |pandasParseIndexer                                                                                                         #
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
    seq_ranges = [
        'table','data.int','data.float','data'
        ,'index','index.merge','index.merge.rest','header','header.merge','header.merge.rest','box'
        ,'index.False','header.False'
    ]
    row_adj = df.columns.nlevels if header else 0
    col_adj = df.index.nlevels if index else 0
    table_top, table_left = 0,0
    len_row, len_col = df.shape
    table_bottom = table_top + row_adj + len_row - 1
    table_right = table_left + col_adj + len_col - 1
    data_top = table_top + row_adj
    data_left = table_left + col_adj
    box_bottom = data_top - 1
    box_right = data_left - 1
    xlrng = {}
    f_empty = (len_row == 0) or (len_col == 0)

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
        #[ASSUMPTION]
        #[1] <tail> as a slicer cannot be subtracted by 1
        #[2] <tail> as a positional threshold should be subtracted by 1
        pos = list(zip(idx_head[idx_head.ne(idx_tail)].sub(1).to_list(), idx_tail[idx_head.ne(idx_tail)].to_list()))
        return(pos)

    #120. Function to extract the rest of the indexers when any level is to be <merged while some items are not eventually merged
    #[ASSUMPTION]
    #[1] If an item in a level to be <merged> only shows up once in the index, it is usually NOT in the scope of merging cells
    #[2] That is why we need to extract such items to apply the same format as the <merged> ranges
    def h_resi_idx(idx : pd.Index, slicers : list[tuple[int, int]], logname : str = 'fmtRestIdx'):
        indexer = set.union(*[
            set(pandasParseIndexer(idx, slice(*s), idxall = idxall, logname = logname))
            for s in slicers
        ])
        return([(k, k + 1) for k in range(len(idx)) if k not in indexer])

    #170. Function to create zebra stripes in terms of EXCEL COM API as conditional formatting
    #171. Determine the benchmark cell, including row indices if any, to calculate the zebra stripes
    rng_bench = None
    if len(df) != 0:
        #100. Scenario when [index] is to be exported
        if index:
            for i in [ j for j in range(df.index.nlevels) if j not in idx_to_merge ]:
                if df.index.get_level_values(i).notnull().all():
                    rng_bench = rng.__getitem__((
                        slice(data_top, data_top + 1, None)
                        ,slice(table_left + i, table_left + i + 1, None)
                    ))
                    break

        #500. Select the first cell in one column with no NA value as benchmark, given it is still not determined
        if rng_bench is None:
            for i in range(len(df.columns)):
                if df.iloc[:, i].notnull().all():
                    rng_bench = rng.__getitem__((
                        slice(data_top, data_top + 1, None)
                        ,slice(data_left + i, data_left + i + 1, None)
                    ))
                    break

    #175. Prepare the function
    #Quote: https://blog.csdn.net/pingfanren022/article/details/120383187
    def h_stripe(rngslice, attr):
        #100. Setup the formula
        #Quote: https://www.myonlinetraininghub.com/excel-conditional-formatting-zebra-stripes
        #110. Find the address of the benchmark cell
        #[ASSUMPTION]
        #[1] If the benchmark cell is still not determined, we can only use the first cell for current range as benchmark
        #[2] If the latter choice is made, the formula fails given the column of the final benchmark cell contains NA values
        if rng_bench is not None:
            add_bench = rng_bench.address
        else:
            add_bench = rng.__getitem__(rngslice)[0,0].address

        #190. Create the formula for conditional formatting
        uf_stripe = '=MOD(SUBTOTAL(103,{0}:{1}),2)'.format(add_bench, re.sub(r'\$(\d+)$', r'\1', add_bench))

        #200. Identify the sliced range
        subrng = rng.__getitem__(rngslice)

        #300. Set conditional formatting to the sliced range
        subrng.api.FormatConditions.Add(
            xw.constants.FormatConditionType.xlExpression
            ,xw.constants.FormatConditionOperator.xlEqual
            ,uf_stripe
        )

        #400. Make the newly added condition as the top priority
        #[ASSUMPTION]
        #[1] After this step we can use [1] to reference the above rule
        subrng.api.FormatConditions(subrng.api.FormatConditions.Count).SetFirstPriority()

        #500. Remove tint and shade
        subrng.api.FormatConditions(1).Interior.TintAndShade = 0

        #600. Set the color index to the default pattern
        subrng.api.FormatConditions(1).Interior.PatternColorIndex = xw.constants.Constants.xlAutomatic

        #700. Set the stripe color
        subrng.api.FormatConditions(1).Interior.Color = attr.get('val')

    #180. Function to test if an object can be coerced to float
    def testFloat(x):
        try:
            _ = float(str(x))
            return(True)
        except:
            return(False)

    #200. Identify the areas to be merged
    #210. Merged indexes
    merged_idx = { i:h_idx_merge_grp(i, 'index') for i in idx_to_merge }
    xlmerge_idx = [
        (
            slice(data_top + h, data_top + t, None)
            ,slice(table_left + k, table_left + k + 1, None)
        )
        for k,v in merged_idx.items()
        for h,t in v
    ]

    #220. Rest index slicers when they cannot be merged eventually
    merged_idx_rest = {
        lvl : h_resi_idx(df.index, slicer_list, logname = 'fmtRestIdx')
        for lvl,slicer_list in merged_idx.items()
    }

    #250. Merged headers
    merged_hdr = { i:h_idx_merge_grp(i, 'columns') for i in hdr_to_merge }
    xlmerge_hdr = [
        (
            slice(table_top + k, table_top + k + 1, None)
            ,slice(data_left + h, data_left + t, None)
        )
        for k,v in merged_hdr.items()
        for h,t in v
    ]

    #260. Rest header slicers when they cannot be merged eventually
    merged_hdr_rest = {
        lvl : h_resi_idx(df.columns, slicer_list, logname = 'fmtRestHdr')
        for lvl,slicer_list in merged_hdr.items()
    }

    #400. Define dedicated ranges
    #410. Range for the entire table
    xlrng['table'] = [
        (
            slice(table_top, table_bottom + 1, None)
            ,slice(table_left, table_right + 1, None)
        )
    ]

    #420. Ranges by data types
    #421. Integers
    col_int_flag = df.dtypes.apply(pd.api.types.is_integer_dtype)
    col_int = [
        i + table_left + col_adj
        for i,v in enumerate(df.columns)
        if col_int_flag.iloc[i]
    ]
    if f_empty:
        xlrng['data.int'] = []
    else:
        xlrng['data.int'] = [
            (
                slice(data_top, table_bottom + 1, None)
                ,slice(col, col + 1, None)
            )
            for col in col_int
        ]

    #422. Floats
    col_float_flag = df.dtypes.apply(pd.api.types.is_float_dtype)
    col_float = [
        i + table_left + col_adj
        for i,v in enumerate(df.columns)
        if col_float_flag.iloc[i]
    ]
    if f_empty:
        xlrng['data.float'] = []
    else:
        xlrng['data.float'] = [
            (
                slice(data_top, table_bottom + 1, None)
                ,slice(col, col + 1, None)
            )
            for col in col_float
        ]

    #430. Ranges expanded from the merged ones
    #431. Ranges expanded from the vertically merged index levels
    xlrng['index.merge'] = [
        (
            slice(data_top + h, data_top + t, None)
            ,slice(table_left + k, table_right + 1, None)
        )
        for k,v in merged_idx.items()
        for h,t in v
    ]

    #432. Ranges expanded from the vertically merged index levels (for the items that are NOT eventually merged)
    xlrng['index.merge.rest'] = [
        (
            slice(data_top + h, data_top + t, None)
            ,slice(table_left + k, table_right + 1, None)
        )
        for k,v in merged_idx_rest.items()
        for h,t in v
    ]

    #435. Ranges expanded from the horizontally merged column levels
    xlrng['header.merge'] = [
        (
            slice(table_top + k, table_bottom + 1, None)
            ,slice(data_left + h, data_left + t, None)
        )
        for k,v in merged_hdr.items()
        for h,t in v
    ]

    #436. Ranges expanded from the horizontally merged column levels (for the items that are NOT eventually merged)
    xlrng['header.merge.rest'] = [
        (
            slice(table_top + k, table_bottom + 1, None)
            ,slice(data_left + h, data_left + t, None)
        )
        for k,v in merged_hdr_rest.items()
        for h,t in v
    ]

    #440. Range for the box crossing index and header
    if index & header:
        xlrng['box'] = [
            (
                slice(table_top, box_bottom + 1, None)
                ,slice(table_left, box_right + 1, None)
            )
        ]
    else:
        xlrng['box'] = []

    #450. Range for the data part
    if f_empty:
        xlrng['data'] = []
    else:
        xlrng['data'] = [
            (
                slice(data_top, table_bottom + 1, None)
                ,slice(data_left, table_right + 1, None)
            )
        ]

    #460. Header
    if header & (len_col > 0):
        xlrng['header'] = [
            (
                slice(table_top, box_bottom + 1, None)
                ,slice(data_left, table_right + 1, None)
            )
        ]
        xlrng['header.False'] = []
    else:
        xlrng['header'] = []
        xlrng['header.False'] = [
            (
                slice(table_top, table_bottom + 1, None)
                ,slice(table_left, table_right + 1, None)
            )
        ]

    #470. Index
    if index & (len_row > 0):
        xlrng['index'] = [
            (
                slice(data_top, table_bottom + 1, None)
                ,slice(table_left, box_right + 1, None)
            )
        ]
        xlrng['index.False'] = []
    else:
        xlrng['index'] = []
        xlrng['index.False'] = [
            (
                slice(table_top, table_bottom + 1, None)
                ,slice(table_left, table_right + 1, None)
            )
        ]

    #480. Stripes
    #481. Identify the levels to create stripes within [df.index] range
    if index & (len_row > 0):
        lvl_stripe = [ i for i in range(df.index.nlevels) if i not in idx_to_merge ]
        xlstripe_idx = [
            (
                slice(data_top, table_bottom + 1, None)
                ,slice(table_left + i, table_left + i + 1, None)
            )
            for i in lvl_stripe
        ]
    else:
        xlstripe_idx = []

    #500. Find ranges with numbers stored as [text] and set their NumberFormat as [text] with intention
    #510. Within the data part
    if len(xlrng['data']) > 0:
        #100. Identify all columns with numbers stored as [text]
        #[ASSUMPTION]
        #[1] Identify the columns by either [dtype==object] or [dtype==string]
        #[2] Identify any cell that stores pure digits among above columns
        #[3] Identify columns with all values are NULL (but not pd.NaT, as it indicates a datetime column) among above ones
        #[4] Set [2] or [3] as what we need
        cols_obj = df.columns[df.dtypes.apply(lambda x: pd.api.types.is_object_dtype(x) or pd.api.types.is_string_dtype(x))]
        cols_numlike = df[cols_obj].map(testFloat).apply(pd.Series.any)
        cols_allnull = df[cols_obj].map(lambda x: pd.isnull(x) and (x is not pd.NaT)).apply(pd.Series.all)
        cols_totext = cols_obj[cols_numlike | cols_allnull]
        colnum_totext = pandasParseIndexer(df.columns, cols_totext, idxall = idxall, logname = 'txtCol')

        #500. Set the NumberFormat for each column identified above
        for i in colnum_totext:
            txt_rng = (
                slice(data_top, table_bottom + 1, None)
                ,slice(data_left + i, data_left + i + 1, None)
            )
            rsetattr(
                rng.__getitem__(txt_rng)
                ,attr = 'api.NumberFormat'
                ,val = '@'
            )

    #530. Within the index part
    if len(xlrng['index']) > 0:
        #100. Identify all index levels with numbers stored as [text]
        df_idx = df.index.to_frame()
        idxs_obj = df_idx.columns[df_idx.dtypes.apply(lambda x: pd.api.types.is_object_dtype(x) or pd.api.types.is_string_dtype(x))]
        idxs_numlike = df_idx[idxs_obj].map(testFloat).apply(pd.Series.any)
        idxs_allnull = df_idx[idxs_obj].map(lambda x: pd.isnull(x) and (x is not pd.NaT)).apply(pd.Series.all)
        idxs_totext = idxs_obj[idxs_numlike | idxs_allnull]
        idxnum_totext = pandasParseIndexer(df_idx.columns, idxs_totext, idxall = idxall, logname = 'txtIdx')

        #500. Set the NumberFormat for each index level identified above
        for i in idxnum_totext:
            txt_rng = (
                slice(data_top, table_bottom + 1, None)
                ,slice(table_left + i, table_left + i + 1, None)
            )
            rsetattr(
                rng.__getitem__(txt_rng)
                ,attr = 'api.NumberFormat'
                ,val = '@'
            )
    #600. Setup styles for the predefined ranges
    #610. Retrieve the theme as requested
    table_theme = theme_xwtable(theme)

    #620. Create the stripes
    if stripe:
        for r in xlstripe_idx + xlrng['data']:
            for debugname, attr in table_theme.get('stripe', {}).items():
                h_stripe(r, attr)

    #630. Reorder the ranges so that the styles for the latters overwrite those for the formers
    xlrng = OrderedDict({ k:xlrng.get(k) for k in seq_ranges if k in xlrng })

    #650. Set the styles in loop
    for k,v in xlrng.items():
        #100. Retrieve the styles for current item
        item_theme = table_theme.get(k, {})
        if not len(item_theme): continue

        #500. Differentiate the scenarios
        # print('<k>: ' + k)
        for r in v:
            # print('<r>: ' + rng.__getitem__(r).address)
            for debugname, attr in item_theme.items():
                #Quote: https://gaopinghuang0.github.io/2018/11/17/python-slicing
                # print('<debugname>: ' + debugname)
                rsetattr(rng.__getitem__(r), **attr)

    #700. Set the styles of the requested ranges
    #710. Specific rows of the [index] part
    for m in fmtIdx:
        #001. Skip if not applicable
        if (not index) | (len(df.index) == 0): break

        #005. Extract the members
        k,v,lvl = m.get('slicer'), m.get('attrs'), m.get('levels', None)

        #100. Translate the indexer
        idx_to_fmt = pandasParseIndexer(df.index, k, idxall = idxall, logname = 'fmtIdx')

        #300. Translate the indexer of levels if any
        if lvl is not None:
            lvl_to_fmt = pandasParseIndexer(pd.Index(df.index.names), lvl, idxall = idxall, logname = 'fmtIdx.levels')
            idx_to_fmt = list(itt.product(idx_to_fmt, lvl_to_fmt))

        #500. Set the styles row by row (since the slicer may not be continuous)
        for f_row in idx_to_fmt:
            #100. Identify the range
            if isinstance(f_row, tuple):
                idx_rng = (
                    slice(data_top + f_row[0], data_top + f_row[0] + 1, None)
                    ,slice(table_left + f_row[1], table_left + f_row[1] + 1, None)
                )
            else:
                idx_rng = (
                    slice(data_top + f_row, data_top + f_row + 1, None)
                    ,slice(table_left, box_right + 1, None)
                )

            #500. Set the styles
            for attr in v.values():
                rsetattr(rng.__getitem__(idx_rng), **attr)

    #730. Specific rows of the [data] part
    for m in fmtRow:
        #001. Skip if not applicable
        if f_empty: break

        #005. Extract the members
        k,v = m.get('slicer'), m.get('attrs')

        #100. Translate the indexer
        row_to_fmt = pandasParseIndexer(df.index, k, idxall = idxall, logname = 'fmtRow')

        #500. Set the styles row by row (since the slicer may not be continuous)
        for f_row in row_to_fmt:
            #100. Identify the range
            row_rng = (
                slice(data_top + f_row, data_top + f_row + 1, None)
                ,slice(data_left, table_right + 1, None)
            )

            #500. Set the styles
            for attr in v.values():
                rsetattr(rng.__getitem__(row_rng), **attr)

    #750. Specific columns of the [columns] part
    for m in fmtHdr:
        #001. Skip if not applicable
        if (not header) | (len(df.columns) == 0): break

        #005. Extract the members
        k,v,lvl = m.get('slicer'), m.get('attrs'), m.get('levels', None)

        #100. Translate the indexer
        hdr_to_fmt = pandasParseIndexer(df.columns, k, idxall = idxall, logname = 'fmtHdr')

        #300. Translate the indexer of levels if any
        if lvl is not None:
            lvl_to_fmt = pandasParseIndexer(pd.Index(df.columns.names), lvl, idxall = idxall, logname = 'fmtHdr.levels')
            hdr_to_fmt = list(itt.product(lvl_to_fmt, hdr_to_fmt))

        #500. Set the styles column by column (since the slicer may not be continuous)
        for f_col in hdr_to_fmt:
            #100. Identify the range
            if isinstance(f_col, tuple):
                hdr_rng = (
                    slice(table_top + f_col[0], table_top + f_col[0] + 1, None)
                    ,slice(data_left + f_col[1], data_left + f_col[1] + 1, None)
                )
            else:
                hdr_rng = (
                    slice(table_top, box_bottom + 1, None)
                    ,slice(data_left + f_col, data_left + f_col + 1, None)
                )

            #500. Set the styles
            for attr in v.values():
                rsetattr(rng.__getitem__(hdr_rng), **attr)

    #770. Specific columns of the [data] part
    for m in fmtCol:
        #001. Skip if not applicable
        if f_empty: break

        #005. Extract the members
        k,v = m.get('slicer'), m.get('attrs')

        #100. Translate the indexer
        col_to_fmt = pandasParseIndexer(df.columns, k, idxall = idxall, logname = 'fmtCol')

        #500. Set the styles column by column (since the slicer may not be continuous)
        for f_col in col_to_fmt:
            #100. Identify the range
            col_rng = (
                slice(data_top, table_bottom + 1, None)
                ,slice(data_left + f_col, data_left + f_col + 1, None)
            )

            #500. Set the styles
            for attr in v.values():
                rsetattr(rng.__getitem__(col_rng), **attr)

    #790. Specific cells of the [data] part
    for m in fmtCell:
        #001. Skip if not applicable
        if f_empty: break

        #005. Extract the members
        k,v = m.get('slicer'), m.get('attrs')

        #009. Raise error if the requested slicer is invalid
        if not isinstance(k, tuple):
            raise TypeError('[' + LfuncName + f'][fmtCell]:[{str(k)}] must be 2-tuple!')
        if len(k) != 2:
            raise TypeError('[' + LfuncName + f'][fmtCell]:[{str(k)}] must be 2-tuple!')

        #100. Translate the indexer
        cell_to_fmt = list(itt.product(
            pandasParseIndexer(df.index, k[0], idxall = idxall, logname = 'fmtCell.row')
            ,pandasParseIndexer(df.columns, k[-1], idxall = idxall, logname = 'fmtCell.col')
        ))

        #500. Set the styles row by row (since the slicer may not be continuous)
        for f_row, f_col in cell_to_fmt:
            #100. Identify the range
            cell_rng = (
                slice(data_top + f_row, data_top + f_row + 1, None)
                ,slice(data_left + f_col, data_left + f_col + 1, None)
            )

            #500. Set the styles
            for attr in v.values():
                rsetattr(rng.__getitem__(cell_rng), **attr)

    #800. Merge the ranges as requested
    for r in xlmerge_idx + xlmerge_hdr:
        rng.__getitem__(r).merge()

    #999. Export the data to the entire range
    if (not asformatter) and (not formatOnly):
        #100. Create a copy of the data frame to avoid modification on the original object
        df_copy = df.copy(deep = True)

        #300. Remove the names of [df.index] during the export
        if not (index & header & index_name):
            df_copy.index.names = [ None for i in range(len(df_copy.index.names)) ]

        #900. Write the data
        rng.value = df_copy
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
    #We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings <= 0.27.15] and [Python <= 3.8]
    #It is weird but works!
    #Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
    import pywintypes
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
    udf2 = udf.copy(deep=True).assign(**{ 'F' : lambda x: pd.Series(np.random.randn(len(x)), dtype = 'string') })
    testdf = pd.DataFrame({'aaa' : [1,3,5], 'bbb' : ['01','03','05']}, index = [2,4,7])
    emp_row = testdf.head(0)
    emp_col = testdf.loc[:, []]

    #200. Set the universal parameters
    args_xw = {
        'index' : True
        ,'header' : True
        ,'mergeIdx' : True
        ,'mergeHdr' : 'C'
        ,'stripe' : True
        ,'theme' : 'BlackGold'
        #Set font color as red for the first row of index
        ,'fmtIdx' : [
            {
                'slicer' : 0
                ,'attrs' : {
                    'Font.Color' : {
                        'attr' : 'api.Font.Color'
                        ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#FF0000'))
                    }
                }
                ,'levels' : 'B'
            }
        ]
        #Set bold font for the entire last row
        ,'fmtRow' : [
            {
                'slicer' : len(upvt) - 1
                ,'attrs' : {
                    'Font.Bold' : {
                        'attr' : 'api.Font.Bold'
                        ,'val' : True
                    }
                }
            }
        ]
        #Set font color as green for the list of column headers
        ,'fmtHdr' : [
            {
                'slicer' : slice(2,4,None)
                ,'attrs' : {
                    'Font.Color' : {
                        'attr' : 'api.Font.Color'
                        ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb('#00FF00'))
                    }
                }
                ,'levels' : -1
            }
        ]
        ,'fmtCol' : [
            #Set below columns as millions
            {
                'slicer' : [1,5]
                ,'attrs' : {
                    'NumberFormat' : {
                        'attr' : 'api.NumberFormat'
                        ,'val' : '_( * #,##0.00,,"M"_) ;_ (* #,##0.00,,"M")_ ;_( * "-"??_) ;_ @_ '
                    }
                }
            }
            #Set below column as percentage
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
        #Set font as italic for the list of cells
        #Quote: https://docs.xlwings.org/en/latest/api.html#font
        ,'fmtCell' : [
            {
                'slicer' : ([0,3], slice(2,5,None))
                ,'attrs' : {
                    'Font.Italic' : {
                        'attr' : 'font.italic'
                        ,'val' : True
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
        xlsh.cells.color = xw.utils.hex_to_rgb('#202122')
        xwDfToRange(
            xlrng
            ,upvt
            ,asformatter = False
            ,**args_xw
        )
        xlsh.autofit()

        #600. Export the data as the formatter
        #[ASSUMPTION]
        #[1] It is tested that the formatter has no effect where [xlwings <= 0.27.15]
        #[2] It is tested that the formatter works for [xlwings == 0.28.5] and maybe afterwards for good
        #[3] In order to validate [index] and [header] arguments when we set the function as [formatter],
        #     we have to place it in the same call of [options()] method, see below example
        #[4] Chains of [options()] only validate the last one [xlwings <= 0.28.5]
        #[5] Using [formatter=] option will cause the removal of leading zeros from cell values [xlwings <= 0.28.5]
        #     It is presumed that [xw.Range.value = val] will convert the numeric-like characters into numerics inadvertently
        xlrng2 = xlsh.range('B20').expand().options(pd.DataFrame, index = True, header = True, formatter = xwfmtter)
        xlrng2.value = upvt

        #700. Export the raw data with SAS theme
        xlsh2 = xlwb.sheets.add('RAW')
        xlrng2 = xlsh2.range('B2').expand().options(pd.DataFrame, index = True, header = True)
        xwDfToRange(
            xlrng2
            ,udf2
            ,theme = 'SAS'
            ,fmtCol = [
                #Set below columns as text
                {
                    'slicer' : 3
                    ,'attrs' : {
                        'NumberFormat' : {
                            'attr' : 'api.NumberFormat'
                            ,'val' : '@'
                        }
                    }
                }
            ]
        )
        xlsh2.autofit()

        #800. Export empty data frames
        xlsh3 = xlwb.sheets.add('EMPTY_ROW')
        xlsh3.cells.color = xw.utils.hex_to_rgb('#202122')
        xlrng3 = xlsh3.range('B2').expand().options(pd.DataFrame, index = True, header = True)
        xwDfToRange(
            xlrng3
            ,emp_row
        )
        xlsh3.autofit()

        xlsh4 = xlwb.sheets.add('EMPTY_COL')
        xlsh4.cells.color = xw.utils.hex_to_rgb('#202122')
        xlrng4 = xlsh4.range('B2').expand().options(pd.DataFrame, index = True, header = True)
        xwDfToRange(
            xlrng4
            ,emp_col
        )
        xlsh4.autofit()

        #999. Purge
        xlwb.save(xlfile)
        xlwb.close()
        xlapp.screen_updating = True

    if os.path.isfile(xlfile): os.remove(xlfile)
#-Notes- -End-
'''
