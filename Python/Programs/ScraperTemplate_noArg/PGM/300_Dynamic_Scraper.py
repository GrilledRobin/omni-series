#!/usr/bin/env python3
# -*- coding: utf-8 -*-

print('Starting to download files from website...')
#[ASSUMPTION]
#[1] Allow user to define specific scrapers for the items on the same website, without patching the class everytime
#[2] The specific scrapers can be dynamically created in RAM (and with a design, can be dynamically imported from modules)

import os, logging, re, platform, inspect, types, time
#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32con, win32gui
import datetime as dt
from win32com.client import GetObject
from collections.abc import Iterable
from selenium import webdriver
from selenium.webdriver.edge.service import Service as edgeService
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from omniPy.AdvOp import getWinUILanguage, importByStr, modifyDict, ls_frame
from omniPy.Dates import asDates
from omniPy.RPA import getDesktopWindows
from omniPy.FileSystem import winReg_getInfByStrPattern, winKnownFolders

#100. Define class to generalize the operations
class OpsWebsite:
    #002. Constructor
    def __init__(
        self
        ,website : str = 'https://aaa/bbb/'
        ,webtitle : str = 'Title'
        ,scraper : str = 'Chrome'
        ,user : str = None
        ,pwd : str = None
        ,apiPkgPull : str = None
        ,apiPfxPull : str = 'webDownload_'
        ,apiSfxPull : str = ''
        ,lsPullOpt : dict = {}
    ):
        #100. Assign values to local variables
        self.website = website
        self.webtitle = webtitle
        self.scraper = scraper
        self.user = user
        self.pwd = pwd
        self.apiPkgPull = apiPkgPull
        self.apiPfxPull = apiPfxPull
        self.apiSfxPull = apiSfxPull
        self.lsPullOpt = lsPullOpt
        self._rst = {}

        self.loginpage = re.sub(r'/\s*$', '', self.website) + '/login.jsp'
        self.curr_win_ver = platform.release()
        self.curr_win_lang = getWinUILanguage()
        #Retrieve the default folder [Downloads] for current user on Windows OS
        self.dir_Downloads = winKnownFolders('Downloads')
        self.path_omniPy = os.path.dirname(os.path.dirname(importByStr('omniPy', asModule = True).__file__))

        #Identify all <pull> methods matching the provided pattern of API names
        self.hasPkgPull = False
        if isinstance(self.apiPkgPull, str):
            if len(self.apiPkgPull) > 0:
                self.hasPkgPull = True

        #Enable the chromium based web browser to download multiple files at the same time
        #Quote: https://stackoverflow.com/questions/31430532/
        self.prefs = {'profile.default_content_setting_values.automatic_downloads': 1}

        #300. Determine the caller of the driver
        self['_init_' + self.scraper]()

        #500. Search for available APIs
        #[ASSUMPTION]
        #[1] Ensure the evaluation is only conducted once
        this_full = self.full
        self.__dict_active__ = { k:False for k in this_full }

    #Method to enable slicing fashion during operation on APIs
    #Quote: https://www.liaoxuefeng.com/wiki/1016959663602400/1017590712115904
    def __getitem__(self, attr):
        return(getattr(self, attr))

    def termScraper(self):
        #[ASSUMPTION]
        #[1] We do not use the package <wmi> as it is too slow
        #使用Python玩转WMI
        #Quote: https://segmentfault.com/a/1190000021661055
        mywmi = GetObject('winmgmts:/root/cimv2')
        # mywmi = GetObject('winmgmts:') #更简单的写法
        processes = mywmi.ExecQuery(f'Select * from Win32_Process where Name="{self.scraper.lower()}.exe"')
        for p in processes:
            try:
                p.Terminate()
            except:
                pass

    def disconnect(self):
        self.removefull()
        self.driver.quit()
        self.termScraper()

    def _init_Chrome(self):
        #Quote: https://stackoverflow.com/questions/20203947/windows-registry-location-for-google-chrome-version
        exec_vers = winReg_getInfByStrPattern(
            r'HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon'
            ,inRegExp = r'^version$'
            ,chkType = 1
        )
        exec_ver = [ v['value'] for v in exec_vers if v['reqtype'] == 'value' ][0]
        #For current browser, the selenium driver only validates the version EXCEPT the minor number
        driver_ver = '.'.join(exec_ver.split('.')[:3])
        #20230207 It is tested that <win32> should be used instead of <x64>
        driver_exec = os.path.join(self.path_omniPy, 'Packages', 'Selenium', 'drivers', self.scraper, driver_ver, 'win32', 'chromedriver.exe')

        #Quote: https://stackoverflow.com/questions/62490495/how-to-change-the-user-agent-using-selenium-and-python
        user_agent = f'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{exec_ver} Safari/537.36'
        #Quote: https://www.selenium.dev/documentation/webdriver/browsers/chrome/
        web_options = webdriver.ChromeOptions()
        web_options.add_argument('--user-agent=' + user_agent)
        web_options.add_argument('--start-maximized')
        web_options.add_experimental_option('excludeSwitches', ['disable-popup-blocking'])
        #Quote: https://www.coder.work/article/166344
        web_options.add_argument('--no-sandbox')
        web_options.add_experimental_option('prefs', self.prefs)

        #Update local variables
        self.web_service = webdriver.ChromeService(executable_path = driver_exec)
        self.browser_win = 'Google Chrome'
        self.hwnd_class = 'Chrome_WidgetWin_1'
        self.web_options = web_options
        self.driver_call = webdriver.Chrome

    def _init_MSEdge(self):
        #Quote: https://stackoverflow.com/questions/20203947/windows-registry-location-for-google-chrome-version
        exec_vers = winReg_getInfByStrPattern(
            r'HKEY_CURRENT_USER\Software\Microsoft\Edge\BLBeacon'
            ,inRegExp = r'^version$'
            ,chkType = 1
        )
        exec_ver = [ v['value'] for v in exec_vers if v['reqtype'] == 'value' ][0]
        #For current browser, the selenium driver only validates the version EXCEPT the minor number
        driver_ver = '.'.join(exec_ver.split('.')[:3])
        #20230207 It is tested that <win32> should be used instead of <x64>
        driver_exec = os.path.join(self.path_omniPy, 'Packages', 'Selenium', 'drivers', self.scraper, driver_ver, 'win32', 'msedgedriver.exe')

        #Quote: https://stackoverflow.com/questions/62490495/how-to-change-the-user-agent-using-selenium-and-python
        user_agent = f'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{exec_ver} Safari/537.36'
        #Quote: https://www.selenium.dev/documentation/webdriver/browsers/chrome/
        web_options = webdriver.EdgeOptions()
        web_options.add_argument(f'user-agent="{user_agent}"')
        web_options.add_argument('start-maximized')
        web_options.add_experimental_option('excludeSwitches', ['disable-popup-blocking'])
        web_options.add_experimental_option('prefs', self.prefs)
        web_options.use_chromium = True

        #Update local variables
        self.web_service = edgeService(executable_path = driver_exec)
        self.browser_win = 'Microsoft\u200b Edge'
        self.hwnd_class = 'Chrome_WidgetWin_1'
        self.web_options = web_options
        self.driver_call = webdriver.Edge

    def connect(self, user = None, pwd = None):
        #Quote: https://stackoverflow.com/questions/9226519/turning-off-logging-in-selenium-from-python
        from selenium.webdriver.remote.remote_connection import LOGGER as seleniumLogger
        seleniumLogger.setLevel(logging.ERROR)

        #010. Determine the user
        txt_user = user if isinstance(user, str) else self.user
        txt_pwd = pwd if isinstance(pwd, str) else self.pwd

        if not isinstance(txt_user, str):
            raise ValueError(f'<user> must be a string! Provided <{type(txt_user).__name__}>')
        if not isinstance(txt_pwd, str):
            raise ValueError(f'<pwd> must be a string! Provided <{type(txt_pwd).__name__}>')

        #050. Close any active web driver
        self.termScraper()

        #080. Prepare the fresh web driver
        self.driver = self.driver_call(service = self.web_service, options = self.web_options)

        #100. Open the login page of the dedicated website
        self.driver.get(self.loginpage)

        #120. Skip the warning page if it is regarded as <unsafe>, i.e. non <https>
        #[ASSUMPTION]
        #[1] Some old website in intranet of a company may not use <https> protocol for user connection
        try:
            private_skip = (
                WebDriverWait(self.driver, 5)
                .until(EC.element_to_be_clickable((By.ID, 'details-button')))
            )
            private_skip.click()
            proceed_skip = (
                WebDriverWait(self.driver, 2)
                .until(EC.element_to_be_clickable((By.ID, 'proceed-link')))
            )
            proceed_skip.click()
        except:
            pass

        #300. Get the handle of the web browser
        time.sleep(1)
        hwnd_desktop = getDesktopWindows()
        name_mainpage = [
            v['title']
            for k,v in hwnd_desktop.items()
            if re.search(rf'^{self.webtitle}.+{self.browser_win}$', v['title'])
        ][0]
        win_login = win32gui.FindWindow(self.hwnd_class, name_mainpage)

        #500. Maximize it if needed
        win32gui.ShowWindow(win_login, win32con.SW_MAXIMIZE)

        #800. Input values and click the login button
        #801. Switch to the correct iframe
        fr_screen = self.driver.find_element(By.NAME, 'screen')
        self.driver.switch_to.frame(fr_screen)
        fr_login = self.driver.find_element(By.NAME, 'content')
        self.driver.switch_to.frame(fr_login)

        #810. User
        in_user = WebDriverWait(self.driver, 5).until(EC.element_to_be_clickable((By.ID, 'userID')))
        in_user.send_keys(Keys.DELETE, txt_user)

        #850. Password
        in_pwd = WebDriverWait(self.driver, 5).until(EC.element_to_be_clickable((By.NAME, 'password')))
        in_pwd.send_keys(Keys.DELETE, txt_pwd)

        #890. Submit
        btn_login = WebDriverWait(self.driver, 5).until(EC.element_to_be_clickable((By.NAME, 'login')))
        btn_login.click()

        #[ASSUMPTION]
        #[1] There may be alert noticing that there was a previously active connection and asking to close it
        #     before proceeding
        #[2] However, this does not prevent further actions
        #[3] Hence, we wait a little while for it to popup and directly accept this alert before next steps
        #Quote: https://stackoverflow.com/questions/74108141/selenium-chrome-unexpected-alert-open
        time.sleep(1)
        try:
            alert = self.driver.switch_to.alert
            alert.accept()
        except:
            pass

        #900. Wait untile the new popup window shows while the initial page is NOT closed
        for _ in range(5):
            time.sleep(5)
            hwnd_desktop = getDesktopWindows()
            chk_main = [
                v['title']
                for k,v in hwnd_desktop.items()
                if re.search(rf'^{self.webtitle}.+{self.browser_win}$', v['title'])
            ]
            if len(chk_main) == 2:
                break

        #950. Switch the control to the newly borne window
        self.driver.switch_to.window(self.driver.window_handles[-1])

    #[ASSUMPTION]
    #[1] If we need to download data from any <iframe> embedded in current website, there could be stale elements
    #     that we cannot get via the driver every time
    #[2] Hence we need to extract the absolute path of the <iframe> and get it via the driver directly
    #[3] Below is an example of redirecting the driver via dynamic search within a <JSP> query
    def getpath(self, path = 'AAA'):
        self.path_expr = 'O' if path == 'AAA' else 'M'
        self.path_menu = 'O' if path == 'AAA' else 'M'
        self.driver.get(
            f'{self.website}/jsp/GenericExport.jsp?FUNCTION_ID=ABC'
            +f'&MENU_ID={self.path_menu}'
            +f'&EXPR={self.path_expr}'
            +'&submit=Y'
        )

    def download(
        self
        ,mapper = {'rptid01' : {'dates' : None}}
    ):
        for rpt_id,rpt_cfg in mapper.items():
            #100. Determine the dates
            opsdate = asDates(rpt_cfg.get('dates', None))

            if isinstance(opsdate, Iterable):
                opsdate = opsdate[:]
            else:
                opsdate = [opsdate]

            #500. Loop the dates with certain process
            for d in opsdate:
                if not isinstance(d, dt.date):
                    print(f'Date is not provided for downloading <{rpt_id}>. Skip current step')
                    continue

                #[ASSUMPTION]
                #[1] Import the method every time it is requested, to enable dynamic debugging
                #[2] One must save the API/method to the module, or re-define it in current session, before calling this method
                self.add(rpt_id)

                modifyDict(
                    self._rst
                    ,{
                        rpt_id : {
                            d : self[f'down_{rpt_id}'](cfg = {k:v for k,v in rpt_cfg.items() if k not in ['dates']}, date = d)
                        }
                    }
                    ,inplace = True
                )

    def add(self, attr : str):
        #001. Verify whether the API can be found in the candidate packages
        if attr not in self.full:
            raise ValueError(f'[{self.__class__.__name__}]No method is found to register API for [{attr}]!')

        #500. Import the method
        #Quote: https://stackoverflow.com/questions/972/adding-a-method-to-an-existing-object-instance-in-python
        apiPtnPull = str(self.apiPfxPull) + attr + str(self.apiSfxPull)
        try:
            if self.hasPkgPull:
                __func_pull__ = importByStr('.' + apiPtnPull, package = self.apiPkgPull)
            else:
                __func_pull__ = list(ls_frame(pattern = f'^{apiPtnPull}$', **self.lsPullOpt).values())
                if len(__func_pull__) == 1:
                    __func_pull__ = __func_pull__[0]
                else:
                    __func_pull__ = None
        except:
            __func_pull__ = None

        #700. Verify whether the core reader is callable on the fly
        if not callable(__func_pull__):
            raise TypeError(f'[{self.__class__.__name__}][{apiPtnPull}] is not callable!')

        #900. Bind the method to current instance
        setattr(self, f'down_{attr}', types.MethodType(__func_pull__, self))

        #950. Update the API status
        modifyDict(self.__dict_active__, { attr : True }, inplace = True)

    def addful(self):
        for a in self.full:
            self.add(a)

    def remove(self, attr):
        if attr in self.active:
            delattr(self, f'down_{attr}')
            modifyDict(self.__dict_active__, { attr : False }, inplace = True)

    def removefull(self):
        for a in self.active:
            self.remove(a)

    def _rem_affix_(self, mthdname : set, pfx : str = '', sfx : str = ''):
        def h_r_a(m):
            rstOut = m
            if len(pfx):
                rstOut = rstOut[len(pfx):]
            if len(sfx):
                rstOut = rstOut[:-len(sfx)]
            return(rstOut)
        return({ h_r_a(m) for m in mthdname })

    @property
    def full(self):
        #Quote: https://stackoverflow.com/questions/139180/how-to-list-all-functions-in-a-module
        if self.hasPkgPull:
            pkg_pull = importByStr(self.apiPkgPull, asModule = True)
            api_pull = {
                f
                for f,o in inspect.getmembers_static(pkg_pull, predicate = callable)
                if f.startswith(self.apiPfxPull) and f.endswith(self.apiSfxPull)
            }
        else:
            lsPullOpt = {
                'verbose' : False
                ,'predicate' : callable
                ,'flags' : re.NOFLAG
                ,**{ k:v for k,v in self.lsPullOpt.items() if k not in ['pattern','verbose','predicate','flags'] }
            }
            api_pull = {
                f
                for f in ls_frame(pattern = f'^{self.apiPfxPull}.+{self.apiSfxPull}$', **lsPullOpt)
            }

        #999. Export
        return(self._rem_affix_(api_pull, pfx = self.apiPfxPull, sfx = self.apiSfxPull))

    @property
    def status(self):
        return(self.__dict_active__)

    @property
    def active(self):
        return({ k for k,v in self.status.items() if v })

    @property
    def result(self):
        return(self._rst)
#End class

#300. Instantiate the class
#[ASSUMPTION]
#[1] Ensure to search for APIs in current session, instead of from physical modules
opsWebsite = OpsWebsite(apiPkgPull = None, user = 'XXXXX', pwd = 'YYYYY')

#310. Connect the server
opsWebsite.connect()

#350. One can also provide different credentials at runtime
# opsWebsite.connect(user = 'XXXXX', pwd = 'YYYYY')

#500. Add API at runtime
#501. Import specific modules for this API
import os, time
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from omniPy.AdvOp import tryProc

#[ASSUMPTION]
#[1] Try as many times for the same session
#[2] Raise if all attempts fail
@tryProc(times = 5, interval = 300.0)
def webDownload_RPTTESTER01(self, cfg : dict = {}, date : dt.date = None):
    #010. Local parameters
    rptpath = 'AAA'
    rptid = 'RPTTESTER01'
    rptname = 'Test 01'
    txt_day = date.strftime('%d')
    txt_month = date.strftime('%m')
    txt_year = date.strftime('%Y')
    files_all = [date.strftime('%Y%m%d') + '.zip']
    chkflnm = [os.path.join(self.dir_Downloads, f + '.partial') for f in files_all]
    stpflnm = [os.path.join(self.dir_Downloads, f) for f in files_all]

    for f in chkflnm + stpflnm:
        if os.path.isfile(f):
            try:
                os.remove(f)
            except:
                raise FileExistsError(f'<{f}> cannot be removed! Program is bombed!')

    #100. Switch the driver to the corresponding path
    self.getpath(rptpath)

    #300. Search for the dedicated data to download
    srch_input = WebDriverWait(self.driver, 20).until(EC.element_to_be_clickable((By.NAME, 'SEARCH_TEXT')))
    srch_input.send_keys(rptname)
    btn_search = self.driver.find_element(By.XPATH, ".//a[contains(text(), 'search')][1]")
    btn_search.click()

    #350. Click on the search result to open the download page
    link = WebDriverWait(self.driver, 60).until(EC.visibility_of_element_located((By.XPATH, f'//a[contains(@href, "{rptid}")]')))
    link.send_keys(Keys.RETURN)

    #500. Input the date variables
    d_in_day = WebDriverWait(self.driver, 5).until(EC.element_to_be_clickable((By.NAME, 'SEARCH_DATE_D')))
    d_in_month = self.driver.find_element(By.NAME, 'SEARCH_DATE_M')
    d_in_year = self.driver.find_element(By.NAME, 'SEARCH_DATE_Y')

    actions = (
        ActionChains(self.driver)
        .click(d_in_day)
        #10 times is enough as the date format is <YYYY-MM-DD> which only contains 10 characters
        .send_keys(*tuple(Keys.LEFT for i in range(10)))
        .send_keys(*tuple(Keys.DELETE for i in range(10)))
        .send_keys(txt_day)
    )
    actions.perform()

    actions = (
        ActionChains(self.driver)
        .click(d_in_month)
        #10 times is enough as the date format is <YYYY-MM-DD> which only contains 10 characters
        .send_keys(*tuple(Keys.LEFT for i in range(10)))
        .send_keys(*tuple(Keys.DELETE for i in range(10)))
        .send_keys(txt_month)
    )
    actions.perform()

    actions = (
        ActionChains(self.driver)
        .click(d_in_year)
        #10 times is enough as the date format is <YYYY-MM-DD> which only contains 10 characters
        .send_keys(*tuple(Keys.LEFT for i in range(10)))
        .send_keys(*tuple(Keys.DELETE for i in range(10)))
        .send_keys(txt_year)
    )
    actions.perform()

    #700. Click on the <Confirm> button
    time.sleep(2)
    btn_download = self.driver.find_element(By.XPATH, '//a[contains(@onclick, "submit")]')
    btn_download.click()

    #900. Verify the download
    for _ in range(12):
        time.sleep(10)
        if all([os.path.isfile(f) for f in stpflnm]):
            return(stpflnm)

    #999. Raise exception if not all of the files are downloaded
    raise RuntimeError(f'Failed to download <{rptid}>')

#600. Download data via the API just created above
mapper = {
    'RPTTESTER01' : {
        'dates' : ['20240416','20240417']
    }
}
opsWebsite.download(mapper)

#690. View the downloaded file names
rst = opsWebsite.result

#900. Purge
opsWebsite.disconnect()

for v in rst.values():
    for rstfiles in v.values():
        for f in rstfiles:
            if os.path.isfile(f): os.remove(f)
