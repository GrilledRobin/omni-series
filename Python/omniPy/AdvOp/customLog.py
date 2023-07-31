#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import logging
from typing import Union, Optional

def customLog(
    name : str
    ,propagate : bool
    ,console : bool = True
    ,logfile : Union[bool, str] = True
    ,debugfile : Union[bool, str] = False
    ,fmt : str = '%(levelname)s: %(asctime)-15s %(message)s'
    ,datefmt : Optional[str] = None
    ,level : int = logging.DEBUG
    ,logWarnings : bool = True
) -> logging.Logger:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create or extend a customized logger (only when it is a Singleton)                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Log the results both inside the command console and to an external log file, optionally with a debug file                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |name        :   Character string as the name of the logger to be created/extended                                                  #
#   |propagate   :   Whether to propagate the messages to all parent loggers, see Python: logging.Logger.propagate                      #
#   |                 [None        ] <Default> Follow the default behavior of Python                                                    #
#   |                 [False       ]           Usually used in custom logger                                                            #
#   |console     :   Whether to log the messages into the command console                                                               #
#   |                 [True        ] <Default> Log the messages into the console                                                        #
#   |                 [False       ]           Do not log messages into the console                                                     #
#   |logfile     :   Whether or where to store the messages into a log file                                                             #
#   |                 [True        ] <Default> Write messages to <logger.log> in the same location as the caller script                 #
#   |                 [False       ]           Do not create logfile                                                                    #
#   |                 [<str>       ]           Absolute path of the dedicated logfile to write the messages                             #
#   |debugfile   :   Whether or where to store the <logger.debug> messages into a debug file                                            #
#   |                 [False       ] <Default> Do not create debugfile                                                                  #
#   |                 [True        ]           Write DEBUG messages to <debug.log> in the same location as the caller script            #
#   |                 [<str>       ]           Absolute path of the dedicated debugfile to write the messages                           #
#   |fmt         :   Whether to propagate the messages to all parent loggers, see Python: logging.Logger.propagate                      #
#   |                 [<see def>   ] <Default> Use the dedicated formatter, see logging.Formatter                                       #
#   |                 [<str>       ]           Customized formatter                                                                     #
#   |datefmt     :   How to format the datetime, see logging.Formatter                                                                  #
#   |                 [<see def>   ] <Default> Use the dedicated formatter, see logging.Formatter                                       #
#   |                 [<str>       ]           Customized formatter                                                                     #
#   |level       :   Level to write logs, see <Python logging levels>                                                                   #
#   |                 [<see def>   ] <Default> Use the dedicated level to create logs                                                   #
#   |                 [<int>       ]           Specific level                                                                           #
#   |logWarnings :   Whether to log the <warnings.warn> messages into the <logfile>                                                     #
#   |                 [True        ] <Default> Log the dedicated messages into <logfile> instead of <console>                           #
#   |                 [False       ]           Log the dedicated messages into <console> instead of <logfile>                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Logger]    :   A customized logger instance                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230731        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, logging, typing                                                                                                           #
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
    __Err : str = 'ERROR: [' + LfuncName + ']Process failed due to errors!'

    #012. Handle the parameter buffer
    if not isinstance(propagate, bool):
        propagate = False
    if isinstance(logfile, bool):
        if logfile: logfile = 'logger.log'
    if isinstance(debugfile, bool):
        if debugfile: debugfile = 'debug.log'
    if (not debugfile) and (level > logging.DEBUG):
        print(f'[{LfuncName}][debugfile] is not defined, DEBUG messages will be ignored.')

    #100. Create a plain logger
    _logger = logging.getLogger(name)
    _logger.setLevel(level)
    if not propagate:
        _logger.propagate = False

    #200. Setup the formatter
    fmtter = logging.Formatter(fmt = fmt, datefmt = datefmt)

    #300. Setup handlers
    if console:
        _console = logging.StreamHandler(stream = sys.stdout)
        _console.setLevel(level)
        _console.setFormatter(fmtter)
        _logger.addHandler(_console)

    if logfile:
        _normal = logging.FileHandler(logfile)
        if debugfile:
            _normal.setLevel(logging.INFO)
        else:
            _normal.setLevel(level)
        _normal.setFormatter(fmtter)
        _logger.addHandler(_normal)

    if debugfile:
        _debug = logging.FileHandler(debugfile)
        _debug.setLevel(level)
        _debug.setFormatter(fmtter)
        _logger.addHandler(_debug)

    #500. Whether and where to log the <warnings.warn> messages
    #[ASSUMPTION]
    #[1] https://stackoverflow.com/questions/41764345/python-3-how-to-log-warnings-and-errors-to-log-file
    #[2] https://docs.python.org/3/library/logging.html#logrecord-attributes
    #[3] Without this part, or without the <if> clause, such messages cannot be captured
    if logWarnings:
        logging.captureWarnings(True)
        logging.basicConfig(
            filename = logfile
            ,level = level
            ,format = fmt
        )

    #700. Define hook to capture the [Traceback] that is printed in the command console when errors are raised
    def h_exception(exc_type, exc_value, exc_traceback):
        #Ignore exception from keyboard interruption, so that one can use [Ctrl+C] to terminate the process in the console
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return

        _logger.error('Uncaught exception', exc_info=(exc_type, exc_value, exc_traceback))

    sys.excepthook = h_exception

    #999. Export
    return(_logger)

#End customLog

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    from warnings import warn
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import customLog

    #100. Setup loggers
    #[IMPORTANT]
    #[1] These two loggers MUST be both invoked to enable the correct logging
    #Only with this line can <warnings.warn> be logged into the logfile
    logger = customLog('', True, logWarnings = True)
    #Only with this line can <warnings.warn> be logged into the console
    logger = customLog(__name__, False, logWarnings = False)

    #300. Test the log function
    #Below result cannot be captured into the logfile
    print('This will show in the logfile')

    #Original logger.info also works fine
    logger.info('This should be OK')

    #400. Test the warning message
    warn('Dedicated to display the warning message')

    #500. Test the exception
    raise RuntimeError('Dedicated to abort the session')
#-Notes- -End-
'''
