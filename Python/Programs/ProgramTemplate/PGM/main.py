#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Load preliminary packages
import os, sys, re, logging
from itertools import product
from inspect import getsourcefile
from packaging import version

args_in = sys.argv.copy()

#003. Find the location of current script
#Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
scr_name : str = getsourcefile(lambda:0)
# scr_name = r'D:\Python\Programs\ProgramTemplate\PGM\main.py'
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
    raise RuntimeError('['+name_autoexec+'] is not found! Program aborted!')

file_autoexec = exist_autoexec[0]

#025. Attach the path to the system path list for the method [__import__]
#[IMPORTANT] The path which [__import__] is looking for a package is the [Parent Directory] to its name!
path_omniPy = [ d for d in paths_omniPy if os.path.isdir(os.path.join(d,name_omniPy)) ][0]
if path_omniPy not in sys.path:
    sys.path.append( path_omniPy )

#027. Enable the function to execute other scripts in the same environment
from omniPy.AdvOp import exec_file, modifyDict, customLog, PrintToLog
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
#[1] [dateEnd         ] [character       ] [yyyymmdd        ]
#[2] [dateBgn         ] [character       ] [yyyymmdd        ]
if len(args_in):
    #010. Verify the number of input arguments
    f_has_dateBgn = False
    if len(args_in) == 2:
        if len(args_in[-1]):
            f_has_dateBgn = True

    #100. Determine the beginning and ending of the request
    argEnd = args_in[0]
    if f_has_dateBgn:
        argBgn = args_in[-1]
    else:
        #010. Declare the logic
        #[ASSUMPTION]
        #[1] Using [logging.info] will only write the message into the log file
        #[2] Using [logger.info] will write the message both into the log file and the command console
        logger.info('<dateBgn> is not provided, set the period coverage as 3 months counting backwards.')

        #100. Shift the ending date to its 2nd previous month beginning
        argBgn = intnx('month', argEnd, -2, 'b')

    #300. Modify the default arguments to create calendars
    args_cln_mod = modifyDict(getOption['args.Calendar'], {'clnBgn' : argBgn, 'clnEnd' : argEnd})

    #500. Create a fresh new calendar
    G_clndr = UserCalendar(**args_cln_mod)

    #700. Create a fresh new date observer
    G_obsDates = ObsDates(obsDate = argEnd, **args_cln_mod)

#052. Directories for current process
dir_proc = os.path.dirname(dir_curr)
dir_out = os.path.join(dir_proc, 'Report')
dir_data = os.path.join(dir_proc, 'Data')
dir_data_raw = os.path.join(dir_data, 'RAWDATA')
dir_data_db = os.path.join(dir_data, 'DB')

#055. Directories for local data mart
dir_DM = os.path.join('D:\ '.strip(), '01LocalDM', 'Data')
dir_DM_raw = os.path.join(dir_DM, '01RAW')
dir_DM_sas = os.path.join(dir_DM, '02SAS')
dir_DM_db = os.path.join(dir_DM, 'DB')
dir_DM_src = os.path.join(dir_DM, 'SRC')
dir_DM_T1 = os.path.join(dir_DM, 'custlvl')
dir_DM_T2 = os.path.join(dir_DM_db, '08Digital Banking')

#057. Prepare R parameters, in case one has to call RScript.exe for interaction
rKey = r'HKEY_LOCAL_MACHINE\SOFTWARE\R-core\R64'
rVal = r'InstallPath'
r_install = winReg_getInfByStrPattern(rKey, rVal)
if len(r_install):
    R_HOME = r_install[0]['value']
else:
    R_HOME = ''

R_EXE = os.path.join(R_HOME, 'bin', 'Rscript.exe')

#058. Prepare SAS parameters, in case one has to call SAS for interaction
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
i_len = len(pgms_curr)

#700. Print configurations into the log for debug
#701. Prepare lists of parameters
key_args = {
    'rundate' : G_obsDates.values[0].strftime('%Y-%m-%d')
}
key_dirs = {
    'Process Home' : dir_curr
    # ,'SAS omnimacro' : SAS_omnimacro
}
key_tolog = {**key_args, **key_dirs}
mlen_prms = max([ len(k) for k in key_tolog.keys() ])

#710. Print parameters
#[ASSUMPTION]
#[1] Triangles [<>] are not accepted in naming folders, hence they are safe to be used for enclosing the value of variables
logger.info('-' * 80)
logger.info('Process Parameters:')
for k,v in key_tolog.items():
    logger.info('<' + k.ljust(mlen_prms, ' ') + '>: <' + v + '>')

#720. Print existence of key directories
logger.info('-' * 80)
logger.info('Existence of above key locations:')
for k,v in key_dirs.items():
    logger.info('<' + k.ljust(mlen_prms, ' ') + '>: <' + str(os.path.isdir(v)) + '>')

if not all([ os.path.isdir(v) for v in key_dirs.values() ]):
    raise RuntimeError('Some among the key locations DO NOT exist! Program terminated!')

#770. Subordinate scripts
logger.info('-' * 80)
logger.info('Subordinate scripts to be located at:')
logger.info(dir_curr)
if i_len == 0:
    raise RuntimeError('No available subordinate script is found! Program terminated!')

#780. Verify the process control file to minimize the system calculation effort
fname_ctrl = r'proc_ctrl' + G_obsDates.values[0].strftime('%Y%m%d') + '.txt'
proc_ctrl = os.path.join(dir_curr, fname_ctrl)

#781. Remove any control files that were created on other dates
cln_ctrls = getMemberByStrPattern(
    dir_curr
    ,r'^proc_ctrl\d{8}\.txt$'
    ,exclRegExp = r'^' + fname_ctrl + r'$'
    ,chkType = 1
    ,FSubDir = False
)
if len(cln_ctrls):
    for f in cln_ctrls:
        os.remove(f[0])

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
    logger.info('-' * 80)
    logger.info('Below scripts have been executed today, thus are excluded.')
    for f in pgm_executed_dedup:
        logger.info('<' + f + '>')

    #900. Exclusion
    pgms_curr = [ o for o in pgms_curr if os.path.basename(o[0]) not in pgm_executed_dedup ]
    i_len = len(pgms_curr)
    if i_len == 0:
        logger.info('All scripts have been executed previously. Program completed.')
        sys.exit()

logger.info('-' * 80)
logger.info('Subordinate scripts to be called in below order:')
i_nums = len(str(i_len))
#Quote[#26]: https://stackoverflow.com/questions/30686701/python-get-size-of-string-in-bytes
mlen_pgms = max([ len(os.path.basename(p[0]).encode('utf-16-le')) for p in pgms_curr ])
for i in range(i_len):
    #100. Pad the sequence numbers by leading zeros, to make the log audience-friendly
    i_char = str(i+1).zfill(i_nums)

    #999. Print the message
    logger.info('<' + i_char + '>: <' + os.path.basename(pgms_curr[i][0]).ljust(mlen_pgms, ' ') + '>')

#800. Call the subordinate scripts that are previously found
logger.info('-' * 80)
logger.info('Calling subordinate scripts...')
for pgm in pgms_curr:
    #001. Get the file name of the script
    fname_scr = os.path.basename(pgm[0])

    #100. Declare which script is called at this step
    logger.info('-' * 40)
    logger.info('<' + fname_scr + '> Beginning...')

    #500. Call the dedicated program
    exec_file(pgm[0])

    #700. Write current script to the process control file for another call of the same process
    with open(proc_ctrl, 'a') as f:
        f.writelines(fname_scr + '\n')

    #999. Mark completion of current step
    logger.info('<' + fname_scr + '> Complete!')

logger.info('-' * 80)
logger.info('Process Complete!')
