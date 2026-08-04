#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import json
import pandas as pd
from inspect import cleandoc
from shiny import Inputs, Outputs, Session, module, reactive, ui, render
from shinywidgets import output_widget, render_widget
from itables.widget import ITable
from omniPy.AdvOp import modifyDict
from omniPy.Styles import OSThemesCSS, CSSKeyframes
from omniPy.ShinyApp import (
    jsHotkeyManager
    ,parseHotkey
    ,jsRegHotkeyWithEffect
    ,jsAutoScrollForDataTables
    ,jsAutoHeight
    ,jsDebounce
    ,jsWinDateCat
    ,jsSyncScrollBar
    ,jsTooltipManager
)
from omniPy.ShinyApp.Modules import ns, DropdownSelect

class DataTablesExplorer:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to create a `shiny module` to display the `DataTables` component in the fashion of Windows Explorer         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[UI Components]                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Toolbar                                                                                                                        #
#   |    [1] <Show Index Toggle   > switch the display of `index` of the reactive input `pd.DataFrame`                                  #
#   |    [2] <Button Select All   > Select all displaying rows in the table and highlight them                                          #
#   |    [3] <Button Deselect All > Deselect all displaying rows in the table and remove their highlight                                #
#   |    [4] <Button Invert Select> Toggle the selection status of the displaying rows in the table                                     #
#   |    [5] <Button Grouping     > Show or hide the Dropdown Select component, from which you can select one of the columns to group   #
#   |        the rows, or select the indication of `No-group` to remove the groups                                                      #
#   |        [1] Columns in the type of `float` are excluded as groupers                                                                #
#   |        [2] Click an option that is already selected, i.e. grouping by that column, will un-group the table and lead to the        #
#   |            selection of the indicator `No-group`                                                                                  #
#   |        [3] When <Show Index Toggle> is turned on, the `index` columns (except the index of type `float`) are also included in the #
#   |            Dropdown list                                                                                                          #
#   |        [4] When in group mode, rows in each group can be displayed or hidden by toggle the group separator, in the fashion of     #
#   |            Windows Explorer                                                                                                       #
#   |    [6] Any `HTML` tags that may be created by `ui.tags`, can be inserted between <Button Grouping> and <Search Box> at the call to#
#   |        `server`, as variable positional parameters                                                                                #
#   |    [7] <Search Box          > (Optional) Search any text string in the WHOLE table, as a universal filtration                     #
#   |[2] Data Table                                                                                                                     #
#   |    [1] There could be a column specified in the argument `actColName` of `server` to display at the left-most side of the table   #
#   |        [1] <Action Button> will also show for each row with the label specified in the argument `actColBtnLabel` of `server`,     #
#   |            clicking on which will lead to the refresh of the reactive output `pd.DaraFrame`, indicating which row was clicked     #
#   |[3] Summary Bar (Optional)                                                                                                         #
#   |    [1] Show the total count of rows, as well as the count of selected rows if any, in the fashion of Windows Explorer             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] It is designed to resemble the Windows Explorer fashion to control the view of `DataTables`                                    #
#   |[2] The entire component is auto heighted, given its wrapper is the only one container with automatic height calculation in the    #
#   |    parent container, otherwise the viewport of the window will be calculated in the wrong way                                     #
#   |[3] Hotkeys are allowed to be applied to the buttons in the toolbar, see the example for details                                   #
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
#   |   |   |   |This method is intended to instantiate the container by defining hyper-parameters. Please try NOT change them during   #
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
#   |   |   |idRootEl          :   <str      > HTML ID of the root of this component                                                    #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in the App                                      #
#   |   |   |                      [<str>               ]          Use other HTML ID to distinguish the modules (which is unnecessary)  #
#   |   |   |idDTWrapper       :   <str      > HTML ID of the wrapper of the `DataTables` of this component, to which the auto-scroll is#
#   |   |   |                       applied, meaning that there will be scroll bars INSIDE this wrapper when the table exceeds its size #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in the App                                      #
#   |   |   |                      [<str>               ]          Use other HTML ID to distinguish the modules (which is unnecessary)  #
#   |   |   |idToolbarSelAll   :   <str      > HTML ID of <Button Select All> of this component                                         #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in the App                                      #
#   |   |   |                      [<str>               ]          Use other HTML ID to distinguish the modules (which is unnecessary)  #
#   |   |   |idToolbarDeselAll :   <str      > HTML ID of <Button Deselect All> of this component                                       #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in the App                                      #
#   |   |   |                      [<str>               ]          Use other HTML ID to distinguish the modules (which is unnecessary)  #
#   |   |   |idToolbarSelInv   :   <str      > HTML ID of <Button Invert Select> of this component                                      #
#   |   |   |                      [<see def.>          ]<Default> Use the same HTML ID in the App                                      #
#   |   |   |                      [<str>               ]          Use other HTML ID to distinguish the modules (which is unnecessary)  #
#   |   |   |ioDTBtn           :   <str      > Message name of the event when clicking on the inline buttons created in the `DataTable` #
#   |   |   |                      [<see def.>          ]<Default> Use the same message name in the App                                 #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |ioFlagUIReady     :   <str      > Message name sent from `ui` to `server`, indicating the `ui` is created, crucial when    #
#   |   |   |                       `ui` is dynamically rendered in the caller module                                                   #
#   |   |   |                      [<see def.>          ]<Default> Use the same message name during the transmition                     #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |ioSelectedRows    :   <str      > Message name of the event when there are rows marked as `selected` in the table          #
#   |   |   |                      [<see def.>          ]<Default> Use the same message name in the App                                 #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |ioMsgPgmSelected  :   <str      > Message name of the event when any column name is selected at back-end as grouper        #
#   |   |   |                      [<see def.>          ]<Default> Use the same message name in the App                                 #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |ioMsgManSelected  :   <str      > Message name of the event when any column name is selected in the Dropdown Select        #
#   |   |   |                       component as grouper                                                                                #
#   |   |   |                      [<see def.>          ]<Default> Use the same message name in the App                                 #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameDTE           :   <str      > Name of the component as DataTables Explorer, should be a valid `JS Object Name`         #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameGlobalTheme   :   <str      > Name of the theme defined in <Styles.OSThemesCSS> to manage the global styles of the App #
#   |   |   |                      [<see def.>          ]<Default> Use a universal style defined in <Styles.OSThemesCSS>                #
#   |   |   |                      [<str>               ]          Any valid theme defined in <Styles.OSThemesCSS>                      #
#   |   |   |nameTooltipManager:   <str      > Name of the dependent component Tooltip Manager, should be a valid `JS Object Name`      #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |instTooltipManager:   <str      > Name of the instance of Tooltip Manager, should be a valid `JS Object Name`              #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameHotkeyManager :   <str      > Name of the dependent component Hotkey Manager, should be a valid `JS Object Name`       #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameSyncScrollBar :   <str      > Name of the dependent component SyncScrollBar, should be a valid `JS Object Name`        #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameAutoScroll    :   <str      > Name of the dependent `JS` function `autoScrollForDataTables`                            #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameAutoHeight    :   <str      > Name of the dependent `JS` function `autoHeight`                                         #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameDebounce      :   <str      > Name of the dependent `JS` function `debounce`                                           #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameDateCat       :   <str      > Name of the dependent `JS` function `winDateCat`                                         #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nameInlineBtnCls  :   <str      > Name of the `CSS` class for the inline action buttons created in the table, for `JS`     #
#   |   |   |                       manipulation and listening                                                                          #
#   |   |   |                      [<see def.>          ]<Default> Use the name in the App                                              #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |valNoGroup        :   <str      > The option value (not the name) indicating `No-group` in the Dropdown Select component   #
#   |   |   |                      [<see def.>          ]<Default> Use the value in the App                                             #
#   |   |   |                      [<str>               ]          Use other value to distinguish the modules (which is unnecessary)    #
#   |   |   |valSelNoGroup     :   <str      > The value indicating that there is a manual selection upon `No-group` at the front-end,  #
#   |   |   |                       informing the back-end NOT to conduct the programmatic selection any more, otherwise there will be  #
#   |   |   |                       infinite loop during the instruction transmition for the Dropdown Select component                  #
#   |   |   |                      [<see def.>          ]<Default> Use the value in the App                                             #
#   |   |   |                      [<str>               ]          Use other value to distinguish the modules (which is unnecessary)    #
#   |   |   |nameHotkeyReg     :   <str      > Name of the registration function for hotkeys                                            #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined name                                             #
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
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |id                :   <str     > ID of the created module. This is resulted from the extension by <module.ui>              #
#   |   |   |dynamicUI         :   <bool    > Whether the `UI` is created in a dynamic way, e.g. show when required                     #
#   |   |   |                      [False               ]<Default> Module is called in the root of a `shiny` App                        #
#   |   |   |                      [True                ]          Module `UI` is created once required to display. Use this value when #
#   |   |   |                                                      the `UI` part of this module is created in the `server` part of its  #
#   |   |   |                                                      caller module, i.e. in a dynamic way.                                #
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
#   |   |   |id                :   <str      > ID of the created module. This is resulted from the extension by <module.server>         #
#   |   |   |dfInput           :   <reactive > DataFrame stored as the type of `reactive.Value`, to display in this module              #
#   |   |   |                      IMPORTANT: `dfInput.columns` cannot be `pd.MultiIndex`                                               #
#   |   |   |*pos              :   <tuple    > Any positional arguments for <ui.tags.div> to insert between <Button Grouping> and       #
#   |   |   |                      <Search Box> in the Toolbar part of the `UI`                                                         #
#   |   |   |addActCol         :   <bool     > Whether to add a column with action buttons for each row                                 #
#   |   |   |                      [False               ]<Default> Do not add the column                                                #
#   |   |   |                      [True                ]          Add the column to allow more control over the module output          #
#   |   |   |actColName        :   <str      > Name of the column with action buttons to be created on the left-most side of the table  #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined name                                             #
#   |   |   |                      [<str>               ]          Specify a different name                                             #
#   |   |   |actColBtnLabel    :   <str      > Label of the action buttons in the column in the name as defined by `actColName`         #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined label                                            #
#   |   |   |                      [<str>               ]          Specify a different label                                            #
#   |   |   |actColBtnClass    :   <str      > The `CSS` class(es) for the action buttons to allow more styles                          #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined class that matches the module style              #
#   |   |   |                      [<str>               ]          Specify different class(es), split by spaces                         #
#   |   |   |colSelected       :   <str      > The name of selected rows in the `dfInput` during web interaction, as a column name in   #
#   |   |   |                      the output DataFrame of the module                                                                   #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined string as the output column name                 #
#   |   |   |                      [<str>               ]          Specify a different column name                                      #
#   |   |   |searchInTable     :   <reactive > Bool value stored as the type of `reactive.Value` indicating whether to allow quick smart#
#   |   |   |                      search within the whole table                                                                        #
#   |   |   |                      [True                ]<Default> Allow quick smart search, see official document of `DataTables.js`   #
#   |   |   |                      [False               ]          Do not display the <Search Box>                                      #
#   |   |   |showSummary       :   <reactive > Bool value stored as the type of `reactive.Value` indicating whether to display a summary#
#   |   |   |                      bar at the bottom of the module `UI`, showing the total number of rows in the table and how many are #
#   |   |   |                      selected at runtime                                                                                  #
#   |   |   |                      [True                ]<Default> Show a summary bar at the bottom of the module `UI`                  #
#   |   |   |                      [False               ]          Do not show the summary bar                                          #
#   |   |   |lang              :   <reactive > Dict stored as the type of `reactive.Value` indicating the texts displayed in the `UI` in#
#   |   |   |                      the preferred language configuration                                                                 #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined language for all components in the `UI` part    #
#   |   |   |                      [<dict>              ]          Provide your own language setting at runtime                         #
#   |   |   |dialogTitle       :   <str      > Title of the popup dialog as file selector                                               #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined title in the dialog                             #
#   |   |   |                      [<str>               ]          Show customized title in the dialog                                  #
#   |   |   |**kw              :   <dict     > Any keyword arguments for <ui.tags.div> to customize the `HTML` attributes of the Toolbar#
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<pd.DataFrame>    :   Generate reactive value <pd.DataFrame> in the `shiny module` at runtime, attributes are as below     #
#   |   |   |                      [index  ] The same as the `dfInput`, which makes it easier to match the data points                  #
#   |   |   |                      [columns] include below                                                                              #
#   |   |   |                                [`colSelected`] <bool> stores the flag of whether the row is selected at runtime           #
#   |   |   |                                [`actColName` ] <int > stores how many times the inline button of current row is clicked   #
#   |   |   |                                                       NOTE: This column only exists when `addActCol==True`                #
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
#   | Date |    20260723        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |re, json, pandas, inspect, shiny, shinywidgets, itables                                                                        #
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
#   |   |   |parseHotkey                                                                                                                #
#   |   |   |jsRegHotkeyWithEffect                                                                                                      #
#   |   |   |jsAutoScrollForDataTables                                                                                                  #
#   |   |   |jsAutoHeight                                                                                                               #
#   |   |   |jsDebounce                                                                                                                 #
#   |   |   |jsWinDateCat                                                                                                               #
#   |   |   |jsSyncScrollBar                                                                                                            #
#   |   |   |jsTooltipManager                                                                                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |Modules                                                                                                                    #
#   |   |   |   |ns                                                                                                                     #
#   |   |   |   |DropdownSelect                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #002. Constructor
    def __init__(
        self
        ,idOSTheme : str = 'os-theme-preset'
        ,idRootEl : str = 'dteRoot'
        ,idDTWrapper : str = 'dteWrapper'
        ,idToolbarSelAll : str = 'selectAll'
        ,idToolbarDeselAll : str = 'deselectAll'
        ,idToolbarSelInv : str = 'selectInvert'
        ,ioDTBtn : str = 'act_click'
        ,ioFlagUIReady : str = 'dte_ui_ready'
        ,ioSelectedRows : str = 'itables_selected'
        ,ioMsgPgmSelected : str = 'pgm_selected'
        ,ioMsgManSelected : str = 'man_selected'
        ,nameDTE : str = 'DataTablesExplorer'
        ,nameGlobalTheme : str = 'Windows'
        ,nameTooltipManager : str = 'window.TooltipManager'
        ,instTooltipManager : str = 'tooltipManager'
        ,nameHotkeyManager : str = 'HotkeyManager'
        ,nameSyncScrollBar : str = 'SyncScrollBar'
        ,nameAutoScroll : str = 'autoScrollForDataTables'
        ,nameAutoHeight : str = 'autoHeight'
        ,nameDebounce : str = 'debounce'
        ,nameDateCat : str = 'winDateCat'
        ,nameInlineBtnCls : str = 'action-btn'
        ,valNoGroup : str = 'no_grp'
        ,valSelNoGroup : str = 'sel_no_grp'
        ,nameHotkeyReg : str = 'jsRegHotkeyWithEffect'
        ,enableHotkey : bool = True
        ,enclosers : dict[str, str] = {'(' : ')'}
        ,hideHotkey : bool = False
        ,options : dict = {}
    ):
        #100. Prepare hyper-parameters
        self.idOSTheme = idOSTheme
        self.idRootEl = idRootEl
        self.idDTWrapper = idDTWrapper
        self.idToolbarSelAll = idToolbarSelAll
        self.idToolbarDeselAll = idToolbarDeselAll
        self.idToolbarSelInv = idToolbarSelInv
        self.ioDTBtn = ioDTBtn
        self.ioFlagUIReady = ioFlagUIReady
        self.ioSelectedRows = ioSelectedRows
        self.ioMsgPgmSelected = ioMsgPgmSelected
        self.ioMsgManSelected = ioMsgManSelected
        self.nameDTE = nameDTE
        self.nameGlobalTheme = nameGlobalTheme
        self.nameTooltipManager = nameTooltipManager
        self.instTooltipManager = instTooltipManager
        self.nameHotkeyManager = nameHotkeyManager
        self.nameSyncScrollBar = nameSyncScrollBar
        self.nameAutoScroll = nameAutoScroll
        self.nameAutoHeight = nameAutoHeight
        self.nameDebounce = nameDebounce
        self.nameDateCat = nameDateCat
        self.nameInlineBtnCls = nameInlineBtnCls
        self.valNoGroup = valNoGroup
        self.valSelNoGroup = valSelNoGroup
        self.nameHotkeyReg = nameHotkeyReg
        self.enableHotkey = enableHotkey
        self.enclosers = enclosers
        self.hideHotkey = hideHotkey
        self.options = options
        self._reg = []
        self.event_dte_init = 'dte-component-init'
        self.event_dte_destroy = 'dte-component-destroy'

        #200. Define options for external componentts
        #210. Options for <HotkeyManager>
        opt_hm = {
            'instHotkeyManager' : 'window.hotkeyManager'
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

        #800. Initialize dependent modules
        self.dds_group = DropdownSelect(
            nameGlobalTheme = nameGlobalTheme
            ,nameTooltipManager = nameTooltipManager
            ,instTooltipManager = instTooltipManager
            ,nameHotkeyManager = nameHotkeyManager
            ,nameHotkeyReg = nameHotkeyReg
            ,enableHotkey = enableHotkey
            ,enclosers = enclosers
            ,hideHotkey = hideHotkey
            ,options = self.options
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
        self._register_(self.dds_group.headContent)

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
        #[ASSUMPTION]
        #[1] We split this part as it may be the same injection as other modules with hotkey functionality
        anim.load('btnClickPulse')
        css_anim_hotkey = ui.head_content(ui.tags.style(anim.gather))
        anim.purge()

        anim.load([
            'transformPulse'
            ,'rotateFade'
            ,'transformFlip'
        ])
        css_anim_icons = ui.head_content(ui.tags.style(anim.gather))
        anim.purge()

        #130. Prepare the specific CSS for current module
        css_snippet = cleandoc('''
            /* 统一简约线条图标基础样式 */
            .dte-root .operation-icon {
              color: var(--text-secondary);
              /*
              display: inline-block;
              */
              width: 20px;
              height: 20px;
              line-height: 20px;
              text-align: center;
            }
            /* 全选图标 "\2611" */
            .dte-root .icon-select-all::before {
              content: "☑";
            }
            /* 全否选图标 "\2610" */
            .dte-root .icon-select-none::before {
              content: "☐";
            }
            /* 反选图标 "\21C4" */
            .dte-root .icon-select-invert::before {
              content: "⇄";
            }
            /* 高亮一列图标 "\25AE" */
            .dte-root .icon-highlight-column::before {
              content: "▮";
            }
            /* 分组图标 "\229E" */
            .dte-root .icon-group {
              /*
              margin-top: -2px;
              */
            }
            .dte-root .icon-group::before {
              content: "⊞";
            }
            /* 表格中按钮图标 "\1F310" */
            .dte-root .icon-inline-action {
              margin-top: -2px;
            }
            .dte-root .icon-inline-action::before {
              content: "🌐";
              filter: brightness(0.8);
              font-size: var(--font-s);
              margin-top: -2px;
            }

            /* 悬停状态 - 与文件列表行悬停视觉统一 */
            .dte-root .operation-icon:hover {
              color: var(--accent-color); /* 系统主题色强调 */
              transform: translateY(-1px); /* 轻微上浮效果 */
            }
            .dte-root .icon-inline-action:hover {
              filter: brightness(1.25); /* 部分图标有前置的亮度改动 */
            }
            .dte-root .inline-action-label:hover {
              filter: brightness(1.2);
              transform: translateY(-1px);
            }

            /* 点击按压状态 - 物理反馈 */
            .dte-root .operation-icon:active {
              transform: translateY(0);
            }

            /* 功能状态切换动画 */
            /* 全选/全不选状态切换 */
            .dte-root .icon-select-all.active::before {
              animation: transformPulse 0.3s ease;
            }
            .dte-root .icon-select-none.active::before {
              animation: rotateFade 0.2s ease;
            }

            /* 反选交互动画 */
            .dte-root .icon-select-invert:hover::before {
              animation: transformFlip 0.4s ease;
            }

            /* 将整个module内容器改为紧凑型 */
            /* 这里不加空格，代表若同时存在这些class，才应用样式 */
            .dte-root.explorer-compact {
              padding: 0;
              height: 100%;
              /* 上下排列 */
              display: flex;
              flex-direction: column;
              /* 当root高度由外部指定时，不允许其内部额外出现滚动条 */
              overflow: hidden;
            }
            .dte-root .dte-table-wrapper {
              height: 100%;
            }

            /* 自定义按钮的label */
            .dte-root .action-label {
              font-family: var(--font-family);
            }

            .dte-root .dte-switch-inline {
              height: var(--explorer-btn-height);
              /* 将子容器垂直居中 */
              display: flex;
              align-items: center;
            }

            /* 覆盖 shiny input container 的样式 */
            /* 参考 .currOS-btn */
            .dte-root .dte-switch-inline > .shiny-input-container {
              /* 将switch改为inline，可与自定义label在同一行显示 */
              display: flex;
              align-items: center;
              text-align: center;
              height: var(--explorer-btn-height);
              width: 32px;
              padding: 0 4px;
              margin-bottom: 0;
              font-weight: 500;
            }

            .dte-root .dte-switch-inline > .shiny-input-container > .bslib-input-switch {
              display: flex;
              align-items: center;
              margin-top: 4px;
            }

            /* 将原生label隐藏 */
            /* https://cloud.tencent.com/developer/article/2623354 */
            .dte-root .dte-switch-inline .form-check-label {
              display: none;
            }

            /* 自定义label尽量靠近开关 */
            .dte-root .dte-switch-inline > .currOS-btn-explorer {
              margin-left: -8px;
            }

            .dte-root .dte-switch-inline > .currOS-btn-explorer:hover {
              cursor: default;
            }

            /* 改变开关的形状 */
            .dte-root .dte-switch-inline .form-check-input {
              height: 12px;
              width: 1.5em !important;
              vertical-align: middle;
              margin-top: 2px;
              cursor: pointer;
            }
            /* 没有效果，因为该组件用svg控制开关动画 */
            .dte-root .dte-switch-inline .form-check-input:hover {
              color: var(--accent-color);
            }

            .dte-root .currOS-btn-explorer span {
              margin-left: 0 !important;
            }

            /* 覆盖默认输入框 */
            /* [dte] DataTables as Explorer */
            .dte-root .dte-explorer-input {
              width: 200px;
              margin-left: auto;
              margin-top: var(--explorer-margin-adj);
              margin-bottom: 0;
              height: var(--explorer-btn-height);
              padding: 0 4px;
            }

            /* 分组展开/收起状态 */
            .dte-root .icon-group.active::before {
              content: "\229F"; /* 切换为展开符号 */
              transform: rotate(180deg);
              transition: transform 0.2s ease;
            }

            /* 修改DT的默认样式 */
            .dte-root table.dataTable thead th,
            .dte-root table.dataTable thead td {
              border-bottom: 1px solid var(--border-color) !important;
            }
            .dte-root table.dataTable tbody td {
              border-top: none !important;
              border-bottom: none !important;
            }
            .dte-root table.dataTable.no-footer {
              border-bottom: none;
            }

            /* 依据 SyncScrollBar 的需求设置 */
            .dte-root .dt-scroll-head {
              scrollbar-width: none;
              -ms-overflow-style: none;
            }
            .dte-root .dt-scroll-head::-webkit-scrollbar {
                display: none;
                width: 0;
                height: 0;
            }

            /* Set the styles when the filtered data.table has no record */
            .dte-root .dataTables_empty {
              line-height: 1;
              font-size: 14px;
              font-family: var(--font-family);
            }

    		/*
              Below class is defined to set the styles for the accessaries of the datatable
              Quote: https://datatables.net/examples/basic_init/dom.html
            */
            .dte-root .acc-dataTable {
              line-height: 1;
              font-size: 14px;
              font-family: var(--font-family);
            }

            /* 选择表格中的行会触发两个修改 */
            .dte-root .dte-table-wrapper table.dataTable tbody tr.selected {
              background-color: var(--group-sep-bg) !important;
              color: var(--text-primary) !important;
            }
            /* 不限定元素的selector优先级低，会被命名selector覆盖 */
            .dte-root .dte-table-wrapper table.dataTable>tbody>tr.selected>* {
              box-shadow: inset 0 0 0 9999px rgba(var(--bg-primary),1);
            }
            .dte-root .dte-table-wrapper table.dataTable>tbody>tr.selected>.sorting_1 {
              box-shadow: inset 0 0 0 9999px rgba(var(--bg-primary),1);
            }

            /* 当表格中的行被悬停或选中时，行中的按钮背景变透明，这样保持与行中其他字段的背景一致 */
            .dte-root .dte-table-wrapper table.dataTable>tbody>tr.selected>td .action-btn {
              background-color: transparent;
            }
            .dte-root .dte-table-wrapper table.dataTable>tbody>tr:hover>td .action-btn {
              background-color: transparent;
            }

            /* 此组件自定义的列 */
            .dte-root td.row-id-col,
            .dte-root th.row-id-col {
              display: none !important;
            }
            /* 索引列仅保留颜色，显隐由 DataTables API 控制 */
            .dte-root .index-col {
              color: var(--text-secondary);
            }

            /* 稍微修改表头样式 */
            .dte-root .currOS-details-header {
              background-color: var(--bg-primary);
              color: var(--text-secondary);
              font-size: 12px;
              font-weight: 600;
            }
            /* [Testing] 可将以下语句放开以测试 `autoScrollForDataTables` 是否能准确计算高度 */
            /*
            .dte-root .dt-scroll-head table.dataTable th {
              padding: 8px 12px;
            }
            */
        ''')

        #200. 启动时注册快捷键管理器
        #[ASSUMPTION]
        #[1] 由于没有外部依赖，该管理器每次注入均完全一样，因此会由 `ui.head_content` 进行哈希去重
        #[2] 同样，创建管理器实例时，脚本也会被去重，从而避免多实例
        hotkeyManager = ui.head_content(ui.tags.script(jsHotkeyManager(self.nameHotkeyManager)))

        js_hotkeyMgr = cleandoc(f'''
            // 创建{self.nameHotkeyManager}实例
            {self.options[self.nameHotkeyManager]['instHotkeyManager']} = new {self.nameHotkeyManager}({{
                ignoreEditable: {str(self.options.get('ignoreEditable', 'true')).lower()}, // 默认在输入框中跳过
                preventDefault: {str(self.options.get('preventDefault', 'true')).lower()},
                stopPropagation: {str(self.options.get('stopPropagation', 'true')).lower()},
                debug: {str(self.options.get('stopPropagation', 'false')).lower()}, // 可设为true查看调试日志
            }});

            // ==================== 页面卸载时清理 ====================
            window.addEventListener('beforeunload', () => {{
                {self.options[self.nameHotkeyManager]['instHotkeyManager']}.dispose();
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

        #500. 无需定制的依赖项
        dtAutoScroll = ui.head_content(ui.tags.script(jsAutoScrollForDataTables(
            funcName = self.nameAutoScroll
        )))
        rootAutoHeight = ui.head_content(ui.tags.script(jsAutoHeight(
            funcName = self.nameAutoHeight
        )))
        debounce = ui.head_content(ui.tags.script(jsDebounce(
            funcName = self.nameDebounce
        )))
        winDateCat = ui.head_content(ui.tags.script(jsWinDateCat(
            funcName = self.nameDateCat
        )))

        syncScrollBar = ui.head_content(ui.tags.script(jsSyncScrollBar(
            funcName = self.nameSyncScrollBar
        )))

        #700. 注册本模块中自定义的全局 JS 功能
        #710. 以 Windows Explorer 样式展示数据表格
        js_dte = cleandoc(f'''
            // DataTable 浏览器主类
            class {self.nameDTE} {{
                #rootId;
                #tableContainerId;
                #selectAllId;
                #deselectAllId;
                #invertSelectId;
                #searchInputId;
                #itablesSelectedId;
                #actClickId;
                #summaryId;
                #msgDTAutoHeight;
                #msgPgmSelect;
                #menuNoGroup;
                #menuSelNoGroup;
                #summaryTemplate;

                #instSyncScrollBar;
                #initAutoHeighted;

                #groupMode = false;
                #groupColName = '';
                #groupColIdx = -1;
                #showIndex = false;

                #currentTable = null;
                #currentTableNode = null;
                #tableCheckInterval = null;
                #selectedInterval = null;

                /**
                    依赖的外部项
                    - 类
                      - window.DropdownSelect
                      - SyncScrollBar
                    - 函数
                      - {self.nameAutoHeight}
                      - {self.nameAutoScroll}
                      - {self.nameDateCat}
                */

                constructor(options) {{
                    this.#rootId = options.rootId;
                    this.#tableContainerId = options.tableContainerId;
                    this.#selectAllId = options.selectAllId;
                    this.#deselectAllId = options.deselectAllId;
                    this.#invertSelectId = options.invertSelectId;
                    this.#searchInputId = options.searchInputId;
                    this.#itablesSelectedId = options.itablesSelectedId;
                    this.#actClickId = options.actClickId;
                    this.#summaryId = options.summaryId;
                    this.#msgDTAutoHeight = options.msgDTAutoHeight;
                    this.#msgPgmSelect = options.msgPgmSelect;
                    this.#menuNoGroup = options.menuNoGroup;
                    this.#menuSelNoGroup = options.menuSelNoGroup;

                    this.#summaryTemplate = '';
                    this.#instSyncScrollBar = null;
                    this.#initAutoHeighted = false;

                    this.#setupEventListeners();
                    this.#startTableMonitor();
                    this.#startSelectedCollector();
                    /*
                        [ASSUMPTION]
                        [1] 经测试，这里只能使用 this.#menuNoGroup ，因为此时其他监听器还未创建，无法在后端计算，必须给菜单中现有的值
                    */
                    this.#updateMenuIndicator(this.#menuNoGroup);

                    // 页面就绪后应用自适应高度
                    {self.nameAutoHeight}({{selector: '#' + this.#rootId}});
                }}

                // ---------- 公开接口（供 Shiny 调用）----------
                /** 按列名将数据分组 */
                groupByColumn(colName) {{
                    const table = this.#currentTable;
                    if (!table) return;
                    if (!colName) {{
                        this.#groupMode = false;
                        this.#groupColName = '';
                        this.#groupColIdx = -1;
                        $(table.table().body()).find('tr').show();
                        $(table.table().node()).find('tr.group-separator').removeClass('collapsed').remove();
                        table.order([]).draw();
                        return;
                    }}
                    this.#groupMode = true;
                    let colIdx = -1;
                    table.columns().every(function() {{
                        if ($(this.header()).text().trim() === colName) {{
                            colIdx = this.index();
                            return false;
                        }}
                    }});
                    if (colIdx === -1) return;
                    const currentOrder = table.order();
                    /*
                    console.log(
                        'prev groupColName: ', this.#groupColName
                        ,' | prev groupColIdx:', this.#groupColIdx
                        ,' | prev orderby:', currentOrder.length > 0 ? currentOrder[0][0] : null
                        ,' | prev order:', currentOrder.length > 0 ? currentOrder[0][1] : null
                    );
                    */
                    let newDir = 'asc';
                    if (currentOrder.length > 0 && colIdx === this.#groupColIdx) {{
                        newDir = currentOrder[0][1] === 'desc' ? 'asc' : 'desc';
                    }}
                    this.#groupColName = colName;
                    this.#groupColIdx = colIdx;
                    table.order([colIdx, newDir]).draw();
                    const newOrder = table.order();
                    /*
                    console.log(
                        'curr groupColName: ', this.#groupColName
                        ,' | curr groupColIdx:', this.#groupColIdx
                        ,' | curr orderby:', newOrder[0][0]
                        ,' | curr order:', newOrder[0][1]
                    );
                    */
                }}

                updateMenuIndicator(colName) {{
                    this.#updateMenuIndicator(colName);
                }}
                // Shiny中发送的消息无法操作私有变量，这里暴露一个公有方法，但不接收参数，直接调用私有方法操作私有变量
                syncMenuIndicator() {{
                    this.#updateMenuIndicator(this.#groupColName);
                }}

                /** 组件语言变更 */
                updateLang(template) {{
                    this.#summaryTemplate = template.summaryTemplate;

                    // 变更语言后须同时更新显示文字
                    this.#updateSummary();
                }}

                /** 公开接口用于Shiny从后端发送指令更改索引列的显示状态 */
                setShowIndex(show) {{
                    this.#showIndex = show;
                    if (typeof this.#applyIndexColumnVisibility === 'function') {{
                        this.#applyIndexColumnVisibility();
                    }}
                }}

                /** 资源回收 */
                dispose() {{
                    if (this.#instSyncScrollBar && typeof this.#instSyncScrollBar.dispose === 'function') {{
                        this.#instSyncScrollBar.dispose();
                        this.#instSyncScrollBar = null;
                    }}
                    if (this.#tableCheckInterval) {{
                        clearInterval(this.#tableCheckInterval);
                        this.#tableCheckInterval = null;
                    }}
                    if (this.#selectedInterval) {{
                        clearInterval(this.#selectedInterval);
                        this.#selectedInterval = null;
                    }}
                    $(document).off('click', '#' + this.#selectAllId);
                    $(document).off('click', '#' + this.#deselectAllId);
                    $(document).off('click', '#' + this.#invertSelectId);
                    $(document).off('click', '#' + this.#rootId + ' .action-btn');
                    $(document).off('click', '#' + this.#rootId + ' tr.group-separator');
                }}

                // ---------- 私有方法 ----------
                /** 向后端发送消息更新下拉框选择状态 */
                /**
                    [ASSUMPTION]
                    [1] 在表格中选择列的时候并未与下拉框组件交互，因此需要推送程序化选择的指令
                    [2] 下拉框中点击已选中的选项时，组件功能是取消所有选择状态；但这个模块需要改为将 `无分组` 的选项选中。因此
                        需要额外推送程序化选择的指令并由后端执行
                */
                #updateMenuIndicator(colName) {{
                    Shiny.setInputValue(this.#msgPgmSelect, colName, {{ priority: 'event' }});
                }}

                /** 使用 DataTables API 控制索引列可见性 */
                #applyIndexColumnVisibility() {{
                    if (!this.#currentTable) return;
                    this.#currentTable.columns('.index-col').visible(this.#showIndex);
                    this.#currentTable.columns.adjust();
                    setTimeout(() => {{ this.#currentTable.columns.adjust(); }}, 50);
                    setTimeout(() => {{ this.#updateGroupSeparators(this.#currentTable); }}, 60);
                }}

                /** 显示或隐藏分组分隔条 */
                #updateGroupSeparators(api) {{
                    if (!api) return;
                    const tbody = $(api.table().body());
                    const cols = api.columns().indexes();
                    const rowIdColIdx = cols.length - 1;

                    api.rows().every(function() {{
                        const row = this.node();
                        const rowId = api.cell(this, rowIdColIdx).data();
                        $(row).attr('id', rowId);
                    }});

                    $(api.table().header()).find('th').addClass('currOS-details-header');
                    tbody.find('tr:not(.group-separator)').addClass('currOS-details-row');
                    tbody.find('tr.selected').addClass('selected');

                    tbody.find('tr.group-separator').remove();
                    tbody.find('tr.currOS-details-row').show();
                    tbody.find('tr.group-separator').removeClass('collapsed');

                    if (!this.#groupMode) {{
                        tbody.find('tr').attr('data-group', '');
                        this.#updateMenuIndicator('');
                        return;
                    }}

                    const order = api.order();
                    if (!order || order.length === 0) {{
                        this.#groupMode = false;
                        this.#groupColName = '';
                        this.#groupColIdx = -1;
                        tbody.find('tr').attr('data-group', '');
                        this.#updateMenuIndicator(this.#menuNoGroup);
                        return;
                    }}

                    const colIdx = order[0][0];
                    const th = $(api.column(colIdx).header());
                    // console.log('groupColName: ', this.#groupColName, ' | colIdx:', colIdx, ' | th:', th.text().trim());

                    if (th.text().trim() !== this.#groupColName) {{
                        if (th.hasClass('col-type-float')) {{
                            this.#groupMode = false;
                            this.#groupColName = '';
                            this.#groupColIdx = -1;
                            tbody.find('tr').attr('data-group', '');
                            this.#updateMenuIndicator(this.#menuNoGroup);
                            return;
                        }}
                        this.#groupColName = th.text().trim();
                        this.#updateMenuIndicator(this.#groupColName);
                    }}

                    if (th.hasClass('col-type-float')) {{
                        this.#groupMode = false;
                        this.#groupColName = '';
                        this.#groupColIdx = -1;
                        tbody.find('tr').attr('data-group', '');
                        this.#updateMenuIndicator(this.#menuNoGroup);
                        return;
                    }}

                    const isDate = th.hasClass('col-type-date');
                    api.rows().every(function(rowIdx) {{
                        const row = this.node();
                        const displayVal = api.cell(rowIdx, colIdx).render('display');
                        let groupVal = '';
                        if (isDate) {{
                            const dataVal = api.cell(rowIdx, colIdx).data();
                            const d = new Date(dataVal);
                            if (!isNaN(d)) {{
                                groupVal = {self.nameDateCat}(d);
                            }} else {{
                                groupVal = displayVal;
                            }}
                        }} else {{
                            groupVal = displayVal;
                        }}
                        $(row).attr('data-group', groupVal);
                    }});

                    // 分隔条 colspan 基于可见列数
                    const visibleColCount = api.columns(':visible').count();
                    const rows = tbody.find('tr:not(.group-separator)').toArray();
                    let prevGroup = null;
                    $.each(rows, (i, row) => {{
                        const groupVal = $(row).attr('data-group');
                        if (!groupVal) return;
                        if (groupVal !== prevGroup) {{
                            const colspan = visibleColCount;
                            const groupCount = $(row).nextUntil('.group-separator', 'tr[data-group="' + groupVal + '"]').length + 1;
                            const sep = $(
                                '<tr class="currOS-group-separator group-separator">'
                                + '<td colspan="' + colspan + '">'
                                + '<span class="group-toggle"></span>' + groupVal + ' (' + groupCount + ')'
                                + '</td>'
                                + '</tr>'
                            );
                            $(row).before(sep);
                            prevGroup = groupVal;
                        }}
                    }});
                }}

                /** 用自定义搜索框替代原生搜索（主要为了将搜索框拆分出来放入工具栏） */
                #setupCustomSearch() {{
                    const container = $('#' + this.#tableContainerId);
                    // 隐藏原生搜索行
                    const nativeSearchInput = container.find(`input[type='search'].dt-input`);
                    if (nativeSearchInput.length > 0) {{
                        nativeSearchInput.closest('.dt-layout-row').hide();
                    }}
                    // 隐藏信息行
                    const infoDiv = container.find('.dt-info');
                    if (infoDiv.length > 0) {{
                        infoDiv.closest('.dt-layout-row').hide();
                    }}

                    // 监听自定义输入框
                    const customInput = $('#' + this.#searchInputId);
                    customInput.addClass('currOS-input dte-explorer-input');
                    customInput.off('input.search').on('input.search', (e) => {{
                        const value = $(e.target).val();
                        // 将值写入原生搜索框并触发搜索
                        // const nativeInput = container.find('input[type="search"].dt-input');
                        if (nativeSearchInput.length > 0 && this.#currentTable) {{
                            nativeSearchInput.val(value);
                            this.#currentTable.search(value).draw();
                        }}
                    }});
                }}

                /** 用自定义统计页脚替代原生页脚（主要为了将页脚拆分出来方便重写布局） */
                #updateSummary() {{
                    const summaryDiv = $('#' + this.#summaryId);
                    if (!this.#currentTable || !summaryDiv.length) return;
                    const info = this.#currentTable.page.info();
                    const total = info.recordsTotal;
                    const filtered = info.recordsDisplay;

                    // 统计筛选后可见的选中行数
                    const selectedSet = new Set();
                    $(this.#currentTable.table().body()).find('tr.selected').each(function() {{
                        const id = $(this).attr('id');
                        if (id) selectedSet.add(id);
                    }});
                    let selectedInFiltered = 0;
                    $(this.#currentTable.table().body()).find('tr').each(function() {{
                        if (selectedSet.has($(this).attr('id'))) selectedInFiltered++;
                    }});

                    // 这些格式字符串将由后端更新
                    const texts = this.#summaryTemplate || {{
                        display_total: '{{}}个项目',
                        selected: ' | 选中{{}}个项目',
                        total: ' | 筛选前总共{{}}个项目'
                    }};
                    let text = texts.display_total.replace('{{}}', filtered);
                    if (selectedInFiltered > 0) {{
                        text += texts.selected.replace('{{}}', selectedInFiltered);
                    }}
                    if (filtered < total) {{
                        text += texts.total.replace('{{}}', total);
                    }}
                    summaryDiv.text(text);
                }}

                /** 创建监听器 */
                #setupEventListeners() {{
                    // 点击分隔条折叠或展开对应数据行
                    $(document).on('click', '#' + this.#rootId + ' tr.group-separator', (e) => {{
                        const sep = $(e.currentTarget);
                        sep.toggleClass('collapsed');
                        const groupVal = sep.next('tr').attr('data-group');
                        const groupRows = sep.nextUntil('.group-separator', 'tr[data-group="' + groupVal + '"]');
                        if (sep.hasClass('collapsed')) {{
                            groupRows.stop(true, true).slideUp(100);
                        }} else {{
                            groupRows.stop(true, true).slideDown(100);
                        }}
                    }});

                    // 数据选择组件的操作
                    $(document).on('click', '#' + this.#selectAllId, () => {{
                        if (this.#currentTable) this.#currentTable.rows().select();
                    }});
                    $(document).on('click', '#' + this.#deselectAllId, () => {{
                        if (this.#currentTable) this.#currentTable.rows().deselect();
                    }});
                    $(document).on('click', '#' + this.#invertSelectId, () => {{
                        if (!this.#currentTable) return;
                        const sel = this.#currentTable.rows({{selected: true}}).indexes();
                        const all = this.#currentTable.rows().indexes();
                        const toDeselect = [], toSelect = [];
                        for (let i = 0; i < all.length; i++) {{
                            if (sel.indexOf(all[i]) === -1) toSelect.push(all[i]);
                            else toDeselect.push(all[i]);
                        }}
                        this.#currentTable.rows(toSelect).select();
                        this.#currentTable.rows(toDeselect).deselect();
                    }});

                    // 监听表格中按钮的点击事件
                    $(document).on('click', '#' + this.#rootId + ' .{self.nameInlineBtnCls}', (e) => {{
                        e.stopPropagation(); e.preventDefault();
                        const rowId = $(e.currentTarget).data('row-id');
                        if (rowId !== undefined) {{ Shiny.setInputValue(this.#actClickId, rowId, {{priority: 'event'}}); }}
                        const tr = $(e.currentTarget).closest('tr')[0];
                        if (tr && this.#currentTable) {{ this.#currentTable.row(tr).deselect(); }}
                    }});
                }}

                /** 持续监测表格实例（兼容 scroll 布局） */
                #startTableMonitor() {{
                    this.#tableCheckInterval = setInterval(() => {{
                        const container = $('#' + this.#tableContainerId);
                        if (container.length === 0) return;
                        const tableNode = container.find('.dt-scroll-body table.dataTable')[0] || container.find('table.dataTable')[0];
                        if (!tableNode) return;
                        if (tableNode !== this.#currentTableNode) {{
                            this.#currentTableNode = tableNode;
                            const table = $(tableNode).DataTable();
                            this.#currentTable = table;

                            // 同步 `head` 与 `body` 中的滚动条，仅同步X轴
                            if (!this.#instSyncScrollBar) {{
                                const dtBody = tableNode.closest('.dt-scroll-body');
                                const siblings = Array.from(dtBody.parentNode.children).filter(function(child) {{
                                    // 排除当前元素并筛选具有相同class的元素
                                    return child !== dtBody && child.classList.contains('dt-scroll-head');
                                }});
                                const dtHead = siblings[0];
                                this.#instSyncScrollBar = new {self.nameSyncScrollBar}({{
                                    containers: [dtBody, dtHead],
                                    scrollBar: 'X',
                                    debug: false, // 可设为true查看调试日志
                                    autoEnable: true,
                                }});
                            }}

                            table.columns('.index-col').visible(this.#showIndex);

                            $(tableNode).off('draw.dt').on('draw.dt', () => {{
                                /*
                                    [ASSUMPTION]
                                    [1] 经测试，这里的 api 不能再次用 query 取得，否则在多实例之间切换过的前提下会获得不同的对象，这样原有的排序无法获取
                                */
                                // const api = $(tableNode).DataTable();
                                const api = table;
                                const order = api.order();
                                if (this.#groupMode && (!order || order.length === 0)) {{
                                    this.#groupMode = false;
                                    this.#groupColName = '';
                                    this.#groupColIdx = -1;
                                    this.#updateMenuIndicator(this.#menuNoGroup);
                                }}
                                /*
                                console.log(
                                    'tableContainerId: ', this.#tableContainerId
                                    ,' | new groupColName: ', this.#groupColName
                                    ,' | new groupColIdx:', this.#groupColIdx
                                    ,' | new orderby:', order.length > 0 ? order[0][0] : null
                                    ,' | new order:', order.length > 0 ? order[0][1] : null
                                );
                                */
                                setTimeout(() => {{
                                    this.#updateGroupSeparators(api);
                                    this.#updateSummary();
                                }}, 0);
                            }});

                            setTimeout(() => {{
                                this.#updateGroupSeparators(table);
                                this.#setupCustomSearch();
                                if (!this.#initAutoHeighted) {{
                                    {self.nameAutoScroll}(this.#msgDTAutoHeight);
                                    this.#initAutoHeighted = true;
                                }}
                                this.#updateSummary();
                            }}, 50);
                        }}
                    }}, 300);
                }}

                /** 监听表格中行的选择事件 */
                #startSelectedCollector() {{
                    this.#selectedInterval = setInterval(() => {{
                        if (!this.#currentTable) return;
                        const selected = [];
                        $(this.#currentTable.table().body()).find('tr.selected').each(function() {{
                            const id = $(this).attr('id'); if (id) selected.push(id);
                        }});
                        Shiny.setInputValue(this.#itablesSelectedId, JSON.stringify(selected));
                        this.#updateSummary();
                    }}, 300);
                }}
            }}
        ''')

        #730. Listener to create customized Datatables Explorer instance at runtime
        js_creator = cleandoc(f'''
            document.addEventListener('DOMContentLoaded', function() {{
                // 全局实例索引（同时保留在 DOM 元素上）
                window.{self.nameDTE}Instances = window.{self.nameDTE}Instances || {{}};
                window.dteResizeHandlers = window.dteResizeHandlers || {{}};

                Shiny.addCustomMessageHandler('{self.event_dte_init}', function(payload) {{
                    const ns = payload.ns;                  // 模块唯一标识
                    const options = payload.options;        // 选项数据

                    // 若已存在实例，跳过后续步骤
                    if (window.{self.nameDTE}Instances[ns]) {{
                        return;
                    }}

                    // 创建新实例，存储引用到全局和 DOM 元素
                    const instance = new {self.nameDTE}(options);
                    window.{self.nameDTE}Instances[ns] = instance;

                    // 经测试，每次调整window的尺寸，都会影响root的尺寸，因此需要监听
                    const optDebounce = {{
                        rootId: payload.rootId,
                        tableContainerId: payload.tableContainerId,
                        msgDTAutoHeight: payload.msgDTAutoHeight,
                    }};
                    function resizeFunc(options) {{
                        const container = $('#' + options.tableContainerId);
                        if (container.length === 0) return;
                        const tableNode = container.find('.dt-scroll-body table.dataTable')[0] || container.find('table.dataTable')[0];
                        if (!tableNode) return;

                        setTimeout(function() {{
                            {self.nameAutoHeight}({{selector: '#' + options.rootId}});
                            {self.nameAutoScroll}(options.msgDTAutoHeight);
                        }}, 20);
                    }}
                    window.dteResizeHandlers[ns] = {self.nameDebounce}(resizeFunc.bind(null, optDebounce), 100);
                    window.addEventListener('resize', window.dteResizeHandlers[ns]);

                    // ==================== 页面卸载时清理 ====================
                    window.addEventListener('beforeunload', () => {{
                        window.removeEventListener('resize', window.dteResizeHandlers[ns], true);
                        delete window.dteResizeHandlers[ns];
                    }});
                }});

                // 可选：模块销毁清理
                Shiny.addCustomMessageHandler('{self.event_dte_destroy}', function(ns) {{
                    if (window.{self.nameDTE}Instances[ns]) {{
                        window.{self.nameDTE}Instances[ns].dispose();
                        delete window.{self.nameDTE}Instances[ns];
                    }}
                }});
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
            #500. 其他依赖项
            ,dtAutoScroll
            ,rootAutoHeight
            ,debounce
            ,winDateCat
            ,syncScrollBar
            #800. 组件定义
            ,ui.head_content(ui.tags.script(js_dte))
            ,ui.head_content(ui.tags.script(js_creator))
            #900. 组件样式
            #[ASSUMPTION]
            #[1] 将需要设置最高优先级的样式放在最后注入
            ,css_anim_hotkey
            ,css_anim_icons
            ,ui.head_content(ui.tags.style(css_snippet))
            ,os_theme
        ]

        return(init_tags_final)

    #750. Static part
    @property
    def ui(self):
        @module.ui
        def wrapper(
            dynamicUI : bool = False
        ):
            #050. Local parameters
            idRootEl = ns(self.idRootEl)
            idDTWrapper = ns(self.idDTWrapper)
            ioFlagUIReady = ns(self.ioFlagUIReady)
            ioMsgPgmSelected = ns(self.ioMsgPgmSelected)
            ioMsgManSelected = ns(self.ioMsgManSelected)
            funcNameInit = re.sub(r'\W', r'_', ns('initDTE'))

            #800. Prepare UI-specific JS injection for current session
            #[ASSUMPTION]
            #[1] Listen to the message of manual selection in the Dropdown Select component and decide the behavior at the back-end
            #[2] Send an input value to the `server`, indicating that the static `UI` is ready for server to create dynamic `UI`
            js_ui = cleandoc(f'''
                {funcNameInit} = function() {{
                    Shiny.addCustomMessageHandler('{ioMsgManSelected}', function(msg) {{
                        if (!window.{self.nameDTE}Instances['{idRootEl}']) return;
                        if (typeof window.{self.nameDTE}Instances['{idRootEl}'].groupByColumn !== 'function') return;
                        if (!msg.value) return;
                        // console.log('{idRootEl}:', msg.value);
                        if (msg.value === '{self.valSelNoGroup}') {{
                            window.{self.nameDTE}Instances['{idRootEl}'].groupByColumn('');
                        }} else if (msg.value === '{self.valNoGroup}') {{
                            Shiny.setInputValue('{ioMsgPgmSelected}', msg.value, {{ priority: 'event' }});
                        }} else {{
                            window.{self.nameDTE}Instances['{idRootEl}'].groupByColumn(msg.value);
                        }}
                    }});

                    Shiny.setInputValue('{ioFlagUIReady}', true, {{ priority: 'event' }});
                }};
            ''')

            #805. Determine if the UI is designed to be created dynamically in the caller session
            #[ASSUMPTION]
            #[1] We have to delay the initialization of `server`, for the data transmition depends on the `UI` to exist in the
            #    first place. The best way is to inform `server` that the `UI` is created and ready to receive data
            #[2] We cannot listen to the event `shiny:connected` or `DOMContentLoaded` for below reasons:
            #    [1] This module may be called in another module or Shiny app in a dynamic way, so it may miss the timing when
            #        `shiny` is initialized at the launch of the app
            #[3] We cannot trigger the injection by `session.on_flushed` at `server` side for below reasons:
            #    [1] It is only triggered at the next reactive flush of the module, which will miss the first value passed from the
            #        manual selection (which is `null` though). By doing this will lead to the initial status of the Dropdown
            #        Select component to be `null selected` instead of `selected the item of No-grouping`
            #    [2] Quote: https://shiny.posit.co/py/api/core/Session.html#shiny.session.Session.on_flushed
            if dynamicUI:
                js_delay = f'{funcNameInit}();'
            else:
                js_delay = cleandoc(f'''
                    setTimeout({funcNameInit}, 100);
                ''')

            #809. Combine the scripts
            js_snippet = '\n'.join([js_ui, js_delay])

            #999. Render UI
            ui_tags_final = ui.tags.div(
                #500. 启动时可见的部分
                ui.tags.div(
                    ui.output_ui('toolbar_ui'),
                    style="border-bottom: 1px solid var(--border-color); margin-bottom: 2px;"
                )
                ,ui.tags.div(output_widget('main_table'), id = idDTWrapper, class_ = 'dte-table-wrapper')
                ,ui.output_ui('summary_ui')
                ,ui.tags.script(js_snippet)
                ,class_ = 'currOS-explorer-view explorer-compact dte-root'
                ,id = idRootEl
            )

            return(ui_tags_final)

        return(wrapper)

    #800. Server part
    @property
    def server(self):
        @module.server
        def wrapper(
            input : Inputs
            ,output : Outputs
            ,session : Session
            ,dfInput : reactive.Value
            ,*pos
            ,addActCol : bool = False
            ,actColName : str = 'actionColumn'
            ,actColBtnLabel : str = 'Action'
            ,actColBtnClass : str = 'currOS-btn-explorer'
            ,colSelected : str = 'col_selected'
            ,searchInTable : reactive.Value = reactive.value(True)
            ,showSummary : reactive.Value = reactive.value(True)
            ,lang : reactive.Value = reactive.value({
                'show_index' : '显示索引'
                ,'select_all' : '全选'
                ,'deselect_all' : '全否选'
                ,'invert_select' : '反选'
                ,'group_btn' : '分组'
                ,'menu-grouping' : {
                    'universal' : '全局控制'
                    ,'index' : '行索引'
                    ,'columns' : '列名'
                }
                ,'menu-no-group' : '(无分组)'
                ,'group_sel_ph' : '未选择'
                ,'search_input' : '在列表中搜索'
                ,'summary_display_total' : '{}个项目'
                ,'summary_selected' : '选中{}个项目'
                ,'summary_total' : '筛选前总共{}个项目'
            })
            ,**kw
        ):
            #050. Local parameters
            idRootEl = session.ns(self.idRootEl)
            idDTWrapper = ns(self.idDTWrapper)
            ioDTBtn = session.ns(self.ioDTBtn)
            idSearchInput = session.ns('search_input')
            idToolbarSelAll = session.ns(self.idToolbarSelAll)
            idToolbarDeselAll = session.ns(self.idToolbarDeselAll)
            idToolbarSelInv = session.ns(self.idToolbarSelInv)
            ioSelectedRows = session.ns(self.ioSelectedRows)
            show_index = reactive.value(False)
            selected_rows = reactive.value(set())
            action_clicks = reactive.value(dict())
            dds_group_label = reactive.value(None)
            dds_group_ph = reactive.value(None)
            choices = reactive.value(None)
            pgm_selection = reactive.value(None)
            man_selection = reactive.value(None)
            ioMsgPgmSelected = session.ns(self.ioMsgPgmSelected)
            ioMsgManSelected = session.ns(self.ioMsgManSelected)
            idUISummary = session.ns('summary')

            hk_new = {
                'select_all' : reactive.value(None)
                ,'deselect_all' : reactive.value(None)
                ,'invert_select' : reactive.value(None)
            }
            hk_registered = {
                'select_all' : None
                ,'deselect_all' : None
                ,'invert_select' : None
            }
            display_label = {
                'select_all' : reactive.value(None)
                ,'deselect_all' : reactive.value(None)
                ,'invert_select' : reactive.value(None)
            }

            #099. Send message to front-end to establish the component
            #[ASSUMPTION]
            #[1] We cannot send the message regardless of whether the `UI` is ready, otherwise the establishment of the component
            #    will miss the timing to receive this message when `UI` is dynamically created
            @reactive.effect
            async def _construction():
                #001. Skip if `UI` is not ready
                if not input[self.ioFlagUIReady]():
                    return

                #800. Prepare UI-specific JS injection for current session
                options = {
                    'rootId': idRootEl
                    ,'tableContainerId': idDTWrapper
                    ,'selectAllId': idToolbarSelAll
                    ,'deselectAllId': idToolbarDeselAll
                    ,'invertSelectId': idToolbarSelInv
                    ,'searchInputId': idSearchInput
                    ,'actClickId': ioDTBtn
                    ,'summaryId': idUISummary
                    ,'itablesSelectedId': ioSelectedRows
                    ,'msgDTAutoHeight': {
                        'selector': '#' + idDTWrapper
                        ,'fullwidth': True
                    }
                    ,'msgPgmSelect': ioMsgPgmSelected
                    ,'menuNoGroup': self.valNoGroup
                    ,'menuSelNoGroup': self.valSelNoGroup
                }

                await session.send_custom_message(
                    self.event_dte_init,
                    {'ns': idRootEl, 'options': options}
                )

            #100. Show/hide the index columns as per interaction in the page
            @reactive.effect
            @reactive.event(input['show_index'])
            def _sync_show_index():
                val = input['show_index']()
                show_index.set(val)
                show_js = 'true' if val else 'false'
                ui.remove_ui('#' + session.ns('toggleIndex'))
                js_snippet = cleandoc(f'''
                    if (
                        window.{self.nameDTE}Instances['{idRootEl}']
                        && typeof window.{self.nameDTE}Instances['{idRootEl}'].setShowIndex === 'function'
                    ) {{
                        window.{self.nameDTE}Instances['{idRootEl}'].setShowIndex({show_js});
                    }}
                ''')
                ui.insert_ui(ui.tags.script(js_snippet, id = session.ns('toggleIndex')), selector = 'body', where = 'afterBegin')

            #200. Determine the dataframe to use in the server part
            @reactive.calc
            def df_lcl():
                df = dfInput().copy()
                for c in df.select_dtypes(include = 'object').columns:
                    df[c] = df[c].astype(str)

                # 先生成 _row_id，确保后续按钮可用
                if isinstance(df.index, pd.MultiIndex):
                    df['_row_id'] = ['_'.join(map(str, vals)) for vals in df.index]
                else:
                    df['_row_id'] = df.index.astype(str)

                if addActCol:
                    btn_class = actColBtnClass or 'currOS-btn-explorer'
                    def make_btn(row_id):
                        return(ui.tags.button(
                            ui.tags.span(
                                ui.tags.div(class_ = 'operation-icon icon-inline-action')
                                ,class_ = 'action-icon'
                            )
                            ,ui.tags.span(
                                actColBtnLabel
                                ,class_ = 'action-label inline-action-label'
                            )
                            ,class_ = f'{self.nameInlineBtnCls} {btn_class}'
                            ,data_row_id = f'{row_id}'
                        ))
                    df[actColName] = [make_btn(rid) for rid in df['_row_id']]

                # 统一索引命名（用于分组菜单）
                if isinstance(df.index, pd.MultiIndex):
                    new_names = [name if name is not None else f'_itable_idx_{i}' for i, name in enumerate(df.index.names)]
                    df.index = df.index.set_names(new_names)
                else:
                    if df.index.name is None:
                        df.index.name = '_itable_idx_0'
                return df

            #209. Function to obtain the index of the local dataframe
            @reactive.calc
            def all_indices():
                return list(df_lcl().index)

            #280. Determine the dataframe to display in the UI
            @reactive.calc
            def df_display():
                df = df_lcl().copy()
                idx = df.index
                if isinstance(idx, pd.MultiIndex):
                    for i, name in enumerate(idx.names):
                        df[name] = idx.get_level_values(i)
                else:
                    name = idx.name
                    df[name] = idx

                final_cols = []
                if addActCol and actColName in df.columns:
                    final_cols.append(actColName)
                idx_names = df.index.names if isinstance(df.index, pd.MultiIndex) else [df.index.name]
                for n in idx_names:
                    if n in df.columns and n not in final_cols:
                        final_cols.append(n)
                for c in df.columns:
                    if c not in final_cols and c != '_row_id':
                        final_cols.append(c)
                final_cols.append('_row_id')
                return df[final_cols]

            #300. Function to read the selected rows from the front-end interaction
            @reactive.effect
            def _update_selected_from_js():
                js_data = input[self.ioSelectedRows]()
                if js_data is None:
                    return
                try:
                    ids = json.loads(js_data)
                    selected_rows.set(set(str(i) for i in ids))
                except:
                    pass

            #500. ---------- 动态工具栏 ----------
            @output
            @render.ui
            def toolbar_ui():
                L = lang()
                return(ui.div(
                    ui.tags.div(
                        ui.input_switch('show_index', None, value=False)
                        ,ui.tags.div(L['show_index'], class_='btn btn-default currOS-btn-explorer')
                        ,class_ = 'dte-switch-inline'
                    )
                    ,ui.input_action_button(
                        self.idToolbarSelAll
                        ,ui.output_ui('selectAll_label')
                        ,class_ = 'currOS-btn-explorer'
                        ,icon = ui.tags.div(class_ = 'operation-icon icon-select-all')
                    )
                    ,ui.input_action_button(
                        self.idToolbarDeselAll
                        ,ui.output_ui('deselectAll_label')
                        ,class_ = 'currOS-btn-explorer'
                        ,icon = ui.tags.div(class_ = 'operation-icon icon-select-none')
                    )
                    ,ui.input_action_button(
                        self.idToolbarSelInv
                        ,ui.output_ui('invSelect_label')
                        ,class_ = 'currOS-btn-explorer'
                        ,icon = ui.tags.div(class_ = 'operation-icon icon-select-invert')
                    )
                    ,self.dds_group.ui(
                        session.ns('col_sel_menu')
                        ,icon = ui.tags.div(class_ = 'operation-icon icon-group')
                        ,class_ = ''
                        ,displaySelection = False
                        ,displaySide = 'right'
                        ,dynamicUI = True
                    )
                    ,*pos
                    ,*(
                        [ui.tags.input(id = idSearchInput, type = 'text', placeholder = L['search_input'])]
                        if searchInTable()
                        else []
                    )
                    ,style = 'display: flex; gap: 4px; padding: 2px 0;'
                    ,class_ = 'toolbar'
                    ,**kw
                ))

            #510. Helper functions
            #511. Function to parse the labels for hotkey creation
            @reactive.effect
            def _prep_label():
                lcl_label = lang()
                buttons = list(display_label.keys())
                for btn in buttons:
                    display_label[btn].set(lcl_label[btn])
                if self.enableHotkey:
                    for btn in buttons:
                        display, tmphotkey = parseHotkey(lcl_label[btn], enclosers = self.enclosers)
                        if tmphotkey is None:
                            hk_new[btn].set('')
                        else:
                            hk_new[btn].set(tmphotkey)
                        if self.hideHotkey:
                            display_label[btn].set(display)

            #515. Function to generate the JS snippet for certain button
            def h_gen_label_js(
                btnName : str
                ,btnId : str
                ,runScript : str = 'btn.click();'
            ) -> str:
                nonlocal hk_registered
                lcl_hotkey = hk_new[btnName]()
                lcl_hotkey_registered = hk_registered[btnName]

                #300. Prepare the script to register/unregister the hotkey for the trigger button
                js_snippet = jsRegHotkeyWithEffect(
                    selector = '#' + btnId
                    ,register = lcl_hotkey
                    ,unregister = lcl_hotkey_registered
                    ,funcName = 'regHotkey_' + re.sub(r'\W', '_', btnId)
                    ,addTooltip = self.hideHotkey
                    ,instTooltipManager = self.instTooltipManager
                    ,instHotkeyManager = self.options[self.nameHotkeyManager]['instHotkeyManager']
                    ,elName = 'btn'
                    ,runScript = runScript
                    #[ASSUMPTION]
                    #[1] See below classes in `Styles.OSThemesCSS`
                    ,classList = ['key-triggered', 'clicked']
                    ,returnFunc = None
                    ,options = self.options[self.nameHotkeyReg]
                )

                #399. Update the registered hotkey
                hk_registered[btnName] = lcl_hotkey

                return(js_snippet)

            #550. Render label of `select all` button at runtime
            #[ASSUMPTION]
            #[1] Trigger the refresh of the dynamic `ui` by observing `lang`, to ensure that when different language configurations
            #    indicate the same `display_label` with different hotkeys, the hotkeys of this `ui` is also up-to-date
            @output
            @render.ui
            def selectAll_label():
                _ = lang()
                lcl_label = display_label['select_all']()
                js_snippet = h_gen_label_js('select_all', idToolbarSelAll)
                return(ui.div(
                    lcl_label
                    ,ui.tags.script(js_snippet)
                ))

            #560. Render label of `deselect all` button at runtime
            @output
            @render.ui
            def deselectAll_label():
                _ = lang()
                lcl_label = display_label['deselect_all']()
                js_snippet = h_gen_label_js('deselect_all', idToolbarDeselAll)
                return(ui.div(
                    lcl_label
                    ,ui.tags.script(js_snippet)
                ))

            #570. Render label of `invert select` button at runtime
            @output
            @render.ui
            def invSelect_label():
                _ = lang()
                lcl_label = display_label['invert_select']()
                js_snippet = h_gen_label_js('invert_select', idToolbarSelInv)
                return(ui.div(
                    lcl_label
                    ,ui.tags.script(js_snippet)
                ))

            #600. 分组下拉框组件互动
            #610. 设置下拉框选项
            @reactive.effect
            def col_choices():
                L = lang()
                df = df_lcl()
                choices_int = []

                #100. Add choice for No Group at the top of the dropdown component
                choices_int.append({
                    'label' : L['menu-grouping']['universal']
                    ,'options' : [
                        {'value' : self.valNoGroup, 'label' : L['menu-no-group']}
                    ]
                })

                #400. Add choices of index if required at runtime
                if show_index():
                    idx_names = df.index.names
                    choices_int.append({
                        'label' : L['menu-grouping']['index']
                        ,'options' : [
                            {'value' : n, 'label' : n}
                            for n in idx_names
                        ]
                    })

                #700. Add choices of columns
                choices_int.append({
                    'label' : L['menu-grouping']['columns']
                    ,'options' : [
                        {'value' : n, 'label' : n}
                        for n in df.columns
                        if (n not in [actColName, '_row_id'])
                        and (not pd.api.types.is_float_dtype(df[n]))
                    ]
                })

                choices.set(choices_int)

            #620. 从所有非该组件中互动取得的已选项，用于在该组件中同步显示选项状态的变更
            @reactive.effect
            def _pgm_selection():
                pgm_val = input[self.ioMsgPgmSelected]()
                pgm_selection.set(pgm_val)

            #630. 为组件动态计算入参
            @reactive.effect
            def _cr_dds_svr():
                L = lang()
                dds_group_label.set(L['group_btn'])
                dds_group_ph.set(L['group_sel_ph'])

            #650. 创建下拉框组件的 server 部分
            #[ASSUMPTION]
            #[1] 若要组件的 server 能直接在本 module 顶层调用，需要在组件的内部必要功能上加条件控制
            #[2] 最优做法是：由组件的 UI 静态发送 `UI已装载` 的标志消息，由组件的 server 端各相关功能根据它判断调用时机
            selected_groupby = self.dds_group.server(
                'col_sel_menu'
                ,label = dds_group_label
                ,placeholder = dds_group_ph
                ,choices = choices
                ,listenPayload = pgm_selection
                ,maxHeight = 800
                ,minHeight = 40
                ,minWidth = 40
                ,scrollSpeed = 5.5
                ,windowGap = 10
                ,submenuGap = 4
                ,submenuMaxHeight = 800
            )

            #670. 获取组件交互所得的已选项
            @reactive.effect
            def _get_man_select():
                #800. Observe the interactive selection made at front-end and collect the result
                #[ASSUMPTION]
                #[1] When clicking a selected item again, the component removes all selection, which is not the design of this module
                #[2] We reset such behavior by directing the empty selection to a certain choice `menu_no_group`
                leaf_value = self.dds_group.extractFromLeaf(
                    selected_groupby()
                    ,attr_ = 'value'
                    ,placeholder = 'no.Select'
                    ,unknown = 'unknown'
                )
                if leaf_value == self.valNoGroup:
                    leaf_value = self.valSelNoGroup
                elif leaf_value in ['no.Select', 'unknown']:
                    leaf_value = self.valNoGroup
                # print(f'leaf_value: {leaf_value}')
                man_selection.set(leaf_value)

            #680. 向前端发送组件交互所得的已选项，用于触发前端重绘分组容器
            @reactive.effect
            async def _man_selection():
                value = man_selection()
                if not isinstance(value, str):
                    return
                await session.send_custom_message(
                    ioMsgManSelected
                    ,{'value' : value.strip()}
                )

            #700. ---------- 动态状态栏 ----------
            @output
            @render.ui
            def summary_ui():
                if not showSummary():
                    return None
                L = lang()
                # 注入 summary 格式到前端，并初始化文本
                display_total = re.sub(r'`', r'\`', L['summary_display_total'])
                selected = re.sub(r'`', r'\`', L['summary_selected'])
                total = re.sub(r'`', r'\`', L['summary_total'])
                js_snippet = cleandoc(f'''
                    textTemplate = {{
                        display_total: `{display_total}`,
                        selected: ` | {selected}`,
                        total: ` | {total}`
                    }};
                    if (
                        window.{self.nameDTE}Instances['{idRootEl}']
                        && typeof window.{self.nameDTE}Instances['{idRootEl}'].updateLang === 'function'
                    ) {{
                        setTimeout(function() {{
                            window.{self.nameDTE}Instances['{idRootEl}'].updateLang({{
                                summaryTemplate: textTemplate,
                            }});
                        }}, 200);
                    }}
                ''')
                ui.remove_ui('#summaryTextsScript')
                ui.insert_ui(ui.tags.script(js_snippet, id = 'summaryTextsScript'), selector = 'body', where = 'afterBegin')
                total_records = len(dfInput().index)
                return(ui.tags.div(
                    L['summary_display_total'].format(total_records)
                    ,class_ = 'currOS-summary-bar'
                    ,id = idUISummary
                ))

            #800. 绘制主体数据表格
            @output(id = 'main_table')
            @render_widget
            def main_table():
                df = df_display()
                if df.empty: df = pd.DataFrame(columns = df_display().columns)

                #[ASSUMPTION]
                #[1] 模拟Windows Explorer将所有表头左对齐
                #    https://datatables.net/reference/option/columns.className
                cols = df.columns.tolist()
                row_id_idx = cols.index('_row_id')

                # 构建 columnDefs，统一添加 dt-head-left
                column_defs = []
                # row-id 列
                column_defs.append({'targets' : [row_id_idx], 'className' : 'row-id-col dt-head-left'})

                # 按需要增加每行的按钮
                if addActCol and actColName in cols:
                    act_idx = cols.index(actColName)
                    column_defs.append({
                        'targets' : [act_idx]
                        ,'type' : 'html'
                        ,'orderable' : False
                        ,'className' : 'dt-head-left'
                    })

                # 预先将索引列加入前端表格，使得前端能完全控制其是否显示，从而无需通信
                idx_names = df.index.names if isinstance(df.index, pd.MultiIndex) else [df.index.name]
                for n in idx_names:
                    if n in cols:
                        i = cols.index(n)
                        column_defs.append({'targets' : [i], 'className' : 'index-col dt-head-left'})

                # 将所有源数据中的列加入表格
                for i, col in enumerate(cols):
                    if i == row_id_idx or (addActCol and col == actColName) or col in idx_names:
                        continue
                    dtype = df[col].dtype
                    base_class = 'dt-head-left'
                    if pd.api.types.is_float_dtype(dtype):
                        base_class += ' col-type-float'
                    elif pd.api.types.is_datetime64_any_dtype(dtype):
                        base_class += ' col-type-date'
                    column_defs.append({'targets' : [i], 'className' : base_class})

                #[ASSUMPTION]
                #[1] Parameters
                #    [paging                     ] Should be `False` to maintain a File Explorer style
                #    [dom                        ] is actually deprecated, use `layout=` instead
                #      https://datatables.net/reference/option/dom
                #      https://datatables.net/reference/option/layout
                #    [allow_html                 ] Should be `True` to enable buttons inside the table
                #    [warn_on_undocumented_option] Should be `False` to suppress unnecessary warnings
                #    [classes                    ] Should be set as below to maintain mimum functionality
                #      https://datatables.net/manual/styling/classes
                #    [layout                     ] Should be investigated
                #      https://datatables.net/reference/option/layout
                #      https://datatables.net/examples/layout/ids-and-classes.html
                return ITable(
                    df
                    ,showIndex = False
                    ,select = 'multi'
                    ,paging = False
                    ,ordering = True
                    ,columnDefs = column_defs
                    ,allow_html = True
                    ,warn_on_undocumented_option = False
                    ,classes = 'compact order-column nowrap'
                    # 由于JS处理了自动高度的问题，这里必须为 100% ，不能为 100vh
                    ,scrollY = '100%'
                    ,scrollCollapse = True
                    ,layout = {
                        'topEnd' : 'search'
                    }
                )

            #900. 收集返回信息
            #910. 收集表格中每个按钮的点击次数
            @reactive.Effect
            @reactive.event(input[self.ioDTBtn])
            def _handle_act_click():
                row_id = input[self.ioDTBtn]()
                if row_id is None: return
                clicks = action_clicks().copy()
                clicks[str(row_id)] = clicks.get(str(row_id), 0) + 1
                action_clicks.set(clicks)

            #990. 创建输出数据
            @reactive.Calc
            def df_return():
                idx = dfInput().index
                if isinstance(idx, pd.MultiIndex):
                    row_ids = ['_'.join(map(str, vals)) for vals in idx]
                else:
                    row_ids = idx.astype(str)
                result = pd.DataFrame(index = idx)
                result[colSelected] = [rid in selected_rows() for rid in row_ids]
                if addActCol:
                    result[actColName] = [action_clicks().get(rid, 0) for rid in row_ids]
                return(result)

            return(df_return)

        return(wrapper)

#End DataTablesExplorer

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
    to_esc_css = (
        """
            .card {
                background-color: var(--bg-primary);
            }
            .card-header {
                background-color: var(--bg-primary);
                font-family: var(--font-family);
            }

            /* 对所有 nav-item 用伪元素模拟渐变边框 */
            /* Quote: https://cloud.tencent.com/developer/article/1960952 */
            .nav_item {
                background-clip: padding-box; /* 重要 */
            }
            .nav-item::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                z-index: -1; /* 确保伪元素在内容之下 */
                border-radius: inherit; /* 重要 */
                background-image: linear-gradient(180deg, var(--border-color), var(--bg-primary));
            }

            /* 非活动的 Tab 页边框 */
            .nav-tabs .nav-link,
            .nav-tabs>li>a {
                border: none;
                border-top: var(--bs-nav-tabs-border-width) solid var(--border-color);
                border-bottom: transparent;
            }
            .nav-tabs .nav-link:hover,
            .nav-tabs>li>a:hover {
                border-top: var(--bs-nav-tabs-border-width) solid var(--border-color);
                background: linear-gradient(180deg, var(--bg-surface), var(--bg-primary));
            }

            /* 非活动的 Tab 页文字（为链接） */
            .nav-link,
            .nav-tabs>li>a {
                color: var(--accent-color);
            }
            .nav-link:hover,
            .nav-tabs>li>a:hover {
                color: var(--accent-hover);
            }

            /* 活动的 Tab 页边框 */
            .nav-tabs .nav-link.active,
            .nav-tabs>li>a.active {
                border: none;
                border-top: var(--bs-nav-tabs-border-width) solid var(--border-color);
                border-bottom: transparent;
            }

            /* 活动的 Tab 页背景和文字 */
            .card-header-tabs .nav-link.active {
                background: linear-gradient(180deg, var(--bg-surface), var(--bg-primary));
                color: var(--text-primary);
            }

            #debug.shiny-text-output {
                font-family: var(--font-family);
                color: var(--text-primary);
            }
        """
    ).strip()
    to_esc_lang = (
        """
            {
                'show_index' : '显示索引'
                ,'select_all' : '全选'
                ,'deselect_all' : '全否选'
                ,'invert_select' : '反选 (alt+numpad-)'
                ,'group_btn' : '分组'
                ,'menu-grouping' : {
                    'universal' : '全局控制'
                    ,'index' : '行索引'
                    ,'columns' : '列名'
                }
                ,'menu-no-group' : '(无分组)'
                ,'group_sel_ph' : '未选择'
                ,'search_input' : '在列表中搜索'
                ,'summary_display_total' : '{}个项目'
                ,'summary_selected' : '选中{}个项目'
                ,'summary_total' : '筛选前总共{}个项目'
            }
        """
    ).strip()
    multi_quotes = '"""'
    newline = '\\n'
    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import sys
        import pandas as pd
        import numpy as np
        from shiny import App, ui, render, reactive

        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )
        from omniPy.ShinyApp.Modules import DataTablesExplorer

        dte_Table1 = DataTablesExplorer(
            nameGlobalTheme = 'Windows'
            ,hideHotkey = True
        )

        css_snippet = {multi_quotes}
            {to_esc_css}
        {multi_quotes}

        app_ui = ui.page_fillable(
            ui.tags.div(*dte_Table1.headContent)
            ,ui.head_content(ui.tags.style(css_snippet))
            ,ui.navset_card_tab(
                ui.nav_panel(
                    'Table A'
                    ,dte_Table1.ui('explorer')
                    ,ui.output_text('debug')
                )
                ,ui.nav_panel(
                    'Table B'
                    ,dte_Table1.ui('test')
                )
            )
            ,fillable_mobile = True
        )

        # 设置随机种子以保证结果可复现（可选）
        np.random.seed(42)

        # 1. 创建 MultiIndex 索引
        # 第一层：字符 (例如 'A', 'B', 'C'...)
        # 第二层：整数 (例如 1, 2, 3...)
        # 为了凑够30行，我们可以设计组合，例如 5个字符 * 6个整数 = 30行
        level_0 = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon']
        level_1 = [ str(i) for i in[10, 20, 30, 40, 50, 60] ]

        # 生成所有组合并截取前30个（这里正好5*6=30）
        multi_index = pd.MultiIndex.from_product([level_0, level_1], names=['StrLevel', 'IntLevel'])

        # 2. 准备各列数据
        n_rows = 30

        # 列1-2: 字符类型 (String/Object)
        col_str_1 = np.random.choice(['apple', 'banana', 'cherry', 'date'], n_rows)
        col_str_2 = ['ID_' + str(i) for i in range(n_rows)]

        # 列3-4: 整数类型 (Int)
        col_int_1 = np.random.randint(1, 100, n_rows)
        col_int_2 = np.random.randint(1000, 9999, n_rows)

        # 列5-6: 浮点数类型 (Float)
        col_float_1 = np.random.randn(n_rows) * 10 + 50  # 均值50，标准差10
        col_float_2 = np.random.uniform(0.0, 1.0, n_rows)

        # 列7-8: 分类类型 (Categorical)
        # 先定义原始数据，再转换为 category 类型
        cat_data_1 = np.random.choice(['Low', 'Medium', 'High'], n_rows)
        col_cat_1 = pd.Categorical(cat_data_1, categories=['Low', 'Medium', 'High'], ordered=True)

        cat_data_2 = np.random.choice(['TypeX', 'TypeY', 'TypeZ'], n_rows)
        col_cat_2 = pd.Categorical(cat_data_2)

        # 列9-10: 日期时间类型 (Datetime)
        # 生成从 2023-01-01 开始的随机日期
        start_date = pd.Timestamp('2023-01-01')
        random_days = np.random.randint(0, 365, n_rows)
        col_dt_1 = start_date + pd.to_timedelta(random_days, unit='D')

        # 生成带时间的 datetime
        random_seconds = np.random.randint(0, 86400, n_rows)
        col_dt_2 = start_date + pd.to_timedelta(random_days * 86400 + random_seconds, unit='s')

        # 3. 构建 DataFrame
        data = {{
            'CharCol_1': col_str_1,
            'CharCol_2': col_str_2,
            'IntCol_1': col_int_1,
            'IntCol_2': col_int_2,
            'FloatCol_1': col_float_1,
            'FloatCol_2': col_float_2,
            'CatCol_1': col_cat_1,
            'CatCol_2': col_cat_2,
            'DateTimeCol_1': col_dt_1,
            'DateTimeCol_2': col_dt_2
        }}

        df_input = pd.DataFrame(data, index=multi_index)

        def server(input, output, session):
            df1 = reactive.value(df_input)
            df2 = reactive.Value(pd.DataFrame({{
                "名称": ["张三", "李四", "王五", "赵六", "钱七"],
                "部门": pd.Categorical(["技术", "市场", "技术", "市场", "财务"]),
                "工龄": [3, 5, 2, 8, 4],
                "入职日期": pd.to_datetime(["2020-01-15", "2018-06-01", "2022-03-10", "2015-12-20", "2019-07-30"]),
                "绩效分": [88.5, 92.0, 85.0, 91.2, 78.5]
            }}))

            lang = reactive.value({to_esc_lang})

            #[ASSUMPTION]
            #[1] 按钮上可加快捷键，如 `反选`
            df1_return = dte_Table1.server(
                'explorer'
                ,df1
                ,addActCol = True
                ,actColBtnClass = 'currOS-btn-explorer'
                ,searchInTable = reactive.value(True)
                ,showSummary = reactive.value(True)
                ,lang = lang
            )
            df2_return = dte_Table1.server(
                'test'
                ,df2
                ,addActCol = True
                ,actColBtnClass = 'currOS-btn-explorer'
                ,searchInTable = reactive.value(False)
                ,showSummary = reactive.value(True)
                ,lang = lang
            )

            @output
            @render.text
            def debug():
                d = df1_return()
                total_clicks = d['actionColumn'].sum()
                return(f'选中行数: {{d["col_selected"].sum()}} / 按钮点击总次数: {{total_clicks}}')

        app = App(app_ui, server)
        if __name__ == '__main__':
            app.run()
    """)

    #380. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #370. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App with a navigation box with two tabs
    #[03] Click on the switch to show or hide the <indexes> of the table, which will NOT disturb the other interactions in the table
    #    [1] When the table is grouped by any among the <indexes> and switch to hide the <indexes>, the table will fallback to
    #        the status of non-grouped. This is the design.
    #[04] There are buttons to manage the selected rows in the table, try them and see the stats at the bottom of the tab
    #[05] There is a button triggering the dropdown list to choose the grouping column name, which will group the rows in the table
    #    [1] Float columns are NOT displayed in the dropdown list, which is the design
    #    [2] Date and datetime columns will be categorized in the similar way as Windows 11, during grouping the rows
    #    [3] At the time there is an active grouping column, you can switch the grouping column by clicking on the `sort` indicators
    #        beside the column head in the table, which can be clicked once more to toggle the sorting order of groups as well
    #    [4] Rows in the same group can be cascaded and expanded by the group separator right above the first row of the group
    #[06] There can be an input box on the right side of the toolbar, allowing to filter the texts in the WHOLE table
    #[07] Table is rendered by `ITables` hence it is interactive
    #    [1] One can choose to add a column with action buttons on the very left side of the table, so that when clicking on any
    #        of them, there will be a reactive dataframe refreshed as the module output marking which row has been clicked
    #    [2] Clicking on anywhere except the inline button will highlight the entire row, and also trigger the refresh of the reactive
    #        dataframe as the module output, marking which rows are selected
    #    [3] There are components on the header part to toggle the sorting order of any ONE column. We do not plan to allow multiple
    #        sorting as we design to resemble the Windows Explorer style
    #[08] Hotkeys are allowed to be added in all the buttons in the toolbar, see `反选` as example
    #    [1] Hotkeys are also allowed to be hidden from the label, which leads to a tooltip created instead, to display the hotkey
    #    [2] Hotkeys can be a single name on the keyboard, or prefixed with at most 3 meta keys, e.g. `ctrl+alt+shift+A`. However,
    #        keyboard combinations with only the meta keys are NOT allowed, bad case: `ctrl` or `ctrl+shift`
    #[09] You can add more HTML tags between the dropdown list and the input box for your own customization, by inserting something
    #     like `ui.tags.div` at the call to module `server` as positional arguments
    #[10] Similarly, you can add more style controls to the toolbar with HTML attributes, by inserting something like
    #     `data_attr='...'` at the call to module `server` as keyword arguments. They will be translated to: `data-attr='...'` in the
    #     rendered <div> of the toolbar
    #[11] Switch between the tabs to check the segregation of the module instances
    #[12] Close the test page in the web browser
    #[13] Close the command console as popped up when executing the BAT file

    #390. Clean the slate
    #[ASSUMPTION]
    #[1] Below action will NOT remove its parent folders
    shutil.rmtree(dst_dir, ignore_errors = True)

#-Notes- -End-
'''
