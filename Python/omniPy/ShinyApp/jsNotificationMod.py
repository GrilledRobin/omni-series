#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from inspect import cleandoc

def jsNotificationMod(html_id : str, notifier_ns :str = 'shiny-notification-') -> str:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to inject a piece of JavaScript into the <shiny> app or module, to change the default style of           #
#   | notifications so that they resemble the same of the dedicated operation system, such as Windows or MacOS                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] It is strongly recommended to introduce the OS styles pack <Styles.OSThemesCSS> to make this function work                     #
#   |[2] With above pre-requisite, the style of `shiny` notifications will now adapt to the theme of the OS at runtime                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |html_id           :   <str> Valid character string that represents an element in HTML                                              #
#   |notifier_ns       :   <str> Namespace of the notifier in `shiny`. It is presumed to be the same string as always                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>             :   Character representation of JS snippet                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260624        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
    notifier_panel_id = 'panel'
    notifier_btn_class = 'close'

    #100. Setup the JS program
    js_snippet = cleandoc(f'''
        /* 100. Notification Panel */
        var ePanel = document.getElementById('{notifier_ns}{notifier_panel_id}');

        /* 110. Make the panel a flex container and justify its children to the bottom right */
        ePanel.style.setProperty('display', 'flex');
        ePanel.style.setProperty('justify-content', 'flex-end');
        ePanel.style.setProperty('align-items', 'flex-end');

        /* 130. Remove the distance from and to the edges as the children inherit the system automatic positions */
        ePanel.style.setProperty('margin', '0');
        ePanel.style.setProperty('padding', '0');

        /* 150. Set the panel to the bottom right of its parent, which is presumably `body` */
        ePanel.style.setProperty('position', 'fixed');
        ePanel.style.setProperty('bottom', '0');
        ePanel.style.setProperty('right', '0');

        /* 400. Notification Container */
        var eCnt = document.getElementById('{html_id}');

        /* 410. Inherit the system original class */
        eCnt.classList.add('currOS-notification');

        /* 150. Set the element to the bottom right of its parent, which is presumably the `panel` */
        eCnt.style.setProperty('position', 'fixed');
        eCnt.style.setProperty('bottom', '0');
        eCnt.style.setProperty('right', '0');

        /* 700. Notification Button */
        var eBtn = document.getElementsByClassName('{notifier_ns}{notifier_btn_class}');

        /* 750. Highlight the button so that it is easier to locate */
        /* 遍历修改样式 */
        for(var i = 0; i < eBtn.length; i++){{
            eBtn[i].classList.add('currOS-notification-close');
            eBtn[i].style.setProperty('color', 'var(--text-secondary)');
        }};
    ''')

    #900. Return the flag
    return(js_snippet)
#End jsNotificationMod

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

    from omniPy.ShinyApp import jsNotificationMod
    print(jsNotificationMod.__doc__)

    #100. View the JS as a character string
    print(jsNotificationMod('shinynotify_file_save'))

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
    py_snippet = cleandoc(f"""
        #!/usr/bin/env python3
        # -*- coding: utf-8 -*-

        import sys
        from shiny import App, Inputs, Outputs, Session, reactive, ui
        dir_omniPy : str = r'{dir_omniPy} '.strip()
        if dir_omniPy not in sys.path:
            sys.path.append( dir_omniPy )
        from omniPy.Styles import OSThemesCSS
        from omniPy.ShinyApp import jsNotificationMod

        app_ui = ui.page_fluid(
            ui.tags.style(getattr(OSThemesCSS, 'Windows'))
            ,ui.input_action_button('show', 'Show', class_ = 'currOS-btn')
            ,' '
            ,ui.input_action_button('remove', 'Remove', class_ = 'currOS-btn')
        )

        def server(input: Inputs, output: Outputs, session: Session):
            ids: list[str] = []
            n: int = 0
            notifier_ns = 'shiny-notification-'
            notifier_id = 'shinynotify_file_save'

            @reactive.effect
            @reactive.event(input.show)
            def _():
                nonlocal n
                # Save the ID for removal later
                id_ = ui.notification_show(
                    ui.tags.div(
                        ui.tags.div(
                            'Message ' + str(n)
                            ,class_ = 'currOS-notification-body'
                        )
                        ,ui.tags.script(jsNotificationMod(notifier_ns + notifier_id, notifier_ns = notifier_ns))
                    )
                    ,duration = None
                    ,id = notifier_id
                )
                ids.append(id_)
                n += 1

            @reactive.effect
            @reactive.event(input.remove)
            def _():
                if ids:
                    ui.notification_remove(ids.pop())

        app = App(app_ui, server)
    """)

    #380. Dump the script into the App file
    with open(dst_app, 'w', encoding = 'utf-8') as f:
        f.write(re.sub(r'\n\s+\n', r'\n\n', py_snippet, flags = re.M))

    #370. Test steps
    #[01] Execute the BAT file <dst_bat> either from command console or by double click on the file name
    #[02] The default web browser will be activated and show the App with two buttons
    #[03] Click the button <'Show'> and now a notification pops at the bottom right of the page
    #[04] Click the button <'Remove'> and the notification is removed
    #[05] Click the button <'Show'> again and now a new notification pops at the bottom right of the page
    #[06] Click the button <'Remove'> and the new notification is removed
    #[07] Close the test page in the web browser
    #[08] Close the command console as popped up when executing the BAT file

    #390. Clean the slate
    #[ASSUMPTION]
    #[1] Below action will NOT remove its parent folders
    shutil.rmtree(dst_dir, ignore_errors = True)

#-Notes- -End-
'''
