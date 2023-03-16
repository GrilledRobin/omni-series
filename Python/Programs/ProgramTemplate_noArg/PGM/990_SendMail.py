#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#[FEATURE]
#[1] Launch MS Outlook
#[2] Send an email on behalf of another account with attachments
#[3] Embed the pictures into HTML mail body
#Quote: https://win32com.goermezer.de/microsoft/ms-office/send-email-with-outlook-and-python.html
#MS official document for the COM API:
#Quote: https://learn.microsoft.com/en-us/previous-versions/office/dn320330(v=office.15)?redirectedfrom=MSDN
logger.info('Send Email')
import os
from win32com.client import Dispatch

#ssn = Dispatch('Mapi.Session')
mail = Dispatch('Outlook.Application')
#ssn.Logon('Outlook2019')

msg = mail.CreateItem(0)
msg.To = 'recipient@domain.com'

msg.CC = 'more email addresses here'
msg.BCC = 'more email addresses here'

msg.Subject = 'The subject of you mail'

msg.SentOnBehalfOfName = 'onbehalfofname@domain.com'

#Quote: https://stackoverflow.com/questions/21466180/sending-high-importance-email-through-outlook-using-python
msg.Importance = 2

attachment1 = 'Path to attachment no. 1'
attachment2 = 'Path to attachment no. 2'
msg.Attachments.Add(attachment1)

#[ASSUMPTION]
#[1] [attachment2] is a picture which is required to embed in the body of the mail
#Quote: https://python-forum.io/thread-12718.html
att = msg.Attachments.Add(attachment2)
#Quote: https://learn.microsoft.com/en-us/office/client-developer/outlook/mapi/mapping-mapi-names-to-canonical-property-names
PR_ATTACH_MIME_TAG = 'http://schemas.microsoft.com/mapi/proptag/0x370E001F'
#Quote: https://duoduokou.com/python/40842699176642623618.html
PR_ATTACH_CONTENT_ID = 'http://schemas.microsoft.com/mapi/proptag/0x3712001F'
img_id = 'MyId1'
att.PropertyAccessor.SetProperty(PR_ATTACH_MIME_TAG, 'image/' + os.path.splitext(os.path.basename(attachment2))[-1][1:])
att.PropertyAccessor.SetProperty(PR_ATTACH_CONTENT_ID, img_id)

mailbody = '<h1>Test body with image</h1><br><br><br><br> <img src="cid:'+img_id+'" height=42 width=42>'
msg.HTMLBody = mailbody

msg.Send()
