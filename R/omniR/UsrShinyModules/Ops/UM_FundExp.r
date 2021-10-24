#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This module (Fund Explorer) is designed for below purposes:                                                                        #
#   |[1]Select a series of fund products from the provided Fund Price trend table                                                       #
#   |[2]Compare the historical customer cost to the fund NAV for the selected funds, given the customer currently holds their units     #
#   |[3]Compare the historical prices of the selected funds                                                                             #
#   |[4]Compare the historical P&L (Profit & Loss) of the selected funds                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 客户经理协助客户在基金货架中筛选需要进行调仓的组合                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CustData      :   The vector/list of various data regarding one specific customer, details are as below:                           #
#   |                   [CurrDate         ]    <Date>       The date value that represents the reporting date                           #
#   |                   [NumFmt_Currency  ]    <vector>     Vector of field names that will be displayed in the format: #,#00,00        #
#   |                   [NumFmt_Percent   ]    <vector>     Vector of field names that will be displayed in the format: #00,00%         #
#   |                   [NumFmt_Price     ]    <vector>     Vector of field names that will be displayed in the format: #00,0000        #
#   |                   [NumFmt_PnL       ]    <vector>     Vector of field names that will be displayed in opposite colors             #
#   |                   [Fund_Sel         ]    <data.frame> Historical data for customer cost, fund prices and predictions if any       #
#   |                   [FundLst_toDrawCH ]    <vector>     (can be NULL) Previously saved state of user selection upon the funds, to   #
#   |                                                        reload in this session; which enables user to switch language/font while   #
#   |                                                        keeping the selections from being rolled back.                             #
#   |f_loadstate   :   Flag of whether to load the previously saved state, useful for tracking of historical operations                 #
#   |                   [T]<Default> Try to load the state [FundLst_toDrawCH] from the input [CustData]                                 #
#   |                   [F]          Ignore the state in the input and start the module from scratch                                    #
#   |lang_cfg      :   Language configuration for Customer Portfolio Management                                                         #
#   |color_cfg     :   Color configuration for this module                                                                              #
#   |lang_disp     :   Language to extract all items from within [lang_cfg], currently support below 2 languages:                       #
#   |                   [CN]<Default>                                                                                                   #
#   |                   [EN]                                                                                                            #
#   |font_disp     :   Font of all characters in all paragraphs                                                                         #
#   |                   [Quote: http://blog.sina.com.cn/s/blog_54be98b80102xm1w.html ]                                                  #
#   |                   [Microsoft YaHei]<Default>                                                                                      #
#   |                   [Helvetica]                                                                                                     #
#   |                   [sans-serif]                                                                                                    #
#   |                   [Arial]                                                                                                         #
#   |                   [宋体]                                                                                                          #
#   |observer_pfx  :   The naming prefix of the [observer]s to be destroyed as garbage collection                                       #
#   |                   [1] Naming convention of observers is: [ session$userData[[paste(ns(observer_pfx),'name',sep='_')]] ]           #
#   |                   [2] Following above naming convention, ensure the [observer]s in the [module] are stored in [session$userData]  #
#   |                   [3] 'uObs' is the default value of the parameter, representing: User-defined Observer                           #
#   |fDebug        :   Switch for debug mode                                                                                            #
#   |                   [FALSE]<Default> normal mode                                                                                    #
#   |                   [TRUE] debug mode                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |800.   Naming Convention.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |FundExp       :   Fund Explorer                                                                                                    #
#   |uDiv          :   User defined HTML Tag as Division (similar names would be: [uRow], [uCol], etc.)                                 #
#   |uWg           :   User defined Widgets                                                                                             #
#   |uObs          :   User defined Observers                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CallCounter   :   The counter of completion of this module. Only meaningful when this module is called once                        #
#   |                   [0] starting value                                                                                              #
#   |ActionDone    :   Flag of whether the necessary action within the module is successfully taken                                     #
#   |                   [FALSE]<Default> turn to [TRUE] once the crucial action is observed to have been taken                          #
#   |EnvVariables  :   List of variables created within the module environment with their last values                                   #
#   |                   Value of any internal variable can be retrieved via the form: [EnvVariables()$varname], where [varname] is      #
#   |                    usually defined as [uRV$varname] inside the module program.                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200406        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200419        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add a parameter [color_cfg] to unify the color settings for all related modules                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200509        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [observer_pfx] to name the observers                                                                    #
#   |      |[2] Store all necessary observers into [session$userData] for garbage collection                                            #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Packages                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |shiny, htmltools, dplyr, grDevices, V8, shinydashboardPlus, DT                                                                 #
#   |   |(inherited from [UM_FundCompare])       lubridate, htmlwidgets, tidyselect, shinydashboard, echarts4r                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Directory: [omniR$AdvOp]                                                                                                       #
#   |   |   |gc_shiny_module                                                                                                            #
#   |   |   |   |rem_shiny_inputs      [Dependency of above function]                                                                   #
#   |   |Directory: [omniR$Styles]                                                                                                      #
#   |   |   |rgba2rgb                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Dependent user-defined Modules                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Directory: [omniR$UsrShinyModules$Ops]                                                                                         #
#   |   |   |UM_FundCompare                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, htmltools, dplyr, grDevices, V8, shinydashboardPlus, DT
	, lubridate, htmlwidgets, tidyselect, shinydashboard, echarts4r
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

UM_FundExp_ui <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_FundExp'))
}

#Below UIs are inherited from the dependent modules, so that all the adjustments between blocks can be done in higher-order modules.
UM_FundExp_ui_CostPnL <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_CostPnL'))
}

UM_FundExp_ui_FundPrice <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_FundPrice'))
}

UM_FundExp_ui_FundPnL <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_FundPnL'))
}

UM_FundExp_svr <- function(input,output,session
	,CustData = NULL,f_loadstate = T
	,lang_cfg = NULL,color_cfg = NULL
	,lang_disp = 'CN',font_disp = 'Microsoft YaHei'
	,observer_pfx = 'uObs'
	,fDebug = FALSE){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	if (!is.logical(f_loadstate)) stop(ns(paste0('[001]Crucial parameter [f_loadstate] is not logical!')))
	lang_disp <- match.arg(lang_disp,c('CN','EN'))
	#We must ensure the prefix of the observers exist, otherwise all the similar observers will be destroyed!
	if (length(observer_pfx) == 0) observer_pfx <- 'uObs'
	uRV$font_list <- c('Microsoft YaHei','Helvetica','sans-serif','Arial','宋体')
	uRV$font_list_css <- paste0(
		sapply(uRV$font_list, function(m){if (length(grep('\\W',m,perl = T))>0) paste0('"',m,'"') else m})
		,collapse = ','
	)
	font_disp <- match.arg(font_disp,uRV$font_list)
	#Below is to define the additional KPIs to be used for fund comparison
	var_DrawCH <- c(
		'Last7Day_PnL_pa' = 'percent'
		,'PnLPredict_3m_pa' = 'percent'
		,'PnLPredict_6m_pa' = 'percent'
		,'PnLPredict_12m_pa' = 'percent'
	)
	#Below is the list of important stages to trigger the increment of initial progress bar
	uRV$pb_k <- list(
		#[1] Loading data
		load = 0
		#[2] Drawing charts
		,chart = 1
	)
	uRV$pb_k_all <- length(uRV$pb_k)
	uRV$pb_cnt_chart <- 0
	#We observe the status of the progress bar every 1sec, and destroy it after is it reaches the end
	uRV$k_ms_invld <- 1000
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- shiny::reactiveVal(0)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[Module Call][UM_FundExp]')))
	}

	#005. Check parameters
	#We do not return values to break the chain of the subsequent processes.
	if (is.null(CustData)) stop(ns(paste0('[005]Crucial input data [CustData] is not provided!')))
	if (length(CustData) == 0) stop(ns(paste0('[005]Crucial input data [CustData] has no content!')))

	#200. General settings of styles for the output UI
	setNumColor <- function(n){ifelse(n>-0.0000001,color_cfg$Positive,color_cfg$Negative)}

	#212. Font Size of chart items
	uRV$styles_ch_FontSize_title <- 14
	uRV$styles_ch_FontSize_item <- 10

	#240. Prepare the color series to differentiate the bars in the chart by [ProdType]

	#260. Determine the styles of specific columns in [DT::datatable]
	#261. Whether to display the row names
	dt_rownames <- FALSE

	#263. How to shift the column identifier in [columnDefs -> target]
	dt_colshift <- ifelse(dt_rownames,0,-1)

	#265. Determine the styles of the datatables inside the [tabBox]
	uRV$uTB_width <- 12
	uRV$styles_tabBox_font <- paste0(''
		,'font-family: ',font_disp,';'
		,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
	)

	#267. Determine which types of formats to be applied to which columns
	#This part is moved to the global options.
	#Check the definition of the series of variables from the input: [CustData$NumFmt_:]

	#270. Format the [DT::datatable] to ensure the table is fully stretch-able
	uRV$dt_styles_FundPrice <- shiny::HTML(
		paste0(''
			#Selectors in CSS:
			#[Quote: http://www.divcss5.com/rumen/r50591.shtml ]
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
			#Below class is defined to set the styles for the accessaries of the datatable
			#[Quote: https://datatables.net/examples/basic_init/dom.html ]
			,'.acc-dataTable {'
				,'line-height: 1;'
				,uRV$styles_tabBox_font
			,'}'
			#Set the styles when the filtered data.table has no record
			,'.dataTables_empty {'
				,'line-height: 1;'
				,uRV$styles_tabBox_font
			,'}'
			#Below ensure the widget has a full width in its container
			,'[id^=htmlwidget-] {'
				,'width: 100% !important;'
				,'height: auto !important;'
			,'}'
		)
	)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(''
			#Set the paddings of the [tabBox]
			# '[class^=col-][class$=',uRV$uTB_width,'] {'
			,'.col-sm-',uRV$uTB_width,' {'
				,'padding: 0px;'
			,'}'
			#Add styles to the navigation buttons
			,'.uAB-nav-xs {'
				,'text-align: center;'
				,'padding: 0px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'background-color: rgba(0,0,0,0);'
				,uRV$styles_tabBox_font
			,'}'
			#Add hover effect to the navigation buttons
			,'.uAB-nav-xs.hover, .uAB-nav-xs:focus, .uAB-nav-xs:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			#Add styles to the action buttons
			,'.uAB-theme-xs {'
				,'text-align: center;'
				,'padding: 0px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$CustAct,';'
				,uRV$styles_tabBox_font
			,'}'
			#Add hover effect to the action buttons
			,'.uAB-theme-xs.hover, .uAB-theme-xs:focus, .uAB-theme-xs:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			,'.box-title {'
				,'font-family: ',font_disp,';'
				,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_title),' !important;'
			,'}'
			,'.fe_fluidRow {'
				,'padding: 2px 0px;'
			,'}'
			,'.fe_Column {'
				,'padding: 0px;'
				,'margin: 0px;'
			,'}'
		)
	)

	#400. Prepare the HTML elements
	#410. Fund selector
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Reshape the input data][IN][CustData$Fund_Sel]')))
	}

	#411. Prepare a function to translate the HTML tags into character string, in order to place them inside datatable
	btn_Funds <- function(FUN, len, id, ...) {
		inputs <- character(len)
		for (i in seq_len(len)) {
			inputs[i] <- as.character(FUN(paste0(id, i), ...))
		}
		inputs
	}

	#413. Only select the data as of current reporting date
	dtsrc_Funds <- CustData$Fund_Sel %>%
		dplyr::filter(d_data == CustData$CurrDate) %>%
		dplyr::mutate(
			K_Row = dplyr::row_number()
			,F_Selected = ifelse(FC_Holding == 'Yes',T,F)
		)
	#In case the input data has a state of fund selection, we reload the state.
	if (isTRUE(f_loadstate))
		if (!is.null(CustData$FundLst_toDrawCH))
			dtsrc_Funds <- dtsrc_Funds %>%
				dplyr::mutate( F_Selected = ifelse( ProdCode %in% CustData$FundLst_toDrawCH , T , F ) )
	nrow_dtsrc_Funds <- nrow(dtsrc_Funds)

	#415. Define the table to display
	colsDT_FundSel <- names(lang_cfg[[lang_disp]][['tblvars']][['Fund_Explorer']])
	names(colsDT_FundSel) <- lang_cfg[[lang_disp]][['tblvars']][['Fund_Explorer']]

	#417. Add the buttons inside the datatable by the function defined at above steps
	#[Quote: https://stackoverflow.com/questions/45739303/r-shiny-handle-action-buttons-in-data-table ]
	dtsrc_Funds$btn_FundSel <- btn_Funds(
		shiny::actionButton
		,nrow_dtsrc_Funds
		#[shiny] does not recognize the series of button IDs as they are created by [ESCAPE] in datatable.
		,'pseudoSel_'
		,class = 'uAB-nav-xs'
		,icon = shiny::icon('square-o')
		,NULL
		,onclick = paste0('Shiny.onInputChange("',ns('uWg_AB_FundExp_Sel'),'", this.id + "_" + (new Date()).getTime())')
	)

	#419. Transform the icons of the buttons in terms of whether the product is already selected
	dtsrc_Funds <- dtsrc_Funds %>%
		dplyr::mutate(
			btn_FundSel = ifelse(
				F_Selected
				,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_FundSel)
				,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_FundSel)
			)
		)
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Reshape the input data][OUT][dtsrc_Funds]')))
	}

	#420. Draw the datatable
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[420][Draw the datatable][IN][dtsrc_Funds]')))
	}
	#421. Prepare the necessary fields to draw a datatable for fund selection
	uRV$dt_draw <- dtsrc_Funds[,c(colsDT_FundSel,'K_Row','F_Selected','ProdCode','FC_Holding')]
	uRV$dtnames <- colnames(uRV$dt_draw)
	uRV$FundLst_toDrawCH <- uRV$dt_draw %>%
		dplyr::filter(F_Selected == T) %>%
		dplyr::select(ProdCode) %>%
		unique() %>%
		unlist() %>%
		sort()

	#425. Draw the datatable
	#[Quote: https://rstudio.github.io/DT/options.html ]
	#[Quote: https://rstudio.github.io/DT/010-style.html ]
	uRV$dt_Funds_pre <- DT::datatable(
		uRV$dt_draw
		,caption = htmltools::tags$caption(
			style = paste0(
				'padding-right: 0px;'
				,'caption-side: top;'
				,'text-align: right;'
				,uRV$styles_tabBox_font
			)
			,shiny::tags$span(shiny::tagList(
				shiny::tags$span(
					style = paste0('padding-top: 2px;')
					,paste0(lang_cfg[[lang_disp]][['dtnav']][['Fund_Explorer']][['Navigator']], ': ')
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Holding')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('check-square')
						,lang_cfg[[lang_disp]][['dtnav']][['Fund_Explorer']][['Filter_Holding']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Holding'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Selected')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('check-square-o')
						,lang_cfg[[lang_disp]][['dtnav']][['Fund_Explorer']][['Filter_Selected']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Selected'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Excluded')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('square-o')
						,lang_cfg[[lang_disp]][['dtnav']][['Fund_Explorer']][['Filter_Excluded']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Excluded'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Clear')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('minus-square-o')
						,lang_cfg[[lang_disp]][['dtnav']][['Fund_Explorer']][['Clear_Selected']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Clear'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('uWg_AB_ConfirmSel')
						,class = 'uAB-theme-xs'
						,icon = shiny::icon('toggle-right')
						,lang_cfg[[lang_disp]][['dtnav']][['Fund_Explorer']][['Confirm_Selection']]
						,onclick = paste0('Shiny.onInputChange("',ns('uWg_AB_ConfirmSel'),'", (new Date()).getTime())')
					)
				)
			))
		)
		,rownames = dt_rownames
		#Only determine the columns to be displayed, rather than the columns to extract from the input data
		,colnames = colsDT_FundSel
		,width = '100%'
		,class = 'compact display'
		# ,style = 'bootstrap'
		,fillContainer = TRUE
		,escape = FALSE
		#No need to attach the extensions as we do not render the datatable inside the UI
		# ,extensions = c('KeyTable','Responsive')
		,selection = list(
			mode = 'single'
			,target = 'row'
		)
		,options = list(
			serverSide = TRUE
			,processing = TRUE
			#Setup the styles for the table header
			,initComplete = V8::JS(paste0(
				"function(settings, json){"
					,"$(this.api().table().header()).css({"
						,"'background-color': '",color_cfg$DTHeaderBg,"'"
						,",'color': '",color_cfg$DTHeaderTxt,"'"
						,",'font-family': '",font_disp,"'"
						,",'font-size': '",shiny::validateCssUnit(uRV$styles_ch_FontSize_item),"'"
					,"});"
				,"}"
			))
			,stateSave = FALSE
			# ,autoWidth = TRUE
			,scrollX = TRUE
			#Below option shinks the datatable when the page has too few records to display
			#Seems ineffective!
			,scrollCollapse = TRUE
			#[Show N entries] on top left
			,pageLength = 10
			,lengthMenu = c(5, 10, 15, 20)
			,pagingType = 'full_numbers'
			# ,pageLength = nrow_dtsrc_Funds
			#[Quote: https://datatables.net/reference/option/language.searchPlaceholder ]
			,language = append(
				lang_cfg[[lang_disp]][['dtstyle']][['language']]
				,list(searchPlaceholder = lang_cfg[[lang_disp]][['dtstyle']][['Fund_Explorer']][['searchPlaceholder']])
			)
			# ,language = list(
			# 	#Leave nothing to the left of the search box
			# 	search = '_INPUT_'
			# )
			,dom = '<"acc-dataTable"lftp>'
			,orderMulti = TRUE
			,columnDefs = list(
				list(
					targets = which(colnames(uRV$dt_draw) %in% c('K_Row','F_Selected','ProdCode','FC_Holding')) + dt_colshift
					,visible = FALSE
				)
				#Prevent the column with buttons to be orderable as the result is not as desired
				,list(
					targets = which(colnames(uRV$dt_draw) %in% c('AvgCost','Price','btn_FundSel')) + dt_colshift
					,orderable = FALSE
				)
				#Set the icon at the center of the column
				,list(
					targets = which(colnames(uRV$dt_draw) %in% c('btn_FundSel')) + dt_colshift
					,className = 'dt-center'
				)
			)
		#End of [options]
		)
	#End of [datatable]
	) %>%
		#Set the numbers to be displayed as: [#,###.00]
		DT::formatCurrency(
			which(colsDT_FundSel %in% CustData$NumFmt_Currency)
			,currency = ''
		) %>%
		#Set the price to be displayed as: [#,###.0000]
		DT::formatCurrency(
			which(colsDT_FundSel %in% CustData$NumFmt_Price)
			,currency = ''
			,digits = 4
		) %>%
		#Set the percentage to be displayed as: [#,###.00%]
		DT::formatPercentage(
			which(colsDT_FundSel %in% CustData$NumFmt_Percent)
			,digits = 2
		) %>%
		#Set the font color for positive numbers as [green], while that for negative ones as [red]
		DT::formatStyle(
			which(colsDT_FundSel %in% CustData$NumFmt_PnL)
			,color = DT::styleInterval(
				-0.0000001
				,c(color_cfg$Negative,color_cfg$Positive)
			)
		) %>%
		#Set the font for all content in the table
		DT::formatStyle(
			seq_along(colsDT_FundSel)
			,fontFamily = font_disp
			,fontSize = shiny::validateCssUnit(uRV$styles_ch_FontSize_item)
		)
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[420][Draw the datatable][OUT][uRV$dt_Funds_pre]')))
	}

	#500. Update objects reactively
	#510. Save the selection result when user confirms in the Fund Selector
	session$userData[[paste(ns(observer_pfx),'conf_sel',sep='_')]] <- shiny::observe(
		{
			input$uWg_AB_ConfirmSel

			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[510][observe][IN][input$uWg_AB_ConfirmSel]:',input$uWg_AB_ConfirmSel)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfirmSel)) return()

				#100. Export the result for all languages
				uRV$FundLst_toDrawCH <- uRV$dt_draw %>%
					dplyr::filter(F_Selected == T) %>%
					dplyr::select(ProdCode) %>%
					unique() %>%
					unlist() %>%
					sort()

				#900. Mark the completion of operations in this module
				uRV_finish(uRV_finish() + 1)
				uRV$ActionDone <- TRUE
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[510][observe][OUT][uRV$FundLst_toDrawCH]:<',paste0(uRV$FundLst_toDrawCH,collapse = '>,<'),'>')))
				}
			})
		#End of [observeEvent] at [510]
		}
		,label = ns(paste0('[510]Determine the user selection result'))
	)

	#520. Draw the charts once the fund list is confirmed by user
	session$userData[[paste(ns(observer_pfx),'conf_fundlist',sep='_')]] <- shiny::observe(
		{
			uRV$FundLst_toDrawCH

			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[520][observe][IN][uRV$FundLst_toDrawCH]:<',paste0(uRV$FundLst_toDrawCH,collapse = '>,<'),'>')))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$FundLst_toDrawCH)) return()

				#100. Export the selection result when user confirms in the Fund Selector

				#200. Retrieve necessary data for charting
				FundLst_drawCH <- CustData$Fund_Sel %>% dplyr::filter(ProdCode %in% uRV$FundLst_toDrawCH)

				#300. Garbage collection of the previous call
				#See [Dependency]
				gc_shiny_module(
					'mFC'
					,input
					,session
					,UI_Selectors = NULL
					,UI_namespaced = T
					,observer_pfx = observer_pfx
				)

				#500. Call the separate module to draw the necessary charts
				#See [Dependency]
				uRV$uMod_FC <- shiny::callModule(
					UM_FundCompare_svr
					,'mFC'
					,FundForComp = FundLst_drawCH
					,ObsDate = CustData$CurrDate
					,VarComp = var_DrawCH
					,lang_cfg = lang_cfg
					,color_cfg = color_cfg
					,lang_disp = lang_disp
					,font_disp = font_disp
					,observer_pfx = observer_pfx
					,fDebug = fDebug
				)

				#600. Export the parameters for printable version once the above module is called
				uRV$knitr_params <- uRV$uMod_FC$EnvVariables()$knitr_params

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[520][observe][OUT][uRV$knitr_params]:',length(uRV$knitr_params))))
				}
			})
		#End of [observe] at [520]
		}
		,label = ns(paste0('[520]Draw the charts once the fund list is confirmed by user'))
	)

	#595. Increment the progress when necessary
	#[Quote: https://stackoverflow.com/questions/44367004/r-shiny-destroy-observeevent ]
	#We suspend the observer once the progress bar is closed
	session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]] <- shiny::observeEvent(
		uRV$pb_cnt_chart
		,{
			if (is.null(uRV$pb_chart)) return()
			#Close the progress bar as long as its value reaches 100%
			# shiny::invalidateLater(uRV$k_ms_invld,session)
			if (!is.environment(uRV$pb_chart$.__enclos_env__$private)) return()
			if (uRV$pb_cnt_chart >= uRV$pb_k$chart){
				if (!uRV$pb_chart$.__enclos_env__$private$closed) try(uRV$pb_chart$close(), silent = T)
				uRV$pb_cnt_chart <- 0
				session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]]$suspend()
			}
		}
		# ,suspended = T
	)

	#600. User actions
	#610. Once user clicks upon any among the buttons within the Fund Selector
	session$userData[[paste(ns(observer_pfx),'fund_sel',sep='_')]] <- shiny::observeEvent(
		input$uWg_AB_FundExp_Sel
		,{
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[610][observeEvent][IN][input$uWg_AB_FundExp_Sel]:<',input$uWg_AB_FundExp_Sel,'>')))
				}
				#100. Extract the button ID, although it is useless in action monitoring
				btnID <- gsub('^(.+)_\\d+$','\\1',input$uWg_AB_FundExp_Sel,perl = TRUE)

				#200. Identify the clicked row by extracting the number part from the button ID
				selectedRow <- as.numeric(gsub('^.+_(\\d+)$','\\1',btnID,perl = TRUE))
				# uRV$Prod_Selected <- paste('click on ',dtsrc_Funds[selectedRow,colsDT_FundSel[[1]]])

				#500. Overwrite the data used to draw the datatable
				uRV$dt_draw[selectedRow,'F_Selected'] <- !uRV$dt_draw[selectedRow,'F_Selected']
				uRV$dt_draw <- uRV$dt_draw %>%
					dplyr::mutate(
						btn_FundSel = ifelse(
							F_Selected
							,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_FundSel)
							,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_FundSel)
						)
					)
				#[Quote: https://github.com/rstudio/DT/pull/480 ]

				#900. Refresh the datatable at frontend, to improve the user experience
				#[Quote: https://community.rstudio.com/t/edit-data-table-in-r-shiny-and-save-the-data-table-to-the-original-dataframe/25355/2 ]
				#[Quote: https://github.com/hinkelman/Shiny-Scorekeeper/blob/master/server.R ] Row #65
				DT::replaceData(
					uRV$proxy_dt_Funds
					,uRV$dt_draw
					,resetPaging = FALSE
					#IMPORTANT! Below option is CRUCIAL!
					,rownames = dt_rownames
				)
				#Debug Mode
				if (fDebug){
					fundchk <- uRV$dt_draw %>%
						dplyr::filter(F_Selected) %>%
						dplyr::select_at(paste0('ProdName_',lang_disp)) %>%
						unlist()
					message(ns(paste0('[610][observeEvent][OUT][uRV$dt_draw]:<',paste0(fundchk,collapse = '>,<'),'>')))
				}
			})
		#End of [observeEvent] at [610]
		}
		,label = ns(paste0('[610]Refresh the datatable once user clicks any button within it'))
	)

	#620. Handle navigation once the user clicks any among the navigation buttons
	#Since we do not activate the [filter] (by columns) function for the DT, we can neither search by columns
	#We add two white spaces before and after the keyword to avoid mis-searching
	#20200418 Robin Lu Bin: Tested that the white spaces surrounding the keywords are USELESS!
	session$userData[[paste(ns(observer_pfx),'nav_holding',sep='_')]] <- shiny::observeEvent(
		input$FilterAB_Holding
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[621][observeEvent][IN][input$FilterAB_Holding]:<',input$FilterAB_Holding,'>')))
			}
			DT::updateSearch(uRV$proxy_dt_Funds, keywords = list(global = '  Yes  '))
		#End of [observeEvent] at [621]
		}
		,label = ns(paste0('[621]Only display the products with customer holding at present'))
	)
	session$userData[[paste(ns(observer_pfx),'nav_selected',sep='_')]] <- shiny::observeEvent(
		input$FilterAB_Selected
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[623][observeEvent][IN][input$FilterAB_Selected]:<',input$FilterAB_Selected,'>')))
			}
			DT::updateSearch(uRV$proxy_dt_Funds, keywords = list(global = '  TRUE  '))
		#End of [observeEvent] at [623]
		}
		,label = ns(paste0('[623]Only display the products selected by the user for comparison'))
	)
	session$userData[[paste(ns(observer_pfx),'nav_excluded',sep='_')]] <- shiny::observeEvent(
		input$FilterAB_Excluded
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[625][observeEvent][IN][input$FilterAB_Excluded]:<',input$FilterAB_Excluded,'>')))
			}
			DT::updateSearch(uRV$proxy_dt_Funds, keywords = list(global = '  FALSE  '))
		#End of [observeEvent] at [625]
		}
		,label = ns(paste0('[625]Only display the products that are NOT selected by the user'))
	)
	session$userData[[paste(ns(observer_pfx),'nav_clear',sep='_')]] <- shiny::observeEvent(
		input$FilterAB_Clear
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[627][observeEvent][IN][input$FilterAB_Clear]:<',input$FilterAB_Clear,'>')))
			}
			DT::clearSearch(uRV$proxy_dt_Funds)

			#500. Overwrite the data used to draw the datatable
			uRV$dt_draw[['F_Selected']] <- FALSE
			uRV$dt_draw <- uRV$dt_draw %>%
				dplyr::mutate(
					btn_FundSel = ifelse(
						F_Selected
						,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_FundSel)
						,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_FundSel)
					)
				)

			#900. Refresh the datatable at frontend, to improve the user experience
			DT::replaceData(
				uRV$proxy_dt_Funds
				,uRV$dt_draw
				,resetPaging = FALSE
				#IMPORTANT! Below option is CRUCIAL!
				,rownames = dt_rownames
			)
		#End of [observeEvent] at [627]
		}
		,label = ns(paste0('[627]Clear all selections made by the user'))
	)

	#700. Create UI
	#701. Setup the placeholder if there is no further UI to be created
	tags_placeholder <- shiny::tagList(
		#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
		shiny::tags$style(
			type = 'text/css'
			,uRV$styles_tabBox_font
		)

		,shinydashboardPlus::boxPlus(
			width = 12
			,collapsible = TRUE
			,id = ns('uBox_fe')
			,title = lang_cfg[[lang_disp]][['tabboxnames']][['FC_Placeholder']]
			,solidHeader = FALSE
			,closable = FALSE
			,enable_dropdown = FALSE

			,style = paste0(''
				,'text-align: center;'
				,uRV$styles_tabBox_font
			)
			,shiny::tags$span(
				shiny::icon('exclamation-triangle')
				,paste0(' ', lang_cfg[[lang_disp]][['tabnames']][['FC_Placeholder']])
			)
		#End of [box]
		)
	)

	#710. Create the Fund Selector
	output$dt_Funds <- DT::renderDT({
		#Take dependency from below action (without using its value):

		#008. Create a progress bar to notify the user when a large dataset is being loaded for chart drawing
		uRV$pb_chart <- shiny::Progress$new(session, min = 0, max = uRV$pb_k$chart)

		#Start to display the progress bar
		uRV$pb_chart$set(message = paste0('Fund Explorer [2/',uRV$pb_k_all,']'), value = 0)
		session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]]$resume()

		#Increment the progress bar
		#[Quote: https://nathaneastwood.github.io/2017/08/13/accessing-private-methods-from-an-r6-class/ ]
		#[Quote: https://github.com/rstudio/shiny/blob/master/R/progress.R ]
		if (is.environment(uRV$pb_chart$.__enclos_env__$private)) if (!uRV$pb_chart$.__enclos_env__$private$closed){
			val <- uRV$pb_chart$getValue()+1
			uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Fund Selector'))
			uRV$pb_cnt_chart <- shiny::isolate(uRV$pb_cnt_chart) + 1
		}
		# on.exit(try(uRV$pb_chart$close(), silent = T))

		#Render UI
		uRV$dt_Funds_pre
	})
	#There is no need to add [ns] to the proxy, for it will be added inside [DT]
	uRV$proxy_dt_Funds <- DT::dataTableProxy('dt_Funds')

	output$FundSelector <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[710][renderUI][IN][output$FundSelector]')))
		}

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$dt_styles_FundPrice
			)
			#Quote: Xie Yihui published this solution on the topic: [Icons in a datatable (DT)] in forum [Google Groups]
			#[shiny::icon()] uses the font-awesome library by default, and shiny does not really know the dependency
			# on font-awesome unless at least one icon has been rendered in the shiny UI.
			#In this case, the [as.character()] function masks the function [shiny::icon()], so shiny has no idea the
			# app depends on font-awesome (the dependency info is lost through [as.character()])
			#The other solution is to use glyphicon library as walk-around.
			,shiny::tags$span(shiny::icon('archive'), style = 'display: none;')
			,DT::DTOutput(ns('dt_Funds'))
		)
	})

	#750. Charts
	output$uDiv_CostPnL <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[751][renderUI][IN][output$uDiv_CostPnL]')))
		}
		#Take dependency from below action (without using its value):
		uRV$FundLst_toDrawCH

		#Skip if there is no fund selected for comparison
		if (is.null(uRV$FundLst_toDrawCH)) return(tags_placeholder)
		if (length(uRV$FundLst_toDrawCH) == 0) return(tags_placeholder)

		UM_FundCmp_ui_CostPnL(ns('mFC'))
	})
	output$uDiv_FundPrice <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[753][renderUI][IN][output$uDiv_FundPrice]')))
		}
		#Take dependency from below action (without using its value):
		uRV$FundLst_toDrawCH

		#Skip if there is no fund selected for comparison
		if (is.null(uRV$FundLst_toDrawCH)) return(NULL)
		if (length(uRV$FundLst_toDrawCH) == 0) return(NULL)

		UM_FundCmp_ui_FundPrice(ns('mFC'))
	})
	output$uDiv_FundPnL <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[755][renderUI][IN][output$uDiv_FundPnL]')))
		}
		#Take dependency from below action (without using its value):
		uRV$FundLst_toDrawCH

		#Skip if there is no fund selected for comparison
		if (is.null(uRV$FundLst_toDrawCH)) return(NULL)
		if (length(uRV$FundLst_toDrawCH) == 0) return(NULL)

		UM_FundCmp_ui_FundPnL(ns('mFC'))
	})

	#790. Final UI
	#797. Combine all charts
	output$uDiv_FundExp <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[797][renderUI][IN][output$uDiv_FundExp]')))
		}

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shiny::fluidRow(class = 'fe_fluidRow', shiny::uiOutput(ns('FundSelector')))
		)
	#End of [renderUI] of [797]
	})

	#999. Return the result
	#Next time I may try to append values as instructed below:
	#[Quote: https://community.rstudio.com/t/append-multiple-reactive-output-of-a-shiny-module-to-an-existing-reactivevalue-object-in-the-app/36985/2 ]
	return(
		list(
			CallCounter = shiny::reactive({uRV_finish()})
			,ActionDone = shiny::reactive({uRV$ActionDone()})
			,EnvVariables = shiny::reactive({uRV})
		)
	)
}

#[Full Test Program;]
if (FALSE){
	if (interactive()){
		lst_pkg <- c( 'tmcn'
			, 'shiny', 'htmltools', 'dplyr', 'grDevices', 'V8', 'shinydashboardPlus', 'DT'
			, 'lubridate', 'htmlwidgets', 'tidyselect', 'shinydashboard', 'echarts4r'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		omniR <- 'D:\\R\\omniR'
		source(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_FundCompare.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'Styles','rgba2rgb.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','rem_shiny_inputs.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','gc_shiny_module.r')),encoding = 'utf-8')

		#Load necessary data
		myProj <- 'D:\\R\\Project'
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','theme_color_sets.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Data','Test_PortMgmt_LoadData.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','lang_PortMgmt.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','color_PortMgmt.r')), encoding = 'utf-8')

		ui <- shinydashboardPlus::dashboardPagePlus(
			header = shinydashboardPlus::dashboardHeaderPlus()
			,sidebar = shinydashboard::dashboardSidebar(
				shinydashboard::sidebarMenu(id = 'left_sidebar'
					#[Icons are from the official page: https://adminlte.io/themes/AdminLTE/pages/UI/icons.html ]
					,shinydashboard::menuItem(
						'Portfolio Management'
						,tabName = 'uMI_PortMgmt'
						,icon = shiny::icon('bar-chart')
					)
					,shinydashboard::menuItem(
						'Print Report'
						,tabName = 'uMI_PrintRpt'
						,icon = shiny::icon('bar-chart')
					)
				)
			)
			,body = shinydashboard::dashboardBody(
				shinyjs::useShinyjs()
				,shiny::fluidPage(
					#Add identical number of [tabItems] corresponding to the [tabName]s identified in [sidebar]
					shinydashboard::tabItems(
						#Add one [tabItem]
						shinydashboard::tabItem(tabName = 'uMI_PortMgmt'
							,shiny::column(width = 3
							,shinyWidgets::prettyToggle(inputId = 'toggle'
								,label_on = 'CN'
								,status_on = 'default'
								,icon_on = icon('ok-circle', lib = 'glyphicon')
								,label_off = 'EN'
								,status_off = 'default'
								,icon_off = icon('remove-circle', lib = 'glyphicon')
								,plain = TRUE
								,inline = TRUE
							)
							)
							,shiny::column(width = 9
								,shiny::fluidRow(shiny::uiOutput('modUI0'))
								,shiny::fluidRow(shiny::uiOutput('modUI1'))
								,shiny::fluidRow(shiny::uiOutput('modUI2'))
								,shiny::fluidRow(shiny::uiOutput('modUI3'))

							)
						#End of [tabItem]
						)
						#Add one [tabItem]
						,shinydashboard::tabItem(tabName = 'uMI_PrintRpt'
							,shiny::column(width = 9
								,shiny::fluidRow(shiny::downloadButton('Save','Download Report'))
							)
						#End of [tabItem]
						)
					#End of [tabItems]
					)
				)
			)
			,rightsidebar = shinydashboardPlus::rightSidebar()
			,title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$mFE <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0)
				,ActionDone = shiny::reactive({FALSE})
				,EnvVariables = shiny::reactive({NULL})
			)

			output$modUI0 <- shiny::renderUI({UM_FundExp_ui(modout$ID_Mod)})
			output$modUI1 <- shiny::renderUI({UM_FundExp_ui_CostPnL(modout$ID_Mod)})
			output$modUI2 <- shiny::renderUI({UM_FundExp_ui_FundPrice(modout$ID_Mod)})
			output$modUI3 <- shiny::renderUI({UM_FundExp_ui_FundPnL(modout$ID_Mod)})

			shiny::observe(
				{
					#100. Take dependencies
					input$toggle

					#900. Execute below block of codes only once upon the change of any one of above dependencies
					shiny::isolate({
						if (is.null(input$toggle)) return()

						if (input$toggle) lang_disp <- 'CN'
						else lang_disp <- 'EN'

						#IMPORTANT!!! We always have to create a new ID for the module!
						#The internal observers from the previous call of this module cannot be overlooked by [shiny] mechanism!
						# modout$ID_Mod <- paste0('FE','_',floor(runif(1) * 10^6))
						modout$ID_Mod <- paste0('FE','_',1)

						#Garbage collection of the previous call
						#[Quote: [omniR$AdvOp$gc_shiny_module]]
						gc_shiny_module(
							modout$ID_Mod
							,input
							,session
							,UI_Selectors = NULL
							,UI_namespaced = T
							,observer_pfx = 'uObs'
						)

						modout$mFE <- shiny::callModule(
							UM_FundExp_svr
							,modout$ID_Mod
							,CustData = uRV$PM_rpt
							,f_loadstate = T
							,lang_cfg = lang_CPM
							,color_cfg = color_CPM
							,lang_disp = lang_disp
							,font_disp = 'Microsoft YaHei'
							,observer_pfx = 'uObs'
							,fDebug = FALSE
						)

						modout$params <- modout$mFE$EnvVariables()$knitr_params
					#End of [isolate]
					})
				}
				,label = '[500]Monitor the status of the module call'
			)
			shiny::observeEvent(modout$params,{
				if (is.null(modout$params)) return()
				params_global <<- modout$params
				#[Quote: https://shiny.rstudio.com/articles/generating-reports.html ]
				output$Save <- shiny::downloadHandler(
					filename = 'PortMgmt.html'
					,content = function(file){
						tempReport <- file.path(tempdir(),'JointPlots.Rmd')
						file.copy(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortMgmt.Rmd')), tempReport, overwrite = TRUE)
						rmarkdown::render(
							tempReport
							,output_file = file
							,params = modout$params
							,envir = new.env(parent = globalenv())
						)
					}
				)
			})
			shiny::observeEvent(modout$mFE$CallCounter(),{
				if (modout$mFE$CallCounter() == 0) return()
				message('[mFE$CallCounter()]:',modout$mFE$CallCounter())
			})
		}

		shinyApp(ui, server)
	}

}

#[Test Rmarkdown]
if (FALSE){
	reportTpl <- normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortMgmt.Rmd'))
	rpt_html <- normalizePath(file.path(omniR,'UsrShinyModules','Ops','PortMgmt.html'))
	rpt_pdf <- normalizePath(file.path(omniR,'UsrShinyModules','Ops','PortMgmt.pdf'))
	tempReport <- file.path(tempdir(),'custPortMgmt.Rmd')
	file.copy(reportTpl, tempReport, overwrite = TRUE)
	rmarkdown::render(
		tempReport
		,output_file = rpt_html
		,params = params_global
		,envir = new.env(parent = globalenv())
	)

}

#[Partial Test Program;]
if (FALSE){
	source(normalizePath(file.path(myProj,'Analytics','Func','UI','theme_color_sets.r')), encoding = 'utf-8')
	source(normalizePath(file.path(myProj,'Analytics','Data','Test_PortMgmt_LoadData.r')), encoding = 'utf-8')
	source(normalizePath(file.path(myProj,'Analytics','Func','UI','lang_PortMgmt.r')), encoding = 'utf-8')
	source(normalizePath(file.path(myProj,'Analytics','Func','UI','color_PortMgmt.r')), encoding = 'utf-8')
	uRV$chb <- uRV$PM_rpt
	CustData <- uRV$chb
	lang_cfg <- lang_CPM
	lang_disp <- 'CN'

	#Below please paste related code snippets and execute

}
