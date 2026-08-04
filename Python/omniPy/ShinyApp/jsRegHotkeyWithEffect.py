#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import textwrap
from inspect import cleandoc
from typing import Optional
from omniPy.AdvOp import modifyDict

def jsRegHotkeyWithEffect(
    selector : str
    ,register : Optional[str] = None
    ,unregister : Optional[str] = None
    ,funcName : str = 'regHotkeyWithEffect'
    ,addTooltip : bool = True
    ,instTooltipManager :str = 'tooltipManager'
    ,instHotkeyManager :str = 'hotkeyManager'
    ,elName : str = 'btn'
    ,runScript : str = 'btn.click();'
    ,classList : str | list[str] = ''
    ,returnFunc : Optional[str] = None
    ,options : dict = {
        'hotkeyManager' : {
            'ignoreEditable' : True
            ,'preventDefault' : True
            ,'stopPropagation' : True
            ,'ignoreRepeat' : True
            ,'debug' : False
            ,'description' : 'click'
        }
        ,'tooltipManager' : {
            'content' : ''
            ,'customClass' : ''
            ,'delay' : 180
            ,'maxWidth' : 320
            ,'placement' : 'auto'
        }
    }
) -> str | None:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the HTML App, not necessarily `shiny` app or module, to register a  #
#   | hotkey for the dedicated web element, preferrably a `button`, via the instance of a global hotkey manager as `instHotkeyManager`, #
#   | with certain interactive effects or anminations defined by a series of `CSS` classes                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] It requires a live instance of the global hotkey manager, see <ShinyApp.jsHotkeyManager> for its usage                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |selector          :   <str > Valid character string that represents a selector for method `querySelector` in HTML                  #
#   |register          :   <str > Valid character string as hotkey for registration, usually parsed by <ShinyApp.parseHotkey>           #
#   |                      [None                ] <Default> Not to register any hotkey. Be careful of the consequence of setting this   #
#   |                      [<str>               ]           Set a valid hotkey, e.g. `'ctrl+alt+f'` or `'ctrl+alt+numpad+'`             #
#   |unregister        :   <str > Valid character string as hotkey for removal of registration, usually parsed by <ShinyApp.parseHotkey>#
#   |                      [None                ] <Default> Unregister no hotkey                                                        #
#   |                      [<str>               ]           Set a valid hotkey, e.g. `'ctrl+alt+f'` or `'ctrl+alt+numpad+'`             #
#   |funcName          :   <str > Customize the JS function name to distinguish the script execution                                    #
#   |                      [<see def.>          ] <Default> Use a universal function name to be in use for the whole web page           #
#   |                      [<str>               ]           Set different function names to distinguish the script execution            #
#   |instTooltipManager:   <str > Name of the live instance of the global tooltip manager                                               #
#   |                      [<see def.>          ] <Default> Use a universal name that is defined for the whole App                      #
#   |                      [<str>               ]           Set different name if the global instance is defined in other way           #
#   |instHotkeyManager :   <str > Name of the live instance of the global hotkey manager                                                #
#   |                      [<see def.>          ] <Default> Use a universal name that is defined for the whole App                      #
#   |                      [<str>               ]           Set different name if the global instance is defined in other way           #
#   |elName            :   <str > The element name defined for internal usage of this function, which is used in `runScript` for element#
#   |                      manipulation                                                                                                 #
#   |                      [<see def.>          ] <Default> Example of the manipulation of a button as is indicated in `runScript`      #
#   |                      [<str>               ]           Use the specific name as indicated in `runScript`                           #
#   |runScript         :   <str > Valid `JS` statements in any length, preferrably with certain manipulation of `elName`                #
#   |                      [<see def.>          ] <Default> Example of the click of a button as named by `elName`                       #
#   |                      [<str>               ]           Any valid `JS` statements, can be expressed in multiple lines               #
#   |classList         :   <str > Valid `CSS` class or Python `list` of the previous, indicating the special effects to add to `elName` #
#   |                      when the hotkey event is triggered                                                                           #
#   |                      [<see def.>          ] <Default> No `CSS` class is to be added                                               #
#   |                      [<str>               ]           `CSS` class or Python list of strings that represent `CSS` classes          #
#   |returnFunc        :   <str > Valid `JS` function name to export to the session, with which one can unregister this hotkey directly #
#   |                      without calling `instHotkeyManager.unregister(el,hotkeyString)` elsewhere                                    #
#   |                      [None                ] <Default> No need for single manipulation                                             #
#   |                      [<str>               ]           Any valid `JS` function name                                                #
#   |options           :   <dict> Options accepted by `register` method of both instances of the hotkey manager and tooltip manager     #
#   |                      , to overwrite the universal configurations of the event listeners                                           #
#   |                      [<see def.>          ] <Default> See <ShinyApp.jsHotkeyManager> and <ShinyApp.jsTooltipManager> for valid    #
#   |                                                        options                                                                    #
#   |                      [<dict>              ]           Provide a `dict` for translation into `JS`                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   Character representation of JS snippet, or `None` if neither `register` nor `unregister` is specified        #
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
#   |re, textwrap, inspect, typing                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |modifyDict                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #050. Local parameters
    if isinstance(classList, str):
        classList = [classList]
    class_rem = ''
    class_add = ''
    sp_reg = ' ' * 20
    sp_tt = ' ' * 16
    js_unregister = ''
    js_register = ''
    js_tooltip = ''
    ret_str = ''
    assign_str = ''

    #100. Beautify the input statements
    scr_indented = textwrap.indent(runScript, sp_reg).lstrip()

    #200. Define options for customization
    #210. Options for hotkey manager
    opt_preset_hk = {
        'ignoreEditable' : True
        ,'preventDefault' : True
        ,'stopPropagation' : True
        ,'ignoreRepeat' : True
        ,'debug' : False
        ,'description' : ''
    }
    if isinstance(options, dict) and instHotkeyManager in options and isinstance(options[instHotkeyManager], dict):
        opt_preset_hk = modifyDict(opt_preset_hk, options[instHotkeyManager])
    opt_str_hk = f'\n{sp_reg},'.join([
        (k + ': ' + (f'\'{v}\'' if isinstance(v, str) else str(v).lower()))
        for k,v in opt_preset_hk.items()
    ]).strip()

    #230. Options for tooltip manager
    opt_preset_tt = {
        'content' : ''
        ,'customClass' : ''
        ,'delay' : 180
        ,'maxWidth' : 320
        ,'placement' : 'auto'
    }
    if isinstance(options, dict) and instTooltipManager in options and isinstance(options[instTooltipManager], dict):
        opt_preset_tt = modifyDict(opt_preset_tt, options[instTooltipManager])
        if register:
            opt_preset_tt['content'] = register
    opt_str_tt = f'\n{sp_tt},'.join([
        (k + ': ' + (f'\'{v}\'' if isinstance(v, str) else str(v).lower()))
        for k,v in opt_preset_tt.items()
    ]).strip()

    #300. Determine the classes
    if classList:
        class_list = ','.join([f'\'{s}\'' for s in classList])
        class_rem = f'{elName}.classList.remove({class_list});'
        class_redraw = f'void {elName}.offsetHeight; /* 触发重绘 */'
        class_add = f'{elName}.classList.add({class_list});'

    #500. Prepare the script to register/unregister the hotkey for the trigger button
    if unregister:
        js_unregister = (f'''
            {instHotkeyManager}.unregister(
                {elName},
                '{unregister}',
            );
        ''').strip()

    if register:
        js_register = (f'''
            // 注册快捷键 - 指向同一个处理函数
            const unregisterComp = {instHotkeyManager}.register(
                // component标识符
                {elName},
                '{register}',
                (event) => {{
                    {class_rem}
                    {scr_indented}
                    {class_redraw}
                    {class_add}
                }}, {{
                    {opt_str_hk}
                }}
            );
        ''').strip()

    #600. Prepare the script to add the hotkey string as tooltip for the trigger button
    if addTooltip:
        js_tooltip = (f'''
            {instTooltipManager}.register({elName}, {{
                {opt_str_tt}
            }});
        ''').strip()

    #700. Determine if a function of unregistering current hotkey should be captured in the front-end
    if returnFunc:
        ret_str = 'return unregisterComp;'
        assign_str = f'const {returnFunc} = '

    #800. Setup the JS program
    js_snippet = cleandoc(f'''
        function {funcName}() {{
            const {elName} = document.querySelector(`{selector}`);
            {js_unregister}
            {js_register}
            {js_tooltip}
            {ret_str}
        }}
        {assign_str}{funcName}();
    ''')

    #900. Return the script
    if (not unregister) and (not register):
        return(None)
    return(re.sub(r'\n\s+\n', r'\n\n', js_snippet, flags = re.M))
#End jsRegHotkeyWithEffect

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp import jsRegHotkeyWithEffect
    print(jsRegHotkeyWithEffect.__doc__)

    #100. View the JS as a character string
    print(jsRegHotkeyWithEffect(
        '#button'
        ,register = 'ctrl+numpad-'
        ,classList = ['key-triggered', 'clicked']
    ))

    #300. Test the functionality
    # see <ShinyApp.Modules.OSNativeFileSelector> for sample usage

#-Notes- -End-
'''
