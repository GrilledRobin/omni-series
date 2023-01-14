#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This module (Portfolio Adjustment) is designed for below purposes:                                                                 #
#   |[1]Display the profitability of the portfolio a customer is holding at present, and that of the adjusted portfolio if any          #
#   |[2]Select product types from a given list in order to adjust the pofolio of a customer                                             #
#   |[3]Adjust the portfolio by a series of slider bars                                                                                 #
#   |[4]Display the comparison table regarding the portfolio profitability                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 客户经理协助客户对当前持有的产品进行调整以获得更合理的收益水平                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CustData      :   The vector/list of various data regarding one specific customer, details are as below:                           #
#   |                   [NumFmt_Currency  ]    <vector>     Vector of field names that will be displayed in the format: #,#00,00        #
#   |                   [NumFmt_Percent   ]    <vector>     Vector of field names that will be displayed in the format: #00,00%         #
#   |                   [NumFmt_Price     ]    <vector>     Vector of field names that will be displayed in the format: #00,0000        #
#   |                   [NumFmt_PnL       ]    <vector>     Vector of field names that will be displayed in opposite colors             #
#   |                   [CustRate_Prod    ]    <data.frame> Snapshot data with expected customer rate by products                       #
#   |                   [Prod_Acct        ]    <data.frame> MTD data of customer P&L at account level                                   #
#   |                   [FundLst_toDrawCH ]    <vector>     (can be NULL) Previously saved state of user selection upon the funds, to   #
#   |                                                        reload in this session; which enables user to switch language/font while   #
#   |                                                        keeping the selections from being rolled back.                             #
#   |                   [AUM_new          ]    <vector>     (can be NULL) Previously saved state of user input of a different AUM value #
#   |                                                        reload in this session; which enables user to switch language/font while   #
#   |                                                        keeping the input from being rolled back.                                  #
#   |                   [Prod_Adjusted    ]    <data.frame> (can be NULL) Previously saved state of adjusted portfolio holding to       #
#   |                                                        reload in this session; which enables user to switch language/font while   #
#   |                                                        keeping the selections from being rolled back.                             #
#   |f_loadstate   :   Flag of whether to load the previously saved state, useful for tracking of historical operations                 #
#   |                   [T]<Default> Try to load the state [FundLst_Selected] and [Prod_Adjusted] from the input [CustData]             #
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
#   |Ech_ext_utils :   The location of the JS file as utility extension to [echarts] to include for printing                            #
#   |                   IMPORTANT: Unlike the front-end configuration, this must be provided a physical location on the harddisk for    #
#   |                               rmarkdown/pagedown to lookup when creating plain HTML file to display the state of the App          #
#   |Wg_SliderGrp  :   The location of the HTML widget file as utility extension of [Slider Group]                                      #
#   |                   IMPORTANT: Unlike the front-end configuration, this must be provided a physical location on the harddisk for    #
#   |                               current function to compile the widget out of the plain HTML file                                   #
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
#   |CPA           :   Customer Portfolio Adjustment                                                                                    #
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
#   | Date |    20200411        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200418        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add a parameter [Ech_ext_utils] to acquire the utility extension for [echarts], esp. for the function call of               #
#   |      | [getEchartBarXAxisTitle] at present.                                                                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200419        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add a parameter [color_cfg] to unify the color settings for all related modules                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200501        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Set an observer to load the state of [Prod_Adjusted] and destroy once it is executed                                    #
#   |      |[2] Add a call to the HTML widget powered by [vue.js] as Slider Group for product balance adjustment                        #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200509        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [observer_pfx] to name the observers                                                                    #
#   |      |[2] Store all necessary observers into [session$userData] for garbage collection                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [match.arg.x] to enable matching args after mutation, e.g. case-insensitive match                  #
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
#   |   |shiny, dplyr, tidyselect, htmltools, V8, htmlwidgets, shinyWidgets, tippy, DT, echarts4r, jsonlite                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |scaleNum                                                                                                                   #
#   |   |   |match.arg.x                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$UsrShinyModules                                                                                                          #
#   |   |   |echarts_ext_utils.js      [Quote: This is a JS function library! Please use [tags$script] to activate it!]                 #
#   |   |   |vue.js                    [Quote: This is a JS function library! Please use [tags$script] to activate it!]                 #
#   |   |   |shinyjsExtension.js       [Quote: This is a JS function library! Please use [shinyextendjs] to activate it!]               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Visualization                                                                                                            #
#   |   |   |Widget_SliderGroup.html   [Quote: This is an HTML widget powered by [vue.js]!]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Dependent user-defined Modules                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, dplyr, tidyselect, htmltools, V8, htmlwidgets, shinyWidgets, tippy, DT, echarts4r, jsonlite
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

UM_CPA_ui_ProdSel <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_ProdSel'))
}

UM_CPA_ui_AUMadj <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_AUMadj'))
}

UM_CPA_ui_ProfitByProdType <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_ProfitByProdType'))
}

UM_CPA_ui_Advise <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_Advise'))
}

UM_custPortAdj_svr <- function(input,output,session
	,CustData = NULL,f_loadstate = T
	,lang_cfg = NULL,color_cfg = NULL
	,lang_disp = c('CN','EN'),font_disp = c('Microsoft YaHei','Helvetica','sans-serif','Arial','宋体')
	,Ech_ext_utils = NULL,Wg_SliderGrp = NULL
	,observer_pfx = 'uObs'
	,fDebug = FALSE){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	if (!is.logical(f_loadstate)) stop(ns(paste0('[001]Crucial parameter [f_loadstate] is not logical!')))
	lang_disp <- match.arg.x(lang_disp, arg.func = toupper)
	#We must ensure the prefix of the observers exist, otherwise all the similar observers will be destroyed!
	if (length(observer_pfx) == 0) observer_pfx <- 'uObs'
	formal.args <- formals(sys.function(sysP <- sys.parent()))
	uRV$font_list <- eval(formal.args$font_disp, envir = sys.frame(sysP))
	uRV$font_list_css <- paste0(
		sapply(uRV$font_list, function(m){if (length(grep('\\W',m,perl = T))>0) dQuote(m, q = F) else m})
		,collapse = ','
	)
	font_disp <- match.arg.x(font_disp)
	if (is.null(Ech_ext_utils)) warning(ns(paste0('[001]Crucial parameter [Ech_ext_utils] is missing! Printing may fail!')))
	#Below is the list of important stages to trigger the increment of initial progress bar
	uRV$pb_k <- list(
		#[1] Loading data
		load = 0
		#[2] Drawing charts
		,chart = 2
	)
	uRV$pb_k_all <- length(uRV$pb_k)
	uRV$pb_cnt_chart <- 0
	#We observe the status of the progress bar every 1sec, and destroy it after is it reaches the end
	uRV$k_ms_invld <- 1000
	uRV$df_Reset <- 0
	uRV$df_Update <- 0
	uRV$cnt_AUM_upd <- 0
	uRV$cnt_bal_upd <- 0
	uRV$AUM <- sum(CustData$Prod_Acct$bal_bcy)
	uRV$AUM_diff <- 0
	uRV$AUM_new <- uRV$AUM + uRV$AUM_diff
	uRV$knitr_params <- list()
	uRV$SaveState <- 0
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- shiny::reactiveVal(0)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[Module Call][UM_custPortAdj]')))
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
	uRV$dt_styles_DTables <- shiny::HTML(
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

	#280. Format the modals
	#281. Modal dialogs
	uRV$modal_styles_Dialog <- shiny::HTML(
		paste0(''
			#Format the [dismiss] button in the dialog
			,'[data-dismiss=modal] {'
				,'text-align: center;'
				,'padding: 4px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$Advise,';'
				,'font-family: ',font_disp,';'
				,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
				,'width: 40px;'
			,'}'
			#Add hover effect to the action buttons
			,'[data-dismiss=modal].hover, [data-dismiss=modal]:focus, [data-dismiss=modal]:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$AdvBtnHover,';'
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
			#Add styles to the action buttons
			,'.uAB-theme-m {'
				,'text-align: center;'
				,'padding: 4px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$CustAct,';'
				,'font-family: ',font_disp,';'
				,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
			,'}'
			#Add hover effect to the action buttons
			,'.uAB-theme-m.hover, .uAB-theme-m:focus, .uAB-theme-m:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			,'.cpa_fluidRow {'
				,'padding: 2px 15px;'
			,'}'
			,'.cpa_Column {'
				,'padding: 0px;'
				,'margin: 0px;'
			,'}'
		)
	)

	#400. Prepare the HTML elements
	#401. Load the parameter table
	dtsrc <- CustData$CustRate_Prod %>%
		dplyr::left_join(
			CustData$Prod_Acct %>%
				dplyr::select(nc_cifno,ProdCode,tidyselect::starts_with('c_ccy_'))
			,by = c(
				'ProdCode' = 'ProdCode'
				,'c_ccy_CN' = 'c_ccy_CN'
				,'c_ccy_EN' = 'c_ccy_EN'
			)
			,suffix = c('', '.cust')
		) %>%
		dplyr::mutate(
			F_Holding = ifelse(is.na(nc_cifno),F,T)
			,ProdCcy_CN = paste0(ProdName_CN,'-',c_ccy_CN)
			,ProdCcy_EN = paste0(ProdName_EN,'-',c_ccy_EN)
			,CustRate_Range = paste0(
				formatC( RateLower * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ), '%'
				,'~'
				,formatC( RateUpper * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ), '%'
			)
			,FeeRange = paste0(
				formatC( FeeLower * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ), '%'
				,'~'
				,formatC( FeeUpper * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ), '%'
			)
		)

	#405. Check whether there are any funds selected
	#We only need the table structure at present
	uRV$FundSel <- dtsrc %>% dplyr::filter(is.na(F_Holding))
	#Load the state if any
	if (isTRUE(f_loadstate))
		if (!is.null(CustData$FundLst_toDrawCH)){
			#This fund list should match below conditions:
			#[1] Exist in the full fund base
			#[2] Does not exist in the product holding as those from the product holding will be loaded separately
			uRV$FundSel <- dtsrc %>% dplyr::filter(!F_Holding, ProdCode %in% CustData$FundLst_toDrawCH)
		}

	#406. Check whether there is a new AUM value from the previously saved state
	#Load the state if any
	if (isTRUE(f_loadstate))
		if (!is.null(CustData$AUM_new)){
			uRV$AUM_new <- CustData$AUM_new
			uRV$AUM_diff <- uRV$AUM_new - uRV$AUM
		}

	#410. Product selector excluding funds as they would be selected in other modules while the parameter is passed in this module
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Reshape the input data][IN][CustData$CustRate_Prod]')))
	}

	#411. Prepare a function to translate the HTML tags into character string, in order to place them inside datatable
	btn_Prods <- function(FUN, len, id, ...) {
		inputs <- character(len)
		for (i in seq_len(len)) {
			inputs[i] <- as.character(FUN(paste0(id, i), ...))
		}
		inputs
	}

	#413. Only retrieve the products which are NOT invested by the customer
	dtsrc_ProdSel <- dtsrc %>%
		dplyr::filter(ProdType_EN != 'Fund', !F_Holding) %>%
		dplyr::arrange(ProdType_Seq, ProdCode) %>%
		dplyr::mutate(
			K_Row = dplyr::row_number()
			,F_Selected = F
		)

	#414. In case the input data has a state of fund selection, we reload the state.
	#This tibble is to be exported as a saved state.
	if (isTRUE(f_loadstate))
		if (!is.null(CustData$PortAdj_Selected)){
			chk_state <- CustData$PortAdj_Selected %>% dplyr::mutate(state_load = T)
			# View(chk_state)
			suppressMessages(
				dtsrc_ProdSel <- dtsrc_ProdSel %>%
					dplyr::left_join(chk_state, suffix = c('', '.sel')) %>%
					dplyr::mutate(F_Selected = ifelse(is.na(state_load),F,T)) %>%
					dplyr::select(-state_load, -tidyselect::ends_with('.sel'))
			)
		}
	nrow_dtsrc_ProdSel <- nrow(dtsrc_ProdSel)

	#415. Define the table to display
	colsDT_ProdSel <- names(lang_cfg[[lang_disp]][['tblvars']][['PortAdj_ProdSel']])
	names(colsDT_ProdSel) <- lang_cfg[[lang_disp]][['tblvars']][['PortAdj_ProdSel']]

	#417. Add the buttons inside the datatable by the function defined at above steps
	#[Quote: https://stackoverflow.com/questions/45739303/r-shiny-handle-action-buttons-in-data-table ]
	dtsrc_ProdSel$btn_ProdSel <- btn_Prods(
		shiny::actionButton
		,nrow_dtsrc_ProdSel
		#[shiny] does not recognize the series of button IDs as they are created by [ESCAPE] in datatable.
		,ns('pseudoSel_')
		,class = 'uAB-nav-xs'
		,icon = shiny::icon('square-o')
		,NULL
		,onclick = paste0('Shiny.onInputChange("',ns('uWg_AB_PortAdj_Sel'),'", this.id + "_" + (new Date()).getTime())')
	)

	#419. Transform the icons of the buttons in terms of whether the product is already selected
	dtsrc_ProdSel <- dtsrc_ProdSel %>%
		dplyr::mutate(
			btn_ProdSel = ifelse(
				F_Selected
				,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_ProdSel)
				,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_ProdSel)
			)
		)
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Reshape the input data][OUT][dtsrc_ProdSel]')))
	}

	#420. Draw the datatable
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[420][Draw the datatable][IN][dtsrc_ProdSel]')))
	}
	#421. Prepare the necessary fields to draw a datatable for fund selection
	uRV$dt_draw <- dtsrc_ProdSel[,c(colsDT_ProdSel,'K_Row','F_Selected','ProdCode','c_ccy_CN','c_ccy_EN')]
	uRV$dtnames <- colnames(uRV$dt_draw)

	#425. Draw the datatable
	#[Quote: https://rstudio.github.io/DT/options.html ]
	#[Quote: https://rstudio.github.io/DT/010-style.html ]
	uRV$dt_Prods_pre <- DT::datatable(
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
					,paste0(lang_cfg[[lang_disp]][['dtnav']][['PortAdj_ProdSel']][['Navigator']], ': ')
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Selected')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('check-square-o')
						,lang_cfg[[lang_disp]][['dtnav']][['PortAdj_ProdSel']][['Filter_Selected']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Selected'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Excluded')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('square-o')
						,lang_cfg[[lang_disp]][['dtnav']][['PortAdj_ProdSel']][['Filter_Excluded']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Excluded'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('FilterAB_Clear')
						,class = 'uAB-nav-xs'
						,icon = shiny::icon('minus-square-o')
						,lang_cfg[[lang_disp]][['dtnav']][['PortAdj_ProdSel']][['Clear_Selected']]
						,onclick = paste0('Shiny.onInputChange("',ns('FilterAB_Clear'),'", (new Date()).getTime())')
					)
				)
				,shiny::tags$span(
					style = paste0('padding: 0;')
					,shiny::actionButton(
						ns('uWg_AB_ConfirmSel')
						,class = 'uAB-theme-xs'
						,icon = shiny::icon('toggle-right')
						,lang_cfg[[lang_disp]][['dtnav']][['PortAdj_ProdSel']][['Confirm_Selection']]
						,onclick = paste0('Shiny.onInputChange("',ns('uWg_AB_ConfirmSel'),'", (new Date()).getTime())')
					)
				)
			))
		)
		,rownames = dt_rownames
		#Only determine the columns to be displayed, rather than the columns to extract from the input data
		,colnames = colsDT_ProdSel
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
			,pagingType = 'numbers'
			# ,pageLength = nrow_dtsrc_Funds
			#[Quote: https://datatables.net/reference/option/language.searchPlaceholder ]
			,language = append(
				lang_cfg[[lang_disp]][['dtstyle']][['language']]
				,list(searchPlaceholder = lang_cfg[[lang_disp]][['dtstyle']][['PortAdj_ProdSel']][['searchPlaceholder']])
			)
			# ,language = list(
			# 	#Leave nothing to the left of the search box
			# 	search = '_INPUT_'
			# )
			,dom = '<"acc-dataTable"lftp>'
			,orderMulti = TRUE
			,columnDefs = list(
				list(
					targets = which(
						colnames(uRV$dt_draw) %in% c(
							'K_Row','F_Selected','ProdCode','c_ccy_CN','c_ccy_EN'
							,'ProdType_EN','ProdType_Seq'
							,paste0('ProdName_',lang_disp),'RateLower','RateUpper','FeeLower','FeeUpper'
						)
					) + dt_colshift
					,visible = FALSE
				)
				#Prevent the column with buttons to be orderable as the result is not as desired
				,list(
					targets = which(colnames(uRV$dt_draw) %in% c('btn_ProdSel')) + dt_colshift
					,orderable = FALSE
				)
				#Set the icon at the center of the column
				,list(
					targets = which(colnames(uRV$dt_draw) %in% c('btn_ProdSel')) + dt_colshift
					,className = 'dt-center'
				)
			)
		#End of [options]
		)
	#End of [datatable]
	) %>%
		#Set the numbers to be displayed as: [#,###.00]
		DT::formatCurrency(
			names(colsDT_ProdSel)[which(colsDT_ProdSel %in% CustData$NumFmt_Currency)]
			,currency = ''
		) %>%
		#Set the price to be displayed as: [#,###.0000]
		DT::formatCurrency(
			names(colsDT_ProdSel)[which(colsDT_ProdSel %in% CustData$NumFmt_Price)]
			,currency = ''
			,digits = 4
		) %>%
		#Set the percentage to be displayed as: [#,###.00%]
		DT::formatPercentage(
			names(colsDT_ProdSel)[which(colsDT_ProdSel %in% CustData$NumFmt_Percent)]
			,digits = 2
		) %>%
		#Set the font color for positive numbers as [green], while that for negative ones as [red]
		DT::formatStyle(
			names(colsDT_ProdSel)[which(colsDT_ProdSel %in% CustData$NumFmt_PnL)]
			,color = DT::styleInterval(
				-0.0000001
				,c(color_cfg$Negative,color_cfg$Positive)
			)
		) %>%
		#Set the font for all content in the table
		DT::formatStyle(
			names(colsDT_ProdSel)
			,fontFamily = font_disp
			,fontSize = shiny::validateCssUnit(uRV$styles_ch_FontSize_item)
		)
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[420][Draw the datatable][OUT][uRV$dt_Prods_pre]')))
	}

	#440. Prepare the chart of AUM distribution
	#441. Whe clicking upon the [Reset] button
	session$userData[[paste(ns(observer_pfx),'reset',sep='_')]] <- shiny::observe(
		{
			input$uWg_AB_Reset

			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[441][observe][IN][input$uWg_AB_Reset]:',input$uWg_AB_Reset)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_Reset)) return()
				if (input$uWg_AB_Reset == 0) return()

				#100. Change the counter for resetting the state
				uRV$df_Reset <- uRV$df_Reset + 1

				#300. Reset the total AUM
				uRV$AUM_new <- uRV$AUM
				uRV$AUM_diff <- 0

				#500. Replace the data in the Product Selector by setting [F_Selected = F] as initialization
				#510. Overwrite the data used to draw the datatable
				uRV$dt_draw[['F_Selected']] <- FALSE
				uRV$dt_draw <- uRV$dt_draw %>%
					dplyr::mutate(
						btn_ProdSel = ifelse(
							F_Selected
							,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_ProdSel)
							,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_ProdSel)
						)
					)

				#590. Refresh the datatable at frontend, to improve the user experience
				DT::replaceData(
					uRV$proxy_dt_ProdSel
					,uRV$dt_draw
					,resetPaging = FALSE
					#IMPORTANT! Below option is CRUCIAL!
					,rownames = dt_rownames
				)
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[441][observe][OUT][uRV$df_Reset]:',uRV$df_Reset)))
					message(ns(paste0('[441][observe][OUT][uRV$dt_draw]')))
					message(ns(paste0('[441][observe][OUT][<uRV$dt_Prods_pre>]: Updated datatable!')))
				}
			})
		#End of [observe] at [440]
		}
		,label = ns(paste0('[441]Switch to original [CustRate] data to be merged to the customer holding data'))
	)

	#445. Whe clicking upon the [Confirm Selection] button
	session$userData[[paste(ns(observer_pfx),'conf_sel',sep='_')]] <- shiny::observe(
		{
			input$uWg_AB_ConfirmSel

			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[445][observe][IN][input$uWg_AB_ConfirmSel]:',input$uWg_AB_ConfirmSel)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfirmSel)) return()
				if (input$uWg_AB_ConfirmSel == 0) return()

				#100. Change the counter for resetting the state
				uRV$df_Update <- uRV$df_Update + 1
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[445][observe][OUT][uRV$df_Update]:',uRV$df_Update)))
				}
			})
		#End of [observe] at [445]
		}
		,label = ns(paste0('[445]Switch to the internal [dt_draw] data to be merged to the customer holding data'))
	)

	#449. Reset or update the base data for charting
	session$userData[[paste(ns(observer_pfx),'upd_chartbase',sep='_')]] <- shiny::observe(
		{
			uRV$df_Reset
			uRV$df_Update

			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[449][observe][IN][uRV$df_Reset]:',uRV$df_Reset)))
					message(ns(paste0('[449][observe][IN][uRV$df_Update]:',uRV$df_Update)))
				}
				#010. Return if the condition is not valid

				#100. Prepare the data to be merged for AUM allocation
				uRV$df_mrgTo_ProdAcct <- dtsrc_ProdSel %>%
					dplyr::inner_join(
						uRV$dt_draw %>%
							dplyr::filter(F_Selected == T) %>%
							dplyr::select(ProdCode,tidyselect::starts_with('c_ccy_'))
						,by = c(
							'ProdCode' = 'ProdCode'
							,'c_ccy_CN' = 'c_ccy_CN'
							,'c_ccy_EN' = 'c_ccy_EN'
						)
						,suffix = c('', '.sel')
					)

				#200. Export the selection result for all languages
				uRV$PortAdj_Selected <- uRV$dt_draw %>%
					dplyr::filter(F_Selected == T) %>%
					dplyr::select(ProdType_Seq,ProdType_EN,tidyselect::starts_with('ProdCcy_')) %>%
					dplyr::arrange(ProdType_Seq,ProdType_EN)

				#500. Combine the customer holding to the extra products as indicated
				#This data is created even at initialization of the module.
				uRV$df_ProdAdj <- CustData$Prod_Acct %>%
					dplyr::mutate(F_Holding = T) %>%
					dplyr::left_join(
						CustData$CustRate_Prod
						,by = c(
							'ProdCode' = 'ProdCode'
							,'c_ccy_CN' = 'c_ccy_CN'
							,'c_ccy_EN' = 'c_ccy_EN'
						)
						,suffix = c('', '.chk')
					) %>%
					dplyr::select(-tidyselect::ends_with('.chk')) %>%
					#We have to create below two fields at first,
					# for we have no source fields for the [union]ed table [uRV$df_mrgTo_ProdAcct].
					dplyr::mutate(
						ProdCcy_CN = paste0(ProdName_CN,'-',c_ccy_CN)
						,ProdCcy_EN = paste0(ProdName_EN,'-',c_ccy_EN)
					) %>%
					dplyr::union_all(uRV$df_mrgTo_ProdAcct) %>%
					dplyr::union_all(uRV$FundSel) %>%
					dplyr::mutate(
						bal_bcy = ifelse(is.na(bal_bcy),0,bal_bcy)
						,aum = uRV$AUM
					) %>%
					dplyr::mutate(
						F_Holding = ifelse(is.na(F_Holding),F,F_Holding)
						,bal_pct = ifelse(aum == 0 | is.na(aum), 0, bal_bcy / aum)
						,lbl_CN = scaleNum( bal_bcy , ScaleBase = 10000 , map_units = map_units_CN , scientific = F )$values
						,lbl_EN = scaleNum( bal_bcy , ScaleBase = 1000 , map_units = map_units_EN , scientific = F )$values
					) %>%
					dplyr::mutate(
						ProdCcy_CN = ifelse(ProdType_EN == 'Savings+', ProdName_CN, ProdCcy_CN)
						,ProdCcy_EN = ifelse(ProdType_EN == 'Savings+', ProdName_EN, ProdCcy_EN)
					)

				#700. Adjust the product balance at initialization & update on charting base
				uRV$Prod_Adjusted <- uRV$df_ProdAdj %>%
					dplyr::select(ProdType_Seq,ProdType_EN,bal_bcy,tidyselect::starts_with('ProdCcy_')) %>%
					dplyr::rename(bal_new = bal_bcy) %>%
					#This condition ensures the changes are made upon the most basic product - CASA
					dplyr::mutate(
						bal_new = ifelse(ProdType_EN == 'Savings+', bal_new + uRV$AUM_diff, bal_new)
						,aum_new = uRV$AUM_new
					) %>%
					dplyr::mutate(
						bal_pct = ifelse(aum_new == 0, 0, bal_new / aum_new)
						,lbl_CN = scaleNum( bal_new , ScaleBase = 10000 , map_units = map_units_CN , scientific = F )$values
						,lbl_EN = scaleNum( bal_new , ScaleBase = 1000 , map_units = map_units_EN , scientific = F )$values
					) %>%
					dplyr::arrange(ProdType_Seq,desc(ProdCcy_EN))

				#900. Mark the completion of operations in this module
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[449][observe][OUT][<uRV$df_ProdAdj>,<uRV$Prod_Adjusted>]')))
				}
			})
		#End of [observe] at [449]
		}
		,label = ns(paste0('[449]Prepare the chart base for portfolio adjustment'))
	)

	#450. Determine the data as [Adjusted Product Holding]
	#451. Verify whether there is a previously saved state to load
	#We only conduct the loading at the initialization of the module, not even when clicking [reset],
	# as below adjusted result is NOT an external result from other modules for loading,
	# but from the previous call of this module itself.
	obs_Load_Prod_Adjusted <- shiny::observe(
		{
			uRV$df_Reset

			shiny::isolate({
				#010. Return if the condition is not valid
				if (is.null(uRV$df_Reset)) return()
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[451][initialize][state load][CustData$Prod_Adjusted]')))
				}

				#500. Load the state
				if (isTRUE(f_loadstate))
					if (!is.null(CustData$Prod_Adjusted)){
						uRV$Prod_Adjusted <- CustData$Prod_Adjusted
					}

				#800. Destroy the observer once it is executed
				obs_Load_Prod_Adjusted$destroy()

				#900. Mark the completion of operations in this module
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[451][initialize][state load][CustData$Prod_Adjusted]:Successful')))
				}
			#End of [isolate]
			})
		#End of [observe] at [451]
		}
		,label = ns(paste0('[451]Load the state for [Prod_Adjusted]'))
	)

	#500. Update objects reactively
	#520. Draw the charts once the necessary actions have been taken by user
	session$userData[[paste(ns(observer_pfx),'upd_charts',sep='_')]] <- shiny::observe(
		{
			uRV$df_Reset
			uRV$df_Update
			uRV$cnt_AUM_upd
			uRV$cnt_bal_upd

			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[520][observe][IN][uRV$df_Reset]:',uRV$df_Reset)))
					message(ns(paste0('[520][observe][IN][uRV$df_Update]:',uRV$df_Update)))
					message(ns(paste0('[520][observe][IN][uRV$cnt_AUM_upd]:',uRV$cnt_AUM_upd)))
					message(ns(paste0('[520][observe][IN][uRV$cnt_bal_upd]:',uRV$cnt_bal_upd)))
				}
				#010. Return if the condition is not valid
				# return()

				#100. Determine the sequence of chart items by selecting all exiting products in the input data and the adjusted one
				suppressMessages(
					uRV$ch_base <- uRV$df_ProdAdj %>%
						dplyr::full_join(
							uRV$Prod_Adjusted %>%
								dplyr::rename(
									new_pct = bal_pct
									,lbl_CN_new = lbl_CN
									,lbl_EN_new = lbl_EN
								)
							,suffix = c('', '.new')
						) %>%
						dplyr::mutate(
							bal_bcy = ifelse(is.na(bal_bcy),0,bal_bcy)
							,bal_pct = ifelse(is.na(bal_pct),0,bal_pct)
							,bal_new = ifelse(is.na(bal_new),0,bal_new)
							,new_pct = ifelse(is.na(new_pct),0,new_pct)
							,fx_gain_pct = ifelse(is.na(fx_gain_pct),0,fx_gain_pct)
							,GainRate_ccy = ifelse(is.na(GainRate_ccy),0,GainRate_ccy)
						) %>%
						dplyr::mutate(
							lbl_CN = scaleNum( bal_bcy , ScaleBase = 10000 , map_units = map_units_CN , scientific = F )$values
							,lbl_EN = scaleNum( bal_bcy , ScaleBase = 1000 , map_units = map_units_EN , scientific = F )$values
							,lbl_CN_new = scaleNum( bal_new , ScaleBase = 10000 , map_units = map_units_CN , scientific = F )$values
							,lbl_EN_new = scaleNum( bal_new , ScaleBase = 1000 , map_units = map_units_EN , scientific = F )$values
						) %>%
						#Below sorting is only useful for [echarts]!
						#The dataIndex is ONLY determined by the evaluation field!
						dplyr::arrange(bal_bcy) %>%
						dplyr::mutate(dataIndex = dplyr::row_number() - 1) %>%
						dplyr::arrange(bal_new) %>%
						dplyr::mutate(dataIndexNew = dplyr::row_number() - 1) %>%
						#Below sorting is only useful for displaying the items at [xAxis/yAxis]
						dplyr::arrange(desc(ProdType_Seq),ProdCcy_EN)
				)
				# View(uRV$df_ProdAdj)
				# View(uRV$Prod_Adjusted)
				# View(uRV$ch_base)

				#300. Prepare the advice as text messages
				#310. Prepare the wording for other products than funds
				uRV$df_adv_src_oth <- uRV$ch_base %>%
					dplyr::select(ProdCode,tidyselect::starts_with('c_ccy_'),tidyselect::starts_with('ProdCcy_'),bal_bcy,bal_new) %>%
					dplyr::mutate(bal_chg = bal_new - bal_bcy) %>%
					dplyr::mutate(direction = ifelse(bal_chg >= -0.0000001, 1, -1)) %>%
					dplyr::select(-bal_bcy,-bal_new) %>%
					dplyr::inner_join(
						CustData$src_ProdAdvisory
						,by = c(
							'ProdCode' = 'ProdCode'
							,'c_ccy_EN' = 'c_ccy_EN'
							,'direction' = 'direction'
						)
						,suffix = c('', '.txt')
					)

				#320. Parse the text to retrieve the amount for display
				uRV$df_adv_txt_oth <- uRV$df_adv_src_oth %>%
					dplyr::mutate(
						amt = ifelse(
							Amt_Tbl == 'uRV$df_adv_src_oth'
							,abs(bal_chg)
							,ifelse(
								is.na(Amt_Tbl)
								,NA
								,eval(parse(
									text = paste0(
										Amt_Tbl,' %>% '
										,'dplyr::filter( ProdCode == ',ProdCode,', c_ccy_EN == ',c_ccy_EN,' ) %>% '
										,'dplyr::select_at("',Amt_Var,'") %>% '
										,'unlist()'
									)
									,keep.source = F
								))
							)
						)
					)

				#340. Prepare the wording for funds
				uRV$df_adv_txt_fund <- uRV$ch_base %>%
					dplyr::filter(ProdType_EN == 'Fund') %>%
					dplyr::select(ProdCode,tidyselect::starts_with('c_ccy_'),tidyselect::starts_with('ProdCcy_'),bal_bcy,bal_new) %>%
					dplyr::mutate(bal_chg = bal_new - bal_bcy) %>%
					dplyr::mutate(direction = ifelse(bal_chg >= -0.0000001, 1, -1)) %>%
					dplyr::select(-bal_bcy,-bal_new) %>%
					dplyr::mutate(
						ops_CN = ifelse(
							direction == 1
							,lang_cfg[['CN']][['advmsgs']][['Fund']][['Positive']]
							,lang_cfg[['CN']][['advmsgs']][['Fund']][['Negative']]
						)
						,ops_EN = ifelse(
							direction == 1
							,lang_cfg[['EN']][['advmsgs']][['Fund']][['Positive']]
							,lang_cfg[['EN']][['advmsgs']][['Fund']][['Negative']]
						)
						,amt = abs(bal_chg)
					)

				#390. Combine the text messages
				uRV$df_adv_txt <- uRV$df_adv_txt_oth %>%
					dplyr::union_all(uRV$df_adv_txt_fund) %>%
					dplyr::filter(round(bal_chg,2) != 0)

				#395. Create the UI to display the text messages.
				if (nrow(uRV$df_adv_txt) > 0) {
					uRV$txt_area_adv <- shiny::fluidRow(
						class = 'cpa_fluidRow'
						,style = paste0(''
							,uRV$styles_tabBox_font
						)
						,lapply(1:nrow(uRV$df_adv_txt), function(i){
							txt <- paste0('* '
								,uRV$df_adv_txt[i,paste0('ProdCcy_',lang_disp)],' - '
								,uRV$df_adv_txt[i,paste0('ops_',lang_disp)]
								,formatC(
									abs(uRV$df_adv_txt[i,'bal_chg'] %>% unlist())
									,digits = 2
									,big.mark = ','
									,format = 'f'
									,zero.print = '0.00'
								)
							)

							shiny::fluidRow(
								class = 'cpa_fluidRow'
								,txt
							)
						})
					)
				} else {
					uRV$txt_area_adv <- shiny::fluidRow(
						class = 'cpa_fluidRow'
						,style = paste0(''
							,uRV$styles_tabBox_font
						)
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%'
							)
							,lang_cfg[[lang_disp]][['advmsgs']][['Nil']]
						)
					)
				}

				#400. Set the height of the chart dynamically
				params_barWidth <- 12
				params_kSeries <- 2
				params_barCategoryGap <- 0.2
				params_groupGap <- 12
				params_ChartToGridTop <- 24
				params_ChartToGridBottom <- 8
				ch_height <- (
						params_barWidth * ( params_kSeries + params_barCategoryGap ) + params_groupGap
					) * nrow(uRV$ch_base)
					+ params_ChartToGridBottom
				uRV$ch_height_BalAdj <- ch_height + params_ChartToGridTop + params_ChartToGridBottom

				#500. Draw the chart to display the AUM distribution
				uRV$ch_BalAdj <- uRV$ch_base %>%
					#Set the [height] here to ensure the [printed chart] has the same height,
					# while set the [height] inside [echarts4rOutput] is to ensure the [screen display] has the same height.
					#This means: both settings have to be set for compatibility!
					echarts4r::e_charts(bal_bcy, width = '100%', height = uRV$ch_height_BalAdj) %>%
					#100. Draw the bar for the series as [Current Product Holding]
					echarts4r::e_bar_(
						paste0('ProdCcy_',lang_disp)
						,name = lang_cfg[[lang_disp]][['tblvars']][['PortAdj_Dist']][['bal_bcy']]
						,barWidth = params_barWidth
						,color = color_cfg$CustAct
						,label = list(
							show = TRUE
							,position = 'right'
							,distance = 2
							,fontFamily = font_disp
							,fontSize = uRV$styles_ch_FontSize_item
							,formatter = htmlwidgets::JS(paste0(
								'function(params){'
									,"var labellst = [\"",paste0(uRV$ch_base[[paste0('lbl_',lang_disp)]],collapse = '","'),"\"];"
									,"var idxlst = [",paste0(uRV$ch_base$dataIndex,collapse = ','),"];"
									,'return('
										# ,'labellst[idxlst.indexOf(params.dataIndex)] + " : " + params.dataIndex'
										,'labellst[idxlst.indexOf(params.dataIndex)]'
									,');'
								,'}'
							))
						)
						,tooltip = list(
							confine = TRUE
							,textStyle = list(
								fontFamily = font_disp
							)
							,formatter = htmlwidgets::JS(paste0(
								'function(params){'
									,"var pctlst = [",paste0(uRV$ch_base$bal_pct,collapse = ','),"];"
									,"var idxlst = [",paste0(uRV$ch_base$dataIndex,collapse = ','),"];"
									,'return('
										,'"<strong>" + params.value[1] + "</strong>"'
										,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['PortAdj_Dist']][['bal_bcy']],')"'
										,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(2))'
										,'+ "<br/>(" + (parseFloat(pctlst[idxlst.indexOf(params.dataIndex)]) * 100).toFixed(2) + "%)"'
									,');'
								,'}'
							))
						)
						,x_index = 0
						,y_index = 0
					) %>%
					#200. Draw the bar for the series as [Adjusted Product Holding]
					echarts4r::e_data(uRV$ch_base,bal_new) %>%
					echarts4r::e_bar_(
						paste0('ProdCcy_',lang_disp)
						,name = lang_cfg[[lang_disp]][['tblvars']][['PortAdj_Dist']][['bal_new']]
						,barWidth = params_barWidth
						,barCategoryGap = params_barCategoryGap * 100
						,color = color_cfg$CustNew
						,label = list(
							show = TRUE
							,position = 'right'
							,distance = 2
							,fontFamily = font_disp
							,fontSize = uRV$styles_ch_FontSize_item
							,formatter = htmlwidgets::JS(paste0(
								'function(params){'
									,"var labellst = [\"",paste0(uRV$ch_base[[paste0('lbl_',lang_disp,'_new')]],collapse = '","'),"\"];"
									,"var idxlst = [",paste0(uRV$ch_base$dataIndexNew,collapse = ','),"];"
									,'return('
										# ,'labellst[idxlst.indexOf(params.dataIndex)] + " : " + params.dataIndex'
										,'labellst[idxlst.indexOf(params.dataIndex)]'
									,');'
								,'}'
							))
						)
						,tooltip = list(
							confine = TRUE
							,textStyle = list(
								fontFamily = font_disp
							)
							,formatter = htmlwidgets::JS(paste0(
								'function(params){'
									,"var pctlst = [",paste0(uRV$ch_base$new_pct,collapse = ','),"];"
									,"var idxlst = [",paste0(uRV$ch_base$dataIndexNew,collapse = ','),"];"
									,'return('
										,'"<strong>" + params.value[1] + "</strong>"'
										,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['PortAdj_Dist']][['bal_new']],')"'
										,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[0]).toFixed(2))'
										,'+ "<br/>(" + (parseFloat(pctlst[idxlst.indexOf(params.dataIndex)]) * 100).toFixed(2) + "%)"'
									,');'
								,'}'
							))
						)
						,x_index = 0
						,y_index = 0
					) %>%
					#300. Setup the axes
					echarts4r::e_y_axis(
						index = 0
						,gridIndex = 0
						,data = uRV$ch_base[[paste0('ProdCcy_',lang_disp)]]
						,type = 'category'
						,axisLabel = list(
							# rotate = -90
							fontFamily = font_disp
							,fontSize = uRV$styles_ch_FontSize_item
							,margin = 4
							#[Below function is from: [shinyjsExtension.js]]
							#Another solution: [ http://www.kt5.cn/fe/2019/12/20/echarts-label-axislabel/ ]
							,formatter = htmlwidgets::JS(paste0(
								'function(value,index){'
									,'return('
										#Below function comes directly from the JavaScript file
										#[Quote: [omniR$UsrShinyModules$shinyjsExtension.js]]
										,'getEchartBarXAxisTitle('
											,'value'
											#Below parameter has no effect as this is for y-axis
											,',',nrow(uRV$ch_base)
											#Below parameter is to calculate the number of characters to be displayed in each row
											,',',uRV$styles_ch_FontSize_item
											#It is weird that this width has no relationship with the [grid width]!
											,',',172
											#Below two parameters indicate the margins of the label to the left edge as well as the axis
											,',2'
											,',2'
											#Below parameter indicates that the calculation is for y-axis
											,',"y"'
										,')'
									,');'
								,'}'
							))
							#Force to show all labels
							,interval = 0
						)
						,axisTick = list(show = FALSE)
						,axisPointer = list(show = FALSE)
						,splitLine = list(
							lineStyle = list(
								type = 'dashed'
							)
						)
					) %>%
					echarts4r::e_x_axis(
						index = 0
						,gridIndex = 0
						,show = FALSE
						,type = 'value'
						,axisTick = list(show = FALSE)
						,axisPointer = list(show = FALSE)
						,axisLabel = list(show = FALSE)
					) %>%
					#400. Setup the legend
					echarts4r::e_legend(
						right = 4
						,top = 16
						,orient = 'vertical'
						,itemGap = 2
						,itemWidth = 8
						,itemHeight = 8
						,textStyle = list(
							fontFamily = font_disp
							,fontSize = uRV$styles_ch_FontSize_item
						)
					) %>%
					#500. Setup the title
					echarts4r::e_title(
						text = lang_cfg[[lang_disp]][['charttitle']][['PortAdj_Dist']]
						,left = 4
						,top = 2
						,textStyle = list(
							fontFamily = font_disp
							,fontSize = uRV$styles_ch_FontSize_title
						)
					) %>%
					#920. Show a loading animation when the chart is re-drawn
					echarts4r::e_show_loading() %>%
					#980. Enable the tooltip triggered by mouse over the bars
					echarts4r::e_tooltip(
						trigger = 'item'
						,axisPointer = list(
							type = 'cross'
						)
					)

				#Set proper grid
				uRV$grid_BalAdj <- list(index = 0, top = params_ChartToGridTop, right = 40, bottom = params_ChartToGridBottom, left = 120)
				uRV$ch_BalAdj <- do.call(echarts4r::e_grid
					,append(
						list(e = uRV$ch_BalAdj)
						,append(
							uRV$grid_BalAdj
							,list(height = ch_height)
						)
					)
				)
				output$EchOut_BalAdj <- echarts4r::renderEcharts4r({uRV$ch_BalAdj})

				#700. Draw a datatable showing the P&L of the adjusted portfolio
				#710. Prepare the columns to be displayed
				colsDT_PnL <- c(
					paste0('ProdCcy_',lang_disp), 'ProdRiskLevel', 'fx_gain_pct'
					, 'bal_bcy', 'GainRate_ccy'
					, 'bal_new', 'RateLower', 'RateUpper'
				)

				#730. Calculate the summaries
				gain_curr <- sum(
					uRV$ch_base$bal_bcy * uRV$ch_base$GainRate_ccy * ( rep(1,nrow(uRV$ch_base)) + uRV$ch_base$fx_gain_pct )
				) / sum(
					uRV$ch_base$bal_bcy
				)
				gain_exp_lower <- sum(
					uRV$ch_base$bal_new * uRV$ch_base$RateLower
				) / sum(
					uRV$ch_base$bal_new
				)
				gain_exp_upper <- sum(
					uRV$ch_base$bal_new * uRV$ch_base$RateUpper
				) / sum(
					uRV$ch_base$bal_new
				)

				#740. Setup the two-level header of the table
				#[Quote: https://rstudio.github.io/DT/ ]
				sketch <- htmltools::withTags(table(
					class = 'compact display'
					,thead(
						tr(
							th(rowspan = 2, lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][[paste0('ProdCcy_',lang_disp)]])
							,th(rowspan = 2, lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['ProdRiskLevel']])
							,th(rowspan = 2, lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['fx_gain_pct']])
							,th(colspan = 2, lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['Before']][['th']])
							,th(colspan = 3, lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['After']][['th']])
						)
						,tr(
							th(lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['Before']][['bal_bcy']])
							,th(lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['Before']][['GainRate_ccy']])
							,th(lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['After']][['bal_new']])
							,th(lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['After']][['RateLower']])
							,th(lang_cfg[[lang_disp]][['tblvars']][['PortAdj_PnL']][['After']][['RateUpper']])
						)
					)
				))

				#750. Create a temporary data.frame to drawing the data.table
				tmp_dt <- uRV$ch_base %>%
					#Below sorting is to echo the sequence of items in above chart
					dplyr::arrange(ProdType_Seq,desc(ProdCcy_EN))

				#780. Draw the datatable
				#[Quote: https://rstudio.github.io/DT/options.html ]
				#[Quote: https://rstudio.github.io/DT/010-style.html ]
				uRV$dt_PnL <- DT::datatable(
					tmp_dt[,colsDT_PnL]
					,caption = htmltools::tags$caption(
						style = paste0(
							'padding-right: 5px;'
							,'caption-side: bottom;'
							,'text-align: right;'
							,uRV$styles_tabBox_font
						)
						,shiny::tags$span(shiny::tagList(
							shiny::HTML(sprintf(
								lang_cfg[[lang_disp]][['tblsubtotals']][['PortAdj_PnL']]
								,shiny::tags$span(
									style = paste0('color: ',setNumColor(gain_curr),';')
									,paste0(formatC( gain_curr * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ),'%')
								)
								,shiny::tags$span(
									style = paste0('color: ',setNumColor(gain_exp_lower),';')
									,paste0(formatC( gain_exp_lower * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ),'%')
								)
								,shiny::tags$span(
									style = paste0('color: ',setNumColor(gain_exp_upper),';')
									,paste0(formatC( gain_exp_upper * 100 , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' ),'%')
								)
							))
						))
					)
					,rownames = dt_rownames
					#Only determine the columns to be displayed, rather than the columns to extract from the input data
					# ,colnames = colsDT_PnL
					#Replace [colnames] with [container]
					,container = sketch
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
						#Setup the styles for the table header
						initComplete = V8::JS(paste0(
							"function(settings, json){"
								,"$(this.api().table().header()).css({"
									,"'background-color': '",color_cfg$DTHeaderBg,"'"
									,",'color': '",color_cfg$DTHeaderTxt,"'"
									,",'font-family': '",font_disp,"'"
									,",'font-size': '",shiny::validateCssUnit(uRV$styles_ch_FontSize_item),"'"
								,"});"
							,"}"
						))
						#We have to set the [stateSave=F], otherwise the table cannot be displayed completely!!
						,stateSave = FALSE
						,ordering = FALSE
						# ,autoWidth = TRUE
						,scrollX = FALSE
						#[Show N entries] on top left
						,pageLength = nrow(uRV$dt_PnL)
						#[Quote: https://datatables.net/reference/option/language.searchPlaceholder ]
						,language = lang_cfg[[lang_disp]][['dtstyle']][['language']]
						#Only display the table
						,dom = 't'
						,columnDefs = list()
					#End of [options]
					)
				#End of [datatable]
				) %>%
					#Set the numbers to be displayed as: [#,###.00]
					DT::formatCurrency(
						which(colsDT_PnL %in% CustData$NumFmt_Currency)
						,currency = ''
					) %>%
					#Set the price to be displayed as: [#,###.0000]
					DT::formatCurrency(
						which(colsDT_PnL %in% CustData$NumFmt_Price)
						,currency = ''
						,digits = 4
					) %>%
					#Set the percentage to be displayed as: [#,###.00%]
					DT::formatPercentage(
						which(colsDT_PnL %in% CustData$NumFmt_Percent)
						,digits = 2
					) %>%
					#Set the font color for positive numbers as [green], while that for negative ones as [red]
					DT::formatStyle(
						which(colsDT_PnL %in% CustData$NumFmt_PnL)
						,color = DT::styleInterval(
							-0.0000001
							,c(color_cfg$Negative,color_cfg$Positive)
						)
					) %>%
					#Set the font for all content in the table
					DT::formatStyle(
						colsDT_PnL
						,fontFamily = font_disp
						,fontSize = shiny::validateCssUnit(uRV$styles_ch_FontSize_item)
					)

				#900. Output the element to the parent environment
				uRV$knitr_params$print_ch_BalAdj <- shiny::tagList(
					shiny::tags$script(src = Ech_ext_utils)
					,uRV$ch_BalAdj
				)
				uRV$knitr_params$print_dt_PnL <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$dt_styles_DTables
					)
					,uRV$dt_PnL
				)
				uRV$knitr_params$print_txt_Advisory <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					,shiny::fluidRow(
						class = 'cpa_fluidRow'
						,style = paste0(''
							,'font-family: ',font_disp,';'
							,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_title),';'
						)
						,lang_cfg[[lang_disp]][['rptsecs']][['Advisory']][['Helper']]
					)
					,uRV$txt_area_adv
				)

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
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[595][observeEvent][IN][uRV$pb_cnt_chart]:<',uRV$pb_cnt_chart,'>')))
			}
			if (is.null(uRV$pb_chart)) return()
			#Close the progress bar as long as its value reaches 100%
			# shiny::invalidateLater(uRV$k_ms_invld,session)
			if (!is.environment(uRV$pb_chart$.__enclos_env__$private)) return()
			if (uRV$pb_cnt_chart >= uRV$pb_k$chart){
				# uRV$pb_chart$set(message = NULL)
				if (!uRV$pb_chart$.__enclos_env__$private$closed) try(uRV$pb_chart$close(), silent = T)
				# uRV$pb_chart <- NULL
				uRV$pb_cnt_chart <- 0
				session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]]$suspend()
			}
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[595][observeEvent][OUT][Progress bar closed]')))
			}
		}
		# ,suspended = T
	)

	#600. User actions
	#610. Once user clicks upon any among the buttons within the Fund Selector
	session$userData[[paste(ns(observer_pfx),'fund_sel',sep='_')]] <- shiny::observeEvent(
		input$uWg_AB_PortAdj_Sel
		,{
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[610][observeEvent][IN][input$uWg_AB_PortAdj_Sel]:<',input$uWg_AB_PortAdj_Sel,'>')))
				}
				#100. Extract the button ID, although it is useless in action monitoring
				btnID <- gsub('^(.+)_\\d+$','\\1',input$uWg_AB_PortAdj_Sel,perl = TRUE)

				#200. Identify the clicked row by extracting the number part from the button ID
				selectedRow <- as.numeric(gsub('^.+_(\\d+)$','\\1',btnID,perl = TRUE))
				# uRV$Prod_Selected <- paste('click on ',dtsrc_Funds[selectedRow,colsDT_ProdSel[[1]]])

				#500. Overwrite the data used to draw the datatable
				uRV$dt_draw[selectedRow,'F_Selected'] <- !uRV$dt_draw[selectedRow,'F_Selected']
				uRV$dt_draw <- uRV$dt_draw %>%
					dplyr::mutate(
						btn_ProdSel = ifelse(
							F_Selected
							,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_ProdSel)
							,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_ProdSel)
						)
					)
				#[Quote: https://github.com/rstudio/DT/pull/480 ]

				#900. Refresh the datatable at frontend, to improve the user experience
				#[Quote: https://community.rstudio.com/t/edit-data-table-in-r-shiny-and-save-the-data-table-to-the-original-dataframe/25355/2 ]
				#[Quote: https://github.com/hinkelman/Shiny-Scorekeeper/blob/master/server.R ] Row #65
				DT::replaceData(
					uRV$proxy_dt_ProdSel
					,uRV$dt_draw
					,resetPaging = FALSE
					#IMPORTANT! Below option is CRUCIAL!
					,rownames = dt_rownames
				)
				#Debug Mode
				if (fDebug){
					fundchk <- uRV$dt_draw %>%
						dplyr::filter(F_Selected) %>%
						dplyr::select_at(paste0('ProdCcy_',lang_disp)) %>%
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
	session$userData[[paste(ns(observer_pfx),'nav_selected',sep='_')]] <- shiny::observeEvent(
		input$FilterAB_Selected
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[623][observeEvent][IN][input$FilterAB_Selected]:<',input$FilterAB_Selected,'>')))
			}
			DT::updateSearch(uRV$proxy_dt_ProdSel, keywords = list(global = '  TRUE  '))
		#End of [observeEvent] at [623]
		}
		,label = ns(paste0('[623]Only display the products selected by the user for comparison'))
	)
	session$userData[[paste(ns(observer_pfx),'nav_nonselected',sep='_')]] <- shiny::observeEvent(
		input$FilterAB_Excluded
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[625][observeEvent][IN][input$FilterAB_Excluded]:<',input$FilterAB_Excluded,'>')))
			}
			DT::updateSearch(uRV$proxy_dt_ProdSel, keywords = list(global = '  FALSE  '))
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
			DT::clearSearch(uRV$proxy_dt_ProdSel)

			#500. Overwrite the data used to draw the datatable
			uRV$dt_draw[['F_Selected']] <- FALSE
			uRV$dt_draw <- uRV$dt_draw %>%
				dplyr::mutate(
					btn_ProdSel = ifelse(
						F_Selected
						,gsub(shiny::icon('square-o'),shiny::icon('check-square-o'),btn_ProdSel)
						,gsub(shiny::icon('check-square-o'),shiny::icon('square-o'),btn_ProdSel)
					)
				)

			#900. Refresh the datatable at frontend, to improve the user experience
			DT::replaceData(
				uRV$proxy_dt_ProdSel
				,uRV$dt_draw
				,resetPaging = FALSE
				#IMPORTANT! Below option is CRUCIAL!
				,rownames = dt_rownames
			)
		#End of [observeEvent] at [627]
		}
		,label = ns(paste0('[627]Clear all selections made by the user'))
	)

	#630. AUM Adjuster
	#631. Pop out the modal when clicking on the [Adjust] button
	session$userData[[paste(ns(observer_pfx),'aum_adj_showmodal',sep='_')]] <- shiny::observeEvent(
		input$uWg_AB_AUM_adj
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[631][observeEvent][IN][input$uWg_AB_AUM_adj]:',input$uWg_AB_AUM_adj)))
			}
			shiny::showModal(uRV$modal_AUM_adj)
		}
		,label = ns('[631]Popup the modal once clicking on the [Adjust] button')
	)

	#635. When clicking upon the [Save] button in the modal of [AUM Adjustment]
	session$userData[[paste(ns(observer_pfx),'aum_adj_upd',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_setAUM

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[635][observe][IN][input$uWg_AB_setAUM]:',input$uWg_AB_setAUM)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_setAUM)) return()
				#Below condition differentiates the below observer by NOT updating the AUM value at initialization
				if (input$uWg_AB_setAUM == 0) return()

				#100. Calculate the difference made by the operation
				AUM_diff <- input$uWg_nI_AUM - uRV$AUM

				#200. Popup an alert if CASA balance is NOT sufficient for subtraction
				#When such case happens, we leave the decision to user instead of superceding the Business logics,
				# such as: futher subtract balance from funds or deposits (which system cannot decide for the customer).
				vfy_Savings <- uRV$Prod_Adjusted %>%
					dplyr::filter(ProdType_EN == 'Savings+') %>%
					dplyr::select(bal_new) %>%
					unlist() %>%
					unname()
				if (round(vfy_Savings + AUM_diff,digits = 2) < 0){
					shinyWidgets::sendSweetAlert(
						session
						,title = lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['Alert_CASAmin']][['Title']]
						,text = lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['Alert_CASAmin']][['Text']]
						,type = 'error'
						,html = FALSE
						#Below option is only applied since [shinyWidgets:0.4.8.930]
						# ,btn_colors = c(color_cfg$CustAct)
						,btn_labels = lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['Alert_CASAmin']][['Return']]
					)

					#Skip the update of AUM amount
					return()
				}

				#500. Update the AUM
				if (round(AUM_diff,digits = 4) != 0){
					#100. Mark the update of the AUM
					uRV$cnt_AUM_upd <- uRV$cnt_AUM_upd + 1

					#500. Update the related variables
					uRV$AUM_new <- input$uWg_nI_AUM
					uRV$AUM_diff <- round(AUM_diff,digits = 4)
					uRV$Prod_Adjusted <- uRV$Prod_Adjusted %>%
						#This condition ensures the changes are made upon the most basic product - CASA
						dplyr::mutate(
							bal_new = ifelse(ProdType_EN == 'Savings+', bal_new + uRV$AUM_diff, bal_new)
							,aum_new = uRV$AUM_new
						) %>%
						dplyr::mutate(
							bal_pct = ifelse(aum_new == 0, 0, bal_new / aum_new)
							,lbl_CN = scaleNum( bal_new , ScaleBase = 10000 , map_units = map_units_CN , scientific = F )$values
							,lbl_EN = scaleNum( bal_new , ScaleBase = 1000 , map_units = map_units_EN , scientific = F )$values
						) %>%
						dplyr::select(-aum_new)

					#800. Refresh the values passed to the widget for minor change of product balance
				}

				#800. Close the modal
				shiny::removeModal()

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[635][observe][OUT][uRV$AUM_new]:',uRV$AUM_new)))
					message(ns(paste0('[635][observe][OUT][uRV$AUM_diff]:',uRV$AUM_diff)))
				}
			#End of [isolate]
			})
		}
		,label = ns('[635]Update the AUM value if the input has changed')
	)

	#637. Create a modal to manually overwrite the AUM value
	#Below observer differentiates the above one by creating the modal at initialization
	session$userData[[paste(ns(observer_pfx),'aum_adj_setmodal',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$df_Reset
			input$uWg_AB_setAUM

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[637][observe][IN][input$uWg_AB_setAUM]:',input$uWg_AB_setAUM)))
				}
				#010. Return if the condition is not valid
				#Since the input tag is NOT created at the inilialization of the module, we need to skip the verification
				# in order to create the UI anyway.
				# if (is.null(input$uWg_AB_setAUM)) return()

				#900. Create a new modal
				uRV$modal_AUM_adj <- shiny::modalDialog(
					shiny::tagList(
						shiny::numericInput(
							ns('uWg_nI_AUM')
							,NULL
							,value = uRV$AUM_new
							,min = 0
							,width = '100%'
						)
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%'
								,uRV$styles_tabBox_font
							)
							,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_adj_modal']][['Notice_Threshold']]
						)
					)
					,title = lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_adj_modal']][['Title']]
					,footer = shiny::tagList(
						shiny::modalButton(lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_adj_modal']][['Cancel']])
						,shiny::actionButton(
							ns('uWg_AB_setAUM')
							,class = 'uAB-theme-m'
							,width = 40
							,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_adj_modal']][['Save']]
						)
					)
				)
			#End of [isolate]
			})
		}
		,label = ns('[637]Create a modal with the updated content')
	)

	#639. Update the UI to display the AUM
	session$userData[[paste(ns(observer_pfx),'aum_adj_ui',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$AUM_new

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[639][observe][IN][uRV$AUM_new]:',uRV$AUM_new)))
				}
				#010. Return if the condition is not valid

				#100. Create the UI to display on the screen
				uRV$span_AUM_disp <- shiny::tags$span(
					style = paste0(''
						,uRV$styles_tabBox_font
						,'padding-left: 4px;'
						,'padding-right: 15px;'
					)
					,shiny::tags$span(shiny::tagList(
						lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM']]
						,shiny::icon('cny')
						,tippy::tippy_this(
							ns('uSpan_AUM_new')
							,paste0(''
								,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_tooltip']]
								,shiny::icon('cny')
								,formatC(
									uRV$AUM
									,digits = 2
									,big.mark = ','
									,format = 'f'
									,zero.print = '0.00'
								)
							)
							,placement = 'top'
							,distance = 2
							,arrow = FALSE
						)
						#Only display the modified AUM
						,shiny::tags$span(
							id = ns('uSpan_AUM_new')
							,formatC(
								uRV$AUM_new
								,digits = 2
								,big.mark = ','
								,format = 'f'
								,zero.print = '0.00'
							)
						#End of [span]
						)
						#Additional display the modifier
						,shiny::tags$span(
							style = paste0('color: ',setNumColor(uRV$AUM_diff),';')
							,paste0(
								' ('
								,formatC(
									uRV$AUM_diff
									,digits = 2
									,big.mark = ','
									,format = 'f'
									,flag = '+'
									,zero.print = '0.00'
								)
								,')'
							)
						#End of [span]
						)
					#End of [span]
					))
				#End of [span]
				)

				#500. Create the UI to be printed
				uRV$knitr_params$print_AUM_adj <- shiny::fluidRow(
					class = 'cpa_fluidRow'
					,style = paste0(''
						,'text-align: right;'
					)
					,uRV$span_AUM_disp
				)

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[639][observe][OUT][uRV$knitr_params]:',length(uRV$knitr_params))))
				}
			#End of [isolate]
			})
		}
		,label = ns('[639]Create the UI to display the AUM')
	)

	#640. Product Balance Adjuster

	#645. When clicking upon the [Save] button in the modal of [Product Balance Adjustment]
	session$userData[[paste(ns(observer_pfx),'bal_adj_upd',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_setbal

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[645][observe][IN][input$uWg_AB_setbal]:',input$uWg_AB_setbal)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_setbal)) return()
				#Below condition differentiates the below observer by NOT updating the product balance at initialization
				if (input$uWg_AB_setbal == 0) return()

				#100. Mark the update of the AUM
				uRV$cnt_bal_upd <- uRV$cnt_bal_upd + 1

				#500. Update the related variables
				txt_frJSON <- jsonlite::fromJSON(input$uWg_SG_baladj)
				uRV$Prod_Adjusted$bal_new <- sapply(txt_frJSON, function(m){m$value})
				# tmp <- uRV$Prod_Adjusted[which(uRV$Prod_Adjusted$ProdCcy_EN == 'Alternative Structured Product-BCY'),'bal_new']
				# uRV$Prod_Adjusted[which(uRV$Prod_Adjusted$ProdCcy_EN == 'Alternative Structured Product-BCY'),'bal_new'] <- tmp + 500000
				# tmp <- uRV$Prod_Adjusted[which(uRV$Prod_Adjusted$ProdCcy_EN == 'USD Bond MF-USD'),'bal_new']
				# uRV$Prod_Adjusted[which(uRV$Prod_Adjusted$ProdCcy_EN == 'USD Bond MF-USD'),'bal_new'] <- tmp - 500000

				#800. Close the modal
				shiny::removeModal()

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[645][observe][OUT][uRV$Prod_Adjusted]: Update successful')))
				}
			#End of [isolate]
			})
		}
		,label = ns('[645]Update the product balance if the input has changed')
	)

	#649. Create a modal to adjust the product balance
	#Below observer differentiates the above one by creating the modal at initialization
	session$userData[[paste(ns(observer_pfx),'bal_adj_setmodal',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_bal_adj

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[649][observe][IN][input$uWg_AB_bal_adj]:',input$uWg_AB_bal_adj)))
				}
				#010. Return if the condition is not valid
				#Since the input tag is NOT created at the inilialization of the module, we need to skip the verification
				# in order to create the UI anyway.
				if (is.null(input$uWg_AB_bal_adj)) return()

				#100. Prepare the data for the creation of slider group
				json_pre <- uRV$Prod_Adjusted %>%
					dplyr::mutate(
						ProdCcy_EN = gsub('^Saving Account$','huodongzijin',ProdCcy_EN)
					) %>%
					dplyr::mutate(
						id = ProdCcy_EN
						,value = bal_new
						,isListen = T
					) %>%
					dplyr::rename(
						'title' = paste0('ProdCcy_',lang_disp)
					) %>%
					dplyr::select('id','title','value','isListen') %>%
					as.data.frame()

				#200. Convert the data to JSON character string
				json_list <- lapply(
					seq_len(nrow(json_pre))
					,function(m){
						paste0(
							#Add a header to each group as per requested by the HTML widget introduced into this module
							'"',json_pre[m,'id'],'":'
							,gsub('^\\[(.*)\\]$','\\1',jsonlite::toJSON(json_pre[m,], digits = NA), perl = T)
						)
					}
				)
				json_ToWidget <- paste0('{',paste0(json_list,collapse = ','),'}')

				#400. Translate the HTML interface
				widgetfile <- file(Wg_SliderGrp, 'rt', encoding = 'utf-8')
				widgetcode <- readLines(widgetfile)
				close(widgetfile)
				uRV$ID_uSG <- paste0('uSG','_',floor(runif(1) * 10^6))
				widgetcode <- gsub('\\*\\*\\*APP\\*\\*\\*',uRV$ID_uSG,widgetcode)
				widgetcode <- gsub('\\*\\*\\*ID\\*\\*\\*',ns('uWg_SG_baladj'),widgetcode)
				widgetcode <- gsub('\\*\\*\\*DATA\\*\\*\\*',json_ToWidget,widgetcode)
				SliderGroup <- paste0(widgetcode,collapse = '\n')

				#900. Create a new modal
				uRV$modal_bal_adj <- shiny::modalDialog(
					shiny::tagList(
						shiny::fluidRow(
							class = 'cpa_fluidRow'
							,shiny::HTML(SliderGroup)
						)
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%'
								,uRV$styles_tabBox_font
							)
							,shiny::tags$div(lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_modal']][['Notice_Threshold']])
							,shiny::tags$div(lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_modal']][['Notice_Prod']])
							,shiny::tags$div(lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_modal']][['Notice_CASA']])
						)
					)
					,title = lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_modal']][['Title']]
					,footer = shiny::tagList(
						shiny::modalButton(lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_modal']][['Cancel']])
						,shiny::actionButton(
							ns('uWg_AB_setbal')
							,class = 'uAB-theme-m'
							,width = 40
							,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_modal']][['Save']]
							,onclick = paste0('Shiny.setInputValue("',ns('uWg_SG_baladj'),'", document.getElementById("',ns('uWg_SG_baladj'),'").value);console.log("',ns('uWg_SG_baladj'),'");')
						)
					)
				)
			#End of [isolate]
			})
		}
		,label = ns('[649]Create a modal with the updated content')
	)

	#641. Pop out the modal when clicking on the [Minor] button
	session$userData[[paste(ns(observer_pfx),'bal_adj_showmodal',sep='_')]] <- shiny::observeEvent(
		input$uWg_AB_bal_adj
		,{
			#Debug Mode
			if (fDebug){
				message(ns(paste0('[641][observeEvent][IN][input$uWg_AB_bal_adj]:',input$uWg_AB_bal_adj)))
			}
			shiny::showModal(uRV$modal_bal_adj)
		}
		,label = ns('[641]Popup the modal once clicking on the [Minor] button')
	)

	#695. Determine when to save the state for later loading, literally after the respective states are updated
	session$userData[[paste(ns(observer_pfx),'save_state',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$AUM_new
			uRV$PortAdj_Selected
			uRV$Prod_Adjusted

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#010. Return if the condition is not valid
				if (all(is.null(uRV$AUM_new),is.null(uRV$PortAdj_Selected),is.null(uRV$Prod_Adjusted))) return()
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[695][observe][IN][uRV$AUM_new]:',uRV$AUM_new)))
					message(ns(paste0('[695][observe][IN][uRV$PortAdj_Selected]:')))
					dplyr::glimpse(uRV$PortAdj_Selected)
					message(ns(paste0('[695][observe][IN][uRV$Prod_Adjusted]:')))
					dplyr::glimpse(uRV$Prod_Adjusted)
				}

				#500. Flag the user action
				uRV$SaveState <- uRV$SaveState + 1

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[695][observe][OUT][uRV$SaveState]:',uRV$SaveState)))
				}
			#End of [isolate]
			})
		}
		,label = ns('[695]Mark the state to be saved')
	)

	#700. Create UI
	#710. Create the Product Selector
	output$dt_Prods <- DT::renderDT({
		#Render UI
		uRV$dt_Prods_pre
	})
	#There is no need to add [ns] to the proxy, for it will be added inside [DT]
	uRV$proxy_dt_ProdSel <- DT::dataTableProxy('dt_Prods')

	output$ProdSelector <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[710][renderUI][IN][output$ProdSelector]')))
		}

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$dt_styles_DTables
			)
			#Quote: Xie Yihui published this solution on the topic: [Icons in a datatable (DT)] in forum [Google Groups]
			#[shiny::icon()] uses the font-awesome library by default, and shiny does not really know the dependency
			# on font-awesome unless at least one icon has been rendered in the shiny UI.
			#In this case, the [as.character()] function masks the function [shiny::icon()], so shiny has no idea the
			# app depends on font-awesome (the dependency info is lost through [as.character()])
			#The other solution is to use glyphicon library as walk-around.
			,shiny::tags$span(shiny::icon('archive'), style = 'display: none;')
			,DT::DTOutput(ns('dt_Prods'))
		)
	})

	#720. Create UI to display and modify the AUM
	#721. A text box to display the AUM with a button to trigger the modification modal to show up
	output$uDiv_AUMadj <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[721][renderUI][IN][output$AUM_adj]')))
		}

		#Take dependency from below action (without using its value):

		#008. Create a progress bar to notify the user when a large dataset is being loaded for chart drawing
		shiny::isolate({
			uRV$pb_chart <- shiny::Progress$new(session, min = 0, max = uRV$pb_k$chart)
			session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]]$resume()

			#Start to display the progress bar
			uRV$pb_chart$set(message = paste0('Portfolio Adjustment [2/',uRV$pb_k_all,']'))

			#Increment the progress bar
			#[Quote: https://nathaneastwood.github.io/2017/08/13/accessing-private-methods-from-an-r6-class/ ]
			#[Quote: https://github.com/rstudio/shiny/blob/master/R/progress.R ]
			if (is.environment(uRV$pb_chart$.__enclos_env__$private)) if (!uRV$pb_chart$.__enclos_env__$private$closed){
				val <- uRV$pb_chart$getValue()+1
				uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']Holding Adjustment'))
				uRV$pb_cnt_chart <- shiny::isolate(uRV$pb_cnt_chart) + 1
			}
		})

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)

			,shiny::fluidRow(
				class = 'cpa_fluidRow'
				,shiny::fillRow(
					flex = c(1,NA)
					,height = 24
					,shiny::uiOutput(ns('uDiv_AUM_disp'))
					,shiny::tags$span(
						style = paste0('padding: 0;')
						,tippy::tippy_this(
							ns('uWg_AB_AUM_adj')
							,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_adj_tooltip']]
							,placement = 'right'
							,distance = 2
							,arrow = FALSE
						)
						,shiny::actionButton(
							ns('uWg_AB_AUM_adj')
							,class = 'uAB-theme-xs'
							,width = 56
							,icon = shiny::icon('pencil-square-o')
							,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['AUM_adj']]
						)
					#End of [span]
					)
				#End of [fillRow]
				)
			#End of [fluidRow]
			)

			,shiny::fluidRow(
				class = 'cpa_fluidRow'
				,style = paste0(''
					#Set [position] as [relative] enables the sub-divisions to be placed at absolute position.
					,'position: relative;'
				)
				,echarts4r::echarts4rOutput(ns('EchOut_BalAdj'), height = uRV$ch_height_BalAdj)
				,shiny::tags$div(
					style = paste0(''
						,'position: absolute;'
						,'top: 0px;'
						,'right: 15px;'
					)
					,tippy::tippy_this(
						ns('uWg_AB_bal_adj')
						,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj_tooltip']]
						,placement = 'right'
						,distance = 2
						,arrow = FALSE
					)
					,shiny::actionButton(
						ns('uWg_AB_bal_adj')
						,class = 'uAB-theme-xs'
						,width = 56
						,icon = shiny::icon('sliders')
						,lang_cfg[[lang_disp]][['rptsecs']][['PortAdj']][['bal_adj']]
					)
				)
			)
		#End of [tagList]
		)
	#End of [renderUI]
	})

	#722. Sub-division that has dependencies at rendering
	output$uDiv_AUM_disp <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[722][renderUI][IN][output$uDiv_AUM_disp]')))
		}

		#900. Create the UI
		uRV$span_AUM_disp
	#End of [renderUI]
	})

	#750. Table to display the P&L comparison
	output$dt_PnL_Disp <- DT::renderDT({
		#Take dependency
		uRV$dt_PnL

		#Increment the progress bar
		shiny::isolate({
			if (is.environment(uRV$pb_chart$.__enclos_env__$private)) if (!uRV$pb_chart$.__enclos_env__$private$closed){
				val <- uRV$pb_chart$getValue()+1
				uRV$pb_chart$inc(amount = 1, detail = paste0('[',val,'/',uRV$pb_k$chart,']P&L Comparison'))
				uRV$pb_cnt_chart <- shiny::isolate(uRV$pb_cnt_chart) + 1
			}
			# on.exit(try(uRV$pb_chart$close(), silent = T))
		})

		#Render UI
		uRV$dt_PnL
	})

	output$uDiv_ProfitByProdType <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[750][renderUI][IN][output$uDiv_ProfitByProdType]')))
		}

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shiny::tags$style(
				type = 'text/css'
				,uRV$dt_styles_DTables
			)
			,shiny::fluidRow(class = 'cpa_fluidRow', DT::DTOutput(ns('dt_PnL_Disp')))
		)
	})

	#770. Text advisory
	output$uDiv_Advise <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[770][renderUI][IN][output$uDiv_Advise]')))
		}

		shiny::tagList(
			uRV$knitr_params$print_txt_Advisory

			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			,shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shiny::fluidRow(
				class = 'cpa_fluidRow'
				,style = paste0(''
					,'text-align: right;'
				)
				,tippy::tippy_this(
					ns('uWg_AB_Reset')
					,lang_cfg[[lang_disp]][['rptsecs']][['Advisory']][['Reset_tooltip']]
					,placement = 'top'
					,distance = 2
					,arrow = FALSE
				)
				,shiny::actionButton(
					ns('uWg_AB_Reset')
					,class = 'uAB-theme-m'
					,icon = shiny::icon('refresh')
					,lang_cfg[[lang_disp]][['rptsecs']][['Advisory']][['Reset']]
				)
			#End of [fluidRow]
			)
		)
	})

	#790. Final UI
	#797. Combine all charts
	output$uDiv_ProdSel <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[797][renderUI][IN][output$uDiv_ProdSel]')))
		}

		shiny::tagList(
			#This is to set the styles for the [sweet alert], as it is placed ahead of all tags in the main page.
			shiny::tags$head(
				shiny::tags$style(
					type = 'text/css'
					,uRV$modal_styles_Dialog
				)
			)
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			,shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			,shiny::fluidRow(class = 'cpa_fluidRow', shiny::uiOutput(ns('ProdSelector')))
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
			,'shiny', 'dplyr', 'tidyselect', 'htmltools', 'V8', 'htmlwidgets', 'shinyWidgets', 'tippy', 'DT', 'echarts4r', 'jsonlite'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		#We use [file.path] to create path names instead of using [paste], to set compatibility of different OS.
		omniR <- 'D:\\R\\omniR'
		js_vue <- list.files( omniR , '^vue.*\\.js$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE ) %>%
			normalizePath()
		source(normalizePath(file.path(omniR,'AdvOp','scaleNum.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','rem_shiny_inputs.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','gc_shiny_module.r')),encoding = 'utf-8')
		shinyjs_ext <- normalizePath(file.path(omniR,'UsrShinyModules','shinyjsExtension.js'))
		Ech_ext_utils <- normalizePath(file.path(omniR,'UsrShinyModules','echarts_ext_utils.js'))
		Wg_SliderGrp <- normalizePath(file.path(omniR,'Visualization','Widget_SliderGroup.html'))
		file_vue <- gsub('^.*\\\\(.+?)$','\\1',js_vue)
		file_shinyjs_ext <- gsub('^.*\\\\(.+?)$','\\1',shinyjs_ext)
		file_ech_ext <- gsub('^.*\\\\(.+?)$','\\1',Ech_ext_utils)

		#Load necessary data
		myProj <- 'D:\\R\\Project'
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','theme_color_sets.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Data','Test_PortMgmt_LoadData.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','lang_PortMgmt.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','color_PortMgmt.r')), encoding = 'utf-8')

		#Add resource directory for loading the scripts
		wd <- getwd()
		myApp <- 'tmpApp'
		dir_www <- file.path(wd,'www') %>% normalizePath()
		#[Quote: https://github.com/rstudio/shiny/issues/578 ]
		#In an app with full path, there is a resource path set as [getwd()/www], while such path is not added in a temporary app.
		#That is why we need to manually add such resource path in a testing program.
		if (!dir.exists(dir_www)) dir.create(dir_www, showWarnings = F, recursive = T)
		shiny::addResourcePath(myApp,dir_www)

		#Copy the scripts to working directory
		path_js <- 'script'
		dir_js <- file.path(dir_www,path_js) %>% normalizePath()
		if (!dir.exists(dir_js)) dir.create(dir_js, showWarnings = F, recursive = T)
		file.copy(js_vue, dir_js, overwrite = TRUE)
		file.copy(shinyjs_ext, dir_js, overwrite = TRUE)
		file.copy(Ech_ext_utils, dir_js, overwrite = TRUE)

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
				#Introduce the core library of [JQuery]
				#[Quote: https://stackoverflow.com/questions/5445491/height-equal-to-dynamic-width-css-fluid-layout?noredirect=1 ]
				#Below script is only valid when a complete APP is created.
				#In that case, the script file should be placed under any one of the [shiny::resourcePaths()]
				#e.g. If a script file is under directory: [www/script/aa.js],
				# the [src] attribute should be set as: ['script/aa.js']
				,shiny::tags$script(
					type = 'text/javascript'
					,src = paste(myApp,path_js,file_vue,sep = '/')
					,charset = 'utf-8'
				)
				,shiny::tags$script(
					type = 'text/javascript'
					,src = paste(myApp,path_js,file_ech_ext,sep = '/')
					,charset = 'utf-8'
				)
				#It is tested that the location of the call [extendShinyjs] is under [getwd()], instead of any pre-defined location.
				,shinyjs::extendShinyjs(script = paste('www',path_js,file_shinyjs_ext,sep = '/'))
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
			modout$mCPA <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0)
				,ActionDone = shiny::reactive({FALSE})
				,EnvVariables = shiny::reactive({NULL})
			)

			output$modUI0 <- shiny::renderUI({UM_CPA_ui_ProdSel(modout$ID_Mod)})
			output$modUI1 <- shiny::renderUI({UM_CPA_ui_AUMadj(modout$ID_Mod)})
			output$modUI2 <- shiny::renderUI({UM_CPA_ui_ProfitByProdType(modout$ID_Mod)})
			output$modUI3 <- shiny::renderUI({UM_CPA_ui_Advise(modout$ID_Mod)})

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
						# modout$ID_Mod <- paste0('CPA','_',floor(runif(1) * 10^6))
						modout$ID_Mod <- paste0('CPA','_',1)

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

						modout$mCPA <- shiny::callModule(
							UM_custPortAdj_svr
							,modout$ID_Mod
							,CustData = uRV$PM_rpt
							,f_loadstate = T
							,lang_cfg = lang_CPM
							,color_cfg = color_CPM
							,lang_disp = lang_disp
							,font_disp = 'Microsoft YaHei'
							,Ech_ext_utils = Ech_ext_utils
							,Wg_SliderGrp = Wg_SliderGrp
							,observer_pfx = 'uObs'
							,fDebug = FALSE
						)

						modout$params <- modout$mCPA$EnvVariables()$knitr_params
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
			shiny::observeEvent(modout$mCPA$CallCounter(),{
				if (modout$mCPA$CallCounter() == 0) return()
				message('[mCPA$CallCounter()]:',modout$mCPA$CallCounter())
			})

			#Clear the extra files
			session$onSessionEnded(
				function(){
					#100. Remove the scripts if any
					#110. JQuery core script

					#130. Vue core script
					tmpjs_vue <- file.path(dir_js,file_vue) %>% normalizePath()
					if (file.exists(tmpjs_vue)) file.remove(tmpjs_vue)

					#150. shinyjs extension
					tmpjs_shinyjs_ext <- file.path(dir_js,file_shinyjs_ext) %>% normalizePath()
					if (file.exists(tmpjs_shinyjs_ext)) file.remove(tmpjs_shinyjs_ext)

					#170. Echarts extensive utilities
					tmpjs_ech_ext <- file.path(dir_js,file_ech_ext) %>% normalizePath()
					if (file.exists(tmpjs_ech_ext)) file.remove(tmpjs_ech_ext)

					#800. Remove the directories if empty
					#[Quote: https://stackoverflow.com/questions/21576944/fast-test-if-directory-is-empty ]
					#[Quote: https://stackoverflow.com/questions/28097035/how-to-remove-a-directory-in-r ]
					#810. Remove the [script] directory
					# if (length(dir(dir_js, all.files = T, recursive = T)) == 0) unlink(dir_js, recursive = T)

					#850. Remove the [www] directory
					# if (length(dir(dir_www, all.files = T, recursive = T)) == 0) unlink(dir_www, recursive = T)

					#890. Remove the resource path
					shiny::removeResourcePath(myApp)

					#999. Stop the app
					stopApp()
				}
			)
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
