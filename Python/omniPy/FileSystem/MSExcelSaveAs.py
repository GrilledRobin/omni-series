# -*- coding: utf-8 -*-
#!/usr/bin/env python3

import sys
#We have to import [pywintypes] to activate the DLL required by [win32api]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
from win32com.client import Dispatch

def MSExcelSaveAs(
    infile
    ,outfile
    ,inSheet = 1
    ,outtype = 51
) -> 'Use Windows Dispatch to save MS EXCEL files as other file types':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to use Windows Dispatch to save MS EXCEL files as other file types                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |infile         :   Full path of the input MX EXCEL file                                                                            #
#   |outfile        :   Full path of the converted file                                                                                 #
#   |                   [None      ]<default> Throw error if not provided                                                               #
#   |inSheet        :   Which sheet to convert if [outfile] is a plain text file or only contains one [sheet]                           #
#   |                   [1         ]<default> Convert the first sheet in the input file for certain [outtype]                           #
#   |                   [<name>    ]          Provide the sheet id or name to convert for certain [outtype]                             #
#   |outtype        :   Type of the output file as integer during [saveas], see the [Full Test Program] section for full list of types  #
#   |                   [51        ]<default> Save the file as the default EXCEL file                                                   #
#   |                   [<int>     ]          Other types to save the input file as                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[chr. string ] :   Full path of the converted file if process is completed                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210207        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |100.   Dependent packages                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, win32com                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012.   Handle the parameter buffer.
    if outfile is None:
        raise ValueError( '[' + LfuncName + '][outfile] must be provided!' )
    if inSheet is None: inSheet = 1
    if outtype is None: outtype = 51

    #100. Connect to MS EXCEL Application
    #It seems to inherit the same syntax as VBScript
    #For MS Word, you can set as below:
    #WordApp = Dispatch('Word.Application')
    XLApp = Dispatch('Excel.Application')
    XLApp.Visible = 0
    XLApp.DisplayAlerts = 0

    #200. Open the input file with EXCEL Application
    #For MS Word, you can set as below:
    #WordDoc = WordApp.Documents.Open(infile)
    XLBook = XLApp.Workbooks.Open(infile)

    #500. Activate the specific sheet for certain output file types
    if inSheet: XLBook.Sheets(inSheet).Activate()

    #For MS Word, we should wait for long enough before saving the file, otherwise there is an error issued as: -2147352567
    #time.sleep(3)

    #700. Save the input file as another one as per request
    #For MS Word, please check the official documents for arguments of [SaveAs]
    XLBook.SaveAs( outfile, FileFormat = outtype )

    #800. Close the input file [testing purpose, may delete it; hence please pay attention]
    # XLBook.Close()

    #900. Quit the EXCEL Application
    XLApp.Quit()

    #999. Return the full path of the output file when completed
    return( outfile )
#End userBasedCF

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import time
    import os
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.FileSystem import MSExcelSaveAs
    print(MSExcelSaveAs.__doc__)

    #100. Convert XLSX to XLS
    in_XLSX = dir_omniPy + r'omniPy\FileSystem\MSExcelSaveAs_In.xlsx'.strip()
    out_XLS = dir_omniPy + r'omniPy\FileSystem\MSExcelSaveAs_Out.xls'.strip()
    testpath = MSExcelSaveAs( in_XLSX, out_XLS, outtype = 56 )

    #200. Convert XLS to XLSX
    in_XLS = dir_omniPy + r'omniPy\FileSystem\MSExcelSaveAs_In.xls'.strip()
    out_XLSX = dir_omniPy + r'omniPy\FileSystem\MSExcelSaveAs_Out.xlsx'.strip()
    testpath = MSExcelSaveAs( in_XLS, out_XLSX )

    #300. Convert XLSX to CSV
    out_CSV = dir_omniPy + r'omniPy\FileSystem\MSExcelSaveAs_Out.csv'.strip()
    testpath = MSExcelSaveAs( in_XLSX, out_CSV, inSheet = 'Sheet2', outtype = 6 )
    #Same action as above
    # testpath = MSExcelSaveAs( in_XLSX, out_CSV, inSheet = 2, outtype = 6 )

    #[Quote: https://docs.microsoft.com/en-us/office/vba/api/excel.xlfileformat ]
    """
    [Name in EXCEL]               [VBS/VBA ID] [File Type]
    xlAddIn                                 18 Microsoft Office Excel 加载项
    xlAddIn8                                18 Excel 2007 加载项
    xlCSV                                    6 CSV
    xlCSVMac                                22 Macintosh CSV
    xlCSVMSDOS                              24 MSDOS CSV
    xlCSVWindows                            23 Windows CSV
    xlCurrentPlatformText                -4158 当前平台文本
    xlDBF2                                   7 DBF2
    xlDBF3                                   8 DBF3
    xlDBF4                                  11 DBF4
    xlDIF                                    9 DIF
    xlExcel12                               50 Excel 12
    xlExcel2                                16 Excel 2
    xlExcel2FarEast                         27 Excel2 FarEast
    xlExcel3                                29 Excel3
    xlExcel4                                33 Excel4
    xlExcel4Workbook                        35 Excel4 工作簿
    xlExcel5                                39 Excel5
    xlExcel7                                39 Excel7
    xlExcel8                                56 Excel8
    xlExcel9795                             43 Excel9795
    xlHtml                                  44 HTML 格式
    xlIntlAddIn                             26 国际加载项
    xlIntlMacro                             25 国际宏
    xlOpenXMLAddIn                          55 打开 XML 加载项
    xlOpenXMLTemplate                       54 打开 XML 模板
    xlOpenXMLTemplateMacroEnabled           53 打开启用的 XML 模板宏
    xlOpenXMLWorkbook                       51 打开 XML 工作簿
    xlOpenXMLWorkbookMacroEnabled           52 打开启用的 XML 工作簿宏
    xlSYLK                                   2 SYLK
    xlTemplate                              17 模板
    xlTemplate8                             17 模板 8
    xlTextMac                               19 Macintosh 文本
    xlTextMSDOS                             21 MSDOS 文本
    xlTextPrinter                           36 打印机文本
    xlTextWindows                           20 Windows 文本
    xlUnicodeText                           42 Unicode 文本
    xlWebArchive                            45 Web 档案
    xlWJ2WD1                                14 WJ2WD1
    xlWJ3                                   40 WJ3
    xlWJ3FJ3                                41 WJ3FJ3
    xlWK1                                    5 WK1
    xlWK1ALL                                31 WK1ALL
    xlWK1FMT                                30 WK1FMT
    xlWK3                                   15 WK3
    xlWK3FM3                                32 WK3FM3
    xlWK4                                   38 WK4
    xlWKS                                    4 工作表
    xlWorkbookDefault                       51 默认工作簿
    xlWorkbookNormal                     -4143 常规工作簿
    xlWorks2FarEast                         28 Works2 FarEast
    xlWQ1                                   34 WQ1
    xlXMLSpreadsheet                        46 XML 电子表格
    """
#-Notes- -End-
'''
