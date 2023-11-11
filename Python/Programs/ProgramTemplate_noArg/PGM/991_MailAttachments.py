#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#[FEATURE]
#[1] Launch MS Outlook
#[2] Filter emails with certain criteria
#[3] Download attachments
print('Filter Email')
import os, sys
import pywintypes
import win32com.client
import datetime as dt

#100. Get API to operate MS Outlook on the fly (require Outlook to be active and logged in)
outlook = win32com.client.Dispatch('Outlook.Application').GetNamespace('MAPI')

#200. Locate inbox of current user
#[ASSUMPTION]
#[1] Ensure constants are registered before this Python session, see [HOW TO] section
inbox = outlook.GetDefaultFolder(win32com.client.constants.olFolderInbox)

#300. Filter emails by specific rules
#Quote: https://stackoverflow.com/questions/39656433/how-to-download-outlook-attachment-from-python-script
#[ASSUMPTION]
#[1] See [HOW TO] for the list of valid restriction keywords
rec_dt = (dt.datetime.now() - dt.timedelta(days = 1)).strftime('%m/%d/%Y %H:%M %p')
restricts = {
    'From' : ' '.join([
        chr(34) + 'urn:Schemas:httpmail:fromname' + chr(34)
        ,'='
        ,chr(39) + 'Display Name of Sender' + chr(39)
    ])
    #Quote: https://stackoverflow.com/questions/53874973/restrict-outlook-items-to-todays-date-vba
    #Quote: https://learn.microsoft.com/en-us/office/vba/outlook/how-to/search-and-filter/filtering-items-using-a-date-time-comparison
    ,'Date' : '%today(' + chr(34) + 'urn:schemas:httpmail:datereceived' + chr(34) + ')%'
    ,'Subject' : ' '.join([
        chr(34) + 'urn:Schemas:httpmail:Subject' + chr(34)
        ,'Like'
        ,chr(39) + 'SQL LIKE SYNTAX%' + chr(39)
    ])
    ,'HasAttachment' : ' '.join([
        chr(34) + 'urn:Schemas:httpmail:HasAttachment' + chr(34)
        ,'='
        ,'1'
    ])
}
criteria = ['From','Subject','HasAttachment']
messages = inbox.Items.Restrict('@SQL=' + ' AND '.join([ v for k,v in restricts.items() if k in criteria ]))

#350. Add further filtration
messages = messages.Restrict(f'[ReceivedTime] >= {chr(39)}{rec_dt}{chr(39)}')

if len(messages) == 0:
    sys.exit()

#400. Download all attachments
for m in messages:
    for att in m.Attachments:
        print(att.FileName)
        att.SaveAsFile(os.path.join(os.path.expanduser(r'~\Documents'), att.FileName))

#900. Delete all identified emails
#[ASSUMPTION]
#[1] In case the iterator is dynamically modified by the API, we only conduct the process all afterwards
for m in messages:
    m.Delete()

'''
#All constants regarding MS Outlook folders
#Quote: https://learn.microsoft.com/zh-cn/office/vba/api/outlook.oldefaultfolders

#Quote: https://stackoverflow.com/questions/67481097/iterate-through-folders-in-a-secondary-outlook-inbox-using-python
#In case there are multiple stores for the same Outlook session,
# we should iterate over all stores in below syntax
mapi = outlook.GetNamespace('MAPI')
for store in mapi.Stores:
    Inbox = store.GetDefaultFolder(6)

#Sample operations
#Quote: https://blog.csdn.net/keeppractice/article/details/125645302

#[HOW TO]
#[1] Setup interface to constants
#Quote: https://iarp.github.io/python/python3-win32com-constants.html
#Quote: https://stackoverflow.com/questions/48401919/pywin-installed-but-pythonwin-cannot-open
#[ASSUMPTION]
#We MUST follow below steps to enable the constants in Python
#    [1] Under <Anaconda-202307>, [Pythonwin.exe] cannot be executed properly; we thus have to call below script directly
#    [2] Run <Python.exe '<Anaconda Installation>/Lib/site-packages/win32com/client/makepy.py'> in command console
#    [3] Select ONLY ONE item, i.e. <Microsoft Outlook XX.X Object Library (X.X)> in the dropbox, then click <OK>
#    [4] Start a new Python session and dispatch the MS Outlook API <see above programs>
#    [5] Once the API is dispatched, run <win32com.client.constants.__dict__> to check all available constants

#[2] Access folder by name
#Quote: https://stackoverflow.com/questions/2043980/using-win32com-and-or-active-directory-how-can-i-access-an-email-folder-by-name

#[3] List of restriction keywords
#Quote: https://stackoverflow.com/questions/61086486/how-to-download-email-attachments-from-outlook-using-python
#Quote: https://stackoverflow.com/questions/74759904/pywin32-mail-filtering-using-restict-method
urn: Schemas: mailheader: approved
urn: Schemas: httpmail: attachmentfilename
urn: Schemas: mailheader: BCC
urn: Schemas: httpmail: BCC
urn: Schemas: httpmail: CC
urn: Schemas: mailheader: CC
urn: Schemas: mailheader: Comment
urn: Schemas: mailheader: content -base
urn: Schemas: mailheader: content -Class
urn: Schemas: mailheader: content -Description
urn: Schemas: mailheader: content -disposition
urn: schemas:httpmail:content-disposition-type
urn: Schemas: mailheader: content -ID
urn: Schemas: mailheader: content -Language
urn: Schemas: mailheader: content -Location
urn: schemas:httpmail:content-media-type
urn: Schemas: mailheader: content -transfer - Encoding
urn: schemas:mailheader:content-type
urn: Schemas: mailheader: Control
urn: Schemas: httpmail: Date
urn: Schemas: mailheader: Date
urn: Schemas: httpmail: DateReceived
urn: Schemas: httpmail: displaycc
urn: Schemas: httpmail: displayto
urn: Schemas: mailheader: disposition
urn:schemas:mailheader:disposition-notification-to
urn: Schemas: mailheader: distribution
urn: Schemas: mailheader: expires
urn: Schemas: mailheader: expiry -Date
urn: Schemas: httpmail: flagcompleted
urn:schemas:mailheader:followup-to
urn: Schemas: httpmail: From
urn: Schemas: mailheader: From
urn: Schemas: httpmail: fromemail
urn: Schemas: httpmail: fromname
urn: Schemas: httpmail: HasAttachment
urn: Schemas: httpmail: htmldescription
urn: Schemas: httpmail: Importance
urn: Schemas: mailheader: Importance
urn:schemas:mailheader:in-reply-to
urn: Schemas: mailheader: Keywords
urn: Schemas: mailheader: Lines
urn: Schemas: mailheader: Message -ID
urn: Schemas: httpmail: messageflag
urn: Schemas: mailheader: mime -Version
urn: Schemas: mailheader: Newsgroups
urn: Schemas: httpmail: normalizedsubject
urn: Schemas: mailheader: Organization
urn: Schemas: mailheader: original -Recipient
urn: Schemas: mailheader: Path
urn: Schemas: mailheader: posting -Version
urn: Schemas: httpmail: Priority
urn: Schemas: mailheader: Priority
urn: Schemas: mailheader: Received
urn: Schemas: mailheader: References
urn: Schemas: mailheader: relay -Version
urn: Schemas: httpmail: Reply -By
urn: Schemas: mailheader: Reply -By
urn:schemas:httpmail:reply-to
urn:schemas:mailheader:reply-to
urn:schemas:mailheader:return-path
urn:schemas:mailheader:return-receipt-to
urn: Schemas: httpmail: savedestination
urn: Schemas: httpmail: saveinsent
urn: Schemas: mailheader: Sender
urn: Schemas: httpmail: Sender
urn: Schemas: httpmail: SenderEMail
urn: Schemas: httpmail: SenderName
urn: Schemas: mailheader: Sensitivity
urn: Schemas: httpmail: Subject
urn: Schemas: mailheader: Subject
urn: Schemas: httpmail: Submitted
urn: Schemas: mailheader: summary
urn: Schemas: httpmail: textdescription
urn: Schemas: mailheader: thread -Index
urn: Schemas: mailheader: thread -topic
urn: Schemas: httpmail: thread -topic
urn:schemas:httpmail:to
urn:schemas:mailheader:to
urn: Schemas: mailheader: x -Mailer
urn: Schemas: mailheader: x -Message - completed
urn: Schemas: mailheader: x -Message - flag
urn: Schemas: mailheader: x -unsent
urn: Schemas: mailheader: xref

#[4] Delete mail items
#Quote: https://pyquestions.com/python-win32com-delete-multiple-emails-in-outlook
'''
