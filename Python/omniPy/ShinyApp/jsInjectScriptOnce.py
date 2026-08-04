#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
from inspect import cleandoc

def jsInjectScriptOnce(
    funcName : str = 'window.injectScriptOnce'
    ,scriptType : str = 'script'
) -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the HTML front end, NOT necessarily inside <shiny> app, to make sure#
#   | that the dedicated JS or CSS script is only introduced once in the entire session                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] HTML will NOT remove duplicated tag injection, while `shiny.ui.head_content` will help do so and also prevent the JS class from#
#   |     being re-defined (that triggers a console error)                                                                              #
#   |[2] For case in `shiny` App, it is also better to prepare self-protaction method to avoid duplicated definition of JS class        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIO                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Introduce a JS or CSS snippet inside a container only once                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Arguments in the injected JS function]                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[element        ] HTML element as an HTML object (instead of its ID or any selector), within which to inject the script            #
#   |[snippet        ] JS or CSS scripts to inject inside above element                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |funcName          :   <str > Customize the JS function name to setup more than one universal function in the console               #
#   |                      [<see def.>          ] <Default> Use a universal function name to be in use for the whole web page           #
#   |                      [<str>               ]           Set different function names to test the functionality                      #
#   |scriptType        :   <str > Type of script to inject                                                                              #
#   |                      [script              ] <Default> Indicate that a <script> tag is to inject                                   #
#   |                      [style               ]           Indicate that a <style> tag is to inject                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   Character representation of JS snippet                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260708        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.

    #050. Local parameters
    func_name_trans = re.sub(r'\W', '_', funcName)

    #800. Setup the JS program
    js_snippet = cleandoc(f'''
        // 放在 ui.head_content 中
        if (!window.__MODULE_LOADED_{func_name_trans}__) {{
            window.__MODULE_LOADED_{func_name_trans}__ = true;

            {funcName} = function(element, snippet) {{
                const scripts = element.getElementsByTagName('{scriptType}');
                for (var i = 0; i < scripts.length; i++) {{
                    if (scripts[i].textContent === snippet) {{
                        // 脚本已存在，无需再次加载
                        return;
                    }}
                }}
                var script = document.createElement('{scriptType}');
                script.textContent = snippet;
                element.appendChild(script);
            }}
        }}
    ''')

    #900. Return the snippet
    return(js_snippet)
#End jsInjectScriptOnce

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    import re
    from shiny import ui
    from inspect import cleandoc
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.ShinyApp import jsInjectScriptOnce
    print(jsInjectScriptOnce.__doc__)

    #100. View the JS as a character string
    print(jsInjectScriptOnce())

    #300. How to inject a snippet once in a certain tag
    #310. Prepare a snippet which you need only to show up once in certain container
    js_snippet = cleandoc(f"""
        $(document).on('shiny:connected', function() {{
            console.log('creation done');
        }});
    """)

    #[ASSUMPTION]
    #[1] The snippet may contain many characters, so sometimes we have to use template string (`...`) in JS
    #[2] Hence we have to escape any possible backquotes inside its definition body
    js_snippet = re.sub('`', r'\`', js_snippet)

    #350. Introduce this tool
    name_inj_once = 'window.injectScriptOnce'
    js_inj_once = jsInjectScriptOnce(funcName = name_inj_once, scriptType = 'script')

    #370. Prepare a snippet to be executed and removed immediately, which injects above snippet
    wrapper_id = 'this-wrapper'

    exec_id1 = 'exec-and-remove'
    js_inject1 = cleandoc(f"""
        let thistgt = document.getElementById('{wrapper_id}');
        {name_inj_once}(thistgt, `{js_snippet}`);
        document.getElementById('{exec_id1}').remove();
    """)

    exec_id2 = 'exec-and-remove2'
    js_inject2 = cleandoc(f"""
        let thistgt = document.getElementById('{wrapper_id}');
        {name_inj_once}(thistgt, `{js_snippet}`);
        document.getElementById('{exec_id2}').remove();
    """)

    #390. Now setup the dedicated container
    #[ASSUMPTION]
    #[1] As a global function `js_inj_once` itself can be injected to <head>, it will be deduplicated by `shiny`
    #[2] You will find in the webpage that `js_snippet` is only injected once
    #[3] Both tags `js_inject1` and `js_inject2` are removed by themselves
    test_ui = ui.div(
        ui.head_content(ui.tags.script(js_inj_once))
        ,ui.tags.script(js_inject1, id = exec_id1)
        ,ui.tags.script(js_inject2, id = exec_id2)
        ,'your content'
        ,id = wrapper_id
    )
#-Notes- -End-
'''
