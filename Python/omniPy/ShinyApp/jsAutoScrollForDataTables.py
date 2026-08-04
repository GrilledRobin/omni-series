#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from inspect import cleandoc

def jsAutoScrollForDataTables(
    funcName : str = 'autoScrollForDataTables'
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the HTML front end, NOT necessarily inside <shiny> app, to          #
#   | complement the <DataTables.js> default <scrollY=100%> behavior when the parent container of <ITable> is flex                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Default option <scrollY=100%> does not fill the table into the space of a flex container properly, as there are too many       #
#   |     sub-containers along the ancestral tree, while they are not set proper `height` to broadcast the height of the root container #
#   |[2] We complement this part by setting proper `height` style for all containers along the ancestral tree                           #
#   |    [1] At `layout` layer of the tree, there could be several sibling containers to the `.dt-layout-table`, so its height becomes  #
#   |        no longer `100%`, but rather `calc(100% - total height of the siblings)`                                                   #
#   |    [2] At `scroll` layer of the tree, there could be a sibling `.dt-scroll-head` to the `.dt-scroll-body`, so its height becomes  #
#   |        no longer `100%`, but rather `calc(100% - height of the scroll head)`                                                      #
#   |    [3] All the top and bottom margins should be taken into account during the calculation as well                                 #
#   |    [4] The rest parent containers to `table.dataTable` should maintain `height:100%` to propagate correct calculation             #
#   |    [5] At last, we should handle some other styles that prevent the correct display                                               #
#   |[3] During the identification of sibling containers, it is presumed that all the containers at any layer inside `DataTables` widget#
#   |     are displayed from top to bottom, instead of from left to right. Their height can hence be deducted. There could be a rough   #
#   |     solution to handle the case where the containers are placed from left to right (not easy to handle all cases), please check   #
#   |     the `skeleton` part of the docstring for details.                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The `body` of the HTML should be flex, e.g. using `shiny.ui.page_fillable`, to ensure dynamic filling of empty space           #
#   |[2] The argument of `DataTables`, e.g. `itables.widget.ITable`, should set `scrollY=100%` to compromise this solution, and it      #
#   |     CANNOT be set as `scrollY=100vh` since this value is not able to be propagated properly                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Set the `DataTable` to fill the rest viewport of the whole page, esp. fill the full height                                     #
#   |[2] Also provide optional argument `fullwidth` to fill the width when needed                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Arguments in the injected JS function]                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[selector       ] <String  > HTML selector for the parent container of the `DataTables` widget, rather than the widget itself      #
#   |[headHeight     ] <Number  > (Optional) Set a customized height of `head`, see the comments for the reason                         #
#   |[fullwidth      ] <Boolean > Whether to set the `DataTable` as full width in the container                                         #
#   |                  [true                ] <Default> Set the table as full width in the container                                    #
#   |                  [false               ]           Use the default behavior of table width in `DataTables.js`                      #
#   |[debug          ] <Boolean > Whether to print debug information in `console.log`                                                   #
#   |                  [false               ] <Default> Suppress the debug information                                                  #
#   |                  [true                ]           Print debug information in `console.log`                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |funcName          :   <str > Customize the JS function name to setup more than one universal function in the console               #
#   |                      [<see def.>          ] <Default> Use a universal function name to be in use for the whole web page           #
#   |                      [<str>               ]           Set different function names to test the functionality                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   Character representation of JS snippet                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260702        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |inspect                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #050. Local parameters
    # op_slash = '' if consoleLog else '// '
    # op_rem_bgn = '' if consoleLog else '/*'
    # op_rem_end = '' if consoleLog else '*/'

    #800. Setup the JS program
    js_snippet = cleandoc(f'''
        function {funcName}({{ selector, headHeight, fullwidth = true, debug = false }} = {{}}) {{
            // 005. Locate the dedicated root member
            const thisroot = document.querySelector(selector);
            if (!thisroot) {{
                console.warn('{funcName}: 未找到元素', selector);
                return;
            }}

            // 010. Local parameters
            const _debug = !!debug;
            const MAX_RETRIES = 30;
            const RETRY_DELAY = 100;
            let retries = 0;

            // 200. Helper functions
            // 210. Function to detect certain conditions before the main activity
            function applyOnceReady() {{
                // 010. Locate the `head` and `body` of the table respectively
                const thishead = thisroot.querySelector('.dt-scroll-head table.dataTable');
                const thisbody = thisroot.querySelector('.dt-scroll-body table.dataTable');

                // 090. Continuous detection of the existence of the dedicated member
                if (!thisbody) {{
                    if (retries < MAX_RETRIES) {{
                        retries++;
                        setTimeout(applyOnceReady, RETRY_DELAY);
                        return;
                    }} else {{
                        console.error('{funcName}: 等待超时，未找到 table.dataTable (body)');
                        return;
                    }}
                }}

                // 100. 允许横向填满视窗
                if (fullwidth) {{
                    thisbody.style.width = '100%';
                    thisbody.parentElement.style.width = '100%';
                    // 经测试，这一步无法令复杂表格的 `head` 元素自动填满视窗，需要在进程中额外触发表格重绘。见 example
                    if (thishead) thishead.style.width = '100%';
                }}

                // 200. 给定的最外层容器样式
                Object.assign(thisroot.style, {{
                    flex: '1 1 0%',
                    minHeight: '0px',
                    overflow: 'hidden',
                    display: 'flex',
                    flexDirection: 'column'
                }});
                ['flex', 'minHeight', 'overflow', 'display', 'flexDirection'].forEach(prop => {{
                    thisroot.style.setProperty(prop, thisroot.style[prop], 'important');
                }});

                // 300. 消除 shinywidgets 400px 魔数
                // 具体selector为: `forward-fill-potential > *` 也即它的子容器属性被预设
                // 但我们不改它的子容器，只限定这一层；这样保留子容器预设的同时加上新效果
                const ipywidgetOutput = thisroot.querySelector('.shiny-ipywidget-output');
                if (ipywidgetOutput) {{
                    ipywidgetOutput.style.setProperty('flex', '1 1 0%', 'important');
                    ipywidgetOutput.style.setProperty('height', '100%', 'important');
                    ipywidgetOutput.style.setProperty('min-height', '0', 'important');
                }}

                // 400. 计算前调整
                // 410. 表格容器的margin也会由DataTables.js自动计算，须设置为0
                // 注意这一步须在高度扣除前执行，因为它自身的margin也在标准流程中被扣除（虽然由于这里的设置，使得最后扣除的是 0）
                const layoutTableEl = thisroot.querySelector('.dt-layout-table');
                if (layoutTableEl) {{
                    layoutTableEl.style.setProperty('margin', '0', 'important');
                }}

                // 480. Set a default height out of `thishead`
                if (!headHeight) {{
                    const headStyle = window.getComputedStyle(thishead);
                    headHeight = headStyle.offsetHeight;
                    if (_debug) {{
                        console.log('Obtain height from the head table: ', headHeight + 'px');
                    }}
                }}

                // 490. 自定义表头高度，防止计算差异过大
                /* IMPORTANT:
                    [1] 若未自定义高度，则出现：程序获取的 `offsetHeight` == 30，而开发者工具中查到的容器高度为 37；即 `offsetHeight` 小于实际值！
                    [2] 推测原因为：`head` 中有另一个 `DataTable` ，因此其高度默认会由 `DataTable` 决定，这样它就不是固定高度；而 autoHeight 的
                        实现基础是父容器中只能有一个自动高度的子容器！
                    [3] 简单处理办法：为 `head` 设置自定义高度，确保其父容器中只有 `body` 为自动高度；这样计算才正确
                    [4] 保底处理：计算 `thishead` 的高度，将其赋值给 `scrollHead`
                */
                const scrollHead = thisroot.querySelector('.dt-scroll-head');
                if (scrollHead) {{
                    scrollHead.style.setProperty('overflow', 'hidden');
                    scrollHead.style.setProperty('height', headHeight + 'px');
                }}

                // 500. ========== 泛化兄弟高度扣除 ==========
                let el = thisbody.parentElement; // .dt-scroll-body
                while (el && el !== thisroot) {{
                    // 100. 定位当前层的父项
                    const parent = el.parentElement;
                    if (!parent) break;

                    // 200. 准备数据累加因子
                    let siblingSum = 0;
                    const sibDetails = [];

                    // 300. 获取当前父项的gap样式（flex布局）
                    // 每有k个element，就有k-1个gap需要从viewport减去；因此正好如下循环每次触发计算都要减gap
                    const parentStyle = window.getComputedStyle(parent);
                    const parentGap = parseFloat(parentStyle.gap) || 0;

                    // 500. 为当前层每个元素做计算
                    for (const sibling of parent.children) {{
                        // 010. Local parameters
                        let h;
                        let h_log;
                        let g;

                        // 100. Load the styles of current member
                        const style = window.getComputedStyle(sibling);
                        if (style.display === 'none') continue;

                        // 300. Do not touch the height of the `self` member, as it is the target for calculation
                        if (sibling === el) {{
                            h = 0;
                            h_log = 'self';
                            g = 0;
                        }} else {{
                            // 优先使用 offsetHeight，若为 0 则回退到 getBoundingClientRect
                            // offsetHeight包含元素的内容（content）、内边距（padding）和边框（border），但不包括外边距（margin）
                            h = style.offsetHeight;
                            if (h === 0 || h === undefined) {{
                                const rect = sibling.getBoundingClientRect();
                                h = rect.height;
                            }}
                            h_log = h;
                            g = parentGap
                        }}

                        // 500. Retrieve the margins for all members, including `self`
                        const mt = parseFloat(style.marginTop) || 0;
                        const mb = parseFloat(style.marginBottom) || 0;
                        const total = h + mt + mb + g;
                        siblingSum += total;

                        // 800. Store the debug information
                        sibDetails.push({{
                            className: sibling.className,
                            offsetHeight: h_log,
                            marginTop: mt,
                            marginBottom: mb,
                            gap: parentGap,
                            total: total
                        }});
                    }}

                    // 800. 打印debug信息
                    if (_debug) {{
                        console.log(
                            '%c[autoScroll] Layer: ' + el.className,
                            'font-weight:bold',
                            '| siblings:', sibDetails,
                            '| total reduction:', siblingSum + 'px'
                        );
                    }}

                    // 900. 应用最终样式
                    el.style.setProperty(
                        'height',
                        `calc(100% - ${{siblingSum}}px)`,
                        'important'
                    );

                    // 999. 继续向上
                    el = el.parentElement;
                }}

                // 700. 附加样式修正
                const layoutDivs = thisroot.querySelectorAll('.dt-layout-table > div');
                layoutDivs.forEach(div => div.style.overflow = 'hidden');

                // 900. 新增：强制重绘表格列宽，使横向滚动立即生效
                if (fullwidth && thishead) {{
                    // 确保是 DataTable 实例并支持 API
                    // 延迟一小段时间确保浏览器完成布局
                    setTimeout(() => {{
                        $(thisbody).DataTable().columns.adjust().draw(false);
                        if (_debug) {{
                            console.log('DataTable columns.adjust() called for fullwidth');
                        }}
                    }}, 50);
                }}
            }}

            // 900. Execution
            applyOnceReady();
        }}
    ''')

    #900. Return the snippet
    return(js_snippet)
#End jsAutoScrollForDataTables

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import os, re
    import shutil
    import sys
    from inspect import cleandoc
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp import jsAutoScrollForDataTables
    print(jsAutoScrollForDataTables.__doc__)

    #100. View the JS as a character string
    print(jsAutoScrollForDataTables())

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

    #350. Dump the script into the caller file
    with open(dst_bat, 'w', encoding = 'utf-8') as f:
        f.write(bat_snippet)

    multi_quotes = '"""'
    to_esc_shiny_handler = (
        """
            let thismsg = '';
            $(document).on('shiny:connected', function() {{
                Shiny.addCustomMessageHandler('{shiny_msg}', function(msg) {{
                    thismsg = msg;
                }});
            }});
        """.strip()
    )
    to_esc_tbl_redraw = (
        """
            let autoHeighted = false;
            intervalID = setInterval(function() {{
                const cnt = $('#dt_id_for_locate');
                if (cnt.length === 0) return;
                const tableNode = cnt.find('.dt-scroll-body table.dataTable')[0] || cnt.find('table.dataTable')[0];
                if (!tableNode) return;
                if (!autoHeighted) {{
                    {func_name}(thismsg);
                    autoHeighted = true;
                }}
                if (autoHeighted) {{
                    clearInterval(intervalID);
                }}
            }}, 100);
        """.strip()
    )

    #370. Prepare the full test program
    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import sys
        import pandas as pd
        import numpy as np
        from inspect import cleandoc
        from shiny import App, ui
        from shinywidgets import output_widget, render_widget
        from itables.widget import ITable
        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )

        from omniPy.ShinyApp import jsAutoScrollForDataTables

        np.random.seed(42)
        df = pd.DataFrame(np.random.randn(500, 8), columns=[f'列{{i}}' for i in range(8)])

        func_name = 'autoScrollForDataTables'
        shiny_msg = 'applyAutoScroll'
        dtAutoScroll = jsAutoScrollForDataTables(
            consoleLog = False
            ,funcName = func_name
        )

        #[ASSUMPTION]
        #[1] This handler executes the injected funrtion at the beginning of `shiny` session
        #    [1] It is because that there is no re-draw instruction of the table from the server side in the entire session
        #    [2] If your App re-draws the table dynamically, make sure this injection is called everytime it is re-drawn
        #[2] Add other handlers when you need at proper stage of the JS injection
        shiny_handler = cleandoc(f{multi_quotes}
            {to_esc_shiny_handler}
        {multi_quotes})

        #[ASSUMPTION]
        #[1] Add one step to force re-draw the table to ensure new styles can be implemented correctly
        #    [1] It should be set for large complex tables if there are lots of preparations during their initialization
        #    [2] We do not use `else` clause to clear the interval ID, to avoid unnecessary loop
        tbl_redraw = cleandoc(f{multi_quotes}
            {to_esc_tbl_redraw}
        {multi_quotes})

        #[ASSUMPTION]
        #[1] CSS class `.table-container` is not necessarily to be set in the first place,
        #     it is used to add attribtes in the function `jsAutoScrollForDataTables`
        #[2] However, one can set it at the top for more styling, as the necessary attributes
        #     will be added later in the function `jsAutoScrollForDataTables`
        #[3] The container `ui.page_fillable` is a must to make the display correct
        app_ui = ui.page_fillable(
            ui.tags.head(
                ui.tags.script(dtAutoScroll)
                ,ui.tags.script(shiny_handler)
                ,ui.tags.script(tbl_redraw)
            )
            ,ui.tags.h4('📊 大数据表格（仅表格内部可滚动）', style='margin: 10px 20px;')
            ,ui.tags.div(
                output_widget('big_table')
                ,class_='table-container'
                ,id='dt_id_for_locate'
            )
        )

        #[ASSUMPTION]
        #[1] Parameter `scrollY='100%'` is a must to make the display correct
        #[2] `session.on_flushed` handles the initialization process AFTER the DataTable is created
        def server(input, output, session):
            @render_widget
            def big_table():
                return ITable(
                    df
                    ,scrollY='100%'
                    ,scrollX=True
                    ,paging=False
                    ,searching=False
                    ,buttons=[]
                    ,select=True
                    ,warn_on_undocumented_option=False
                )

            @session.on_flushed
            async def apply_auto_scroll():
                await session.send_custom_message(shiny_msg, {{
                    'selector': '.table-container'
                    ,'fullwidth': True
                }})

        app = App(app_ui, server)
    """)

    #380. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #370. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App with the full table
    #[03] The table header has full width as requested
    #[04] The table body has full width as requested
    #[05] The scroll bar only shows inside the `DataTable` container
    #[06] Try to adjust the window size and the scroll bar inside the table should adjust in accordance
    #[07] Close the test page in the web browser
    #[08] Close the command console as popped up when executing the BAT file

    #390. Clean the slate
    #[ASSUMPTION]
    #[1] Below action will NOT remove its parent folders
    shutil.rmtree(dst_dir, ignore_errors = True)
#-Notes- -End-

#-Skeleton- -Begin-
你是Python专家，擅长用最新版pandas, shiny和itables设计交互式桌面应用，请解决以下问题并给出可用的案例
1. itables.widget.ITable在绘制表格时包含选项 `scrollY="100vh"` ，若未同时给出容器高度时，会由shinywidgets自动设定一个
   样式：`flex: 1 1 400px !important`
2. 用户尝试取消这个限制并用css覆盖上述值为：`flex: 1 1 auto !important`
3. 由此产生新问题：无论浏览器窗口如何变化，表格在渲染时总会超出可视范围并在浏览器中显示滚动条
4. 请在浏览可视范围内显示完整的ITable页面，当表格记录数很多时，确保只有<table>中自动出现滚动条而外层容器均无滚动条

===============================DeepSeek v4=====================================
问题的根源在于 **CSS 高度计算冲突**：`scrollY="100vh"` 让表格内部滚动区为视口高度，但外层容器（如 `body`、Shiny 布局）也会有内边距、
  边框或兄弟元素占据空间，导致总高度 > 100vh，于是浏览器出现滚动条。
强行覆盖成 `flex: 1 1 auto` 后，容器失去了伸缩约束，高度完全由内容（表格）决定，反而加剧了溢出。

要让 **只有 `<table>` 内部出现滚动条，外层毫无滚动条**，核心思路是：
1. 让表格的**容器高度严格等于视口的剩余可用高度**（不超出）。
2. 表格内部 `scrollY` 设为 `"100%"`，使其填满容器并在溢出时内部滚动。

使用 **Shiny for Python 的填充布局系统** 可以完美实现这一点。

### 关键要点说明

| 组件 | 作用 |
|------|------|
| `ui.page_fillable` | 创建一个 `flex` 纵向布局，自动撑满视口，`html/body` 无滚动条 |
| `overflow: hidden` | 切断所有外层滚动，只有表格内部可以滚动 |
| `.table-container` | `flex: 1 1 0%` 使其占据剩余全部高度，`min-height: 0` 允许收缩 |
| `output_widget(..., height="100%")` | 将 widget 高度设为 100% 继承容器 |
| `scrollY="100%"` | 表格内部滚动区域占满容器，超出行数时 DataTables 会在 `<table>` 内生成垂直滚动条 |

### 避免重回老路
- **不要** 使用 `scrollY="100vh"`，它假设表格可以独占整个视口，但标题、边距都会让它溢出。
- **不要** 用 `!important` 覆盖成 `flex: 1 1 auto`，那会让容器随内容变大。
- **务必** 让高度通过 CSS 继承链正确传递：`page_fillable` → `flex容器` → `widget` → `ITable(scrollY="100%")`。

按此方案，无论窗口如何缩放，表格始终完整可见在视口内，行数再多也只有表格内部出现滚动条。

===============================DeepSeek v4=====================================
问题确认：之前方案中表格外部和内部均无滚动条，说明 `scrollY="100%"` 未能正确生效——表格高度没有被限制为容器高度，而是完全展开，但因
        外层 `overflow: hidden` 导致超出的行被截断，且没有内部滚动条。

**根本原因**：`scrollY="100%"` 要求其所在容器具有**明确的高度**（非 `auto`），而 flex 子项的高度是计算出的，CSS 认为它不是“确定的高度”
    ，因此百分比高度回退为 `auto`，`scrollY` 被忽略，DataTables 不会创建内部滚动区域。

### 可靠解决方案
使表格的容器具备**确定的像素高度**，最简单的做法是使用绝对定位，让容器在视口中精确定位，从而获得明确的可计算高度。

### 关键修复点

| 问题 | 旧方案 | 新方案 |
|------|--------|--------|
| 容器高度不确定 | `flex: 1 1 0%`（计算值，非明确高度） | `position: absolute; top:50px; bottom:0;` → 明确像素高度 |
| `scrollY="100%"` 失效 | 百分比基于 `auto`，退化为 `auto` | 基于明确容器高度，正确设置 DataTables 滚动区域 |
| 表格内部无滚动条 | 表格溢出被外层 `overflow:hidden` 裁剪 | 表格被限制在容器内，超出时出现内部滚动条 |

### 效果验证
- 缩放浏览器窗口，表格始终完整显示在视口内，**浏览器无任何滚动条**。
- 上下滚动鼠标滚轮时，只有表格的 `<table>` 内部区域在滚动。
- 水平方向若列太多，也可启用 `scrollX`，操作同样只限于表格内。

### 补充：若标题高度动态变化
可将标题高度写为 CSS 变量，并用 `calc()` 动态设置 `top` 值，例如：
```css
:root { --header-h: 60px; }
.app-header { height: var(--header-h); }
.table-area { top: var(--header-h); }
```
这样所有相关尺寸一次修改即可同步，维护更方便。

===============================DeepSeek v4=====================================
问题定位：表格被裁剪为 400px，说明 shinywidgets 的默认样式 `flex: 1 1 400px !important` 仍在生效，将 widget 的最小高度锁死。
        而之前 `page_fillable` + `overflow:hidden` 方案因容器高度未真正传给表格内部，导致 `scrollY="100%"` 失效，表格既不溢出也不滚动。

修正的核心是**两条腿走路**：
1. 彻底覆盖 shinywidgets 的 400px 限制，让 widget 容器跟随 flex 布局自动伸展。
2. 确保 DataTables 的滚动容器 `dt-scroll-body` 能获得明确的像素高度，让内部滚动条正常出现。

### 为什么这次一定行

| 问题 | 原因 | 修复 |
|------|------|------|
| 表格被裁剪为 400px | `.shiny-ipywidget-output` 有 `flex: 1 1 400px !important` | 用 新规则 彻底覆盖 |
| 表格内部无滚动条 | `scrollY="100%"` 要求容器有明确高度，而 `min-height:400px` 让高度不固定 | 设置 `height:100%`，使容器高度 = flex 分配的高度 |
| 浏览器出现滚动条 | 外层容器高度超出 100vh | `page_fillable` + `overflow:hidden` 阻断所有外层滚动，只留下表格内部滚动 |
| DataTables 内部未启用滚动 | `dt-scroll-body` 未拿到 100% 高度 | 显式设置 `.dt-scroll-body { height: 100% }`，确保其父链高度明确 |

### 效果
- 浏览器窗口任意缩放，页面内容**完全在视口内**，无外层滚动条。
- 表格行数再多，只会在 `<table>` 区域出现**竖直滚动条**，可鼠标滚轮或拖拽滑块浏览。
- 列数太多时，水平滚动条也仅限于表格内部（`scrollX=True`）。

### 定制提示
- 若标题栏高度需要动态调整，可将标题放入 flex 布局的第一项，并固定高度（例如 `height: 60px`），然后 `.table-container` 会自动占据剩余空间，无需修改 CSS。
- 若要保留表格上方其他控件（如按钮），同样放在 `page_fillable` 的固定高度行中即可。

===============================DeepSeek v4=====================================
经测试反馈，表格确实填满了页面，但 **内部仍未出现滚动条**。问题出在 **高度继承链不完整**。

DataTables 的 `scrollY="100%"` 需要直接父容器 `dt-scroll-body` 获得一个**明确的像素高度**，才能在该容器内生成滚动条。但要走到这一步
  ，`dt-scroll-body` 的所有祖先元素（`dt-scroll`、`dt-layout-full`、`dt-layout-table`、`dt-container`、`itables_anywidget`、
  `shiny-ipywidget-output`）都必须具备明确的 `height` 值，不能是 `auto`。

您之前设置的 `height: 100%` 只到 `dt-container` 和 `dt-scroll-body`，漏掉了 `dt-layout-table`、`dt-layout-full`、`dt-scroll`
  这几个中间层，导致百分比高度向上查找时遇到 `auto` 失效，`dt-scroll-body` 高度实际为 0，`scrollY` 便被忽略，表格内部滚动条无法生成。

### 为什么这次绝对能行

| 失败点 | 原因 | 本次修复 |
|--------|------|----------|
| 表格内部无滚动条 | `scrollY="100%"` 向上查找容器高度时，在 `dt-scroll-body` 的某个祖先遇到 `auto`，导致最终高度为 0，DataTables 放弃内部滚动
  | 为 **全部6层中间容器** 显式设置 `height: 100% !important`，让高度从 `.table-container` 一路贯通到 `dt-scroll-body` |
| 表格被裁剪 400px | `.shiny-ipywidget-output` 的 `flex: 1 1 400px !important` 锁死最小高度 | 已用 `flex: 1 1 0% !important` 覆盖 |
| 浏览器出现滚动条 | 总高度 > 100vh | `page_fillable` + `overflow: hidden` 彻底阻止外层滚动 |

### 最终效果
- **浏览器没有任何滚动条**，页面内容严格在视口内。
- **滚动条只出现在表格的数据区域**（`dt-scroll-body` 内），可通过鼠标滚轮或拖动滑块上下浏览 500 行数据。
- 水平方向若列过多，表格内也会出现水平滚动条（`scrollX=True`）。

### 备选调试技巧
如果仍然失败，可以在浏览器开发者工具中检查 `.dt-scroll-body` 的计算高度是否大于 0，并确认其 `overflow-y` 属性为 `auto` 或 `scroll`。如果高度仍为 0，
  检查是否有其他 CSS（如 itables 自带的）设置了 `height: auto !important`，可以尝试用更具体的选择器覆盖，例如：
```css
div.table-container div.dt-scroll-body {
    height: 100% !important;
}
```

===============================  新需求   =====================================
非常好！该版本能实现功能。请将该逻辑制成JS function注入方式，并最大限度使用新式let私有变量以确保无跨实例污染。将功能用于上面的实例并给出完整程序
- 约定
  - 经测试，最外层的page-fillable无需设置css，所有高度限定操作均在ITable的父容器中进行即可实现完整功能
- 功能名称: autoScrollForDataTables
- 参数
  - container_id : ITable组件的父容器id（此例中为 class包含".table-container" 的容器）
  - container_class :  ITable组件的父容器中需要识别的class（此例中为 class包含".table-container" 的容器）作为双保险，若 container_id
    未提供则退回使用这个参数；若二者皆未提供则报错退出
  - autoScrollX : true/false 默认true 指定是否同时将x轴也设置为自动出现滚动条
- 功能
  1. 通过container_id和container_class找到表格父容器定义为 thisroot
  2. 在thisroot中找到 table.dataTable 。一般有两个：一个出现在 .dt-scroll-head 中，我们命名为 thishead；另一个出现在 .dt-scroll-body 中，
     我们命名为 thisbody
  3. 若 autoScrollX == true
    1. 将thisbody的宽度设置为 100%
    2. 将thisbody父容器的宽度设置为 100%
    3. 将thishead的宽度设置为 100%
  4. thisroot的样式设置按照现行的.table-container即可，只是改为JS注入
  5. 消除 shinywidgets 的 400px 魔数也可参照现行方案，只是改为JS注入
  6. 贯通 itables 全部中间容器的高度链条，这一步须从thisbody（不含thisbody本身）递归找到所有父节点，直到 thisroot 为止，不包含 thisroot；
     分别在每个找到的节点设置 `height: 100% !important`
  7. 找到需要扣除的高度
    - 找到离thisbody最近的父节点中 class包含 .dt-layout-table 的节点，获取其所有兄弟节点的高度（包含margin和border）并将其加总，
      (隐藏节点应该没有高度或高度为 0 请验证；或加判断：若隐藏则高度设为 0)，赋值给 height_sibling
    - 找到离thisbody最近的 class包含 .dt-scroll-head 的节点，获取其高度，赋值给 height_head
  8. 定义thisbody的高度: calc(100% - height_sibling - height_head) !important
  9. 处理相关的显示因素
    - 为itables做特殊设置: `.table-container .dt-layout-table>div {overflow: hidden;}` 防止在这一层出现滚动条
    - 表格容器的margin也会由DataTables.js自动计算，须设置为0。CSS中为 `.table-container .dt-layout-table {margin: 0 !important;}`
    - 表头正下方的表格第一行有上边框，不能挡住，CSS为: `.table-container .dt-scroll-head {height: 32px;overflow: visible !important;}`

20260702 1547
前端渲染报错问题已解决，测试通过，请保持
经测试，发现第8步设置表格高度的计算逻辑需要修改，请按照以下方法修改整体方案
- 由于 .dt-layout-table 有兄弟容器，它的高度不能设置为 100% ，而应当为: calc(100% - height_sibling)
- 由于 .dt-scroll-body 有兄弟容器 .dt-scroll-body ，它的高度（也就是第8步中）应当为: calc(100% - height_head)

===============================DeepSeek v4=====================================
针对您的要求，对 `autoScrollForDataTables` 函数的高度设置逻辑进行了精确修正：

- **`.dt-layout-table`** 的高度改为 `calc(100% - height_sibling)`，扣除同级兄弟容器的总高度；
- **`.dt-scroll-body`** 的高度改为 `calc(100% - height_head)`，扣除表头容器的高度；
- 其他中间容器保持 `height: 100%`，确保链条贯通。

以下是完整的可运行程序。

### 核心修改说明

| 修改点 | 原逻辑 | 新逻辑 | 效果 |
|--------|--------|--------|------|
| `.dt-layout-table` 高度 | 贯通链条中设为 `height: 100%` | 单独设置为 `calc(100% - height_sibling)` | 为兄弟容器腾出空间，避免溢出 |
| `.dt-scroll-body` 高度 | 设为 `calc(100% - height_sibling - height_head)` | `calc(100% - height_head)` | 兄弟高度已扣除，此时只需减去表头 |
| 中间容器处理 | 全部无差别设 `height: 100%` | 遍历时跳过 `layoutTable` 和 `.dt-scroll-body`，其余仍设 `height: 100%` | 高度链条正确贯通，无冲突 |

### 预期效果
- 浏览器控制台将输出 `sibling details`、`height_sibling`、`height_head` 以及分别应用到 `.dt-layout-table` 和 `.dt-scroll-body` 的 `calc` 公式。
- 页面完全适配视口，无外层滚动条。
- 数据行超出可视区域时，仅表格内部出现垂直滚动条，横向滚动同理。

===============================  新需求   =====================================
非常好！功能已经实现，请保持现有功能并增加以下功能
- 当autoScrollX=true时，thishead的属性设置正确，但需要手动调整浏览器大小才能应用；能否在开始处加一个重绘表格的步骤？

===============================DeepSeek v4=====================================
根据您的反馈，增加了一个**强制重绘表格列宽**的步骤，确保 `autoScrollX=true` 时设置的宽度能立即生效，无需手动调整浏览器窗口。

### 新增功能详解

- 在 `autoScrollX` 为 `true` 且表头存在的情况下，通过 `$.fn.dataTable.isDataTable(thisbody)` 确认表格已初始化为 DataTable 实例。
- 使用 `setTimeout` 延迟 50 毫秒调用 `$(thisbody).DataTable().columns.adjust().draw(false)`，让浏览器在应用新的宽度样式后重新计算列宽并重绘。
- 这一操作无需用户手动调整窗口，表格的横向滚动立即正确呈现。

### 预期效果
- 启动后表格的横向滚动（如有）直接可用，无需触发窗口 resize。
- 控制台输出 `DataTable columns.adjust() called for autoScrollX` 确认重绘执行。
- 其余功能保持不变：页面无外层滚动条，表格内部滚动正常，高度计算准确。

===============================  新需求   =====================================
非常好！功能已经实现，请保持现有功能并增加以下功能
- 进一步泛化sibling部分的逻辑：从thisbody也就是<table>的直接父节点开始，每一层父节点均判断是否有竖向排列的siblings，若有则将当前节点高度设为
    calc(100% - sum sibling height)，同样不含thisroot
  - 这样就可以简化逻辑并去除 .dt-layout-table 和 .dt-scroll-body 在容器高度的特异性

请解释现在的逻辑中若出现同一层为横向排列的siblings时（如 flex-direction: column），会减去它们的高度吗？按照需求，当前层的这种排列方式不用减去
  siblings的高度。若无法判断是否横向排列，请给出原因

===============================DeepSeek v4=====================================
在当前泛化逻辑中，**无论父容器的排列方向是横向还是纵向，只要兄弟元素可见（`display` 不为 `none`），其高度（含垂直 margin）都会被
  累加并从当前层的高度中扣除**。
也就是说，如果某一层是横向排列（例如 `flex-direction: row`），其兄弟元素并排显示，但这些兄弟的高度仍然会被错误扣除，导致当前层的高度被过分压缩。

不过，在 itables 的实际 DOM 结构中，从 `.dt-scroll-body` 向上到容器之间的所有中间层（如 `.dt-layout-table`、`.dt-layout-full`、
  `.dt-layout-row`、`.dt-autosize` 等）**其父容器均为纵向堆叠布局**（`flex-direction: column` 或默认块级垂直排列），因此不存在横向兄弟。
  这就是目前泛化逻辑能够正确工作的原因，也是没有专门判断方向的原因。

### 为何不自动判断横向排列？
要可靠判断「横向排列」需同时考虑多种可能性：
- `display: flex` 且 `flex-direction: row / row-reverse`
- `display: inline-flex` 同理
- 普通流中通过 `float`、`inline-block` 实现的横向排列
- Grid 布局中 `grid-auto-flow: column` 等

完全覆盖这些情况会使代码显著复杂，且对于 itables 的确定结构来说属于过度设计。因此当前选择是**保持简单，依赖 itables 始终纵向堆叠的已知特性**。

### 如果未来需要适应横向兄弟
可以加入一个检查：**若父容器为 flex 容器且 `flex-direction` 为 `row` 或 `row-reverse`，则跳过该层的兄弟高度扣除**。修改片段如下：
```javascript
const parentStyle = window.getComputedStyle(parent);
const isHorizontalFlex = parentStyle.display === 'flex' &&
    (parentStyle.flexDirection === 'row' || parentStyle.flexDirection === 'row-reverse');
if (!isHorizontalFlex) {
    // 进行扣除...
}
```
但这在当前 itables 场景中并非必需，因为所有兄弟确实都是纵向排列的。

#-Skeleton- -End-
'''
