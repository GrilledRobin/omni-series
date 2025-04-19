#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Load preliminary packages
import os, sys, re, logging
import shutil as su
from warnings import warn
from itertools import product
from inspect import getsourcefile
from packaging import version
#[ASSUMPTION]
#[1] Below 3rd-party packages require Anaconda to be installed, or PIP to install
from wcwidth import wcswidth

args_in = sys.argv.copy()

#003. Find the location of current script
#Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
scr_name : str = getsourcefile(lambda:0)
# scr_name = r'D:\Python\Programs\ProgramTemplate_DM\PGM\main.py'
dir_curr = os.path.dirname(scr_name)

#019. Enable the text writing to the log file
log_name = os.path.join(dir_curr, re.sub(r'\.\w+$', '.log', os.path.basename(scr_name)))

#020. Import the user defined package
#021. Define the candidates
drives_autoexec = [ d + os.sep for d in ['D:', 'C:'] ]
paths_autoexec = ['Python', 'Robin', 'RobinLu', 'SAS']
name_autoexec = r'autoexec.py'
name_omniPy = r'omniPy'
name_omnimacro = r'omnimacro'
#Quote: https://stackoverflow.com/questions/533905/get-the-cartesian-product-of-a-series-of-lists
comb_autoexec = list(product(drives_autoexec, paths_autoexec))
files_autoexec = [ os.path.join( *p, name_autoexec ) for p in comb_autoexec ]
paths_omniPy = [ os.path.join( *p ) for p in comb_autoexec ]
paths_omnimacro = [ os.path.join( *p, name_omnimacro ) for p in comb_autoexec ]

#022. Only retrieve the first valid path from the list of candidate paths
exist_autoexec = [ f for f in files_autoexec if os.path.isfile(f) ]
if not exist_autoexec:
    raise RuntimeError(f'[{name_autoexec}] is not found! Program aborted!')

file_autoexec = exist_autoexec[0]

#025. Attach the path to the system path list for the method [__import__]
#[IMPORTANT] The path which [__import__] is looking for a package is the [Parent Directory] to its name!
path_omniPy = [ d for d in paths_omniPy if os.path.isdir(os.path.join(d,name_omniPy)) ][0]
if path_omniPy not in sys.path:
    sys.path.append( path_omniPy )

#027. Enable the function to execute other scripts in the same environment
from omniPy.AdvOp import exec_file, modifyDict, customLog, PrintToLog, thisShell, alignWidth
from omniPy.AdvDB import DataIO
from omniPy.Dates import UserCalendar, ObsDates, intnx
from omniPy.FileSystem import getMemberByStrPattern, winReg_getInfByStrPattern

#030. Prepare logging
#031. Clean all previously registered handlers, in case this program is executed again in the same session
for h in logging.root.handlers[:]:
    logging.root.removeHandler(h)

#035. Setup loggers
#[IMPORTANT]
#[1] These two loggers MUST be both invoked to enable the correct logging
#[2] Sequence of below lines MUST be as is, to ensure correct position of <warnings.warn> messages
#Only with this line can <warnings.warn> be logged into the console
logger = customLog(__name__, False, mode = 'w', logfile = log_name, logWarnings = False)
#Only with this line can <warnings.warn> be logged into the logfile
logger = customLog('', True, mode = 'a', logfile = log_name, logWarnings = True)

#037. Enable the logger to capture <print> results in both console and logfile
if thisShell() in ['CLI']:
    PrintToLog(logger)

#040. Load useful user-defined environment
#Check the [__doc__] of below script for its detailed output
exec_file(file_autoexec)

#050. Define local environment
#051. Period of dates for current script
#[ASSUMPTION]
#[1] Take the command line arguments ahead of the rest processes
#[2] All input values will be split by [space]; hence please ensure they are properly quoted where necessary
#[3] All input values are stored in one [list] of characters
#[4] Script file name is always the first in this list, which we ignore for most of the scenarios
#[5] If any argument is provided, we should reset [G_clndr] and [G_obsDates] as their period coverage may have been extended
args_in.pop(0)
#This program may take up to 2 arguments in below order:
#[1] [dateRpt         ] [character       ] [yyyymmdd        ]
#[2] [sendEmail       ] [character       ] [0, 1 or <empty> ]
if len(args_in):
    #300. Modify the default arguments to create calendars
    #[ASSUMPTION]
    #[1] <getOption> is defined in <autoexec>
    argEnd = args_in[0]
    args_cln_mod = modifyDict(
        getOption['args.Calendar']
        ,{
            'clnBgn' : intnx('day', argEnd, -30, daytype = 'C')
            ,'clnEnd' : intnx('day', argEnd, 30, daytype = 'C')
        }
    )

    #500. Create a fresh new calendar
    G_clndr = UserCalendar(**args_cln_mod)

    #700. Create a fresh new date observer
    G_obsDates = ObsDates(obsDate = intnx('day', argEnd, 1, daytype = 'W'), **args_cln_mod)

#[ASSUMPTION]
#[1] As a business case, we often call the process on the previous workday of current run date
#[2] We align the system behavior when the Business Date is provided or not
#    [a] When NOT providing a date, the Business Date is the previous workday of the run date
#    [b] When a date is provided, it is presumed to be the Business Date to run the process
#[3] As the date is always referred to as a character string marking files or connections, we set it as a string representation
L_curdate = intnx('day', G_obsDates.values[0], -1, daytype = 'W').strftime('%Y%m%d')

#052. Directories for current process
dir_proc = os.path.dirname(dir_curr)
dir_out = os.path.join(dir_proc, 'Report')
dir_data = os.path.join(dir_proc, 'Data')
dir_data_raw = os.path.join(dir_data, 'RAWDATA')
dir_data_db = os.path.join(dir_data, 'DB')
dir_data_src = os.path.join(dir_data, 'SRC')
dir_ctrl = os.path.join(dir_curr, 'Control')
if not os.path.isdir(dir_ctrl): os.makedirs(dir_ctrl)

#055. Directories for local data mart
dir_DM = os.path.join('D:\ '.strip(), '01LocalDM', 'Data')
dir_DM_raw = os.path.join(dir_DM, '01RAW')
dir_DM_sas = os.path.join(dir_DM, '02SAS')
dir_DM_db = os.path.join(dir_DM, 'DB')
dir_DM_src = os.path.join(dir_DM, 'SRC')
dir_DM_T1 = os.path.join(dir_DM, 'custlvl')
dir_DM_T2 = os.path.join(dir_DM_db, '08Digital Banking')

#059. Initialize the I/O class for standardization of data API
dataIO = DataIO()

#060. Determine whether to send email
f_sendmail = False
if len(args_in) == 2:
    f_sendmail = args_in[1] == '1'

#063. Search for necessary scripts anyway
scr_mail_ctrl = getMemberByStrPattern(
    dir_ctrl
    ,r'^\d{3}_.*(mail).*\.py$'
    ,chkType = 1
    ,FSubDir = False
)
scr_mail_curr = getMemberByStrPattern(
    dir_curr
    ,r'^\d{3}_.*(mail).*\.py$'
    ,chkType = 1
    ,FSubDir = False
)

#065. Move the script of sending mail in terms of the request
#[ASSUMPTION]
#[1] We allow multiple scripts to send emails
#[2] If there is any script of the same name in both <dir_ctrl> and <dir_curr>, we overwrite the destination file without warning
if f_sendmail:
    #100. Issue warning if there is no script to send email
    if (len(scr_mail_ctrl) == 0) and (len(scr_mail_curr) == 0):
        warn('No script found for emailing!')

    #500. Move the scripts from <dir_ctrl> to <dir_curr>
    for obj in scr_mail_ctrl:
        su.copy2(obj['path'], dir_curr)
        os.remove(obj['path'])
else:
    #500. Move the scripts from <dir_curr> to <dir_ctrl>
    for obj in scr_mail_curr:
        su.copy2(obj['path'], dir_ctrl)
        os.remove(obj['path'])

#080. Locate binaries of other languages for interaction
#081. Prepare R parameters, in case one has to call RScript.exe for interaction
rKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\R-core\R64'
rVal = r'InstallPath'
r_install = winReg_getInfByStrPattern(rKey, rVal)
if len(r_install):
    R_HOME = r_install[0]['value']
else:
    R_HOME = ''

R_EXE = os.path.join(R_HOME, 'bin', 'Rscript.exe')

#083. Prepare SAS parameters, in case one has to call SAS for interaction
#[ASSUMPTION]
#[1] There is no need to quote the commands in shell, as [subprocess] will do the implicit quoting
#Quote: https://stackoverflow.com/questions/14928860/passing-double-quote-shell-commands-in-python-to-subprocess-popen
sasKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\SAS Institute Inc.\The SAS System'
#The names of the direct sub-keys are the version numbers of all installed [SAS] software
sasVers = winReg_getInfByStrPattern(sasKey, inRegExp = r'^\d+(\.\d+)+$', chkType = 2)
if len(sasVers):
    sasVers_comp = [ version.parse(v.get('name', None)) for v in sasVers ]
    sasVer = sasVers[sasVers_comp.index(max(sasVers_comp))].get('name', None)
    SAS_HOME = winReg_getInfByStrPattern(os.path.join(sasKey, sasVer), 'DefaultRoot')[0]['value']
else:
    SAS_HOME = ''

SAS_EXE = os.path.join(SAS_HOME, 'sas.exe')
SAS_CFG_ZH = os.path.join(SAS_HOME, 'nls', 'zh', 'sasv9.cfg')
SAS_CFG_INIT = ['-CONFIG', SAS_CFG_ZH, '-MEMSIZE', '0', '-NOLOGO', '-ICON']
SAS_omnimacro = [ d for d in paths_omnimacro if os.path.isdir(d) ][0]

#100. Find all subordinate scripts that are to be called within current session
pgms_curr = getMemberByStrPattern(dir_curr, r'^\d{3}_.+\.py$', chkType = 1, FSubDir = False)

#700. Print configurations into the log for debug
#701. Prepare lists of parameters
key_args = {
    'rundate' : L_curdate
}
key_dirs = {
    'Process Home' : dir_curr
    # ,'SAS omnimacro' : SAS_omnimacro
}
key_tolog = {**key_args, **key_dirs}
#[ASSUMPTION]
#[1] We obtain the displayed width of the string, e.g. 2 for a Chinese character
#[2] Quote: https://blog.csdn.net/weixin_45715159/article/details/106176454
#[3] We do the same for below messaging
mlen_prms = max([ wcswidth(k) for k in key_tolog.keys() ])

#710. Print parameters
#[ASSUMPTION]
#[1] Triangles [<>] are not accepted in naming folders, hence they are safe to be used for enclosing the value of variables
print('-' * 80)
print('Process Parameters:')
for k,v in key_tolog.items():
    print('<' + alignWidth(k, width = mlen_prms) + '>: <' + v + '>')

#720. Print existence of key directories
print('-' * 80)
print('Existence of above key locations:')
for k,v in key_dirs.items():
    print('<' + alignWidth(k, width = mlen_prms) + '>: <' + str(os.path.isdir(v)) + '>')

if not all([ os.path.isdir(v) for v in key_dirs.values() ]):
    raise RuntimeError('Some among the key locations DO NOT exist! Program terminated!')

#770. Subordinate scripts
print('-' * 80)
print('Subordinate scripts to be located at:')
print(dir_curr)
if not pgms_curr:
    raise RuntimeError('No available subordinate script is found! Program terminated!')

#780. Verify the process control file to minimize the system calculation effort
fname_ctrl = f'proc_ctrl{L_curdate}.txt'
proc_ctrl = os.path.join(dir_curr, fname_ctrl)

#781. Remove any control files that were created on other dates
cln_ctrls = getMemberByStrPattern(
    dir_curr
    ,r'^proc_ctrl\d{8}\.txt$'
    ,exclRegExp = f'^{fname_ctrl}$'
    ,chkType = 1
    ,FSubDir = False
)
for f in cln_ctrls:
    os.remove(f['path'])

#785. Read the content of the process control file, which represents the previously executed scripts
pgm_executed = []
if os.path.isfile(proc_ctrl):
    #100. Read all lines into a list
    with open(proc_ctrl, 'r') as f:
        pgm_executed = f.readlines()

    #500. Exclude those beginning with a semi-colon [;], resembling the syntax of [MS DOS]
    pgm_executed = [ f.strip() for f in pgm_executed if not f.startswith(';') ]

#787. Exclude the previously executed scripts from the full list for current session
if pgm_executed:
    #010. Remove duplicates from this list
    pgm_executed_dedup = sorted(list(set(pgm_executed)))

    #100. Prepare the log
    print('-' * 80)
    print('Below scripts have been executed today, thus are excluded.')
    for f in pgm_executed_dedup:
        print('<' + f + '>')

    #900. Exclusion
    pgms_curr = [ o for o in pgms_curr if os.path.basename(o['path']) not in pgm_executed_dedup ]
    if not pgms_curr:
        print('All scripts have been executed previously. Program completed.')
        sys.exit()

print('-' * 80)
print('Subordinate scripts to be called in below order:')
i_nums = len(str(len(pgms_curr)))
#[ASSUMPTION]
#Quote[#26]: https://stackoverflow.com/questions/30686701/python-get-size-of-string-in-bytes
# mlen_pgms = max([ len(os.path.basename(p[0]).encode('utf-16-le')) for p in pgms_curr ])
#[1] Above solution cannot get the displayed width of the MBCS character string
#[2] We leverage <wcwidth> for such process
#[3] By doing this, the messages shown in Command Console will be aligned with the same length
#[4] However, in the text editors using mono space fonts such as <Courier New> will have weird spacing
mlen_pgms = max([ wcswidth(os.path.basename(p['path'])) for p in pgms_curr ])
for i,pgm in enumerate(pgms_curr):
    #100. Pad the sequence numbers by leading zeros, to make the log audience-friendly
    i_char = str(i+1).zfill(i_nums)

    #300. Obtain the script file name
    fname_scr = os.path.basename(pgm['path'])

    #500. Determine the padding
    scr_pad = alignWidth(fname_scr, width = mlen_pgms)

    #999. Print the message
    print(f'<{i_char}>: <{scr_pad}>')

#800. Call the subordinate scripts that are previously found
print('-' * 80)
print('Calling subordinate scripts...')
for i,pgm in enumerate(pgms_curr):
    #001. Get the file name of the script
    fname_scr = os.path.basename(pgm['path'])

    #100. Declare which script is called at this step
    print('-' * 40)
    print(f'<{fname_scr}> Beginning...')

    #500. Call the dedicated program
    exec_file(pgm['path'])

    #700. Write current script to the process control file for another call of the same process
    with open(proc_ctrl, 'a') as f:
        f.writelines(fname_scr + '\n')

    #999. Mark completion of current step
    print(f'<{fname_scr}> Complete!')

print('-' * 80)
print('Process Complete!')
