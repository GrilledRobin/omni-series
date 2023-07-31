#!/usr/bin/env python3
# -*- coding: utf-8 -*-

logger.info('step 1')

from warnings import warn

#300. Test the log function
#Below message can now be captured into the logfile
print('This will show in the logfile')

#Test carriage return
print('>>>Test carriage return for <print>')
print('\n')
print('<<<Test carriage return for <print>')

logger.info('>>>Test carriage return for <logger.info>')
logger.info('\n')
logger.info('<<<Test carriage return for <logger.info>')

#400. Test the warning message
warn('Dedicated to display the warning message')

#500. Test the exception
#Not Run
# raise RuntimeError('Dedicated to abort the session')
