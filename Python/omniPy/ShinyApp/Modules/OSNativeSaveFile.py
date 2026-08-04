#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, re
import datetime as dt
from typing import Optional
from inspect import cleandoc
from shiny import Inputs, Outputs, Session, module, reactive, ui, render
from PySide6.QtWidgets import QApplication, QFileDialog, QWidget
from PySide6.QtCore import Qt
from omniPy.AdvOp import modifyDict
from omniPy.Styles import OSThemesCSS, CSSKeyframes
from omniPy.ShinyApp import jsHotkeyManager, jsNotificationMod, parseHotkey, jsRegHotkeyWithEffect, jsTooltipManager

class OSNativeSaveFile:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to create a `shiny module` for interactively exporting files from any object in current session to the      #
#   | harddrives in terms of the native dialog provided by current OS, and then obtain the absolute path of the exported file for next  #
#   | steps if any                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[UI Components]                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] <Action Button> result a popup window when clicked                                                                             #
#   |    [1] <OS Native Save File Name> introduced by `PySide6`, for user to save an object to a file on harddrives in the way current  #
#   |        OS allows                                                                                                                  #
#   |[2] <Notification> indicating successful saving of the file when available                                                         #
#   |[3] <Notification> indicating cancellation of the file saving when available                                                       #
#   |[4] <Notification> indicating failure of the file saving when encountered                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__init__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate the component by defining hyper-parameters. Please try NOT change them during   #
#   |   |   |   | the instantiation to avoid seemingly duplicated DOM tree in the App                                                   #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] One can create instances with different hyper-parameters, but it is highly not recommended                         #
#   |   |   |   |    [1] These parameters have no effect on instance segregation, which is done by the class itself                     #
#   |   |   |   |    [2] Rather, they have negative side effects by injecting unnecessary JS scripts that are redundent for front-end   #
#   |   |   |   |        listening, although the excessive events will never be triggered                                               #
#   |   |   |   |[2] The only reason to expose these hyper-parameters is to allow the developers to understand the flow direction of the#
#   |   |   |   |    internal message transfer of `shiny`. i.e. they are utilized in both `ui` and `server` to commit transmition.      #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |CONVENTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] Begin with `id` - HTML ID that is NOT scoped, in order to make it work, follow below convention                    #
#   |   |   |   |    [1] Wrap it with <ShinyApp.Modules.ns> in `ui` part, and it will be parsed in static mode in the App               #
#   |   |   |   |    [2] Wrap it with <session.ns> in `server` part to be parsed at runtime                                             #
#   |   |   |   |[2] Begin with `io` - Name of the JS messages passed between `ui` and `server`, literally used at the background       #
#   |   |   |   |    [1] Wrap it with <ShinyApp.Modules.ns> in `ui` part, or with <session.ns> in `server`, similar to `id`, when the   #
#   |   |   |   |        message is only used for current instance                                                                      #
#   |   |   |   |    [2] Directly use it when the message is designed to be globally listened and handled                               #
#   |   |   |   |[2] Begin with `ns` - Tag attribute that is NOT scoped, similar to HTML ID, but set as attribute of a `ui.Tag`         #
#   |   |   |   |    [1] Wrap it with <ShinyApp.Modules.ns> in `ui` part, and it will be parsed in static mode in the App               #
#   |   |   |   |    [2] Wrap it with <session.ns> in `server` part to be parsed at runtime                                             #
#   |   |   |   |[3] Begin with `name` - The universal name of internal variable, used in at least two among `ui`, `server` and         #
#   |   |   |   |    `_initModule_`, indicating that it is implemented in different parts of the module                                 #
#   |   |   |   |[4] `options` - Stores the universal argument default values of external functions. Useful for chaining the modules    #
#   |   |   |   |    when they depend on the same external functions                                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |idTriggerBtn      :   <str      > HTML ID of the trigger button in this module                                             #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in `ui` and `server`                            #
#   |   |   |                      [<str>               ]          Use other ID to distinguish the modules (which is unnecessary)       #
#   |   |   |idOSTheme         :   <str      > HTML ID of the injected CSS holding the OS theme. It will be removed imperatively at the #
#   |   |   |                       construction of the JS class, and added back to DOM afterwards, to ensure higher priority to that of#
#   |   |   |                       the embedded styles in the JS class. So be sure to set its HTML ID unique within the whole App      #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in the App                                      #
#   |   |   |                      [<str>               ]          Use other HTML ID to distinguish the modules (which is unnecessary)  #
#   |   |   |nameGlobalTheme   :   <str     > Name of the theme defined in <Styles.OSThemesCSS> to manage the global styles of the App  #
#   |   |   |                      [<see def.>          ]<Default> Use a universal style defined in <Styles.OSThemesCSS>                #
#   |   |   |                      [<str>               ]          Any valid theme defined in <Styles.OSThemesCSS>                      #
#   |   |   |nameTooltipManager:   <str      > Name of the dependent component Tooltip Manager, should be a valid `JS Object Name`      #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |instTooltipManager:   <str      > Name of the instance of Tooltip Manager, should be a valid `JS Object Name`              #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameHotkeyManager :   <str      > Name of the global hotkey manager as `JS` class                                          #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined class name                                       #
#   |   |   |                      [<str>               ]          Use other names to distinguish the modules (which is unnecessary)    #
#   |   |   |enableHotkey      :   <bool     > Whether to recognize the keys enclosed by the `enclosers` at the end part of `label` as  #
#   |   |   |                       the keyboard hotkey, to resemble the `click` event                                                  #
#   |   |   |                      [True                ]<Default> Allow keyboard hotkey for the action                                 #
#   |   |   |                      [False               ]          Only allow mouse click                                               #
#   |   |   |enclosers         :   <dict     > Mapping of enclosers with <key> as the left bound or opener, <value> as the right bound  #
#   |   |   |                        or closer. There can be several pairs of enclosers, while only the content wrapped inside the last #
#   |   |   |                        part of `label` by any among the enclosers will be recognized as hotkey                            #
#   |   |   |                      [<see def.>          ]<Default> Identify the hotkey part using the pre-defined enclosers             #
#   |   |   |                      [<dict>              ]          Provide dedicated pair or pairs of enclosers for recognition         #
#   |   |   |hideHotkey        :   <bool     > Whether to hide the recognized hotkey from `label` at the display. This is useful when   #
#   |   |   |                       the webpage is crowded and the hotkey indication can be elaborated in the user manual               #
#   |   |   |                      [False               ]<Default> Show `label` as it is                                                #
#   |   |   |                      [True                ]          Truncate the recognized hotkey from `label` at display               #
#   |   |   |options           :   <dict     > Dict of all the rest arguments to all the dependent facilities                           #
#   |   |   |                      [<see def.>          ]<Default> Empty input to maintain the flexibility                              #
#   |   |   |                      [<dict>              ]          Dict with `key` as the dependent function names, and `values` as the #
#   |   |   |                                                       dict of keyword arguments that can be passed during the call to the #
#   |   |   |                                                       dependent function                                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   Only for initialization                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[ui]                                                                                                                           #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to register the `ui` part of the `shiny module`                                                #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] It is designed to extend the `click` event by allowing keyboard shortcut                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |id                :   <str     > ID of the created module. This is resulted from the extension by <module.ui>              #
#   |   |   |*pos              :   <tuple   > Any positional arguments for <ui.input_action_button> as there is only one to manipulate  #
#   |   |   |class_            :   <str     > The CSS `class` to set the style of the button                                            #
#   |   |   |                      [<see def.>          ]<Default> Use a universal style defined in <Styles.OSThemesCSS>                #
#   |   |   |                      [<str>               ]          Any valid CSS `class` that has an external definition, or passed as  #
#   |   |   |                                                       separate `style=` argument to this function                         #
#   |   |   |**kw              :   <dict    > Any keyword arguments for <ui.input_action_button> as there is only one to manipulate     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<ui.tags>         :   HTML tag for the `shiny module` to process at runtime                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[server]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to register the `server` part of the `shiny module`                                            #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] `input`, `output` and `session` are defined but hidden at runtime, so they are not passed as parameters during the #
#   |   |   |   |     call of the server. See examples for detailed usage                                                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |id                :   <str     > ID of the created module. This is resulted from the extension by <module.server>          #
#   |   |   |obj_reactive      :   <react   > Reactive value in `shiny` which could yield any possible type of object for exporting at  #
#   |   |   |                       runtime                                                                                             #
#   |   |   |label             :   <str     > Label to show on the action button                                                        #
#   |   |   |                      IMPORTANT: Indicative shortcut in it is removed when <hideHotkey=True>                               #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined label on the button, avoid conflict with the    #
#   |   |   |                                                       keyboard hotkeys of the web browser                                 #
#   |   |   |                      [<str>               ]          Show customizezd label on the button                                 #
#   |   |   |fileTypes         :   <dict    > Dict that indicates the types to restrict when saving the file                            #
#   |   |   |                      [None                ]<Default> Allow to save all types of files                                     #
#   |   |   |                      [dict                ]          Provide valid dict, see the examples                                 #
#   |   |   |fileTypesSaver    :   <dict    > dict of callables by key that indicates the API to export the dataframe by different types#
#   |   |   |                      [None                ]<Default> System will raise exception during the export                        #
#   |   |   |                      [dict                ]          Provide valid dict of <callable>s, see the examples                  #
#   |   |   |                                                      IMPORTANT: Any <callable> provided should take exactly 2 arguments,  #
#   |   |   |                                                                  which are NOT <KEYWORD_ONLY>, in the syntax <(in,out)>   #
#   |   |   |                                                                  indicating input object and output path                  #
#   |   |   |initPath          :   <str     > The starting path for at the initialization of the file selector                          #
#   |   |   |                      [None                ]<Default> Navigate to <This Computer> directory                                #
#   |   |   |                      [str                 ]          Navigate to the existing path, or <This Computer> given it is not    #
#   |   |   |defaultName       :   <str     > Default file name to save when the dialog shows, to save the input effort when necessary  #
#   |   |   |                      [None                ]<Default> Use the formatted value of current time as the file name             #
#   |   |   |                      [<str>               ]          Specify a default name for your App                                  #
#   |   |   |allowAcceptAll    :   <bool    > Whether to show an option `All Files (*)` in the filtration dropbox                       #
#   |   |   |                      [True                ]<Default> Show an option to allow select all types of files                    #
#   |   |   |                      [False               ]          Prevent the selection of all types of files                          #
#   |   |   |txtAcceptAll      :   <str     > The text showing in the dropbox, representing `All Files (*)`                             #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined text for selecting among all types of files     #
#   |   |   |                      [<str>               ]          Show customized text for selecting among all types of files          #
#   |   |   |dialogTitle       :   <str     > Title of the popup dialog as file selector                                                #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined title in the dialog                             #
#   |   |   |                      [<str>               ]          Show customized title in the dialog                                  #
#   |   |   |msgCancel         :   <str     > Message to show in the notification zone when user click `cancel` in the dialog           #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined message in the notification                     #
#   |   |   |                      [<str>               ]          Show customized message in the notification                          #
#   |   |   |durCancel         :   <num     > Duration in seconds of the `Cancel` message before it closes automatically                #
#   |   |   |                      [<see def.>          ]<Default> Set the pre-defined duration                                         #
#   |   |   |                      [<float> or <int>    ]          Set the customized duration                                          #
#   |   |   |msgSuccess        :   <str     > Message to show in the notification zone when the export is successful                    #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined message in the notification                     #
#   |   |   |                      [<str>               ]          Show customized message in the notification                          #
#   |   |   |durSuccess        :   <num     > Duration in seconds of the `Success` message before it closes automatically               #
#   |   |   |                      [<see def.>          ]<Default> Set the pre-defined duration                                         #
#   |   |   |                      [<float> or <int>    ]          Set the customized duration                                          #
#   |   |   |msgFail           :   <str     > Message to show in the notification zone when export fails. This will NOT close until user#
#   |   |   |                       click the `close` button in the notification card                                                   #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined message in the notification                     #
#   |   |   |                      [<str>               ]          Show customized message in the notification                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<str>             :   The absolute path of the file as exported                                                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_register_]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to register the `headContent` of all dependent modules, as well as that of this module itself, #
#   |   |   |   | to a collection of `HTML` tags, so that they can be injected into the `head` of the final `shiny` App in one batch    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |tags              :   <list     > The list of `ui.Tag` indicating the dedicated `headContent` of the dependent module      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This function only conduct collection of `HTML` tags                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_initModule_]                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to prepare the `headContent` of this module, with the `JS`/`CSS` scripts defined for global    #
#   |   |   |   | usage in the App. It also set some local attributes of the instance for use in other methods.                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This function does not take argument, but uses the local attributes or methods                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   List of `ui.Tag` for collection purpose                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[headContent]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This property is to retrieve the collection of `headContent` along the call tree of modules                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not take external argument input                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   Full collection of `headContent` along the call tree of modules till current one                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260623        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |os, typing, shiny, PySide6, datetime                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |modifyDict                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Styles                                                                                                                         #
#   |   |   |OSThemesCSS                                                                                                                #
#   |   |   |CSSKeyframes                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |ShinyApp                                                                                                                       #
#   |   |   |jsHotkeyManager                                                                                                            #
#   |   |   |jsNotificationMod                                                                                                          #
#   |   |   |parseHotkey                                                                                                                #
#   |   |   |jsRegHotkeyWithEffect                                                                                                      #
#   |   |   |jsTooltipManager                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #002. Constructor
    def __init__(
        self
        ,idTriggerBtn : str = 'btn_file_save'
        ,idOSTheme : str = 'os-theme-preset'
        ,nameGlobalTheme : str = 'Windows'
        ,nameTooltipManager : str = 'window.TooltipManager'
        ,instTooltipManager : str = 'tooltipManager'
        ,nameHotkeyManager : str = 'HotkeyManager'
        ,nameHotkeyReg : str = 'jsRegHotkeyWithEffect'
        ,enableHotkey : bool = True
        ,enclosers : dict[str, str] = {'(' : ')'}
        ,hideHotkey : bool = False
        ,options : dict = {}
    ):
        #100. Prepare hyper-parameters
        self.idTriggerBtn = idTriggerBtn
        self.idOSTheme = idOSTheme
        self.nameGlobalTheme = nameGlobalTheme
        self.nameTooltipManager = nameTooltipManager
        self.instTooltipManager = instTooltipManager
        self.nameHotkeyManager = nameHotkeyManager
        self.nameHotkeyReg = nameHotkeyReg
        self.enableHotkey = enableHotkey
        self.enclosers = enclosers
        self.hideHotkey = hideHotkey
        self.options = options
        self._reg = []

        #200. Define options for external componentts
        #210. Options for <HotkeyManager>
        opt_hm = {
            'instHotkeyManager' : 'hotkeyManager'
            ,'ignoreEditable' : True
            ,'preventDefault' : True
            ,'stopPropagation' : True
            ,'ignoreRepeat' : True
            ,'debug' : False
        }
        if isinstance(curropt := self.options.get(self.nameHotkeyManager, None), dict):
            opt_upd = {
                self.nameHotkeyManager : modifyDict(opt_hm, curropt)
            }
            self.options = modifyDict(self.options, opt_upd)
        else:
            self.options = modifyDict(
                self.options
                ,{
                    self.nameHotkeyManager : opt_hm
                }
            )

        #220. Options for hotkey registration function
        opt_hkr = {
            self.options[self.nameHotkeyManager]['instHotkeyManager'] : {
                #[ASSUMPTION]
                #[1] Unlike the above static options for <HotkeyManager>, these options represent the tweak at runtime,
                #    i.e. only for this module instance
                'ignoreEditable' : True
                ,'preventDefault' : True
                ,'stopPropagation' : True
                ,'ignoreRepeat' : True
                ,'debug' : False
                ,'description' : 'click'
            }
            ,self.instTooltipManager : {
                'content' : ''
                ,'customClass' : ''
                ,'delay' : 180
                ,'maxWidth' : 320
                ,'placement' : 'auto'
            }
        }
        if hideHotkey:
            opt_hkr[self.instTooltipManager]['customClass'] = 'currOS-tooltip'
        if isinstance(curropt := self.options.get(self.nameHotkeyReg, None), dict):
            opt_upd = {
                self.nameHotkeyReg : modifyDict(opt_hkr, curropt)
            }
            self.options = modifyDict(self.options, opt_upd)
        else:
            self.options = modifyDict(
                self.options
                ,{
                    self.nameHotkeyReg : opt_hkr
                }
            )

        #900. Register the `head` content along the call tree
        #[ASSUMPTION]
        #[1] One should register the `headContent` of all dependent modules here
        #[2] The `initModuleTags` of this module should always be registered at first to ensure its priority till this node
        #[3] In this design pattern, only the `headContent` of the modules that are called at top level, i.e. in the final App,
        #    will have to be injected to the beginning of the App, to be recognized at `shiny:connected` and executed inside the
        #    global environment
        initModuleTags = self._initModule_()
        self._register_(initModuleTags)

    #200. Private methods
    #220. Method to enable slicing fashion during operation on APIs
    def __getitem__(self, attr):
        return(getattr(self, attr))

    #400. Helper methods
    #401. Function to register the tags to append to `head` as static JS or CSS snippets
    #[ASSUMPTION]
    #[1] We always have to inject the `head` scripts of current module for the last, to ensure its priority
    #[2] That is why we cannot use `list.extend`
    def _register_(self, tags : list[ui.Tag]):
        self._reg = [t for t in tags if t is not None] + [t for t in self._reg if t not in tags]

    #405. Function to return the tags to append to `head` as static JS or CSS snippets
    @property
    def headContent(self):
        return(self._reg)

    #700. UI part
    #710. Initialization part
    #[ASSUMPTION]
    #[1] `shiny:connected` event is only triggered once upon the system boot
    #[2] So when there is a chain of nested modules, all the scripts based on `shiny:connected` in the lower-level modules
    #    will NOT be executed at the front-end (HTML protection)
    #[3] That is why we need to register all the JS scripts in the main App (i.e. top caller) rather than in the modules
    def _initModule_(self):
        #100. 启动时注入OS主题样式预设
        #[ASSUMPTION]
        #[1] 对于 no OS theme 的场景，以下调整脚本不需要注入，因此可能为 None
        #[2] 由于 package 中其他 modules 可能含 JS Class Construction，这里注入 OS theme 时须给定完全一样的 HTML ID ，从而允许它们先找到
        #    已注入的样式并删除，再覆盖注入。否则会因过早注入而使其优先级低于 JS Class 中封装的自定义样式
        vld_theme = self.nameGlobalTheme in OSThemesCSS.presets
        os_theme = (
            ui.head_content(ui.tags.style(getattr(OSThemesCSS, self.nameGlobalTheme), id = self.idOSTheme))
            if vld_theme
            else None
        )

        #110. Load animations
        anim = CSSKeyframes()
        anim.load('btnClickPulse')
        css_anim = ui.head_content(ui.tags.style(anim.gather))

        #200. 启动时注册快捷键管理器
        #[ASSUMPTION]
        #[1] 由于没有外部依赖，该管理器每次注入均完全一样，因此会由 `ui.head_content` 进行哈希去重
        #[2] 同样，创建管理器实例时，脚本也会被去重，从而避免多实例
        hotkeyManager = ui.head_content(ui.tags.script(jsHotkeyManager(self.nameHotkeyManager)))

        js_hotkeyMgr = cleandoc(f'''
            // 创建{self.nameHotkeyManager}实例
            const {self.options[self.nameHotkeyManager]['instHotkeyManager']} = new {self.nameHotkeyManager}({{
                ignoreEditable: {str(self.options.get('ignoreEditable', 'true')).lower()}, // 默认在输入框中跳过
                preventDefault: {str(self.options.get('preventDefault', 'true')).lower()},
                stopPropagation: {str(self.options.get('stopPropagation', 'true')).lower()},
                debug: {str(self.options.get('debug', 'false')).lower()}, // 可设为true查看调试日志
            }});

            // ==================== 页面卸载时清理 ====================
            window.addEventListener('beforeunload', () => {{
                {self.options[self.nameHotkeyManager]['instHotkeyManager']}.destroy();
            }});
        ''')

        #300. 启动时注册提示浮窗 tooltip 管理器
        #[ASSUMPTION]
        #[1] 由于没有外部依赖，该管理器每次注入均完全一样，因此会由 `ui.head_content` 进行哈希去重
        #[2] 管理器为静态单例模式，因此无需实例化
        ttMgr_cssHead = 'ttm-'
        ttMgr = jsTooltipManager(
            funcName = self.nameTooltipManager
            ,cssHead = ttMgr_cssHead
        )
        tooltipManager = ui.head_content(ui.tags.script(ttMgr))

        #310. 专属CSS
        css_ttm = cleandoc(f'''
            .currOS-tooltip .{ttMgr_cssHead}arrow-inner {{
              background: linear-gradient(45deg, var(--bg-surface), var(--tooltip-bg-grad));
            }}

            /* 深色模式下的边框调整 */
            @media (prefers-color-scheme: dark) {{
              .currOS-tooltip .{ttMgr_cssHead}arrow-inner {{
                background: linear-gradient(45deg, rgba(44, 44, 44, 0.85), var(--tooltip-bg-grad));
                border-color: var(--tooltip-border);
              }}
            }}
        ''')

        js_ttMgr = cleandoc(f'''
            // 模拟创建{self.nameTooltipManager}实例
            {self.instTooltipManager} = {self.nameTooltipManager};

            // 先创建一个隐藏元素并为其创建 tooltip，从而触发 TTM 的 CSS 注入，这样确保后续样式覆盖能正常进行
            /**
                [ASSUMPTION]
                [1] TTM 是静态类，没有 constructor，因此仅在注册第一个 tooltip 时会注入内部封装的 CSS
            */
            let pseudoEL = document.createElement('div');
            pseudoEL.style.visibility = 'hidden';
            try {{
                {self.instTooltipManager}.register(pseudoEL, {{ content: 'Pseudo' }});
            }} catch (err) {{
            }}
            {self.instTooltipManager}.unregister();
            document.addEventListener('DOMContentLoaded', function() {{
                document.body.appendChild(pseudoEL);
                if (pseudoEL && pseudoEL.parentNode) {{
                    pseudoEL.parentNode.removeChild(pseudoEL);
                }}
                pseudoEL = null;
            }});

            // ==================== 页面卸载时清理 ====================
            window.addEventListener('beforeunload', () => {{
                {self.instTooltipManager}.dispose();
            }});
        ''')

        #999. Render UI
        init_tags_final = [
            #000. 注入全局唯一的各种脚本（须全部都唯一才能在这里统一注入）
            #[ASSUMPTION]
            #[1] 注入顺序至关重要，请参阅 HTML 中脚本执行和样式应用的优先级文档
            #400. 全局快捷键管理器
            #410. 依赖项为全局 tooltip 管理器
            tooltipManager
            ,ui.head_content(
                ui.tags.script(js_ttMgr)
            )
            ,ui.head_content(
                ui.tags.style(css_ttm)
            )
            ,hotkeyManager
            ,ui.head_content(ui.tags.script(js_hotkeyMgr))
            #900. 组件样式
            #[ASSUMPTION]
            #[1] 将需要设置最高优先级的样式放在最后注入
            ,css_anim
            ,os_theme
        ]

        return(init_tags_final)

    #400. UI part
    @property
    def ui(self):
        @module.ui
        def wrapper(
            *pos
            ,class_ : str = 'currOS-btn'
            ,**kw
        ):
            #050. Local parameters

            #800. Collect web elements
            #805. Set the style of the virtual container
            e_style = 'margin: 0;padding: 0;'

            #810. Button
            e_button = ui.input_action_button(
                self.idTriggerBtn
                ,ui.output_ui('tiggerBtn_label')
                ,*pos
                ,class_ = class_
                ,**kw
            )

            #890. Combine the UI
            e_ui = ui.tags.div(
                e_button
                ,style = e_style
            )

            return(e_ui)

        return(wrapper)

    #500. Server part
    @property
    def server(self):
        @module.server
        def wrapper(
            input : Inputs
            ,output : Outputs
            ,session : Session
            ,obj_reactive : reactive.Value
            ,label : str = 'Save (Alt+S)'
            ,fileTypes : dict[str, list[str]] = None
            ,fileTypesSaver : dict[str, callable] = None
            ,initPath : Optional[str] = None
            ,defaultName : Optional[str] = None
            ,allowAcceptAll : bool = False
            ,txtAcceptAll : str = '所有文件 (*)'
            ,dialogTitle : str = '保存文件'
            ,msgCancel : str = '已取消操作！'
            ,durCancel : Optional[int | float] = 2
            ,msgSuccess : str = '保存成功！'
            ,durSuccess : Optional[int | float] = 2
            ,msgFail : str = '保存失败！'
        ):
            #050. Local parameters
            idTriggerBtn = session.ns(self.idTriggerBtn)
            display_label = reactive.value(None)
            hotkey = reactive.value(None)
            hotkey_registered = None
            #[ASSUMPTION]
            #[1] As of <shiny==1.6.3>, `notifier_ns` is a constant as below
            notifier_ns = 'shiny-notification-'
            notifier_id = 'shinynotify_file_save'
            saved_path = reactive.value('')
            if defaultName is None:
                defaultName = dt.datetime.now().strftime('%Y%m%d%H%M%S')
            if not fileTypesSaver:
                raise ValueError('No Export function registered!')

            #[ASSUMPTION]
            #[1] Support for hotkey of trigger button
            @reactive.effect
            def _prep_label():
                lcl_label = label()
                display_label.set(lcl_label)
                if self.enableHotkey:
                    display, tmphotkey = parseHotkey(lcl_label, enclosers = self.enclosers)
                    if tmphotkey is not None:
                        hotkey.set(tmphotkey)
                    if self.hideHotkey:
                        display_label.set(display)

            #400. Render dynamic `ui`
            #420. Render label of trigger button at runtime
            @output
            @render.ui
            def tiggerBtn_label():
                nonlocal hotkey_registered
                lcl_label = display_label()
                lcl_hotkey = hotkey()
                lcl_hotkey_registered = hotkey_registered

                #300. Prepare the script to register/unregister the hotkey for the trigger button
                js_snippet = jsRegHotkeyWithEffect(
                    selector = '#' + idTriggerBtn
                    ,register = lcl_hotkey
                    ,unregister = lcl_hotkey_registered
                    ,funcName = 'regHotkey_' + re.sub(r'\W', '_', idTriggerBtn)
                    ,addTooltip = self.hideHotkey
                    ,instHotkeyManager = self.options[self.nameHotkeyManager]['instHotkeyManager']
                    ,elName = 'btn'
                    ,runScript = 'btn.click();'
                    ,classList = ['key-triggered', 'clicked']
                    ,returnFunc = None
                    ,options = self.options[self.nameHotkeyReg]
                )

                #399. Update the registered hotkey
                hotkey_registered = lcl_hotkey

                return(ui.div(
                    lcl_label
                    ,ui.tags.script(js_snippet)
                ))

            #700. ----- 动态禁用/启用按钮 -----
            @reactive.effect
            def _update_button_state():
                obj = obj_reactive()
                if obj is None:
                    ui.update_action_button(self.idTriggerBtn, disabled=True)
                else:
                    ui.update_action_button(self.idTriggerBtn, disabled=False)

            #800. Observe the `click` event of the button in UI
            #[ASSUMPTION]
            #[1] 经测试，此处必须是同步函数，不能为 async ，否则会阻塞 shiny 进程导致无法弹出窗口
            @reactive.effect
            @reactive.event(input[self.idTriggerBtn])
            def _save_dialog():
                #100. 确保 QApplication 存在，必须在主线程中、模块加载时创建，且在整个应用生命周期内保持
                app = QApplication.instance()
                if app is None:
                    app = QApplication([])

                #200. Local parameters
                #210. Load the dataframe
                obj = obj_reactive()
                if obj is None:
                    saved_path.set('')
                    return

                #220. 构建文件过滤字符串
                filter_texts = {}
                filter_parts = []
                if fileTypes:
                    filter_texts = {
                        desc : ('(' + ' '.join(f'*.{e}' for e in exts) + ')')
                        for desc, exts in fileTypes.items()
                    }
                    filter_parts = [ f'{k} {v}' for k,v in filter_texts.items() ]
                if allowAcceptAll or not filter_parts:
                    filter_parts.append(txtAcceptAll)
                filter_str = ';;'.join(filter_parts)

                #250. 设置起始目录和文件名
                start_dir = initPath if initPath else os.path.expanduser('~')
                default_path = os.path.join(start_dir, defaultName)

                #400. 创建临时置顶窗口作为父窗口，确保对话框前置
                top_widget = QWidget()
                top_widget.setWindowFlags(Qt.WindowStaysOnTopHint)
                top_widget.show()
                top_widget.hide()

                #500. 打开原生保存对话框（同步阻塞，但稳定可靠）
                #[ASSUMPTION]
                #[1] Arguments are: (父窗口, 标题, 默认路径+文件名, 过滤器)
                file_path, selected_filter = QFileDialog.getSaveFileName(
                    top_widget
                    ,dialogTitle
                    ,default_path
                    ,filter_str
                )

                #700. 销毁临时窗口
                top_widget.close()
                top_widget.deleteLater()

                #790. 用户取消
                if not file_path:
                    saved_path.set('')
                    ui.notification_show(
                        ui.tags.div(
                            ui.tags.div(
                                msgCancel
                                ,class_ = 'currOS-notification-body'
                            )
                            ,ui.tags.script(jsNotificationMod(f'{notifier_ns}{notifier_id}', notifier_ns = notifier_ns))
                        )
                        ,duration = durCancel
                        ,close_button = True
                        ,id = notifier_id
                    )
                    return

                #900. 判断导出格式（根据过滤器或文件后缀）
                if selected_filter != txtAcceptAll:
                    selected_type = {f'{k} {v}':k for k,v in filter_texts.items()}.get(selected_filter)
                    selected_saver = fileTypesSaver.get(selected_type)
                else:
                    selected_type = os.path.splitext(file_path)[-1][1:].upper()
                    if selected_type not in {k.upper() for k in fileTypesSaver.keys()}:
                        raise ValueError(f'No Export function registered for file type: <{selected_type}>!')
                    selected_saver = {k.upper() : v for k,v in fileTypesSaver.items()}.get(selected_type)

                if not callable(selected_saver):
                    raise ValueError(f'Export function for file type: <{selected_type}> is not callable!')

                try:
                    _ = selected_saver(obj, file_path)
                except Exception as e:
                    print(f'Failure on exporting: {e}')
                    # 失败弹窗，需手动点击按钮关闭
                    ui.notification_show(
                        ui.tags.div(
                            ui.tags.div(
                                msgFail
                                ,class_ = 'currOS-notification-body'
                            )
                            ,ui.tags.script(jsNotificationMod(f'{notifier_ns}{notifier_id}', notifier_ns = notifier_ns))
                        )
                        ,duration = None
                        ,close_button = True
                        ,id = notifier_id
                    )
                    saved_path.set('')
                    return

                saved_path.set(file_path)
                ui.notification_show(
                    ui.tags.div(
                        ui.tags.div(
                            msgSuccess
                            ,class_ = 'currOS-notification-body'
                        )
                        ,ui.tags.script(jsNotificationMod(f'{notifier_ns}{notifier_id}', notifier_ns = notifier_ns))
                    )
                    ,duration = durSuccess
                    ,close_button = True
                    ,id = notifier_id
                )

            return(saved_path)

        return(wrapper)

#End OSNativeSaveFile

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

    #300. Test the functionality
    #301. Locate the dedicated App
    dst_dir = r'D:\Temp\test_app'
    dst_app = os.path.join(dst_dir, 'app.py')
    dst_bat = os.path.join(dst_dir, 'run_app.bat')

    if not os.path.isdir(dst_dir): os.makedirs(dst_dir)

    #320. Prepare the caller BAT
    bat_snippet = cleandoc(rf"""
        @echo off
        @set "CurDir=%~dp0"
        @if "%CurDir:~-1%"=="\" @set "CurDir=%CurDir:~0,-1%"
        @call "{os.path.join(dir_omniPy, 'loc_omniPy_VENV.bat')}"
        @call "%BAT_VENV%"
        shiny run --reload --launch-browser "%CurDir%\app.py"
        exit /b %ErrorLevel%
    """)

    #330. Dump the script into the caller file
    with open(dst_bat, 'w', encoding = 'utf-8') as f:
        f.write(bat_snippet)

    #370. Prepare the full test program
    enclosers_to_escape = "{'(' : ')'}"
    multi_quotes = '"""'
    newline = '\\n'
    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import os
        import sys
        import pandas as pd
        import numpy as np
        from inspect import cleandoc
        from shiny import App, ui, reactive, render
        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )
        from omniPy.ShinyApp.Modules import OSNativeSaveFile

        ossf = OSNativeSaveFile(
            nameGlobalTheme = 'Windows'
            ,enableHotkey = True
            ,enclosers = {enclosers_to_escape}
            ,hideHotkey = False
        )

        # Prepare API to save different file types
        # [ASSUMPTION]
        # [1] One can try to export a snapshot into a picture file with similar functions as below
        def saver_CSV(arg_in : pd.DataFrame, arg_out : str):
            return(arg_in.to_csv(arg_out, index=False))
        def saver_XLSX(arg_in : pd.DataFrame, arg_out : str):
            return(arg_in.to_excel(arg_out, index=False, engine='openpyxl'))

        # Inject JS into the dedicated web element
        # [ASSUMPTION]
        # [1] It is tested that `.classList.add` method cannot chain `.style` attribute
        # [2] So we split them into different snippets
        def jsSetStyle(html_id : str) -> str:
            rstOut = cleandoc(f{multi_quotes}
                // Shiny 连接后延迟发送
                $(document).on('shiny:connected', function() {{{{
                    setTimeout(function() {{{{
                        el = document.getElementById('{{html_id}}');
                        if (!el) return;
                        el.classList.add('currOS-box');
                        el.style.setProperty('background-color', 'var(--accent-color)', 'important');
                        el.style.setProperty('font-weight', '400', 'important');
                    }}}}, 50);
                }}}});
            {multi_quotes})
            return(rstOut)

        app_ui = ui.page_fluid(
            ui.h2('原生保存文件对话框')
            ,ui.tags.div(*ossf.headContent) if ossf.headContent else None
            ,ui.row(
                ui.column(4, ui.input_action_button('gen_data', '生成示例数据', class_ = 'currOS-btn-secondary'))
                ,ui.column(4, ossf.ui(
                    'file_save'
                    ,class_ = 'currOS-btn'
                ))
            )
            ,ui.hr()
            ,ui.h4('数据预览')
            ,ui.output_table('data_preview')
            ,ui.h4('保存结果')
            ,ui.output_text_verbatim('save_result')
            ,ui.tags.script(jsSetStyle('save_result'))
        )

        def server(input, output, session):
            df_rv = reactive.value(None)

            @reactive.effect
            @reactive.event(input['gen_data'])
            def _():
                df = pd.DataFrame({{
                    'ID': range(1, 6)
                    ,'Name': ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve']
                    ,'Score': np.random.randint(60, 100, 5)
                    ,'Date': pd.date_range('2025-01-01', periods=5)
                }})
                df_rv.set(df)

            @output
            @render.table
            def data_preview():
                df = df_rv()
                if (not isinstance(df, pd.DataFrame)) or df.empty:
                    return pd.DataFrame({{'提示': ['请先点击“生成示例数据”']}})
                return(df.head(10))

            # 挂载保存模块，并获取保存路径的响应值
            saved_path_rv = ossf.server(
                'file_save'
                ,obj_reactive = df_rv
                ,label = reactive.value('保存文件 (alt+S)')
                ,fileTypes = {{
                    'CSV' : ['csv']
                    ,'XLSX' : ['xlsx']
                }}
                ,fileTypesSaver = {{
                    'CSV' : saver_CSV
                    ,'XLSX' : saver_XLSX
                }}
                ,initPath = os.path.expanduser('~/Documents')
                ,defaultName = None
                ,allowAcceptAll = True
                ,txtAcceptAll = '所有文件 (*)'
                ,dialogTitle = '保存文件'
            )

            @output
            @render.text
            def save_result():
                path = saved_path_rv()
                if not path:
                    return '尚未保存文件'
                return('已保存至: ' + path)

        app = App(app_ui, server)
    """)

    #380. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #370. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App with two buttons and two boxes
    #[03] Click the button <'生成示例数据'> to generate random data table and the upper box shows the preview of the table
    #[04] Click the button <'保存文件 (alt+S)'> to open the dialog to choose the export file, with the default name in the input box
    #[05] Click the button <'保存'> in the dialog, and there will be a notification showing '保存成功！' (can be modified at ease)
    #[06] Hit the keyboard shortcut <alt+S> and conduct the same process
    #[07] The same can be operated on the other button without conflict
    #[08] Close the test page in the web browser
    #[09] Close the command console as popped up when executing the BAT file

    #390. Clean the slate
    #[ASSUMPTION]
    #[1] Below action will NOT remove its parent folders
    shutil.rmtree(dst_dir, ignore_errors = True)

#-Notes- -End-
'''
