#!/usr/bin/env python3
# -*- coding: utf-8 -*-

logger.info('Starting to download files from website...')
logger.info(u'This step is to demonstrate the scraper without developer’s tool')

import os
#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32api, win32con, win32gui
import time
import progressbar
import datetime as dt
import subprocess as sp
from pynput.keyboard import Controller as Controller_k
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from omniPy.Dates import ObsDates
from omniPy.RPA import clicks, setClipboard, getDesktopWindows

#There must be a script file [winGuiAuto.py] in the same directory as this one
from winGuiAuto import findControl, clickButton

#010. Local parameters
svr_home1 = 'https://aaa/bbb/'
txt_user = 'user'
txt_pwd = 'password'

site_home1 = svr_home1 + 'login.jsp'
site_title1 = 'test system 1'

L_obsDates = ObsDates(obsDate = dt.date.today())
rpt_date = L_obsDates.prevWorkDay[0]
txt_day = rpt_date.strftime('%d')
txt_month = rpt_date.strftime('%m')
txt_year = rpt_date.strftime('%Y')

files_all = [rpt_date.strftime('%Y%m%d') + '.zip']
L_stpflnm = [ os.path.join(dir_Downloads, f) for f in files_all ]

keyboard = Controller_k()

#selenium在启动IE浏览器的时候，能否像chrome那样配置user-agent启动参数
#Quote: https://ask.csdn.net/questions/761546
#Get your [user-agent] through below website, by visiting with IE, Chrome or Firefox, etc. (different for each)
#Quote: https://httpbin.org/headers
#[1] Below value is for [IE on Win10 21H1]
user_agent = 'Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko'
ie_options = webdriver.IeOptions()
ie_options.add_argument('user-agent=' + user_agent)
ie_options.add_argument('require_window_focus')

attr_IE = {
    '10' : {
        #Below page has a toolbar beneath the title bar
        'Err Page' : {
            'title' : {
                'en_US' : u'This site isn’t secure'
                ,'zh_CN' : u'证书错误'
            }
            ,'override' : {
                'en_US' : {
                    'pos' : [(184,352),(256,472)]
                }
                ,'zh_CN' : {
                    'pos' : [(160,320)]
                }
            }
        }
        #Below page has no toolbar beneath the title bar
        ,'Err Page2' : {
            'title' : {
                'en_US' : u'This site isn’t secure'
                ,'zh_CN' : u'证书错误'
            }
            ,'override' : {
                'en_US' : {
                    'pos' : [(200,280),(200,400)]
                }
                ,'zh_CN' : {
                    'pos' : [(160,272)]
                }
            }
        }
        #Below is a popup window as security warning
        ,'Sec Warn' : {
            'title' : {
                'en_US' : u'Security Warning'
                ,'zh_CN' : u'安全提示'
            }
            ,'skip' : {
                'en_US' : u'Yes'
                ,'zh_CN' : u'确定'
            }
        }
        ,'Login Page' : {
            'pos' : {
                'en_US' : {
                    'userID' : [(760,456)]
                    ,'password' : [(760,480)]
                    ,'loginButton' : [(632,528)]
                }
                ,'zh_CN' : {
                    'userID' : [(760,436)]
                    ,'password' : [(760,456)]
                    ,'loginButton' : [(632,504)]
                }
            }
        }
        #Below is a popup window indicating the password will expire soon, which we would skip
        ,'Expire' : {
            'title' : {
                'en_US' : u'Message from webpage'
                ,'zh_CN' : u'来自网页的消息'
            }
            ,'skip' : {
                'en_US' : u'Cancel'
                ,'zh_CN' : u'取消'
            }
        }
    }
}

#050. Define function to close the window of Security Warning
def closeSecWarning():
    #100. Find the window
    hwnd_warn = win32gui.FindWindow(None, attr_IE[curr_win_ver]['Sec Warn']['title'][curr_win_lang])

    #300. Find the control indicating [skip]
    hwnd_skip = findControl(hwnd_warn, wantedText = attr_IE[curr_win_ver]['Sec Warn']['skip'][curr_win_lang])

    #800. Click the control to close the window
    #Sometimes below action is not working
#    clickButton(hwnd_skip)

    #810. Set the window to the foreground
    #Quote: https://www.cnblogs.com/chenjy1225/p/12174889.html
    win32gui.SetForegroundWindow(hwnd_warn)

    #830. Get the rect of the control
    #[left]-[top]-[right]-[bottom]
    hwnd_skip_pos = win32gui.GetWindowRect(hwnd_skip)

    #890. Click on the center of the control
    clicks((
        int((hwnd_skip_pos[0] + hwnd_skip_pos[2])/2)
        ,int((hwnd_skip_pos[1] + hwnd_skip_pos[3])/2)
    ))

#060. Define function to window indicating [Certificate Error]
def skipErrPage(page_type = 'Err Page'):
    #One can try below method if the webdriver is allowed to run script
    #Quote: https://www.cnblogs.com/leeboke/articles/5013793.html
#    driver.get('javascript:document.getElementById("overridelink").click();')

    #100. Find the window
    hwnd_warn = win32gui.FindWindow('IEFrame', attr_IE[curr_win_ver][page_type]['title'][curr_win_lang] + ' - Internet Explorer')

    #500. Bring the window to the foreground and set proper size for clicking inside it
    win32gui.SetForegroundWindow(hwnd_warn)
    driver.set_window_rect(0,0,1800,1000)
    hwnd_pos = win32gui.GetWindowRect(hwnd_warn)
    topleft = (hwnd_pos[0], hwnd_pos[1])

    #600. Click the link [继续浏览此网站（不推荐）]
    time.sleep(1)
    click_pos = attr_IE[curr_win_ver][page_type]['override'][curr_win_lang]['pos']
    clicks(*click_pos, offset = topleft)

    #700. Close the popup window for [Security Warning] if any
    time.sleep(2)
    #710. Find all windows on desktop
    hwnd_desktop = getDesktopWindows()
    hwnd_titles = set([ h['title'] for h in hwnd_desktop.values() ])

    #790. Close the window
    warn_titles = set([ t + ' - Internet Explorer' for t in attr_IE[curr_win_ver][page_type]['title'].values() ])
    if warn_titles & hwnd_titles:
        closeSecWarning()

#070. Define function to check whether [Certificate Error] is present and skip it
def checkErrPage(page_type = 'Err Page'):
    #100. Find the titles of all windows handled by current webdriver
    titles = set()
    for h in driver.window_handles:
        driver.switch_to.window(h)
        titles |= set([driver.title])

    #900. Skip the [Certificate Error] page
    warn_titles = set(attr_IE[curr_win_ver][page_type]['title'].values())
    if warn_titles & titles:
        skipErrPage(page_type)

logger.info('100. Login to the dedicated website')
#Quote: https://www.thepythoncode.com/article/automate-login-to-websites-using-selenium-in-python
#101. Initialize the IE driver
#[executable_path] is deprecated at [selenium=4.0.0]
driver = webdriver.Ie(options = ie_options)
#driver.implicitly_wait(5)

#110. Open the login page
driver.get(site_home1)

#115. Skip the warnings
time.sleep(2)
checkErrPage('Err Page')
time.sleep(2)
checkErrPage('Err Page2')

#130. Get the handle of IE
#Class [IEFrame] is indicated here:
#Quote: https://www.programcreek.com/python/example/4315/win32com.client.Dispatch
time.sleep(2)
hwnd_login = win32gui.FindWindow('IEFrame', site_title1 + ' - Internet Explorer')

#150. Bring the window to the foreground and maximize it
win32gui.SetForegroundWindow(hwnd_login)
#Quote: https://www.programcreek.com/python/example/115351/win32con.SW_MAXIMIZE
win32gui.ShowWindow( hwnd_login, win32con.SW_MAXIMIZE )

#160. Input values and click the login button
#161. Click on the position of [User] and input text
clicks(*attr_IE[curr_win_ver]['Login Page']['pos'][curr_win_lang]['userID'])
time.sleep(0.3)
keyboard.type(txt_user)

#165. Click on the position of [Password] and input text
clicks(*attr_IE[curr_win_ver]['Login Page']['pos'][curr_win_lang]['password'])
time.sleep(0.3)
keyboard.type(txt_pwd)

#169. Click on the center of [login] button
clicks(*attr_IE[curr_win_ver]['Login Page']['pos'][curr_win_lang]['loginButton'])

#180. Close the popup window indicating [Password will expire soon]
time.sleep(5)
#181. Find all windows on desktop
hwnd_desktop = getDesktopWindows()

#185. Close the window by clicking on [Cancel]
titles_all = set([ h['title'] for h in hwnd_desktop.values() ])
titles_exp = set([ t + ' - Internet Explorer' for t in attr_IE[curr_win_ver]['Expire']['title'].values() ])
titles_toclose = titles_exp & titles_all
for t in titles_toclose:
    #010. Determine the texts to be located
    cancel_expire = attr_IE[curr_win_ver]['Expire']['skip'][curr_win_lang]

    #100. Get the handle of the window
    hwnd_expire = win32gui.FindWindow('IEFrame', t)

    #300. Find the control [取消]
    hwnd_cancel = findControl(hwnd_expire, wantedText = cancel_expire)

    #500. Click the button
    clickButton(hwnd_cancel)

#190. Skip the warnings
time.sleep(2)
checkErrPage('Err Page2')

logger.info('500. Download report')
#505. Bring the window with main page to the foreground
time.sleep(2)
#Assume there is only one IE window and it is initiated by our webdriver
driver.switch_to.window(driver.window_handles[0])
win32gui.SetForegroundWindow(win32gui.FindWindow('IEFrame', None))

#530. Get the page of specified menu
#[IMPORTANT] Starting from this step, we need to call [driver.page_source] frequently, and look inside its content for URL
#driver.page_source
driver.get(svr_home1 + 'XXX/YYY')

#540. Search for the URL of the dedicated menu item
#For some reason, we may need to skip the Security Warning twice to close one single window, which is quite weird
time.sleep(2)
checkErrPage('Err Page2')
time.sleep(2)
checkErrPage('Err Page2')

#550. Enter the report ID and click [Enter] on the keyboard to conduct search
#Below forum expresses the reason why the [send_keys()] method of IEDriver X64 is too slow
#Quote: https://github.com/seleniumhq/selenium-google-code-issue-archive/issues/5116
time.sleep(2)
driver.switch_to.window(driver.window_handles[0])
win32gui.SetForegroundWindow(win32gui.FindWindow('IEFrame', site_title1 + ' - Internet Explorer'))
#Quote: https://selenium-python.readthedocs.io/locating-elements.html
#[SEARCH_TEXT] is the [name] attribute of the dedicated html tag as retrieved by [driver.page_source], the same for the rest
srch_input = driver.find_element(By.NAME, 'SEARCH_TEXT')
#We set the text into the system clipboard, in case [send_keys()] method of IEDriver X64 is too slow
setClipboard(u'批量报表导出')
srch_input.send_keys(Keys.CONTROL, 'v')
#[RETURN] will initiate the search, which is designed by the website
srch_input.send_keys(Keys.RETURN)

#560. Click on the search result to open the download page (the result is a new division on the same page)
#Quote: https://www.tutorialspoint.com/selenium-click-link-by-href-value
time.sleep(2)
link = driver.find_element(By.CSS_SELECTOR, '//a[href*="UTET00BI"]')
link.send_keys(Keys.RETURN)
#Sometimes [click] will not work
#link.click()

#569. Skip the warnings
time.sleep(2)
checkErrPage('Err Page2')

#570. Input the date texts on the refreshed page
time.sleep(2)
div_day = driver.find_element(By.NAME, 'SEARCH_DATE_REGISTER_D')
div_mon = driver.find_element(By.NAME, 'REGISTER_D_MONTH')
div_yr = driver.find_element(By.NAME, 'REGISTER_D_YEAR')
setClipboard(txt_day)
div_day.send_keys(Keys.CONTROL, 'v')
setClipboard(txt_month)
div_mon.send_keys(Keys.CONTROL, 'v')
setClipboard(txt_year)
div_yr.send_keys(Keys.CONTROL, 'v')

#580. Click on the [确定] button
time.sleep(1)
download_bgn = driver.find_element(By.CSS_SELECTOR, '//a[onclick*="submitBI"]')
download_bgn.send_keys(Keys.RETURN)

#590. Send the keys [Alt+S] to save the file to the default directory
time.sleep(5)
win32gui.SetForegroundWindow(win32gui.FindWindow('IEFrame', None))
time.sleep(1)
#[对照表]
#Quote: https://www.cnblogs.com/chenxi188/p/11642006.html
#[Alt]
win32api.keybd_event(0x12,0,0,0)
#[S]
win32api.keybd_event(83,0,0,0)
win32api.keybd_event(83, 0, win32con.KEYEVENTF_KEYUP, 0)
win32api.keybd_event(0x12, 0, win32con.KEYEVENTF_KEYUP, 0)

logger.info('700. Close the IE session')
#710. According to the LAN speed, we wait for 20 seconds and until the file is downloaded
for i in range(4):
    time.sleep(5)
    if all([os.path.isfile(f) for f in L_stpflnm]):
        driver.quit()
        break

#750. Monitor all IE windows afterwards
hwnd_final = win32gui.FindWindow('IEFrame', None)
while hwnd_final:
    #Quote: https://stackoverflow.com/questions/27586411/how-do-i-close-window-with-handle-using-win32gui-in-python
    win32gui.PostMessage(hwnd_final,win32con.WM_CLOSE,0,0)
    hwnd_final = win32gui.FindWindow('IEFrame', None)

logger.info('800. Move the files to the sharedrive')
dir_share = r'network/drive'
files_share = [ os.path.join(dir_share, f) for f in files_all ]

logger.info('---------------------华丽的分割线---------------------')
#Quote: https://pypi.org/project/progressbar2/
pb_widgets = [
    ' [', progressbar.Timer(), '] '
    , progressbar.Bar()
    , ' (', progressbar.ETA(), ') '
]
for f in progressbar.progressbar(L_stpflnm, widgets = pb_widgets):
    #100. Open the PIPE
    rc = sp.Popen(
        ['copy', '/y', f, dir_share]
        #[shell=True] is often used when the command is comprised of executable, arguments and switches, instead of a list
        #It is always recommended NOT to set [shell] argument for [sp.Popen] to save system parsing resources
        #Quote: https://stackoverflow.com/questions/20451133/
        #Quote: https://stackoverflow.com/questions/69544990/
        ,shell = True
        ,stdout = sp.PIPE
        ,stderr = sp.PIPE
    )

    #700. Communicate with the pipe, i.e. submit the commands in the console
    #[ASSUMPTION]
    #[1] This operation cause Python to wait for the completion of the commands
    #[2] This operation enables a [returncode] after the completion of the commands
    copy_msg, copy_errs = rc.communicate()

    #709. Abort the process if SAS program encounters issues
    if rc.returncode:
        raise RuntimeError('File Copy executed with errors!')

    #790. Terminate the command console
    rc.terminate()

logger.info('890. Remove the files on this computer')
f_comp = [ os.path.isfile(f) for f in files_share ]
if all(f_comp):
    for f in L_stpflnm:
        if os.path.isfile(f): os.remove(f)
else:
    #It eventually never triggers
    err_copy = [ f for i,f in enumerate(files_all) if not f_comp[i] ]
    raise RuntimeError(
        'Below files have been downloaded by failed to copy to sharedrive:'
        + '\n' + '<Folder>: <' + dir_share + '>'
        + '\n' + '<Files >: \n<' + '>\n<'.join(err_copy) + '>'
    )
