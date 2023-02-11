#!/usr/bin/env python3
# -*- coding: utf-8 -*-

logger.info('Starting to download files from website...')
logger.info(u'This step is to demonstrate the scraper with the help of developer’s tool')

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
from selenium import webdriver
from selenium.webdriver.ie.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains
from omniPy.Dates import ObsDates
from omniPy.RPA import clicks, setForegroundWindow

#010. Local parameters
svr_home2 = 'https://aaa/bbb/'
txt_user = 'user'
txt_pwd = 'password'

site_home2 = svr_home2
site_title2 = 'test system 2'

logger.info('050. Calculate dates')
#051. Identify the holidays between today (which is presumably workday) and the previous workday
L_obsDates = ObsDates(obsDate = dt.date.today())
L_obsDates.DateOutAsStr = False
rundate_w = L_obsDates.prevWorkDay
kday_delta = (L_obsDates.values[0] - rundate_w[0] - dt.timedelta(days = 1)).days
rundate_h = [ rundate_w[0] + dt.timedelta(days = (1 + i)) for i in range(kday_delta) ]

rpt_date = rundate_w + rundate_h
query_date = [ d.strftime('%Y-%m-%d') for d in rpt_date ]
wds = [True] + [ False for d in rundate_h ]
#According to Business requirement, there are 2 files to download on each workday, while 1 on each holiday
k_files = [ 2 if f else 1 for f in wds ]

files_w = [
    'ODS_' + rundate_w[0].strftime('%Y%m%d') + '.zip'
    ,'MF_' + rundate_w[0].strftime('%Y%m%d') + '.zip'
]
files_h = [
    'MF_' + d.strftime('%Y%m%d') + '.zip'
    for d in rundate_h
]
files_all = files_w + files_h
L_stpflnm = [ os.path.join(dir_Downloads, f) for f in files_all ]

#060. Setup IE options
#selenium在启动IE浏览器的时候，能否像chrome那样配置user-agent启动参数
#Quote: https://ask.csdn.net/questions/761546
#Get your [user-agent] through below website, by visiting with IE, Chrome or Firefox, etc. (different for each)
#Quote: https://httpbin.org/headers
#[1] Below value is for [IE on Win10 21H1]
user_agent = 'Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko'
ie_options = webdriver.IeOptions()
ie_options.add_argument('user-agent=' + user_agent)
ie_options.add_argument('require_window_focus')
#Below options are to enable IE Mode in MS Edge, in case IE is no longer available while website only supports visiting via IE
#Quote: https://github.com/microsoft/edge-selenium-tools/issues/57
#Quote: https://learn.microsoft.com/en-us/microsoft-edge/webdriver-chromium/ie-mode?tabs=python
ie_options.attach_to_edge_chrome = True
ie_options.edge_executable_path = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'

#With this setting, one can place the IE driver in any path regardless of system PATH
#Quote: https://www.selenium.dev/documentation/webdriver/getting_started/install_drivers/
ie_service = Service(executable_path = '/path/to/iedriver')

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
        #Below is a popup window as ActiveX warning
        ,'ActiveX' : {
            'skip' : {
                'en_US' : u'Yes'
                ,'zh_CN' : u'确定'
            }
        }
    }
}

#070. Define function to close the window of ActiveX Warning
def closeActiveXWarning():
    #100. Find the window
    hwnd_warn = win32gui.FindWindow('#32770', 'Internet Explorer')

    #810. Set the window to the foreground
    #Quote: https://www.cnblogs.com/chenjy1225/p/12174889.html
    setForegroundWindow(hwnd_warn)

    #830. Get the rect of the control
    #[left]-[top]-[right]-[bottom]
    hwnd_pos = win32gui.GetWindowRect(hwnd_warn)

    #890. Click on the button within this window
    clicks((
        hwnd_pos[0] + 200
        ,hwnd_pos[1] + 120
    ))

logger.info('100. Login to the dedicated website')
#Quote: https://www.thepythoncode.com/article/automate-login-to-websites-using-selenium-in-python
#101. Initialize the IE driver
#[executable_path] is deprecated at [selenium=4.0.0]
driver = webdriver.Ie(service = ie_service, options = ie_options)
#driver.implicitly_wait(5)

#110. Open the login page
driver.get(site_home2)

#115. Skip the warnings
time.sleep(2)
closeActiveXWarning()

#130. Get the handle of IE
#Class [IEFrame] is indicated here:
#Quote: https://www.programcreek.com/python/example/4315/win32com.client.Dispatch
time.sleep(2)
hwnd_login = win32gui.FindWindow('IEFrame', u'登录 - Internet Explorer')

#150. Bring the window to the foreground and maximize it
setForegroundWindow(hwnd_login)
#Quote: https://www.programcreek.com/python/example/115351/win32con.SW_MAXIMIZE
win32gui.ShowWindow( hwnd_login, win32con.SW_MAXIMIZE )

#160. Input values and click the login button
#161. Click on the position of [机构] and fill in the dedicated value
time.sleep(0.5)
in_br = driver.find_element(By.ID, 'brhIdId')
in_br.send_keys('CHINA MAIN BR')
#Wait for long enough till the dropdown list shows
time.sleep(2)
#Confirm the selection
in_br.send_keys(Keys.RETURN)

#163. Find the input form [操作员] and fill in the dedicated value
time.sleep(0.5)
in_user = driver.find_element(By.ID, 'oprid')
in_user.send_keys(txt_user)

#165. Find the input form [密码] and fill in the dedicated value
time.sleep(0.5)
in_pwd = driver.find_element(By.ID, 'password')
in_pwd.send_keys(txt_pwd)

#169. Click on the [login] button
time.sleep(0.5)
btn_login = driver.find_element(By.ID, 'ext-gen15')
btn_login.send_keys(Keys.RETURN)

logger.info('500. Download report')
#505. Bring the window with main page to the foreground
time.sleep(5)
#Assume there is only one IE window and it is initiated by our webdriver
driver.switch_to.window(driver.window_handles[0])
hwnd_main = win32gui.FindWindow('IEFrame', None)
setForegroundWindow(hwnd_main)
#Quote: https://www.programcreek.com/python/example/115351/win32con.SW_MAXIMIZE
win32gui.ShowWindow( hwnd_main, win32con.SW_MAXIMIZE )

#530. Get the page of specified menu
#[IMPORTANT] Starting from this step, we need to call [driver.page_source] frequently, and look inside its content for URL
#driver.page_source
id_page = 'U0203009'
#Quote: https://stackoverflow.com/questions/62320910/how-to-change-the-input-field-value-using-selenium-and-python
ul_setup = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.CSS_SELECTOR, 'ul[id="ext-gen77"]')))
div_setup = ul_setup.find_element(By.CSS_SELECTOR, '.x-tree-node-el[ext:tree-node-id="' + id_page + '"]')
tab_setup = div_setup.find_element(By.CSS_SELECTOR, 'a[tabIndex=1]')
#It never works to [click] on such an <anchor>
#tab_setup.click()
tab_setup.send_keys(Keys.RETURN)

#540. Open the tab of download frame
#[1] The tested server will block consecutive download actions in the same page, so we [get] the URL each time as refresh
#[2] Due to above reason, we need the absolute URL for the download page, instead of a switch to its subordinate [iframe]
#541. Define helper function to locate the <anchor>s
def getAnchors(date):
    #010. Switch to the download page
    #Quote: https://stackoverflow.com/questions/34907897/selecting-nested-iframes-with-selenium-in-python
#    fr_down = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CSS_SELECTOR, 'iframe[src*=' + id_page + ']')))
#    driver.switch_to.frame(fr_down)
    driver.get(svr_home2 + 'page/terminal/device/' + id_page + '.jsp')

    #100. Click on the tab to open the iframe with download list
    #110. Find the <li> tag which contains the download link
    li_down = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'li_ID')))

    #150. Locate its subordinate <a> and click on it
    a_down = li_down.find_element(By.ID, 'ext-gen29')
    #[click] works here
    a_down.click()

    #300. Input the report date for searching
    in_date = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'txnDateQuery')))
    #Quote: https://stackoverflow.com/questions/62320910/how-to-change-the-input-field-value-using-selenium-and-python
    ActionChains(driver).click(in_date).key_down(Keys.CONTROL).send_keys('a').key_up(Keys.CONTROL).send_keys(date).perform()

    #500. Click on the button [submit] to conduct the search
    btn_submit = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'ext-gen119')))
    btn_submit.send_keys(Keys.RETURN)

    #700. Find all <anchor>s from the search result as a table
    table_down = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID, 'ext-gen131')))
    a_result = table_down.find_element(By.CSS_SELECTOR, 'div[id="ext-gen132"]').find_elements(By.CSS_SELECTOR, 'a')

    #999. Export the result
    return(a_result)

#545. Loop each file on each date as required, to download them respectively
for i,d in enumerate(rpt_date):
    for j in range(k_files[i]):
        #100. Get the available anchors at each iteration
        a_down = getAnchors(query_date[i])

        #300. Click the [j]th link on the page
        setForegroundWindow(hwnd_main)
        time.sleep(0.5)
        a_down[j].click()

        #590. Send the keys [Alt+S] to save the file to the default directory
        time.sleep(3)
        #[对照表]
        #Quote: https://www.cnblogs.com/chenxi188/p/11642006.html
        #[Alt]
        win32api.keybd_event(0x12,0,0,0)
        #[S]
        win32api.keybd_event(83,0,0,0)
        win32api.keybd_event(83, 0, win32con.KEYEVENTF_KEYUP, 0)
        win32api.keybd_event(0x12, 0, win32con.KEYEVENTF_KEYUP, 0)
        #Postpone the next iteration to avoid the crowd
        time.sleep(2)

logger.info('700. Close the IE session')
#710. According to the LAN speed, we wait for 300 seconds and until the file is downloaded
for i in range(30):
    time.sleep(10)
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
