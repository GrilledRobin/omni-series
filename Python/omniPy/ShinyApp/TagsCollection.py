#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from shiny import ui

class TagsCollection:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to collect a series of useful HTML tags for various Apps                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] `shiny.ui` creates the tags as text strings, so it is friendly to embed them directly into an HTML document                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[arrow]                                                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to create modern SVG arrows in all 4 directions                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |arr_dir__         :   <str     > The dedicated arrow in such direction, should be provided as positional parameter to avoid#
#   |   |   |                                  conflict against potential HTML attribute names, as they should be provided in the       #
#   |   |   |                                  fashion of keyword parameters                                                            #
#   |   |   |**kw              :   <various > Various HTML attributes to assign to the generated tag                                    #
#   |   |   |                      IMPORTANT: `shiny` will translate all underscores into hyphens, e.g. `data_id` -> `data-id`. See     #
#   |   |   |                                  details in `shiny` official documents                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<ui.tags>         :   HTML tag for the `shiny module` to process at runtime                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260710        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |shiny                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #200. Private methods
    #220. Method to enable slicing fashion during operation on APIs
    def __getitem__(self, attr):
        return(getattr(self, attr))

    #300. Arrows
    arrow_dir = {
        'up' : '18 15 12 9 6 15'
        ,'down' : '6 9 12 15 18 9'
        ,'right' : '9 6 18 12 9 18'
        ,'left' : '15 6 6 12 15 18'
    }
    arrow_config = {
        'viewBox' : '0 0 24 24'
        ,'fill' : 'none'
        ,'stroke' : 'currentColor'
        ,'stroke_width' : '2.5'
        ,'stroke_linecap' : 'round'
        ,'stroke_linejoin' : 'round'
    }

    def arrow(self, arr_dir__ : str, /, **kw):
        if not isinstance(arr_dir__, str) or arr_dir__ not in self.arrow_dir:
            raise ValueError(f'[{self.__class__.__name__}]<arr_dir__> should be one of these: {set(self.arrow_dir.keys())}')

        arr_dir = self.arrow_dir.get(arr_dir__.lower())
        return(ui.tags.svg(
            ui.HTML(f'<polyline points="{arr_dir}"></polyline>')
            ,**self.arrow_config
            ,**kw
        ))

#End TagsCollection

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import os, re
    import shutil
    import sys
    from inspect import cleandoc
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.ShinyApp import TagsCollection

    tc = TagsCollection()

    #100. Create an arrow with direction as 'up'
    arr_up = tc.arrow('up')
    print(arr_up)
    _ = """
        <svg
            viewBox='0 0 24 24'
            fill='none'
            stroke='currentColor'
            stroke-width='2.5'
            stroke-linecap='round'
            stroke-linejoin='round'
        >
            <polyline points='18 15 12 9 6 15'></polyline>
        </svg>
    """

    #300. Create an arrow with direction as 'right' and a certain style
    arr_right = tc.arrow('right', style = 'width: 12px; height: 12px;')
    print(arr_right)
    _ = """
        <svg
            viewBox='0 0 24 24'
            fill='none'
            stroke='currentColor'
            stroke-width='2.5'
            stroke-linecap='round'
            stroke-linejoin='round'
            style='width: 12px; height: 12px;'
        >
            <polyline points='9 6 18 12 9 18'></polyline>
        </svg>
    """

#-Notes- -End-
'''
