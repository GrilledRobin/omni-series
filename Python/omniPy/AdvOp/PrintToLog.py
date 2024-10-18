#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from omniPy.AdvOp import SingletonMeta

#100. Definition of the class.
class PrintToLog(metaclass = SingletonMeta):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to duplicate the console output stream to the logfile                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Reference:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Duplicate log stream: https://stackoverflow.com/questions/18214902/logging-module-for-print-statements-duplicate-log-entries       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__init__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate a singleton object to redirect the stdout stream                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |logger            :   <logger  > logging.Logger instance to patch                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   Only for initialization                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[write]                                                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to overwrite the method <stream.write> by redirecting it to logger                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |record            :   The message to emit from <stream.write>                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   Only for writing message                                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[flush]                                                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to mask the method in <sys.stdout>                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take arguments                                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   Only for writing message                                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230731        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20241018        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when <sys.stdout.isatty()> is required in any process                                                       #
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
#   |   |<None>                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Identify the qualified name of current class (for logging purpose at large)
    #Quote: https://www.python.org/dev/peps/pep-3155/
    #[1] [__qualname__] attribute is valid for a [class] or [function], but invalid for an [object] instantiated from a [class]
    LClassName = __qualname__
    #We do not allow attributes to be added inside the instance
    __slots__ = ('stdout','logger','_buf')

    #002. Constructor
    def __init__(self, logger):
        self.stdout = sys.stdout
        self.logger = logger
        sys.stdout = self
        #[ASSUMPTION]
        #[1] We avoid to use single empty string to dodge from the Shlemiel the painter’s algorithm
        #[2] https://stackoverflow.com/questions/19425736/how-to-redirect-stdout-and-stderr-to-logger-in-python
        #[3] https://www.joelonsoftware.com/2001/12/11/back-to-basics/
        self._buf = []

    #100. Overwrite the <write> method by removing trailing carriage returns (only once per message)
    def write(self, record):
        if record.endswith('\n'):
            self._buf.append(record[:-1])
            self.logger.info(''.join(self._buf))
            self._buf = []
        else:
            self._buf.append(record)

    #200. Get the attributes which are not patched in this class
    #[ASSUMPTION]
    #[1] When running a <shiny> app, <sys.stdout.isatty()> is called to configure the default formatter, hence we bring it in
    #[2] https://stackoverflow.com/questions/858623/how-to-recognize-whether-a-script-is-running-on-a-tty
    #[3] <__getattr__> will only catch the non-existent attributes
    #[4] http://www.sefidian.com/2021/06/06/python-__getattr__-and-__getattribute__-magic-methods/
    def __getattr__(self, attr):
        return(getattr(self.stdout, attr))

    #900. Setup the method to avoid warning messages showing NO ATTRIBUTE of <flush>
    #[ASSUMPTION]
    #[1] <logging> has already flushed each message before emitting
    #[2] https://stackoverflow.com/questions/16633911/does-python-logging-flush-every-log
    def flush(self):
        pass

#End PrintToLog

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import customLog, PrintToLog, thisShell

    #100. Setup loggers
    #[IMPORTANT]
    #[1] These two loggers MUST be both invoked to enable the correct logging
    #[2] Sequence of below lines MUST be as is, to ensure correct position of <warnings.warn> messages
    #Only with this line can <warnings.warn> be logged into the console
    logger = customLog(__name__, False, mode = 'w', logWarnings = False)
    #Only with this line can <warnings.warn> be logged into the logfile
    logger = customLog('', True, mode = 'a', logWarnings = True)

    #200. Enable the logger to capture <print> results in both console and logfile
    #[ASSUMPTION]
    #[1] When the script is running in an interactive Python, the <stdout> may be locked due to <asyncio>
    #[2] That is why we only test the file logging in a CLI
    if thisShell() in ['CLI']:
        PrintToLog(logger)

    #300. Test the log function
    #Below message can now be captured into the logfile
    print('This will show in the logfile')

    #Original logger.info also works fine
    logger.info('This should be OK')

    #400. Test the warning message
    warn('Dedicated to display the warning message')

    #500. Test the exception
    raise RuntimeError('Dedicated to abort the session')

#-Notes- -End-
'''
