#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import textwrap
import pandas as pd
from inspect import cleandoc
from shiny import Inputs, Outputs, Session, module, reactive, ui, render
from omniPy.AdvOp import modifyDict
from omniPy.Styles import OSThemesCSS, CSSKeyframes
from omniPy.ShinyApp import jsDropdownSelect, TagsCollection, parseHotkey, jsHotkeyManager, jsRegHotkeyWithEffect, jsTooltipManager
from omniPy.ShinyApp.Modules import ns

class DropdownSelect:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to create a `shiny module` for interactively selecting items from a modern fashion dropdown list            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[UI Components]                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] <Button> result a popup HTML tag when clicked                                                                                  #
#   |    [1] <Dropdown Panel> listing all choices defined at module call, probably with multiple levels and grouping indications. User  #
#   |        is allowed to select only one choice among all the nested panels                                                           #
#   |[2] (optional) disabled <Text Input> showing the interactive selection result on the right side (default) or left side of the      #
#   |    button as requested at initialization of the component                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] It is designed to accept keyboard and touchpad interactions, see its dependent JS class definition for details                 #
#   |[2] Execution and injection dependencies are as below                                                                              #
#   |    [1] `_send_choices` depends on reactive input at call to `server`                                                              #
#   |    [2] Eventlisteners registered for construction of JS class depends on the message sent from `_send_choices`                    #
#   |    [3] Construction of JS class depends on `wrapper` creation in DOM via `ui`                                                     #
#   |    [4] `ui` depends on reactive input at call to `server`                                                                         #
#   |    [5] Injection of OS theme depends on the instruction from `_send_choices`                                                      #
#   |[3] Based on above dependency tree, we have to conduct below statements in the dedicated sequence                                  #
#   |    [1] Inject all global tools `headContent` at the beginning of the App ui, or they will never be executed due to protection of  #
#   |        the web browser                                                                                                            #
#   |    [2] Call the `ui` inside the `ui` part of the caller module or the App where applicable. It can be embedded in a dynamically   #
#   |        created part of `ui`, as we have designed to skip the component construction when `ui` is not ready                        #
#   |    [3] Call the `server` inside the `server` part of the caller module or the App where applicable.                               #
#   |        [IMPORTANT] Do not call it in a `reactive.effect` function, as it will NOT propagate the selection result as a             #
#   |                    `reactive.value` by doing so. Just make it a direct call and assign a `reactive.value` to make it work, see    #
#   |                    <ShinApp.Modules.DataTablesExplorer> for its usage in a dynamically created `ui`.                              #
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
#   |   |   |ioFlagUIReady     :   <str      > Message name sent from `ui` to `server`, indicating the `ui` is created, crucial when    #
#   |   |   |                       `ui` is dynamically rendered in the caller module                                                   #
#   |   |   |                      [<see def.>          ]<Default> Use the same message name during the transmition                     #
#   |   |   |                      [<str>               ]          Use other name to distinguish the modules (which is unnecessary)     #
#   |   |   |nsComponent       :   <str      > Namespace of the component by which to search within the DOM tree to locate the wrapper  #
#   |   |   |                       of the component this module is creating. `ui` use this to set the `data-ns` of the wrapper, and    #
#   |   |   |                       `server` send this to the global eventlistener for component construction                           #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined namespace                                        #
#   |   |   |                      [<str>               ]          Use other names to distinguish the modules, which is unnecessary as  #
#   |   |   |                                                      it is already wrapped by the system `ns`                             #
#   |   |   |nsSelResult       :   <str      > Name of the input event sent from `ui` side and to be observed at the `server` side. This#
#   |   |   |                       event holds the selection result from within the component interaction                              #
#   |   |   |                      [<see def.>          ]<Default> Use the same event name in `ui` and `server`                         #
#   |   |   |                      [<str>               ]          Use other names to distinguish the modules (which is unnecessary)    #
#   |   |   |nsPgmSel          :   <str      > Name of event sent from `server` side and to be listened at the front-end. This event    #
#   |   |   |                       holds the programmatic instruction to select certain choice at the front-end                        #
#   |   |   |                      [<see def.>          ]<Default> Use the same event name in `ui` and `server`                         #
#   |   |   |                      [<str>               ]          Use other names to distinguish the modules (which is unnecessary)    #
#   |   |   |nameGlobalTheme   :   <str      > Name of the theme defined in <Styles.OSThemesCSS> to manage the global styles of the App #
#   |   |   |                      [<see def.>          ]<Default> Use a universal style defined in <Styles.OSThemesCSS>                #
#   |   |   |                      [<str>               ]          Any valid theme defined in <Styles.OSThemesCSS>                      #
#   |   |   |nameHotkeyManager :   <str      > Name of the global hotkey manager as `JS` class                                          #
#   |   |   |                      [<see def.>          ]<Default> Use the pre-defined class name                                       #
#   |   |   |                      [<str>               ]          Use other names to distinguish the modules (which is unnecessary)    #
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
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] It is defined as an `active biding` method, but returns a callable, for below reasons                              #
#   |   |   |   |    [1] Expose a method that is callable while not holding the argument `self` (which is NOT accepted by `shiny`)      #
#   |   |   |   |    [2] Enable the calls to the private methods to extend its functionality                                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |id                :   <str      > ID of the created module. This is resulted from the extension by <module.ui>             #
#   |   |   |*pos              :   <tuple    > Any positional arguments for <ui.tags.div> to wrap the `label`                           #
#   |   |   |icon              :   <str      > The icon tag to the left of `label` for more visual effect                               #
#   |   |   |                      [<see def.>          ] <Default> Do not place an icon                                                #
#   |   |   |                      [<str>               ]           Can be a tag created by classes in `ui.tags`                        #
#   |   |   |class_            :   <str      > The CSS `class` to extend or overwrite the style of the button                           #
#   |   |   |                      IMPORTANT: This dedicated `class` should be of higher priority than those defined in `head` to take  #
#   |   |   |                                 effect, otherwise it is ignored by HTML                                                   #
#   |   |   |                      [<see def.>          ] <Default> Use the system default without tweak                                #
#   |   |   |                      [<str>               ]           Any valid CSS `class` that has an external definition               #
#   |   |   |displaySelection  :   <bool     > Whether to display the selected label in an additional tag of this component             #
#   |   |   |                      IMPORTANT: This instruction leads to a new tag to the right or left side of the trigger button, as   #
#   |   |   |                                 indicated by `displaySide`, so please leave sufficient room for it in the page            #
#   |   |   |                      [False               ]<Default> Suppress the display to simplify the interaction                     #
#   |   |   |                      [True                ]          Show the selected label after the front-end operation                #
#   |   |   |displaySide       :   <str      > To which side of the trigger button should the selection label is allowed to display     #
#   |   |   |                      [right               ] <Default> Display a box to the right side of the trigger button               #
#   |   |   |                      [<str>               ]           All other strings will be treated as `left`                         #
#   |   |   |**kw              :   <dict    > Any keyword arguments for <ui.tags.div> to wrap the `label`                               #
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
#   |   |   |   |[1] It is defined as an `active biding` method, but returns a callable, for below reasons                              #
#   |   |   |   |    [1] Expose a method that is callable while not holding the argument `self` (which is NOT accepted by `shiny`)      #
#   |   |   |   |    [2] Enable the calls to the private methods to extend its functionality                                            #
#   |   |   |   |[2] `input`, `output` and `session` are defined but hidden at runtime, so they are not passed as parameters during the #
#   |   |   |   |     call of the server. See examples for detailed usage                                                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |id                :   <str      > ID of the created module. This is resulted from the extension by <module.server>         #
#   |   |   |label             :   <str      > Label to show on the button                                                              #
#   |   |   |                      IMPORTANT: Indicative hotkey in it is removed when <hideHotkey=True>                                 #
#   |   |   |                      [<see def.>          ]<Default> Show the pre-defined label on the button, avoid conflict with the    #
#   |   |   |                                                       keyboard hotkeys of the web browser                                 #
#   |   |   |                      [<str>               ]          Show customizezd label on the button                                 #
#   |   |   |placeholder       :   <str      > The placeholder to show up in the <outputEL> container when all options are deselected   #
#   |   |   |                      [<see def.>          ] <Default> Use empty placeholder                                               #
#   |   |   |                      [<str>               ]           Set specific placeholder for certain instance                       #
#   |   |   |choices           :   <list     > Reactive input as certain structured input to be parsed as the valid choices for         #
#   |   |   |                       front-end operation, see Examples for the structure, and <ShinyApp.jsDropdownSelect> for the design #
#   |   |   |                      [None                ]<Default> Should be provided at the call to `server`                           #
#   |   |   |                      [<see Ex.>           ]          Provide valid structure, see the examples                            #
#   |   |   |listenPayload     :   <str      > The payload to observe, as the instruction to conduct programmatic selection             #
#   |   |   |                      [None                ]<Default> Wait for external message                                            #
#   |   |   |                      [<str>               ]          Valid `value` for making the selection at front-end                  #
#   |   |   |maxHeight         :   <int/float> The maximum height in pixel of the main panel, scroll components will be activated if it #
#   |   |   |                       is exceeded                                                                                         #
#   |   |   |                      [<see def.>          ] <Default> Set a popular height of the main panel                              #
#   |   |   |                      [<int/float>         ]           Customize the maximum height of the instances                       #
#   |   |   |minHeight         :   <int/float> The minimum height in pixel of the panels when there is no choice to display             #
#   |   |   |                      [<see def.>          ] <Default> Set a minimum height of the empty panels                            #
#   |   |   |                      [<int/float>         ]           Customize the minimum height of the instances                       #
#   |   |   |minWidth          :   <int/float> The minimum width in pixel of the panels when there is no choice to display              #
#   |   |   |                      [<see def.>          ] <Default> Set a minimum width of the empty panels                             #
#   |   |   |                      [<int/float>         ]           Customize the minimum width of the instances                        #
#   |   |   |scrollSpeed       :   <float    > The animation speed for the scroll component                                             #
#   |   |   |                      [<see def.>          ] <Default> Set a popular speed of the scroll component animation               #
#   |   |   |                      [<float>             ]           Customize the animation speed when hovering over the scroll         #
#   |   |   |                       component                                                                                           #
#   |   |   |windowGap         :   <int/float> The gap in pixel of the panels to the edge of the window viewport to avoid being hidden  #
#   |   |   |                      [<see def.>          ] <Default> Set a certain gap against the window when there is not enough room  #
#   |   |   |                      [<int/float>         ]           Customize the gap between the panels and the window edge            #
#   |   |   |submenuGap        :   <int/float> The gap in pixel between the panels to avoid visual inconvenience                        #
#   |   |   |                      [<see def.>          ] <Default> Set a certain gap between the panels, rather than squeezing them    #
#   |   |   |                       together                                                                                            #
#   |   |   |                      [<int/float>         ]           Customize the gap between the panels                                #
#   |   |   |submenuMaxHeight  :   <int/float> The maximum height in pixel of the sub panel, scroll components will be activated if it  #
#   |   |   |                       is exceeded                                                                                         #
#   |   |   |                      [<see def.>          ] <Default> Set a popular height of the sub  panel                              #
#   |   |   |                      [<int/float>         ]           Customize the maximum height of the instances                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   The selected result in the same structure as `choices`, except that it only contains the             #
#   |   |   |                      sub-structure along the choices levels to where the selected `value` is identified                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[extractFromLeaf]                                                                                                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to extract the information from the structure that is the same as `choices` or a sub-structure #
#   |   |   |   | of it                                                                                                                 #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] literally it can only extract `value` or `label` as there are no others for current design                         #
#   |   |   |   |[2] `structure` provided here can only contain one single branch from root to the deepest leaf, which is not           #
#   |   |   |   |     necessarily the deepest one in `choices`                                                                          #
#   |   |   |   |[3] Its common usage is to extract information from the selected output result, which matches above requirement        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |structure         :   <list    > The valid structure that is the same as `choices`, or its sub-structure                   #
#   |   |   |attr_             :   <str     > The dedicated attribute from the leaf to extract                                          #
#   |   |   |                      [<see def.>          ]<Default> The pre-defined attribute to extract                                 #
#   |   |   |                      [<str>               ]          Provide valid attribute that a `choice` would contain                #
#   |   |   |placeholder       :   <str     > The placeholder for output, given the structure is invalid                                #
#   |   |   |                      [<see def.>          ]<Default> Return this value when the input structure is invalid                #
#   |   |   |                      [<str>               ]          Specify another value for return when the input structure is invalid #
#   |   |   |unknown           :   <str     > The fallback for output, given the structure is not recognized                            #
#   |   |   |                      [<see def.>          ]<Default> Return this value when the input structure is not recognized         #
#   |   |   |                      [<str>               ]          Specify a fallback value for return                                  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   The selected result in the same structure as `choices`, except that it only contains the             #
#   |   |   |                      sub-structure to where the selected `value` is identified                                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[structureToDf]                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to convert the dedicated structure, which is the same as `choices` or a sub-structure of it,   #
#   |   |   |   | into a <pd.DataFrame> for further manipulation at back-end                                                            #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] It is a `staticmethod` which can be called directly from the class                                                 #
#   |   |   |   |[2] Uses tail recursion optimization to reduce the system effort. Time Complexity = O(N)                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |structure         :   <list    > The valid structure that is the same as `choices`, or its sub-structure                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<dataframe>       :   The dataframe that stores the meta information of the structure                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[dfToStructure]                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to convert the `pd.DataFrame` back to the dedicated structure and ensure that the conversion   #
#   |   |   |   | keeps all information, esp. the sequence of the groups and choices                                                    #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] It is a `staticmethod` which can be called directly from the class                                                 #
#   |   |   |   |[2] `choices == dfToStructure(structureToDf(choices))`                                                                 #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |df                :   <dataframe> The dataframe that stores the meta information of the structure                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   The valid structure that is the same as `choices`                                                    #
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
#   |   |[_prune_structure_]                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to prune the structure to only identify the selected item while fitting its shape              #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |ASSUMPTION                                                                                                             #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] DFS (Depth First Search) is implemented so the worst Time Complexity is O(N), except that it returns before        #
#   |   |   |   |     reaching the deepest node; so it has better performance                                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |structure         :   <list    > The valid structure that is the same as `choices` for pruning                             #
#   |   |   |target            :   <str     > The target value to search inside the `structure` during pruning                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<list>            :   A sub-structure that is probably in the same shape as `structure`, but may be shorter than it when   #
#   |   |   |                      the `target` is not in the deepest level                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_vfy_dup_]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to verify whether there is any duplicated `value` in the provided `choices` and raise exception#
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |df                :   <dataframe> The dataframe that stores the meta information of the structure                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This function only raise exception when necessary                                                    #
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
#   |   |   |<ui.tags.div>     :   Full collection of `headContent` along the call tree of modules till current one                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260707        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |re, pandas, inspect, shiny                                                                                                     #
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
#   |   |   |jsDropdownSelect                                                                                                           #
#   |   |   |TagsCollection                                                                                                             #
#   |   |   |parseHotkey                                                                                                                #
#   |   |   |jsHotkeyManager                                                                                                            #
#   |   |   |jsRegHotkeyWithEffect                                                                                                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |Modules                                                                                                                    #
#   |   |   |   |ns                                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #002. Constructor
    def __init__(
        self
        ,idTriggerBtn : str = 'dds_trigger'
        ,idOSTheme : str = 'os-theme-preset'
        ,ioFlagUIReady : str = 'dds_ui_ready'
        ,nsComponent : str = 'ddsmodule'
        ,nsSelResult : str = 'selected'
        ,nsPgmSel : str = 'pgm_select'
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
        self.ioFlagUIReady = ioFlagUIReady
        self.nsComponent = nsComponent
        self.nsSelResult = nsSelResult
        self.nsPgmSel = nsPgmSel
        self.nameGlobalTheme = nameGlobalTheme
        self.nameTooltipManager = nameTooltipManager
        self.instTooltipManager = instTooltipManager
        self.nameHotkeyManager = nameHotkeyManager
        self.nameHotkeyReg = nameHotkeyReg
        self.enableHotkey = enableHotkey
        self.enclosers = enclosers
        self.hideHotkey = hideHotkey
        self._choicesDf = {}
        self._reg = []
        self.options = options

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

        #800. Prepare favorite components
        self.tc = TagsCollection()

        #900. Register the `head` content along the call tree
        #[ASSUMPTION]
        #[1] One should register the `headContent` of all dependent modules here
        #[2] The `initModuleTags` of this module should always be registered at first to ensure its priority till this node
        #[3] In this design pattern, only the `headContent` of the modules that are called at top level, i.e. in the final App,
        #    will have to be injected to the beginning of the App, to be recognized at `shiny:connected` and executed inside the
        #    global environment
        initModuleTags = self._initModule_()
        self._register_(initModuleTags)

    #200. Dunder methods
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

    #410. Function to prune the structure to only identify the selected item while fitting its shape
    #[ASSUMPTION]
    #[1] 深度优先搜索 Depth-First-Search
    #    Quote: https://baike.baidu.com/item/%E6%B7%B1%E5%BA%A6%E4%BC%98%E5%85%88%E6%90%9C%E7%B4%A2/5224976
    def _prune_structure_(self, structure : list, target : str):
        '''
        从嵌套的 structure 中裁剪出只包含 target_value 路径的结构。
        structure 是分组（有 options）或选项（有 value, 可能含 children）的列表。
        返回格式与输入一致，但只保留匹配的节点及其祖先。
        '''
        if not structure or not isinstance(structure, list):
            return(None)

        for item in structure:
            # 分组节点：递归搜索 options
            if isinstance(item, dict) and 'options' in item and not item.get('value'):
                pruned_options = self._prune_structure_(item['options'], target)
                if pruned_options is not None:
                    return([{**item, 'options': pruned_options}])

            # 普通选项或含 children 的选项
            elif isinstance(item, dict):
                value = item.get('value')
                # 命中目标
                if value == target:
                    # 返回只包含当前选项（保留 children 键但为空，或直接不包含 children）
                    return([{k: v for k, v in item.items() if k != 'children' or v is None}])

                # 有子菜单，继续深入
                if 'children' in item and item['children']:
                    pruned_children = self._prune_structure_(item['children'], target)
                    if pruned_children is not None:
                        return([{**item, 'children': pruned_children}])

            # 简单字符串（兼容老格式）
            elif isinstance(item, str) and item == target:
                return([item])

        return(None)

    #420. Function extract the information from the structure
    def extractFromLeaf(
        self
        ,structure : list
        ,attr_ : str = 'label'
        ,placeholder : str = '未选择'
        ,unknown : str = '未知'
    ):
        '''递归获取选中项的 label（最深层叶子节点）'''
        if not structure:
            return(placeholder)

        # 如果是列表，遍历每个元素
        if isinstance(structure, list):
            for item in structure:
                result = self.extractFromLeaf(
                    item
                    ,attr_ = attr_
                    ,placeholder = placeholder
                    ,unknown = unknown
                )
                if result and result != placeholder:
                    return(result)
            return(placeholder)

        # 如果是分组格式 {'label': ..., 'options': [...]}
        if isinstance(structure, dict) and 'options' in structure:
            return(self.extractFromLeaf(
                structure['options']
                ,attr_ = attr_
                ,placeholder = placeholder
                ,unknown = unknown
            ))

        # 如果是普通选项 {'value': ..., 'label': ..., 'children': [...]}
        if isinstance(structure, dict):
            # 有子菜单时深入查找
            if 'children' in structure and structure['children']:
                return(self.extractFromLeaf(
                    structure['children']
                    ,attr_ = attr_
                    ,placeholder = placeholder
                    ,unknown = unknown
                ))
            # 无子菜单（或子菜单为空），则返回当前 label
            if attr_ in structure:
                return(structure[attr_])

        return(unknown)

    #450. Function to convert the structure of `choices` into `pd.DataFrame`
    @staticmethod
    def structureToDf(structure: list) -> pd.DataFrame:
        '''
        将嵌套 structure 转换为 DataFrame。
        每行记录一个选项（含 value, label, level, parent_value, path_values）。
        支持分组、多级 children。
        '''
        rows = []
        order_counter = 0
        group_id_counter = 0

        def walk(items, level=0, parent_value=None, path_values=None):
            nonlocal order_counter, group_id_counter
            if path_values is None:
                path_values = []
            for item in items:
                # 处理分组（有 options 且无 value）
                if isinstance(item, dict) and 'options' in item and not item.get('value'):
                    group_value = f'__group__{group_id_counter}__'
                    group_id_counter += 1
                    rows.append({
                        'value': group_value
                        ,'label': item['label']
                        ,'level': level
                        ,'parent_value': parent_value
                        ,'path_values': path_values + [group_value]
                        ,'order': order_counter
                        ,'is_group': True
                    })
                    order_counter += 1
                    walk(item['options'], level + 1, group_value, path_values + [group_value])
                    continue

                # 普通选项
                value = item.get('value')
                label = item.get('label', value)
                current_path = path_values + [value]
                rows.append({
                    'value': value
                    ,'label': label
                    ,'level': level
                    ,'parent_value': parent_value
                    ,'path_values': current_path
                    ,'order': order_counter
                    ,'is_group': False
                })
                order_counter += 1

                if 'children' in item and item['children']:
                    walk(item['children'], level + 1, value, current_path)

        walk(structure)
        return(pd.DataFrame(rows))

    #460. Function to convert the `pd.DataFrame` into the structure
    @staticmethod
    def dfToStructure(df: pd.DataFrame) -> list:
        '''
        将上述 DataFrame 转换回嵌套 structure。
        要求 DataFrame 至少包含：value, label, parent_value
        path_values 列可选。
        '''
        # 按 order 列排序，确保原始顺序
        df_sorted = df.sort_values('order') if 'order' in df.columns else df

        # 创建所有节点（分组与选项）
        nodes = {}
        for _, row in df_sorted.iterrows():
            if row['is_group']:
                nodes[row['value']] = {
                    'label': row['label']
                    ,'options': []
                    ,'__is_group': True
                }
            else:
                nodes[row['value']] = {
                    'value': row['value']
                    ,'label': row['label']
                    ,'children': []
                    ,'__is_group': False
                }

        # 建立父子关系
        for _, row in df_sorted.iterrows():
            value = row['value']
            parent = row.get('parent_value')
            if pd.notna(parent) and parent in nodes:
                parent_node = nodes[parent]
                if parent_node['__is_group']:
                    parent_node['options'].append(nodes[value])
                else:
                    parent_node['children'].append(nodes[value])

        # 收集顶级节点（parent_value 为空）
        top_rows = df_sorted[df_sorted['parent_value'].isna()]
        top_nodes = []
        seen = set()
        for _, row in top_rows.iterrows():
            if row['value'] not in seen:
                top_nodes.append(nodes[row['value']])
                seen.add(row['value'])

        # 清理空列表和内部标记
        def clean_node(node):
            if isinstance(node, dict):
                node.pop('__is_group', None)
                if 'children' in node:
                    if not node['children']:
                        del node['children']
                    else:
                        for child in node['children']:
                            clean_node(child)
                if 'options' in node:
                    for opt in node['options']:
                        clean_node(opt)

        result = []
        for node in top_nodes:
            clean_node(node)
            result.append(node)

        return result

    #600. Quality control methods
    def _vfy_dup_(self, df : pd.DataFrame):
        #100. Extract all records that have duplicated `value`
        val_dup = df.loc[df.duplicated('value'), 'value']
        if len(val_dup) == 0:
            return
        df_dup = df.loc[lambda x: x['value'].isin(val_dup), ['value', 'path_values']]
        msg_dup = [
            {'value' : row[0], 'path' : row[1]}
            for row in df_dup.itertuples(index = False)
        ]

        #900. Raise exception if any duplication is identified
        raise ValueError(f'[{self.__class__.__name__}]<choices> should not contain duplicated <value>! provided: {msg_dup}')

    #700. UI part
    #710. Initialization part
    #[ASSUMPTION]
    #[1] `shiny:connected` event is only triggered once upon the system boot
    #[2] So when there is a chain of nested modules, all the scripts based on `shiny:connected` in the lower-level modules
    #    will NOT be executed at the front-end (HTML protection)
    #[3] That is why we need to register all the JS scripts in the main App (i.e. top caller) rather than in the modules
    def _initModule_(self):
        #010. Local parameters
        vld_theme = self.nameGlobalTheme in OSThemesCSS.presets
        self.os_theme = self.nameGlobalTheme if vld_theme else None
        dds_classic = '' if vld_theme else '_c'
        self.event_dds_init = f'dds{dds_classic}-component-init'
        self.event_dds_destroy = f'dds{dds_classic}-component-destroy'
        js_const_theme = cleandoc(f'''
            const _ID_OSTHEME_ = '{self.idOSTheme}';
            const _OSTHEME_ = '';
        ''')

        #[ASSUMPTION]
        #[1] All below names of CSS class will be configured OUTSIDE the JS Class, i.e. in `shiny.ui`
        tags_ext = ['triggerBtn', 'outputEl', 'optionsList', 'scrollContainer', 'dropdown']

        #100. Define CSS
        #105. Retrieve the OS preset
        if vld_theme:
            css_theme = re.sub(
                '`'
                ,r'\`'
                ,textwrap.indent(getattr(OSThemesCSS, self.os_theme), ' ' * 20).strip()
            )
            js_const_theme = cleandoc(f'''
                const _ID_OSTHEME_ = '{self.idOSTheme}';
                const _OSTHEME_ = `
                    {css_theme}
                `;
            ''')

        #110. Load animations
        anim = CSSKeyframes()
        anim.load('btnClickPulse')
        css_anim = ui.head_content(ui.tags.style(anim.gather))

        #130. Adjust the OS theme to match the styles of <outputEl> and <triggerBtn>
        #[ASSUMPTION]
        #[1] Given <currOS-input> has some different position settings than <currOS-btn-explorer>, we need to adjust the
        #    class of <outputEl> with a certain new one <currOS-dds-outputEl>
        #[2] Since the OS theme is injected in delayed fashion, this injection should be conducted even later, to take higher
        #    priority than the OS presets
        os_theme_adj_css = cleandoc('''
            .currOS-dds-outputEl {
                height: var(--explorer-btn-height);
                padding: 4px 4px;
                margin: 0;
            }
        ''')
        self.os_theme_adj = os_theme_adj_css if vld_theme else None

        #150. Prepare OS theme preset
        #[ASSUMPTION]
        #[1] Below classes should only cover the styles OTHER THAN position-related ones, as they are used inside the JS
        css_os_classes = {
            'outputEl' : 'currOS-input currOS-dds-outputEl'
            ,'triggerBtn' : 'currOS-btn-explorer'
            ,'dropdown' : 'currOS-dropdown-menu'
            ,'scrollContainer' : 'currOS-dropdown-scroll-container'
            ,'optionsList' : 'currOS-dropdown-group-list'
            ,'subPanel' : 'currOS-dropdown-menu'
            ,'groupLabel' : 'currOS-dropdown-group-label'
            ,'scroll_arrow' : 'currOS-dropdown-scroll-arrow'
            ,'arrow_icon' : 'currOS-dropdown-arrow-icon'
            ,'option_separator' : 'currOS-dropdown-divider'
            ,'option_item' : 'currOS-dropdown-item'
            ,'option_indicator' : 'currOS-dropdown-indicator'
            ,'option_label' : 'currOS-dropdown-item-label'
            ,'submenu_arrow' : 'currOS-dropdown-submenu-arrow'
        }

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
                debug: {str(self.options.get('debug', 'false')).lower()}, // 可设为true查看调试日志
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

        #600. Introduce JS Dropdown Select component
        #610. Parameter to instantiate a JS Class for managing a dropdown select component
        dds_args = {
            #[ASSUMPTION]
            #[1] The only case that <funcName> is different among `shiny` Apps, is when it is requested NOT to follow OT theme
            #[2] The worst scenario in a `shiny` App is that there are two types of modules, one follows OS themes while the
            #    other does not, regardless of how many modules are called
            #[3] Hence in the worst scenario, there are only two JS scripts injected in the `shiny` App, which are differed by
            #    out preset name suffix <dds_classic>
            #[4] That is why there is no need to expose <funcName> as an argument to the <ui> function, as the user does not need
            #    to know its differentiation. The same rationale validates for all the rest parameters below.
            #[5] One exception: one module requests 'Windows' while another requests 'MacOS' in the same App.
            #    [1] It is less likely to happen unless for testing purpose, when there could be various ways to walk around
            #        such situation.
            #    [2] The catch is: there are many same CSS variables (with different values) defined in <OSThemesCSS> to simplify
            #        the configuration, so it is impossible to see the different presets at the same time.
            'funcName' : f'window.DropdownSelect{dds_classic}'
            #[ASSUMPTION]
            #[1] All below parameters only affect the JS class definition hence they should be globally unique
            #[2] Should anyone among them be different in the same session, make sure <funcName> are also different
            #    [1] Otherwise the JS class injected later will be ignored by the system (self-protection mode)
            ,'bubbleEvent' : f'dds{dds_classic}-select-change'
            ,'cssClasses' : {
                #010. Exposed classes for the wrapper itself
                'wrapper' : f'dds{dds_classic}-wrapper'
                ,'embeddedStylesId' : f'dds{dds_classic}-emb-styles'
                #100. Classes bound to the internal element/container, as named in the keys
                ,'outputEl' : f'dds{dds_classic}-selected-output'
                ,'triggerBtn' : f'dds{dds_classic}-trigger-btn'
                ,'dropdown' : f'dds{dds_classic}-dropdown-panel'
                ,'scrollContainer' : f'dds{dds_classic}-scroll-container'
                ,'optionsList' : f'dds{dds_classic}-options-list'
                ,'arrowUp' : f'dds{dds_classic}-scroll-arrow-up'
                ,'arrowDown' : f'dds{dds_classic}-scroll-arrow-down'
                ,'subPanel' : f'dds{dds_classic}-submenu-panel'
                ,'groupLabel' : f'dds{dds_classic}-option-group-label'
                #500. Classes that are internally used without being bound to certain names
                ,'scroll_arrow' : f'dds{dds_classic}-scroll-arrow'
                ,'arrow_icon' : f'dds{dds_classic}-arrow-icon'
                ,'option_separator' : f'dds{dds_classic}-option-separator'
                ,'option_item' : f'dds{dds_classic}-option-item'
                ,'option_indicator' : f'dds{dds_classic}-option-indicator'
                ,'option_label' : f'dds{dds_classic}-option-label'
                ,'submenu_arrow' : f'dds{dds_classic}-submenu-arrow'
                ,'hitarea' : f'dds{dds_classic}-hitarea'
            }
            ,'cssClassesAdd' : {
                'scrollContainer' : ''
                ,'optionsList' : ''
                ,'subPanel' : ''
                ,'groupLabel' : ''
                ,'scroll_arrow' : ''
                ,'option_separator' : ''
                ,'option_item' : ''
                ,'option_indicator' : ''
                ,'option_label' : ''
                ,'submenu_arrow' : ''
            }
            ,'maxHeight' : 600
            ,'minHeight' : 40
            ,'minWidth' : 40
            ,'scrollSpeed' : 5.5
            ,'windowGap' : 10
            ,'submenuGap' : 4
            ,'submenuMaxHeight' : 600
            ,'placeholder' : '未选择'
            ,'hotkey' : ''
        }
        dds_args['arrows'] = {
            'up' : self.tc.arrow(
                'up'
                ,class_ = dds_args['cssClasses']['arrow_icon']
            )
            ,'down' : self.tc.arrow(
                'down'
                ,class_ = dds_args['cssClasses']['arrow_icon']
            )
            ,'right' : self.tc.arrow(
                'right'
                ,class_ = dds_args['cssClasses']['arrow_icon']
                ,style = 'width: 14px; height: 14px;'
            )
            ,'left' : self.tc.arrow(
                'left'
                ,class_ = dds_args['cssClasses']['arrow_icon']
                ,style = 'width: 14px; height: 14px;'
            )
        }
        el_func_name = dds_args['funcName'].split('.')[-1]

        #620. Patch the initialization parameters for current OS
        self.dds_add_ext = {
            k : ''
            for k in css_os_classes.keys()
            if k in tags_ext
        }
        if vld_theme:
            #100. Make the modification structure the same as the original one
            dds_args_mod = {
                'cssClassesAdd' : {
                    k : v
                    for k,v in css_os_classes.items()
                    if k in dds_args['cssClassesAdd']
                }
            }

            #500. Conduct the modification to style the internal tags during the construction of the JS class
            dds_args = modifyDict(dds_args, dds_args_mod)

            #700. Prepare the modification for classes of the external tags required by the JS class
            self.dds_add_ext = {
                k : (' ' + v)
                for k,v in css_os_classes.items()
                if k in tags_ext
            }

        #660. Prepare patches to the CSS classes of the arrows
        #[ASSUMPTION]
        #[1] In the original design, the arrows have two classes in the first place
        #[2] Hence if we have to add more classes, we need to append to the last
        self.css_arrow_up = [
            dds_args['cssClasses']['scroll_arrow']
            ,dds_args['cssClasses']['arrowUp']
            ,dds_args['cssClassesAdd']['scroll_arrow'] or None
        ]
        self.css_arrow_down = [
            dds_args['cssClasses']['scroll_arrow']
            ,dds_args['cssClasses']['arrowDown']
            ,dds_args['cssClassesAdd']['scroll_arrow'] or None
        ]

        #699. Collect the final parameters and form the valid JS class definition
        self.dds_args = dds_args
        js_dds = jsDropdownSelect(**dds_args)

        #700. Prepare event listeners and handlers
        #[ASSUMPTION]
        #[1] `shiny` 会在tags的参数中把名称的下划线转成短横线，如： `output_id = 'abc'` -> `<tag output-id = 'abc'></tag>`
        #[2] 由于这里同时监听所有通过 JS Class 生成的实例，这一段脚本应当放进 <head> 并确保唯一注入（ui.head_content 自动实现哈希去重）
        #[3] 由于我们使用更 `shiny` 的做法，利用 `ui.insert_ui` 从后端注入CSS， `init_os_css` 的监听程序不再有用，仅供参考
        #710. Listener to send messages from front-end to `shiny` server
        js_sender = cleandoc(f'''
            // 监听所有下拉组件的变化事件
            $(document).on('{dds_args["bubbleEvent"]}', '.{dds_args["cssClasses"]["wrapper"]}', function(e) {{
                const shinyInputId = e.currentTarget.getAttribute('output-id');
                if (!shinyInputId) return;
                // console.log(e.detail);
                Shiny.setInputValue(shinyInputId, e.detail, {{ priority: 'event' }});
            }});
        ''')

        #730. Listener to create customized Dropdown Select component instance at runtime
        #[ASSUMPTION]
        #[1] `Shiny.addCustomMessageHandler` 中监听的事件名称有两种生成方式
        #    [1] 用模板字符串生成，示例： `{pfxListenDraw}${{shinyInputId}}`。这种方法利用 `JS` 动态解析变量
        #        [1] 经测试，变量 `pfxListenDraw` 须由参数传入给定值，而不能是 `shiny.ui` 动态生成，可能由于生成时机晚于 JS Class construction
        #    [2] 用字符串拼接生成，示例： `'{msgpfx_choices}' + shinyInputId`。这种方法利用 `Python` 动态传入变量，再由 `JS` 解析
        #        [1] 经测试，变量 `msgpfx_choices` 可以由 `shiny.ui` 动态生成，前端也能正确解析
        js_creator = cleandoc(f'''
            document.addEventListener('DOMContentLoaded', function() {{
                // 全局实例索引（同时保留在 DOM 元素上）
                window.{el_func_name}Instances = window.{el_func_name}Instances || {{}};

                Shiny.addCustomMessageHandler('{self.event_dds_init}', function(payload) {{
                    const ns = payload.ns;                  // 模块命名空间，例如 "city-"
                    const choices = payload.choices;        // 选项数据
                    const config = payload.config || {{}};  // 可包含 hotkey、maxHeight 等

                    // 查找容器（支持 data-ns 或 output-id 两种方式）
                    let container = document.querySelector('[data-ns="' + ns + '"]');
                    if (!container) {{
                        // 兼容旧版：查找 output-id 属性
                        container = document.querySelector('[output-id="' + ns + '"]');
                    }}
                    if (!container) {{
                        console.warn('{el_func_name} container not found for ns:', ns);
                        return;
                    }}

                    // 若已存在实例，更新数据（若配置变化可在此扩展，但通常只更新数据）
                    if (window.{el_func_name}Instances[ns]) {{
                        window.{el_func_name}Instances[ns].updateData(choices);
                        // 如需要更新快捷键等配置，请通过专门的配置更新方法处理
                        return;
                    }}

                    // 创建新实例，存储引用到全局和 DOM 元素
                    const instance = new {dds_args['funcName']}(container, choices, config);
                    window.{el_func_name}Instances[ns] = instance;
                    container.{el_func_name} = instance;   // 保留对 DOM 元素的引用（与旧代码兼容）

                    // 创建并绑定消息接收器，处理后端发送的程序化选择指令
                    const shinyPgmSelId = container.getAttribute('pgm-sel-id');
                    Shiny.addCustomMessageHandler(shinyPgmSelId, function(payload) {{
                        if (!payload) return;
                        container.{el_func_name}.selectByValue(payload.value);
                    }});

                    // 在上述管理器创建之后引入 OS Theme ，可确保其 CSS 的解析优先级高于管理器内置的样式
                    // [ASSUMPTION]
                    // [1] 当 `dds_classic` 非空时， `_OSTHEME_` 为空，所以以下执行中止
                    // [2] 当 `dds_classic` 为空时，由以下全局变量控制，仅执行一次
                    function injectOSTheme(theme, styleId) {{
                        if (window.__OS_Theme_Injected__) return;
                        if (!theme) return;
                        const oldEl = document.getElementById(styleId);
                        if (oldEl) {{
                            if (typeof oldEl.remove === 'function') {{
                                oldEl.remove(); // 现代浏览器
                            }} else if (oldEl.parentNode) {{
                                oldEl.parentNode.removeChild(oldEl); // IE 降级
                            }}
                        }}

                        const styleEl = document.createElement('style');
                        styleEl.id = styleId;
                        styleEl.textContent = theme;
                        document.head.appendChild(styleEl);
                        window.__OS_Theme_Injected__ = true;
                    }}
                    injectOSTheme(_OSTHEME_, _ID_OSTHEME_);
                }});

                // 可选：模块销毁清理
                Shiny.addCustomMessageHandler('{self.event_dds_destroy}', function(payload) {{
                    const ns = payload.ns;
                    if (window.{el_func_name}Instances[ns]) {{
                        window.{el_func_name}Instances[ns].dispose();
                        delete window.{el_func_name}Instances[ns];
                        // 同时清理 DOM 属性
                        let container = document.querySelector('[data-ns="' + ns + '"]');
                        if (!container) {{
                            // 兼容旧版：查找 output-id 属性
                            container = document.querySelector('[output-id="' + ns + '"]');
                        }}
                        if (container) delete container.{el_func_name};
                    }}
                }});
            }});
        ''')

        #999. Render UI
        #[ASSUMPTION]
        #[1] It is tested that `ui.head_content` will remove the same input within a multi-instance `shiny` session
        #    (while HTML itself will not do so)
        #[2] This happens when ALL tags included in `ui.head_content`, so make sure each call of `ui.head_content` contains
        #    unique input
        init_tags_final = [
            #000. 注入全局唯一的各种脚本（须全部都唯一才能在这里统一注入）
            #[ASSUMPTION]
            #[1] 注入顺序至关重要，请参阅 HTML 中脚本执行和样式应用的优先级文档
            #050. 依赖项为全局 tooltip 管理器
            #[ASSUMPTION]
            #[1] 后续需要用 OS theme 覆盖部分 TTM 样式，因此先注入 TTM
            tooltipManager
            ,ui.head_content(
                ui.tags.script(js_ttMgr)
            )
            ,ui.head_content(
                ui.tags.style(css_ttm)
            )
            #100. 下拉框组件
            #110. 下拉框组件的定义。注意全局同时存在两种定义：follow OS theme 和 no OS theme ；因此这里单独注入
            ,ui.head_content(
                ui.tags.script(js_dds)
            )
            #120. 判断是否注入主题样式
            ,ui.head_content(
                ui.tags.script(js_const_theme)
            )
            #130. 定义 `shiny` 前后端通信的发送器和接收器
            #[ASSUMPTION]
            #[1] 接收器在组件创建时根据实例动态创建，否则无法在全局定位组件进而绑定可接收的消息
            #[2] 发送器是组件冒泡事件，因此直接在全局定义即可，无须绑定组件
            ,ui.head_content(
                ui.tags.script(js_sender)
            )
            #190. 创建下拉框组件的脚本
            #[ASSUMPTION]
            #[1] 由于我们改造成每个module生成带 `ns` 的事件名，以下代码每次都会不同，因此单独注入
            ,ui.head_content(
                ui.tags.script(js_creator)
            )
            #400. 全局快捷键管理器
            ,css_anim
            ,hotkeyManager
            ,ui.head_content(ui.tags.script(js_hotkeyMgr))
        ]

        return(init_tags_final)

    #750. Static part
    @property
    def ui(self):
        @module.ui
        def wrapper(
            *pos
            ,icon : ui.HTML = None
            ,class_ : str = ''
            ,displaySelection : bool = False
            ,displaySide : str = 'right'
            ,dynamicUI : bool = False
            ,**kw
        ):
            #010. Local parameters
            idTriggerBtn = ns(self.idTriggerBtn)
            ioFlagUIReady = ns(self.ioFlagUIReady)
            selected_output_id = ns(self.nsSelResult)
            pgm_select_id = ns(self.nsPgmSel)
            dds_component = ns(self.nsComponent)

            if not isinstance(displaySide, str):
                displaySide = 'right'
            displaySide = displaySide.lower()
            flex_dir = '' if displaySide == 'right' else '-reverse'

            #800. Prepare JS injection for current session, indicating that the `UI` is ready
            #[ASSUMPTION]
            #[1] We have to delay the initialization of `server`, for the data transmition depends on the `UI` to exist in the
            #    first place. The best way is to inform `server` that the `UI` is created and ready to receive data
            if dynamicUI:
                js_snippet = cleandoc(f'''
                    Shiny.setInputValue('{ioFlagUIReady}', true, {{ priority: 'event' }});
                ''')
            else:
                js_snippet = cleandoc(f'''
                    setTimeout(function() {{
                        Shiny.setInputValue('{ioFlagUIReady}', true, {{ priority: 'event' }});
                    }}, 100);
                ''')

            #999. Render UI
            #[ASSUMPTION]
            #[1] It is tested that `ui.head_content` will remove the same input within a multi-instance `shiny` session
            #    (while HTML itself will not do so)
            #[2] This happens when ALL tags included in `ui.head_content`, so make sure each call of `ui.head_content` contains
            #    unique input
            ui_tags_final = ui.tags.div(
                #100. 注入全局唯一的各种脚本（须全部都唯一才能在这里统一注入）
                #[ASSUMPTION]
                #[1] 由于多级 module 存在时，`shiny:connected` 事件不会多次执行，现将注入部分剥离出去，见 `_initModule_` 的用法
                #500. 启动时可见的部分
                #[ASSUMPTION]
                #[1] 以下各tags的id只在JS内部流转，用于接收已选择的子项信息，因此可以不用ns交给后端
                #[2] 触发按钮需要动态设置快捷键，因此须用ns交给后端监听
                ui.tags.div(
                    ui.tags.button(
                        ui.tags.div(
                            icon
                            ,ui.tags.div(ui.output_ui('tiggerBtn_label'), *pos, **kw)
                            ,self.tc.arrow(
                                'down'
                                ,style = 'width: 10px; height: 10px; margin-top: 4px;'
                            )
                            ,style = 'display: flex; flex-direction: row;'
                        )
                        ,id = idTriggerBtn
                        ,class_ = (
                            self.dds_args['cssClasses']['triggerBtn']
                            + self.dds_add_ext['triggerBtn']
                            + (f' {class_}' if class_ else '')
                        )
                        # ,aria_label = '打开下拉列表'
                    )
                    ,ui.tags.span(
                        ui.output_ui('selected_placeholder')
                        ,id = 'selected-output'
                        ,class_ = self.dds_args['cssClasses']['outputEl'] + self.dds_add_ext['outputEl'] + ' placeholder'
                        ,style = ('' if displaySelection else 'display: none;')
                    )
                    ,style = f'display: flex; flex-direction: row{flex_dir};'
                )
                #500. 启动时隐藏的部分（下拉框主菜单），布局结构不可改动
                ,ui.tags.div(
                    ui.tags.div(
                        self.dds_args['arrows']['up']
                        ,id = 'arrow-up'
                        ,class_ = ' '.join([s for s in self.css_arrow_up if isinstance(s, str)])
                    )
                    ,ui.tags.div(
                        ui.tags.ul(
                            id = 'options-list'
                            ,class_ = self.dds_args['cssClasses']['optionsList'] + self.dds_add_ext['optionsList']
                        )
                        ,id = 'scroll-container'
                        ,class_ = self.dds_args['cssClasses']['scrollContainer'] + self.dds_add_ext['scrollContainer']
                    )
                    ,ui.tags.div(
                        self.dds_args['arrows']['down']
                        ,id = 'arrow-down'
                        ,class_ = ' '.join([s for s in self.css_arrow_down if isinstance(s, str)])
                    )
                    ,id = 'dropdown'
                    ,class_ = self.dds_args['cssClasses']['dropdown'] + self.dds_add_ext['dropdown']
                )
                #700. `UI` 绘制完成后通知后端 `server` 发送创建 Dropdown 组件的指令
                #[ASSUMPTION]
                #[1] `server` 不能先发送创建组件的指令，否则找不到容器
                ,ui.tags.script(js_snippet)
                #800. 关键识别码
                #801. 在 `shiny.ui.tags` 中的各组件均不会自动在 session 内为 `id` 加上 namespace ，因此我们自行补全
                ,id = ns('ddselect')
                #810. 这里的 `class` 是 JS Class 必需的名称，用于封装整个组件
                ,class_ = self.dds_args['cssClasses']['wrapper']
                #830. 传递命名空间，JS 读取；须保证全局唯一，故使用 `ns` 操作。注意 `shiny` 会自动将 `output_id` 转为 `output-id`
                ,output_id = selected_output_id
                ,pgm_sel_id = pgm_select_id
                ,data_ns = dds_component
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
            ,label : reactive.Value[str | ui.HTML] = reactive.value(None)
            ,placeholder : reactive.Value[str] = reactive.value('未选择')
            ,choices : reactive.Value[list] = reactive.value([])
            ,listenPayload : reactive.Value[str] = reactive.value(None)
            ,maxHeight : int | float = 600
            ,minHeight : int | float = 40
            ,minWidth : int | float = 40
            ,scrollSpeed : float = 5.5
            ,windowGap : int | float = 10
            ,submenuGap : int | float = 4
            ,submenuMaxHeight : int | float = 600
        ):
            #050. Local parameters
            idTriggerBtn = session.ns(self.idTriggerBtn)
            display_label = reactive.value(None)
            hotkey = reactive.value(None)
            hotkey_registered = None
            selected_result = reactive.value(None)
            choices_df_name = session.ns('choicesDf')
            dds_component = session.ns(self.nsComponent)
            dds_component_ready = reactive.value(False)
            pgm_select_id = session.ns(self.nsPgmSel)

            #[ASSUMPTION]
            #[1] Support for hotkey of trigger button
            @reactive.effect
            def _prep_label():
                lcl_label = label()
                display_label.set(lcl_label)
                if self.enableHotkey:
                    display, tmphotkey = parseHotkey(lcl_label, enclosers = self.enclosers)
                    if tmphotkey is None:
                        hotkey.set('')
                    else:
                        hotkey.set(tmphotkey)
                    if self.hideHotkey:
                        display_label.set(display)

            #200. Helper functions

            #300. Send the choices once `server` is initialized
            @reactive.effect
            async def _send_choices():
                #001. Skip if `UI` is not ready
                if not input[self.ioFlagUIReady]():
                    return

                data = choices()
                if data is None:
                    return
                if not data:
                    return

                #100. Store the choices data for internal processes
                self._choicesDf[choices_df_name] = self.structureToDf(data)

                #109. Ensure there is no duplicated `value`
                self._vfy_dup_(self._choicesDf[choices_df_name])

                #900. Send the instruction for front-end to establish the component
                # 通过自定义消息发送给客户端 JS
                #[ASSUMPTION]
                #[1] We have to disable the internal hotkey, as we introduced a global hotkey manager
                config = {
                    'maxHeight' : maxHeight
                    ,'minHeight' : minHeight
                    ,'minWidth' : minWidth
                    ,'scrollSpeed' : scrollSpeed
                    ,'windowGap' : windowGap
                    ,'submenuGap' : submenuGap
                    ,'submenuMaxHeight' : submenuMaxHeight
                    ,'placeholder' : placeholder()
                    ,'hotkey' : ''
                }
                await session.send_custom_message(
                    self.event_dds_init,
                    {'ns': dds_component, 'choices': data, 'config': config}
                )

                #990. Clean-up
                #[ASSUMPTION]
                #[1] We conduct the injection of OS theme to a separate step, so make the process more specific and focusing
                dds_component_ready.set(True)

            #320. Inject the OS theme when necessary
            #[ASSUMPTION]
            #[1] The reactive events observed here will not change in the session for the same module, hence literally below
            #    reactive effect only works once in a lifetime
            #[2] We do not set this process in `ui` part, it is because that the injection sequence is as below
            #    [1] At the call to `ui`, it injects all static scripts and styles into the DOM tree, and if we inject the OS theme
            #        at this step, all next injections will have higher priority at style rendering
            #    [2] At the `server` initialization, `_send_choices` is executed while the reactive value `choices` it is observing
            #        is provided at the function call
            #    [3] The dedicated `Shiny.addCustomMessageHandler` is triggered thereafter to construct the JS component, which
            #        injects the embedded CSS at the end of `head`
            #    [4] We can inject the OS theme now to make higher priority than the previous. So we do two things here in line
            #        [1] Use `Shiny.setInputValue` to send a message from front-end (set a timeout to wait until the session is ready),
            #            indicating whether which OS theme is allowed to inject. Note: wherever this JS statement is placed in DOM,
            #            it will always execute AFTER the JS component construction, as that event is triggered at the call to `server`
            #        [2] Observe above indication thereafter and send another message back to front-end, instructing the JS listener
            #            to conduct the injection
            #            [1] Changed: now use `ui.insert_ui` to simplify the injection
            @reactive.effect
            def _inject_theme():
                #010. Determination
                #[ASSUMPTION]
                #[1] This function will skip at the call to `server`, since below reactive value is `False`
                #[2] Only after the first batch of `choices` is sent to the front-end, will this function be ready to execute, as
                #    below reactive value is changed to `True` at that step
                #[3] Even if there are other batches of `choices` are sent to the front-end in the future, this function will not
                #    execute again as below reactive value stays as `True` and there is no more reactive effect to trigger
                if not dds_component_ready():
                    return

                #300. Prepare adjustment of the output part
                os_theme_adj_css = self.os_theme_adj

                #900. Injection
                ui.insert_ui(
                    ui.head_content(ui.tags.style(os_theme_adj_css))
                    ,selector = 'head'
                    ,where = 'beforeEnd'
                )

            #400. Render dynamic `ui`
            #410. Render label of trigger button at runtime
            @output
            @render.ui
            def tiggerBtn_label():
                nonlocal hotkey_registered
                lcl_label = display_label()
                lcl_hotkey = hotkey()
                lcl_hotkey_registered = hotkey_registered
                el_func_name = self.dds_args['funcName'].split('.')[-1]

                #100. Prepare the manipulation of the trigger button
                js_toggle = cleandoc(f'''
                    let container = document.querySelector('[data-ns="{dds_component}"]');
                    if (!container) {{
                        // 兼容旧版：查找 output-id 属性
                        container = document.querySelector('[output-id="{dds_component}"]');
                    }}
                    const dds = container.{el_func_name};
                    dds.toggle();
                    // 需要focus在按钮上，这样下拉框组件默认的键盘事件才会与鼠标点击按钮时保持一致
                    btn.focus();
                ''')

                #300. Prepare the script to register/unregister the hotkey for the trigger button
                js_snippet = jsRegHotkeyWithEffect(
                    selector = '#' + idTriggerBtn
                    ,register = lcl_hotkey
                    ,unregister = lcl_hotkey_registered
                    ,funcName = 'regHotkey_' + re.sub(r'\W', '_', idTriggerBtn)
                    ,addTooltip = self.hideHotkey
                    ,instTooltipManager = self.instTooltipManager
                    ,instHotkeyManager = self.options[self.nameHotkeyManager]['instHotkeyManager']
                    ,elName = 'btn'
                    ,runScript = js_toggle
                    #[ASSUMPTION]
                    #[1] See below classes in `Styles.OSThemesCSS`
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

            #420. Render placeholder of the embedded text output at runtime
            @output
            @render.ui
            def selected_placeholder():
                return(ui.div(placeholder()))

            #600. Conduct programmatic selection when receiving external message
            @reactive.effect
            async def _pgm_selection():
                #001. Skip if `UI` is not ready
                if not input[self.ioFlagUIReady]():
                    return

                value = listenPayload()
                if not isinstance(value, str):
                    return
                if value == '':
                    return
                if not self._choicesDf[choices_df_name]['value'].eq(value).any():
                    print(
                        f'[{self.__class__.__name__}]<listenPayload> provided value that is not in scope hence is skipped.'
                        + f' Provided: {value}'
                    )
                    return
                await session.send_custom_message(
                    pgm_select_id
                    ,{'value' : value.strip()}
                )

            #800. Observe the interactive selection made at front-end and collect the result
            #[ASSUMPTION]
            #[1] 监听客户端选择事件（JS 通过 Shiny.setInputValue 发送）
            @reactive.effect
            def _observe_selection():
                sel = input[self.nsSelResult]()
                if sel is None:
                    return
                value = sel.get('value')
                # label = sel.get('label')
                # 根据结构裁剪出只包含选中项的分支
                full = choices()
                if full is None:
                    selected_result.set(None)
                    return
                pruned = self._prune_structure_(full, value)
                selected_result.set(pruned)

            #998. 模块销毁时清理客户端实例（可选）
            @session.on_ended
            async def _destroy_dds():
                await session.send_custom_message(
                    self.event_dds_destroy
                    ,{'ns': dds_component}
                )

            return(selected_result)

        return(wrapper)

#End DropdownSelect

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import os
    import re
    import shutil
    import sys
    import textwrap
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
            :root {
                --border: #d9dde3;
                --border-focus: #4a90d9;
                --radius: 10px;
            }

            .demo-container {
                border-radius: 20px;
                padding: 36px 32px;
                max-width: 640px;
                width: 100%;
                display: flex;
                flex-direction: column;
                gap: 32px;
            }

            .select-control {
                display: flex;
                flex-direction: row;
                align-items: center;
                gap: 10px;
                background-color: var(--bg-primary);
                border: 1.5px solid var(--border);
                border-radius: var(--radius);
                padding: 4px 4px 4px 14px;
                transition: border-color 180ms, box-shadow 180ms;
                cursor: default;
            }
            .select-control:focus-within {
                border-color: var(--border-focus);
            }

            .operation-icon {
                color: var(--text-secondary);
                /*
                display: inline-block;
                */
                width: 20px;
                height: 20px;
                line-height: 20px;
                text-align: center;
            }
            .icon-group {
                margin-top: 0;
            }
            .icon-group::before {
                content: '⊞';
            }

            .card {
                background-color: var(--bg-primary);
                color: var(--text-primary);
            }

            /* 需要显示选择结果时，这样注入能使显示框自动填满父容器 */
            .select-control .dds-wrapper {
                width: 100%;
            }
        """.strip()
    )
    to_esc_ch_city = textwrap.indent(
        """
            [
                {
                    'label': '🌍 一线城市'
                    ,'options': [
                        {'value': 'bj', 'label': '北京'}
                        ,{'value': 'sh', 'label': '上海'}
                        ,{'value': 'gz', 'label': '广州'}
                        ,{
                            'value': 'sz'
                            ,'label': '深圳'
                            ,'children': [
                                {
                                    'label' : '城区一'
                                    ,'options' : [
                                        {'value': 'sz_ns', 'label': '南山区'}
                                        ,{
                                            'value': 'sz_ft'
                                            ,'label': '福田区'
                                            ,'children': [
                                                {'value': 'sz_ft_dist1', 'label': '小区一'}
                                                ,{'value': 'sz_ft_dist2', 'label': '小区二'}
                                            ]
                                        }
                                        ,{'value': 'sz_lg', 'label': '龙岗区'}
                                    ]
                                }
                                ,{
                                    'label' : '城区二'
                                    ,'options' : [
                                        {'value': 'sz_lh', 'label': '罗湖区'}
                                        ,{'value': 'sz_yt', 'label': '盐田区'}
                                        ,{'value': 'sz_ba', 'label': '宝安区'}
                                    ]
                                }
                            ]
                        }
                    ]
                }
                ,{
                    'label': '🏙️ 新一线城市'
                    ,'options': [
                        {'value': 'cd', 'label': '成都'}
                        ,{'value': 'hz', 'label': '杭州'}
                        ,{'value': 'wh', 'label': '武汉'}
                        ,{
                            'value': 'nj'
                            ,'label': '南京'
                            ,'children': [
                                {'value': 'nj_xw', 'label': '玄武区'}
                                ,{'value': 'nj_gl', 'label': '鼓楼区'}
                                ,{'value': 'nj_jn', 'label': '江宁区'}
                            ]
                        }
                    ]
                }
                ,{
                    'label': '🏛️ 历史文化名城'
                    ,'options': [
                        {'value': 'xa', 'label': '西安'}
                        ,{'value': 'lz', 'label': '兰州'}
                        ,{'value': 'ty', 'label': '太原'}
                    ]
                }
            ]
        """.strip()
        ,' ' * 4
    ).lstrip(' ' * 4)
    to_esc_ch_fruit = textwrap.indent(
        """
            [
                {
                    'value': 'apple'
                    ,'label': '苹果'
                    ,'children': [
                        {
                            'value': 'apple_fuji'
                            ,'label': '富士'
                            ,'children': [
                                {'value': 'apple_fuji_shaanxi', 'label': '陕西红富士'}
                                ,{'value': 'apple_fuji_xinjiang', 'label': '新疆红富士'}
                                ,{'value': 'apple_fuji_shandong', 'label': '山东红富士'}
                            ]
                        }
                        ,{'value': 'apple_gala', 'label': '嘎啦'}
                    ]
                }
                ,{'value': 'banana', 'label': '香蕉'}
                ,{'value': 'orange', 'label': '橙子'}
                ,{'value': 'grape', 'label': '葡萄'}
                ,{'value': 'mango', 'label': '芒果'}
                ,{'value': 'berry', 'label': '蓝莓'}
                ,{'value': 'peach', 'label': '蜜桃'}
                ,{'value': 'melon', 'label': '哈密瓜'}
            ]
        """.strip()
        ,' ' * 4
    ).lstrip(' ' * 4)
    to_esc_cont_style = textwrap.indent(
        """
            .shiny-input-container {
                display: inline-flex;
                gap: 8px;
            }
            .shiny-input-container .control-label {
                white-space: nowrap;
                height: 1.5rem;
                font-size: var(--font-m);
                margin-top: 4px;
            }
            #test_value_input {
                height: 2rem;
                margin-top: 0;
                margin-bottom: 0;
            }
        """.strip()
        ,' ' * 16
    ).lstrip(' ' * 16)
    to_esc_cont_js = textwrap.indent(
        """
            shiny_input = document.getElementById('test_value_input');
            shiny_input.classList.add('currOS-input');
        """.strip()
        ,' ' * 16
    ).lstrip(' ' * 16)
    multi_quotes = '"""'

    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import sys
        from shiny import App, ui, render, reactive
        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )
        from omniPy.ShinyApp.Modules import DropdownSelect

        #[ASSUMPTION]
        #[1] We only need one instance to create different modules in one App
        #[2] The segregation is done by setting `module ID` at runtime
        dds_city = DropdownSelect(
            nameGlobalTheme = 'Windows'
        )
        dds_fruit = DropdownSelect(
            # nameGlobalTheme = 'other'
        )

        custom_css = {multi_quotes}
            {to_esc_css}
        {multi_quotes}

        # ==================================================
        # 示例数据准备与工具函数
        # ==================================================
        def build_city_structure():
            {multi_quotes}返回城市分组及子菜单的结构字典{multi_quotes}
            return(
                {to_esc_ch_city}
            )

        def build_fruit_structure():
            return(
                {to_esc_ch_fruit}
            )

        def highlight_selected(df, selected_value):
            {multi_quotes}在 DataFrame 中标记选中的行（用于前端表格高亮）{multi_quotes}
            df = df.copy()
            df['_selected'] = df['value'] == selected_value
            return(df)

        # ==================================================
        # 主应用 UI
        # ==================================================
        app_ui = ui.page_fillable(
            ui.tags.head(ui.tags.style(custom_css))
            ,ui.tags.div(*dds_city.headContent) if dds_city.headContent else None
            ,ui.tags.div(*dds_fruit.headContent) if dds_fruit.headContent else None
            ,ui.h2('Shiny 模块化下拉选择示例', class_='demo-title')
            ,ui.row(
                ui.column(6
                    ,ui.card(
                        ui.h4('城市选择（分组 + 子菜单）')
                        ,ui.tags.div(
                            dds_city.ui(
                                'city'
                                ,icon = ui.tags.div(class_='operation-icon icon-group')
                                ,displaySelection = True
                            )
                            ,class_ = 'select-control'
                        )
                        ,ui.tags.span(
                            ui.output_text('city_selected_label')
                        )
                    )
                )
                ,ui.column(6
                    ,ui.card(
                        ui.h4('水果选择（简单列表 + 子菜单）')
                        ,ui.tags.div(
                            dds_fruit.ui(
                                'fruit'
                                ,displaySelection = True
                                ,displaySide = 'left'
                            )
                            ,class_ = 'select-control'
                        )
                        ,ui.tags.span(
                            ui.output_text('fruit_selected_label')
                        )
                    )
                )
            )
            ,ui.row(
                ui.column(6
                    ,ui.row(
                        ui.tags.style({multi_quotes}
                            {to_esc_cont_style}
                        {multi_quotes})
                        ,ui.input_text(
                            'test_value_input'
                            ,'输入 value 值'
                        )
                        ,ui.tags.script({multi_quotes}
                            {to_esc_cont_js}
                        {multi_quotes})
                        ,ui.input_action_button(
                            'test_select_btn'
                            ,'程序化选中'
                            ,class_ = 'currOS-btn'
                            ,style = 'width: 100px; padding: 0 12px; height: 2rem; margin: 0;'
                        )
                    )
                )
            )
            ,ui.row(
                ui.column(12
                    ,ui.card(
                        ui.h4('选项数据表格（城市）')
                        ,ui.output_table('city_table')
                    )
                )
            )
        )

        # ==================================================
        # 主应用 Server
        # ==================================================
        def server(input, output, session):
            # 创建 reactive 结构（模拟从后端 API 获取）
            city_structure = reactive.value(build_city_structure())
            fruit_structure = reactive.value(build_fruit_structure())
            city_pgm_select = reactive.value(None)
            city_label = reactive.value('City')
            fruit_label = reactive.value('Fruit (ctrl+alt+F)')

            # 调用模块
            city_selection = dds_city.server(
                'city'
                ,label = city_label
                ,choices = city_structure
                ,listenPayload = city_pgm_select
                ,maxHeight = 400
            )
            fruit_selection = dds_fruit.server(
                'fruit'
                ,label = fruit_label
                ,choices = fruit_structure
            )

            @reactive.effect
            @reactive.event(input.test_select_btn)
            def _city_selection():
                city_pgm_select.set(input.test_value_input())

            # 显示选中的标签
            @output
            @render.text
            def city_selected_label():
                sel = city_selection()
                if sel is None:
                    return('未选择城市')
                # 从裁剪后的结构中提取标签
                return(dds_city.extractFromLeaf(sel, attr_ = 'label'))

            @output
            @render.text
            def fruit_selected_label():
                sel = fruit_selection()
                if sel is None:
                    return('未选择水果')
                # 类似提取
                return('已选')  # 简化

            # 城市数据表格
            @output
            @render.table
            def city_table():
                df = dds_city.structureToDf(build_city_structure())
                # 高亮选中行
                sel = city_selection()
                if sel is not None:
                    # 获取选中的 value
                    selected_value = dds_city.extractFromLeaf(sel, attr_ = 'value')
                    df = highlight_selected(df, selected_value)
                # 生成表格，高亮列
                return(df)

        # ==================================================
        # 创建 App
        # ==================================================
        app = App(app_ui, server, static_assets={{}})
        if __name__ == '__main__':
            app.run()
    """)

    #380. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #370. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App
    #[03] Click the button <'City'> and select one from the choices in any among the different levels of panels
    #[04] The selected result shows in two places
    #    [1] The box to the right of the trigger button, which is the embedded component of the module
    #    [2] The text output to the bottom of the trigger button, which captures the return value of the module server
    #    [3] The table at the bottom of the page now contains an extra column `_selected`, which indicates that the row
    #        with `value` equals to the selection is marked as `True`
    #[05] Type `sz_ns` in the input box in the middle of the page and click the button `程序化选中`
    #[06] The results in step [04] now becomes '南山区', echoing the programmatic selection
    #[07] A simpler dropdown component on the right side of the page can also be tested, which indicates that the modules
    #     are well segregated
    #    [1] This dropdown component allows hotkey, so try to press the indicated hotkey combination to resemble the click
    #[08] Close the test page in the web browser
    #[09] Close the command console as popped up when executing the BAT file

    #390. Clean the slate
    #[ASSUMPTION]
    #[1] Below action will NOT remove its parent folders
    shutil.rmtree(dst_dir, ignore_errors = True)

#-Notes- -End-
'''
