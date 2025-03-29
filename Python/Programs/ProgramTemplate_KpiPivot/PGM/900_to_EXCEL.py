#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to Export the data to EXCEL, with or without template                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250329        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Export to EXCEL')
import os
import pandas as pd
import xlwings as xw
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
attrs_rpt = pd.DataFrame.from_records([
    {
        'RPT_DATA' : rpt_rst
        ,'SKIP_EMPTY' : True
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
#910. Helper function to export one table at a time
def h_expExcel(row : pd.Series):
    if row['SKIP_EMPTY']:
        if len(row['RPT_DATA']) == 0:
            return(-1)

    if os.path.isfile(row['RPT_FILE']): os.remove(row['RPT_FILE'])
    has_tpl = pd.notnull(row['RPT_TPL'])
    with xw.App( visible = False, add_book = (not has_tpl) ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Identify the EXCEL workbook and worksheet
        if has_tpl:
            xlwb = xlapp.books.open(row['RPT_TPL'])
            xlsh = xlwb.sheets[row['RPT_SHEET']]
        else:
            xlwb = xlapp.books[0]
            xlsh = xlwb.sheets[0]
            xlsh.name = row['RPT_SHEET']

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

        #300. Set general styles
        xlsh.cells.color = xw.utils.hex_to_rgb(color_theme['dark'])

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

        #800. More settings
        xlsh.autofit()

        #999. Purge
        xlwb.save(row['RPT_FILE'])
        xlwb.close()
        xlapp.screen_updating = True

    return(0)

#950. Conduct the process
attrs_rpt['rc_export'] = attrs_rpt.apply(h_expExcel, axis = 1)

print('999. Save the result to harddrive')
if os.path.isfile(L_stpflnm1): os.remove(L_stpflnm1)
rc = dataIO['HDFS'].push(
    {
        'attrs_rpt' : attrs_rpt.drop(columns = ['RPT_DATA'])
    }
    ,L_stpflnm1
)
