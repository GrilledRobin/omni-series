#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
from inspect import cleandoc
from omniPy.AdvOp import modifyDict

def jsWinDateCat(
    funcName : str = 'winDateCat'
    ,mapper : dict[str, str] = {
        'unknown' : '未知'
        ,'today' : '今天'
        ,'yesterday' : '昨天'
        ,'earlierThisWeek' : '本周早些时候'
        ,'lastWeek' : '上周'
        ,'earlierThisMonth' : '这个月的早些时候'
        ,'lastMonth' : '上月'
        ,'earlierThisYear' : '今年的早些时候'
        ,'longTimeAgo' : '很久以前'
    }
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the web page, not necessarily `shiny` app or module, to register a  #
#   | function to categorize the provided date value in terms of the Windows Explorer fashion                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |FEATURE                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Language of output can be customized at runtime                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Arguments in the injected JS function]                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[dt              ] HTML date or datetime object for parsing                                                                        #
#   |[category        ] Set of date categories as mapper to translate the date value                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |funcName          :   <str > Customize the JS function name to distinguish the script execution                                    #
#   |                      [<see def.>          ] <Default> Use a universal function name to be in use for the whole web page           #
#   |                      [<str>               ]           Set different function names to distinguish the script execution            #
#   |mapper            :   <dict> Mapper to describe the date values in categories. This acts as the `default mapper` for the function  #
#   |                      when there is no `category` provided at runtime.                                                             #
#   |                      [<see def.>          ] <Default> Use the preset mapper matching `Windows OS` fashion                         #
#   |                      [<dict>              ]           Provide a `dict` for translation into `JS`                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   Character representation of JS snippet                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260721        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |re, inspect                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |modifyDict                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #050. Local parameters
    sp_reg = ' ' * 16
    mapper_preset = {
        'unknown' : '未知'
        ,'today' : '今天'
        ,'yesterday' : '昨天'
        ,'earlierThisWeek' : '本周早些时候'
        ,'lastWeek' : '上周'
        ,'earlierThisMonth' : '这个月的早些时候'
        ,'lastMonth' : '上月'
        ,'earlierThisYear' : '今年的早些时候'
        ,'longTimeAgo' : '很久以前'
    }
    if isinstance(mapper, dict):
        mapper_preset = modifyDict(mapper_preset, mapper)
    mapper_str = f'\n{sp_reg},'.join([
        (k + ': ' + (f'\'{v}\'' if isinstance(v, str) else str(v).lower()))
        for k,v in mapper_preset.items()
    ]).strip()

    #800. Setup the JS program
    js_snippet = cleandoc(f'''
        function {funcName}(dt, category = {{}}) {{
            const _cats = {{
                {mapper_str}
                ,...category
            }};

            // 100. Parse dates
            const now = new Date();
            const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            const target = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate());

            // 300. Calculate the difference of the target date to today
            const diffDays = Math.floor((today - target) / (1000 * 60 * 60 * 24));

            // 700. Switch the category in terms of the difference
            if (isNaN(diffDays)) return _cats.unknown;
            if (diffDays === 0) return _cats.today;
            if (diffDays === 1) return _cats.yesterday;
            const weekday = now.getDay() || 7;
            if (diffDays >= 2 && diffDays <= weekday - 1) return _cats.earlierThisWeek;
            if (diffDays <= weekday + 6) return _cats.lastWeek;
            if (target.getMonth() === now.getMonth() && target.getFullYear() === now.getFullYear()) {{
                return _cats.earlierThisMonth;
            }}
            if (
                (target.getMonth() === now.getMonth() - 1 || (now.getMonth() === 0 && target.getMonth() === 11))
                && target.getFullYear() === now.getFullYear()
            ) {{
                return _cats.lastMonth;
            }}
            if (target.getFullYear() === now.getFullYear()) {{
                return _cats.earlierThisYear;
            }}
            return _cats.longTimeAgo;
        }}
    ''')

    #900. Return the script
    return(re.sub(r'\n\s+\n', r'\n\n', js_snippet, flags = re.M))
#End jsWinDateCat

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp import jsWinDateCat
    print(jsWinDateCat.__doc__)

    #100. View the JS as a character string
    print(jsWinDateCat())

    #300. Test the functionality
    # see <ShinyApp.Modules.DataTablesExplorer> for sample usage

    #350. JS usage reference
    _ = """
        // 100. Define a date of 2026-07-21
        const mydate = new Date(2026, 6, 21);

        // 500. Print the category of it
        console.log(winDateCat(mydate));
    """

#-Notes- -End-
'''
