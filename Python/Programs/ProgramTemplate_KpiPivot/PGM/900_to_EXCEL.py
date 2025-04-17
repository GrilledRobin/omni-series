#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to Export the data to EXCEL, with or without template                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] There may be multiple tables exported to the same <RPT_FILE>; since it is the first parameter to the function call, we set it  #
#   |     as the top priority to split the process                                                                                      #
#   |[2] Given above condition, there may be sheets introduced from multiple <RPT_TPL> into the same <RPT_FILE>; we further split the   #
#   |     process by this one                                                                                                           #
#   |[3] Given above conditions, there may be multiple tables exported to the same <RPT_SHEET>; we further split the process            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250329        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250403        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now only export the tables in the Ranges of one Sheet in one workbook at one batch                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250417        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Since <xw.Book.fullname> follows the symbolic link of a file, we also expand the provided paths to their <realpath>     #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Export to EXCEL')
import os
import pandas as pd
import xlwings as xw
from typing import Optional
from xlwings.constants import LineStyle as xwLS
from xlwings.constants import BordersIndex as xwBI
from xlwings.constants import BorderWeight as xwBW
from omniPy.AdvOp import get_values, xwDfToRange, xwGroupForDf

#010. Local environment
L_srcflnm1 = os.path.join(dir_data_db, f'rpt_rst{L_curdate}.hdf')
L_stpflnm1 = os.path.join(dir_data_db, f'attrs_rpt{L_curdate}.hdf')
dataIO.add('HDFS')
color_theme = {
    'dark' : '#202122'
    ,'light' : '#FFE8CB'
    #Classic green of MS PowerBI default theme
    ,'highlight' : '#01B8AA'
}
fmt_num = {
    'INT' : '_( * #,##0_) ;_ (* #,##0)_ ;_( * "-"??_) ;_ @_ '
    ,'MIL' : '_( * #,##0.00,,"M"_) ;_ (* #,##0.00,,"M")_ ;_( * "-"??_) ;_ @_ '
    ,'DEC' : '_( * #,##0.00_) ;_ (* #,##0.00)_ ;_( * "-"??_) ;_ @_ '
    ,'PCT' : '_( * #,##0.00%_) ;_ (* #,##0.00%)_ ;_( * "-"??_) ;_ @_ '
}

#040. Load the data in current session
if not isinstance(get_values('args_pvt_df', inplace = False), pd.DataFrame):
    args_pvt_df = dataIO['HDFS'].pull(L_srcflnm1, 'args_pvt_df')
if not isinstance(get_values('rpt_rst', inplace = False), pd.DataFrame):
    rpt_rst = dataIO['HDFS'].pull(L_srcflnm1, 'rpt_rst')

args_pvt = { k:v for k,v in args_pvt_df[['key','value']].itertuples(index = False) }

print('100. Define attributes for exporting')
#[ASSUMPTION]
#[1] Store the process into data for later audit trail
attrs_rpt = (
    pd.DataFrame.from_records([
        {
            'RPT_DATA' : rpt_rst
            ,'RPT_TPL' : None
            ,'RPT_FILE' : os.path.join(dir_out, f'Report{L_curdate}.xlsx')
            ,'RPT_SHEET' : 'TEST'
            ,'RPT_ROW' : 2
            ,'RPT_COL' : 2
            ,'index' : True
            ,'header' : True
            ,'mergeIdx' : True
            ,'mergeHdr' : True
        }
    ])
    #[ASSUMPTION]
    #[1] We must set the empty <RPT_TPL> as an empty string, for <pandas> has inconsistent behaviors as below
    #    [1] When use <pd.Series.apply()>, the cell value of NULL is extracted as <None>
    #    [2] When use <pd.Series.eq(None)>, the result is False as tthe cell value of NULL is regarded as <NaN>
    #[2] <xw.Book.fullname> refers to the absolute path, esp. for path created by symbolic link, of the the workbook,
    #     so we have to resolve the <realpath> of any input to ensure the identical behaviors of all paths
    .fillna(value = {'RPT_TPL' : ''})
    .assign(**{
        'RPT_TPL' : lambda x: x['RPT_TPL'].apply(lambda row: '' if row == '' else os.path.realpath(row))
        ,'RPT_FILE' : lambda x: x['RPT_FILE'].apply(lambda row: '' if row == '' else os.path.realpath(row))
    })
)

print('200. Helper functions')
#210. Function to slice all columns to be displayed as integer
def h_getCol_int(df : pd.DataFrame) -> list[int]:
    return(
        df.columns
        .get_level_values(-1)
        .to_series()
        .reset_index(drop = True)
        .loc[lambda x: x.str.startswith('#')]
        .index
        .to_list()
    )

#250. Function to process one table for one EXCEL Range
#[ASSUMPTION]
#[1] The provided <book> may not be the same one as <sheet.book.fullname> during the process, hence we do not
#     risk ourselves by using a separate argument
#[2] Similar situations apply to other arguments
def h_range(
    row : pd.Series
    ,xlsh : xw.Sheet
) -> int:
    #200. Prepare the specific arguments for current table
    args_axis = {
        'index' : row['index']
        ,'header' : row['header']
    }
    args_merge = {
        'mergeIdx' : row['mergeIdx']
        ,'mergeHdr' : row['mergeHdr']
    }

    args_xw_slicer = {
        'fmtCol' : [
            {
                'slicer' : h_getCol_int(row['RPT_DATA'])
                ,'attrs' : {
                    'NumberFormat' : {
                        'attr' : 'api.NumberFormat'
                        ,'val' : fmt_num['INT']
                    }
                }
            }
        ]
    }

    #400. Define the range
    xlrng = (
        xlsh.range((row['RPT_ROW'], row['RPT_COL'])).expand()
        #[ASSUMPTION]
        #[1] It is tested that chains of [options()] only validate the last one [xlwings <= 0.28.5]
        .options(pd.DataFrame, **args_axis)
        # .options(formatter = fmt_bold)
    )

    #500. Export the data
    xwDfToRange(
        xlrng
        ,row['RPT_DATA']
        ,**args_xw_general
        ,**args_axis
        ,**args_merge
        ,**args_xw_slicer
    )

    #600. Add groups and outlines
    xwGroupForDf(
        xlrng
        ,row['RPT_DATA']
        ,formatOnly = True
        ,kw_pvtLike = args_pvt
        ,**args_axis
        ,**args_merge
    )

    return(0)

#260. Function to process multiple tables for one EXCEL Worksheet
def h_sheet(
    cfg : pd.DataFrame
    ,tpl : Optional[str]
    ,bookpath : str
    ,xlsh : xw.Sheet
) -> pd.DataFrame:
    #100. Identify the specific attributes for exporting data
    df_sheet = (
        cfg
        .loc[lambda x: x['RPT_TPL'].eq(tpl)]
        .loc[lambda x: x['RPT_FILE'].eq(bookpath)]
        .loc[lambda x: x['RPT_SHEET'].eq(xlsh.name)]
    )

    #300. Set general styles
    xlsh.cells.color = xw.utils.hex_to_rgb(color_theme['dark'])

    #700. Write the data
    #[ASSUMPTION]
    #[1] We need to convert the <Series> into <DataFrame> in order to prevent <pandas> from concatenating the
    #     returning Series of <Series> into a single <DataFrame> with multiple columns
    rc = df_sheet.apply(h_range, xlsh = xlsh, axis = 1).rename('rc').to_frame()

    #800. More settings
    xlsh.autofit()

    #999. Purge
    return(rc)

#270. Function to process multiple EXCEL Worksheets for one <RPT_TPL>
#[ASSUMPTION]
#[1] If <RPT_TPL> is not NULL, we copy the sheets to <xlwb_to>
#[2] If otherwise, we create a new book with these sheets, then copy them to <xlwb_to>
def h_tpl(
    tpl : Optional[str]
    ,cfg : pd.DataFrame
    ,xlwb_to : xw.Book
    ,single_tpl : bool
) -> pd.DataFrame:
    #100. Identify the specific attributes for exporting data
    has_tpl = tpl != ''
    df_tpl = (
        cfg
        .loc[lambda x: x['RPT_FILE'].eq(xlwb_to.fullname)]
        .loc[lambda x: x['RPT_TPL'].eq(tpl)]
        [['RPT_FILE','RPT_TPL','RPT_SHEET']]
        .drop_duplicates()
    )

    #200. Helper function to process one record at one batch
    def h_sheets(row : pd.Series, wb : xw.Book) -> pd.DataFrame:
        #100. Prepare the sheet
        if has_tpl:
            xlsh = wb.sheets[row['RPT_SHEET']]
        else:
            xlsh = wb.sheets.add(row['RPT_SHEET'])

        #500. Write the data to the sheet
        rc = h_sheet(cfg, row['RPT_TPL'], xlwb_to.fullname, xlsh)

        #700. Copy the sheet with data to the destination
        if not single_tpl:
            xlsh.copy(after = xlwb_to.sheets['..todel...'])

        return(rc)

    #200. Identify the template
    if single_tpl:
        xlwb = xlwb_to
    else:
        if has_tpl:
            xlwb = xlwb_to.app.books.open(tpl)
        else:
            xlwb = xlwb_to.app.books.add()
            xlsh_del = xlwb.sheets[0]
            #We set a relatively unique name
            xlsh_del.name = '..todel...'

    #500. Write the data into the sheets
    #[ASSUMPTION]
    #[1] Result from applying <h_sheets> is a DataFrame with only one column
    rc = pd.concat(
        df_tpl.apply(h_sheets, wb = xlwb, axis = 1).to_list()
        ,ignore_index = False
    )

    #999. Purge
    if not single_tpl:
        xlwb.close()

    return(rc)

#280. Function to process multiple EXCEL Worksheets for one <RPT_FILE>
def h_book(
    bookpath : str
    ,xlapp : xw.App
    ,cfg : pd.DataFrame
) -> pd.DataFrame:
    #100. Identify the specific attributes for exporting data
    df_book = (
        cfg
        .loc[lambda x: x['RPT_FILE'].eq(bookpath)]
        [['RPT_FILE','RPT_TPL']]
        .drop_duplicates()
        .reset_index(drop = True)
    )

    #200. Identify whether there is only one <RPT_TPL> for the <RPT_FILE>
    #[ASSUMPTION]
    #[1] In such case we directly save <RPT_TPL> as <RPT_FILE>, to retain all sheets and formulae if any
    #[2] If <RPT_TPL> refers to the same file path as <RPT_FILE>, we overwrite <RPT_TPL> silently
    #[3] If there are multiple <RPT_TPL> for the same <RPT_FILE>, there is no reason to keep all sheets
    #     from all templates as there may be conflicts. Therefore, any formulae that refer to cross-sheet
    #     cells would possibly fail
    f_single_tpl = (len(df_book) == 1) & (len(df_book.loc[lambda x: x['RPT_TPL'].ne('')]) == 1)

    #300. Create a new workbook and save it as the destination immediately
    #[ASSUMPTION]
    #[1] This step ensures that the <fullname> of the newly created book is the required one
    if f_single_tpl:
        if df_book['RPT_FILE'].str.strip().str.upper().ne(df_book['RPT_TPL'].str.strip().str.upper()).all():
            if os.path.isfile(bookpath): os.remove(bookpath)
        xlwb = xlapp.books.open(df_book.at[0,'RPT_TPL'])
        xlsh_del = xlwb.sheets.add('..todel...')
    else:
        if df_book['RPT_FILE'].str.strip().str.upper().eq(df_book['RPT_TPL'].str.strip().str.upper()).any():
            raise RuntimeError(
                'It is not accepted that multiple <RPT_TPL> (even when any of them is <None>) for the same <RPT_FILE>'
                + ' while one of them refers to the same path as <RPT_FILE>!'
            )
        if os.path.isfile(bookpath): os.remove(bookpath)
        xlwb = xlapp.books.add()
        xlsh_del = xlwb.sheets[0]
        xlsh_del.name = '..todel...'

    xlwb.save(bookpath)

    #500. Handle multiple templates for it
    rc = pd.concat(
        df_book['RPT_TPL'].apply(h_tpl, cfg = cfg, xlwb_to = xlwb, single_tpl = f_single_tpl).to_list()
        ,ignore_index = False
    )

    #700. Save and close the workbook
    xlsh_del.delete()
    xlwb.save()
    xlwb.close()

    #999. Purge
    return(rc)

print('300. Setup customization of styles')
#210. Set the [totals] part as bold font with a line on the top edge
xw_totals_row = {
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
        ,'val' : xw.utils.rgb_to_int(xw.utils.hex_to_rgb(color_theme['light']))
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

print('600. Set the arguments for exporting data to EXCEL')
args_xw_general = {
    'stripe' : True
    ,'theme' : 'BlackGold'
    ,'fmtIdx' : [
        #Set style for the last row of index
        {
            'slicer' : -1
            ,'attrs' : xw_totals_row
        }
    ]
    ,'fmtRow' : [
        #Set style for the last row of data part
        {
            'slicer' : -1
            ,'attrs' : xw_totals_row
        }
    ]
}

print('900. Export')
#910. Mark the <RPT_FILE> for which all the input data tables are empty
#[ASSUMPTION]
#[1] As a convention, we only skip the <RPT_FILE> when ALL of the tables to export inside it are empty
rc_empty = (
    attrs_rpt
    .assign(**{
        'rc' : lambda x: x['RPT_DATA'].apply(len).map({0 : -1})
    })
    .groupby('RPT_FILE')
    .agg(**{'rc' : pd.NamedAgg(column = 'rc', aggfunc = lambda x: x.eq(-1).all())})
    .loc[lambda x: x['rc'].eq(True)]
    .assign(**{
        'rc' : -1
    })
)
mask_empty = attrs_rpt['RPT_FILE'].isin(rc_empty.index)

#950. Pour the data into the files
with xw.App( visible = False, add_book = False ) as xlapp:
    #010. Set options
    xlapp.display_alerts = False
    xlapp.screen_updating = False

    #500. Execution
    rc_proc = pd.concat(
        (
            attrs_rpt
            .loc[lambda x: ~mask_empty]
            ['RPT_FILE']
            .drop_duplicates()
            .apply(h_book, xlapp = xlapp, cfg = attrs_rpt)
            .to_list()
        )
        ,ignore_index = False
    )

    #999. Purge
    xlapp.screen_updating = True

#970. Collect the returncode
attrs_rpt['rc_export'] = (
    rc_proc
    .reindex(attrs_rpt.index)
    .where(
        ~mask_empty
        ,rc_empty.reindex(attrs_rpt['RPT_FILE']).set_index(attrs_rpt.index)
    )
    ['rc']
)

print('999. Save the result to harddrive')
if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    {
        'attrs_rpt' : attrs_rpt.drop(columns = ['RPT_DATA'])
    }
    ,L_stpflnm1
)
