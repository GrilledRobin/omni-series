#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This module (Customer Portfolio Dashboard) is designed for below purposes:                                                         #
#   |[1]Display the customer individual report of AUM and Gain/Loss by products                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 客户经理查看客户在我行资产分布以及近期盈亏情况                                                                                 #
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
#   |                   [NumFmt_Currency  ]    <vector>     Vector of field names that will be displayed in the format: #,#00,00        #
#   |                   [NumFmt_Percent   ]    <vector>     Vector of field names that will be displayed in the format: #00,00%         #
#   |                   [NumFmt_Price     ]    <vector>     Vector of field names that will be displayed in the format: #00,0000        #
#   |                   [NumFmt_PnL       ]    <vector>     Vector of field names that will be displayed in opposite colors             #
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
#   |CPD           :   Customer Portfolio Dashboard                                                                                     #
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
#   | Date |    20200328        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200407        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Replace the creation of data.tables with [mapply] to enable the extensibility of different product classification           #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200419        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add a parameter [color_cfg] to unify the color settings for all related modules                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200510        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |shiny, DT, shinydashboard, shinydashboardPlus, echarts4r, htmlwidgets, dplyr, tidyselect, data.table, grDevices                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Styles                                                                                                                   #
#   |   |   |rgba2rgb                                                                                                                   #
#   |   |   |bg_gradient                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	shiny, DT, shinydashboard, shinydashboardPlus, echarts4r, htmlwidgets, dplyr, tidyselect, data.table, grDevices
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

UM_CPD_ui_NameCard <- function(id){
	#Set current Name Space
	ns <- shiny::NS(id)

	shiny::uiOutput(ns('uDiv_NameCard'))
}

UM_CPD_ui_ProdType <- function(id){
	#Set current Name Space
	ns <- shiny::NS(id)

	shiny::uiOutput(ns('uDiv_ProdType'))
}

UM_CPD_ui_DashTables <- function(id){
	#Set current Name Space
	ns <- shiny::NS(id)

	shiny::uiOutput(ns('uDiv_DashTables'))
}

UM_CPD_ui_CTT <- function(id){
	#Set current Name Space
	ns <- shiny::NS(id)

	shiny::uiOutput(ns('uDiv_CTT'))
}

UM_custPortDash_svr <- function(input,output,session
	,CustData = NULL
	,lang_cfg = NULL,color_cfg = NULL
	,lang_disp = 'CN',font_disp = 'Microsoft YaHei'
	,observer_pfx = 'uObs'
	,fDebug = FALSE){
	ns <- session$ns

	#001. Prepare the list of reactive values for calculation
	uRV <- shiny::reactiveValues()
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	lang_disp <- match.arg(lang_disp,c('CN','EN'))
	uRV$font_list <- c('Microsoft YaHei','Helvetica','sans-serif','Arial','宋体')
	uRV$font_list_css <- paste0(
		sapply(uRV$font_list, function(m){if (length(grep('\\W',m,perl = T))>0) paste0('"',m,'"') else m})
		,collapse = ','
	)
	font_disp <- match.arg(font_disp,uRV$font_list)
	#Define the list of data.frames to be displayed as [data.table]
	lst_drawDT <- c('Prod_Dep','Prod_Inv','Prod_MF','Prod_Bnc')
	#Below is the list of important stages to trigger the increment of initial progress bar
	uRV$pb_k <- list(
		#[1] Loading data
		load = 0
		#[2] Drawing charts
		,chart = 5
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
		message(ns(paste0('[Module Call][UM_custPortDash]')))
	}

	#005. Check parameters
	#We do not return values to break the chain of the subsequent processes.
	if (is.null(CustData)) stop(ns(paste0('[005]Crucial input data [CustData] is not provided!')))
	if (length(CustData) == 0) stop(ns(paste0('[005]Crucial input data [CustData] has no content!')))

	#200. General settings of styles for the output UI
	setNumColor <- function(n){ifelse(n>-0.0000001,color_cfg$Positive,color_cfg$Negative)}

	#201. Prepare the styles for the buttons indicating file attributes
	uRV$btn_styles_attr <- paste0(''
		,'width: 120px;'
		,'font-family: "',font_disp,'";'
		,'font-size: 12px;'
		,'text-align: left;'
		,'padding-left: 8px;'
		,'padding-top: 6px;'
		,'padding-right: inherit;'
		,'border: none;'
	)

	#202. Text area for dataframe attributes
	uRV$txt_styles_attr <- paste0(''
		,'font-family: "',font_disp,'";'
		,'font-size: 12px;'
		,'padding-left: 10px;'
		,'padding-top: 6px;'
	)

	#203. Font Size of chart items
	uRV$styles_ch_FontSize_title <- 14
	uRV$styles_ch_FontSize_item <- 10

	#204. Default styles for the content in all charts
	uRV$styles_ch_content <- list(
		fontFamily = font_disp
		,fontSize = uRV$styles_ch_FontSize_item
	)

	#207. Attributes for [tooltips]
	uRV$attr_tooltips <- list(
		textStyle = modifyList(
			uRV$styles_ch_content
			,list(
				color = '#fff'
			)
		)
		,backgroundColor = 'rgba(50,50,50,0.7)'
		,borderColor = 'rgba(50,50,50,0)'
	)

	#210. Format the [userBox]
	uRV$styles_uCard <- shiny::HTML(
		paste0(''
			,'.box:hover {'
				#Quote: https://blog.csdn.net/dangbai01_/article/details/108658829
				#box-shadow: h-shadow v-shadow blur spread color inset
				,'box-shadow: 0 2px 4px 0 rgba(0,0,0,0.2);'
				,'transition: 0.3s;'
			,'}'
			#Narrow down the margin of the user profile box
			,'.box-widget {'
				,'margin-bottom: 4px;'
			,'}'
			,'.box-footer {'
				,'border-top: none;'
				,bg_gradient( color_cfg$UsrFooterBg, rgba2rgb(color_cfg$UsrFooterBg, alpha_in = 0.5) )
				,'box-shadow: 1px 1px 4px 1px rgba(0,0,0,0.2) inset;'
			,'}'
			,'.widget-user-header {'
				,'padding-right: 10px !important;'
			,'}'
			,'.widget-user-username {'
				,'color: ',color_cfg$UsrTitle,';'
				,'font-family: "',font_disp,'";'
				,'font-size: 18px !important;'
				,'overflow: hidden;'
				,'white-space: nowrap;'
			,'}'
			,'.widget-user-desc {'
				,'color: ',color_cfg$UsrTitle,';'
				,'font-family: "',font_disp,'";'
				,'font-size: 12px !important;'
				,'overflow: hidden;'
				,'white-space: nowrap;'
				,'padding-top: 4px;'
				,'margin-bottom: 6px;'
			,'}'
			,'.bg-light-blue-gradient {'
				,bg_gradient( color_cfg$UsrBox, rgba2rgb(color_cfg$UsrBox, alpha_in = 0.7) )
			,'}'
		)
	)

	#220. Grid for the chart [ProdCat]
	uRV$grid_ProdCat_Left <- list(CN = 40 , EN = 48)

	#230. Grid for the chart [RiskLvl]
	uRV$grid_RiskLvl_Right <- list(CN = 40 , EN = 72)

	#240. Prepare the color series to differentiate the bars in the chart by [ProdType]
	CustData$Bal_ProdType$color_old <- color_cfg$CustAct
	CustData$Bal_ProdType$color_new <- color_cfg$CustNew
	uRV$legendColor_ch_ProdName <- min(CustData$Bal_ProdType$color_old)

	#250. Prepare the color series to differentiate the bars in the chart by [FundName]
	CustData$Bal_FundName$color_old <- color_cfg$CustAct
	CustData$Bal_FundName$color_new <- color_cfg$CustNew
	uRV$legendColor_ch_FundName <- min(CustData$Bal_FundName$color_old)

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
	#Check below website to find the selectors to override:
	#Quote: https://datatables.net/manual/styling/theme-creator
	uRV$dt_styles_byProduct <- shiny::HTML(
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
			,'.dataTable.display>tbody>tr {'
				,'background-color: ',color_cfg$tabBox_NavBg,';'
			,'}'
			#[1] Here the color [#F9F9F9] is the default one as an odd row in a striped table of [DT::datatable]
			#[2] It is tested that: rgba2rgb( '#F7F7F7', alpha_in = 0.7, color_bg = grDevices::col2rgb('#FFFFFF') ) == '#F9F9F9'
			#[3] We have to set the color of the pseudo-class selector as [!important] to override the default effect
			,'.dataTable.display>tbody>tr:hover {'
				,'background-color: rgba(',paste0(grDevices::col2rgb('#F7F7F7'), collapse = ','),',0.7) !important;'
			,'}'
			#Fill the rows with opacity
			,'.dataTable.display>tbody>tr.odd {'
				,'background-color: rgba(',paste0(grDevices::col2rgb('#F7F7F7'), collapse = ','),',0.7) !important;'
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
				,uRV$styles_tabBox_font
			,'}'
			#Set the styles when the filtered data.table has no record
			,'.dataTables_empty {'
				,'line-height: 1;'
				,uRV$styles_tabBox_font
			,'}'
		)
	)

	#275. Format the [shinydashboard::tabBox]
	uRV$styles_tabBox <- shiny::HTML(
		paste0(''
			#Selectors in CSS:
			#[Quote: http://www.divcss5.com/rumen/r50591.shtml ]
			#Below ensures the background is transparent
			,'.nav-tabs-custom {'
				,'background: none !important;'
			,'}'
			#[title] in the [shinydashboard::tabBox]
			,'.nav-tabs-custom>.nav-tabs>li.header {'
				,'background: none !important;'
			,'}'
			#All inactive tabs
			,'.nav-tabs-custom>.nav-tabs>li {'
				,'background-color: rgba(',paste0(grDevices::col2rgb(color_cfg$tabBox_NavBg), collapse = ','),',0.7);'
			,'}'
			#<a> tag of the active tab
			,'.nav-tabs-custom>.nav-tabs>li.active>a {'
				,'background: none !important;'
			,'}'
			#Set the color of the top-border of active tabs inside the [tabBox]
			,'.nav-tabs-custom>.nav-tabs>li.active {'
				,'border-top-color: ',color_cfg$tabBox,';'
			,'}'
			#Set the same background for the active tab and the tab content
			,'.nav-tabs-custom>.nav-tabs>li.active, .nav-tabs-custom>.tab-content {'
				,'background-color: ',color_cfg$tabBox_NavBg,';'
			,'}'
		)
	)

	#280. Styles for displaying the different bars in the chart [ProdCTT]
	uRV$grid_ProdCTT_Left <- list(CN = 48 , EN = 56)
	uRV$colors_ProdCTT <- data.frame(
		kpi = c('CTTRatio','bal_pct','new_pct')
		,baseColor = c(color_cfg$Advise,color_cfg$CustAct,color_cfg$CustNew)
		,kpiseq = c(10,50,90)
		,stringsAsFactors = FALSE
	)
	#Here the number 3 reparesents these: [Core], [T1], [T2]
	uRV$colors_legend_ProdCTT <- rgba2rgb(rep('#000000',3), alpha_in = c(1,0.6,0.2))

	#290. Styles for the final output UI
	#Use [HTML] to escape any special characters
	#[Quote: https://mastering-shiny.org/advanced-ui.html#using-css ]
	uRV$styles_final <- shiny::HTML(
		paste0(
			#Set the paddings of the [tabBox]
			# '[class^=col-][class$=',uRV$uTB_width,'] {'
			'.col-sm-',uRV$uTB_width,' {'
				,'padding: 0px;'
			,'}'
			,'.cpd_fluidRow {padding: 2px 15px 2px 15px;}'
			,'.cpd_Column {'
				,'padding: 0px;'
			,'}'
		)
	)

	#400. Prepare the HTML elements
	#410. Name card, total portfolio distribution on the report
	#411. Customer profile
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Prepare Chart][IN][uRV$uCard_Profile]')))
	}
	uRV$uCard_Profile <- shiny::tagList(
		shiny::tags$style(
			type = 'text/css'
			,uRV$styles_uCard
		)

		,shinydashboardPlus::userBox(
			width = 12
			,height = 192
			,collapsible = FALSE
			#We will modify the CSS class [bg-light-blue-gradient] with our color theme in [uRV$styles_final]
			# ,background = color_cfg$UsrBox
			,background = 'light-blue'
			,gradient = TRUE
			,title = shinydashboardPlus::userDescription(
				title = CustData$custinf[[paste0('CustName_',lang_disp)]][[1]]
				#[Quote: https://github.com/rstudio/shinydashboard/issues/57 ]
				,subtitle = shiny::span(shiny::tagList(
					shiny::icon(ifelse(CustData$custinf[['f_qpv']][[1]] == 1,'gem','star'))
					,paste0(' ',CustData$custinf[[paste0('qpv_',lang_disp)]][[1]])
				))
				,type = 2
				,image = CustData$PhotoURL
				,imageElevation = 1
			)
			,footer = shiny::tagList(
				#Relationship period length with the Bank
				shiny::fluidRow(
					class = 'cpd_fluidRow'
					,style = paste0(''
						,'overflow: hidden;'
						,'color: ',color_cfg$UsrBox
					)
					,shiny::fillRow(
						flex = c(NA,1)
						,height = 24
						,shiny::tags$div(
							style = uRV$btn_styles_attr
							,shiny::span(shiny::tagList(
								shiny::icon('calendar-plus')
								,paste0(' ',lang_cfg[[lang_disp]][['tblvars']][['custinf']][['d_create_on']])
							))
						)
						,shiny::tags$div(
							style = uRV$txt_styles_attr
							,strftime(CustData$custinf[['d_create_on']][[1]], '%Y-%m-%d', tz = Sys.getenv('TZ'))
						)
					#End of [fillRow]
					)
				#End of [fluidRow]
				)
				#Risk Profile Questionnaire
				,shiny::fluidRow(
					class = 'cpd_fluidRow'
					,style = paste0(''
						,'overflow: hidden;'
						,'color: ',color_cfg$UsrBox
					)
					,shiny::fillRow(
						flex = c(NA,1)
						,height = 24
						,shiny::tags$div(
							style = uRV$btn_styles_attr
							,shiny::span(shiny::tagList(
								shiny::icon('map-marker-alt')
								,paste0(' ',lang_cfg[[lang_disp]][['tblvars']][['custinf']][['RPQ']])
							))
						)
						,shiny::tags$div(
							style = uRV$txt_styles_attr
							,paste0(
								CustData$custinf[['RPQ']][[1]]
								,'-'
								,CustData$custinf[[paste0('RPQ_Value_',lang_disp)]][[1]]
							)
						)
					#End of [fillRow]
					)
				#End of [fluidRow]
				)
			#End of [footer]
			)
		#End of [userBox]
		)
	#End of [tagList]
	)
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[410][Prepare Chart][OUT][uRV$uCard_Profile]')))
	}

	#413. Asset distribution by Product Category
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[413][Prepare Chart][IN][uRV$ch_ProdCat]')))
	}
	uRV$ch_ProdCat <- CustData$Bal_ProdCat %>%
		#Set the [height] here to ensure the [printed chart] has the same height,
		# while set the [height] inside [echarts4rOutput] is to ensure the [screen display] has the same height.
		#This means: both settings have to be set for compatibility!
		echarts4r::e_charts(PortRatio, height = 192) %>%
		#100. Draw the bar for the series as [Recommended Asset Distribution]
		echarts4r::e_bar_(
			paste0('ProdCat_',lang_disp)
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCat']][['PortRatio']]
			,barWidth = 12
			,itemStyle = list(
				color = color_cfg$Advise
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'right'
					,distance = 2
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'(params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>' , lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCat']][['PortRatio']] , '</strong>"'
								,'+ " : " + (params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		#200. Draw the bar for the series as [Actual Asset Distribution]
		echarts4r::e_data(CustData$Bal_ProdCat,bal_pct) %>%
		echarts4r::e_bar_(
			paste0('ProdCat_',lang_disp)
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCat']][['bal_pct']]
			,barWidth = 12
			,barCategoryGap = 20
			,itemStyle = list(
				color = color_cfg$CustAct
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'right'
					,distance = 2
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'(params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>' , lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCat']][['bal_pct']] , '</strong>"'
								,'+ " : " + (params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		#300. Setup the axes
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,data = CustData$Bal_ProdCat[[paste0('ProdCat_',lang_disp)]]
			,position = 'left'
			,type = 'category'
			,axisLabel = modifyList(
				uRV$styles_ch_content
				,list(
					margin = 4
				)
			)
			,axisLine = list(
				lineStyle = list(
					color = color_cfg$ech_al_Style
				)
			)
			,axisTick = list(show = FALSE)
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
			,top = 2
			,orient = 'vertical'
			,itemGap = 2
			,itemWidth = 8
			,itemHeight = 8
			,textStyle = uRV$styles_ch_content
		) %>%
		#500. Setup the title
		echarts4r::e_title(
			text = lang_cfg[[lang_disp]][['charttitle']][['Bal_ProdCat']]
			,left = 4
			,top = 2
			,textStyle = uRV$styles_ch_content
		) %>%
		#920. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#980. Enable the tooltip triggered by mouse over the bars
		echarts4r::e_tooltip(
			trigger = 'item'
			,axisPointer = list(
				show = FALSE
			)
		)

	#Set proper grid
	uRV$grid_ProdCat <- list(index = 0, top = 24, right = 40, bottom = 8, left = uRV$grid_ProdCat_Left[[lang_disp]])
	uRV$ch_ProdCat <- do.call(echarts4r::e_grid
		,append(
			list(e = uRV$ch_ProdCat)
			,append(
				uRV$grid_ProdCat
				,list(height = 160)
			)
		)
	)
	output$EchOut_ProdCat <- echarts4r::renderEcharts4r({uRV$ch_ProdCat})
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[413][Prepare Chart][OUT][uRV$ch_ProdCat]')))
	}

	#415. Asset distribution by Product Risk Level
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[415][Prepare Chart][IN][uRV$ch_RiskLvl]')))
	}
	uRV$ch_RiskLvl <- CustData$Bal_RiskLvl %>%
		echarts4r::e_charts(bal_pct, height = 192) %>%
		echarts4r::e_bar_(
			paste0('Value_',lang_disp)
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_RiskLvl']][['bal_pct']]
			,barWidth = 12
			,barCategoryGap = 16
			,itemStyle = list(
				color = color_cfg$CustAct
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'left'
					,distance = 2
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'(params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>" + params.value[1] + "</strong>"'
								,'+ " : " + (params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,data = CustData$Bal_RiskLvl[[paste0('Value_',lang_disp)]]
			,position = 'right'
			,type = 'category'
			,axisLabel = modifyList(
				uRV$styles_ch_content
				,list(
					margin = 4
				)
			)
			,axisLine = list(
				lineStyle = list(
					color = color_cfg$ech_al_Style
				)
			)
			,axisTick = list(show = FALSE)
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
			,inverse = TRUE
			,type = 'value'
			,axisTick = list(show = FALSE)
			,axisPointer = list(show = FALSE)
			,axisLabel = list(show = FALSE)
		) %>%
		echarts4r::e_legend(
			left = 4
			,top = 2
			,orient = 'vertical'
			,itemGap = 2
			,itemWidth = 8
			,itemHeight = 8
			,textStyle = uRV$styles_ch_content
		) %>%
		echarts4r::e_title(
			text = lang_cfg[[lang_disp]][['charttitle']][['Bal_RiskLvl']]
			,right = 4
			,top = 2
			,textStyle = uRV$styles_ch_content
		) %>%
		echarts4r::e_show_loading() %>%
		echarts4r::e_tooltip(
			trigger = 'item'
			,axisPointer = list(
				show = FALSE
			)
		)

	#Set proper grid
	uRV$grid_RiskLvl <- list(index = 0, top = 24, right = uRV$grid_RiskLvl_Right[[lang_disp]], bottom = 8, left = 40)
	uRV$ch_RiskLvl <- do.call(echarts4r::e_grid
		,append(
			list(e = uRV$ch_RiskLvl)
			,append(
				uRV$grid_RiskLvl
				,list(height = 160)
			)
		)
	)
	output$EchOut_RiskLvl <- echarts4r::renderEcharts4r({uRV$ch_RiskLvl})
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[415][Prepare Chart][OUT][uRV$ch_RiskLvl]')))
	}

	#430. Distribution by product type and fund names
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[430][Prepare Chart][IN][uRV$ch_ProdType]')))
	}
	#431. Sort the data in descending order
	name_Bal_ProdType <- names(CustData$Bal_ProdType)
	if ('new_bcy' %in% name_Bal_ProdType) {
		Bal_ProdType <- CustData$Bal_ProdType %>%
			dplyr::arrange(dplyr::desc(new_bcy),dplyr::desc(bal_bcy))
	} else {
		Bal_ProdType <- CustData$Bal_ProdType %>%
			dplyr::arrange(dplyr::desc(bal_bcy))
	}

	#435. Asset distribution by Product Type
	uRV$ch_ProdType <- Bal_ProdType %>%
		echarts4r::e_charts_(paste0('ProdType_',lang_disp), height = 160) %>%
		#100. Draw the bars for all product types
		echarts4r::e_bar(
			bal_bcy
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdType']][['bal_bcy']]
			,barWidth = '30%'
			#Inject the JS code to set different colors to all bars respectively
			#[Quote: https://www.php.cn/js-tutorial-409788.html ]
			,itemStyle = list(
				color = htmlwidgets::JS(paste0(
					'function(params){'
						,'var colorlst = ["',paste0(CustData$Bal_ProdType$color_old,collapse = '","'),'"];'
						,'return(colorlst[params.dataIndex]);'
					,'}'
				))
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'top'
					,distance = 2
					#Turn on this option if the colors of each bar are not unified
					# ,color = '#000'
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'var labellst = ["',paste0(CustData$Bal_ProdType[[paste0('lbl_',lang_disp)]],collapse = '","'),'"];'
							,'return('
								,'labellst[params.dataIndex]'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'var pctlst = [',paste0(CustData$Bal_ProdType$bal_pct,collapse = ','),'];'
							,'return('
								,'"<strong>" + params.value[0] + "</strong>"'
								,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed(2))'
								,'+ "<br/>(" + (parseFloat(pctlst[params.dataIndex]) * 100).toFixed(2) + "%)"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		)

	#437. Add a new serie to represent the adjusted holding
	if ('new_bcy' %in% name_Bal_ProdType) {
		uRV$legendColor_ch_ProdName <- c(uRV$legendColor_ch_ProdName, min(CustData$Bal_ProdType$color_new))

		uRV$ch_ProdType %<>%
			#120. Draw the bars for adjusted holdings
			echarts4r::e_bar(
				new_bcy
				,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdType']][['new_bcy']]
				,barWidth = '30%'
				#Inject the JS code to set different colors to all bars respectively
				#[Quote: https://www.php.cn/js-tutorial-409788.html ]
				,itemStyle = list(
					color = htmlwidgets::JS(paste0(
						'function(params){'
							,'var colorlst = ["',paste0(CustData$Bal_ProdType$color_new,collapse = '","'),'"];'
							,'return(colorlst[params.dataIndex]);'
						,'}'
					))
					,borderWidth = 1
					,barBorderRadius = 3
				)
				,label = modifyList(
					uRV$styles_ch_content
					,list(
						show = TRUE
						,position = 'top'
						,distance = 2
						#Turn on this option if the colors of each bar are not unified
						# ,color = '#000'
						,formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'var labellst = ["',paste0(CustData$Bal_ProdType[[paste0('lbl_new_',lang_disp)]],collapse = '","'),'"];'
								,'return('
									,'labellst[params.dataIndex]'
								,');'
							,'}'
						))
					)
				)
				,tooltip = modifyList(
					uRV$attr_tooltips
					,list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'var pctlst = [',paste0(CustData$Bal_ProdType$new_pct,collapse = ','),'];'
								,'return('
									,'"<strong>" + params.value[0] + "</strong>"'
									,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed(2))'
									,'+ "<br/>(" + (parseFloat(pctlst[params.dataIndex]) * 100).toFixed(2) + "%)"'
								,');'
							,'}'
						))
					)
				)
				,x_index = 0
				,y_index = 0
			)
	}

	#439. Other settings
	uRV$ch_ProdType %<>%
		#300. Setup the axes
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,show = FALSE
			,axisPointer = list(show = FALSE)
		) %>%
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,data = CustData$Bal_ProdType[[paste0('ProdType_',lang_disp)]]
			,show = TRUE
			,axisLabel = modifyList(
				uRV$styles_ch_content
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(value,index){'
							,'return('
								#[Quote: parameter config of both [xAxis.axisLabel.formatter] and [legend.tooltip]]
								,'echarts.format.truncateText(value,48,"',uRV$styles_ch_FontSize_item,'px ',font_disp,'","...")'
							,');'
						,'}'
					))
					# ,rotate = 90
					,interval = 0
					,margin = 4
				)
			)
			,axisLine = list(
				lineStyle = list(
					color = color_cfg$ech_al_Style
				)
			)
			,axisTick = list(show = FALSE)
		) %>%
		#400. Setup the legend
		echarts4r::e_legend(
			right = 4
			,top = 16
			,itemWidth = 8
			,itemHeight = 8
			# ,icon = rep('none',nrow(uRV$colors_ProdCTT))
			,textStyle = uRV$styles_ch_content
			,itemStyle = list(
				color = uRV$legendColor_ch_ProdName
			)
		) %>%
		#500. Setup the title
		echarts4r::e_title(
			text = lang_cfg[[lang_disp]][['charttitle']][['Bal_ProdType']]
			,left = 4
			,top = 2
			,textStyle = uRV$styles_ch_content
		) %>%
		#920. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#980. Enable the tooltip triggered by mouse over the bars
		echarts4r::e_tooltip(
			trigger = 'item'
			,axisPointer = list(
				show = FALSE
			)
		)

	#Set proper grid
	uRV$grid_ProdType <- list(index = 0, top = 32, right = 8, bottom = 16, left = 8)
	uRV$ch_ProdType <- do.call(echarts4r::e_grid
		,append(
			list(e = uRV$ch_ProdType)
			,append(
				uRV$grid_ProdType
				,list(height = 112)
			)
		)
	)
	output$EchOut_ProdType <- echarts4r::renderEcharts4r({uRV$ch_ProdType})
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[430][Prepare Chart][OUT][uRV$ch_ProdType]')))
	}

	#440. Distribution by product type and fund names
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[440][Prepare Chart][IN][uRV$ch_FundName]')))
	}
	#441. Only select 5 records at most to save screen display
	name_Bal_FundName <- names(CustData$Bal_FundName)
	nrow_Bal_FundName <- nrow(CustData$Bal_FundName)
	nrow_ch_FundName <- min(5,nrow_Bal_FundName)
	if (nrow_ch_FundName == 0) rows_ch_FundName <- 0 else rows_ch_FundName <- seq(1,nrow_ch_FundName,1)
	if ('new_bcy' %in% name_Bal_FundName) {
		Bal_FundName <- CustData$Bal_FundName %>%
			dplyr::arrange(dplyr::desc(new_bcy),dplyr::desc(bal_bcy)) %>%
			.[rows_ch_FundName,]
	} else {
		Bal_FundName <- CustData$Bal_FundName %>%
			dplyr::arrange(dplyr::desc(bal_bcy)) %>%
			.[rows_ch_FundName,]
	}

	#445. Asset distribution by Product Type
	uRV$ch_FundName <- Bal_FundName %>%
		echarts4r::e_charts_(paste0('ProdName_',lang_disp), height = 160) %>%
		#100. Draw the bars for all product types
		echarts4r::e_bar(
			bal_bcy
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['bal_bcy']]
			,barWidth = '30%'
			#Inject the JS code to set different colors to all bars respectively
			#[Quote: https://www.php.cn/js-tutorial-409788.html ]
			,itemStyle = list(
				color = htmlwidgets::JS(paste0(
					'function(params){'
						,'var colorlst = ["',paste0(CustData$Bal_FundName$color_old,collapse = '","'),'"];'
						,'return(colorlst[params.dataIndex]);'
					,'}'
				))
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'top'
					,distance = 2
					#Turn on this option if the colors of each bar are not unified
					# ,color = '#000'
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'var labellst = ["',paste0(CustData$Bal_FundName[[paste0('lbl_',lang_disp)]],collapse = '","'),'"];'
							,'return('
								,'labellst[params.dataIndex]'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'var pct_aum_lst = [',paste0(CustData$Bal_FundName$bal_pct,collapse = ','),'];'
							,'var pct_fund_lst = [',paste0(CustData$Bal_FundName$bal_fund_pct,collapse = ','),'];'
							,'return('
								,'"<strong>" + params.value[0] + "</strong>"'
								,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed(2))'
								,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['bal_pct']]
									,': " + (parseFloat(pct_aum_lst[params.dataIndex]) * 100).toFixed(2) + "%)"'
								,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['bal_fund_pct']]
									,': " + (parseFloat(pct_fund_lst[params.dataIndex]) * 100).toFixed(2) + "%)"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		)

	#447. Add a new serie to represent the adjusted holding
	if ('new_bcy' %in% name_Bal_FundName) {
		uRV$legendColor_ch_FundName <- c(uRV$legendColor_ch_FundName, min(CustData$Bal_FundName$color_new))

		uRV$ch_FundName %<>%
			#120. Draw the bars for adjusted holdings
			echarts4r::e_bar(
				new_bcy
				,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['new_bcy']]
				,barWidth = '30%'
				#Inject the JS code to set different colors to all bars respectively
				#[Quote: https://www.php.cn/js-tutorial-409788.html ]
				,itemStyle = list(
					color = htmlwidgets::JS(paste0(
						'function(params){'
							,'var colorlst = ["',paste0(CustData$Bal_FundName$color_new,collapse = '","'),'"];'
							,'return(colorlst[params.dataIndex]);'
						,'}'
					))
					,borderWidth = 1
					,barBorderRadius = 3
				)
				,label = modifyList(
					uRV$styles_ch_content
					,list(
						show = TRUE
						,position = 'top'
						,distance = 2
						#Turn on this option if the colors of each bar are not unified
						# ,color = '#000'
						,formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'var labellst = ["'
									,paste0(CustData$Bal_FundName[[paste0('lbl_new_',lang_disp)]],collapse = '","')
								,'"];'
								,'return('
									,'labellst[params.dataIndex]'
								,');'
							,'}'
						))
					)
				)
				,tooltip = modifyList(
					uRV$attr_tooltips
					,list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'var pct_aum_lst = [',paste0(CustData$Bal_FundName$new_pct,collapse = ','),'];'
								,'var pct_fund_lst = [',paste0(CustData$Bal_FundName$new_fund_pct,collapse = ','),'];'
								,'return('
									,'"<strong>" + params.value[0] + "</strong>"'
									,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed(2))'
									,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['new_pct']]
										,': " + (parseFloat(pct_aum_lst[params.dataIndex]) * 100).toFixed(2) + "%)"'
									,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['new_fund_pct']]
										,': " + (parseFloat(pct_fund_lst[params.dataIndex]) * 100).toFixed(2) + "%)"'
								,');'
							,'}'
						))
					)
				)
				,tooltip = modifyList(
					uRV$attr_tooltips
					,list(
						formatter = htmlwidgets::JS(paste0(
							'function(params){'
								,'var pct_aum_lst = [',paste0(CustData$Bal_FundName$new_pct,collapse = ','),'];'
								,'var pct_fund_lst = [',paste0(CustData$Bal_FundName$new_fund_pct,collapse = ','),'];'
								,'return('
									,'"<strong>" + params.value[0] + "</strong>"'
									,'+ "<br/>" + echarts.format.addCommas(parseFloat(params.value[1]).toFixed(2))'
									,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['new_pct']]
										,': " + (parseFloat(pct_aum_lst[params.dataIndex]) * 100).toFixed(2) + "%)"'
									,'+ "<br/>(',lang_cfg[[lang_disp]][['tblvars']][['Bal_FundName']][['new_fund_pct']]
										,': " + (parseFloat(pct_fund_lst[params.dataIndex]) * 100).toFixed(2) + "%)"'
								,');'
							,'}'
						))
					)
				)
				,x_index = 0
				,y_index = 0
			)
	}

	#449. Other settings
	uRV$ch_FundName %<>%
		#300. Setup the axes
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,show = FALSE
			,axisPointer = list(show = FALSE)
		) %>%
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,show = TRUE
			,axisLabel = modifyList(
				uRV$styles_ch_content
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(value,index){'
							,'return('
								#[Quote: parameter config of both [xAxis.axisLabel.formatter] and [legend.tooltip]]
								,'echarts.format.truncateText(value,60,"',uRV$styles_ch_FontSize_item,'px ',font_disp,'","...")'
							,');'
						,'}'
					))
					# ,rotate = 90
					,interval = 0
					,margin = 4
				)
			)
			,axisLine = list(
				lineStyle = list(
					color = color_cfg$ech_al_Style
				)
			)
			,axisTick = list(show = FALSE)
		) %>%
		#400. Setup the legend
		echarts4r::e_legend(
			right = 4
			,top = 16
			,itemWidth = 8
			,itemHeight = 8
			# ,icon = rep('none',nrow(uRV$colors_ProdCTT))
			,textStyle = uRV$styles_ch_content
			,itemStyle = list(
				color = uRV$legendColor_ch_FundName
			)
		) %>%
		#500. Setup the title
		echarts4r::e_title(
			text = lang_cfg[[lang_disp]][['charttitle']][['Bal_FundName']]
			,left = 4
			,top = 2
			,textStyle = uRV$styles_ch_content
		) %>%
		echarts4r::e_text_g(
			type = 'text'
			,right = 8
			,top = 8
			,style = list(
				text = lang_cfg[[lang_disp]][['charttitle_sub']][['Bal_FundName']]
				,textAlign = 'right'
				,font = paste0(uRV$styles_ch_FontSize_item,'px ',uRV$font_list_css)
			)
		) %>%
		#920. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#980. Enable the tooltip triggered by mouse over the bars
		echarts4r::e_tooltip(
			trigger = 'item'
			,axisPointer = list(
				show = FALSE
			)
		)

	#Set proper grid
	uRV$grid_FundName <- list(index = 0, top = 32, right = 8, bottom = 16, left = 8)
	uRV$ch_FundName <- do.call(echarts4r::e_grid
		,append(
			list(e = uRV$ch_FundName)
			,append(
				uRV$grid_FundName
				,list(height = 112)
			)
		)
	)
	output$EchOut_FundName <- echarts4r::renderEcharts4r({uRV$ch_FundName})
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[440][Prepare Chart][OUT][uRV$ch_FundName]')))
	}

	#490. Asset distribution by CTT
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[490][Prepare Chart][IN][uRV$ch_ProdCTT]')))
	}
	#491. Transpose the product holding to facilitate the stacked bar chart
	uRV$trns_ProdCTT <- CustData$Bal_ProdCTT %>%
		dplyr::select(-tidyselect::starts_with('ProdCTT')) %>%
		data.table::transpose(keep.names = 'kpi')
	names(uRV$trns_ProdCTT) <- c('kpi',unlist(CustData$Bal_ProdCTT$ProdCTT))
	uRV$trns_ProdCTT <- uRV$trns_ProdCTT %>%
		#Ensure all the stacked bars have the same length by making the sum of percentages as 100% precisely
		dplyr::mutate(Resi = 1 - Core - T1 - T2) %>%
		#Correct the residual by the sequence: Core -> T1 -> T2, given any among them is NOT zero
		dplyr::mutate(
			Resi = ifelse(Resi == 1 , 0 , Resi)
		) %>%
		dplyr::mutate(
			Core = ifelse(Core != 0 , Core + Resi , Core)
			,Resi = 0
		) %>%
		dplyr::mutate(
			T1 = ifelse(T1 != 0 , T1 + Resi , T1)
			,Resi = 0
		) %>%
		dplyr::mutate(
			T2 = ifelse(T2 != 0 , T2 + Resi , T2)
			,Resi = 0
		) %>%
		#Add colors to the chart
		dplyr::left_join(uRV$colors_ProdCTT, by = c('kpi' = 'kpi'), suffix = c('','.colors')) %>%
		dplyr::mutate(
			color_Core = rgba2rgb(baseColor, alpha_in = 1)
			,color_T1 = rgba2rgb(baseColor, alpha_in = 0.6)
			,color_T2 = rgba2rgb(baseColor, alpha_in = 0.2)
		) %>%
		dplyr::arrange(desc(kpiseq))
	uRV$trns_ProdCTT$kpiname <- sapply(uRV$trns_ProdCTT$kpi, function(m) lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][[m]])

	#495. Draw the chart
	uRV$ch_ProdCTT <- uRV$trns_ProdCTT %>%
		echarts4r::e_charts(kpiname, height = 136) %>%
		#100. Draw the bar for Core Asset
		echarts4r::e_bar_(
			'Core'
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][['Core']]
			,stack = 'Stack'
			,barWidth = 8
			,itemStyle = list(
				#Inject the JS code to set different colors to all bars respectively
				#[Quote: https://www.php.cn/js-tutorial-409788.html ]
				color = htmlwidgets::JS(paste0(
					'function(params){'
						,'var colorlst = ["',paste0(uRV$trns_ProdCTT$color_Core,collapse = '","'),'"];'
						,'return(colorlst[params.dataIndex]);'
					,'}'
				))
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'bottom'
					,color = '#333'
					,distance = 2
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'(params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>' , lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][['Core']] , '</strong>"'
								,'+ " : " + (params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		#200. Draw the bar for T1 Asset
		echarts4r::e_bar_(
			'T1'
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][['T1']]
			,stack = 'Stack'
			,barWidth = 8
			,itemStyle = list(
				color = htmlwidgets::JS(paste0(
					'function(params){'
						,'var colorlst = ["',paste0(uRV$trns_ProdCTT$color_T1,collapse = '","'),'"];'
						,'return(colorlst[params.dataIndex]);'
					,'}'
				))
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'bottom'
					,color = '#333'
					,distance = 2
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'(params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>' , lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][['T1']] , '</strong>"'
								,'+ " : " + (params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		#300. Draw the bar for T2 Asset
		echarts4r::e_bar_(
			'T2'
			,name = lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][['T2']]
			,stack = 'Stack'
			,barWidth = 8
			,itemStyle = list(
				color = htmlwidgets::JS(paste0(
					'function(params){'
						,'var colorlst = ["',paste0(uRV$trns_ProdCTT$color_T2,collapse = '","'),'"];'
						,'return(colorlst[params.dataIndex]);'
					,'}'
				))
				,borderWidth = 1
				,barBorderRadius = 3
			)
			,barCategoryGap = 16
			,label = modifyList(
				uRV$styles_ch_content
				,list(
					show = TRUE
					,position = 'bottom'
					,color = '#333'
					,distance = 2
					,formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'(params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,tooltip = modifyList(
				uRV$attr_tooltips
				,list(
					formatter = htmlwidgets::JS(paste0(
						'function(params){'
							,'return('
								,'"<strong>' , lang_cfg[[lang_disp]][['tblvars']][['Bal_ProdCTT']][['T2']] , '</strong>"'
								,'+ " : " + (params.value[0] * 100).toFixed(2) + "%"'
							,');'
						,'}'
					))
				)
			)
			,x_index = 0
			,y_index = 0
		) %>%
		#300. Setup the axes
		echarts4r::e_x_axis(
			index = 0
			,gridIndex = 0
			,data = uRV$trns_ProdCTT$kpiname
			,axisLine = list(
				show = FALSE
			)
			,axisLabel = modifyList(
				uRV$styles_ch_content
				,list(
					margin = 4
				)
			)
			,axisTick = list(show = FALSE)
			,splitLine = list(
				lineStyle = list(
					type = 'dashed'
				)
			)
		) %>%
		echarts4r::e_y_axis(
			index = 0
			,gridIndex = 0
			,show = FALSE
			,min = 0
			,max = 'dataMax'
			,axisTick = list(show = FALSE)
			,axisPointer = list(show = FALSE)
			,axisLabel = list(show = FALSE)
		) %>%
		#400. Setup the legend
		echarts4r::e_legend(
			right = 4
			,top = 16
			,itemWidth = 8
			,itemHeight = 8
			# ,icon = rep('none',nrow(uRV$colors_ProdCTT))
			,textStyle = uRV$styles_ch_content
			,itemStyle = list(
				color = uRV$colors_legend_ProdCTT
			)
		) %>%
		#500. Setup the title
		echarts4r::e_title(
			text = lang_cfg[[lang_disp]][['charttitle']][['Bal_ProdCTT']]
			,left = 4
			,top = 2
			,textStyle = uRV$styles_ch_content
		) %>%
		#910. Flip the coordinates
		echarts4r::e_flip_coords() %>%
		#920. Show a loading animation when the chart is re-drawn
		echarts4r::e_show_loading() %>%
		#980. Enable the tooltip triggered by mouse over the bars
		echarts4r::e_tooltip(
			trigger = 'item'
			,axisPointer = list(
				show = FALSE
			)
		)

	#Set proper grid
	uRV$grid_ProdCTT <- list(index = 0, top = 24, right = 16, bottom = 24, left = 56)
	uRV$ch_ProdCTT <- do.call(echarts4r::e_grid
		,append(
			list(e = uRV$ch_ProdCTT)
			,append(
				uRV$grid_ProdCTT
				,list(height = 88)
			)
		)
	)
	output$EchOut_ProdCTT <- echarts4r::renderEcharts4r({uRV$ch_ProdCTT})
	#Debug Mode
	if (fDebug){
		message(ns(paste0('[490][Prepare Chart][OUT][uRV$ch_ProdCTT]')))
	}

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
				session$userData[[paste(ns(observer_pfx),'pb_obs_chart',sep='_')]]$destroy()
			}
		}
		# ,suspended = T
	)

	#600. Prepare the datatables to display the brief information of product holding and P&L
	#601. Prepare the general function to draw the datatable
	drawDT_byProduct <- function(tblname){
		#100. Define the table to display
		nrow_tbl <- nrow(CustData[[tblname]])
		colsDT_tbl <- names(lang_cfg[[lang_disp]][['tblvars']][[tblname]])
		names(colsDT_tbl) <- lang_cfg[[lang_disp]][['tblvars']][[tblname]]
		sum_PnL <- sum(CustData[[tblname]][['Gain_bcy_mtd']])
		sumC_PnL <- formatC( sum_PnL , digits = 2 , big.mark = ',' , format = 'f' , zero.print = '0.00' )

		#300. Draw the datatable
		#[Quote: https://rstudio.github.io/DT/options.html ]
		#[Quote: https://rstudio.github.io/DT/010-style.html ]
		dt_pre <- DT::datatable(
			CustData[[tblname]][,colsDT_tbl]
			,caption = shiny::tags$caption(
				style = paste0(
					'padding-right: 5px;'
					,'caption-side: bottom;'
					,'text-align: right;'
					,uRV$styles_tabBox_font
				)
				,shiny::tags$span(shiny::tagList(
					lang_cfg[[lang_disp]][['tblsubtotals']][['Holding']]
					,shiny::icon('yen-sign')
					,shiny::tags$span(
						style = paste0('color: ',setNumColor(sum_PnL),';')
						,sumC_PnL
					)
				))
			)
			,rownames = dt_rownames
			#Only determine the columns to be displayed, rather than the columns to extract from the input data
			,colnames = colsDT_tbl
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
				initComplete = htmlwidgets::JS(paste0(
					'function(settings, json){'
						,'$(this.api().table().header()).css({'
							,'"background-color": "',color_cfg$DTHeaderBg,'"'
							,',"color": "',color_cfg$DTHeaderTxt,'"'
							,',"font-family": "',font_disp,'"'
							,',"font-size": "',shiny::validateCssUnit(uRV$styles_ch_FontSize_item),'"'
						,'});'
					,'}'
				))
				#We have to set the [stateSave=F], otherwise the table cannot be displayed completely!!
				,stateSave = FALSE
				,ordering = FALSE
				# ,autoWidth = TRUE
				,scrollX = FALSE
				#[Show N entries] on top left
				,pageLength = nrow_tbl
				#[Quote: https://datatables.net/reference/option/language.searchPlaceholder ]
				,language = lang_cfg[[lang_disp]][['dtstyle']][['language']]
				#Only display the table
				,dom = 't'
				,columnDefs = list()
			#End of [options]
			)
		#End of [datatable]
		) %>%
			#Set the font for all content in the table
			DT::formatStyle(
				names(colsDT_tbl)
				,fontFamily = font_disp
				,fontSize = shiny::validateCssUnit(uRV$styles_ch_FontSize_item)
			)

		#500. Format specific values
		#510. Format the amount as: [#,###.00]
		if (any(colsDT_tbl %in% CustData$NumFmt_Currency)) {
			dt_pre %<>% DT::formatCurrency(
				names(colsDT_tbl)[which(colsDT_tbl %in% CustData$NumFmt_Currency)]
				,currency = ''
			)
		}

		#530. Format the price as: [#,###.0000]
		if (any(colsDT_tbl %in% CustData$NumFmt_Price)) {
			dt_pre %<>% DT::formatCurrency(
				names(colsDT_tbl)[which(colsDT_tbl %in% CustData$NumFmt_Price)]
				,currency = ''
				,digits = 4
			)
		}

		#550. Format the percentage as: [#,###.00%]
		if (any(colsDT_tbl %in% CustData$NumFmt_Percent)) {
			dt_pre %<>% DT::formatPercentage(
				names(colsDT_tbl)[which(colsDT_tbl %in% CustData$NumFmt_Percent)]
				,digits = 2
			)
		}

		#570. Set the font color for positive numbers as [green], while that for negative ones as [red]
		if (any(colsDT_tbl %in% CustData$NumFmt_PnL)) {
			dt_pre %<>% DT::formatStyle(
				names(colsDT_tbl)[which(colsDT_tbl %in% CustData$NumFmt_PnL)]
				,color = DT::styleInterval(
					-0.0000001
					,c(color_cfg$Negative,color_cfg$Positive)
				)
			)
		}

		#900. Define the output
		dt_out <- shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$dt_styles_byProduct
			)
			,dt_pre
		)

		#999. Return the result
		return(dt_out)
	}

	#610. Prepare the span to display the overall P&L for current holdings
	uRV$span_AllPnL <- shiny::tags$span(
		style = uRV$styles_tabBox_font
		,shiny::tags$span(shiny::tagList(
			lang_cfg[[lang_disp]][['tbltotals']][['Holding']]
			,shiny::icon('yen-sign')
			,shiny::tags$span(
				style = paste0('color: ',setNumColor(CustData$Gain_AllProd),';')
				,formatC(
					CustData$Gain_AllProd
					,digits = 2
					,big.mark = ','
					,format = 'f'
					,zero.print = '0.00'
				)
			#End of [span]
			)
		#End of [span]
		))
	#End of [span]
	)

	#650. Draw the datatables
	uRV$dt_Prods <- lapply(lst_drawDT,drawDT_byProduct)

	#700. Create UI

	#790. Final UI
	#791. Name Card as well as the Overall portfolio
	crTag_Profile <- function(u_Prof,u_ProdCat,u_RiskLvl){
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)

			,shiny::fluidRow(
				class = 'cpd_fluidRow'
				,shiny::fillRow(
					flex = c(5,7)
					,height = 192
					,u_Prof
					,shiny::fillRow(
						flex = c(1,1)
						,height = 192
						,u_ProdCat
						,u_RiskLvl
					)
				)
			)
		#End of [tagList]
		)
	}
	uRV$print_Profile <- crTag_Profile(
		uRV$uCard_Profile
		,uRV$ch_ProdCat
		,uRV$ch_RiskLvl
	)
	output$uDiv_NameCard <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[791][renderUI][IN][output$uDiv_NameCard]')))
		}

		crTag_Profile(
			uRV$uCard_Profile
			,echarts4r::echarts4rOutput(ns(paste0('EchOut_ProdCat')), height = 192)
			,echarts4r::echarts4rOutput(ns(paste0('EchOut_RiskLvl')), height = 192)
		)
	#End of [renderUI] of [791]
	})

	#793. Product Distribution
	crTag_ProdType <- function(u_ProdType,u_FundName){
		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)

			,shiny::fluidRow(
				class = 'cpd_fluidRow'
				,shiny::fillRow(
					flex = c(1,1)
					,height = 160
					,u_ProdType
					,u_FundName
				)
			)
		#End of [tagList]
		)
	}
	uRV$print_ProdType <- crTag_ProdType(
		uRV$ch_ProdType
		,uRV$ch_FundName
	)
	output$uDiv_ProdType <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[793][renderUI][IN][output$uDiv_ProdType]')))
		}

		crTag_ProdType(
			echarts4r::echarts4rOutput(ns(paste0('EchOut_ProdType')), height = 160)
			,echarts4r::echarts4rOutput(ns(paste0('EchOut_FundName')), height = 160)
		)
	#End of [renderUI] of [793]
	})

	#795. Tables to display product holding and P&L
	output$uDiv_DashTables <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[795][renderUI][IN][output$uDiv_DashTables]')))
		}

		shiny::tagList(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,uRV$styles_final
			)
			#Below is a weird solution, but it works!
			#How to use lapply or another higher order function when calling tabPanel in R shiny
			#[Quote: https://stackoverflow.com/questions/56410385 ]
			,do.call(
				function(...){
					shiny::tagList(
						shiny::tags$style(
							type = 'text/css'
							,uRV$styles_tabBox
						)
						,shinydashboard::tabBox(
							title = uRV$span_AllPnL
							# The id lets us use input$tabset1 on the server to find the current tab
							,id = ns('uTB_byProd')
							,width = uRV$uTB_width
							,...
						)
					)
				}
				,mapply(
					function(title, plotid){
						shiny::tabPanel(
							shiny::tags$span(
								style = uRV$styles_tabBox_font
								,lang_cfg[[lang_disp]][['tblnames']][[title]]
							#End of [span]
							)
							,plotid
						)
					}
					,lst_drawDT
					,uRV$dt_Prods
					,SIMPLIFY = FALSE
					,USE.NAMES = FALSE
				)
			)
		#End of [tagList]
		)
	})

	#797. CTT Composition
	crTag_ProdCTT <- function(u_ProdCTT){
		shiny::tags$div(
			#[Quote: https://stackoverflow.com/questions/25340847/control-the-height-in-fluidrow-in-r-shiny ]
			shiny::tags$style(
				type = 'text/css'
				,paste0(''
					#[Weird 1] There exists an unknown division together with the [echarts4r] element created!
					#[Weird 2] It is placed on top of all other elements in fromt of the [rmarkdown] page!
					#[Weird 3] We can only set its [position] attribute as [unset !important] to avoid its overlay!
					,'[id^="htmlwidget-"] {'
						,'position: unset !important;'
					,'}'
				)
			)

			,u_ProdCTT
		#End of [tagList]
		)
	}
	uRV$print_CTT <- crTag_ProdCTT(uRV$ch_ProdCTT)
	output$uDiv_CTT <- shiny::renderUI({
		#Debug Mode
		if (fDebug){
			message(ns(paste0('[797][renderUI][IN][output$uDiv_CTT]')))
		}

		crTag_ProdCTT(echarts4r::echarts4rOutput(ns(paste0('EchOut_ProdCTT')), height = 136))
	#End of [renderUI] of [797]
	})
	uRV$knitr_params <- list(
		lang_cfg = lang_cfg
		,lang_disp = lang_disp
		,print_Profile = uRV$print_Profile
		,print_ProdType = uRV$print_ProdType
		,print_CTT = uRV$print_CTT
		,print_span_AllPnL = uRV$span_AllPnL
		,print_dt_Prods_hdr = lst_drawDT
		,print_dt_Prods = uRV$dt_Prods
	)

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
			, 'shiny', 'DT', 'shinydashboard', 'shinydashboardPlus', 'echarts4r', 'htmlwidgets', 'dplyr', 'tidyselect', 'data.table', 'grDevices'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

		#Source the user specified functions and processes.
		source('D:\\R\\autoexec.r')
		omniR <- getOption('path.omniR')

		#Load necessary data
		myProj <- 'D:\\R\\Project'
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','theme_color_sets.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Data','Test_PortMgmt_LoadData.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','lang_PortMgmt.r')), encoding = 'utf-8')
		source(normalizePath(file.path(myProj,'Analytics','Func','UI','color_PortMgmt.r')), encoding = 'utf-8')

		ui <- shinydashboardPlus::dashboardPage(
			header = shinydashboardPlus::dashboardHeader()
			,sidebar = shinydashboardPlus::dashboardSidebar(
				shinydashboard::sidebarMenu(id = 'left_sidebar'
					#[Icons are from the official page: https://adminlte.io/themes/AdminLTE/pages/UI/icons.html ]
					,shinydashboard::menuItem(
						'Portfolio Management'
						,tabName = 'uMI_PortMgmt'
						,icon = shiny::icon('chart-bar')
					)
					,shinydashboard::menuItem(
						'Print Report'
						,tabName = 'uMI_PrintRpt'
						,icon = shiny::icon('chart-bar')
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
								,icon_on = shiny::icon('ok-circle', lib = 'glyphicon')
								,label_off = 'EN'
								,status_off = 'default'
								,icon_off = shiny::icon('remove-circle', lib = 'glyphicon')
								,plain = TRUE
								,inline = TRUE
							)
							)
							,shiny::column(width = 9
								,shiny::fluidRow(UM_CPD_ui_NameCard('cpd'))
								,shiny::fluidRow(UM_CPD_ui_ProdType('cpd'))
								,shiny::fluidRow(UM_CPD_ui_DashTables('cpd'))
								,shiny::fluidRow(UM_CPD_ui_CTT('cpd'))

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
			,controlbar = shinydashboardPlus::dashboardControlbar()
			,title = 'DashboardPage'
		)
		server <- function(input, output, session) {
			modout <- shiny::reactiveValues()
			modout$cpd <- shiny::reactiveValues(
				CallCounter = shiny::reactiveVal(0)
				,ActionDone = shiny::reactive({FALSE})
				,EnvVariables = shiny::reactive({NULL})
			)

			shiny::observe(
				{
					#100. Take dependencies
					input$toggle

					#900. Execute below block of codes only once upon the change of any one of above dependencies
					shiny::isolate({
						if (is.null(input$toggle)) return()

						if (input$toggle) lang_disp <- 'CN'
						else lang_disp <- 'EN'

						#Garbage collection of the previous call
						#[Quote: [omniR$AdvOp$gc_shiny_module]]
						gc_shiny_module(
							'cpd'
							,input
							,session
							,UI_Selectors = NULL
							,UI_namespaced = T
							,observer_pfx = 'uObs'
						)

						modout$cpd <- shiny::callModule(
							UM_custPortDash_svr
							,'cpd'
							,CustData = uRV$PM_rpt
							,lang_cfg = lang_CPM
							,color_cfg = color_CPM
							,lang_disp = lang_disp
							,font_disp = 'Microsoft YaHei'
							,observer_pfx = 'uObs'
							,fDebug = FALSE
						)

						modout$params <- modout$cpd$EnvVariables()$knitr_params
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
			shiny::observeEvent(modout$cpd$CallCounter(),{
				if (modout$cpd$CallCounter() == 0) return()
				message('[cpd$CallCounter()]:',modout$cpd$CallCounter())
				# message('[cpd$EnvVariables()$text_out]:',modout$cpd$EnvVariables()$text_out)
			})
		}

		shiny::shinyApp(ui, server)
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
