#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Load preliminary packages
import os, sys, re, logging
import platform
from itertools import product
from inspect import getsourcefile

#003. Find the location of current script
#Quote: https://www.geeksforgeeks.org/how-to-get-directory-of-current-script-in-python/
scr_name : str = getsourcefile(lambda:0)
dir_curr = os.path.dirname(scr_name)

#010. Prepare logging
#011. Clean all previously registered handlers, in case this program is executed again in the same session
for h in logging.root.handlers[:]:
    logging.root.removeHandler(h)

#013. Define handler to capture the [Error]s that could be raised to abort the process
#Quote: http://stackoverflow.com/a/16993115/512111
handler_err = logging.StreamHandler(stream = sys.stdout)

#015. Create a custom logger with the stream handler
logger = logging.getLogger(__name__)
logger.addHandler(handler_err)

#017. Define hook to capture the [Traceback] that is printed in the command console when errors are raised
def handle_exception(exc_type, exc_value, exc_traceback):
    #Ignore exception from keyboard interruption, so that one can use [Ctrl+C] to terminate the process in the console
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return

    logger.error("Uncaught exception", exc_info=(exc_type, exc_value, exc_traceback))

sys.excepthook = handle_exception

#019. Enable the text writing to the log file
log_name = os.path.join(dir_curr, re.sub(r'\.\w+$', '.log', os.path.basename(scr_name)))
logging.basicConfig(
    filename = log_name
    ,filemode = 'w'
    ,level = logging.DEBUG
    #Quote: https://docs.python.org/3/library/logging.html#logrecord-attributes
    ,format = '%(levelname)s: %(asctime)-15s %(message)s'
)

#030. Import the user defined package
#031. Define the candidates
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

#032. Only retrieve the first valid path from the list of candidate paths
exist_autoexec = [ f for f in files_autoexec if os.path.isfile(f) ]
if not exist_autoexec:
    raise RuntimeError('['+name_autoexec+'] is not found! Program aborted!')

file_autoexec = exist_autoexec[0]

#035. Attach the path to the system path list for the method [__import__]
#[IMPORTANT] The path which [__import__] is looking for a package is the [Parent Directory] to its name!
path_omniPy = [ d for d in paths_omniPy if os.path.isdir(os.path.join(d,name_omniPy)) ][0]
if path_omniPy not in sys.path:
    sys.path.append( path_omniPy )

#037. Enable the function to execute other scripts in the same environment
from omniPy.AdvOp import exec_file

#039. Load useful user-defined environment
#Check the [__doc__] of below script for its detailed output
exec_file(file_autoexec)

#040. Load user defined functions
from omniPy.AdvOp import getWinUILanguage
from omniPy.FileSystem import winKnownFolders, getMemberByStrPattern, winReg_QueryValue

#050. Define local environment
#051. Variables that can be used at different steps
curr_win_ver = platform.release()
curr_win_lang = getWinUILanguage()
#Retrieve the default folder [Downloads] for current user on Windows OS
dir_Downloads = winKnownFolders('Downloads')

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
R_HOME = winReg_QueryValue(rKey, rVal) or ''
R_EXE = os.path.join(R_HOME, 'bin', 'Rscript.exe')

#058. Prepare SAS parameters, in case one has to call SAS for interaction
#[ASSUMPTION]
#[1] There is no need to quote the commands in shell, as [subprocess] will do the implicit quoting
#Quote: https://stackoverflow.com/questions/14928860/passing-double-quote-shell-commands-in-python-to-subprocess-popen
sasVer = '9.4'
sasKey = os.path.join(r'HKEY_LOCAL_MACHINE\SOFTWARE\SAS Institute Inc.\The SAS System', sasVer)
sasVal = r'DefaultRoot'
SAS_HOME = winReg_QueryValue(sasKey, sasVal) or ''
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
    ,'SAS Home' : SAS_HOME
    ,'SAS omnimacro' : SAS_omnimacro
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
