#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re, os, csv
import pandas as pd
import datetime as dt
import subprocess as sp
from typing import Optional
from packaging import version
from warnings import warn
from functools import partial
from omniPy.AdvDB import inferContents
from omniPy.AdvOp import apply_MapVal
from omniPy.FileSystem import winReg_getInfByStrPattern

def writeSASdat(
    inDat : pd.DataFrame
    ,outFile : str | os.PathLike
    ,metaVar : Optional[pd.DataFrame] = None
    ,dt_map : dict = {
        #[LHS] The original format in SAS loaded from [pyreadstat.read_sas7bdat] and stored in meta.original_variable_types
        #[RHS] The [function] to translate the corresponding values in the format of [LHS]
        #[IMPORTANT] The mapping is conducted by the sequence as provided below, check document for [apply_MapVal]
        #See official document of [SAS Date, Time, and Datetime Values]
        r'(datetime|dateampm)+' : 'dt'
        ,r'(hhmm|mmss)+' : 't'
        ,r'(time|tod|hour)+' : 't'
        ,r'(ampm)+' : 't'
        ,r'(yy|mmdd|ddmm)+' : 'd'
        ,r'(dat|day|mon|qtr|year)+' : 'd'
        ,r'(jul)+' : 'd'
    }
    ,nlsMap : dict = {
        'GB2312' : 'zh'
        ,'GB18030' : 'zh'
        ,'UTF-8' : 'u8'
        ,'...' : '1d'
    }
    ,encoding : str = 'GB2312'
    ,sasReg : str = r'HKEY_LOCAL_MACHINE\SOFTWARE\SAS Institute Inc.\The SAS System'
    ,sasOpt : list = ['-MEMSIZE', '0', '-NOLOGO', '-NOLOG', '-ICON']
    ,wd : str = os.getcwd()
) -> int:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to write SAS dataset by executing SAS program to load CSV exported from the provided data frame          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDat      :   Data frame to be exported, within which the date/time like columns will be converted by certain arguments           #
#   |               [IMPORTANT] Only these dtypes can be recognized by SAS: <str>, <int>, <float>                                       #
#   |outFile    :   PathLike object indicating the full path of the output file, including file extension <sas7bdat>, although it is    #
#   |                not verified but removed imperatively, since SAS creates its extension by all means                                #
#   |metaVar    :   Data frame that defines the meta information for SAS to import CSV datafile, see the example of the requirement     #
#   |               [None        ] <Default> Function infers the meta config                                                            #
#   |               If a data frame is provided, it should contain below columns                                                        #
#   |               [NAME        ] <str    > Column name in SAS syntax                                                                  #
#   |               [LABEL       ] <str    > [Optional] Column label in SAS syntax                                                      #
#   |               [TYPE        ] <int    > Variable type, 1 for numeric, 2 for character                                              #
#   |               [VARNUM      ] <int    > Position of variables in the SAS dataset, as well as in the interim CSV file               #
#   |               [LENGTH      ] <int    > Variable length of the actual storage in SAS dataset                                       #
#   |               [FORMAT      ] <str    > Format name in SAS syntax                                                                  #
#   |               [FORMATL     ] <int    > Format length in SAS syntax, i.e. <w> in the definition <FORMATw.d>                        #
#   |               [FORMATD     ] <int    > Format decimal in SAS syntax, i.e. <d> in the definition <FORMATw.d>                       #
#   |               [INFORMAT    ] <str    > [Omitted] Informat name in SAS syntax                                                      #
#   |               [INFORML     ] <int    > [Omitted] Informat length in SAS syntax, i.e. <w> in the definition <INFORMATw.d>          #
#   |               [INFORMD     ] <int    > [Omitted] Informat decimal in SAS syntax, i.e. <d> in the definition <INFORMATw.d>         #
#   |dt_map     :   Mapping table to convert the SAS datetime values into [datetime]                                                    #
#   |               [ <see def.> ] <Default> See definition of the function                                                             #
#   |nlsMap     :   Mapping table to call SAS in native environment, see the directory <sasHome\nls>                                    #
#   |               [ <see def.> ] <Default> See definition of the function                                                             #
#   |encoding   :   Encoding of these items: SAS NLS configuration, output SAS dataset, SAS script, log message from command console    #
#   |               [ <see def.> ] <Default> See definition of the function                                                             #
#   |sasReg     :   Path of the SAS installation in Windows Registry (to search for SAS executable)                                     #
#   |               [ <see def.> ] <Default> See definition of the function                                                             #
#   |sasOpt     :   Additional options during the call to SAS executable                                                                #
#   |               [ <see def.> ] <Default> See definition of the function                                                             #
#   |wd         :   Directory of the temporary files to reside                                                                          #
#   |               [ <see def.> ] <Default> See definition of the function                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>      :   Integer return code from the communication with Windows Command Console during SAS programm execution               #
#   |               [0           ] Execution successful                                                                                 #
#   |               [non-0 int   ] Failure                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20231230        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, re, os, csv, pandas, datetime, subprocess, packaging, warnings, functools                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvDB                                                                                                                   #
#   |   |   |inferContents                                                                                                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.FileSystem                                                                                                              #
#   |   |   |winReg_getInfByStrPattern                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.
    #from imp import find_module

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if metaVar is None:
        metaVar = inferContents(inDat)
    encoding = encoding.upper()
    trnsType = ['dt','t','d']
    err_funcs = [ v for v in set(dt_map.values()) if v not in trnsType ]
    if err_funcs:
        raise ValueError(
            f'[{LfuncName}]Values of [dt_map] should be among {str(trnsType)}! These are not allowed: {str(err_funcs)}'
        )

    #013. Define the local environment.
    outDir = os.path.dirname(outFile)
    outDat = os.path.splitext(os.path.basename(outFile))[0]
    cfg_nls = apply_MapVal(
        encoding
        ,dict_map = nlsMap
        , preserve = False
        , full_match = True
        , ignore_case = True
        , PRX = False
    )
    #[ASSUMPTION]
    #[1] There is no need to use <\r\n> or <chr(13)+chr(10)> to split lines, we only need <\n> as below
    crlf = chr(10)
    strtab = chr(9)

    #050. Locate SAS installation
    #The names of the direct sub-keys are the version numbers of all installed [SAS] software
    sasVers = winReg_getInfByStrPattern(sasReg, inRegExp = r'^\d+(\.\d+)+$', chkType = 2)
    if len(sasVers) == 0:
        raise RuntimeError(
            f'[{LfuncName}]SAS software is not properly installed! Check Windows Registry: <{sasReg}> for installation status.'
        )

    sasVers_comp = [ version.parse(v.get('name', None)) for v in sasVers ]
    sasVer = sasVers[sasVers_comp.index(max(sasVers_comp))].get('name', None)
    sasHome = winReg_getInfByStrPattern(os.path.join(sasReg, sasVer), 'DefaultRoot')[0]['value']
    sasExe = os.path.join(sasHome, 'sas.exe')
    sasNls = os.path.join(sasHome, 'nls', cfg_nls, 'sasv9.cfg')
    sasInit = sasOpt + ['-CONFIG', sasNls]

    #100. Define converters
    #110. Helper functions
    def h_convDT(vec):
        if pd.isnull(vec):
            return('')
        else:
            return(vec.strftime('%Y-%m-%d %H:%M:%S.') + str(vec.microsecond).zfill(6))
    def h_convD(vec):
        if pd.isnull(vec):
            return('')
        else:
            return(vec.strftime('%Y%m%d'))
    def h_convT(vec):
        if pd.isnull(vec):
            return('')
        else:
            return(
                str(vec.hour).zfill(2)
                + ':' + str(vec.minute).zfill(2)
                + ':' + str(vec.second).zfill(2)
                + '.' + str(vec.microsecond).zfill(6)
            )
    def h_convOth(vec):
        return(vec)

    #130. Map the conversion
    dt_conv = {
        'dt' : {
            'strfmt' : h_convDT
            ,'INFORMAT' : 'YMDDTTM'
            ,'INFORML' : 26
            ,'INFORMD' : 6
        }
        ,'t' : {
            'strfmt' : h_convT
            ,'INFORMAT' : 'TIME'
            ,'INFORML' : 15
            ,'INFORMD' : 6
        }
        ,'d' : {
            'strfmt' : h_convD
            ,'INFORMAT' : 'YYMMDD'
            ,'INFORML' : 10
            ,'INFORMD' : 0
        }
        ,'$' : {
            'strfmt' : h_convOth
            ,'INFORMAT' : '$'
            ,'INFORML' : 0
            ,'INFORMD' : 0
        }
        ,'Oth' : {
            'strfmt' : h_convOth
            ,'INFORMAT' : 'BEST'
            ,'INFORML' : 32
            ,'INFORMD' : 0
        }
    }

    #300. Mutate the meta config table to adapt to SAS syntax
    #310. Helper function to locate the special fields
    def h_getInType(row):
        if row['TYPE'] == 2:
            return('$')
        else:
            rst = apply_MapVal(
                row['FORMAT']
                ,dt_map
                ,preserve = False
                ,full_match = False
                ,ignore_case = True
                ,PRX = True
            )
            return(rst or 'Oth')

    #320. Helper function to avoid closure
    def h_assignVal(df : pd.DataFrame, fld : str):
        mapper = {
            tp : trns.get(fld)
            for tp, trns in dt_conv.items()
        }
        return(df['_trns_type_'].map(mapper))

    #380. Translation
    calcVar = ['INFORMAT','INFORML','INFORMD']
    metaConv = (
        metaVar
        .loc[:, lambda x: ~x.columns.isin(calcVar)]
        .copy(deep = True)
        .sort_values('VARNUM')
        .assign(**{
            '_trns_type_' : lambda x: x.apply(h_getInType, axis = 1)
        })
        .assign(**{
            fld : partial(h_assignVal, fld = fld)
            for tp, trns in dt_conv.items()
            for fld, val in trns.items()
            if fld in calcVar
        })
        #Patch length of character fields
        .assign(**{
            'FORMAT' : lambda x: x['FORMAT'].fillna('')
            ,'INFORML' : lambda x: x['INFORML'].where(x['_trns_type_'].ne('$'), x['LENGTH'])
            ,'INFORMD' : lambda x: x['INFORMD'].where(x['_trns_type_'].ne('$'), 0)
        })
    )
    if 'LABEL' in metaConv.columns:
        metaConv.loc[:, 'LABEL'] = metaConv.loc[:, 'LABEL'].fillna('').str.strip()

    #500. Mutate the provided data for export
    #510. Helper function to avoid closure
    def h_applyByRow(df : pd.DataFrame, fld : str, func : callable):
        return(df[fld].apply(func))

    #530. Force type conversion of all character columns
    col_chr = metaConv.loc[lambda x: x['_trns_type_'].eq('$'), 'NAME']

    #550. Conversion
    convVar = metaConv.loc[lambda x: x['_trns_type_'].isin(trnsType), ['NAME','_trns_type_']]
    rstOut = (
        inDat
        .copy(deep = True)
        .rename(columns = { v : v + '__old' for v in convVar['NAME'] })
        .assign(**{
            fld : partial(h_applyByRow, fld = fld + '__old', func = dt_conv.get(tp).get('strfmt'))
            for fld, tp in dict(convVar.values).items()
        })
        .loc[:, metaConv['NAME'].to_list()]
    )
    rstOut.loc[:, col_chr] = rstOut.loc[:, col_chr].astype(str).where(rstOut.loc[:,col_chr].notnull(), '')

    #700. Prepare SAS script to load CSV file
    #710. Informat
    scr_infmt = crlf.join(
        metaConv['NAME'].str.strip()
        .add(strtab)
        .add(metaConv['INFORMAT'].str.strip())
        .add(metaConv['INFORML'].astype(int).astype(str).str.strip())
        .add('.').add(metaConv['INFORMD'].astype(int).astype(str).str.strip())
        .radd(strtab * 2)
        .to_list()
    )

    #720. Format
    #[ASSUMPTION]
    #[1] SAS variables could have null formats
    #[2] In such case, we have to skip the statement for it
    metaSub_fmt = metaConv.loc[lambda x: x['FORMAT'].ne('')]
    scr_fmt = crlf.join(
        metaSub_fmt['NAME'].str.strip()
        .add(strtab)
        .add(metaSub_fmt['FORMAT'].str.strip())
        .add(metaSub_fmt['FORMATL'].astype(int).astype(str).str.strip())
        .add('.').add(metaSub_fmt['FORMATD'].astype(int).astype(str).str.strip()).add(';')
        .radd(strtab)
        .radd('FORMAT')
        .radd(strtab)
        .to_list()
    )

    #730. Input statement
    scr_input = crlf.join(
        metaConv['NAME'].str.strip()
        .add(strtab)
        .add(metaConv['_trns_type_'].where(metaConv['_trns_type_'].eq('$'), ''))
        .radd(strtab * 2)
        .to_list()
    )

    #740. Length
    scr_length = crlf.join(
        metaConv['NAME'].str.strip()
        .add(strtab)
        .add(metaConv['_trns_type_'].where(metaConv['_trns_type_'].eq('$'), ''))
        .add(metaConv['LENGTH'].astype(int).astype(str).str.strip())
        .radd(strtab * 2)
        .to_list()
    )

    #750. Labels
    #[ASSUMPTION]
    #[1] SAS variables could have null labels
    #[2] In such case, we have to skip the statement for it
    if 'LABEL' in metaConv.columns:
        metaSub_lbl = metaConv.loc[lambda x: x['LABEL'].ne('')]
        scr_label = crlf.join(
            metaSub_lbl
            ['NAME'].str.strip()
            .add(strtab + '=' + strtab)
            .add('%sysfunc(quote(%nrstr(').add(metaSub_lbl['LABEL'].str.strip()).add('), %nrstr(%\')));')
            .radd(strtab)
            .radd('LABEL')
            .radd(strtab)
            .to_list()
        )
    else:
        scr_label = ''

    #760. Determine whether to compress the data
    #[ASSUMPTION]
    #[1] SAS compression will consume more disk space if the original size of dataset is less than 128KB
    cmp = 'yes' if sys.getsizeof(rstOut) > (128 * 1024) else 'no'

    #770. Input options
    time_file = re.sub(r'\W', '', h_convDT(dt.datetime.now()))
    int_csv = os.path.join(wd, f'forsas{time_file}.csv')
    scr_infile = (crlf + strtab * 2).join([
        f'%sysfunc(quote(%nrstr({int_csv}),%nrstr(%\')))'
        ,'firstobs = 1'
        ,'dsd'
        ,'missover'
        ,'lrecl = 32767'
        ,'dlm = "|"'
        ,'encoding = "UTF-8"'
    ])

    #780. Full statements
    scr_final = crlf.join([
        f'libname rst %sysfunc(quote(%nrstr({outDir}), %nrstr(%\')));'
        ,f'data rst.{outDat}(compress = {cmp} encoding = "{encoding}");'
        ,strtab + 'length'
        ,scr_length
        ,strtab + ';'
        ,strtab + 'informat'
        ,scr_infmt
        ,strtab + ';'
        ,scr_fmt
        ,scr_label
        ,strtab + 'infile'
        ,strtab * 2 + scr_infile
        ,strtab + ';'
        ,strtab + 'input'
        ,scr_input
        ,strtab + ';'
        ,'run;'
        ,''
    ])

    #790. Write the script to harddisk for later call
    sasScr = os.path.join(wd, f'forsas{time_file}.sas')
    with open(sasScr, 'w', encoding = encoding) as f:
        f.write(scr_final)

    #800. Write SAS dataset
    #810. Export the data to harddisk
    if os.path.isfile(int_csv): os.remove(int_csv)
    rstOut.to_csv(
        int_csv
        ,sep = '|'
        ,header = False
        ,index = False
        ,encoding = 'UTF-8'
        ,quoting = csv.QUOTE_NONNUMERIC
    )

    #850. Call SAS to load the data
    #851. Open PIPE
    pipeSas = sp.Popen(
        [sasExe, sasScr] + sasInit
        #[shell=True] is often used when the command is comprised of executable, arguments and switches, instead of a list
        #It is always recommended NOT to set [shell] argument for [sp.Popen] to save system parsing resources
        #Quote: https://stackoverflow.com/questions/20451133/
        #Quote: https://stackoverflow.com/questions/69544990/
        ,shell = False
        ,stdout = sp.PIPE
        ,stderr = sp.PIPE
    )

    #855. Communicate with the pipe, i.e. submit the commands in the console
    #[ASSUMPTION]
    #[1] This operation cause Python to wait for the completion of the commands
    #[2] This operation enables a [returncode] after the completion of the commands
    sas_msg, sas_errs = pipeSas.communicate()
    rstRC = pipeSas.returncode

    #858. Collect the execution result
    if rstRC:
        warn(f'[{LfuncName}]<Failure Message Begin>')
        warn(re.sub(r'^.*?(traceback.+)$', r'\1', sas_msg.decode(encoding), flags = re.I | re.M | re.S | re.X))
        warn(f'[{LfuncName}]<Failure Message End>')
        warn(f'[{LfuncName}]<Failure Error Begin>')
        warn(sas_errs.decode(encoding))
        warn(f'[{LfuncName}]<Failure Error End>')

    #859. Close the communication
    pipeSas.terminate()

    #900. Purge
    #910. Remove all temporary files
    if os.path.isfile(sasScr): os.remove(sasScr)
    if os.path.isfile(int_csv): os.remove(int_csv)

    #999. Return the RC from SAS console
    return(rstRC)
#End writeSASdat

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    import os
    import pandas as pd
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import writeSASdat
    from omniPy.AdvDB import loadSASdat, inferContents
    from omniPy.Dates import asDates, asDatetimes, asTimes

    #100. Load the meta config table for data conversion
    conv_meta = pd.read_excel(os.path.join(dir_omniPy, 'omniPy', 'AdvDB', 'meta_writeSASdat.xlsx'))

    #200. Create data frame in terms of the indication in above meta config table
    aaa = (
        pd.DataFrame(
            {
                'var_str' : 'abcde'
                ,'var_int' : 5
                ,'var_float' : 14.678
                ,'var_date' : '2023-12-25'
                ,'var_dt' : '2023-12-25 12:34:56.789012'
                ,'var_time' : '12:34:56.789012'
                ,'var_ts' : asDatetimes('2023-12-25 12:34:56.789012', fmt = '%Y-%m-%d %H:%M:%S.%f')
            }
            ,index = [0]
        )
        #Prevent pandas from inferring dtypes of these fields
        .assign(**{
            'var_date' : lambda x: asDates(x['var_date'])
            #<%f> is only valid at input (strptime) rather than output (strftime)
            ,'var_dt' : lambda x: asDatetimes(x['var_dt'], fmt = '%Y-%m-%d %H:%M:%S.%f')
            ,'var_time' : lambda x: asTimes(x['var_time'], fmt = '%H:%M:%S.%f')
        })
    )

    #300. Convert the data to SAS dataset
    outf = os.path.join(os.getcwd(), 'vfysas.sas7bdat')
    rc = writeSASdat(
        aaa
        ,outf
        ,metaVar = conv_meta
    )
    if os.path.isfile(outf): os.remove(outf)

    #500. Convert the data to SAS dataset without meta config table
    #[ASSUMPTION]
    #[1] Dtypes that are not involved below CANNOT be exported, and will lead to exceptions
    testdf = (
        pd.DataFrame(
            {
                'var_str' : ['abcde',None]
                ,'var_pyarrow' : [np.nan,'k9omd']
                ,'var_int' : [5,7]
                ,'var_float' : [14.678,83.32]
                ,'var_date' : ['2023-12-25','2023-12-32']
                ,'var_dt' : ['2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812']
                ,'var_time' : ['12:34:56.789012','789']
                ,'var_ts' : asDatetimes(['2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812'], fmt = '%Y-%m-%d %H:%M:%S.%f')
                ,'var_bool' : [True,False]
                ,'var_cat' : ['abc','def']
                ,'var_complex' : [1 + 3j, 12.4 + 4.6j]
            }
            ,index = [0,1]
        )
        #Prevent pandas from inferring dtypes of these fields
        .assign(**{
            'var_pyarrow' : lambda x: x['var_pyarrow'].astype(pd.StringDtype('pyarrow'))
            ,'var_cat' : lambda x: x['var_cat'].astype('category')
            ,'var_date' : lambda x: asDates(x['var_date'])
            #<%f> is only valid at input (strptime) rather than output (strftime)
            ,'var_dt' : lambda x: asDatetimes(x['var_dt'], fmt = '%Y-%m-%d %H:%M:%S.%f')
            ,'var_time' : lambda x: asTimes(x['var_time'], fmt = '%H:%M:%S.%f')
        })
    )

    outf2 = os.path.join(os.getcwd(), 'vfysas2.sas7bdat')
    rc = writeSASdat(
        testdf
        ,outf2
    )
    if os.path.isfile(outf2): os.remove(outf2)

    #700. Read SAS dataset and export it to SAS again
    loadsas, meta = loadSASdat( dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat' , encoding = 'GB2312' )
    outf3 = os.path.join(os.getcwd(), 'vfysas3.sas7bdat')
    rc = writeSASdat(loadsas, outf3, encoding = 'GB2312')
    if os.path.isfile(outf3): os.remove(outf3)

    #750. Adjust the meta config before conversion
    meta_loadsas = inferContents(loadsas)
    meta_loadsas.loc[:, 'LENGTH'] = (
        pd.Series(
            meta.variable_storage_width.values()
            ,index = meta.variable_storage_width.keys()
            ,dtype = int
        )
        .reindex(meta_loadsas['NAME'])
        .set_axis(meta_loadsas.index)
    )
    meta_loadsas.loc[:, 'LABEL'] = (
        pd.Series(
            meta.column_names_to_labels.values()
            ,index = meta.column_names_to_labels.keys()
            ,dtype = str
        )
        .reindex(meta_loadsas['NAME'])
        .set_axis(meta_loadsas.index)
    )
    meta_loadsas.loc[lambda x: x['NAME'].eq('f_qpv'), 'FORMATD'] = 0
    outf4 = os.path.join(os.getcwd(), 'vfysas4.sas7bdat')
    rc = writeSASdat(loadsas, outf4, metaVar = meta_loadsas, encoding = 'GB2312')
    if os.path.isfile(outf4): os.remove(outf4)
#-Notes- -End-
'''
