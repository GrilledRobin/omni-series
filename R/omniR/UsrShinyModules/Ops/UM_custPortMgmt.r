#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This module is designed for below purposes:                                                                                        #
#   |[1]Display the customer individual report of AUM and Gain/Loss by products                                                         #
#   |[2]Enable customization upon product balances with interactive simulation                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 客户经理查看客户在我行资产分布以及近期盈亏情况                                                                                 #
#   |[2] 客户经理与客户讨论基金持仓及调仓策略                                                                                           #
#   |[3] 调整客户在我行资产分布并模拟近期盈亏                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CustData      :   The vector/list of various data regarding one specific customer, details are as below:                           #
#   |                   [Rpt_Logo         ]    <Chr>        The URL address to display the logo for the entire report                   #
#   |                   [CIFNO            ]    <Chr>        Customer Information Number, which stands for the unique customer ID in the #
#   |                                                        company                                                                    #
#   |                   [PhotoURL         ]    <Chr>        The URL address to display the customer photo                               #
#   |                   [custinf          ]    <data.frame> Customer level data for displaying of various attributes                    #
#   |                   [Bal_ProdCat      ]    <data.frame> Summary data for drawing the chart of AUM by Product Category               #
#   |                   [Bal_RiskLvl      ]    <data.frame> Summary data for drawing the chart of AUM by Product Risk Level             #
#   |                   [Bal_ProdType     ]    <data.frame> Summary data for drawing the chart of AUM by Product Type                   #
#   |                   [Bal_FundName     ]    <data.frame> Summary data for drawing the chart of Product Balance by Fund Name          #
#   |                   [Prod_Dep         ]    <data.frame> Account level data for drawing the datatable of Deposit products            #
#   |                   [Prod_Inv         ]    <data.frame> Account level data for drawing the datatable of Investment products         #
#   |                   [Prod_MF          ]    <data.frame> Account level data for drawing the datatable of Mutual Fund products        #
#   |                   [Prod_Bnc         ]    <data.frame> Account level data for drawing the datatable of Bancasurance products       #
#   |                   [Bal_ProdCTT      ]    <data.frame> Summary data for drawing the chart of CTT Distribution by Fund products     #
#   |                   [CurrDate         ]    <Date>       The date value that represents the reporting date                           #
#   |                   [Fund_Sel         ]    <data.frame> Historical data for customer cost, fund prices and predictions if any       #
#   |                   [NumFmt_Currency  ]    <vector>     Vector of field names that will be displayed in the format: #,#00,00        #
#   |                   [NumFmt_Percent   ]    <vector>     Vector of field names that will be displayed in the format: #00,00%         #
#   |                   [NumFmt_Price     ]    <vector>     Vector of field names that will be displayed in the format: #00,0000        #
#   |                   [NumFmt_PnL       ]    <vector>     Vector of field names that will be displayed in opposite colors             #
#   |                   [CustRate_Prod    ]    <data.frame> Snapshot data with expected customer rate by products                       #
#   |                   [Prod_Acct        ]    <data.frame> MTD data of customer P&L at account level                                   #
#   |lang_cfg      :   Language configuration for Customer Portfolio Management                                                         #
#   |color_cfg     :   Color configuration for this module                                                                              #
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
#   |...           :   Parameters inherited from the dependent modules. See documents for them respectively                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |800.   Naming Convention.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CPM           :   Customer Portfolio Management                                                                                    #
#   |uDiv          :   User defined HTML Tag as Division (similar names would be: [uRow], [uCol], etc.)                                 #
#   |uWg           :   User defined Widgets                                                                                             #
#   |PO            :   User defined shinyBS:bsPopover                                                                                   #
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
#   | Date |    20200323        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200419        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add a parameter [color_cfg] to unify the color settings for all related modules                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200509        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |shiny, rmarkdown, pagedown, shinyWidgets                                                                                       #
#   |   |(inherited from [UM_custPortDash])       DT, shinydashboard, shinydashboardPlus, echarts4r, htmlwidgets, htmltools, V8, dplyr  #
#   |   |                                         , tidyselect, data.table, grDevices                                                   #
#   |   |(inherited from [UM_FundExp])            lubridate                                                                             #
#   |   |(inherited from [UM_custPortAdj])        tippy, jsonlite                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Directory: [omniR$Styles]                                                                                                      #
#   |   |   |rgba2rgb                                                                                                                   #
#   |   |Directory: [omniR$AdvOp]                                                                                                       #
#   |   |   |scaleNum                                                                                                                   #
#   |   |   |gc_shiny_module                                                                                                            #
#   |   |   |   |rem_shiny_inputs      [Dependency of above function]                                                                   #
#   |   |Directory: [omniR$UsrShinyModules]                                                                                             #
#   |   |   |echarts_ext_utils.js      [Quote: This is a JS function library! Please use [tags$script] to activate it!]                 #
#   |   |   |vue.js                    [Quote: This is a JS function library! Please use [tags$script] to activate it!]                 #
#   |   |   |shinyjsExtension.js       [Quote: This is a JS function library! Please use [shinyextendjs] to activate it!]               #
#   |   |Directory: [omniR$Visualization]                                                                                               #
#   |   |   |Widget_SliderGroup.html   [Quote: This is an HTML widget powered by [vue.js]!]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Dependent user-defined Modules                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Directory: [omniR$UsrShinyModules$Ops]                                                                                         #
#   |   |   |UM_custPortDash                                                                                                            #
#   |   |   |UM_FundExp                                                                                                                 #
#   |   |   |   |UM_FundCompare (called by above module)                                                                                #
#   |   |   |UM_custPortAdj                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, rmarkdown, pagedown, shinyWidgets
	, DT, shinydashboard, shinydashboardPlus, echarts4r, htmlwidgets, htmltools, V8, dplyr, tidyselect, data.table, grDevices
	, lubridate
	, tippy, jsonlite
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

UM_CPM_ui_toolbox <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('uDiv_CPM'))
}

UM_CPM_ui_PortDash <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('ui_PortDash'))
}

UM_CPM_ui_FundExp <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('ui_FundExp'))
}

UM_CPM_ui_AUMadj <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('ui_AUMadj'))
}

UM_CPM_ui_PnLAdvise <- function(id){
	#Set current Name Space
	ns <- NS(id)

	shiny::uiOutput(ns('ui_PnLadvise'))
}

UM_custPortMgmt_svr <- function(input,output,session
	,CustData = NULL
	,lang_cfg = NULL,color_cfg = NULL
	,font_disp = 'Microsoft YaHei'
	,observer_pfx = 'uObs'
	,fDebug = FALSE,...){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	uRV$lang_disp <- 'CN'
	uRV$font_list <- c('Microsoft YaHei','Helvetica','sans-serif','Arial','宋体')
	uRV$font_list_css <- paste0(
		sapply(uRV$font_list, function(m){if (length(grep('\\W',m,perl = T))>0) paste0('"',m,'"') else m})
		,collapse = ','
	)
	font_disp <- match.arg(font_disp,uRV$font_list)
	params_ext <- list(...)
	#Duplicate the input as it is designed to be able to 'rollback' any actions
	#[chb] : Charting Base
	uRV$chb <- CustData
	uRV$f_chb <- 0
	uRV$Counter_lang <- 0
	uRV$Counter_CPD <- 0
	uRV$Counter_FE <- 0
	#Below counter of the call to module [Customer Portfolio Adjustment] should be created after call of [Fund Explorer]
	# uRV$Counter_CPA <- 0
	uRV$knitr_params <- list(
		lang_cfg = lang_cfg
	)
	uRV$lang_selector <- c(
		'CN' = TRUE
		,'EN' = FALSE
	)
	uRV$params_CPD <- c(
		'print_Profile'
		,'print_ProdType'
		,'print_CTT'
		,'print_span_AllPnL'
		,'print_dt_Prods_hdr'
		,'print_dt_Prods'
	)
	uRV$params_FE <- c(
		'print_CostPnL'
		,'print_FundPrice'
		,'print_FundPnL'
	)
	uRV$params_CPA <- c(
		'print_AUM_adj'
		,'print_ch_BalAdj'
		,'print_dt_PnL'
		,'print_txt_Advisory'
	)
	uRV$ActionDone <- shiny::reactive({FALSE})
	uRV_finish <- shiny::reactiveVal(0)
	uRV$mCPD <- shiny::reactiveValues(
		CallCounter = shiny::reactiveVal(0)
		,ActionDone = shiny::reactive({FALSE})
		,EnvVariables = shiny::reactive({NULL})
	)
	uRV$mFE <- shiny::reactiveValues(
		CallCounter = shiny::reactiveVal(0)
		,ActionDone = shiny::reactive({FALSE})
		,EnvVariables = shiny::reactive({NULL})
	)
	uRV$mCPA <- shiny::reactiveValues(
		CallCounter = shiny::reactiveVal(0)
		,ActionDone = shiny::reactive({FALSE})
		,EnvVariables = shiny::reactive({NULL})
	)
	# fDebug <- TRUE
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[Module Call][UM_custPortMgmt]')))
	}

	#005. Check parameters
	#We do not return values to break the chain of the subsequent processes.
	if (is.null(CustData)) stop(ns(paste0('[005]Crucial input data [CustData] is not provided!')))
	if (length(CustData) == 0) stop(ns(paste0('[005]Crucial input data [CustData] has no content!')))

	#200. General settings of styles for the output UI

	#212. Font Size of chart items
	uRV$styles_ch_FontSize_title <- 14
	uRV$styles_ch_FontSize_item <- 10

	#220. Prepare the styles for Report Title
	uRV$class_Rpt_Title <- paste0(''
		,'.uDiv-title {'
			,'font-family: "',font_disp,'";'
			,'padding-left: 16px;'
			,'margin-top: 8px;'
			,'margin-bottom: 0px;'
		,'}'
	)

	#221. Prepare the styles for Report Sections
	uRV$class_Rpt_Section <- paste0(''
		,'.uDiv-section {'
			,'font-family: "',font_disp,'";'
			,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_title),';'
			,'font-weight: bold;'
			,'padding-left: 8px;'
			,'margin-top: 8px;'
			,'margin-bottom: 0px;'
		,'}'
	)

	#223. Prepare the styles for copyright
	uRV$class_Copyright <- paste0(''
		,'.uDiv-copyright {'
			,'font-family: "',font_disp,'";'
			,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
			,'padding-left: 16px;'
			,'margin-top: 0px;'
			,'margin-bottom: 4px;'
		,'}'
	)

	#224. Prepare the styles for data update date
	uRV$class_d_update <- paste0(''
		,'.uDiv-d-update {'
			,'font-family: "',font_disp,'";'
			,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
			,'margin-top: 0px;'
			,'margin-bottom: 4px;'
		,'}'
	)

	#225. Prepare the styles for [Powered By]
	uRV$class_PoweredBy <- paste0(''
		,'.uDiv-poweredby {'
			,'font-family: "',font_disp,'";'
			,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
			,'padding-right: 8px;'
			,'margin-top: 0px;'
			,'margin-bottom: 4px;'
		,'}'
	)

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(''
			,uRV$class_Rpt_Title
			,uRV$class_Rpt_Section
			,uRV$class_Copyright
			,uRV$class_d_update
			,uRV$class_PoweredBy
			#Add styles to the action buttons
			,'.uAB-theme-s {'
				,'text-align: center;'
				,'padding: 2px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$CustAct,';'
				,'font-family: ',font_disp,';'
				,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
			,'}'
			#Add hover effect to the action buttons
			,'.uAB-theme-s.hover, .uAB-theme-s:focus, .uAB-theme-s:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			#Add horizontal margin
			,'.uAB-theme-s {'
				,'text-align: left;'
				,'margin: 0px 4px;'
			,'}'

			#Modify the styles for the [prettyToggle] inside the [toolbox] division
			,'#',ns('cpm_toolbox'),' .form-group {'
				,'text-align: center;'
				,'padding: 2px 4px;'
				,'margin: 0;'
				,'border: none;'
				,'border-radius: 2px;'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$CustAct,';'
				,'font-family: ',font_disp,';'
				,'font-size: ',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),';'
			,'}'
			#Add hover effect to the prettyToggle buttons
			,'#',ns('cpm_toolbox'),' .form-group.hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			,'#',ns('cpm_toolbox'),' .form-group:focus {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			,'#',ns('cpm_toolbox'),' .form-group:hover {'
				,'color: ',color_cfg$UsrTitle,';'
				,'background-color: ',color_cfg$ActBtnHover,';'
			,'}'
			#Add horizontal margin
			,'#',ns('cpm_toolbox'),' .form-group {'
				,'text-align: left;'
				,'margin: 0px 4px !important;'
			,'}'
			#Remove margin of the [.pretty] class
			,'#',ns('cpm_toolbox'),' .form-group>.pretty {'
				,'margin: 0px;'
			,'}'

			,'.cpm_Box {padding: 2px 15px 2px 15px;}'
			,'.cpm_fluidRow {padding: 2px 0px;}'
			,'.cpm_Column {'
				,'padding: 0px;'
			,'}'
		)
	)

	#300. Manipulate the internal data
	#301. Determine when to increment the counter of data manipulation
	session$userData[[paste(ns(observer_pfx),'flag_changebase',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ResetAll
			input$uWg_AB_ConfChg
			input$uWg_pT_Lang

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[301][observe][IN][input$uWg_AB_ResetAll]:',input$uWg_AB_ResetAll)))
					message(ns(paste0('[301][observe][IN][input$uWg_AB_ConfChg]:',input$uWg_AB_ConfChg)))
					message(ns(paste0('[301][observe][IN][input$uWg_pT_Lang]:',input$uWg_pT_Lang)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ResetAll)) return()
				if (input$uWg_AB_ResetAll == 0) return()
				if (is.null(input$uWg_AB_ConfChg)) return()
				if (input$uWg_AB_ConfChg == 0) return()

				#600. Flag the operation
				uRV$f_chb <- uRV$f_chb + 1
			#End of [isolate]
			})
		}
		,label = ns('[301]Reset the base for charting')
	)

	#305. Reset the base for charting once user clicks [Reset]
	session$userData[[paste(ns(observer_pfx),'reset',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ResetAll

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[305][observe][IN][input$uWg_AB_ResetAll]:',input$uWg_AB_ResetAll)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ResetAll)) return()
				if (input$uWg_AB_ResetAll == 0) return()

				#500. Reset the environment
				uRV$chb <- CustData
			#End of [isolate]
			})
		}
		,label = ns('[305]Reset the base for charting')
	)

	#307. Update the base for charting once user clicks [Confirm]
	session$userData[[paste(ns(observer_pfx),'conf_chg',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_ConfChg

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[307][observe][IN][input$uWg_AB_ConfChg]:',input$uWg_AB_ConfChg)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_ConfChg)) return()
				if (input$uWg_AB_ConfChg == 0) return()

				#600. Flag the operation
			#End of [isolate]
			})
		}
		,label = ns('[307]Update the base for charting when confirm the changes')
	)

	#310. Switch between the languages
	session$userData[[paste(ns(observer_pfx),'chg_lang',sep='_')]] <- shiny::observeEvent(
		#100. Take dependencies
		input$uWg_pT_Lang
		,{

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[310][observe][IN][input$uWg_pT_Lang]:',input$uWg_pT_Lang)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_pT_Lang)) return()

				#050. Return if the button has a value as the same as current one
				if (uRV$lang_disp==names(uRV$lang_selector)[which(uRV$lang_selector==input$uWg_pT_Lang)]) return()

				#100. Switch the language
				uRV$lang_disp <- names(uRV$lang_selector)[which(uRV$lang_selector==input$uWg_pT_Lang)]

				#800. Flag the operation
				uRV$Counter_lang <- uRV$Counter_lang + 1
				uRV$Counter_CPD <- uRV$Counter_CPD + 1
				uRV$Counter_FE <- uRV$Counter_FE + 1
				# uRV$Counter_CPA <- uRV$Counter_CPA + 1
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[310][observe][OUT][uRV$lang_disp]:',uRV$lang_disp)))
					message(ns(paste0('[310][observe][OUT][uRV$Counter_lang]:',uRV$Counter_lang)))
					message(ns(paste0('[310][observe][OUT][uRV$Counter_CPD]:',uRV$Counter_CPD)))
					message(ns(paste0('[310][observe][OUT][uRV$Counter_FE]:',uRV$Counter_FE)))
					# message(ns(paste0('[310][observe][OUT][uRV$Counter_CPA]:',uRV$Counter_CPA)))
					message(ns(paste0('[310][observe][OUT][uRV$chb$FundLst_toDrawCH]:<'
						,paste0(uRV$chb$FundLst_toDrawCH,collapse = '>,<')
						,'>'
					)))
				}
			#End of [isolate]
			})
		}
		,ignoreNULL = TRUE
		,ignoreInit = TRUE
		,label = ns('[310]Switch between the languages')
	)

	#350. When user completes the fund selection
	#355. Update the parameters for printing
	session$userData[[paste(ns(observer_pfx),'fund_selected',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$mFE$EnvVariables()$FundLst_toDrawCH

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[355][observe][IN][uRV$mFE$EnvVariables()$FundLst_toDrawCH]:<'
						,paste0(uRV$mFE$EnvVariables()$FundLst_toDrawCH,collapse = '>,<')
						,'>'
					)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$mFE$EnvVariables()$FundLst_toDrawCH)) return()

				#100. Only get the reactive value once to reduce the system calculation effort.
				getparams <- uRV$mFE$EnvVariables()

				#200. Save the current state of fund selection
				uRV$chb$FundLst_toDrawCH <- getparams$FundLst_toDrawCH
				uRV$FundLst_for_CPA <- uRV$chb$FundLst_toDrawCH

				#600. Export the parameters for printable version once the above module is called
				sapply(uRV$params_FE, function(m) uRV$knitr_params[[m]] <- getparams$knitr_params[[m]])
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[355][observe][OUT][uRV$chb$FundLst_toDrawCH]:<'
						,paste0(uRV$chb$FundLst_toDrawCH,collapse = '>,<')
						,'>'
					)))
					message(ns(paste0('[355][observe][OUT][uRV$FundLst_for_CPA]:<'
						,paste0(uRV$FundLst_for_CPA,collapse = '>,<')
						,'>'
					)))
					message(ns(paste0('[355][observe][OUT][uRV$knitr_params]:<',length(uRV$knitr_params),'> items')))
				}
			#End of [isolate]
			})
		}
		,label = ns(paste0('[355]Observe: uRV$mFE$EnvVariables()$FundLst_toDrawCH'))
	)

	#357. Prepare to call module of Portfolio Adjustment when clicking upon the [Confirm Selection] button
	session$userData[[paste(ns(observer_pfx),'call_CPA_prep',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			#We do not take [uRV$chb$FundLst_toDrawCH] as dependency as [uRV$chb] is always changed.
			uRV$FundLst_for_CPA

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[357][observe][IN][uRV$FundLst_for_CPA]:<'
						,paste0(uRV$FundLst_for_CPA,collapse = '>,<')
						,'>'
					)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$FundLst_for_CPA)) return()

				#800. Prepare to call the module of Portfolio Adjustment
				if (is.null(uRV$Counter_CPA)) uRV$Counter_CPA <- 0
				else uRV$Counter_CPA <- uRV$Counter_CPA + 1
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[357][observe][OUT][uRV$Counter_CPA]:',uRV$Counter_CPA)))
				}
			#End of [isolate]
			})
		}
		,label = ns(paste0('[357]Prepare to call module of Portfolio Adjustment when the fund list is confirmed to change'))
	)

	#358. Prepare to call module of Portfolio Adjustment when the display language changes
	session$userData[[paste(ns(observer_pfx),'call_CPA_prep_lang',sep='_')]] <- shiny::observeEvent(
		uRV$Counter_lang
		,{
			#100. Take dependencies

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[358][observeEvent][IN][uRV$Counter_lang]:',uRV$Counter_lang)))
				}
				#010. Return if the condition is not valid
				if (uRV$Counter_lang == 0) return()

				#800. Prepare to call the module of Portfolio Adjustment
				uRV$Counter_CPA <- uRV$Counter_CPA + 1
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[358][observe][OUT][uRV$Counter_CPA]:',uRV$Counter_CPA)))
				}
			#End of [isolate]
			})
		}
		,ignoreInit = T
		,label = ns(paste0('[358]Prepare to call module of Portfolio Adjustment when the display language changes'))
	)

	#360. When user completes the portfolio allocation
	#361. Increment a counter to update the returned values from the moudle [Customer Portfolio Adjustment]
	session$userData[[paste(ns(observer_pfx),'upd_state_CPA',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			# uRV$ID_Mod_CPA
			uRV$mCPA$EnvVariables()$SaveState

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					# message(ns(paste0('[365][observe][IN][uRV$ID_Mod_CPA]:<',uRV$ID_Mod_CPA,'>')))
					message(ns(paste0('[361][observe][IN][uRV$mCPA$EnvVariables()$SaveState]:<'
						,uRV$mCPA$EnvVariables()$SaveState
						,'>'
					)))
				}
				#010. Return if the condition is not valid
				# if (is.null(uRV$mCPA$EnvVariables()$SaveState)) return()

				#200. Prepare to save the state of the module
				if (is.null(uRV$Counter_CPA_data)) uRV$Counter_CPA_data <- uRV$mCPA$EnvVariables()$SaveState
				else {
					if (uRV$Counter_CPA_data == uRV$mCPA$EnvVariables()$SaveState) return()
					else uRV$Counter_CPA_data <- uRV$Counter_CPA_data + 1
				}

				#Debug Mode
				if (fDebug){
					message(ns(paste0('[361][observe][OUT][uRV$Counter_CPA_data]:<',paste0(uRV$Counter_CPA_data,collapse = '>,<'),'>')))
				}
			#End of [isolate]
			})
		}
		,label = ns(paste0('[361]Increment a counter to update the returned values from the moudle [Customer Portfolio Adjustment]'))
	)

	#365. Update the parameters for printing
	session$userData[[paste(ns(observer_pfx),'save_state_CPA',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$Counter_CPA_data

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[365][observe][IN][uRV$Counter_CPA_data]:<',uRV$Counter_CPA_data,'>')))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$Counter_CPA_data)) return()

				#100. Only get the reactive value once to reduce the system calculation effort.
				getparams <- uRV$mCPA$EnvVariables()

				#200. Save the current state of portfolio adjustment
				uRV$chb$AUM_new <- getparams$AUM_new
				uRV$chb$PortAdj_Selected <- getparams$PortAdj_Selected
				uRV$chb$Prod_Adjusted <- getparams$Prod_Adjusted
				# message({uRV$chb$Prod_Adjusted %>% dplyr::filter(ProdType_EN == 'Savings+') %>% dplyr::select(bal_new)})

				#600. Export the parameters for printable version once the above module is called
				sapply(uRV$params_CPA, function(m) uRV$knitr_params[[m]] <- getparams$knitr_params[[m]])
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[365][observe][OUT][uRV$chb$AUM_new]:<',paste0(uRV$chb$AUM_new,collapse = '>,<'),'>')))
					message(ns(paste0('[365][observe][OUT][uRV$chb$PortAdj_Selected]:<'
						,paste0(uRV$chb$PortAdj_Selected[[paste0('ProdCcy_',uRV$lang_disp)]],collapse = '>,<')
						,'>'
					)))
					message(ns(paste0('[365][observe][OUT][uRV$chb$Prod_Adjusted]:<',paste0(colnames(uRV$chb$Prod_Adjusted),collapse = '>,<'),'>')))
					message(ns(paste0('[365][observe][OUT][uRV$chb$Prod_Adjusted]:',paste0(summary(uRV$chb$Prod_Adjusted), collapse = '\n'),'\n')))
					message(ns(paste0('[365][observe][OUT][uRV$knitr_params]:<',length(uRV$knitr_params),'> items')))
				}
			#End of [isolate]
			})
		}
		,label = ns(paste0('[365]Observe: uRV$mCPA$EnvVariables()$ActionCounter'))
	)

	#370. Call modules only when it is instructed
	#373. Module of Customer Portfolio Dashboard
	session$userData[[paste(ns(observer_pfx),'call_CPD',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$Counter_CPD

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[373][observe][IN][uRV$Counter_CPD]:',uRV$Counter_CPD)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$Counter_CPD)) return()

				#300. Garbage collection of the previous call
				#See [Dependency]
				gc_shiny_module(
					'CPD'
					,input
					,session
					,UI_Selectors = NULL
					,UI_namespaced = T
					,observer_pfx = observer_pfx
				)

				#500. Call Module
				#See [Dependency]
				uRV$mCPD <- shiny::callModule(
					UM_custPortDash_svr
					,'CPD'
					,CustData = uRV$chb
					,lang_cfg = lang_cfg
					,color_cfg = color_cfg
					,lang_disp = uRV$lang_disp
					,font_disp = font_disp
					,observer_pfx = observer_pfx
					,fDebug = fDebug
				)

				#600. Export the parameters for printable version once the above module is called
				#Only get the reactive value once to reduce the system calculation effort.
				getparams <- uRV$mCPD$EnvVariables()$knitr_params
				sapply(uRV$params_CPD, function(m) uRV$knitr_params[[m]] <- getparams[[m]])
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[373][observe][OUT][uRV$knitr_params]:<',length(uRV$knitr_params),'> items')))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[373]Call the module to draw the portfolio dashboard')
	)

	#375. Module of Fund Explorer
	session$userData[[paste(ns(observer_pfx),'call_FE',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$Counter_FE

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[375][observe][IN][uRV$Counter_FE]:',uRV$Counter_FE)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$Counter_FE)) return()

				#200. Set a new ID for the module call
				#IMPORTANT!!! We always have to create a new ID for the module!
				#The internal observers fro them previous call of this module cannot be overlooked by [shiny] mechanism!
				# uRV$ID_Mod_FE <- paste0('FE','_',floor(runif(1) * 10^6))
				uRV$ID_Mod_FE <- paste0('FE','_','call')

				#300. Garbage collection of the previous call
				#See [Dependency]
				gc_shiny_module(
					uRV$ID_Mod_FE
					,input
					,session
					,UI_Selectors = NULL
					,UI_namespaced = T
					,observer_pfx = observer_pfx
				)

				#500. Call Module
				#See [Dependency]
				uRV$mFE <- shiny::callModule(
					UM_FundExp_svr
					,uRV$ID_Mod_FE
					,CustData = uRV$chb
					,f_loadstate = T
					,lang_cfg = lang_cfg
					,color_cfg = color_cfg
					,lang_disp = uRV$lang_disp
					,font_disp = font_disp
					,observer_pfx = observer_pfx
					,fDebug = fDebug
				)
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[375]Call the module for user to select Funds for further portfolio allocation')
	)

	#377. Module of Portfolio Adjustment
	session$userData[[paste(ns(observer_pfx),'call_CPA',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$Counter_CPA

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[377][observe][IN][uRV$Counter_CPA]:',uRV$Counter_CPA)))
				}
				#010. Return if the condition is not valid
				if (is.null(uRV$Counter_CPA)) return()
				# message('377 ',try({uRV$chb$Prod_Adjusted %>% dplyr::filter(ProdType_EN == 'Savings+') %>% dplyr::select(bal_new)}, silent = T))

				#200. Set a new ID for the module call
				#IMPORTANT!!! We always have to create a new ID for the module!
				#The internal observers fro them previous call of this module cannot be overlooked by [shiny] mechanism!
				# uRV$ID_Mod_CPA <- paste0('CPA','_',floor(runif(1) * 10^6))
				uRV$ID_Mod_CPA <- paste0('CPA','_','call')

				#300. Garbage collection of the previous call
				#See [Dependency]
				gc_shiny_module(
					uRV$ID_Mod_CPA
					,input
					,session
					,UI_Selectors = NULL
					,UI_namespaced = T
					,observer_pfx = observer_pfx
				)

				#500. Call Module
				#See [Dependency]
				uRV$mCPA <- shiny::callModule(
					UM_custPortAdj_svr
					,uRV$ID_Mod_CPA
					,CustData = uRV$chb
					,f_loadstate = T
					,lang_cfg = lang_cfg
					,color_cfg = color_cfg
					,lang_disp = uRV$lang_disp
					,font_disp = font_disp
					,Ech_ext_utils = params_ext$Ech_ext_utils
					,Wg_SliderGrp = params_ext$Wg_SliderGrp
					,observer_pfx = observer_pfx
					,fDebug = fDebug
				)
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[377]Call the module for user to conduct portfolio allocation')
	)

	#400. Create HTML tags
	#410. Tags that only depend on the change of display language
	session$userData[[paste(ns(observer_pfx),'ui_lang',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			uRV$lang_disp
			input$uWg_AB_ResetAll
			input$uWg_AB_ConfChg

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[410][observe][IN][uRV$lang_disp]:',uRV$lang_disp)))
					message(ns(paste0('[410][observe][IN][input$uWg_AB_ResetAll]:',input$uWg_AB_ResetAll)))
					message(ns(paste0('[410][observe][IN][input$uWg_AB_ConfChg]:',input$uWg_AB_ConfChg)))
				}
				#010. Return if the condition is not valid
				# if (is.null(input$uWg_AB_ResetAll)) return()
				# if (is.null(input$uWg_AB_ConfChg)) return()

				#050. Update the language of the buttons in the toolbox
				shiny::updateActionButton(
					session
					,'uWg_AB_Print'
					,label = lang_cfg[[uRV$lang_disp]][['Print']]
				)

				#100. Report title
				uRV$uDiv_Rpt_Title <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::fillRow(
							flex = c(7,5)
							,height = 40
							,shiny::tags$h3(
								class = 'uDiv-title'
								,lang_cfg[[uRV$lang_disp]][['Title_Rpt']]
							)
							,shiny::tags$div(
								style = paste0(''
									,'text-align: right;'
								)
								#[Quote: https://www.cnblogs.com/kaixiangbb/p/3302677.html ]
								,shiny::tags$img(
									src = CustData$Rpt_Logo
									,width = 164
								)
							)
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 2px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)

					#300. Copyright and data refresh date
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,style = paste0(''
							,'padding-top: 0px;'
						)
						,shiny::fillRow(
							flex = c(7,5)
							,height = 16
							,shiny::tags$div(
								class = 'uDiv-copyright'
								,lang_cfg[[uRV$lang_disp]][['Copyright']]
							)
							,shiny::tags$div(
								class = 'uDiv-d-update'
								,style = paste0(''
									,'text-align: right;'
									,'padding-right: 8px;'
								)
								,paste0(
									lang_cfg[[uRV$lang_disp]][['Data Update Date']],': '
									,strftime(CustData$CurrDate,'%Y-%m-%d', tz = Sys.getenv('TZ'))
								)
							)
						)
					)
				)

				#200. Customer Portfolio Dashboard
				#210. Product Holding by Product Type
				uRV$uDiv_Rpt_ProdType <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							class = 'uDiv-section'
							,lang_cfg[[uRV$lang_disp]][['rptsecs']][['ProdType']][['Title']]
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 1px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)
				)

				#230. Product Holding Details
				uRV$uDiv_Rpt_DashTables <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							class = 'uDiv-section'
							,lang_cfg[[uRV$lang_disp]][['rptsecs']][['DashTables']][['Title']]
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 1px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)
				)

				#270. CTT
				uRV$uDiv_Rpt_CTT <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							class = 'uDiv-section'
							,lang_cfg[[uRV$lang_disp]][['rptsecs']][['CTT']][['Title']]
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 1px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)
				)

				#300. Fund Explorer
				uRV$uDiv_Rpt_FundExplorer <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							class = 'uDiv-section'
							,lang_cfg[[uRV$lang_disp]][['rptsecs']][['FundExplorer']][['Title']]
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 1px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)

					#300. Powered by
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,style = paste0(''
							,'padding-top: 0px;'
						)
						,shiny::tags$div(
							class = 'pull-right uDiv-poweredby'
							,lang_cfg[[uRV$lang_disp]][['Model Declaration']]
						)
					)
				)

				#400. Portfolio Adjustment
				#410. AUM distribution chart
				uRV$uDiv_Rpt_AUMadj <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							class = 'uDiv-section'
							,lang_cfg[[uRV$lang_disp]][['rptsecs']][['PortAdj']][['Title']]
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 1px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)
				)

				#430. P&L Comparison Table
				uRV$uDiv_Rpt_PnLComp <- shiny::tagList(
					#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
					shiny::tags$style(
						type = 'text/css'
						,uRV$styles_final
					)
					#100. Title and logo
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							class = 'uDiv-section'
							,lang_cfg[[uRV$lang_disp]][['rptsecs']][['PnLComp']][['Title']]
						)
					)

					#200. Draw a header line at the top of the report
					,shiny::fluidRow(
						class = 'cpm_fluidRow'
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
								,'height: 1px;'
								,'background-color: ',color_cfg$CustAct,';'
							)
						)
					)
				)

				#950. Export the parameters for printable version
				uRV$knitr_params$lang_disp <- uRV$lang_disp
				uRV$knitr_params$uDiv_Rpt_Title <- uRV$uDiv_Rpt_Title
				uRV$knitr_params$uDiv_Rpt_ProdType <- uRV$uDiv_Rpt_ProdType
				uRV$knitr_params$uDiv_Rpt_DashTables <- uRV$uDiv_Rpt_DashTables
				uRV$knitr_params$uDiv_Rpt_CTT <- uRV$uDiv_Rpt_CTT
				uRV$knitr_params$uDiv_Rpt_FundExplorer <- uRV$uDiv_Rpt_FundExplorer
				uRV$knitr_params$uDiv_Rpt_AUMadj <- uRV$uDiv_Rpt_AUMadj
				uRV$knitr_params$uDiv_Rpt_PnLComp <- uRV$uDiv_Rpt_PnLComp
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[410][observe][OUT][uRV$knitr_params]:<',length(uRV$knitr_params),'> items')))
				}
			#End of [isolate]
			})
		#End of [observe]
		}
		,label = ns('[410]Tags that only depend on the change of display language')
		# ,priority = 990
	)

	#500. User actions
	#599. When clicking upon the 'print' button
	session$userData[[paste(ns(observer_pfx),'click_print',sep='_')]] <- shiny::observe(
		{
			#100. Take dependencies
			input$uWg_AB_Print

			#900. Execute below block of codes only once upon the change of any one of above dependencies
			shiny::isolate({
				#Debug Mode
				if (fDebug){
					message(ns(paste0('[599][observe][IN][input$uWg_AB_Print]:',input$uWg_AB_Print)))
				}
				#010. Return if the condition is not valid
				if (is.null(input$uWg_AB_Print)) return()
				if (input$uWg_AB_Print == 0) return()

				#100. [Knit] the document for preview
				reportTpl <- params_ext$reportTpl
				reportFile <- params_ext$reportFile
				tempReport <- file.path(tempdir(),'custPortMgmt.Rmd')
				file.copy(reportTpl, tempReport, overwrite = TRUE)
				rmarkdown::render(
					tempReport
					,output_file = reportFile
					,params = uRV$knitr_params
					,envir = new.env(parent = globalenv())
				)

				#300. Locate the web explorer
				chrome <- pagedown::find_chrome()

				#500. Use the web explorer to open the preview file
				system(paste0('"',chrome,'" "',reportFile,'"'), wait = F)

				#900. Mark the completion of operations in this module
				uRV_finish(input$uWg_AB_Print)
				uRV$ActionDone <- TRUE
			#End of [isolate]
			})
		}
		,label = ns('[599]Mark the completion of the task')
	)

	#700. Create UI

	#705. Toolbox
	uRV$uAB_Print <- shiny::actionButton(
		ns('uWg_AB_Print')
		,class = 'uAB-theme-s'
		,width = '64px'
		,icon = shiny::icon('print')
		,lang_cfg[[uRV$lang_disp]][['Print']]
	)

	#706. Create a static widget for language switch
	uRV$upT_Lang <- shinyWidgets::prettyToggle(
		inputId = ns('uWg_pT_Lang')
		,label_on = lang_cfg[['CN']][['Switch_Lang']]
		,status_on = "default"
		,icon_on = shiny::icon('language')
		,label_off = lang_cfg[['EN']][['Switch_Lang']]
		,status_off = "default"
		,icon_off = shiny::icon('language')
		,plain = TRUE
		,inline = TRUE
		,width = '64px'
		,value = uRV$lang_selector[[uRV$lang_disp]]
	)

	#710. Title and section headers
	#711. Title
	output$ui_Title <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[711][renderUI][IN][output$ui_Title]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_Title
	})

	#712. Section header of [Holding by Product Type]
	output$ui_hdr_ProdType <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[712][renderUI][IN][output$ui_hdr_ProdType]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_ProdType
	})

	#713. Section header of [Holding Details]
	output$ui_hdr_DashTables <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[713][renderUI][IN][output$ui_hdr_DashTables]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_DashTables
	})

	#714. Section header of [CTT]
	output$ui_hdr_CTT <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[713][renderUI][IN][output$ui_hdr_CTT]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_CTT
	})

	#715. Section header of [Fund Explorer]
	output$ui_hdr_FundExp <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[715][renderUI][IN][output$ui_hdr_FundExp]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_FundExplorer
	})

	#716. Section header of [AUM Allocation]
	output$ui_hdr_AUMadj <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[715][renderUI][IN][output$ui_hdr_AUMadj]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_AUMadj
	})

	#717. Section header of [P&L Comparison]
	output$ui_hdr_PnLComp <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[715][renderUI][IN][output$ui_hdr_PnLComp]')))
		}

		#100. Take dependencies
		# uRV$lang_disp

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		uRV$uDiv_Rpt_PnLComp
	})

	#720. Portfolio Dashboard
	output$ui_PortDash <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[720][renderUI][IN][output$ui_PortDash]')))
		}

		#100. Take dependencies

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::tagList(NULL
			#100. Profile
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPD_ui_NameCard(ns('CPD'))
			)

			#300. Holding by product type
			,shiny::uiOutput(ns('ui_hdr_ProdType'))
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPD_ui_ProdType(ns('CPD'))
			)

			#500. Holding details
			,shiny::uiOutput(ns('ui_hdr_DashTables'))
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPD_ui_DashTables(ns('CPD'))
			)

			#800. CTT
			#I may place this chart into some other section below
			,shiny::uiOutput(ns('ui_hdr_CTT'))
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPD_ui_CTT(ns('CPD'))
			)
		)
	})

	#750. Fund Explorer
	output$ui_FundExp <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[750][renderUI][IN][output$ui_FundExp]')))
		}

		#100. Take dependencies
		uRV$Counter_FE

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::tagList(NULL
			#010. Section Header
			,shiny::uiOutput(ns('ui_hdr_FundExp'))

			#100. Fund Selector
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_FundExp_ui(ns(uRV$ID_Mod_FE))
			)

			#300. Customer Cost vs. Product NAV
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_FundExp_ui_CostPnL(ns(uRV$ID_Mod_FE))
			)

			#500. Fund Price Trend
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_FundExp_ui_FundPrice(ns(uRV$ID_Mod_FE))
			)

			#700. Fund P&L Trend
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_FundExp_ui_FundPnL(ns(uRV$ID_Mod_FE))
			)
		)
	})

	#770. Portfolio Adjustment
	#771. Product Selector and AUM Adjuster
	output$ui_AUMadj <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[771][renderUI][IN][output$ui_AUMadj]')))
		}

		#100. Take dependencies
		uRV$Counter_CPA

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::tagList(NULL
			#010. Section Header
			,shiny::uiOutput(ns('ui_hdr_AUMadj'))

			#100. Product Selector
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPA_ui_ProdSel(ns(uRV$ID_Mod_CPA))
			)

			#300. AUM Adjuster
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPA_ui_AUMadj(ns(uRV$ID_Mod_CPA))
			)
		)
	})

	#775. P&L Comparison and Advisory
	output$ui_PnLadvise <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[775][renderUI][IN][output$ui_PnLadvise]')))
		}

		#100. Take dependencies
		uRV$Counter_CPA

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::tagList(NULL
			#010. Section Header
			,shiny::uiOutput(ns('ui_hdr_PnLComp'))

			#100. Product Selector
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPA_ui_ProfitByProdType(ns(uRV$ID_Mod_CPA))
			)

			#300. AUM Adjuster
			,shiny::fluidRow(
				class = 'cpm_fluidRow'
				,UM_CPA_ui_Advise(ns(uRV$ID_Mod_CPA))
			)
		)
	})

	#799. Final UI
	output$uDiv_CPM <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[799][renderUI][IN][output$uDiv_CPM]')))
		}

		#100. Take dependencies
		uRV$styles_final

		#900. Execute below block of codes only once upon the change of any one of above dependencies
		shiny::isolate({
			shiny::tagList(
				#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
				shiny::tags$style(
					type = 'text/css'
					,uRV$styles_final
				)

				#050. Toolbox
				,shiny::fluidRow(
					class = 'cpm_fluidRow'
					,id = ns('cpm_toolbox')
					,shiny::fillRow(
						flex = c(NA,NA,1)
						,height = 24
						,uRV$uAB_Print
						,uRV$upT_Lang
						,shiny::tags$div(
							style = paste0(''
								,'width: 100%;'
							)
						)
					)
				)

				#100. Title
				,shiny::uiOutput(ns('ui_Title'))
			#End of [tagList]
			)
		})
	#End of [renderUI] of [799]
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
			, 'shiny', 'rmarkdown', 'pagedown', 'shinyWidgets'
			, 'DT', 'shinydashboard', 'shinydashboardPlus', 'echarts4r', 'htmlwidgets', 'htmltools', 'V8', 'dplyr'
			, 'tidyselect', 'data.table', 'grDevices'
			, 'lubridate'
			, 'tippy', 'jsonlite'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		omniR <- normalizePath('D:\\R\\omniR')
		js_vue <- list.files( omniR , '^vue.*\\.js$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE ) %>%
			normalizePath()
		source(normalizePath(file.path(omniR,'AdvOp','scaleNum.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','rem_shiny_inputs.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'AdvOp','gc_shiny_module.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'Styles','rgba2rgb.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortDash.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_FundExp.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_FundCompare.r')),encoding = 'utf-8')
		source(normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortAdj.r')),encoding = 'utf-8')
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
			,sidebar = shinydashboard::dashboardSidebar()
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
				,shinyjs::extendShinyjs(
					script = paste('www',path_js,file_shinyjs_ext,sep = '/')
					,functions = c('collapse')
				)
				,shiny::fluidPage(
					shiny::column(width = 10
						,shinydashboardPlus::boxPlus(width = 12
							,collapsible = TRUE
							,solidHeader = FALSE
							,closable = FALSE
							,shiny::fluidRow(
								style = paste0(''
									,'width: 90%;'
									,'padding: 0px;'
									,'margin: 0px;'
									,'margin-left: 30px;'
								)
								,UM_CPM_ui_toolbox('cpm')
								,UM_CPM_ui_PortDash('cpm')
							)
						#End of [box]
						)
						,shinydashboardPlus::boxPlus(width = 12
							,collapsible = TRUE
							,solidHeader = FALSE
							,closable = FALSE
							,shiny::fluidRow(
								style = paste0(''
									,'width: 90%;'
									,'padding: 0px;'
									,'margin: 0px;'
									,'margin-left: 30px;'
								)
								,UM_CPM_ui_FundExp('cpm')
							)
						#End of [box]
						)
						,shinydashboardPlus::boxPlus(width = 12
							,collapsible = TRUE
							,solidHeader = FALSE
							,closable = FALSE
							,shiny::fluidRow(
								style = paste0(''
									,'width: 90%;'
									,'padding: 0px;'
									,'margin: 0px;'
									,'margin-left: 30px;'
								)
								,UM_CPM_ui_AUMadj('cpm')
								,UM_CPM_ui_PnLAdvise('cpm')
							)
						#End of [box]
						)
					)
				)
			)
			,rightsidebar = shinydashboardPlus::rightSidebar()
			,title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$cpm <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0)
				,ActionDone = shiny::reactive({FALSE})
				,EnvVariables = shiny::reactive({NULL})
			)

			aaa <- 1
			shiny::observeEvent(
				aaa
				,{
					#100. Take dependencies

					#900. Execute below block of codes only once upon the change of any one of above dependencies
					# shiny::isolate({
						modout$cpm <- shiny::callModule(
							UM_custPortMgmt_svr
							,'cpm'
							,CustData = uRV$PM_rpt
							,lang_cfg = lang_CPM
							,color_cfg = color_CPM
							,font_disp = 'Microsoft YaHei'
							,Ech_ext_utils = Ech_ext_utils
							,Wg_SliderGrp = Wg_SliderGrp
							,observer_pfx = 'uObs'
							,reportTpl = normalizePath(file.path(omniR,'UsrShinyModules','Ops','UM_custPortMgmt.Rmd'))
							,reportFile = paste(normalizePath(file.path(omniR,'UsrShinyModules','Ops')),'PortMgmt.html',sep = '\\')
							,fDebug = FALSE
						)
					#End of [isolate]
					# })
				}
				,label = '[500]Monitor the status of the module call'
			)
			shiny::observeEvent(modout$cpm$CallCounter(),{
				if (modout$cpm$CallCounter() == 0) return()
				message('[cpm$CallCounter()]:',modout$cpm$CallCounter())

				params_global <<- modout$cpm$EnvVariables()$knitr_params
				# message('[cpm$EnvVariables()$text_out]:',modout$cpm$EnvVariables()$text_out)
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
	CustData <- uRV$PM_rpt
	uRV$chb <- CustData
	lang_cfg <- lang_CPM
	uRV$lang_disp <- 'CN'

	#Below please paste related code snippets and execute

}
