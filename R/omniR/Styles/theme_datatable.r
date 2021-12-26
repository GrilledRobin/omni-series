#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to prepare CSS for DT::datatable in terms of various themes                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[QUOTE]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[CSS Selectors] http://www.divcss5.com/rumen/r50591.shtml                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |theme       :   The pre-defined themes                                                                                             #
#   |                 [BlackGold   ] <Default> Modified [MS PBI Innovation] theme with specific [black] and [gold] colors               #
#   |transparent :   Whether to set the entire background of the datatable as transparent                                               #
#   |                 [FALSE       ] <Default> Use the theme color                                                                      #
#   |                 [TRUE        ]           Set the alpha of background color as 0                                                   #
#   |fontFamily  :   Character vector of font family to be translated to CSS syntax                                                     #
#   |                 [<vector>    ] <Default> See function definition                                                                  #
#   |fontSize    :   Any vector that can be translated by [htmltools::validateCssUnit]                                                  #
#   |                 [14px        ] <Default> Common font size                                                                         #
#   |fs_header   :   Any vector that can be translated by [htmltools::validateCssUnit].                                                 #
#   |                 [IMPORTANT] Font size for table header will override [fontSize]                                                   #
#   |                 [14px        ] <Default> Common font size                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<shiny.tag> :   An object in the class of [shiny.tag] to be used in shinyApp                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211212        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211218        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a new function [themeColors] to standardize the theme selection                                               #
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
#   |   |shiny, htmltools                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |themeColors                                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, htmltools
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

theme_datatable <- function(
	theme = c('BlackGold', 'PBI', 'Inno', 'MSOffice')
	,transparent = FALSE
	,fontFamily = c('Microsoft YaHei','Helvetica','sans-serif','Arial','宋体')
	,fontSize = '14px'
	,fs_header = '14px'
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	fontSize <- htmltools::validateCssUnit(fontSize)
	fs_header <- htmltools::validateCssUnit(fs_header)

	#015. Function local variables
	fontFamily_css <- paste0(
		sapply(fontFamily, function(m){if (length(grep('\\W',m,perl = T))>0) paste0('\'',m,'\'') else m})
		,collapse = ','
	)

	#500. Retrieve the color set for the requested theme
	coltheme <- themeColors(theme, transparent)

	#600. Combine all attributes
	csstheme <- modifyList(coltheme
		,list(
			'font-family' = list(
				'default' = fontFamily_css
			)
			,'font-size' = list(
				'default' = fontSize
				,'header' = fs_header
			)
		)
	)

	#700. Function to paste the attribute names with their respective values
	h_attr <- function(attr, atype, important = FALSE) {
		imp <- ifelse(important, ' !important', '')
		paste0(paste0(attr, ': ', csstheme[[attr]][[atype]], imp, ';'), collapse = '')
	}

	#800. Prepare the CSS
	rstOut <- shiny::tags$style(
		type = 'text/css'
		,shiny::HTML(paste0(''
			#Selectors in CSS:
			#[Quote: http://www.divcss5.com/rumen/r50591.shtml ]
			,'.dataTables_wrapper {'
				,'background-color' %>% h_attr('default')
				,'font-family' %>% h_attr('default')
				,'font-size' %>% h_attr('default')
			,'}'
			#Below prevents the scroll-Y to show up when the table is too narrow.
			,'.dataTables_scrollBody {'
				,'height: auto !important;'
				,'max-height: none !important;'
			,'}'
			#Below stretches the header row as well when the fluid row is stretched
			,'.dataTables_scrollHeadInner {'
				,'width: 100% !important;'
			,'}'
			#Below ensure the entire table division has a full width in the widget
			,'.dataTable {'
				,'width: 100% !important;'
			,'}'
			,'table.dataTable thead th, table.dataTable thead td {'
				,'background-color' %>% h_attr('header')
				,'color' %>% h_attr('header')
				,'font-size' %>% h_attr('header')
				,'border-bottom' %>% h_attr('default')
			,'}'
			,'table.dataTable.row-border tbody th'
			,', table.dataTable.row-border tbody td'
			,', table.dataTable.display tbody th'
			,', table.dataTable.display tbody td {'
				,'border-top' %>% h_attr('default')
			,'}'
			,'.dataTables_wrapper .dataTables_scroll div.dataTables_scrollBody {'
				,'overflow: visible !important;'
				,'color' %>% h_attr('body')
			,'}'
			,'.dataTables_wrapper.no-footer .dataTables_scrollBody {'
				,'border-bottom' %>% h_attr('default')
			,'}'
			,'.datatables>button, input, optgroup, select, textarea {'
				,'background-color' %>% h_attr('accessory', important = T)
				,'color' %>% h_attr('accessory', important = T)
			,'}'
			,'.dataTables_wrapper .dataTables_length'
			,', .dataTables_wrapper .dataTables_filter'
			,', .dataTables_wrapper .dataTables_info'
			,', .dataTables_wrapper .dataTables_processing'
			,', .dataTables_wrapper .dataTables_paginate {'
				,'background-color' %>% h_attr('default', important = T)
				,'color' %>% h_attr('body')
				,'font-weight: 100;'
			,'}'
			,'.dataTables_wrapper .dataTables_length label'
			,', .dataTables_wrapper .dataTables_filter label {'
				,'font-weight: 100;'
			,'}'
			,'.dataTables_wrapper .dataTables_paginate .paginate_button.disabled'
			,', .dataTables_wrapper .dataTables_paginate .paginate_button.disabled:hover'
			,', .dataTables_wrapper .dataTables_paginate .paginate_button.disabled:active {'
				,'color' %>% h_attr('body', important = T)
			,'}'
			,'.dataTables_wrapper .dataTables_paginate .paginate_button {'
				,'background' %>% h_attr('btn-inact')
				,'border' %>% h_attr('btn-inact')
				,'color' %>% h_attr('btn-inact', important = T)
				,'font-weight: 100;'
				,'line-height: 1;'
			,'}'
			,'.dataTables_wrapper .dataTables_paginate .paginate_button:hover {'
				,'background' %>% h_attr('btn-inact-hover', important = T)
				,'border' %>% h_attr('btn-inact-hover')
				,'color' %>% h_attr('btn-inact-hover', important = T)
			,'}'
			,'.dataTables_wrapper .dataTables_paginate .paginate_button.current {'
				,'background' %>% h_attr('btn-act')
				,'border' %>% h_attr('btn-act')
				,'color' %>% h_attr('btn-act', important = T)
			,'}'
			,'.dataTables_wrapper .dataTables_paginate .paginate_button.current:hover {'
				,'background' %>% h_attr('btn-act-hover', important = T)
				,'border' %>% h_attr('btn-act-hover')
				,'color' %>% h_attr('btn-act-hover', important = T)
			,'}'
			,'table.dataTable.stripe tbody tr, table.dataTable.display tbody tr {'
				,'background-color' %>% h_attr('default')
			,'}'
			#[1] Here the color [#F9F9F9] is the default one as an odd row in a striped table of [DT::datatable]
			#[2] It is tested that: rgba2rgb( '#F7F7F7', alpha_in = 0.7, color_bg = grDevices::col2rgb('#FFFFFF') ) == '#F9F9F9'
			#[3] We have to set the color of the pseudo-class selector as [!important] to override the default effect
			,'.dataTable.stripe>tbody>tr:hover, .dataTable.display>tbody>tr:hover {'
				,'background-color' %>% h_attr('stripe', important = T)
			,'}'
			#Fill the rows with opacity
			,'table.dataTable.stripe tbody tr.odd, table.dataTable.display tbody tr.odd {'
				,'background-color' %>% h_attr('stripe-odd')
			,'}'
			#Below ensure the widget has a full width in its container
			,'[id^=htmlwidget-] {'
				,'width: 100% !important;'
				,'height: auto !important;'
			,'}'
			#Below class is defined to set the styles for the accessaries of the datatable
			#[Quote: https://datatables.net/examples/basic_init/dom.html ]
			,'.acc-dataTable {'
				,'line-height: 1;'
			,'}'
			#Set the styles when the filtered data.table has no record
			,'.dataTables_empty {'
				,'line-height: 1;'
			,'}'
		))
	)

	#999. Return the result
	return( rstOut )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare the palette for the color
		dt_styles <- theme_datatable()

	}
}
