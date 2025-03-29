#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to send the report to recipients                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Many companies forbid MAPI, so we only dispatch MSOutlook to fabricate the manual emailing                                     #
#   |[2] Use this method only when you installed MSOutlook and login with a valid account                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |QUOTE                                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Embed pictures in body: https://win32com.goermezer.de/microsoft/ms-office/send-email-with-outlook-and-python.html              #
#   |[2] COM API: https://learn.microsoft.com/en-us/previous-versions/office/dn320330(v=office.15)?redirectedfrom=MSDN                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250329        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Send Email')
import os
from win32com.client import Dispatch
from omniPy.AdvOp import get_values

#010. Local environment
L_srcflnm1 = os.path.join(dir_data_db, f'attrs_rpt{L_curdate}.hdf')
L_srcflnm10 = os.path.join(dir_data_raw, 'mail_content.txt')

#040. Load the data in current session
if not isinstance(get_values('attrs_rpt', inplace = False), pd.DataFrame):
    attrs_rpt = dataIO['HDFS'].pull(L_srcflnm1, 'attrs_rpt')

print('100. Load mail template')
with open(L_srcflnm10, 'r', encoding = 'utf-8') as f:
    mail_tpl = f.readlines()

cnt_local = {
    'rpt_name' : ';'.join([os.path.splitext(os.path.basename(f))[0] for f in attrs_rpt['RPT_FILE']])
}

print('200. Dispatch the application')
#ssn = Dispatch('Mapi.Session')
#ssn.Logon('Outlook2019')
mail = Dispatch('Outlook.Application')

print('300. Prepare the message')
msg = mail.CreateItem(0)
msg.To = 'recipient@domain.com'

msg.CC = ';'.join([
    'more email addresses here'
])
msg.BCC = 'more email addresses here'

msg.Subject = 'The subject of your mail'

msg.SentOnBehalfOfName = 'onbehalfofname@domain.com'

#Quote: https://stackoverflow.com/questions/21466180/sending-high-importance-email-through-outlook-using-python
msg.Importance = 2

print('500. Prepare the attachments')
for att in attrs_rpt['RPT_FILE']:
    msg.Attachments.Add(att)

print('700. Prepare the mail body')
msg.HTMLBody = ''.join(mail_tpl).replace('\n', '<br/>').format(**cnt_local)

print('999. Sending the mail...')
msg.Send()
print('Mail sent!')
