#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#[FEATURE]
#[1] Export dataframe to EXCEL
#[2] Set full borders to the EXCEL range
#[3] Set number format for the data range
logger.info('Export pandas.DataFrame to EXCEL')
import os
import pandas as pd
import xlwings as xw
from xlwings.constants import BordersIndex as bds

L_stpflnm = os.path.join(dir_out, 'xlOps.xlsx')
xlsh_name = 'test'

testdf = pd.DataFrame({'a':[1,3,5], 'b':[2,4,6]})

if os.path.isfile(L_stpflnm): os.remove(L_stpflnm)

#[ASSUMPTION]
#[1] Use [with] statement to allow exporting more than one sheet to the same EXCEL file
with pd.ExcelWriter(L_stpflnm, mode = 'w') as writer:
    testdf.to_excel(writer, sheet_name = xlsh_name)

#Quote: 设置表格边框
#Quote: https://www.csdn.net/tags/Ntzacg3sMTI4MTEtYmxvZwO0O0OO0O0O.html
#[ASSUMPTION]
#[1] The method [bds.__getattribute__()] must have been modified by the author so that it cannot return the expected result
#[2] We thus use the primative Python function [getattr] to obtain the values of the dedicated attributes
bordersIdx = [
    getattr(bds, m)
    for m in dir(bds)
    if m[0:2] == 'xl' and m not in ['xlDiagonalDown','xlDiagonalUp']
]

#[ASSUMPTION]
#[1] EXCEL will not actually [quit()] when executing [xlapp.quite()], which is absolutely weird
#[2] We thus use [with] statement instead, to ensure the [xlapp] is decommissioned
with xw.App( visible = False, add_book = False ) as xlapp:
    #010. Set options
    xlapp.display_alerts = False
    xlapp.screen_updating = False

    #100. Open the EXCEL workbook
    xlwb = xlapp.books.open(L_stpflnm)

    #300. Format the sheet
    xlsh = xlwb.sheets[xlsh_name]
    xlrng_used = xlsh.used_range

    #310. Borders
    #Quote: Set border using python xlwings
    #Quote: https://stackoverflow.com/questions/37866812
    for border_id in bordersIdx:
        xlrng_used.api.Borders(border_id).LineStyle = 1
        #It is tested [Weight = 1] leads to dotted line
        xlrng_used.api.Borders(border_id).Weight = 2

    #330. Number format
    xlrng_val = xlsh.range('B2', (xlrng_used.last_cell.row, xlrng_used.last_cell.column))
    #Quote: python xlwings API接口之NumberFormat用法
    #Quote: https://www.cnblogs.com/aziji/p/13916129.html
    xlrng_val.api.NumberFormat = '#,##0_ '

    #399. Autofit the width
    xlsh.autofit()

    #999. Purge
    xlwb.save()
    xlwb.close()
    xlapp.screen_updating = True
