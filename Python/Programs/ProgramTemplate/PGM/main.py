#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Load preliminary packages
import os, sys, re, logging
import datetime as dt
from itertools import product
from inspect import getsourcefile

#002. Take the command line arguments ahead of all other processes
#[ASSUMPTION]
#[1] All input values will be split by [space]; hence please ensure they are properly quoted where necessary
#[2] All input values are stored in one [list] of characters
#[3] Script file name is always the first in this list, which we ignore for most of the scenarios
args_in = sys.argv.copy()
args_in.pop(0)
#This program takes 2 arguments in below order:
#[1] [dateEnd         ] [character       ] [yyyymmdd        ]
#[2] [dateBgn         ] [character       ] [yyyymmdd        ]
if len(args_in) == 0:
    raise ValueError('No argument is detected! Program aborted!')

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

#050. Define local environment
#051. Period of dates for current script
#[IMPORTANT] Due to definition of [omniPy.Dates.UserCalendar], we have to set [dateBgn] ahead of [dateEnd]
f_has_dateBgn = False
if len(args_in) == 2:
    if len(args_in[-1]):
        f_has_dateBgn = True

if f_has_dateBgn:
    G_clndr.dateBgn = args_in[-1]
else:
    #010. Declare the logic
    #[ASSUMPTION]
    #[1] Using [logging.info] will only write the message into the log file
    #[2] Using [logger.info] will write the message both into the log file and the command console
    logger.info('<dateBgn> is not provided, use <Current Quarter Beginning> instead.')

    #100. Prepare to observe the date originated from the first input argument
    G_obsDates.values = args_in[0]

    #500. Retrieve <Current Quarter Beginning> by adding 1 calendar day to the <Last Calendar Day of the Previous Quarter>
    G_clndr.dateBgn = G_obsDates.prevQtrLCD[0] + dt.timedelta(days = 1)

G_clndr.dateEnd = args_in[0]

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

#058. Prepare SAS parameters, in case one has to call SAS for interaction
#[ASSUMPTION]
#[1] There is no need to quote the commands in shell, as [subprocess] will do the implicit quoting
#Quote: https://stackoverflow.com/questions/14928860/passing-double-quote-shell-commands-in-python-to-subprocess-popen
SAS_HOME = r'C:\SASHome\SASFoundation\9.4'
#SAS_HOME = r'C:\Program Files\SASHome\x86\SASFoundation\9.4'
SAS_EXE = os.path.join(SAS_HOME, 'sas.exe')
SAS_CFG_ZH = os.path.join(SAS_HOME, 'nls', 'zh', 'sasv9.cfg')
SAS_CFG_INIT = ['-CONFIG', SAS_CFG_ZH, '-MEMSIZE', '0', '-NOLOGO', '-ICON']
SAS_omnimacro = [ d for d in paths_omnimacro if os.path.isdir(d) ][0]

#100. Find all subordinate scripts that are to be called within current session
pgms_curr = opy.FileSystem.getMemberByStrPattern(dir_curr, r'^\d{3}_.+\.py$', chkType = 1, FSubDir = False)
i_len = len(pgms_curr)

#700. Print configurations into the log for debug
#701. Prepare lists of parameters
key_args = {
    'dateBgn' : G_clndr.dateBgn.strftime('%Y-%m-%d')
    ,'dateEnd' : G_clndr.dateEnd.strftime('%Y-%m-%d')
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
logger.info('-' * 80)
if i_len == 0:
    raise RuntimeError('No available subordinate script is found! Program terminated!')

logger.info('Subordinate scripts to be called in below order:')
i_nums = len(str(i_len))
mlen_pgms = max([ len(os.path.basename(p[0])) for p in pgms_curr ])
for i in range(i_len):
    #100. Pad the sequence numbers by leading zeros, to make the log audience-friendly
    i_char = str(i+1).zfill(i_nums)

    #999. Print the message
    logger.info('<' + i_char + '>: <' + os.path.basename(pgms_curr[i][0]).ljust(mlen_pgms, ' ') + '>')

#800. Call the subordinate scripts that are previously found
logger.info('-' * 80)
logger.info('Calling subordinate scripts...')
logger.info('-' * 40)
for pgm in pgms_curr:
    #001. Declare which script is called at this step
    logger.info('<' + os.path.basename(pgm[0]) + '> Beginning...')

    #990. Call the dedicated program
    exec_file(pgm[0])

    #999. Mark completion of current step
    logger.info('<' + os.path.basename(pgm[0]) + '> Complete!')
    logger.info('-' * 40)

logger.info('Process Complete!')
