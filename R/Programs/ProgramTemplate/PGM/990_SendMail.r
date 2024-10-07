#[FEATURE]
#[1] Launch MS Outlook
#[2] Send an email on behalf of another account with attachments
#[3] Embed the pictures into HTML mail body
#Quote: https://win32com.goermezer.de/microsoft/ms-office/send-email-with-outlook-and-python.html
#[ASSUMPTION]
#[1] <message> is captured via user defined handler in <main.r>, hence we use it directly for logging
message('Send Email')

#Quote: https://www.listendata.com/2015/12/send-email-from-r.html
library(RDCOMClient)
#[ASSUMPTION]
#[1] The installation of this package is not straightforward, see [R\Packages] folder for details
#[2] The usage of this package is similar to [win32com.client.Dispatch] in Python
#[3] It is recommended to use '[[' method to assign values to [mail] attributes instead of '$', as warned by the package
#[4] The content of [emailbody.txt] should always end with an empty new line to suppress warnings
#[5] Ensure [outlook] is logged in and active at background/foreground

#010. Parameters
#[ASSUMPTION]
#[1] It is tested that <glue> causes error, presumably due to the lazy-evaluation mechanism of R
#[2] Hence we do not use <glue> to parse the text
L_srcflnm <- file.path(dir_data_raw, 'emailbody.txt')

#200. Load the mail body text
mailBody <- readLines(L_srcflnm) %>%
	paste0(collapse = '<br/>')

#300. Dispatch the API
outlook <- COMCreate('Outlook.Application')
mail <- outlook$CreateItem(0)

#500. Set the mail specs
mail[['SentOnBehalfOfName']] <- 'onbehalfofname@domain.com'
mail[['To']] <- 'recipient@domain.com'
mail[['CC']] <- 'more email addresses here'
mail[['BCC']] <- 'more email addresses here'
mail[['Subject']] = 'The subject of you mail'

attachment1 <- 'Path to attachment no. 1'
attachment2 <- 'Path to attachment no. 2'
att_ext_pre <- strsplit(basename(attachment2), '.', fixed = T)[[1]]
att_ext <- att_ext_pre[[length(att_ext_pre)]]
mail[['Attachments']]$Add(attachment1)

#[ASSUMPTION]
#[1] [attachment2] is a picture which is required to embed in the body of the mail
#Quote: https://python-forum.io/thread-12718.html
att <- mail[['Attachments']]$Add(attachment2)
#Quote: https://learn.microsoft.com/en-us/office/client-developer/outlook/mapi/mapping-mapi-names-to-canonical-property-names
PR_ATTACH_MIME_TAG <- 'http://schemas.microsoft.com/mapi/proptag/0x370E001F'
#Quote: https://duoduokou.com/python/40842699176642623618.html
PR_ATTACH_CONTENT_ID <- 'http://schemas.microsoft.com/mapi/proptag/0x3712001F'
img_id <- 'MyId1'
att[['PropertyAccessor']]$SetProperty(PR_ATTACH_MIME_TAG, paste0('image/', att_ext))
att[['PropertyAccessor']]$SetProperty(PR_ATTACH_CONTENT_ID, img_id)

#[ASSUMPTION]
#[1] It is tested that the HTML body MUST ends with <\n>, otherwise fails
mailbody <- paste0(
	'<h1>Text body</h1><br/><br/>',mailBody,'<br/><br/>'
	,'<h1>Test body with image</h1><br/><br/><br/><br/> <img src="cid:',img_id,'" height=42 width=42>'
	,'\n'
)
mail[['HTMLBody']] <- mailbody

#900. Send mail for current group
mail$Send()
