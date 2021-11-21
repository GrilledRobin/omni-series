#!/usr/bin/env python3
# -*- coding: utf-8 -*-

logger.info('step 2')

import subprocess as sp

L_sasflnm = os.path.join(dir_curr, 'testrun.sas')
L_saslog = os.path.join(dir_curr, 'testrun.log')

logger.info('Executing below SAS program...')
logger.info('<' + L_sasflnm + '>')

#Convention to use [sp.Popen]
#[1] Always use [call] in command console to execute an external BAT script: cmd = ['call', 'xxx.bat'] for returncode retrieval
#[2] Always set [shell=False] to avoid unnecessary waste or error of system parsing
#[3] Always pass [list] as command to minimize shell quoting

#100. Prepare the command in the console
#20211026 It is tested that when we require correct returncode from an external BAT script, we have to [call] it, e.g.
# L_cmd = [ 'call', 'D:\test.bat' ]
L_cmd = [SAS_EXE, L_sasflnm, '-LOG', L_saslog] + SAS_CFG_INIT
#logger.info('<' + ' '.join(L_cmd) + '>')

#500. Prepare the pipe to the command console
rc = sp.Popen(
    L_cmd
    #[shell=True] is often used when the command is comprised of executable, arguments and switches, instead of a list
    #It is always recommended NOT to set [shell] argument for [sp.Popen] to save system parsing resources
    #Quote: https://stackoverflow.com/questions/20451133/
    #Quote: https://stackoverflow.com/questions/69544990/
    ,shell = False
    ,stdout = sp.PIPE
    ,stderr = sp.PIPE
)

#700. Communicate with the pipe, i.e. submit the commands in the console
#[ASSUMPTION]
#[1] This operation cause Python to wait for the completion of the commands
#[2] This operation enables a [returncode] after the completion of the commands
sas_msg, sas_errs = rc.communicate()

#709. Abort the process if SAS program encounters issues
if rc.returncode:
    raise RuntimeError('SAS program executed with errors!')

#790. Terminate the command console
rc.terminate()
