#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from collections.abc import Iterable
from typing import TypedDict, Required

class TxtConverterReqMsg(TypedDict, total = False):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class acts as the static parameter validator to ensure the input message for the various generators that convert Markdown text#
#   | to HTML text along the processing streams                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |800.   Class variables                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |src               :   <callable > Function as source to extract the signature and take place of the expanded holes in <dst>        #
#   |task              :   <str      > The requested task for current batch of process                                                  #
#   |                      [add      ] Add the <value> to the pool of internal tags                                                     #
#   |                      [finish   ] Stop the generation and thus return the generated HTML taglist. Sending this will ignore all     #
#   |                                   other items in the same batch of sending message, and close the generator.                      #
#   |value             :   <str      > The value to be included as the content of the HTML tag split by carriage return to indicate     #
#   |                                   multi-line input; should contain the leading signs for each line, i.e. numbers for <ol> tags    #
#   |                                   and <*>/<-> for <ul> tags                                                                       #
#   |                      [str      ] Will be split by <str.splitlines()>                                                              #
#   |                      [Iterable ] Iterable of character strings, each will be split by <str.splitlines()>                          #
#   |escape            :   <bool     > Whether to escape the input <value> to prevent HTML injection                                    #
#   |                      [True     ] Escape any input <value>                                                                         #
#   |                      [False    ] Keep the raw input                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20251224        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |collections, typing                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    task : Required[str]
    value : str | Iterable[str]
    escape : bool

#End TxtConverterReqMsg

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    import os
    from collections.abc import Iterable
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Styles import TxtConverterReqMsg

    #100. Demostration of the type linting
    #110. Send message to the generator for processing the <value>
    aa1 : TxtConverterReqMsg = {
        'task' : 'add'
        ,'value' : '- List Item 1'
        ,'escape' : False
    }

    #120. Indicate to shut down the generator
    aa2 : TxtConverterReqMsg = {
        'task' : 'finish'
    }

#-Notes- -End-
'''
