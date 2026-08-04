#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from inspect import cleandoc

def jsAutoHeight(
    funcName : str = 'autoHeight'
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the HTML front end, NOT necessarily inside <shiny> app, to enable   #
#   | the automatic <height> of all containers along the ancestral tree till <body> (which is excluded)                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Given any child element of the provided container is designed to display webkit scroll bar on Y-axis automatically when its    #
#   |     content exceeds the destinated height, without triggering the scroll bar on the whole window, this container will have to     #
#   |     set its height as `calc(100% - sum height of all siblings)`, along with all its ancestors till `body`; otherwise the height   #
#   |     values cannot be propagated to that specific child.                                                                           #
#   |[2] In the same way as is designed, if any element calls this function to set an automatic height, its direct parent container     #
#   |    should do the same, and so on as a recursion.                                                                                  #
#   |[3] Since `shiny` modules are designed to chain each other, they share the same concept of `auto height`. Hence if any module is   #
#   |     made of `auto height` with this function, all its caller modules have to choose either of below options                       #
#   |    [1] Make itself `auto height`, too, to let its parent container decide the overall height distribution                         #
#   |    [2] Set itself a certain height (not calculated one) for the height propagation along its children tree                        #
#   |[4] This will not work when two or more elements in a `column` would like to be `auto height`, and the reason is obvious           #
#   |[5] DOM tree should have been initialized BEFORE this function takes effect, see examples to see its proper timing                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Set the `DataTable` to fill the rest viewport of the whole page, esp. fill the full height                                     #
#   |[2] Allow any `shiny` module to be `auto height` in its parent container                                                           #
#   |[3] Generally, allow any single element to be `auto height` in its parent container, given all its siblings have certain heights   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Arguments in the injected JS function]                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[selector       ] <String  > HTML selector for finding the element to set `auto height`                                            #
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
    # op_rem_bgn = '' if consoleLog else '/*'
    # op_rem_end = '' if consoleLog else '*/'

    #800. Setup the JS program
    js_snippet = cleandoc(f'''
        function {funcName}({{ selector, debug = false }} = {{}}) {{
            // 010. Local parameters
            const _debug = !!debug;
            const MAX_RETRIES = 2;
            const RETRY_DELAY = 10;
            let retries = 0;

            // 200. Helper functions
            // 210. Function to detect certain conditions before the main activity
            function applyOnceReady() {{
                // 010. Local parameters
                const thisroot = document.querySelector(selector);

                // 090. Continuous detection of the existence of the dedicated member
                if (!thisroot) {{
                    if (retries < MAX_RETRIES) {{
                        retries++;
                        setTimeout(applyOnceReady, RETRY_DELAY);
                        return;
                    }} else {{
                        console.error('{funcName}: 等待超时，未找到元素', selector);
                        return;
                    }}
                }}

                // 100. body的高度通常都是 100%
                if (thisroot === document.body) return;

                // 200. 定位父容器
                const parent = thisroot.parentElement;
                if (!parent) return;

                // 210. 识别布局
                const parentStyle = window.getComputedStyle(parent);
                const isHorizontal = (
                    parentStyle.display === 'flex' &&
                    (parentStyle.flexDirection === 'row' || parentStyle.flexDirection === 'row-reverse')
                );

                // 220. 获取当前父项的gap样式（flex布局）
                // 每有k个element，就有k-1个gap需要从viewport减去；因此正好如下循环每次触发计算都要减gap
                const parentGap = parseFloat(parentStyle.gap) || 0;

                // 300. 自身属性
                const selfStyle = window.getComputedStyle(thisroot);
                const selfMarginTop = parseFloat(selfStyle.marginTop) || 0;
                const selfMarginBottom = parseFloat(selfStyle.marginBottom) || 0;

                // 500. 准备数据累加因子
                let siblingSum = 0;
                let finalHeight;
                const sibDetails = [];

                // 600. ========== 泛化兄弟高度扣除 ==========
                if (isHorizontal) {{
                    // 100. 横向排列：找出所有兄弟（不含自己）的最大总高度
                    let log_msg = {{}};
                    for (const child of parent.children) {{
                        // 010. 避免引用自身
                        if (child === thisroot) continue;

                        // 100. 获取当前子容器的样式
                        const style = window.getComputedStyle(child);

                        // 109. 不显示的容器没有高度
                        if (style.display === 'none') continue;

                        // 300. 优先使用 offsetHeight，若为 0 则回退到 getBoundingClientRect
                        // offsetHeight包含元素的内容（content）、内边距（padding）和边框（border），但不包括外边距（margin）
                        let h = style.offsetHeight;
                        if (h === 0 || h === undefined) h = child.getBoundingClientRect().height;

                        // 500. Total height
                        const mt = parseFloat(style.marginTop) || 0;
                        const mb = parseFloat(style.marginBottom) || 0;
                        const total = h + mt + mb;

                        // 900. Only keep the maximum height
                        if (total > siblingSum) {{
                            siblingSum = total;
                            log_msg = {{
                                id: child.id,
                                className: child.className,
                                offsetHeight: h,
                                marginTop: mt,
                                marginBottom: mb,
                                total: total
                            }};
                        }}
                    }}

                    // 500. 决定最终高度
                    finalHeight = (siblingSum - (selfMarginTop + selfMarginBottom)) + 'px';

                    // 800. Store the debug information
                    sibDetails.push(log_msg);
                }} else {{
                    // 100. 为当前层每个元素做计算，同样不含自身
                    for (const child of parent.children) {{
                        // 010. 避免引用自身
                        if (child === thisroot) continue;

                        // 010. Local parameters
                        let g;
                        let total;

                        // 100. 获取当前子容器的样式
                        const style = window.getComputedStyle(child);
                        if (style.display === 'none') continue;

                        // 300. 优先使用 offsetHeight，若为 0 则回退到 getBoundingClientRect
                        let h = child.offsetHeight;
                        if (h === 0 || h === undefined) h = child.getBoundingClientRect().height;

                        // 500. Total height
                        const mt = parseFloat(style.marginTop) || 0;
                        const mb = parseFloat(style.marginBottom) || 0;
                        const withnogap = h + mt + mb;

                        // 550. Do not subtract another gap if current member has zero height
                        // Some invisible elements, e.g. SVG, takes no height, we have to fill their gaps
                        if (withnogap === 0) {{
                            total = 0;
                            g = 'gap filled';
                        }} else {{
                            total = withnogap + parentGap;
                            g = parentGap;
                        }}
                        siblingSum += total;

                        // 500. 决定最终高度
                        const totalDeduction = siblingSum + selfMarginTop + selfMarginBottom;
                        finalHeight = `calc(100% - ${{totalDeduction}}px)`;

                        // 800. Store the debug information
                        sibDetails.push({{
                            className: child.className,
                            offsetHeight: h,
                            marginTop: mt,
                            marginBottom: mb,
                            gap: g,
                            total: total
                        }});
                    }}
                }}

                // 800. 打印debug信息
                if (_debug) {{
                    console.log(
                        '%c[autoScroll] Layer: ' + thisroot.className,
                        'font-weight:bold',
                        '| siblings:', sibDetails,
                        '| calculated height:', finalHeight
                    );
                }}

                // 900. 应用最终样式
                thisroot.style.setProperty(
                    'height',
                    finalHeight,
                    'important'
                );
            }}

            // 900. Execution
            applyOnceReady();
        }}
    ''')

    #900. Return the snippet
    return(js_snippet)
#End jsAutoHeight

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

    from omniPy.ShinyApp import jsAutoHeight
    print(jsAutoHeight.__doc__)

    #100. View the JS as a character string
    print(jsAutoHeight())

    #200. Locate the dedicated App
    dst_dir = r'D:\Temp\test_app'
    dst_app = os.path.join(dst_dir, 'app.py')
    dst_bat = os.path.join(dst_dir, 'run_app.bat')

    if not os.path.isdir(dst_dir): os.makedirs(dst_dir)

    #250. Prepare the caller BAT
    bat_snippet = cleandoc(rf"""
        @echo off
        @set "CurDir=%~dp0"
        @if "%CurDir:~-1%"=="\" @set "CurDir=%CurDir:~0,-1%"
        @call "{os.path.join(dir_omniPy, 'loc_omniPy_VENV.bat')}"
        @call "%BAT_VENV%"
        shiny run --reload --launch-browser "%CurDir%\app.py"
        exit /b %ErrorLevel%
    """)

    #260. Dump the script into the caller file
    with open(dst_bat, 'w', encoding = 'utf-8') as f:
        f.write(bat_snippet)

    #300. Test the functionality
    multi_quotes = '"""'
    to_esc_js_inject = (
        """
            document.addEventListener('DOMContentLoaded', function() {{
                {func_name}({{selector: '#set_auto_height'}});
            }});
            const resizeArgs = {{selector: '#set_auto_height'}};
            const resizeHandler = debounce({func_name}.bind(null, resizeArgs), 100);
            window.addEventListener('resize', resizeHandler);
        """.strip()
    )

    #310. Prepare the full test program
    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import sys
        from inspect import cleandoc
        from shiny import App, ui
        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )

        from omniPy.ShinyApp import jsAutoHeight, jsDebounce

        func_name = 'autoHeight'
        divAutoHeight = jsAutoHeight(
            consoleLog = False
            ,funcName = func_name
        )
        resizeDebounce = jsDebounce(
            funcName = 'debounce'
        )

        #[ASSUMPTION]
        #[1] window改变尺寸时，高度计算需要刷新。我们需要每次改变时都重新计算，并且加入防抖机制
        #    [1] 先绑定参数，再防抖（或者先防抖再绑定参数，视需求而定）
        #    [2] 注意：debounce 返回了新函数，所以 saveHandler 必须指向这个最终函数
        js_snippet = cleandoc(f{multi_quotes}
            {to_esc_js_inject}
        {multi_quotes})

        #[ASSUMPTION]
        #[1] The container `ui.page_fillable` is a must to make the display correct
        app_ui = ui.page_fillable(
            ui.tags.head(
                ui.tags.script(divAutoHeight)
                ,ui.tags.script(resizeDebounce)
                ,ui.tags.script(js_snippet)
            )
            ,ui.tags.h4('标题（文字决定高度，因此容器高度是固定值）', style='border: 1px solid;')
            ,ui.tags.div(
                ui.tags.div(
                    ui.tags.div('flex布局下的同一列容器中，本容器设置自动高度；由vh中其他容器的高度计算得出，扣减项如下：')
                    ,ui.tags.div('[1] 父容器的gap：每有一个兄弟容器，减一次gap')
                    ,ui.tags.div('[2] 所有兄弟容器的：高度、margin')
                    ,ui.tags.div('[3] 本容器的：margin')
                )
                ,id='set_auto_height'
                ,style='border: 2px dashed;'
            )
            ,ui.tags.div(
                ui.tags.div('兄弟容器（手动设定高度）')
                ,ui.tags.div('height: 20vh;')
                ,style='height: 20vh; border: 1px solid;'
            )
        )

        def server(input, output, session):
            pass

        app = App(app_ui, server)
    """)

    #340. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #370. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App with the full table
    #[03] There are 3 divisions: header, auto-heighted box, sibling box with given height
    #[04] Resize the window to check if the relative height of all boxes remain the same
    #[05] Close the test page in the web browser
    #[06] Close the command console as popped up when executing the BAT file

    #500. Test the functionality in row-wise flex box
    #510. Prepare the full test program
    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import sys
        from inspect import cleandoc
        from shiny import App, ui
        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )

        from omniPy.ShinyApp import jsAutoHeight, jsDebounce

        func_name = 'autoHeight'
        divAutoHeight = jsAutoHeight(
            consoleLog = False
            ,funcName = func_name
        )
        resizeDebounce = jsDebounce(
            funcName = 'debounce'
        )

        js_snippet = cleandoc(f{multi_quotes}
            {to_esc_js_inject}
        {multi_quotes})

        #[ASSUMPTION]
        #[1] 为了演示，目标容器加了margin
        #[2] 总高度与最高的那个兄弟容器相等
        app_ui = ui.page_fillable(
            ui.tags.head(
                ui.tags.script(divAutoHeight)
                ,ui.tags.script(resizeDebounce)
                ,ui.tags.script(js_snippet)
            )
            ,ui.tags.h4('标题（用于演示祖父级布局不受影响）', style='border: 1px solid;')
            ,ui.tags.div(
                ui.tags.div(
                    ui.tags.div(
                        ui.tags.div('flex: row布局下的同一行容器中，本容器设置自动高度；由父容器中其他容器的高度计算得出，细节如下：')
                        ,ui.tags.div('[1] 所有兄弟容器中最大的：高度 + 上下margin')
                        ,ui.tags.div('[2] 扣除本容器的：上下margin')
                    )
                    ,id='set_auto_height'
                    ,style='border: 2px dashed; margin: 20px;'
                )
                ,ui.tags.div(
                    ui.tags.div('兄弟容器（手动设定高度）')
                    ,ui.tags.div('height: 60vh;')
                    ,style='height: 60vh; border: 1px solid;'
                )
                ,ui.tags.div(
                    ui.tags.div('兄弟容器（手动设定高度）')
                    ,ui.tags.div('height: 300px;')
                    ,style='height: 300px; border: 1px solid;'
                )
                ,style='display: flex; flex-direction: row;'
            )
        )

        def server(input, output, session):
            pass

        app = App(app_ui, server)
    """)

    #540. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #570. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App with the full table
    #[03] There are 3 divisions apart from header: auto-heighted box, sibling with given `vh`, sibling with given `px`
    #[04] Resize the window to check if the auto-heighted box will have the same height as either one on different window heights
    #[05] Close the test page in the web browser
    #[06] Close the command console as popped up when executing the BAT file

    #990. Clean the slate
    #[ASSUMPTION]
    #[1] Below action will NOT remove its parent folders
    shutil.rmtree(dst_dir, ignore_errors = True)
#-Notes- -End-
'''
