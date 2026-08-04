#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
from inspect import cleandoc
from typing import Optional
from omniPy.ShinyApp import TagsCollection

def jsDropdownSelect(
    funcName : str = 'window.DropdownSelect'
    ,bubbleEvent : str = 'dds-select-change'
    ,cssClasses : dict[str, str] = {
        #010. Exposed classes for the wrapper itself
        'wrapper' : 'dds-wrapper'
        ,'embeddedStylesId' : 'dds-emb-styles'
        #100. Classes bound to the internal element/container, as named in the keys
        ,'outputEl' : 'dds-selected-output'
        ,'triggerBtn' : 'dds-trigger-btn'
        ,'dropdown' : 'dds-dropdown-panel'
        ,'scrollContainer' : 'dds-scroll-container'
        ,'optionsList' : 'dds-options-list'
        ,'arrowUp' : 'dds-scroll-arrow-up'
        ,'arrowDown' : 'dds-scroll-arrow-down'
        ,'subPanel' : 'dds-submenu-panel'
        ,'groupLabel' : 'dds-option-group-label'
        #500. Classes that are internally used without being bound to certain names
        ,'scroll_arrow' : 'dds-scroll-arrow'
        ,'arrow_icon' : 'dds-arrow-icon'
        ,'option_separator' : 'dds-option-separator'
        ,'option_item' : 'dds-option-item'
        ,'option_indicator' : 'dds-option-indicator'
        ,'option_label' : 'dds-option-label'
        ,'submenu_arrow' : 'dds-submenu-arrow'
        ,'hitarea' : 'dds-hitarea'
    }
    ,cssClassesAdd : Optional[dict[str, str]] = {
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
    ,maxHeight : int | float = 600
    ,minHeight : int | float = 40
    ,minWidth : int | float = 40
    ,scrollSpeed : float = 5.5
    ,windowGap : int | float = 10
    ,submenuGap : int | float = 4
    ,submenuMaxHeight : int | float = 600
    ,placeholder : str = ''
    ,hotkey : str = ''
    ,arrows : Optional[dict[str, str]] = None
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the HTML front end, NOT necessarily inside `shiny` app, to setup a  #
#   | class for instantiating various Dropdown Select components                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |FEATURE                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ 1] Draw a dropdown select component, possibly with multiple levels, for user to conduct a single selection                       #
#   |[ 2] All panels/sub-panels are able to scroll if the space required by the items exceeds the limit, without the original system    #
#   |     scroll bar, but more similar to the style of dropdown component in Google Chrome                                              #
#   |[ 3] Certain Group Label and Group Separator will show up to split the selection area in the specific panels, with certain pattern #
#   |     of data provision during the setup, see examples for detailed explanation of data layout requirement. See also the real case  #
#   |     in the example of <ShinApp.Modules.DropdownSelect> for the detailed data layout implementation                                #
#   |[ 4] Trigger is a single button with certain set of tags, see examples for the complete HTML tags preparation                      #
#   |[ 5] Keyboard actions are supported, effective keys are as below                                                                   #
#   |     [Space/Enter] Trigger the button, or select current item and close the component                                              #
#   |     [ArrowUp/ArrowDown/ArrowLeft/ArrowRight] Navigate inside and between the panels/sub-panels                                    #
#   |       [Note] When `ArrowRight` to enter a sub-panel, no item will be automatically focused to avoid mis-actions; hence if the     #
#   |              first item inside a sub-panel is selected BEFORE entering with `ArrowRight`, it is also NOT focused to maintain the  #
#   |              consistency of operation. One needs to `ArrowDown` or `ArrowUp` to focus an item for further operations at all times #
#   |     [Escape] Hit once to return to the main panel of the dropdown component; hit for the second time to close the main panel      #
#   |     [Tab] Navigate outside the component, just like the default behavior of webpage navigation                                    #
#   |[ 6] Touchpad operations are also supported                                                                                        #
#   |[ 7] All styles used inside the component are self-contained without external dependency                                           #
#   |[ 8] CSS classes of all internal tags can be tweaked by adding new classes separately, for drawing completely different panels     #
#   |[ 9] Only one main panel is allowed to popup given there are many components created by this class at the same time, to ensure the #
#   |     segregation of operations on the webpage                                                                                      #
#   |[10] A safeguard method `dispose()` is also defined for easy removal of the component with efficient resources clean-up            #
#   |[11] `Python` Name and classes can be customized to draw completely different components with proper segregation                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |API                                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[input choices] <updateData   > method to receive new choices and update the panels. Arguments are as below                        #
#   |                [choices             ] Choices mapping in the same structure as <choices> defined in the constructor               #
#   |[input select ] <selectByValue> method to receive instruction of making certain selection directly from backend. Arguments are     #
#   |                [value               ] The value to make programmatic selection, should be unique within <choices>                 #
#   |[output       ] Expose a bubble-up CustomEvent message for external usage, with its id indicated in the argument <bubbleEvent>; so #
#   |                the message channel can be customized.                                                                             #
#   |                [<return>            ] <{value:'...',label:'...'}> indicating the selection result                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This JS class is designed with self protection from being defined more than once in the session, hence its <funcName> should be#
#   |    a valid name that can be recognized as global object, e.g. attached to `window` as an attribute                                #
#   |[2] Even with self-embedding styles, the modification of styles can also affect all components created by this class in the same   #
#   |    session. A better way as workaround is to use it in `shiny` App with complete customization, see instructions in Examples      #
#   |[3] If one needs to extend or overwrite the self-embedded CSS, the injection should be conducted AFTER the construction of the     #
#   |    first instance of this class, otherwise the external CSS would be of lower priority during rendering                           #
#   |[4] All necessary tags should be wrapped by a single division for this class to work, see Examples for the complete structure      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Draw a modern dropdown select component in the web App that supports multi-layer choices, with shiny interactive effects       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Arguments in the injected JS function]                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[wrapper         ] HTML tag object that wraps all the necessary tags for this class to recognize and manipulate                    #
#   |[choices         ] Certain JS structure of the choices data, to render all panels in the component. `value` inside this structure  #
#   |                   should be unique in scope, otherwise the result is unexpected                                                   #
#   |[config          ] More customization to the instance, including below arguments                                                   #
#   |  [maxHeight       ] <Number > The maximum height in pixel of the main panel, scroll components will be activated if it is exceeded#
#   |  [minHeight       ] <Number > The minimum height in pixel of the panels when there is no choice to display                        #
#   |  [minWidth        ] <Number > The minimum width in pixel of the panels when there is no choice to display                         #
#   |  [scrollSpeed     ] <Number > The animation speed for the scroll component                                                        #
#   |  [windowGap       ] <Number > The gap in pixel of the panels to the edge of the window viewport to avoid being hidden             #
#   |  [submenuGap      ] <Number > The gap in pixel between the panels to avoid visual inconvenience                                   #
#   |  [submenuMaxHeight] <Number > The maximum height in pixel of the sub-panels, scroll components will be activated if it is exceeded#
#   |  [placeholder     ] <String > The placeholder to show up in the <outputEL> container when all options are deselected              #
#   |  [hotkey          ] <String > The hotkey to operate on trigger button, which resembles the click event on it                      #
#   |  [arrows          ] <Object > Collection of strings that represent the HTML arrows for directive operations as well as inside the #
#   |                               scroll components                                                                                   #
#   |  [cssClassesAdd   ] <Object > Collection of strings that represent the additional CSS classes to be appended to the internal tags #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |funcName          :   <str      > Customize the JS function name to setup more than one universal function in the console          #
#   |                      [<see def.>          ] <Default> Use a universal function name to be in use for the whole web page           #
#   |                      [<str>               ]           Set different function names to test the functionality                      #
#   |bubbleEvent       :   <str      > The event name for external monitoring of the user final selection in the choices                #
#   |                      [<see def.>          ] <Default> Use a universal name to be monitored by external functions                  #
#   |                      [<str>               ]           Set it as unique in the session for accurate monitoring                     #
#   |cssClasses        :   <dict     > dict of CSS classes for internal calculation. Value of each item should represent a single CSS   #
#   |                       class; DO NOT provide multiple classes for one item, otherwise the result is unexpected.                    #
#   |                      [<see def.>          ] <Default> Use a universal configuration for simple deployment                         #
#   |                      [<dict>              ]           Set it as unique in the session for complete style segregation              #
#   |cssClassesAdd     :   <dict     > dict of CSS classes to extend the default styles of internal components. It is allowed to provide#
#   |                       multiple CSS class names as value of the same item, split by spaces just as CSS syntax, to enable more      #
#   |                       flexible customization                                                                                      #
#   |                      [<see def.>          ] <Default> No extension for those internal components that are able to be customized   #
#   |                      [<dict>              ]           Extend the classes for those able to be customized                          #
#   |maxHeight         :   <int/float> The maximum height in pixel of the main panel, scroll components will be activated if it is      #
#   |                       exceeded                                                                                                    #
#   |                      [<see def.>          ] <Default> Set a popular height of the main panel                                      #
#   |                      [<int/float>         ]           Customize the maximum height of the instances                               #
#   |minHeight         :   <int/float> The minimum height in pixel of the panels when there is no choice to display                     #
#   |                      [<see def.>          ] <Default> Set a minimum height of the empty panels                                    #
#   |                      [<int/float>         ]           Customize the minimum height of the instances                               #
#   |minWidth          :   <int/float> The minimum width in pixel of the panels when there is no choice to display                      #
#   |                      [<see def.>          ] <Default> Set a minimum width of the empty panels                                     #
#   |                      [<int/float>         ]           Customize the minimum width of the instances                                #
#   |scrollSpeed       :   <float    > The animation speed for the scroll component                                                     #
#   |                      [<see def.>          ] <Default> Set a popular speed of the scroll component animation                       #
#   |                      [<float>             ]           Customize the animation speed when hovering over the scroll component       #
#   |windowGap         :   <int/float> The gap in pixel of the panels to the edge of the window viewport to avoid being hidden          #
#   |                      [<see def.>          ] <Default> Set a certain gap against the window when there is not enough room          #
#   |                      [<int/float>         ]           Customize the gap between the panels and the window edge                    #
#   |submenuGap        :   <int/float> The gap in pixel between the panels to avoid visual inconvenience                                #
#   |                      [<see def.>          ] <Default> Set a certain gap between the panels, rather than squeezing them together   #
#   |                      [<int/float>         ]           Customize the gap between the panels                                        #
#   |placeholder       :   <str      > The placeholder to show up in the <outputEL> container when all options are deselected           #
#   |                      [<see def.>          ] <Default> Use empty placeholder                                                       #
#   |                      [<str>               ]           Set specific placeholder for certain instance                               #
#   |hotkey            :   <str      > The hotkey to operate on trigger button, which resembles the click event on it                   #
#   |                      [<see def.>          ] <Default> Disable hotkey on the trigger button                                        #
#   |                      [<str>               ]           Set specific hotkeys, may include meta keys `ctrl/alt/shift/command/option` #
#   |arrows            :   <dict     > dict of strings that represent the HTML arrows for directive operations as well as inside the    #
#   |                       scroll components                                                                                           #
#   |                      [<see def.>          ] <Default> Use the modern arrows from <ShinyApp.TagsCollection>                        #
#   |                      [<dict>              ]           Define the arrows at your preference                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   Character representation of JS snippet                                                                       #
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
#   |re, sys, inspect, typing                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |ShinyApp                                                                                                                       #
#   |   |   |TagsCollection                                                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #010. Check parameters.
    if not isinstance(cssClasses, dict):
        cssClasses = {}
    if not isinstance(cssClassesAdd, dict):
        cssClassesAdd = {}

    #050. Local parameters
    func_name_trans = re.sub(r'\W', '_', funcName)
    css_presets = {
        #010. Exposed classes for the wrapper itself
        'wrapper' : 'dds-wrapper'
        ,'embeddedStylesId' : 'dds-emb-styles'
        #100. Classes bound to the internal element/container, as named in the keys
        ,'outputEl' : 'dds-selected-output'
        ,'triggerBtn' : 'dds-trigger-btn'
        ,'dropdown' : 'dds-dropdown-panel'
        ,'scrollContainer' : 'dds-scroll-container'
        ,'optionsList' : 'dds-options-list'
        ,'arrowUp' : 'dds-scroll-arrow-up'
        ,'arrowDown' : 'dds-scroll-arrow-down'
        ,'subPanel' : 'dds-submenu-panel'
        ,'groupLabel' : 'dds-option-group-label'
        #500. Classes that are internally used without being bound to certain names
        ,'scroll_arrow' : 'dds-scroll-arrow'
        ,'arrow_icon' : 'dds-arrow-icon'
        ,'option_separator' : 'dds-option-separator'
        ,'option_item' : 'dds-option-item'
        ,'option_indicator' : 'dds-option-indicator'
        ,'option_label' : 'dds-option-label'
        ,'submenu_arrow' : 'dds-submenu-arrow'
        ,'hitarea' : 'dds-hitarea'
    }
    #[ASSUMPTION]
    #[1] Below classes are all set with explicit `className` statements in JS
    #[2] That is why we expose them to the arguments for external patching
    css_addable = {
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
    tc = TagsCollection()

    #[ASSUMPTION]
    #[1] Below white spaces are used to standardize the output string
    sp_config = ' ' * 28
    sp_constructor = ' ' * 24

    #300. Prepare injection to the JS script
    #310. Session-unique classes
    cssClasses_final = css_presets | cssClasses

    #320. Arrow tags
    if not isinstance(arrows, dict):
        arrows = {
            'up' : tc.arrow(
                'up'
                ,class_ = cssClasses_final['arrow_icon']
            )
            ,'down' : tc.arrow(
                'down'
                ,class_ = cssClasses_final['arrow_icon']
            )
            ,'right' : tc.arrow(
                'right'
                ,class_ = cssClasses_final['arrow_icon']
                ,style = 'width: 14px; height: 14px;'
            )
            ,'left' : tc.arrow(
                'left'
                ,class_ = cssClasses_final['arrow_icon']
                ,style = 'width: 14px; height: 14px;'
            )
        }

    arrows_js = f'\n{sp_config},'.join([ f'{k}: `{v}`' for k,v in arrows.items() ])

    #350. Additional classes for certain tags
    if cssClassesAdd:
        #100. Write note for unexpected input
        err_addable = { k for k in cssClassesAdd.keys() if k not in css_addable }
        if err_addable:
            print(f'[{LfuncName}]<cssClassesAdd> contains unexpected targets which will be discarded: {err_addable}')

        #500. Prepare argument for the JS class
        classes_add = css_addable | {k:v for k,v in cssClassesAdd.items() if k in css_addable and isinstance(v, str)}
        classes_add_js = f'\n{sp_config},'.join([ f'{k}: `{v}`' for k,v in classes_add.items() ])

        #700. Prepare statements inside the JS class
        classes_struct_js = f'\n{sp_constructor},'.join([
            f'{k}: \'{cssClasses_final[k]}\' + ((\' \' + this.config.cssClassesAdd.{k}) || \'\')'
            for k in classes_add.keys()
        ])

    #800. Setup the JS program
    js_snippet = cleandoc(f'''
        // 放在 ui.head_content 中
        if (!window.__MODULE_LOADED_{func_name_trans}__) {{
            window.__MODULE_LOADED_{func_name_trans}__ = true;
            // console.log("实际逻辑只执行一次");
            // 定义全局函数、绑定事件等

            {funcName} = class {{
                /** 定义内部使用的CSS类 */
                // [ASSUMPTION]
                // [1] 由于css class名称很可能与外部名称相同，这里使用Python注入ns来确保特异性
                static CSS = `
                    :root {{
                        --dds-border-focus: #4a90d9;
                        --dds-text: #1f2937;
                        --dds-text-secondary: #6b7280;
                        --dds-shadow-md: 0 6px 18px rgba(0,0,0,0.12);
                        --dds-option-hover: #eaf1fb;
                        --dds-option-selected: #dbeafe;
                        --dds-option-active: #eaf1fb;
                        --dds-arrow-color: #5f6b7a;
                        --dds-arrow-disabled: #cbd5e1;
                        --dds-arrow-active: #2563eb;
                        --dds-radius: 10px;
                        --dds-edge-height: 34px;
                        --dds-arrow-size: 18px;
                        --dds-separator-color: #e5e7eb;
                    }}

                    .{cssClasses_final["wrapper"]} {{
                        position: relative;
                        /*
                        width: 100%;
                        */
                    }}

                    .{cssClasses_final["outputEl"]} {{
                        flex: 1;
                        min-width: 0;
                        padding: 8px 2px;
                        color: var(--dds-text);
                        white-space: nowrap;
                        overflow: hidden;
                        text-overflow: ellipsis;
                        background: transparent;
                        border: none;
                        pointer-events: none;
                        font-weight: 500;
                    }}
                    .{cssClasses_final["outputEl"]}.placeholder {{
                        color: #9ca3af;
                        font-weight: 400;
                    }}
                    .{cssClasses_final["triggerBtn"]}:focus {{
                        outline: none;
                    }}

                    .{cssClasses_final["triggerBtn"]} {{
                        flex-shrink: 0;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        width: max-content;
                        height: 36px;
                        border-radius: 8px;
                        border: none;
                        background-color: #f3f4f6;
                        color: #4b5563;
                        cursor: pointer;
                        transition: background 150ms, color 150ms;
                    }}
                    .{cssClasses_final["triggerBtn"]}:hover {{
                        background-color: #e5e7eb;
                        color: #1f2937;
                    }}
                    .{cssClasses_final["triggerBtn"]}:focus {{
                        outline: none;
                    }}
                    .{cssClasses_final["triggerBtn"]}:focus-visible {{
                        box-shadow: 0 0 0 2px rgba(74,144,217,0.5);
                        /*
                        background: #eef2ff;
                        */
                    }}
                    .{cssClasses_final["triggerBtn"]} svg {{
                        width: 18px;
                        height: 18px;
                        transition: transform 180ms;
                    }}
                    .{cssClasses_final["wrapper"]}.open .{cssClasses_final["triggerBtn"]} svg {{
                        transform: rotate(180deg);
                    }}

                    /* 下拉面板：初始完全不渲染，隐藏时不影响布局 */
                    .{cssClasses_final["dropdown"]} {{
                        display: none;                 /* 关键：彻底移出布局 */
                        position: absolute;            /* 保留以备 JS 控制 */
                        width: max-content;            /* 宽度由内容决定 */
                        max-width: calc(100vw - 20px); /* 不超过视口 */
                        min-width: 40px;
                        background: #fff;
                        border: 1.5px solid var(--dds-border-focus);
                        border-radius: var(--dds-radius);
                        box-shadow: var(--dds-shadow-md);
                        z-index: 100;
                        /* 移除原有的 opacity/visibility/transform，用 open 类控制动画 */
                        opacity: 0;
                        transform: translateY(-6px);
                        transition: opacity 180ms, transform 180ms;
                    }}

                    /* 打开状态：由 JS 添加 open 类 */
                    .{cssClasses_final["dropdown"]}.open {{
                        display: flex;                 /* 恢复弹性布局 */
                        opacity: 1;
                        transform: translateY(0);
                    }}

                    .{cssClasses_final["wrapper"]}.open .{cssClasses_final["dropdown"]} {{
                        opacity: 1;
                        visibility: visible;
                        transform: translateY(0);
                        transition: opacity 180ms, transform 180ms, visibility 0ms 0ms;
                    }}
                    /* 由于改为在JS中控制主菜单的浮动位置，以下特殊控制可以去除 */
                    /*
                    .{cssClasses_final["wrapper"]}.drop-up .{cssClasses_final["dropdown"]} {{
                        border-top: 1.5px solid var(--dds-border-focus);
                        border-bottom: none;
                        border-radius: var(--dds-radius) var(--dds-radius) 0 0;
                        transform: translateY(6px);
                    }}
                    .{cssClasses_final["wrapper"]}.drop-up.open .{cssClasses_final["dropdown"]} {{
                        transform: translateY(0);
                    }}
                    */

                    .{cssClasses_final["scrollContainer"]} {{
                        overflow-y: auto;
                        overflow-x: hidden;
                        max-height: 400px;
                        scrollbar-width: none;
                        -ms-overflow-style: none;
                    }}
                    .{cssClasses_final["scrollContainer"]}::-webkit-scrollbar {{
                        display: none;
                        width: 0;
                        height: 0;
                    }}

                    .{cssClasses_final["optionsList"]} {{
                        list-style: none;
                        padding: 6px 0;
                        margin: 0;
                        position: relative;
                        z-index: 1;
                    }}

                    .{cssClasses_final["option_item"]} {{
                        position: relative;
                        display: flex;
                        align-items: center;
                        padding: 9px 16px 9px 12px;
                        cursor: pointer;
                        color: var(--dds-text);
                        transition: background 80ms;
                        font-size: 14px;
                        white-space: nowrap;
                        overflow: visible;
                    }}
                    .{cssClasses_final["option_item"]}:hover {{
                        background: var(--dds-option-hover);
                    }}
                    .{cssClasses_final["option_item"]}.selected {{
                        background: var(--dds-option-selected);
                        font-weight: 600;
                        color: #1d4ed8;
                    }}
                    .{cssClasses_final["option_item"]}.keyboard-active {{
                        background: #e0e7ff;
                        outline: none;
                    }}
                    .{cssClasses_final["option_item"]}.selected.keyboard-active {{
                        background: #c7d2fe;
                    }}

                    .{cssClasses_final["option_indicator"]} {{
                        display: inline-block;
                        width: 16px;
                        margin-right: 6px;
                        text-align: center;
                        visibility: hidden;
                        font-size: 12px;
                        line-height: 1;
                    }}
                    .{cssClasses_final["option_item"]}.selected .{cssClasses_final["option_indicator"]} {{
                        visibility: visible;
                    }}

                    .{cssClasses_final["option_label"]} {{
                        flex: 1;
                    }}

                    .{cssClasses_final["submenu_arrow"]} {{
                        /* margin-left 允许元素右对齐 */
                        margin-left: auto;
                        /* padding-left 将元素与其左边相邻的内容隔开一定距离 */
                        padding-left: 16px;
                        font-size: 12px;
                        color: #888;
                        transition: transform 150ms;
                    }}
                    .{cssClasses_final["option_item"]}:hover > .{cssClasses_final["submenu_arrow"]} {{
                        color: #333;
                    }}

                    .{cssClasses_final["groupLabel"]} {{
                        padding: 8px 16px 4px;
                        font-size: 12px;
                        font-weight: 600;
                        color: var(--dds-text-secondary);
                        text-transform: uppercase;
                        letter-spacing: 0.5px;
                        background: #fafafa;
                        pointer-events: none;
                        white-space: nowrap;
                    }}

                    .{cssClasses_final["option_separator"]} {{
                        height: 1px;
                        background: var(--dds-separator-color);
                        margin: 4px 0;
                        pointer-events: none;
                    }}

                    /* 子菜单面板 */
                    .{cssClasses_final["subPanel"]} {{
                        position: absolute;
                        top: 0;
                        left: 100%;
                        min-width: 40px;
                        width: max-content;            /* 宽度由内容决定 */
                        background: #fff;
                        border: 1.5px solid var(--dds-border-focus);
                        border-radius: var(--dds-radius);
                        box-shadow: var(--dds-shadow-md);
                        opacity: 0;
                        visibility: hidden;
                        transform: scale(0.95);
                        transition: opacity 150ms, transform 150ms, visibility 0ms 150ms;
                        z-index: 200;
                        max-height: 400px;
                        scrollbar-width: none;
                        -ms-overflow-style: none;
                        /*
                        overflow-y: auto;
                        */
                        overflow: visible;   /* 关键：允许扩展区域超出边框 */
                        padding: 4px 0;
                    }}
                    .{cssClasses_final["subPanel"]}::-webkit-scrollbar {{ display: none; }}
                    .{cssClasses_final["subPanel"]}.open {{
                        opacity: 1;
                        visibility: visible;
                        transform: scale(1);
                        transition: opacity 150ms, transform 150ms, visibility 0ms 0ms;
                    }}
                    .{cssClasses_final["subPanel"]}.left-side {{
                        left: auto;
                        right: 100%;
                    }}
                    .{cssClasses_final["subPanel"]} .{cssClasses_final["option_item"]} {{
                        padding: 8px 14px 8px 12px;
                    }}

                    .{cssClasses_final["scroll_arrow"]} {{
                        position: absolute;
                        left: 0;
                        right: 0;
                        height: var(--dds-edge-height);
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        pointer-events: auto;
                        z-index: 10;
                        background: transparent;
                        transition: background 120ms, opacity 180ms;
                        opacity: 0;
                    }}
                    .{cssClasses_final["scroll_arrow"]}.visible {{
                        opacity: 1;
                    }}
                    .{cssClasses_final["scroll_arrow"]}.disabled {{
                        opacity: 0.4;
                        pointer-events: none;
                        cursor: default;
                    }}
                    .{cssClasses_final["scroll_arrow"]}:not(.disabled):hover {{
                        background: rgba(74, 144, 217, 0.06);
                    }}
                    .{cssClasses_final["scroll_arrow"]}:not(.disabled):active {{
                        background: rgba(74, 144, 217, 0.12);
                    }}

                    .{cssClasses_final["arrowUp"]} {{
                        top: 0;
                        border-radius: inherit;
                    }}
                    .{cssClasses_final["arrowDown"]} {{
                        bottom: 0;
                        border-radius: inherit;
                    }}

                    .{cssClasses_final["arrow_icon"]} {{
                        width: var(--dds-arrow-size);
                        height: var(--dds-arrow-size);
                        color: var(--dds-arrow-color);
                        transition: color 150ms;
                    }}
                    .{cssClasses_final["scroll_arrow"]}.disabled .{cssClasses_final["arrow_icon"]} {{
                        color: var(--dds-arrow-disabled);
                    }}
                    .{cssClasses_final["scroll_arrow"]}:not(.disabled):hover .{cssClasses_final["arrow_icon"]} {{
                        color: var(--dds-arrow-active);
                    }}

                    @media (max-width: 480px) {{
                        .{cssClasses_final["scrollContainer"]} {{ max-height: 200px; }}
                        .{cssClasses_final["subPanel"]} {{ min-width: 150px; }}
                    }}
                `;

                static _stylesInjected = false;
                static _zIndexBase = 10000;            // 子菜单起始 z-index
                static _zIndexCurrent = 10000;         // 当前最高 z-index
                static openInstances = new Set();      // 互斥管理

                // ✅ 用 this 访问和设置静态属性
                static injectStyles() {{
                    if (this._stylesInjected) return;
                    const styleEl = document.createElement('style');
                    styleEl.id = '{cssClasses_final["embeddedStylesId"]}';
                    styleEl.textContent = this.CSS;
                    document.head.appendChild(styleEl);
                    this._stylesInjected = true;
                }}

                constructor(wrapper, choices, config = {{}}) {{
                    // ✅ 通过实例的 constructor 属性调用静态成员或方法
                    this.constructor.injectStyles();

                    this.wrapper = wrapper;
                    this.choices = choices;
                    this.config = {{
                        maxHeight: {maxHeight},                 // 下拉列表最大高度
                        minHeight: {minHeight},                 // 下拉列表为空时的预设
                        minWidth: {minWidth},                   // 下拉列表为空时的预设
                        scrollSpeed: {scrollSpeed},
                        windowGap: {windowGap},                 // 使菜单与视窗保留最小间距
                        submenuGap: {submenuGap},               // 子菜单与父选项的水平间距
                        submenuMaxHeight: {submenuMaxHeight},   // 子菜单最大高度
                        placeholder: '{placeholder}',           // 清除选择时，输出框中显示的点位符
                        hotkey: '{hotkey}',                     // Trigger Button 可用的快捷键
                        arrows: {{
                            {arrows_js}
                        }},
                        cssClassesAdd: {{
                            {classes_add_js}
                        }},
                        ...config
                    }};

                    // 状态
                    this.isOpen = false;
                    this.selectedValue = null;
                    this.selectedLabel = null;
                    this.dropUp = false;
                    this.keyboardIndex = -1;
                    this.rafId = null;
                    this.scrollDir = 0;

                    // 为需要显式设置CSS class的元素添加灵活性，增加额外的class
                    this.cssClasses = {{
                        {classes_struct_js}
                    }};
                    // 对于上下箭头，新增的class须在所有已加的classes之后，确保能应用
                    this.cssClasses.scroll_arrow_up = (
                        '{cssClasses_final["scroll_arrow"]}'
                        + ' {cssClasses_final["arrowUp"]}'
                        + ((' ' + this.config.cssClassesAdd.scroll_arrow) || '')
                    );
                    this.cssClasses.scroll_arrow_down = (
                        '{cssClasses_final["scroll_arrow"]}'
                        + ' {cssClasses_final["arrowDown"]}'
                        + ((' ' + this.config.cssClassesAdd.scroll_arrow) || '')
                    );

                    // 改为 Map 记录所有打开的子菜单
                    this.openSubmenus = new Map();      // key: subPanel, value: ( parentLi, zIndex, hideTimer )
                    this.currentSubmenu = null;         // 键盘导航焦点所在的子菜单
                    this.currentSubmenuParent = null;
                    this.submenuItems = [];
                    this.subKeyboardIndex = -1;

                    // 触发按钮的快捷键支持
                    this.hotkey = null;
                    this._hotkeyHandler = null;

                    // DOM引用
                    this.outputEl = (
                        this.wrapper.querySelector('.{cssClasses_final["outputEl"]}') ||
                        this.wrapper.querySelector('[class*="{cssClasses_final['outputEl']}"]')
                    );
                    this.triggerBtn = this.wrapper.querySelector('.{cssClasses_final["triggerBtn"]}');
                    this.dropdown = this.wrapper.querySelector('.{cssClasses_final["dropdown"]}');
                    this.scrollContainer = this.wrapper.querySelector('.{cssClasses_final["scrollContainer"]}');
                    this.optionsList = this.wrapper.querySelector('.{cssClasses_final["optionsList"]}');
                    this.arrowUp = this.wrapper.querySelector('.{cssClasses_final["arrowUp"]}');
                    this.arrowDown = this.wrapper.querySelector('.{cssClasses_final["arrowDown"]}');

                    // 增加活动滚动容器
                    this.mainScrollContainer = this.scrollContainer;
                    this.mainArrowUp = this.arrowUp;
                    this.mainArrowDown = this.arrowDown;
                    this.activeScrollContainer = this.mainScrollContainer;
                    this.activeArrowUp = this.mainArrowUp;
                    this.activeArrowDown = this.mainArrowDown;

                    // 抑制标志
                    this._suppressSubmenu = false;

                    // 存储选项DOM元素
                    this.optionEls = [];

                    // 每个子菜单的延迟关闭定时器
                    this._submenuHideTimers = new Map();
                    this._hideAllTimer = null;

                    // 初始化
                    this._init();
                    this.constructor.openInstances.add(this);
                }}

                /** 初始化DOM和事件 */
                _init() {{
                    // 生成选项
                    this._renderOptions();

                    // 绑定事件
                    this.triggerBtn.addEventListener('click', (e) => {{ e.stopPropagation(); this.toggle(); }});
                    this.triggerBtn.addEventListener('keydown', (e) => this._onKeyDown(e));
                    this.arrowUp.addEventListener('mouseenter', () => this._startScroll(-1));
                    this.arrowUp.addEventListener('mouseleave', () => this._stopScroll());
                    this.arrowDown.addEventListener('mouseenter', () => this._startScroll(1));
                    this.arrowDown.addEventListener('mouseleave', () => this._stopScroll());
                    this.arrowUp.addEventListener('click', e => e.stopPropagation());
                    this.arrowDown.addEventListener('click', e => e.stopPropagation());

                    // 触发按钮的快捷键事件
                    if (this.config.hotkey) {{
                        const parsed = this.constructor._parseHotkey(this.config.hotkey);
                        if (parsed) {{
                            this.hotkey = parsed;
                            this._hotkeyHandler = (e) => {{
                                if (e.repeat) return;
                                const ctrlOk = this.hotkey.ctrl === e.ctrlKey;
                                const altOk = this.hotkey.alt === e.altKey;
                                const shiftOk = this.hotkey.shift === e.shiftKey;
                                const metaOk = this.hotkey.meta === e.metaKey;
                                const keyOk = e.key.toLowerCase() === this.hotkey.key;
                                if (ctrlOk && altOk && shiftOk && metaOk && keyOk) {{
                                    e.preventDefault();
                                    this.triggerBtn.focus();
                                    this.toggle();
                                }}
                            }};
                            document.addEventListener('keydown', this._hotkeyHandler);
                        }}
                    }}

                    // 全局点击关闭主菜单
                    document.addEventListener('click', this._docClickHandler = (e) => {{
                        // 未打开时不处理
                        if (!this.isOpen) return;

                        // 安全获取目标元素
                        const target = e.target;
                        if (!target) return;

                        // 检查是否点击在容器内部（按钮所在的外层 wrapper）
                        const inContainer = this.wrapper && this.wrapper.contains(target);
                        // 检查是否点击在主菜单面板内部
                        const inDropdown = this.dropdown && this.dropdown.contains(target);
                        // 检查是否点击在任何打开的子菜单内部
                        let inSubmenu = false;
                        if (this.openSubmenus && this.openSubmenus.size > 0) {{
                            this.openSubmenus.forEach((_, subPanel) => {{
                                if (subPanel && subPanel.contains(target)) {{
                                    inSubmenu = true;
                                }}
                            }});
                        }}

                        // 如果点击既不在容器、主菜单、也不在任何子菜单内，则关闭整个下拉
                        if (!inContainer && !inDropdown && !inSubmenu) {{
                            this.close();
                        }}
                    }}, true);
                    window.addEventListener('resize', this._resizeHandler = () => {{
                        if (this.isOpen) {{
                            this._determineDirection();
                            this._updateArrows();
                        }}
                    }});
                }}

                /** 静态方法：解析快捷键字符串 */
                static _parseHotkey(hotkeyStr) {{
                    if (!hotkeyStr || typeof hotkeyStr !== 'string') return null;
                    const parts = hotkeyStr.toLowerCase().split('+');
                    const modifiers = {{ ctrl: false, alt: false, shift: false, meta: false }};
                    let key = '';
                    for (const part of parts) {{
                        if (part === 'ctrl' || part === 'control') {{
                            if (modifiers.ctrl) return null; // 重复
                            modifiers.ctrl = true;
                        }} else if (part === 'alt' || part === 'option' || part === 'opt') {{
                            if (modifiers.alt) return null;
                            modifiers.alt = true;
                        }} else if (part === 'shift') {{
                            if (modifiers.shift) return null;
                            modifiers.shift = true;
                        }} else if (part === 'meta' || part === 'command' || part === 'cmd') {{
                            if (modifiers.meta) return null;
                            modifiers.meta = true;
                        }} else if (part.length === 1 && /[a-z]/.test(part)) {{
                            if (key) return null; // 多个字母
                            key = part;
                        }} else {{
                            return null; // 非法修饰键或无效字母
                        }}
                    }}
                    if (!key) return null;
                    return {{ ...modifiers, key }};
                }}

                /** 判断是否有多级菜单 */
                _isGroupedData(data) {{
                    return Array.isArray(data) && data.length > 0 && data[0].hasOwnProperty('options');
                }}

                /** 递归构建选项HTML */
                _renderFlatOptions(container, items, level = 0) {{
                    const frag = document.createDocumentFragment();
                    items.forEach((item, idx) => {{
                        if (item.type === 'separator') {{
                            const sep = document.createElement('li');
                            sep.className = this.cssClasses.option_separator;
                            frag.appendChild(sep);
                            return;
                        }}

                        // 处理分组（适用于子菜单中的分组结构）
                        if (item && typeof item === 'object' && item.options && !item.value) {{
                            const groupLabel = document.createElement('li');
                            groupLabel.className = this.cssClasses.groupLabel;
                            groupLabel.textContent = item.label;
                            groupLabel.style.paddingLeft = (12 + level * 12) + 'px';
                            frag.appendChild(groupLabel);
                            // 递归渲染组内选项
                            this._renderFlatOptions(frag, item.options, level);
                            // 如果不是最后一个项目，添加分隔条
                            if (idx < items.length - 1) {{
                                const sep = document.createElement('li');
                                sep.className = this.cssClasses.option_separator;
                                frag.appendChild(sep);
                            }}
                            return;
                        }}

                        const li = document.createElement('li');
                        li.className = this.cssClasses.option_item;
                        li.setAttribute('role', 'option');
                        li.setAttribute('data-value', item.value);
                        li.style.paddingLeft = (12 + level * 12) + 'px';

                        const indicator = document.createElement('span');
                        indicator.className = this.cssClasses.option_indicator;
                        indicator.textContent = '●';
                        li.appendChild(indicator);

                        const labelSpan = document.createElement('span');
                        labelSpan.className = this.cssClasses.option_label;
                        labelSpan.textContent = item.label;
                        li.appendChild(labelSpan);

                        // 在 li 创建后，添加事件（保留原有 click 和 mouseenter 用于键盘焦点清除）
                        li.addEventListener('mouseenter', () => {{
                            clearTimeout(this._hideAllTimer);      // 新增：防止菜单误关
                            this._clearKeyboardActive();
                        }});

                        // 如果有子菜单，绑定悬浮事件
                        if (item.children && item.children.length > 0) {{
                            const arrowSpan = document.createElement('span');
                            arrowSpan.className = this.cssClasses.submenu_arrow;
                            // arrowSpan.textContent = '▶';
                            arrowSpan.innerHTML = `{arrows["right"]}`;
                            li.appendChild(arrowSpan);

                            const subPanel = document.createElement('div');
                            subPanel.className = this.cssClasses.subPanel;

                            // 创建滚动容器（与主菜单结构一致）
                            const scrollContainer = document.createElement('div');
                            scrollContainer.className = this.cssClasses.scrollContainer;

                            // 向上箭头
                            const arrowUp = document.createElement('div');
                            arrowUp.className = this.cssClasses.scroll_arrow_up;
                            arrowUp.innerHTML = this.config.arrows.up;
                            scrollContainer.appendChild(arrowUp);

                            // 选项列表
                            const subList = document.createElement('ul');
                            subList.className = this.cssClasses.optionsList;
                            this._renderFlatOptions(subList, item.children, level + 1);
                            scrollContainer.appendChild(subList);

                            // 向下箭头
                            const arrowDown = document.createElement('div');
                            arrowDown.className = this.cssClasses.scroll_arrow_down;
                            arrowDown.innerHTML = this.config.arrows.down;
                            scrollContainer.appendChild(arrowDown);

                            // 设置样式并绑定事件
                            scrollContainer.style.maxHeight = (this.config.submenuMaxHeight || '240') + 'px';
                            scrollContainer.style.overflowY = 'auto';
                            scrollContainer.style.scrollbarWidth = 'none'; // Firefox
                            scrollContainer.style.msOverflowStyle = 'none'; // IE/Edge

                            arrowUp.addEventListener('mouseenter', () => {{
                                this._setActiveScroll(scrollContainer, arrowUp, arrowDown);
                                this._updateArrows();
                                this._startScroll(-1);
                            }});
                            arrowUp.addEventListener('mouseleave', () => {{
                                this._stopScroll();
                                this._restoreMainScroll();
                            }});
                            arrowDown.addEventListener('mouseenter', () => {{
                                this._setActiveScroll(scrollContainer, arrowUp, arrowDown);
                                this._updateArrows();
                                this._startScroll(1);
                            }});
                            arrowDown.addEventListener('mouseleave', () => {{
                                this._stopScroll();
                                this._restoreMainScroll();
                            }});

                            subPanel.appendChild(scrollContainer);

                            li.appendChild(subPanel);
                            li._subPanel = subPanel;

                            // 鼠标进入父 li：打开子菜单并取消任何隐藏定时器
                            li.addEventListener('mouseenter', (e) => {{
                                // 清除全局定时器（防止一级菜单被误关）
                                clearTimeout(this._hideAllTimer);
                                // 清除当前子菜单的单独关闭定时器
                                const timer = this._submenuHideTimers.get(subPanel);
                                if (timer) {{
                                    clearTimeout(timer);
                                    this._submenuHideTimers.delete(subPanel);
                                }}

                                // 如果子菜单已经打开，只需重新定位（确保位置正确，避免左上角错位）
                                if (subPanel.classList.contains('open')) {{
                                    const info = this.openSubmenus.get(subPanel);
                                    if (info) {{
                                        this._positionSubmenu(li, subPanel, info.zIndex, {{ isMain: false }});
                                    }}
                                }} else {{
                                    // 否则正常打开子菜单
                                    this._showSubmenu(li, subPanel);
                                }}
                            }});

                            // 鼠标离开父 li：如果未进入子菜单，则延迟关闭
                            li.addEventListener('mouseleave', (e) => {{
                                const relatedTarget = e.relatedTarget;

                                // 若当前 li 有关联的子菜单且子菜单处于打开状态
                                if (subPanel && subPanel.classList.contains('open')) {{
                                    // 鼠标未进入该子菜单，则立即关闭它
                                    if (!subPanel.contains(relatedTarget)) {{
                                        this._closeSubmenu(subPanel);
                                    }}
                                    // 无论是否关闭，该 li 的责任已完成，不再执行后续全局定时器逻辑
                                    return;
                                }}

                                // 普通选项（无子菜单）的离开处理
                                // 如果进入了任何已打开的子菜单（包括通过逻辑链判断），就不关闭
                                if (subPanel && subPanel.contains(relatedTarget)) return;
                                const otherPanel = relatedTarget.closest('.{cssClasses_final["subPanel"]}.open');
                                if (otherPanel) {{
                                    // 如果进入了后代菜单，不关闭
                                    if (this._isDescendantMenu(subPanel, otherPanel)) return;
                                }}
                                if (this.dropdown && this.dropdown.contains(relatedTarget)) return;
                                this._scheduleHideAllSubmenus();
                            }});

                            // 子菜单鼠标进入：清除自身及祖先定时器
                            subPanel.addEventListener('mouseenter', (e) => {{
                                // 关键修复：清除全局隐藏定时器（防止一级菜单被关闭）
                                clearTimeout(this._hideAllTimer);
                                this._hideAllTimer = null;

                                // 清除自身定时器
                                const selfTimer = this._submenuHideTimers.get(subPanel);
                                if (selfTimer) {{
                                    clearTimeout(selfTimer);
                                    this._submenuHideTimers.delete(subPanel);
                                }}

                                // 清除所有祖先子菜单的定时器（保持级联可见）
                                let node = subPanel.parentElement;
                                while (node) {{
                                    if (
                                        node.classList.contains('{cssClasses_final["subPanel"]}')
                                        && this.openSubmenus.has(node)
                                    ) {{
                                        const ancTimer = this._submenuHideTimers.get(node);
                                        if (ancTimer) {{
                                            clearTimeout(ancTimer);
                                            this._submenuHideTimers.delete(node);
                                        }}
                                    }}
                                    node = node.parentElement;
                                }}
                            }});

                            // 子菜单鼠标离开：判断去向
                            subPanel.addEventListener('mouseleave', (e) => {{
                                const relatedTarget = e.relatedTarget;
                                const parentLi = this.openSubmenus.get(subPanel)?.parentLi;

                                // 1. 鼠标进入父选项 → 保持打开
                                if (parentLi && parentLi.contains(relatedTarget)) return;

                                // 2. 鼠标进入主菜单面板 → 关闭当前子菜单
                                if (this.dropdown && this.dropdown.contains(relatedTarget)) {{
                                    this._closeSubmenu(subPanel);
                                    return;
                                }}

                                // 3. 鼠标进入了另一个已打开的子菜单面板
                                const otherPanel = relatedTarget.closest('.{cssClasses_final["subPanel"]}.open');
                                if (otherPanel && otherPanel !== subPanel) {{
                                    // 3a. 如果 otherPanel 是当前子菜单的后代（如二级菜单是一级菜单的后代）→ 保持当前子菜单打开
                                    if (this._isDescendantMenu(subPanel, otherPanel)) return;

                                    // 3b. 如果 otherPanel 是当前子菜单的祖先，并且鼠标正好停在父选项上 → 保持打开（允许重新进入）
                                    if (
                                        this._isDescendantMenu(otherPanel, subPanel)
                                        && parentLi
                                        && parentLi.contains(relatedTarget)
                                    ) return;

                                    // 3c. 其他情况（进入了同级、上级非父选项等）→ 关闭当前子菜单
                                    this._closeSubmenu(subPanel);
                                    return;
                                }}

                                // 4. 完全离开菜单系统 → 启动全局延迟关闭
                                this._scheduleHideAllSubmenus();
                            }});
                        }}

                        li.addEventListener('click', (e) => {{
                            e.stopPropagation();
                            const clickedLi = e.currentTarget;
                            const panel = clickedLi._subPanel;  // 从元素上获取子菜单面板
                            if (item.children && item.children.length > 0) {{
                                // 触屏适配：若子菜单未打开，则打开它；若已打开则不做任何事（保留悬停打开的状态）
                                if (panel && !panel.classList.contains('open')) {{
                                    this._showSubmenu(clickedLi, panel);
                                }}
                                return;
                            }}
                            this._toggleSelection(item.value, item.label);
                        }});

                        li.addEventListener('mouseenter', () => {{
                            this._clearKeyboardActive();
                        }});

                        frag.appendChild(li);
                        if (container === this.optionsList) {{
                            this.optionEls.push(li);
                        }}
                    }});
                    container.appendChild(frag);
                }}

                /** 构建选项的方法 */
                _renderOptions() {{
                    this.optionsList.innerHTML = '';
                    this.optionEls = [];

                    if (this._isGroupedData(this.choices)) {{
                        this.choices.forEach((group, gIndex) => {{
                            if (group.label) {{
                                const groupLabel = document.createElement('li');
                                groupLabel.className = this.cssClasses.groupLabel;
                                groupLabel.textContent = group.label;
                                // 关键：清除全局定时器，防止鼠标经过组标签时子菜单被意外关闭
                                groupLabel.addEventListener('mouseenter', () => {{
                                    clearTimeout(this._hideAllTimer);
                                    this._hideAllTimer = null;
                                }});
                                this.optionsList.appendChild(groupLabel);
                            }}
                            this._renderFlatOptions(this.optionsList, group.options, 0);
                            if (gIndex < this.choices.length - 1) {{
                                const sep = document.createElement('li');
                                sep.className = this.cssClasses.option_separator;
                                this.optionsList.appendChild(sep);
                            }}
                        }});
                    }} else {{
                        this._renderFlatOptions(this.optionsList, this.choices, 0);
                    }}
                }}

                /** 显示子菜单的方法 */
                _positionSubmenu(parentLi, panel, zIndex, options = {{}}) {{
                    const {{ isMain = false, preferUp = false }} = options;
                    const rect = parentLi.getBoundingClientRect();
                    const panelWidth = panel.offsetWidth || this.config.minWidth;
                    const panelHeight = panel.offsetHeight || this.config.minHeight;
                    const gap = isMain ? 4 : (this.config.submenuGap || 6);

                    // 使用 clientWidth/clientHeight 以避开滚动条
                    const maxRight = document.documentElement.clientWidth - this.config.windowGap;
                    const maxBottom = document.documentElement.clientHeight - this.config.windowGap;

                    let left, top;
                    if (isMain) {{
                        left = rect.left;
                        top = preferUp ? rect.top - panelHeight - gap : rect.bottom + gap;
                        if (left + panelWidth > maxRight) {{
                            left = maxRight - panelWidth;
                        }}
                        left = Math.max(this.config.windowGap, left);
                    }} else {{
                        left = rect.right + gap;
                        if (left + panelWidth > maxRight) {{
                            left = rect.left - panelWidth - gap;
                        }}
                        top = rect.top;
                        left = Math.max(this.config.windowGap, left);
                    }}
                    if (top + panelHeight > maxBottom) {{
                        top = maxBottom - panelHeight;
                    }}
                    top = Math.max(this.config.windowGap, top);

                    // 应用固定定位（先清除可能遗留的内联样式）
                    panel.style.cssText = ''; // 重置所有内联样式，然后逐一设置
                    panel.style.position = 'fixed';
                    panel.style.left = left + 'px';
                    panel.style.top = top + 'px';
                    panel.style.zIndex = zIndex;
                    panel.style.visibility = '';
                    panel.style.display = '';
                }}
                _measurePanelSize(parentLi, panel, options = {{}}) {{
                    // 克隆面板（仅结构，不包含事件）
                    const clone = panel.cloneNode(true);
                    clone.style.cssText = 'position:absolute; left:0; top:0; visibility:hidden; display:block; z-index:-1;';
                    document.body.appendChild(clone);
                    const width = clone.offsetWidth;
                    const height = clone.offsetHeight;
                    document.body.removeChild(clone);
                    return {{ width, height }};
                }}

                _isDescendantMenu(ancestor, descendant) {{
                    let current = descendant;
                    while (current) {{
                        if (current === ancestor) return true;
                        const info = this.openSubmenus.get(current);
                        current = info ? info.parentMenu : null;
                    }}
                    return false;
                }}

                _showSubmenu(parentLi, subPanel) {{
                    // 选择过程中禁止打开子菜单
                    if (this._suppressSubmenu) return;

                    // 关闭所有其他无关的子菜单（保留当前面板及其祖先）
                    const toClose = [];
                    this.openSubmenus.forEach((info, panel) => {{
                        if (panel !== subPanel &&
                            !subPanel.contains(panel) &&  // 不是当前面板的后代
                            !panel.contains(subPanel)     // 不是当前面板的祖先
                        ) {{
                            toClose.push(panel);
                        }}
                    }});
                    toClose.forEach(p => this._closeSubmenu(p));

                    // 防御：确保 parentLi 是选项容器（而不是内部的 span）
                    parentLi = parentLi.closest('.{cssClasses_final["option_item"]}');
                    if (!parentLi || !subPanel) return;

                    clearTimeout(this._submenuHideTimer);

                    // 如果已经是打开状态，仅更新位置和 z-index（不增加层级）
                    if (this.openSubmenus.has(subPanel)) {{
                        const info = this.openSubmenus.get(subPanel);
                        this._positionSubmenu(subPanel, parentLi, info.zIndex, false);
                        return;
                    }}

                    // 新 z-index
                    this.constructor._zIndexCurrent++;
                    const z = this.constructor._zIndexCurrent;

                    // ★ 确保存在透明扩展区域，覆盖子菜单间隙
                    let hitArea = subPanel.querySelector('.{cssClasses_final["hitarea"]}');
                    if (!hitArea) {{
                        hitArea = document.createElement('div');
                        hitArea.className = this.cssClasses.hitarea;
                        hitArea.style.cssText = `
                            position:absolute;
                            inset: ${{-(this.config.submenuGap + 2)}}px;
                            /* 以下四项等价于 inset: -8px;
                            top:-8px;
                            bottom:-8px;
                            left:-8px;
                            right:-8px;
                            */
                            z-index:-1;
                            pointer-events:auto;
                            background:transparent;
                        `;
                        subPanel.insertBefore(hitArea, subPanel.firstChild);
                    }}

                    // ★ 关键：将子菜单移出原容器，挂载到 body
                    if (subPanel.parentNode !== document.body) {{
                        document.body.appendChild(subPanel);
                    }}

                    // 先强制设置为固定定位但不可见，以便测量（重要！）
                    subPanel.style.cssText = 'position:fixed; visibility:hidden; display:block;';
                    // 测量（此时面板已在 body 中，可获取准确宽高）
                    const width = subPanel.offsetWidth;
                    const height = subPanel.offsetHeight;

                    // 基于测量结果计算并应用最终定位
                    this._positionSubmenu(parentLi, subPanel, z, {{ isMain: false }});

                    subPanel.classList.add('open');

                    // 记录打开状态
                    const parentMenu = parentLi.closest('.{cssClasses_final["subPanel"]}');   // 可能是 null（一级菜单）
                    this.openSubmenus.set(subPanel, {{ parentLi, zIndex: z, parentMenu }});

                    // 更新内部选项列表，用于键盘导航
                    this.submenuItems = Array.from(subPanel.querySelectorAll('.{cssClasses_final["option_item"]}'));

                    // 以便调用方获取已挂载的面板
                    return subPanel;
                }}

                /** 关闭子菜单的方法 */
                _scheduleHideSubmenu(subPanel, parentLi) {{
                    // 清除旧定时器
                    const oldTimer = this._submenuHideTimers.get(subPanel);
                    if (oldTimer) clearTimeout(oldTimer);
                    const timer = setTimeout(() => {{
                        this._closeSubmenu(subPanel);
                        this._submenuHideTimers.delete(subPanel);
                    }}, 200);
                    this._submenuHideTimers.set(subPanel, timer);
                }}

                _scheduleHideAllSubmenus() {{
                    // 清除已有的全局关闭定时器
                    clearTimeout(this._hideAllTimer);
                    this._hideAllTimer = setTimeout(() => {{
                        this._hideAllSubmenus();
                    }}, 200);
                }}

                _hideAllSubmenus() {{
                    // 关闭所有已记录的子菜单（从最深层开始）
                    const panels = Array.from(this.openSubmenus.keys());
                    panels.forEach(p => this._closeSubmenu(p));
                    this.openSubmenus.clear();
                    // 清除所有单独定时器
                    this._submenuHideTimers.forEach(t => clearTimeout(t));
                    this._submenuHideTimers.clear();
                    this.currentSubmenu = null;
                    this.currentSubmenuParent = null;
                    this.submenuItems = [];
                    this.subKeyboardIndex = -1;
                }}

                _closeSubmenu(subPanel) {{
                    if (!subPanel || !this.openSubmenus.has(subPanel)) return;

                    // 先递归关闭所有后代子菜单（从该面板内部找到打开的 .{cssClasses_final["subPanel"]}.open）
                    const descendantPanels = subPanel.querySelectorAll('.{cssClasses_final["subPanel"]}.open');
                    descendantPanels.forEach(descendant => {{
                        // 移除后代子菜单的 open 状态，但不递归调用 _closeSubmenu 避免重复清理
                        descendant.classList.remove('open');
                        descendant.style.display = 'none';
                        descendant.style.position = '';
                        descendant.style.left = '';
                        descendant.style.top = '';
                        descendant.style.zIndex = '';
                        this.openSubmenus.delete(descendant);
                        // 清除后代子菜单的定时器
                        const timer = this._submenuHideTimers.get(descendant);
                        if (timer) {{
                            clearTimeout(timer);
                            this._submenuHideTimers.delete(descendant);
                        }}
                    }});

                    // 关闭自身
                    subPanel.classList.remove('open');
                    subPanel.style.visibility = '';
                    subPanel.style.display = 'none';
                    subPanel.style.position = '';
                    subPanel.style.left = '';
                    subPanel.style.top = '';
                    subPanel.style.zIndex = '';

                    // 如果当前活动容器是被关闭的子菜单的容器，恢复为主菜单容器
                    if (this.activeScrollContainer === subPanel.querySelector('.{cssClasses_final["scrollContainer"]}')) {{
                        this._restoreMainScroll();
                    }}

                    const info = this.openSubmenus.get(subPanel);
                    if (info) {{
                        // 尝试移回父 li，若父 li 在文档中则归位，否则挂回 body 并隐藏（已隐藏）
                        if (info.parentLi && document.body.contains(info.parentLi) && subPanel.parentNode !== info.parentLi) {{
                            info.parentLi.appendChild(subPanel);
                        }} else if (subPanel.parentNode === document.body && info.parentLi) {{
                            // 父 li 不在文档中，先挂到父 li 上（即使父 li 已被移除，仍需保持关系，下次父 li 恢复时会带出）
                            info.parentLi.appendChild(subPanel);
                        }}
                        this.openSubmenus.delete(subPanel);
                    }}

                    // 清除自身定时器
                    const timer = this._submenuHideTimers.get(subPanel);
                    if (timer) {{
                        clearTimeout(timer);
                        this._submenuHideTimers.delete(subPanel);
                    }}

                    // 如果当前键盘焦点在此子菜单，清除焦点
                    if (this.currentSubmenu === subPanel) {{
                        this.currentSubmenu = null;
                        this.currentSubmenuParent = null;
                        this.submenuItems = [];
                        this.subKeyboardIndex = -1;
                    }}
                }}

                // 新增方法：强制关闭所有子菜单（无状态依赖）
                _forceCloseAllSubmenus() {{
                    // 强制关闭所有子菜单并归位
                    const allSubmenus = document.querySelectorAll('.{cssClasses_final["subPanel"]}');
                    allSubmenus.forEach(panel => {{
                        panel.classList.remove('open');
                        panel.style.display = 'none';
                        panel.style.position = '';
                        panel.style.left = '';
                        panel.style.top = '';
                        panel.style.zIndex = '';
                        const info = this.openSubmenus.get(panel);
                        const parentLi = info?.parentLi || panel.closest('.{cssClasses_final["option_item"]}');
                        if (parentLi && panel.parentNode !== parentLi) {{
                            parentLi.appendChild(panel);
                        }}
                    }});

                    // 清空状态和定时器
                    this._submenuHideTimers.forEach(t => clearTimeout(t));
                    this._submenuHideTimers.clear();
                    clearTimeout(this._hideAllTimer);
                    this.openSubmenus.clear();
                    this.currentSubmenu = null;
                    this.currentSubmenuParent = null;
                    this.submenuItems = [];
                    this.subKeyboardIndex = -1;
                }}

                _hideAllSubmenus() {{
                    // 关闭所有打开的子菜单
                    // 收集所有子菜单，避免遍历中 Map 被修改
                    const panels = Array.from(this.openSubmenus.keys());
                    panels.forEach(sub => this._closeSubmenu(sub));
                    this.openSubmenus.clear();

                    this._submenuHideTimers.forEach(timer => clearTimeout(timer));
                    this._submenuHideTimers.clear();

                    this.currentSubmenu = null;
                    this.currentSubmenuParent = null;
                    this.submenuItems = [];
                    this.subKeyboardIndex = -1;
                }}

                _syncSelectedClass() {{
                    if (!this.selectedValue || !this.dropdown) return;
                    this.dropdown.querySelectorAll('.{cssClasses_final["option_item"]}').forEach(el => {{
                        const val = el.getAttribute('data-value');
                        el.classList.toggle('selected', val === this.selectedValue);
                    }});
                }}

                /** 切换打开/关闭 */
                toggle() {{ this.isOpen ? this.close() : this.open(); }}

                open() {{
                    // 关闭所有其他已打开的实例（互斥）
                    this.constructor.openInstances.forEach(inst => {{
                        if (inst !== this && inst.isOpen) {{
                            inst.close();
                        }}
                    }});

                    if (this.isOpen) return;
                    this.isOpen = true;
                    this._determineDirection();

                    // 挂载主面板到 body，fixed 定位
                    if (this.dropdown.parentNode !== document.body) {{
                        document.body.appendChild(this.dropdown);
                    }}

                    // 临时显示以便测量
                    this.dropdown.style.cssText = 'position:fixed; visibility:hidden; display:block;';
                    // 测量
                    // 直接应用定位（_positionSubmenu 内部会重置样式并设置正确的 fixed）
                    this._positionSubmenu(this.triggerBtn, this.dropdown, 9999, {{ isMain: true, preferUp: this.dropUp }});

                    // 5. 添加 open 类启动动画
                    this.wrapper.classList.add('open');
                    this.dropdown.classList.add('open');
                    if (this.dropUp) this.wrapper.classList.add('drop-up');
                    this.triggerBtn.setAttribute('aria-expanded', 'true');
                    this._scrollToSelected();
                    this._updateArrows();
                    this._resetKeyboardIndex();

                    this._startRafLoop();
                    // this._hideAllSubmenus();

                    // ← 新增：同步选中样式
                    this._syncSelectedClass();
                }}

                close() {{
                    if (!this.isOpen) return;
                    this.isOpen = false;
                    this._stopScroll();
                    this._hideAllSubmenus(); // 或者使用 _forceCloseAllSubmenus()
                    // 子菜单清理已由 _toggleSelection 完成，此处无需再调

                    this.wrapper.classList.remove('open', 'drop-up');
                    this.triggerBtn.setAttribute('aria-expanded', 'false');
                    this._clearKeyboardActive();
                    this.keyboardIndex = -1;
                    this._stopRafLoop();

                    if (this.dropdown) {{
                        // 将面板移回原容器（如果被移到了 body）
                        if (this.dropdown.parentNode !== this.wrapper) {{
                            this.wrapper.appendChild(this.dropdown);
                        }}

                        // 清除所有选项的键盘高亮（包括主菜单和已归位的子菜单）
                        this.dropdown.querySelectorAll('.{cssClasses_final["option_item"]}.keyboard-active').forEach(
                            el => el.classList.remove('keyboard-active')
                        );

                        // 移除 open 类，并重置样式
                        this.dropdown.classList.remove('open');
                        this.dropdown.style.display = 'none';   // 完全隐藏，不占空间
                        this.dropdown.style.position = '';
                        this.dropdown.style.left = '';
                        this.dropdown.style.top = '';
                        this.dropdown.style.zIndex = '';

                    }}
                }}

                /** 判断下拉弹出方向 */
                _determineDirection() {{
                    const rect = this.triggerBtn.getBoundingClientRect();
                    const clientHeight = document.documentElement.clientHeight;
                    const spaceBelow = clientHeight - rect.bottom;
                    const spaceAbove = rect.top;
                    const needed = Math.min(this.config.maxHeight, this.choices.length * 38) + 20;
                    this.dropUp = (spaceBelow < needed && spaceAbove > spaceBelow);
                    const avail = this.dropUp ? spaceAbove : spaceBelow;
                    this.scrollContainer.style.maxHeight = Math.min(this.config.maxHeight, avail - 24) + 'px';
                }}

                /**
                 * 切换选项的选中状态
                 * @param {{string}} value - 选项 value
                 * @param {{string}} label - 选项 label
                */
                _toggleSelection(value, label) {{
                    // 如果点击的是当前已选中的值，则清除选择
                    if (value === this.selectedValue) {{
                        this._clearSelection();
                        return;
                    }}

                    // 静默清除旧状态
                    this._clearSelectionSilent();

                    const panel = this.dropdown; // 始终为主菜单面板，不受挂载位置影响
                    if (panel) {{
                        panel.querySelectorAll('.{cssClasses_final["option_item"]}').forEach(el => {{
                            el.classList.toggle('selected', el.getAttribute('data-value') == value);
                        }});
                    }}

                    // 记录选中值
                    this.selectedValue = value;
                    this.selectedLabel = label;
                    if (this.outputEl) {{
                        this.outputEl.textContent = label;
                        this.outputEl.classList.remove('placeholder');
                    }}

                    // 触发自定义事件，向外部通知选择结果
                    this.wrapper.dispatchEvent(new CustomEvent('{bubbleEvent}', {{
                        bubbles: true,
                        detail: {{ value, label }}
                    }}));

                    // 关闭主菜单
                    this.close();
                }}

                /** 清除当前选中状态 */
                _clearSelectionSilent() {{
                    // 设置抑制标志，阻止任何子菜单打开
                    this._suppressSubmenu = true;

                    // 1. 将所有子菜单归位并隐藏（它们将回到 container 内）
                    this._forceCloseAllSubmenus();

                    // 2. 清除主面板中的选中样式（面板可能在 body 中）
                    if (this.dropdown) {{
                        this.dropdown.querySelectorAll('.{cssClasses_final["option_item"]}.selected').forEach(
                            el => el.classList.remove('selected')
                        );
                    }}

                    // 3. 清除容器内所有子菜单选项的选中样式（子菜单已归位）
                    if (this.wrapper) {{
                        this.wrapper.querySelectorAll('.{cssClasses_final["option_item"]}.selected').forEach(
                            el => el.classList.remove('selected')
                        );
                    }}

                    // 4. 移除选中值
                    this.selectedValue = null;
                    this.selectedLabel = null;
                    if (this.outputEl) {{
                        this.outputEl.textContent = this.config.placeholder || '未选择';
                        this.outputEl.classList.add('placeholder');
                    }}

                    // 5. 注意：不触发外部事件，不调用 close（由外部调用者决定）

                    // 延迟 100ms 解除抑制，确保鼠标事件引起的任何重开都被忽略
                    setTimeout(() => {{
                        this._suppressSubmenu = false;
                    }}, 100);
                }}

                /** 公开方法，触发 null 事件 */
                _clearSelection() {{
                    this._clearSelectionSilent();
                    this.close(); // 关闭主菜单
                    this.wrapper.dispatchEvent(new CustomEvent('{bubbleEvent}', {{
                        bubbles: true,
                        detail: {{ value: null, label: null }}
                    }}));
                }}

                /** 滚动到选中项 */
                _scrollToSelected() {{
                    if (!this.selectedValue) return;
                    const idx = this.optionEls.findIndex(el => el.getAttribute('data-value') == this.selectedValue);
                    if (idx >= 0 && this.optionEls[idx]) {{
                        const el = this.optionEls[idx];
                        const container = this.scrollContainer;
                        const elTop = el.offsetTop;
                        const elBottom = elTop + el.offsetHeight;
                        const scrollTop = container.scrollTop;
                        const viewTop = scrollTop;
                        const viewBottom = scrollTop + container.clientHeight;
                        if (elTop < viewTop + 8) container.scrollTop = elTop - 12;
                        else if (elBottom > viewBottom - 8) container.scrollTop = elBottom - container.clientHeight + 12;
                        this._updateArrows();
                    }}
                }}

                /** 重置键盘索引 */
                _resetKeyboardIndex() {{
                    this._clearKeyboardActive();
                    this.keyboardIndex = (
                        this.selectedValue
                        ? this.optionEls.findIndex(el => el.getAttribute('data-value') == this.selectedValue)
                        : 0
                    );
                    if (this.keyboardIndex < 0) this.keyboardIndex = 0;
                    this._setKeyboardActive(this.keyboardIndex);
                }}

                /** 当子菜单打开时确保没有选项自动高亮 */
                _clearKeyboardActive() {{ this.optionEls.forEach(el => el.classList.remove('keyboard-active')); }}
                _clearSubKeyboardActive() {{
                    if (this.submenuItems) {{
                        this.submenuItems.forEach(el => el.classList.remove('keyboard-active'));
                    }}
                }}

                /** 键盘焦点移到子菜单 */
                _focusSubmenu(subPanel) {{
                    this.currentSubmenu = subPanel;
                    // 只选取子菜单下第一层 {cssClasses_final["optionsList"]} 中的直接子元素，并过滤出 .{cssClasses_final["option_item"]}
                    const scrollContainer = subPanel.querySelector(':scope > .{cssClasses_final["scrollContainer"]}');
                    const list = (
                        scrollContainer
                        ? scrollContainer.querySelector(':scope > .{cssClasses_final["optionsList"]}')
                        : null
                    );
                    this.submenuItems = (
                        list
                        ? Array.from(list.children).filter(li => li.classList.contains('{cssClasses_final["option_item"]}'))
                        : []
                    );
                    this._clearSubKeyboardActive();
                    // 子菜单打开时不自动高亮，subKeyboardIndex 保持 -1
                    this.subKeyboardIndex = -1;
                }}

                /** 设置键盘活跃索引 */
                _setKeyboardActive(index) {{
                    this._clearKeyboardActive();
                    this.keyboardIndex = index;
                    if (this.optionEls[index]) {{
                        this.optionEls[index].classList.add('keyboard-active');
                        const el = this.optionEls[index];
                        const container = this.scrollContainer;
                        const elTop = el.offsetTop, elBottom = elTop + el.offsetHeight;
                        if (elTop < container.scrollTop) {{
                            container.scrollTop = elTop - 4;
                        }} else if (elBottom > container.scrollTop + container.clientHeight) {{
                            container.scrollTop = elBottom - container.clientHeight + 4;
                        }}
                        this._updateArrows();
                    }}
                }}
                _applySubKeyboardHighlight() {{
                    this._clearSubKeyboardActive();
                    if (this.subKeyboardIndex >= 0 && this.subKeyboardIndex < this.submenuItems.length) {{
                        this.submenuItems[this.subKeyboardIndex].classList.add('keyboard-active');
                    }}
                }}

                /** 键盘导航（增强） */
                _onKeyDown(e) {{
                    if (!this.isOpen) {{
                        if (['ArrowDown','ArrowUp','Enter',' '].includes(e.key)) {{ e.preventDefault(); this.open(); }}
                        return;
                    }}

                    // 如果焦点在子菜单内
                    if (this.currentSubmenu) {{
                        const len = this.submenuItems.length;
                        switch (e.key) {{
                            case 'ArrowUp':
                                e.preventDefault();
                                if (this.submenuItems.length === 0) return;
                                if (this.subKeyboardIndex === -1) this.subKeyboardIndex = 0;
                                this.subKeyboardIndex = (this.subKeyboardIndex - 1 + len) % len;
                                this._applySubKeyboardHighlight();
                                this._scrollSubmenuIntoView();
                                break;
                            case 'ArrowDown':
                                e.preventDefault();
                                if (this.submenuItems.length === 0) return;
                                if (this.subKeyboardIndex === len - 1) this.subKeyboardIndex = -1;
                                this.subKeyboardIndex = (this.subKeyboardIndex + 1) % len;
                                this._applySubKeyboardHighlight();
                                this._scrollSubmenuIntoView();
                                break;
                            case 'Enter':
                            case ' ':
                                e.preventDefault();
                                if (this.subKeyboardIndex >= 0 && this.subKeyboardIndex < len) {{
                                    const el = this.submenuItems[this.subKeyboardIndex];
                                    const value = el.getAttribute('data-value');
                                    const labelEl = el.querySelector('.{cssClasses_final["option_label"]}');
                                    const label = labelEl ? labelEl.textContent.trim() : value;
                                    this._toggleSelection(value, label);
                                }}
                                break;
                            case 'ArrowRight':
                                e.preventDefault();
                                if (this.subKeyboardIndex < 0) break;
                                const currentEl = this.submenuItems[this.subKeyboardIndex];
                                const sub = currentEl?.querySelector('.{cssClasses_final["subPanel"]}');
                                if (sub) {{
                                    this.currentSubmenuParent = currentEl;
                                    const panel = this._showSubmenu(currentEl, sub);
                                    this._focusSubmenu(panel);
                                }}
                                break;
                            case 'ArrowLeft':
                                e.preventDefault();
                                const currentPanel = this.currentSubmenu;
                                const info = this.openSubmenus.get(currentPanel);
                                // 先关闭当前子菜单（内部可能触发焦点恢复，但我们随后会覆盖）
                                this._closeSubmenu(currentPanel);

                                if (info && info.parentMenu) {{
                                    // 父菜单是另一个子菜单面板
                                    const parentMenu = info.parentMenu;
                                    // 重新聚焦到父菜单
                                    this._focusSubmenu(parentMenu);
                                    // 高亮父菜单中对应的父选项
                                    const parentVal = info.parentLi.getAttribute('data-value');
                                    const idx = this.submenuItems.findIndex(el => el.getAttribute('data-value') == parentVal);
                                    if (idx >= 0) {{
                                        this.subKeyboardIndex = idx;
                                        this._applySubKeyboardHighlight();
                                        this._scrollSubmenuIntoView();
                                    }}
                                }} else if (info && info.parentLi) {{
                                    // 父菜单是主菜单
                                    const parentVal = info.parentLi.getAttribute('data-value');
                                    const idx = this.optionEls.findIndex(el => el.getAttribute('data-value') == parentVal);
                                    if (idx >= 0) this._setKeyboardActive(idx);
                                    // 清除子菜单焦点状态
                                    this.currentSubmenu = null;
                                    this.currentSubmenuParent = null;
                                    this.submenuItems = [];
                                    this.subKeyboardIndex = -1;
                                }} else {{
                                    // 无记录时回退到主菜单第一项
                                    this._resetKeyboardIndex();
                                    this.currentSubmenu = null;
                                    this.currentSubmenuParent = null;
                                    this.submenuItems = [];
                                    this.subKeyboardIndex = -1;
                                }}
                                break;
                            case 'Escape':
                                e.preventDefault();
                                this._hideAllSubmenus();
                                this._resetKeyboardIndex();
                                break;
                        }}
                        return;
                    }}

                    // 主菜单按键处理
                    const len = this.optionEls.length;
                    switch (e.key) {{
                        case 'ArrowDown':
                            e.preventDefault();
                            this._setKeyboardActive((this.keyboardIndex + 1) % len);
                            break;
                        case 'ArrowUp':
                            e.preventDefault();
                            this._setKeyboardActive((this.keyboardIndex - 1 + len) % len);
                            break;
                        case 'ArrowRight':
                            e.preventDefault();
                            const currentEl = this.optionEls[this.keyboardIndex];
                            if (!currentEl) break;
                            const subPanel = this._showSubmenu(
                                currentEl
                                ,currentEl.querySelector('.{cssClasses_final["subPanel"]}')
                            );
                            this.currentSubmenuParent = currentEl;
                            this._focusSubmenu(subPanel);
                            break;
                        case 'ArrowLeft':
                            // 主菜单无左侧父级，忽略
                            e.preventDefault();
                            break;
                        case 'Enter':
                        case ' ':
                            e.preventDefault();
                            if (this.keyboardIndex >= 0) {{
                                const el = this.optionEls[this.keyboardIndex];
                                const sub = el.querySelector('.{cssClasses_final["subPanel"]}');
                                if (sub && !sub.classList.contains('open')) {{
                                    this._showSubmenu(el, sub);
                                    this.currentSubmenuParent = el;
                                    this._focusSubmenu(sub);
                                }} else if (!sub) {{
                                    const value = el.getAttribute('data-value');
                                    const labelEl = el.querySelector('.{cssClasses_final["option_label"]}');
                                    const label = labelEl ? labelEl.textContent.trim() : value;
                                    this._toggleSelection(value, label);
                                }}
                            }}
                            break;
                        case 'Escape':
                            e.preventDefault();
                            if (this.openSubmenus.size > 0) {{
                                this._hideAllSubmenus();
                                this._resetKeyboardIndex();
                            }} else {{
                                this.close();
                            }}
                            this.triggerBtn.focus();
                            break;
                        case 'Tab':
                            this.close();
                            this.triggerBtn.focus();
                            break;
                    }}
                }}

                /** 定位子菜单 */
                _scrollSubmenuIntoView() {{
                    if (!this.currentSubmenu || this.subKeyboardIndex < 0) return;
                    const el = this.submenuItems[this.subKeyboardIndex];
                    const scrollContainer = this.currentSubmenu.querySelector(':scope > .{cssClasses_final["scrollContainer"]}');
                    if (!scrollContainer) return;
                    const containerRect = scrollContainer.getBoundingClientRect();
                    const elRect = el.getBoundingClientRect();
                    if (elRect.top < containerRect.top) {{
                        scrollContainer.scrollTop -= (containerRect.top - elRect.top) - 4;
                    }} else if (elRect.bottom > containerRect.bottom) {{
                        scrollContainer.scrollTop += (elRect.bottom - containerRect.bottom) + 4;
                    }}
                }}

                /** 动态改变上下箭头的样式 */
                _updateArrows() {{
                    const c = this.activeScrollContainer;
                    const max = c.scrollHeight - c.clientHeight;
                    const has = max > 2;
                    this.activeArrowUp.classList.toggle('visible', has && c.scrollTop > 2);
                    this.activeArrowUp.classList.toggle('disabled', !has || c.scrollTop <= 2);
                    this.activeArrowDown.classList.toggle('visible', has && c.scrollTop < max - 2);
                    this.activeArrowDown.classList.toggle('disabled', !has || c.scrollTop >= max - 2);
                }}

                /** 按照给定方向开始滚动 */
                _startScroll(dir) {{
                    const arrow = dir === -1 ? this.activeArrowUp : this.activeArrowDown;
                    if (arrow.classList.contains('disabled')) return;
                    this.scrollDir = dir;
                }}
                _stopScroll() {{ this.scrollDir = 0; }}

                // 辅助方法：恢复主菜单为活动滚动容器
                _setActiveScroll(container, upArrow, downArrow) {{
                    this.activeScrollContainer = container;
                    this.activeArrowUp = upArrow;
                    this.activeArrowDown = downArrow;
                }}

                _restoreMainScroll() {{
                    this.activeScrollContainer = this.mainScrollContainer;
                    this.activeArrowUp = this.mainArrowUp;
                    this.activeArrowDown = this.mainArrowDown;
                    this._updateArrows();
                }}

                /** 使用requestAnimationFrame循环，在每一帧中检查鼠标位置并决定是否滚动 */
                _startRafLoop() {{ if (!this.rafId) this._rafLoop(); }}
                _stopRafLoop() {{ if (this.rafId) {{ cancelAnimationFrame(this.rafId); this.rafId = null; }} }}

                _rafLoop() {{
                    if (this.isOpen && this.scrollDir !== 0) {{
                        const c = this.activeScrollContainer;
                        const max = c.scrollHeight - c.clientHeight;
                        const speed = this.config.scrollSpeed;
                        if (this.scrollDir === -1) c.scrollTop = Math.max(0, c.scrollTop - speed);
                        else c.scrollTop = Math.min(max, c.scrollTop + speed);
                        this._updateArrows();
                        if ((this.scrollDir === -1 && c.scrollTop <= 0) || (this.scrollDir === 1 && c.scrollTop >= max)) {{
                            this.scrollDir = 0;
                        }}
                    }}
                    if (this.isOpen) this.rafId = requestAnimationFrame(() => this._rafLoop());
                }}

                /** 接收外部指令并重绘组件 */
                updateData(choices) {{
                    this.choices = choices;
                    this._renderOptions();
                    this._updateArrows();
                }}

                /**
                 * 根据 value 值程序化选中一个选项（自动查找 label）
                 * @param {{string}} value - 要选中的选项 value
                */
                selectByValue(value) {{
                    if (value === null || value === undefined) {{
                        this._clearSelection(); // 触发 null 事件
                        return; // 不输出警告
                    }}
                    const label = this._findLabelByValue(this.choices, value);
                    if (label) {{
                        this._toggleSelection(value, label);
                    }} else {{
                        console.warn(`{funcName}: value "${{value}}" not found in choices.`);
                    }}
                }}

                /**
                 * 递归查找 value 对应的 label
                 * @param {{Array}} nodes - 当前层级的选项数组（可能是分组对象、普通选项等）
                 * @param {{string}} value - 目标 value
                 * @returns {{string|null}} 找到的 label，或 null
                */
                _findLabelByValue(nodes, value) {{
                    if (!nodes || !Array.isArray(nodes)) return null;
                    for (const item of nodes) {{
                        // 分组结构：{{ label, options: [...] }}
                        if (item.options && !item.value) {{
                            const found = this._findLabelByValue(item.options, value);
                            if (found) return found;
                        }}
                        // 普通选项或带子菜单的选项
                        else {{
                            if (item.value === value) return item.label;
                            if (item.children && item.children.length > 0) {{
                                const found = this._findLabelByValue(item.children, value);
                                if (found) return found;
                            }}
                        }}
                    }}
                    return null;
                }}

                dispose() {{
                    // 关闭所有打开的菜单
                    this.close();
                    this._hideAllSubmenus();

                    // 移除全局事件监听器（需要在构造函数中保存引用）
                    if (this._docClickHandler) {{
                        document.removeEventListener('click', this._docClickHandler, true);
                    }}
                    if (this._resizeHandler) {{
                        window.removeEventListener('resize', this._resizeHandler);
                    }}

                    // 清除所有定时器
                    clearTimeout(this._hideAllTimer);
                    this._submenuHideTimers.forEach(timer => clearTimeout(timer));
                    this._submenuHideTimers.clear();
                    this._stopRafLoop();

                    // 将主菜单面板归位并移除
                    if (this.dropdown) {{
                        if (this.dropdown.parentNode) {{
                            this.dropdown.parentNode.removeChild(this.dropdown);
                        }}
                    }}

                    // 强制清理所有可能残留的子菜单面板
                    const allSubmenus = this.wrapper.querySelectorAll('.{cssClasses_final["subPanel"]}');
                    allSubmenus.forEach(panel => {{
                        if (panel.parentNode) panel.parentNode.removeChild(panel);
                    }});

                    // 从静态实例集合中移除自身
                    this.constructor.openInstances.delete(this);

                    // 移除触发按钮上的事件（如果不想保留按钮功能）
                    // 此处可选，通常销毁后按钮不再可用
                    if (this.triggerBtn) {{
                        this.triggerBtn.replaceWith(this.triggerBtn.cloneNode(true));
                    }}
                    if (this._hotkeyHandler) {{
                        document.removeEventListener('keydown', this._hotkeyHandler);
                        this._hotkeyHandler = null;
                    }}
                }}
            }}

            // console.log('{funcName} class defined:', typeof {funcName});
        }}
    ''')

    #900. Return the snippet
    return(js_snippet)
#End jsDropdownSelect

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import os
    import sys
    from inspect import cleandoc
    from shiny import ui, reactive
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp import jsDropdownSelect, TagsCollection
    print(jsDropdownSelect.__doc__)

    #100. Export the JS script with the default configuration
    out_script = r'D:\Temp\jsDropdownSelect.js'
    with open(out_script, 'w', encoding = 'utf-8') as f:
        f.write(jsDropdownSelect())

    #190. Purge
    if os.path.isfile(out_script): os.remove(out_script)

    #200. Full parameters to call this function
    #210. Initial parameters
    #[ASSUMPTION]
    #[1] `dds-` is a convention to make unique namespace for these classes, feel free to change it during customization
    #[2] `window.` is NOT a prefix of the name of the class, but indicates its affiliation. Since it is defined within a local
    #     scope (`if` clause), we have to attach it to a global object as workaround, to make it relatively global
    #[3] All CSS classes used within the class definition are exposed in <cssClasses>, feel free to customize them.
    #    Notice: each value represents a single CSS class name. DO NOT provide multiple classes in one value
    #[4] All internal items that allow to append additional classes are exposed in <cssClassesAdd>. Feel free to append multiple
    #    CSS classes to the same item in the syntax of CSS
    #    [1] `None` as value is NOT accepted; if you do not need to customize any of the items, leave it as is or remove it
    #        from provision
    #    [2] Provide more classes, split by spaces, will append them to the classList of the item, so they will have higher
    #        prority as display styles
    #[5] The rest of arguments are just placeholders (i.e. default values) of the objects for argument `config` in the JS class
    #     constructor, so if there are any direct calls to the JS class at front-end at runtime, with certain customization on
    #     `config` parameters, the inputs provided here will be overwritten
    #[6] <arrows> is exposed for users to customize the scroll and paging directives within the component.
    #[7] 重要！！！若下方给出了不同的自定义配置，则 `dds_args['funcName']` 必须设定不同的值，否则由JS Class设计的自保功能会令第一次注入的脚本生效
    #    [1] 两次注入的hash不同，因此`ui.head_content`认为注入了不同脚本（确实不同）；最终`head`中会有两段类似的注入
    #    [2] 此时若JS Class名称相同，则自保机制会防止第二段脚本执行（即使它们注入到`head`以外的位置）
    dds_args = {
        'funcName' : 'window.DropdownSelect'
        ,'bubbleEvent' : 'dds-select-change'
        ,'cssClasses' : {
            #010. Exposed classes for the wrapper itself
            'wrapper' : 'dds-wrapper'
            ,'embeddedStylesId' : 'dds-emb-styles'
            #100. Classes bound to the internal element/container, as named in the keys
            ,'outputEl' : 'dds-selected-output'
            ,'triggerBtn' : 'dds-trigger-btn'
            ,'dropdown' : 'dds-dropdown-panel'
            ,'scrollContainer' : 'dds-scroll-container'
            ,'optionsList' : 'dds-options-list'
            ,'arrowUp' : 'dds-scroll-arrow-up'
            ,'arrowDown' : 'dds-scroll-arrow-down'
            ,'subPanel' : 'dds-submenu-panel'
            ,'groupLabel' : 'dds-option-group-label'
            #500. Classes that are internally used without being bound to certain names
            ,'scroll_arrow' : 'dds-scroll-arrow'
            ,'arrow_icon' : 'dds-arrow-icon'
            ,'option_separator' : 'dds-option-separator'
            ,'option_item' : 'dds-option-item'
            ,'option_indicator' : 'dds-option-indicator'
            ,'option_label' : 'dds-option-label'
            ,'submenu_arrow' : 'dds-submenu-arrow'
            ,'hitarea' : 'dds-hitarea'
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
            ,'hitarea' : ''
        }
        ,'maxHeight' : 600
        ,'minHeight' : 40
        ,'minWidth' : 40
        ,'scrollSpeed' : 5.5
        ,'windowGap' : 10
        ,'submenuGap' : 4
        ,'submenuMaxHeight' : 600
    }

    #220. Prepare arrows
    tc = TagsCollection()

    dds_args['arrows'] = {
        'up' : tc.arrow(
            'up'
            ,class_ = dds_args['cssClasses']['arrow_icon']
        )
        ,'down' : tc.arrow(
            'down'
            ,class_ = dds_args['cssClasses']['arrow_icon']
        )
        ,'right' : tc.arrow(
            'right'
            ,class_ = dds_args['cssClasses']['arrow_icon']
            ,style = 'width: 14px; height: 14px;'
        )
        ,'left' : tc.arrow(
            'left'
            ,class_ = dds_args['cssClasses']['arrow_icon']
            ,style = 'width: 14px; height: 14px;'
        )
    }

    #225. Prepare patches to the CSS classes of the arrows
    #[ASSUMPTION]
    #[1] In the original design, the arrows have two classes in the first place
    #[2] Hence if we have to add more classes, we need to append to the last
    css_arrow_up = [
        dds_args['cssClasses']['scroll_arrow']
        ,dds_args['cssClasses']['arrowUp']
        ,dds_args['cssClassesAdd']['scroll_arrow'] or None
    ]
    css_arrow_down = [
        dds_args['cssClasses']['scroll_arrow']
        ,dds_args['cssClasses']['arrowDown']
        ,dds_args['cssClassesAdd']['scroll_arrow'] or None
    ]

    #290. Prepare the full snippet of the JS class definition
    #[ASSUMPTION]
    #[1] Above parameters are all default ones, so below function call has be same effect as: `jsDropdownSelect()`
    js_dds = jsDropdownSelect(**dds_args)

    #300. Example of the structure of available choices
    #[ASSUMPTION]
    #[1] Basic structure: basic_struct = [{'value':'...','label':'...'},...]
    #    [1] It indicates a simple one-level dropdown panel
    #[2] Parental structure: parental_struct = [{'value':'...','label':'...','children':obj},...]
    #    [1] It indicates there are next levels as sub-panels
    #    [2] `obj` is another basic structure or parental one
    #[3] With group: group_struct = [{'label':'...','options':substruct},...], where `substruct` is in either shape of below
    #    [1] Basic structure
    #    [2] Parental structure
    #[4] If `options` exists in a choice
    #    [1] `value` is ignored if any, suggest not providing it to avoid unexpected result
    #    [2] `label` becomes the group label and cannot be focused or clicked in the component
    #    [3] Items inside `options` will be collected in one group
    #[5] If `options` exists in one level/layer, all items in that level/layer should be in the same shape as `group_struct`,
    #    i.e. all items in that level/layer should be in their own groups without exception
    choices = [
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

    #350. Example of message passed to the instance
    js_payload = {'value' : 'sz_ns'}

    #500. Prepare an icon to display on the left of the trigger button
    #[ASSUMPTION]
    #[1] Example of introduction of an external icon for the trigger button of this component
    icon_styles = cleandoc("""
        .operation-icon {
            color: #6b7280;
            width: 20px;
            height: 20px;
            line-height: 20px;
            text-align: center;
        }
        .icon-group {
            margin-top: 4px;
        }
        .icon-group::before {
            content: '⊞';
        }
    """)
    icon = ui.tags.div(class_='operation-icon icon-group')

    #600. Define all necessary tags to form this component in `shiny` App
    #[ASSUMPTION]
    #[1] 以下除最外层wrapper以外，各容器的id都没有用到（内部均用selector选择wrapper内的class），可不加，更可以不用ns交给后端
    #[2] 最外层div须设定class（`shiny`中须加参数`class_`，因其不能与Python关键字冲突），且须等于 dds_args['cssClasses']['wrapper']
    #    [1] JS功能完全依赖于这个class
    #[3] 根据`shiny`的设计，若需交互功能，最外层div:（见<ShinyApp.Modules.DropdownSelect>）
    #    [1] 须设定`id`; 若由module驱动，该`id`还须加上ns（namespace），因`ui.tags`不会自动加ns。
    #    [2] 须设定`output_id`（会由`shiny`转译成HTML的`output-id`）属性; 若由module驱动，该`id`还须加上ns（namespace）
    #        [1] 后端对API的监听完全依赖于这个属性值
    #        [2] 它的具体值不重要，因为都是后端引用；前提是它整个session全局唯一
    dds_id = 'custom_select'
    selected_output_id = 'selected_output'
    dds_component = ui.tags.div(
        ui.tags.div(
            ui.tags.button(
                ui.tags.div(
                    icon
                    ,ui.tags.div('Open')
                    ,tc.arrow(
                        'down'
                        ,style = 'width: 10px; height: 10px; margin-top: 4px;'
                    )
                    ,style = 'display: flex; flex-direction: row;'
                )
                ,id = 'trigger'
                ,class_ = dds_args['cssClasses']['triggerBtn']
                ,aria_label = '打开下拉列表'
            )
            ,ui.tags.span(
                '未选择'
                ,id = 'selected-output'
                ,class_ = dds_args['cssClasses']['outputEl'] + ' placeholder'
                # ,style = 'display: none;'
            )
            ,style = 'display: flex; flex-direction: row;'
        )
        ,ui.tags.div(
            ui.tags.div(
                dds_args['arrows']['up']
                ,id = 'arrow-up'
                ,class_ = ' '.join([s for s in css_arrow_up if isinstance(s, str)])
            )
            ,ui.tags.div(
                ui.tags.ul(
                    id = 'options-list'
                    ,class_ = dds_args['cssClasses']['optionsList']
                )
                ,id = 'scroll-container'
                ,class_ = dds_args['cssClasses']['scrollContainer']
            )
            ,ui.tags.div(
                dds_args['arrows']['down']
                ,id = 'arrow-down'
                ,class_ = ' '.join([s for s in css_arrow_down if isinstance(s, str)])
            )
            ,id = 'dropdown'
            ,class_ = dds_args['cssClasses']['dropdown']
        )
        ,id = dds_id
        ,class_ = dds_args['cssClasses']['wrapper']
        # 传递命名空间，JS 读取
        ,output_id = selected_output_id
    )

    #690. Full HTML structure to make this component work
    all_tags = ui.tags.div(
        #100. Inject this function into the head tag of HTML and ensure its uniqueness
        ui.head_content(
            ui.tags.script(js_dds)
            ,ui.tags.style(icon_styles)
        )
        ,dds_component
    )

    #700. Verify the final HTML structure of this component, which is the same as when you instantiate it directly in HTML
    # print(dds_component)
    _ = """
        <div id='custom_select' class='dds-wrapper' output-id='selected_output'>
          <div style='display: flex; flex-direction: row;'>
            <button id='trigger' class='dds-trigger-btn' aria-label='打开下拉列表'>
              <div style='display: flex; flex-direction: row;'>
                <div class='operation-icon icon-group'></div>
                <div>Open</div>
                <svg
                  viewBox='0 0 24 24'
                  fill='none'
                  stroke='currentColor'
                  stroke-width='2.5'
                  stroke-linecap='round'
                  stroke-linejoin='round'
                  style='width: 10px; height: 10px; margin-top: 4px;'
                >
                  <polyline points='6 9 12 15 18 9'></polyline>
                </svg>
              </div>
            </button>
            <span id='selected-output' class='dds-selected-output placeholder'>未选择</span>
          </div>
          <div id='dropdown' class='dds-dropdown-panel'>
            <div id='arrow-up' class='dds-scroll-arrow dds-scroll-arrow-up'>
              <svg
                viewBox='0 0 24 24'
                fill='none'
                stroke='currentColor'
                stroke-width='2.5'
                stroke-linecap='round'
                stroke-linejoin='round'
                class='dds-arrow-icon'
              >
                <polyline points='18 15 12 9 6 15'></polyline>
              </svg>
            </div>
            <div id='scroll-container' class='dds-scroll-container'>
              <ul id='options-list' class='dds-options-list'></ul>
            </div>
            <div id='arrow-down' class='dds-scroll-arrow dds-scroll-arrow-down'>
              <svg
                viewBox='0 0 24 24'
                fill='none'
                stroke='currentColor'
                stroke-width='2.5'
                stroke-linecap='round'
                stroke-linejoin='round'
                class='dds-arrow-icon'
              >
                <polyline points='6 9 12 15 18 9'></polyline>
              </svg>
            </div>
          </div>
        </div>
    """

    #800. API使用指引
    #810. API使用（JS方法）
    #811. 创建组件
    _ = f"""
        new {dds_args['funcName']}(
            document.getElementById('{dds_id}')
            ,{choices}
            ,{{
                maxHeight: {dds_args['maxHeight']},
                minHeight: {dds_args['minHeight']},
                minWidth: {dds_args['minWidth']},
                scrollSpeed: {dds_args['scrollSpeed']},
                windowGap: {dds_args['windowGap']},
                submenuGap: {dds_args['submenuGap']},
                submenuMaxHeight: {dds_args['submenuMaxHeight']},
            }}
        );
    """

    #815. 重绘选项
    _ = f"""
        {dds_args['funcName']}.updateData({choices});
    """

    #817. 程序化变更已选项
    _ = f"""
        {dds_args['funcName']}.selectByValue({js_payload.value});
    """

    #830. API使用（`shiny`方法，完整实现参考<ShinyApp.Modules.DropdownSelect>）
    # Setup a valid attribute name for JS object to attach the component. See its usage below
    el_func_name = dds_args['funcName'].split('.')[-1]
    msgpfx_choices = 'dropdown_data_'
    msgpfx_pgm_select = 'select_value_'

    #831. 创建组件
    #[ASSUMPTION]
    #[1] 该方法允许在一个App创建多个实例，并只用一个监听来令它们分别更新（`output-id`起到隔离作用），可以节省资源
    #[2] 因此，这一段script应当用`ui.head_content`放入`head`中使用（这样就可以去重）。下同
    #[3] 重要！！！若下方给出了不同的自定义配置，不会影响JS Class的定义部分，因此仅影响实例创建和事件监听
    _ = f"""
        $(document).on('shiny:connected', function() {{
            // 为每个组件实例化或更新数据（通过自定义消息）
            document.querySelectorAll('.{dds_args["cssClasses"]["wrapper"]}').forEach(function(el) {{
                if (!el) return;
                // 这里的`output-id`就是之前创建组件时设置的`output_id`，值无所谓，因为都是引用
                const shinyInputId = el.getAttribute('output-id');
                if (!shinyInputId) return;
                Shiny.addCustomMessageHandler(`{msgpfx_choices}${{shinyInputId}}`, function(choices) {{
                    if (!el.{el_func_name}) {{
                        el.{el_func_name} = new {dds_args['funcName']}(el, choices, {{
                            output_id: shinyInputId,
                            // 可在此处添加其他自定义配置
                            // maxHeight: {dds_args['maxHeight']},
                        }});
                    }} else {{
                        el.{el_func_name}.updateData(choices);
                    }}
                }});
            }});
        }});
    """

    # 须同时在server部分定义方法来异步发送message供JS监听
    def appserver(input, output, session, choices):
        @reactive.effect
        async def _send_choices():
            data = choices()
            if data is None:
                return
            # 通过自定义消息发送给客户端 JS
            await session.send_custom_message(f'{msgpfx_choices}{selected_output_id}', data)

    #835. 重绘选项
    #[ASSUMPTION]
    #[1] 以上监听方法已实现

    #837. 程序化变更已选项
    _ = f"""
        $(document).on('shiny:connected', function() {{
            document.querySelectorAll('.{dds_args["cssClasses"]["wrapper"]}').forEach(function(el) {{
                if (!el) return;
                const shinyInputId = el.getAttribute('output-id');
                if (!shinyInputId) return;

                // 接收程序化指令，用于自动更新选中的选项
                Shiny.addCustomMessageHandler(`{msgpfx_pgm_select}${{shinyInputId}}`, function(payload) {{
                    if (el.{el_func_name}) {{
                        if (payload) {{
                            el.{el_func_name}.selectByValue(payload.value);
                        }}
                    }}
                }});
            }});
        }});
    """

    # 须同时在server部分定义方法来异步发送message供JS监听
    def appserver(input, output, session, listenPayload):
        @reactive.effect
        async def _pgm_selection():
            value = listenPayload()
            if isinstance(value, str):
                if value:
                    await session.send_custom_message(
                        f'{msgpfx_pgm_select}{selected_output_id}'
                        ,{'value' : value.strip()}
                    )

    #839. 动态获取前端已选择的选项数据
    #[ASSUMPTION]
    #[1] 此时之前设置的`selected_output_id`便成为后端监听的`input[selected_output_id]`，用`setInputValue`发送给后端
    _ = f"""
        $(document).on('shiny:connected', function() {{
            // 监听所有下拉组件的变化事件
            $(document).on('{dds_args["bubbleEvent"]}', '.{dds_args["cssClasses"]["wrapper"]}', function(e) {{
                const shinyInputId = e.currentTarget.getAttribute('output-id');
                if (!shinyInputId) return;
                // console.log(e.detail);
                Shiny.setInputValue(shinyInputId, e.detail, {{ priority: 'event' }});
            }});
        }});
    """

    # 在server部分的监听方法
    def appserver(input, output, session):
        selected_result = reactive.value(None)
        @reactive.effect
        def _watch_selection():
            sel = input[selected_output_id]()
            if sel is None:
                return
            selected_result.set(sel)
#-Notes- -End-
'''
